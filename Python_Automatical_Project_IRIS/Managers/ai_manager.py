import google.generativeai as genai

class GeminiSummarizer:
    def __init__(self, api_key):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-1.5-pro')

    def summarize(self, text, prompt=None):
        """
        주어진 텍스트를 요
        :param text: 요약할 원본 텍스트
        :param prompt: 사용할 프롬프트
        :return: 요약된 텍스트
        """
        if not prompt:
            prompt = f"""
            다음 뉴스 기사의 본문을 한국어로, 전문적이고 간결하게 세 개의 핵심 문장으로 요약해 줘.
            한 문장이 끝나면 </br>로 문단을 나눠서 보기 편하게 해줬으면 좋겠고,
            중요하다고 생각하는 단어에는 HTML 문법으로 볼드 처리해주면 좋겠어

            ---
            {text}
            ---
            """
        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Gemini 요약 중 오류 발생: {e}"