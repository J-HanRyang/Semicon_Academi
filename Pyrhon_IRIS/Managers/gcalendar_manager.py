import os  # 파일/경로 존재 여부 확인 및 입출력 유틸 사용
import html  # 텍스트를 HTML로 이스케이프하기 위한 유틸 함수 제공
import re  # 패턴 매칭과 파싱을 위한 정규표현식 엔진 사용
import datetime as dt  # 날짜/시간 처리와 타임존 연산을 위한 표준 모듈 사용
from typing import Optional, Dict, Any, Tuple  # 정적 분석과 가독성을 위한 타입 힌트 사용

from google.oauth2.credentials import Credentials  # 저장된 OAuth2 자격 증명 로드/검증/사용
from googleapiclient.discovery import build  # Google API 서비스 클라이언트를 동적으로 생성
from google_auth_oauthlib.flow import InstalledAppFlow  # 설치형 앱의 OAuth 동의 플로우 수행
from google.auth.transport.requests import Request  # 토큰 갱신 시 HTTP 전송을 담당하는 어댑터

SCOPES = ["https://www.googleapis.com/auth/calendar.events"]  # 캘린더 이벤트 읽기/쓰기 권한 스코프 지정
KST = dt.timezone(dt.timedelta(hours=9))  # 한국 표준시(+09:00) 타임존 객체 생성
WX_MARK = "1"  # 날씨 일정임을 식별하기 위한 private extended property의 값


