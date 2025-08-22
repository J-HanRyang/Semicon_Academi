import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
import os

class SenderManager :
    def __init__(self, smtp_server, smtp_port, sender_email, sender_password):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.sender_email = sender_email
        self.sender_password = sender_password

    def send_email(self, receiver_email, subject, body, attachment_path=None) :
        msg = MIMEMultipart()
        msg["From"] = self.sender_email
        msg["To"] = receiver_email
        msg["Subject"] = subject

        # 첨부 파일 추가해서 보내기
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as attachment:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(attachment.read())
            encoders.encode_base64(part)
            # os.path.basename으로 파일 이름만 추출
            part.add_header('Content-Disposition', f'attachment; filename={os.path.basename(attachment_path)}')
            msg.attach(part)
            
        # 이메일 본문
        msg.attach(MIMEText(body, "html", "utf-8")) # HTML 형식으로 변경

        try:
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as smtp:
                smtp.starttls()  # TLS 보안 시작
                smtp.login(self.sender_email, self.sender_password)
                smtp.send_message(msg)
            print("✅ 메일 전송 성공!")
            return True
            
        except Exception as e:
            print("❌ 메일 전송 실패:", e)
            return False