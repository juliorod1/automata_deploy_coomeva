#!/bin/bash
#Autor: WME-Kyndryl Colombia 2025 Julio Cesar Rodriguez Ibague, Edwin Giraldo , Jhon Osorio
#Version:v1
# Asigna los argumentos a variables capturados desde la interfaz de usuario
#BLOQUE DE VARIABLES Y CONSTANTES GLOBALES AL PROGRAMA
. /opt/IBM/mqsi/10.0.0.22/server/bin/mqsiprofile
CAMBIO={{cambio}}
SERVER={{servidor}}
BAR_FILES="{{aplicaciones}}" #arreglo separado con espacio: grupo-ejecucion;file.bar;reinicio

CREA_GE={{crea_ge}} # crea grupo de jecucion? 1,0
NODE_BOKER={{nombre_broker}} #node broker
NOM_GE={{nom_ge}} #nombre grupo ejecucion

CREA_MQ={{crea_mqc}} # crea cola ? 1,0
NOM_MQ={{nom_gestorMQ}} #nombre del gestor de colas
SCRIPT_COLA={{script_colaMQ}} #script para crear la cola

LISTA_MAIL="{{emails}}" #notifacion buzones de correo
#LISTA_MAIL="juliorod@kyndryl.com"
RUTA_SOA="/home/deployus/deploy/$CAMBIO" #/home/deployuser/deploy/$CAMBIO acá se ubucaran los bar y los script para creacion de las colas
RUTA_LOGS="/home/deployus/logs" #/home/deployuser/logs ruta de logs de cada ejecucon del cambio

############inicio-espacio para definir y desarrollar las funciones########################################

###funcion para crear un grupo de ejecucion
#crea_ge $NODE_BOKER $NOM_GE
crea_ge() {
echo "****Creando grupo de ejecucion en  $1 llamado  $2"

# Variables de configuración
BROKER_NAME="$1"        # Reemplaza con el nombre de tu broker
EXECUTION_GROUP_NAME="$2" # Reemplaza con el nombre deseado para el grupo de ejecución

# Verifica si se ha proporcionado el nombre del broker
if [ -z "$BROKER_NAME" ] || [ "$BROKER_NAME" == "NOMBRE_DEL_BROKER" ]; then
  echo "Error: Debes especificar el nombre del broker en la variable BROKER_NAME."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
fi

# Verifica si se ha proporcionado el nombre del grupo de ejecución
if [ -z "$EXECUTION_GROUP_NAME" ] || [ "$EXECUTION_GROUP_NAME" == "NOMBRE_DEL_GRUPO_EJECUCION" ]; then
  echo "Error: Debes especificar el nombre del grupo de ejecución en la variable EXECUTION_GROUP_NAME."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
fi

# Comando para crear el grupo de ejecución
echo "Intentando crear el grupo de ejecución '$EXECUTION_GROUP_NAME' en el broker '$BROKER_NAME'."
mqsicreateexecutiongroup "$BROKER_NAME" -e "$EXECUTION_GROUP_NAME"

# Captura el código de salida del comando
exit_code=$?

# Verifica el código de salida
if [ "$exit_code" -eq 0 ]; then
  echo "El grupo de ejecución '$EXECUTION_GROUP_NAME' se creó exitosamente en el broker '$BROKER_NAME'."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
else
  echo "Hubo un error al crear el grupo de ejecución '$EXECUTION_GROUP_NAME'. Código de salida: $exit_code"
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
  # Opcionalmente, puedes agregar más lógica para analizar el código de salida específico de MQ
fi
}
###fin-funcion apra crear un grupo de ejecucion

