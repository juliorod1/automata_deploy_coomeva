import smtplib
from email.mime.text import MIMEText

# Configuración del servidor de reenvío (relay)
smtp_server = 'mx0b-0066f901.pphosted.com'
smtp_port = 25

# Detalles del correo electrónico
from_addr = 'cdplin93@coomeva.nal'
to_addr = 'juliorod@kyndryl.com'
subject = 'Correo de prueba desde Python con caracteres especiales'
body = 'Este es un correo de prueba que contiene el carácter especial é enviado a través del puerto 25 del relay.'

# Construir el mensaje como un objeto MIMEText
msg = MIMEText(body.encode('utf-8'), 'plain', 'utf-8')
msg['Subject'] = subject
msg['From'] = from_addr
msg['To'] = to_addr

try:
    # Crear una conexión SMTP
    with smtplib.SMTP(smtp_server, smtp_port) as server:
        # Enviar el correo electrónico
        server.sendmail(from_addr, to_addr, msg.as_string())
    print(f"Correo electrónico enviado exitosamente a {to_addr} a través de {smtp_server}:{smtp_port}")
except Exception as e:
    print(f"Ocurrió un error al enviar el correo: {e}")
