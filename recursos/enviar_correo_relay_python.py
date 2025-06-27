##############
import sys
import smtplib
from email.mime.text import MIMEText

# Configuración del servidor de reenvío (relay)
smtp_server = 'mx0b-0066f901.pphosted.com'
smtp_port = 25

# Detalles del correo electrónico (estos ahora vendrán de los argumentos)
from_addr = 'WME_automata@coomeva.nal' # Puedes dejarlo fijo o también pasarlo como argumento


def enviar_correo(to_addrs_str, subject, body):
    """Envía un correo electrónico a múltiples destinatarios."""
    to_addrs = to_addrs_str.split(',') # Dividir la cadena en una lista
    msg = MIMEText(body.encode('utf-8'), 'plain', 'utf-8')
    msg['Subject'] = subject
    msg['From'] = from_addr
    msg['To'] = to_addrs_str # Mostrar todos en el encabezado

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.sendmail(from_addr, to_addrs, msg.as_string()) # Pasar la lista de destinatarios
        print(f"Correo electrónico enviado exitosamente a {', '.join(to_addrs)} a través de {smtp_server}:{smtp_port}")
    except Exception as e:
        print(f"Ocurrió un error al enviar el correo: {e}")

if __name__ == "__main__":
    if len(sys.argv) == 4:
        lista_destinatarios = sys.argv[1]
        asunto = sys.argv[2]
        cuerpo = sys.argv[3]
        enviar_correo(lista_destinatarios, asunto, cuerpo)
    else:
        print("Uso: python enviar_correo.py <lista_de_destinatarios_separados_por_comas> <asunto> <body>")
        print("Ejemplo: python enviar_correo.py 'correo1@example.com,correo2@example.net' 'Asunto' 'Cuerpo'")