###inicio funcion para  desplegar los bar
#deploy_bar $ge $file_bar $reinicio $node
deploy_bar() {
echo "**Desplegando en el Grupo de ejecucion $1 el bar $2, nodo $4"

reinicio=$3
# Nombre del nodo de integración (Ajustar según entorno)
INTEGRATION_NODE="$4"

# Cargar entorno de IIB ## ojo!! varibale puede variar  con el servidor
. /opt/IBM/mqsi/10.0.0.22/server/bin/mqsiprofile

IS="$1"
BARFILE=$RUTA_SOA/"$2"

# Validar existencia del archivo BAR
if [ ! -f "$BARFILE" ]; then
  echo "❌ El archivo .bar no existe en la ruta especificada: $BARFILE"
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
fi

echo "============================================"
echo "Desplegando archivo BAR en Integration Server"
echo "Nodo de integración: $INTEGRATION_NODE"
echo "Integration Server : $IS"
echo "Archivo BAR        : $BARFILE"
echo "--------------------------------------------"

# Comando de despliegue
mqsideploy "$INTEGRATION_NODE" -e "$IS" -a "$BARFILE" 
exit_code=$?
if [ "$exit_code" -eq 0 ]; then
  echo "✅ Despliegue exitoso de $BARFILE en $IS"
  if [ $reinicio -eq 1 ]; then
	  echo Reiniciando  el  grupo de Ejecucion "$IS"
	  echo ==Deteniendo====
	  mqsistopmsgflow "$INTEGRATION_NODE" -e $IS
	  echo  ==Iniciando....=====
	  mqsistartmsgflow "$INTEGRATION_NODE" -e $IS
  fi
else
  echo "❌ Error en el despliegue de $BARFILE"
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
fi

}
###fin- funcion para desplegar un bar

###Inicio de la funcion para crear colas en el MQ
#crear-mq $NOM_MQ $SCRIPT_COLA
crear-mq() {
nom_mq=$1
script=$2
echo "**Ejecutando funcion para la creacion de colas en el MQ $1 usnado el script  $2"
# Define el nombre del gestor de colas
QUEUE_MANAGER_NAME="$1"

# Define la ruta al archivo .mqsc que contiene los comandos para crear la cola
MQSC_SCRIPT_PATH="$RUTA_SOA/$2"

# Verifica si el gestor de colas está definido
if [ -z "$QUEUE_MANAGER_NAME" ]; then
  echo "Error: Debes definir el nombre del gestor de colas en la variable QUEUE_MANAGER_NAME."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE 
fi

# Verifica si la ruta al script .mqsc está definida y el archivo existe
if [ -z "$MQSC_SCRIPT_PATH" ] || [ ! -f "$MQSC_SCRIPT_PATH" ]; then
  echo "Error: Debes definir una ruta válida al archivo .mqsc en la variable MQSC_SCRIPT_PATH."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE
fi

# Ejecuta el comando runmqsc redirigiendo la entrada desde el archivo .mqsc
echo "Intentando crear la cola usando el script: $MQSC_SCRIPT_PATH en el gestor de colas: $QUEUE_MANAGER_NAME"
runmqsc "$QUEUE_MANAGER_NAME" < "$MQSC_SCRIPT_PATH"

# Captura el código de salida del comando runmqsc
exit_code=$?

# Verifica el código de salida para determinar si hubo errores
if [ "$exit_code" -eq 0 ]; then
  echo "La cola se creó exitosamente."
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
else
  echo "Hubo un error al crear la cola. Código de salida: $exit_code"
  mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
  # Opcionalmente, puedes agregar más lógica para analizar el código de salida específico de MQ
fi

}
###fin de la funcion para crear colas en el MQ

#######Inicio funcion para envio de notificacion email en caso de exito
#mail-exitoso "$LISTA_MAIL" $CAMBIO $SERVER $NODE_BOKER $NOM_GE $exit_code
mail-exitoso() {
echo evia mail en caso de ser exitoso el cambio
# Variables de configuración
fecha_ejecucion=`date +"%Y-%m-%d %H:%m"`
TO_EMAIL="$1" # Dirección de correo electrónico del destinatario
FROM_EMAIL="CDPAIX10@coomeva.nal" # Dirección de correo electrónico del remitente
LOG_FILE="$RUTA_LOGS/log_ejecucion_soa_$2.log"
ATTACHMENT_NAME=$(basename "$LOG_FILE")
SUBJECT="EXITOSO::Notificacion Cambio $2 :: $3 SOA-MQ-BK "    # Asunto del correo electrónico
BODY="Estimado equipo,

El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] se ha realizado correctamente.
Solicitamos de su colaboración realizando las pruebas respectivas para validar el correcto funcionamiento de los cambios implementados.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: $6
Hora:$fecha_ejecucion

Saludos,
Sistema de Automatización de Despliegues." # Cuerpo del correo electrónico
# Puedes pasar variables adicionales como argumentos al script
# Ejemplo: script.sh "Otro asunto" "Otro cuerpo de mensaje" otro@ejemplo.com

