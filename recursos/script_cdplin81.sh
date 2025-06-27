#!/bin/bash

#Este grupo de variables o argumentos de inicio son generales y siempre el controler de ansible los enviará hacia cada uno de los server, ya sea como variable o como una constante
ruta_jar=/home/scripts/automata_ansible/microservicios/cdplin81/
ruta_bakup=/home/versions
ruta_logs=/opt/microservicios/microbus/logs #opcional., si hay alhgo para validar a nivel de log
historico_instalados=/home/scripts/automata_ansible/microservicios/cdplin81/historico_instalados #si es exitoso se mueve 
servidor="cdplin81"
aplicaciones="/opt/microservicios/microbus/api-gateway-microbus.jar /opt/microservicios/microbus/aplicacion.properties"
lista_mail="juan@coomeva.com.co"
script_reinicio=/opt/microservicios/microbus/scripts/subir_microbus.sh
usuario_app=usrsalud
id_cambio=CRXXXXX1234

despliegue() {

        echo hago de todo y puedo llamar otras funciones .. jejejee
}

#si la variable aplicaciones incluye mas de un valor, use un for enla funcion despliegue, para que itere con los valores de esta ppara hacer el despliegue
case "$servidor" in
  "cdplin81")
    echo "Se seleccionó la Opción cdplin81"
    #aca se rescribe o reasigna valores a las variables que envia el controler según cada server
    usuario_app=usrsalud
    # Aquí puedes agregar o cargar las variables particulares para el cdplinN y llamar una función despliegue y que se usa para todos los casos pasando los parametros particulares para ese server; y otros comando perzonalidos para cdplin81
    despliegue $ruta_jar $ruta_bakup $aplicaciones $script_reinicio $usuario_app 

    ;;
  "cdplin30")
    echo "Se seleccionó la Opción cdplin30"
    usuario_app=usermicoomeva
    script_reinicio=/opt/td-microservice/scripts/subir_micoomeva.sh
    despliegue $ruta_jar $ruta_bakup $aplicaciones $script_reinicio $usuario_app
    ;;
  "cdplin93")
    echo "Se seleccionó la Opción cdplin93"
    usuario_app=root
    despliegue $ruta_jar $ruta_bakup $aplicaciones $script_reinicio $usuario_app
    ;;

  "cdplin99")
    echo "Se seleccionó la Opción cdplin99"
    usuario_app=usermimutual
    script_reinicio=/opt/mimutual/bin/start_mimutual_zabbix.sh
    despliegue $ruta_jar $ruta_bakup $aplicaciones $script_reinicio $usuario_app
    # otros comandos perzonalizados para cdplin99
    ;;
      "cdplin109")
    echo "Se seleccionó la Opción cdplin109"
    usuario_app=usermiddlewaresp
    script_reinicio=/opt/middleware/subir_microservicios.sh
    despliegue $ruta_jar $ruta_bakup $aplicaciones $script_reinicio $usuario_app
    # otros comandos perzonalizados para cdplin99
    ;;
  *)
    echo "Opción no válida"
    # Aquí puedes agregar los comandos para el caso por defecto
    ;;
esac


#requerimientos
#1-backup de las app actualizadas
#2-despliegue de las app
#3-validaciones despliegue: proceso up, puerto zabb up, puerto de la aplicación opcional o alguna validación en logs opcional
#4-rollback--> si no levanta la aplicación
#5-notificacion-->cuando falle ya sea porque no existe en la ruta el jar, o por cualquier opción de falla o de éxito. hay que adecuar segun la tool de envio de correo si es sendmail, mailx, s-nail etc, entonces crear una funciona  para cada tool según aplique en cada server 
