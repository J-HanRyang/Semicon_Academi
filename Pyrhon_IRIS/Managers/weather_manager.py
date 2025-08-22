# ------------------ 표준 라이브러리 ------------------
import datetime as dt
import json
import os
from typing import Any, Dict, List, Optional, Tuple

# ------------------ 서드 파티 라이브러리 ------------------
import requests
from pytz import timezone

# 시간대 상수 정의
KST = timezone("Asia/Seoul")
UTC = timezone("UTC")

class WeatherManager:
    EMOJI = {
        "Rain"   : "🌧️", "Drizzle": "🌦️", "Thunderstorm": "⛈️", "Snow" : "❄️",
        "Clear"  : "☀️", "Clouds" : "☁️",         "Mist": "🌫️", "Fog"  : "🌫️",
        "Haze"   : "🌫️", "Dust"   : "🌫️",         "Sand": "🌫️", "Smoke": "🌫️",
        "Squall" : "💨", "Tornado": "🌪️"
    }
    ADVICE = {
        "Rain"   : "우산 챙기기", "Drizzle" : "우산 챙기기", "Thunderstorm" : "우산 챙기기", "Snow"  : "빙판 주의·따뜻하게",
        "Clear"  : "양산 챙기기", "Clouds"  : "겉옷 챙기기",         "Mist" : "안전운전",    "Fog"   : "안전운전",
        "Haze"   : "마스크 권장", "Dust"    : "마스크 권장",         "Sand" : "마스크 권장", "Smoke" : "마스크 권장",
        "Squall" : "강풍 주의",   "Tornado" : "실내 대피"
    }

    def __init__(self, weather_api_key: str, target_city: str, file_path: str, summarizer: Any):
        self.api_key = weather_api_key
        self.city_name = target_city
        self.file_path = file_path
        self.summarizer = summarizer
        self.KST = KST
        self.coords = self._get_coords_for_location(self.city_name)

    # ==============================================================================
    # 1. 자동화/이메일/캘린더를 위한 메인
    # ==============================================================================
    def run_workflow(self, target_date: dt.date) -> Tuple[str, str]:
        """
        [자동화용] 실시간 날씨와 24시간 예보를 결합하여 최종 JSON을 생성하고 저장합니다.
        """
        if not self.coords:
            print(f"❌ '{self.city_name}'의 좌표를 찾을 수 없어 날씨 작업을 중단합니다.")
            return None

        # 1. 실시간 날씨 데이터 가져오기 (메인)
        main_weather_data = self._get_current_weather()
        if not main_weather_data:
            print("❌ 실시간 날씨 데이터를 가져오는 데 실패했습니다. 작업을 중단합니다.")
            return None

        # 2. 24시간 예보 데이터 가져오기 (서브)
        hourly_forecasts = rain_slots, hourly_forecasts = self._process_24h_forecast()
        current_forecast = self._get_current_weather()
        print(rain_slots)

        if not hourly_forecasts:
            print("❌ 24시간 예보 정보가 없어 작업을 중단합니다.")
            return None

        # 3. AI 코멘트 생성 (24시간 예보를 바탕으로)
        ai_comment = self._get_ai_weather_comment(current_forecast, hourly_forecasts)
        print(f"-> AI 한마디: {ai_comment}")

        # 4. 브리핑 텍스트 생성 (실시간 날씨를 바탕으로)
        status = main_weather_data.get('status')
        temp = main_weather_data.get('temp')
        humi = main_weather_data.get('humi')
        
        icon = self.EMOJI.get(status, '🌍')
        advice = self.ADVICE.get(status, '좋은 하루!')

        # 3. 캘린더 매니저용 요약(Summary)과 설명(Description) 생성
        summary = ""
        description = ""

        is_today = target_date == dt.datetime.now(self.KST).date()

        if is_today:
            # '오늘' 모드: 실시간 날씨와 이후 9시간 예보를 바탕으로 생성
            status = main_weather_data.get('status')
            temp = main_weather_data.get('temp')
            humi = main_weather_data.get('humi')
            
            # 이후 9시간(3개 예보)의 비 예보 정보만 추출
            rain_slots_9h = {}
            for h, rain_mm in rain_slots.items():
                forecast_time = dt.datetime.now(self.KST).replace(hour=h, minute=0, second=0, microsecond=0)
                if forecast_time < dt.datetime.now(self.KST) + dt.timedelta(hours=9):
                    rain_slots_9h[h] = rain_mm

            rain_info_text = self._format_rain_info(rain_slots_9h, is_update=True)
            advice = self.ADVICE.get(status, '좋은 하루!')

            summary = f"{self.EMOJI.get(status, '🌍')} 오늘의 날씨 · {status}"
            description = (f"날씨: {status}\n온도: {temp:.1f}°C\n습도: {humi}%\n{rain_info_text}\n\n"
                           f"메모: {advice}\n\n"
                           f"< 최신정보 업데이트 완료 ({dt.datetime.now(self.KST).strftime('%H:%M')}) >")
        else:
            # '내일' 모드: 내일 24시간 예보 중 비 예보만 추출하여 생성
            raw_data = self._fetch_raw_data()
            target_str = target_date.strftime("%Y-%m-%d")
            filtered_forecasts = [item for item in raw_data["list"] if item["dt_txt"].startswith(target_str)]

            if not filtered_forecasts:
                return "내일 날씨 없음", "내일 예보 정보가 없습니다."

            snapshot = filtered_forecasts[0]
            status = snapshot["weather"][0]["main"]
            
            rain_slots_tomorrow = {}
            for item in filtered_forecasts:
                if self._is_rainy_strict(item):
                    hour = int(item["dt_txt"].split(" ")[1][:2])
                    rain3h = float(item.get("rain", {}).get("3h", 0) or 0)
                    if rain3h > 0:
                        rain_slots_tomorrow[hour] = rain3h
            
            title = f"{self.EMOJI.get(status, '🌍')} 내일의 날씨"
            
            # 비 예보만 포함된 상세 설명 생성
            if rain_slots_tomorrow:
                rain_text_list = [
                    f"- {h:02d}시부터: 약 {rain_slots_tomorrow[h]:.1f}mm" for h in sorted(rain_slots_tomorrow.keys())
                ]
                description = "내일 비 예보:\n" + "\n".join(rain_text_list)
            else:
                description = "내일 비 예보 없음. 맑은 하루가 예상돼요."

            summary = title

        # 5. 최종 데이터 구조화
        full_weather_data = {
            "city": self.city_name,
            "ai_comment": ai_comment,
            "current_weather": main_weather_data,
            "forecasts": hourly_forecasts
        }
    
        # 6. 파일 저장
        if self.file_path:
            os.makedirs(self.file_path, exist_ok=True)
            output_path = os.path.join(self.file_path, "weather_data.json")
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(full_weather_data, f, ensure_ascii=False, indent=4)
            print(f"-> '{output_path}' 파일에 상세 날씨 정보를 저장했습니다.")

        return full_weather_data, summary, description

    # ==============================================================================
    # 2. 웹 실시간용 메인
    # ==============================================================================
    def get_web_weather_data(self) -> Optional[Dict[str, Any]]:
        """
        [웹 전용] 파일 저장 없이 '현재 날씨'와 '24시간 예보' 데이터를
        run_workflow와 동일한 구조로 즉시 반환합니다.
        """
        if not self.coords: return None
        
        current_weather = self._get_current_weather()
        if not current_weather: return None

        _, hourly_forecasts = self._process_24h_forecast()
        if not hourly_forecasts: return None
        
        ai_comment = self._get_ai_weather_comment(current_weather, hourly_forecasts)

        return {
            "city": self.city_name,
            "ai_comment": ai_comment,
            "current_weather": current_weather,
            "forecasts": hourly_forecasts
        }
    
    # ==============================================================================
    # 3. 내부 실행 함수
    # ==============================================================================
    
    # ----------- 좌표 변환 API -----------
    def _get_coords_for_location(self, location_name: str) -> Optional[Tuple[float, float]]:
        try:
            url = f"http://api.openweathermap.org/geo/1.0/direct?q={location_name}&limit=1&appid={self.api_key}"
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            if data:
                return data[0]['lat'], data[0]['lon']
            else:
                print(f"❌ '{location_name}'의 좌표를 찾을 수 없습니다.")
                return None
        except Exception as e:
            print(f"❌ 좌표를 가져오는 중 오류 발생: {e}")
            return None

    # ----------- 실시간 날씨 API -----------
    def _get_current_weather(self) -> Optional[Dict[str, Any]]:
        if not self.coords: return None
        lat, lon = self.coords
        
        try:
            url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={self.api_key}&units=metric&lang=kr"
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
            status = data['weather'][0]['main']
            return {
                "city": data.get('name', self.city_name),
                "status": status,
                "temp": data['main'].get('temp'),
                "humi": data['main'].get('humidity'),
                "description": data['weather'][0].get('description'),
                "emoji": self.EMOJI.get(status, "🌍")
            }
        except Exception as e:
            print(f"❌ 실시간 날씨 데이터 가져오는 중 오류: {e}")
            return None
    
    # ----------- 3시간 단위 날씨 API -----------
    def _fetch_raw_data(self) -> Optional[Dict[str, Any]]:
        if not self.coords: return None
        lat, lon = self.coords
        
        try:
            url = f"http://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={self.api_key}&units=metric&lang=kr"
            response = requests.get(url)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ 날씨 데이터를 가져오는 중 오류 발생: {e}")
            return None
        
    # ---------- 24시간 데이터 반환 ----------
    def _process_24h_forecast(self) -> Tuple[Dict[str, float], List[Dict[str, Any]]]:
        raw_data = self._fetch_raw_data()
        if not raw_data or "list" not in raw_data:
            # 반환값을 튜플로 통일
            return {}, []

        start_index = 0

        # start_index부터 8개의 예보를 추출
        filtered_forecasts = raw_data["list"][start_index : start_index + 8]
        
        if not filtered_forecasts:
            return []
            
        weather_json_data = []
        rain_slots = {}

        for item in filtered_forecasts:
            item_time_kst = dt.datetime.strptime(item["dt_txt"], '%Y-%m-%d %H:%M:%S').replace(tzinfo=UTC).astimezone(self.KST)
            
            forecast_item = {
                "time": item_time_kst.strftime('%Y-%m-%d %H:%M:%S'),
                "status": item["weather"][0]["main"],
                "temp": item["main"]["temp"],
                "humi": item["main"]["humidity"],
                "emoji": self.EMOJI.get(item["weather"][0]["main"], "🌍"),
                "pop": item.get("pop", 0),
                "rain_3h": item.get("rain", {}).get("3h", 0)
            }
            weather_json_data.append(forecast_item)

            if self._is_rainy_strict(item):
                hour_slot_start = item_time_kst.hour
                rain3h = float(item.get("rain", {}).get("3h", 0) or 0)
                if rain3h > 0:
                    rain_slots[hour_slot_start] = rain3h
        
        return rain_slots, weather_json_data

    ## AI한테 날씨와 시간정보를 보내서 한 마디 하게함
    def _get_ai_weather_comment(self, current_forecast: List[Dict], hourly_forecasts) -> str:
        if not self.summarizer or not current_forecast:
            return "오늘도 활기찬 하루 보내세요!"

        current_status = current_forecast['status']
        current_temp = current_forecast['temp']
        current_hour = dt.datetime.now().hour

        if 5 <= current_hour < 12:
            time_of_day = "아침"
        elif 12 <= current_hour < 18:
            time_of_day = "오후"
        elif 18 <= current_hour < 23:
            time_of_day = "저녁"
        else:
            time_of_day = "밤"

        future_events = []
        for forecast in hourly_forecasts[1:]:
            if self._is_rainy_strict(forecast):
                rain_time = dt.datetime.strptime(forecast['time'], '%Y-%m-%d %H:%M:%S').hour
                future_events.append(f"{rain_time}시 경에 비 소식이 있어요.")
                break
        
        future_summary = " ".join(future_events) if future_events else "이후 특별한 날씨 변화는 없을 거예요."

        prompt = f"""
        당신은 사용자의 하루를 챙겨주는 유능하고 친절한 비서 '이리스'입니다.
        주어진 '현재 시간대'와 날씨 정보를 모두 조합해서, 친근한 비서가 말하듯이 매우 자연스럽고 상황에 딱 맞는 날씨 조언을 한두 문장으로 만들어주세요.

        [현재 시간대]
        - {time_of_day}

        [현재 날씨 정보]
        - 날씨: {current_status}
        - 기온: {current_temp:.1f}도

        [미래 날씨 정보]
        - 변화: {future_summary}

        [조언 예시]
        - (아침, 비 올 때): "비 오는 아침이네요! 오늘 외출할 때 우산 꼭 챙겨야겠어요."
        - (밤, 비 올 때): "비가 오는 밤이에요. 주무시기 전에 창문은 꼭 닫으세요."
        - (오후, 맑다가 저녁에 비 올 때): "화창한 오후네요! 다만 저녁 6시쯤 비 소식이 있으니, 퇴근길에 우산 챙기는 걸 잊지 마세요."

        이제, 위 정보를 바탕으로 최고의 조언을 만들어주세요:
        """

        try:
            ai_comment = self.summarizer.summarize(text="", prompt=prompt)
            return ai_comment.strip().replace('"', '')
        except Exception as e:
            print(f"-> 🤖 AI 날씨 코멘트 생성 중 오류 발생: {e}")
            return "오늘도 활기찬 하루 보내세요!"
        
    # 비가 오는지 확인 (비, 소나비, 천둥번개도 비라고 생각)
    def _is_rainy_strict(self, item: Dict[str, Any]) -> bool:
        if "weather" in item and item["weather"][0]["main"] in {"Rain", "Drizzle", "Thunderstorm"}:
            return True

        if "rain" in item and isinstance(item["rain"], dict) and (item["rain"].get("3h", 0) or 0) > 0:
            return True
        return False
    
    def _format_rain_info(self, rain_slots: Dict, is_update: bool) -> str:
        """강수 정보를 텍스트로 변환합니다."""
        if not rain_slots: return "비 예보 없음"
        lines = []
        current_hour = dt.datetime.now(self.KST).hour if is_update else -1
        for h in sorted(rain_slots.keys()):
            if h >= current_hour:
                lines.append(f" - {h:02d}시부터 : 약 {rain_slots[h]:.1f}mm")
        if not lines: return "현재 시간 이후 비 예보 없음"
        return "비오는 시간 (3시간 단위):\n" + "\n".join(lines)
    
    # 웹에서 임시 실행
    def get_temporary_weather(self):
        print("-> 임시 날씨 정보를 조회합니다 (파일 저장 안 함).")
        return self.get_web_weather_data()
