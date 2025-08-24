import os
from flask import Flask, request, render_template, jsonify, session
import configparser
import datetime as dt

from Managers.ai_manager import GeminiSummarizer
from Managers.news_manager import NewsManager
from Managers.weather_manager import WeatherManager
from Managers.report_manager import ReportManager
from Managers.sender_manager import SenderManager

app = Flask(__name__, template_folder='templates')
# [추가] 세션 기능을 사용하기 위해 시크릿 키를 반드시 설정해야 합니다.
app.secret_key = os.urandom(24)

CITIES = {
    'Seoul': '서울특별시', 'Busan': '부산광역시', 'Incheon': '인천광역시',
    'Daegu': '대구광역시', 'Gwangju': '광주광역시', 'Daejeon': '대전광역시',
    'Ulsan': '울산광역시', 'Sejong': '세종특별자치시', 'Suwon': '수원시, 경기도',
    'Chuncheon': '춘천시, 강원도', 'Cheongju': '청주시, 충청북도', 'Jeonju': '전주시, 전라북도',
    'Changwon': '창원시, 경상남도', 'Andong': '안동시, 경상북도', 'Jeju': '제주시, 제주특별자치도'
}

CONFIG_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.ini')

def get_config():
    config = configparser.ConfigParser()
    config.read(CONFIG_PATH, encoding='utf-8')
    return config

def update_config_file(section, key, value):
    config = get_config()
    config.set(section, key, value)
    with open(CONFIG_PATH, 'w', encoding='utf-8') as configfile:
        config.write(configfile)
    print(f"✅ config.ini 업데이트 완료: [{section}] {key} = {value}")

def get_iris_subject(part=""):
    date_str = dt.datetime.now().strftime('%y_%m_%d')
    current_hour = dt.datetime.now().hour
    if 5 <= current_hour < 12: subject = f"🌅 IRIS Morning Briefing | {date_str} 오늘을 여는 소식"
    elif 12 <= current_hour < 18: subject = f"💡 IRIS Afternoon Briefing | {date_str} 활력을 더해 줄 정보"
    elif 18 <= current_hour < 23: subject = f"✨ IRIS Evening Briefing | {date_str} 편안한 밤을 위한 이야기"
    else: subject = f"🌙 IRIS Night Briefing | {date_str} 내일을 준비하는 통찰력"
    if part == 'report': return subject.split('|')[0].strip()
    return subject

@app.route('/')
def index():
    # [수정] 처음 접속 시에는 세션을 비워 새로운 정보를 불러오게 합니다.
    session.pop('briefing_data', None)
    config = get_config()
    keyword = config['USER']['news_keyword']
    city = config['USER']['target_city']
    return process_briefing(keyword, city, config, update_type='all', action='initial_load')

@app.route('/results', methods=['POST'])
def results():
    config = get_config()
    update_type = request.form.get('update_type')
    action = request.form.get('action')
    keyword = request.form.get('news_keywords')
    city = request.form.get('weather_location')

    if action == 'update_config':
        if update_type == 'news' and keyword:
            update_config_file('USER', 'news_keyword', keyword)
        elif update_type == 'weather' and city:
            update_config_file('USER', 'target_city', city)
    
    return process_briefing(keyword, city, config, update_type=update_type, action=action)

