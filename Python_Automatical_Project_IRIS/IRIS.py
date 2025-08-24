# 표준 라이브러리
import configparser
import datetime as dt
from flask import Flask, render_template

# 로컬 매니저
from Managers.ai_manager import GeminiSummarizer
from Managers.gcalendar_manager import CalendarManager
from Managers.news_manager import NewsManager
from Managers.report_manager import ReportManager
from Managers.sender_manager import SenderManager
from Managers.weather_manager import WeatherManager

KST = dt.timezone(dt.timedelta(hours=9))

# 메일 및 보고서 시간별 제목
def get_iris_subject(part = ""):
    date_str = dt.datetime.now().strftime('%y_%m_%d')
    current_hour = dt.datetime.now().hour
    
    if 5 <= current_hour < 12:
        subject = f"🌅 IRIS Morning Briefing | {date_str} 오늘을 여는 소식"
    elif 12 <= current_hour < 18:
        subject = f"💡 IRIS Afternoon Briefing | {date_str} 활력을 더해 줄 정보"
    elif 18 <= current_hour < 23:
        subject = f"✨ IRIS Evening Briefing | {date_str} 편안한 밤을 위한 이야기"
    else:
        subject = f"🌙 IRIS Night Briefing | {date_str} 내일을 준비하는 통찰력"
        
    if part == 'report':
        return subject.split('|')[0].strip()
    elif part == 'mail':
        return subject.split('|')[1].strip()
    else:
        return subject
        
def run_news_briefing():
    # ... (설정 로드 및 매니저 구성 부분은 동일) ...
    print("🕊️ 이리스!, 작업을 시작합니다!")

    try:
        config = configparser.ConfigParser()
        config.read('config.ini', encoding='utf-8')
        
        naver_client_id = config['API']['NAVER_API_KEY']
        naver_client_secret = config['API']['NAVER_API_PW']
        search_query = config['USER']['news_keyword']
        target_count = int(config['USER']['target_news_count'])
        file_path = config['PATHS']['output_directory']

        weather_api_key = config['API']["WEATHER_API_KEY"]
        target_city = config['USER']['target_city']

        gemini_api_key = config['API']['GOOGLE_GEMINI_API_KEY']
        
        sender_email = config['EMAIL']['SENDER_EMAIL']
        sender_password = config['EMAIL']['SENDER_PASSWORD']
        target_email = config['USER']['target_email']
        smtp_server = config['EMAIL']['SMTP_SERVER']
        smtp_port = int(config['EMAIL']['SMTP_PORT'])

        web_url = config['PATHS']['web_url']

    except Exception as e:
        print(f"❌ 설정 파일(config.ini)을 읽는 중 오류가 발생했습니다: {e}")
        return

    # 전문가 팀(매니저 객체)을 구성
    try:
        ai_summarizer = GeminiSummarizer(api_key=gemini_api_key)
        news_manager = NewsManager( naver_client_id, naver_client_secret, ai_summarizer, file_path )
        weather_manager = WeatherManager( weather_api_key, target_city, file_path, ai_summarizer )
        report_manager = ReportManager( file_path, web_url )
        sender_manager = SenderManager( smtp_server, smtp_port, sender_email, sender_password )
        gcalendar_manager = CalendarManager()

    except Exception as e:
        print(f"❌ 전문가 팀을 구성하는 중 오류가 발생했습니다: {e}")
        return

    # 요약 및 보고서 생성 워크플로우를 실행
    try:
        # 1) NewsManager에게 뉴스 요약 작업을 지시
        news_manager.run_workflow(query=search_query, target_count=target_count)

        # 2) WeatherManager에게 날씨 정보 수집 요구
        now = dt.datetime.now(KST)
        today = now.date()
        tomorrow = today + dt.timedelta(days=1)

        weather_manager.run_workflow(today)

        # 오늘 일정 업데이트
        _, today_summary, today_desc = weather_manager.run_workflow(today)
        gcalendar_manager.upsert_today(today_summary, today_desc)

        # 내일 06:00 일정 생성
        if now.hour >= 12:
            _, tom_summary, tom_desc = weather_manager.run_workflow(tomorrow)
            gcalendar_manager.upsert_tomorrow_06(tom_summary, tom_desc)

    except Exception as e:
        print(f"❌ 데이터 생성 중 오류가 발생했습니다: {e}")
        return
    
    # [수정] 이메일 발송 로직: Flask 템플릿을 사용하여 HTML 생성
    try:
        app = Flask(__name__, template_folder='templates') # 이메일 템플릿을 위해 Flask 앱 컨텍스트 사용
        with app.app_context():
            report_subject = get_iris_subject(part='report')
            briefing_data = report_manager.get_briefing_data(subject=report_subject)
            if not briefing_data.get("news_data") and not briefing_data.get("weather_data"):
                print("❌ 오류: 이메일로 보낼 데이터가 없습니다.")
                return 

            html_body = render_template('email_briefing.html', data=briefing_data)
        
        mail_subject = get_iris_subject(part='mail')
        sender_manager.send_email(receiver_email=target_email, subject=mail_subject, body=html_body)

    except Exception as e:
        print(f"❌ 메일 전송 중 오류가 발생했습니다: {e}")

if __name__ == "__main__":
    run_news_briefing()