if [  "$6" -ne 0 ]; then
  SUBJECT="FALLA CAMBIO::Notificacion Cambio $2 :: $3 SOA-MQ-BK "
  BODY="Estimado equipo,

El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] ha FALLADO.
Solicitamos de su colaboración realizando las validaciones  respectivas para validar e identificar la causa de este fallo.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: $6
Hora: $fecha_ejecucion

Saludos,
Sistema de Automatización de Despliegues."
fi
#
if [  "$#" -ne 6 ] ; then
	SUBJECT="FALLA CAMBIO::Notificacion Cambio $2 :: $3 SOA-MQ-BK "
	BODY="El despliegue de la aplicación [$4] en la instancia [$5]  servidor [$3] ha FALLADO.
	Estado: $6
	Hora: $fecha_ejecucion"
fi

#EMAIL_MESSAGE="From: ${FROM_EMAIL}
#To: ${TO_EMAIL}
#Subject: ${SUBJECT}
#Content-Type: text/plain; charset=UTF-8
#
#${BODY}
#"


# Enviar el correo electrónico usando sendmail

(
echo "Content-Type: multipart/mixed; boundary=\"SEP-BOUNDARY\""
echo "From: ${FROM_EMAIL}"
echo "To: ${TO_EMAIL}"
echo "Subject: ${SUBJECT}"
echo ""
echo "--SEP-BOUNDARY"
echo "Content-Type: text/plain; charset=UTF-8"
echo ""
echo "${BODY}"
echo ""
echo "Adjunto encontrarás el archivo de log."
echo ""
echo "--SEP-BOUNDARY"
echo "Content-Type: application/octet-stream; name=\"${ATTACHMENT_NAME}\""
echo "Content-Transfer-Encoding: base64"
echo "Content-Disposition: attachment; filename=\"${ATTACHMENT_NAME}\""
echo ""
uuencode -m "$LOG_FILE" "$ATTACHMENT_NAME" | sed '1d'
echo "--SEP-BOUNDARY--"
)| /usr/sbin/sendmail -oi -f "$FROM_EMAIL" "$TO_EMAIL"

#echo "$EMAIL_MESSAGE" | /usr/sbin/sendmail -oi -f "$FROM_EMAIL" "$TO_EMAIL"

# Verificar el estado del envío (opcional)
if [ $? -eq 0 ]; then
  echo "Correo electrónico enviado exitosamente a: $TO_EMAIL"
else
  echo "Error al enviar el correo electrónico a: $TO_EMAIL"
fi

}
#######fin -funcion para envio de notificacion email en caso de exito

###########fin-espacio para definir y desarrollar las funciones########################################

######PROGRAMA PRINCIPAL##########
#Vamos a decidir qué hacer sugún argumentos de entrada..

if [ $CREA_GE -eq 1 ]; then
	echo "******CREANDO UN GRUPO DE EJECUCION*********"
	echo "***Vamos acrear un grupo de ejecucion en $NODE_BOKER que se llamará $NOM_GE"
	crea_ge  $NODE_BOKER $NOM_GE
fi
#VAlidando el arreglo de aplicaciones que vienen en  $BAR_FILES
if [ "$BAR_FILES" != "NO_APLICA " ]; then
 	echo "****DESPLEGANDO ARCHIVOS BAR EN GRPOS DE EJECUCION***"	
	for i in $BAR_FILES;do
		echo **vamos a desplegar a  $i:
		ge=$(echo $i|awk 'BEGIN{ FS=";"} { print $1 }')
		file_bar=$(echo $i |awk 'BEGIN{ FS=";"} { print $2 }')
		reinicio=$(echo $i |awk 'BEGIN{ FS=";"} { print $3 }')
		node=$(echo $i |awk 'BEGIN{ FS=";"} { print $4 }')
		echo grupo de ejecucion es: $ge
		echo El archivo bar es: $file_bar
		echo Se reinicia grupo?: $reinicio
		echo El Node Broker es: $node
		deploy_bar $ge $file_bar $reinicio $node
	done
else
	echo NO_APLICA para desplegar files bar

fi

#Validando si hay que crear un cola en el MQ o no.
if [ $CREA_MQ -eq 1 ]; then
	echo "*****CREANDO COLAS EN MQ ***"	
	echo Vamos acrear la cola en el MQ $NOM_MQ usando el script $SCRIPT_COLA
	crear-mq $NOM_MQ $SCRIPT_COLA
else
	echo No se crean colas en el MQ
fi
