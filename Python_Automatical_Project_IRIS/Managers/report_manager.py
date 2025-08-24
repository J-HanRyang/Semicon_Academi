import json
import os
from datetime import datetime, timedelta

class ReportManager:
    def __init__(self, file_path, web_url="", cutoff_hour=6):
        self.file_path = file_path
        self.web_url = web_url
        # [추가] NewsManager와 동일한 기준 시간을 설정
        self.CUTOFF_HOUR = cutoff_hour

    # [추가] NewsManager와 동일한 날짜 계산 함수
    def _get_logical_date_obj(self):
        now = datetime.now()
        if now.hour < self.CUTOFF_HOUR:
            return (now - timedelta(days=1)).date()
        else:
            return now.date()

    def get_briefing_data(self, subject=""):
        # [수정] 위에서 만든 함수를 사용하여 오늘 날짜 문자열 생성
        today_str = self._get_logical_date_obj().strftime('%Y-%m-%d')
        
        news_filename = os.path.join(self.file_path, f"news_summary_{today_str}.json")
        weather_filename = os.path.join(self.file_path, 'weather_data.json')
        
        news_articles, weather_data = [], None
        final_topic = "뉴스"
        
        try:
            with open(news_filename, 'r', encoding='utf-8') as f:
                news_data_json = json.load(f)
                final_topic = news_data_json.get('topic', '주제 없음')
                news_articles_raw = news_data_json.get('articles', [])
                
                for article in news_articles_raw:
                    try:
                        pub_date = datetime.strptime(article['publication_date'], '%a, %d %b %Y %H:%M:%S %z')
                        article['formatted_date'] = pub_date.strftime('%Y-%m-%d %H:%M')
                    except (ValueError, KeyError):
                        article['formatted_date'] = "날짜 정보 없음"
                news_articles = news_articles_raw
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Warning: 뉴스 데이터를 불러오는 데 실패했습니다. ({e})")

        try:
            with open(weather_filename, 'r', encoding='utf-8') as f:
                weather_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Warning: 날짜 데이터를 불러오는 데 실패했습니다. ({e})")

        display_title = subject if subject else f"{final_topic} 브리핑"

        return {
            "display_title": display_title,
            "topic": final_topic,
            "web_url": self.web_url,
            "news_data": news_articles,
            "weather_data": weather_data,
            "current_time_str": datetime.now().strftime('%H:%M')
        }