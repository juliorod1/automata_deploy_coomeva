#!/bin/bash
#######Inicio funcion para envio de notificacion email en caso de exito
#mail-exitoso $LISTA_MAIL $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
mail-exitoso() {
echo evia mail en caso de ser exitoso el cambio
# Variables de configuración
TO_EMAIL="$1" # Dirección de correo electrónico del destinatario
FROM_EMAIL="CDPAIX10@coomeva.nal" # Dirección de correo electrónico del remitente
LOG_FILE="$RUTA_SOA/template_broquer_$2.log"
ATTACHMENT_NAME=$(basename "$LOG_FILE")
SUBJECT="EXITOSO::Notificación $2 :: $3 SOA-MQ-BK "    # Asunto del correo electrónico
BODY="Estimado equipo,

El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] se ha realizado correctamente.
Solicitamos de su colaboración realizando las pruebas respectivas para validar el correcto funcionamiento de los cambios implementados.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: $6
Hora: fecha_ejecucion

Saludos,
Sistema de Automatización de Despliegues." # Cuerpo del correo electrónico
# Puedes pasar variables adicionales como argumentos al script
# Ejemplo: script.sh "Otro asunto" "Otro cuerpo de mensaje" otro@ejemplo.com

if [  "$6" -ne 0 ]; then
  SUBJECT="FALLA CAMBIO::Notificación $2 :: $3 SOA-MQ-BK "
  BODY="Estimado equipo,

El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] ha FALLADO.
Solicitamos de su colaboración realizando las validaciones  respectivas para validar e identificar la causa de este fallo.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: $6
Hora: fecha_ejecucion

Saludos,
Sistema de Automatización de Despliegues."
fi
#
if [  "$#" -ne 6 ] ; then
	SUBJECT="FALLA CAMBIO::Notificación $2 :: $3 SOA-MQ-BK "
	BODY="El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] ha FALLADO.
	Estado: $6
	Hora: fecha_ejecucion"
fi

EMAIL_MESSAGE="From: ${FROM_EMAIL}
To: ${TO_EMAIL}
Subject: ${SUBJECT}
Content-Type: text/plain; charset=UTF-8

${BODY}
"


# Enviar el correo electrónico usando sendmail

#(
#echo "Content-Type: multipart/mixed; boundary=\"SEP-BOUNDARY\""
#echo "From: ${FROM_EMAIL}"
#echo "To: ${TO_EMAIL}"
#echo "Subject: ${SUBJECT}"
#echo ""
#echo "--SEP-BOUNDARY"
#echo "Content-Type: text/plain; charset=UTF-8"
#echo ""
#echo "${BODY}"
#echo ""
#echo "Adjunto encontrarás el archivo de log."
#echo ""
#echo "--SEP-BOUNDARY"
#echo "Content-Type: application/octet-stream; name=\"${ATTACHMENT_NAME}\""
#echo "Content-Transfer-Encoding: base64"
#echo "Content-Disposition: attachment; filename=\"${ATTACHMENT_NAME}\""
#echo ""
#uuencode -m "$LOG_FILE" "$ATTACHMENT_NAME" | sed '1d'
#echo "--SEP-BOUNDARY--"
#)| /usr/sbin/sendmail -oi -f "$FROM_EMAIL" "$TO_EMAIL"

echo "$EMAIL_MESSAGE" | /usr/sbin/sendmail -oi -f "$FROM_EMAIL" "$TO_EMAIL"

# Verificar el estado del envío (opcional)
if [ $? -eq 0 ]; then
  echo "Correo electrónico enviado exitosamente a: $TO_EMAIL"
else
  echo "Error al enviar el correo electrónico a: $TO_EMAIL"
fi

}
#######fin -funcion para envio de notificacion email en caso de exito

echo vamos a enviar un mensaje de mail
LISTA_MAIL=juliorod@kyndryl.com
CAMBIO=CRprueba
SERVER=cdplin93
NODE_BOKER=cdplin93
NOM_GE=nom-jars
exit_code=0
mail-exitoso $LISTA_MAIL $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