# [핵심 수정] process_briefing 함수 전체 로직 변경
def process_briefing(keyword, city, config, update_type=None, action=None):
    try:
        output_path = config['PATHS']['output_directory']
        naver_client_id = config['API']['NAVER_API_KEY']
        naver_client_secret = config['API']['NAVER_API_PW']
        weather_api_key = config['API']["WEATHER_API_KEY"]
        gemini_api_key = config['API']['GOOGLE_GEMINI_API_KEY']
        target_news_count = int(config['USER']['target_news_count'])
        ai_summarizer = GeminiSummarizer(api_key=gemini_api_key)

        # 1. 세션에서 기존 데이터를 불러오고, 없으면 파일에서 새로 가져옵니다.
        briefing_data = session.get('briefing_data')
        if not briefing_data or action == 'initial_load':
            print("-> 세션 데이터가 없거나 초기 로드입니다. 파일에서 데이터를 로드합니다.")
            report_manager = ReportManager(file_path=output_path, web_url=config['PATHS']['web_url'])
            report_subject = get_iris_subject(part='report')
            briefing_data = report_manager.get_briefing_data(subject=report_subject)

        # 2. '확인' 버튼: 요청한 부분만 임시로 빠르게 갱신합니다.
        if action == 'confirm':
            if update_type == 'weather':
                print(f"-> 날씨 임시 갱신: {city}")
                weather_manager = WeatherManager(weather_api_key, city, "", ai_summarizer)
                temp_weather = weather_manager.get_temporary_weather()
                if temp_weather: briefing_data['weather_data'] = temp_weather
            elif update_type == 'news':
                print(f"-> 뉴스 임시 갱신: {keyword}")
                news_manager = NewsManager(naver_client_id, naver_client_secret, ai_summarizer, "")
                temp_news = news_manager.get_temporary_news(query=keyword, target_count=target_news_count)
                if temp_news and temp_news['articles']:
                    briefing_data['news_data'] = temp_news['articles']
                    briefing_data['topic'] = temp_news['topic']

        # 3. '갱신' 버튼: 파일을 영구 저장하고, 파일 기준의 최신 정보로 전체를 다시 불러옵니다.
        if action == 'update_config':
            if update_type == 'weather':
                print(f"-> 날씨 설정 저장: {city}")
                weather_manager = WeatherManager(weather_api_key, city, output_path, ai_summarizer)
                weather_manager.run_workflow(target_date=dt.datetime.now().date())
            elif update_type == 'news':
                print(f"-> 뉴스 설정 저장: {keyword}")
                news_manager = NewsManager(naver_client_id, naver_client_secret, ai_summarizer, output_path)
                news_manager.run_workflow(query=keyword, target_count=target_news_count)
            
            print("-> 설정 저장이 완료되어 파일에서 데이터를 다시 로드합니다.")
            report_manager = ReportManager(file_path=output_path, web_url=config['PATHS']['web_url'])
            report_subject = get_iris_subject(part='report')
            briefing_data = report_manager.get_briefing_data(subject=report_subject)

        # 4. 최종 데이터를 세션에 저장합니다.
        session['briefing_data'] = briefing_data

        # 5. 화면을 렌더링합니다.
        form_data = {"current_keyword": keyword, "current_city": city, "cities_map": CITIES}
        return render_template('web_briefing.html', data=briefing_data, form=form_data, config=config)

    except Exception as e:
        print(f"Error in process_briefing: {e}")
        return f"<h1>오류가 발생했습니다.</h1><p>{e}</p><a href='/'>돌아가기</a>"
    
@app.route('/api/force_refresh_news', methods=['POST'])
def refresh_and_confirm():
    print("🔄 새로고침(삭제+확인) 요청을 받았습니다...")    

    try:
        config = get_config()
        ai_summarizer = GeminiSummarizer(api_key=config['API']['GOOGLE_GEMINI_API_KEY'])
        news_manager = NewsManager(
            naver_client_id=config['API']['NAVER_API_KEY'],
            naver_client_secret=config['API']['NAVER_API_PW'],
            summarizer=ai_summarizer,
            file_path=config['PATHS']['output_directory']
        )
        news_manager.clear_today_seen_topics()
        keyword = config['USER']['news_keyword']
        count = int(config['USER']['target_news_count'])
        new_news_data = news_manager.get_temporary_news(query=keyword, target_count=count)
        return jsonify({'status': 'success', 'data': new_news_data})

    except Exception as e:
        print(f"❌ API 강제 새로고침 중 오류 발생: {e}")
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/send_email', methods=['POST'])
def api_send_email():
    print("📧 API를 통한 이메일 발송 요청을 받았습니다...")
    try:
        briefing_data = request.get_json()
        receiver_email = briefing_data.pop('receiver_email', None)
        if not receiver_email:
            return jsonify({'status': 'error', 'message': '이메일 주소를 입력해주세요.'})
        config = get_config()
        sender_manager = SenderManager(
            smtp_server=config['EMAIL']['SMTP_SERVER'],
            smtp_port=int(config['EMAIL']['SMTP_PORT']),
            sender_email=config['EMAIL']['SENDER_EMAIL'],
            sender_password=config['EMAIL']['SENDER_PASSWORD']
        )
        html_body = render_template('email_briefing.html', data=briefing_data)
        mail_subject = get_iris_subject(part='mail')
        sender_manager.send_email(receiver_email=receiver_email, subject=mail_subject, body=html_body)
        return jsonify({'status': 'success', 'message': f'{receiver_email}로 브리핑을 성공적으로 발송했습니다.'})

    except Exception as e:
        print(f"❌ API 이메일 발송 중 오류 발생: {e}")
        return jsonify({'status': 'error', 'message': str(e)})

if __name__ == "__main__" :
    app.run(host="0.0.0.0", port = 5000)