class GCalendarManager:  # 구글 캘린더에 날씨 일정을 생성/수정/삭제하는 매니저 클래스 선언
    def __init__(self, calendar_id: str = "primary"):  # 매니저 인스턴스 초기화(대상 캘린더 선택)
        self.calendar_id = calendar_id  # 조작 대상 캘린더 ID를 보관(기본: 사용자 기본 캘린더)
        self.service = self._get_calendar_service()  # 인증을 완료하고 Calendar API 서비스 핸들을 준비

    def _get_calendar_service(self):  # 구글 캘린더 API 클라이언트를 생성/반환하는 내부 유틸리티
        creds = None  # 자격 증명 객체를 보관할 변수 초기화
        if os.path.exists("token.json"):  # 기존에 발급받은 사용자 토큰 파일이 존재하는지 확인
            creds = Credentials.from_authorized_user_file("token.json", SCOPES)  # 토큰 파일을 로드해 Credentials 객체 생성
        if not creds or not creds.valid:  # 토큰이 없거나 유효하지 않은 경우 재발급/갱신 필요 판단
            if creds and creds.expired and creds.refresh_token:  # 만료되었지만 refresh_token이 있으면 자동 갱신 경로 사용
                creds.refresh(Request())  # HTTP 요청을 통해 액세스 토큰을 새로 고침
            else:  # 토큰이 없거나 갱신 불가한 경우 브라우저 동의 플로우 수행
                if not os.path.exists("credentials.json"):  # 클라이언트 비밀키 파일이 없으면 구성 오류로 간주
                    raise FileNotFoundError("Google Cloud 인증 파일(credentials.json)을 찾을 수 없습니다.")  # 설정 누락을 명확히 알림
                flow = InstalledAppFlow.from_client_secrets_file("credentials.json", SCOPES)  # OAuth 클라이언트 정보를 로드하여 플로우 생성
                creds = flow.run_local_server(port=0)  # 로컬 웹서버를 열어 사용자 브라우저로 인증/동의 진행
            with open("token.json", "w", encoding="utf-8") as f:  # 신규 또는 갱신된 토큰을 로컬에 안전하게 보관
                f.write(creds.to_json())  # Credentials를 JSON 문자열로 직렬화하여 저장
        return build("calendar", "v3", credentials=creds)  # 인증된 Credentials로 Calendar v3 서비스 인스턴스를 생성/반환

    def _find_event_for_date(self, for_date: dt.date) -> Optional[Dict[str, Any]]:  # 특정 날짜에 해당하는 날씨 이벤트 1건을 조회
        time_min = dt.datetime.combine(for_date, dt.time.min, tzinfo=KST).isoformat()  # 조회 시작 시각을 해당 날짜 00:00:00(+09:00)로 설정
        time_max = dt.datetime.combine(for_date, dt.time.max, tzinfo=KST).isoformat()  # 조회 종료 시각을 해당 날짜 23:59:59.999999(+09:00)로 설정
        try:  # API 호출 중 예외 발생을 포착하기 위한 보호 블록 시작
            events_result = self.service.events().list(  # 이벤트 목록 조회 메서드 체이닝 시작
                calendarId=self.calendar_id,  # 대상 캘린더 지정
                timeMin=time_min,  # 기간 필터: 시작 시각
                timeMax=time_max,  # 기간 필터: 종료 시각
                singleEvents=True,  # 반복 이벤트를 개별 인스턴스로 확장하여 반환하도록 지정
                privateExtendedProperty=[f"wx={WX_MARK}", f"for_date={for_date.isoformat()}"],  # 확장 속성 필터로 날씨표식/대상날짜가 일치하는 이벤트만 검색
            ).execute()  # 요청 전송 및 결과 수신
            items = events_result.get("items", [])  # 응답에서 이벤트 리스트를 안전하게 추출(없으면 빈 리스트)
            return items[0] if items else None  # 첫 번째 일치 항목을 반환하거나 없으면 None 반환
        except Exception as e:  # 네트워크/권한/파라미터 오류 등 모든 예외 포착
            print(f"  -> 캘린더 이벤트 조회 중 오류 발생: {e}")  # 디버깅을 위해 오류 메시지를 표준 출력에 남김
            return None  # 실패 시 일관되게 None 반환하여 상위 로직이 분기 처리할 수 있게 함

    def _to_html_description(self, description: str) -> str:
        lines = description.splitlines()
        parts: list[str] = []

        for line in lines:
            if not line.strip():
                # 빈 줄은 <br>로 처리하여 줄바꿈을 명확하게 표현
                parts.append("<br>")
            else:
                # 각 줄을 <div> 태그로 감싸고, HTML 이스케이프 처리
                parts.append(f"<div>{html.escape(line)}</div>")

        return "".join(parts)

    def _add_event(self, summary: str, description: str,  # 새 캘린더 이벤트를 생성하고 ID를 반환
                   start_time: dt.datetime, end_time: dt.datetime) -> str:  # 시작/종료 시각을 받아 정확한 일정 생성
        if not summary or not description:  # 제목 또는 설명이 비어 있으면
            raise ValueError("summary/description이 비었습니다.")  # 명확한 예외를 던져 호출자에게 입력 오류 알림
        desc_html = self._to_html_description(description)  # 설명 텍스트를 HTML로 변환하여 표와 줄바꿈을 적용

        event = {  # Google Calendar API가 요구하는 이벤트 본문을 구성
            "summary": summary,  # 일정 제목 설정
            "description": desc_html,  # HTML 변환된 본문을 저장(리치 텍스트 표현)
            "start": {"dateTime": start_time.isoformat(), "timeZone": "Asia/Seoul"},  # 시작 시각과 타임존 명시
            "end":   {"dateTime": end_time.isoformat(),   "timeZone": "Asia/Seoul"},  # 종료 시각과 타임존 명시
            "transparency": "transparent",  # 바쁨 상태를 차단하지 않도록 투명 처리
            "reminders": {"useDefault": False, "overrides": [{"method": "popup", "minutes": 0}]},  # 기본 리마인더 대신 즉시 팝업 알림 설정
            "extendedProperties": {"private": {"wx": WX_MARK, "for_date": start_time.date().isoformat()}},  # 커스텀 메타로 날씨표식/대상날짜 저장
        }  # 이벤트 본문 구성 완료
        created = self.service.events().insert(calendarId=self.calendar_id, body=event).execute()  # Calendar API로 이벤트를 생성 요청하고 응답 수신
        return created.get("id")  # 생성된 이벤트의 고유 ID를 반환하여 추후 수정/삭제에 사용 가능

    def _delete_event(self, event_id: str) -> None:  # 주어진 이벤트 ID를 가진 일정을 삭제
        self.service.events().delete(calendarId=self.calendar_id, eventId=event_id).execute()  # Calendar API 호출로 일정 제거 수행

    def _get_today_time_block(self) -> Tuple[dt.datetime, dt.datetime]:  # 오늘 날짜 안에서 시작 시각을 0/6/12/18시로 스냅하여 30분 블록 계산
        now = dt.datetime.now(KST)  # 현재 KST 시각을 획득
        if   now.hour >= 18: start_hour = 18  # 현재 시간이 18시 이후면 18시 블록 선택
        elif now.hour >= 12: start_hour = 12  # 12~17시는 12시 블록 선택
        elif now.hour >=  6: start_hour =  6  # 6~11시는 6시 블록 선택
        else:                start_hour =  0  # 0~5시는 0시 블록 선택
        start_dt = now.replace(hour=start_hour, minute=0, second=0, microsecond=0)  # 블록 시작을 해당 정시로 맞춤
        end_dt = start_dt + dt.timedelta(minutes=30)  # 블록 종료를 시작으로부터 30분 뒤로 설정
        return start_dt, end_dt  # (시작, 종료) 튜플을 반환하여 일정 생성 시 사용

    def upsert_today(self, summary: str, description: str):  # 오늘 일정이 있으면 삭제 후 최신 내용으로 재생성
        today = dt.datetime.now(KST).date()  # 오늘 날짜(KST 기준)를 획득
        print(f"\n[TODAY] 오늘({today}) 날씨 일정을 최신화합니다.")  # 동작 로그를 콘솔에 출력
        existing = self._find_event_for_date(today)  # 오늘 날짜에 해당하는 기존 날씨 이벤트 조회
        if existing:  # 기존 이벤트가 존재하면
            self._delete_event(existing["id"])  # 해당 이벤트를 삭제하여 중복을 방지
            print(f"  -> 기존 오늘 일정(ID: {existing['id']}) 삭제")  # 삭제 완료 로그 출력
        start_dt, end_dt = self._get_today_time_block()  # 현재 시간대에 맞는 30분 블록을 계산
        new_id = self._add_event(summary, description, start_dt, end_dt)  # 계산된 블록으로 새 이벤트를 생성
        print(f"  -> ✅ 오늘 일정 {start_dt.strftime('%H:%M')}에 생성 (ID: {new_id})")  # 생성된 일정의 시각과 ID를 로그로 안내

    def upsert_tomorrow_06(self, summary: str, description: str):  # 내일 06:00 고정 시간으로 일정을 재생성
        tomorrow = dt.datetime.now(KST).date() + dt.timedelta(days=1)  # 내일 날짜(KST 기준)를 계산
        print(f"\n[TOMORROW] 내일({tomorrow}) 06:00 날씨 일정을 최신화합니다.")  # 진행 로그 출력
        existing = self._find_event_for_date(tomorrow)  # 내일 날짜의 기존 날씨 이벤트 조회
        if existing:  # 기존 이벤트가 있으면
            self._delete_event(existing["id"])  # 먼저 삭제하여 중복 생성 방지
            print("  -> 기존 내일 일정 삭제")  # 삭제 로그 출력
        start_dt = dt.datetime.combine(tomorrow, dt.time(6, 0), tzinfo=KST)  # 내일 06:00 시작 시각을 생성
        end_dt = start_dt + dt.timedelta(minutes=30)  # 30분 길이의 블록으로 종료 시각 계산
        new_id = self._add_event(summary, description, start_dt, end_dt)  # 설정된 시간으로 새 이벤트 생성
        print(f"  -> ✅ 내일 06:00 일정 생성 (ID: {new_id})")  # 생성된 이벤트 ID를 로그로 안내

    def cleanup_yesterday_weather(self):  # 어제 날짜의 날씨 일정이 남아 있으면 정리(삭제)
        yesterday = dt.datetime.now(KST).date() - dt.timedelta(days=1)  # 어제 날짜(KST 기준)를 계산
        print(f"\n[CLEANUP] 어제({yesterday}) 날씨 일정 정리")  # 정리 작업 로그 출력
        event = self._find_event_for_date(yesterday)  # 어제 날짜의 기존 날씨 이벤트 존재 여부 확인
        if event:  # 이벤트가 존재하면
            self._delete_event(event["id"])  # 해당 이벤트를 삭제하여 오래된 정보 제거
            print("  -> 어제 일정을 삭제했습니다.")  # 삭제 결과 로그 출력
        else:  # 존재하지 않으면
            print("  -> 정리할 어제 일정이 없습니다.")  # 할 일이 없음을 알리는 로그 출력

    def sync_weather_event_for_tomorrow(self, summary: str, description: str):  # 과거 하위 호환 API 이름을 현재 동작으로 매핑
        self.upsert_tomorrow_06(summary, description)  # (구) 내일 일정 생성 요청을 내일 06:00 생성 로직으로 위임


CalendarManager = GCalendarManager  # 하위 호환을 위해 예전 import 이름(CalendarManager)을 현재 클래스에 바인딩