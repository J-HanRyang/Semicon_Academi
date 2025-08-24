# Managers/news_manager.py
import glob
import json
import os
import re
import time
from datetime import datetime, timedelta, timezone

import requests
from rapidfuzz import fuzz

class NewsManager:
    def __init__(self, naver_client_id, naver_client_secret, summarizer, file_path, threshold=50, cutoff_hour=6, days_to_keep=7):
        self.client_id = naver_client_id
        self.client_secret = naver_client_secret
        self.summarizer = summarizer
        self.file_path = file_path
        self.SIMILARITY_THRESHOLD = threshold
        self.CUTOFF_HOUR = cutoff_hour
        self.DAYS_TO_KEEP_LOGS = days_to_keep
        self.seen_topics_filepath = self._get_logical_date_filepath() if self.file_path else None

    def _clean_title(self, title):
        cleaned = re.sub(r'<.*?>', '', title)
        cleaned = re.sub(r'&quot;|\[.*?\]|【.*?】|「.*?」', '', cleaned).strip()
        return cleaned

    def _get_logical_date_obj(self):
        now = datetime.now()
        return (now - timedelta(days=1)).date() if now.hour < self.CUTOFF_HOUR else now.date()

    def _get_logical_date_filepath(self):
        date_str = self._get_logical_date_obj().strftime("%Y-%m-%d")
        os.makedirs(self.file_path, exist_ok=True)
        return os.path.join(self.file_path, f"seen_topics_{date_str}.txt")

    def _load_seen_topics(self):
        if not self.seen_topics_filepath:
            return set()
        try:
            with open(self.seen_topics_filepath, 'r', encoding='utf-8') as f:
                return set(line.strip() for line in f)
        except FileNotFoundError:
            return set()
        
    def _save_seen_topics(self, topics):
        if not self.seen_topics_filepath:
            return
        with open(self.seen_topics_filepath, 'a', encoding='utf-8') as f:
            for topic in topics:
                f.write(topic + '\n')

    def manage_old_files(self):
        if not self.file_path:
            return
        today = datetime.now().date()
        for filename in glob.glob(os.path.join(self.file_path, "seen_topics_*.txt")):
            try:
                file_date_str = os.path.basename(filename).replace("seen_topics_", '').replace('.txt', '')
                file_date = datetime.strptime(file_date_str, "%Y-%m-%d").date()
                if (today - file_date).days >= self.DAYS_TO_KEEP_LOGS:
                    os.remove(filename)
            except ValueError:
                continue

    def _fetch_from_api(self, query, count, start):
        url = f"https://openapi.naver.com/v1/search/news.json?query={query}&display={count}&start={start}&sort=sim"
        headers = {"X-Naver-Client-Id": self.client_id, "X-Naver-Client-Secret": self.client_secret}
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            return response.json().get('items', [])
        except requests.exceptions.RequestException as e:
            print(f"API 요청 오류: {e}")
            return []

    def _group_similar_articles(self, articles):
        article_groups = []
        for article in articles:
            cleaned_title = self._clean_title(article['title'])
            found_group = False
            for group in article_groups:
                rep_title = self._clean_title(group[0]['title'])
                if fuzz.token_sort_ratio(cleaned_title, rep_title) >= self.SIMILARITY_THRESHOLD:
                    group.append(article)
                    found_group = True
                    break
            if not found_group:
                article_groups.append([article])
        return article_groups

    def _get_new_articles(self, query, target_count=10):
        self.manage_old_files()
        seen_topics = self._load_seen_topics()
        now = datetime.now(timezone.utc)
        twenty_four_hours_ago = now - timedelta(hours=24)
        
        articles_new_topics = []
        start_index = 1
        for _ in range(2):
            fetched_articles = self._fetch_from_api(query, 100, start_index)
            if not fetched_articles: break
            
            recent_articles = []
            for article in fetched_articles:
                try:
                    pub_date_dt = datetime.strptime(article['pubDate'], '%a, %d %b %Y %H:%M:%S %z')
                    if pub_date_dt > twenty_four_hours_ago:
                        recent_articles.append(article)
                except (ValueError, KeyError):
                    continue
            
            articles_new_topics.extend(art for art in recent_articles if not any(fuzz.token_sort_ratio(self._clean_title(art['title']), topic) > self.SIMILARITY_THRESHOLD for topic in seen_topics))
            if len(articles_new_topics) >= target_count * 5: break
            start_index += 100
            time.sleep(0.5)

        if not articles_new_topics: return []
        
        article_groups = self._group_similar_articles(articles_new_topics)
        article_groups.sort(key=len, reverse=True)
        final_articles = [group[0] for group in article_groups][:target_count]
        new_topics_to_save = [self._clean_title(art['title']) for art in final_articles]
        self._save_seen_topics(new_topics_to_save)
        return final_articles

    # --- [내부 공통 함수] 뉴스 데이터를 가공하여 최종 딕셔너리 형태로 만듦 ---
    def _create_news_data_dict(self, query, target_count):
        final_articles = self._get_new_articles(query, target_count)
        
        articles_for_export = []
        if final_articles:
            for i, article in enumerate(final_articles):
                try:
                    summary = ""
                    if i < 3:
                        description = self._clean_title(article.get('description', ''))
                        if description:
                            summary = self.summarizer.summarize(description)
                    
                    try:
                        pub_date = datetime.strptime(article['pubDate'], '%a, %d %b %Y %H:%M:%S %z')
                        formatted_date = pub_date.strftime('%Y-%m-%d %H:%M')
                    except (ValueError, KeyError):
                        formatted_date = "날짜 정보 없음"

                    articles_for_export.append({
                        'cleaned_title': self._clean_title(article['title']),
                        'summary': summary,
                        'naver_link': article['link'],
                        'publication_date': article['pubDate'],
                        'formatted_date' : formatted_date
                    })
                except Exception as e:
                    print(f"⚠️ 기사 요약 중 오류 발생 (건너뜁니다): {self._clean_title(article['title'])} - {e}")
                    continue
        else:
            print("-> 새로운 뉴스를 찾지 못했습니다.")

        return {
            "topic": query,
            "articles": articles_for_export
        }

    # '갱신' 시 호출: 데이터를 생성하고 파일에 저장
    def run_workflow(self, query, target_count=10):
        if not self.file_path:
            print("❌ NewsManager: 파일 경로가 지정되지 않아 'run_workflow'를 실행할 수 없습니다.")
            return

        output_data = self._create_news_data_dict(query, target_count)
        date_str = self._get_logical_date_obj().strftime("%Y-%m-%d")
        output_filename = os.path.join(self.file_path, f"news_summary_{date_str}.json")
        
        try:
            with open(output_filename, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, ensure_ascii=False, indent=4)
            print(f"✅ '{output_filename}' 파일로 뉴스 정보 저장을 완료했습니다.")
        except Exception as e:
            print(f"❌ 최종 JSON 파일 저장 중 심각한 오류가 발생했습니다: {e}")

    # '확인' 시 호출: 데이터를 생성만 하고 파일에 저장하지 않음
    def get_temporary_news(self, query, target_count=10):
        print("-> 임시 뉴스 정보를 조회합니다 (파일 저장 안 함).")
        return self._create_news_data_dict(query, target_count)
    
    # 뉴스 기록 초기화
    def clear_today_seen_topics(self):
        if not self.file_path:
            print("-> 임시 모드에서는 뉴스 기록을 초기화할 수 없습니다.")
            return
            
        filepath = self._get_logical_date_filepath()
        try:
            if os.path.exists(filepath):
                os.remove(filepath)
                print(f"✅ '{filepath}' 파일을 삭제하여 뉴스 주제 기억을 초기화했습니다.")
            else:
                print("-> 삭제할 뉴스 기억 파일이 없습니다.")
        except Exception as e:
            print(f"❌ 뉴스 기억 파일 삭제 중 오류 발생: {e}")