#!/bin/bash

## Variables enviadas por Ansible

ruta_micros= {{ ruta_micros }} #origen en fs compartido +micro+servidor
ruta_backup=/home/versiones
servidor={{ servidor }}
aplicaciones="{{ aplicaciones }}" #incluye destino+nom-jar;ruta-script;reinicio <espacio>..
lista_mail="{{ emails }}"
#lista_mail="juliorod@kyndryl.com"
id_cambio="{{ cambio }}"
ruta_jar="$ruta_micros/$servidor" #origen en fs compartido +micro+servidor
historico_instalados="$ruta_micros/$servidor/historico_instalados"

case "cdplin81" in
  "cdplin81")
    usuario_app="usrsalud"
    ;;
  "cdplin30")
    usuario_app="usermicoomeva"
    ;;
  "cdplin93")
    usuario_app="root"
    ;;
  "cdplin99")
    usuario_app="usermimutual"
    ;;
  "cdplin109")
    usuario_app="usermiddlewaresp"
    ;;
  *)
    echo "Servidor no reconocido: cdplin81"
    exit 1
    ;;
esac

validacion() {
  artifact1=$1
  nombre_app_actual=$2
  if [[ -e "$artifact1" ]]; then
    echo validacion::::SI EXISTE EN  [$artifact1]
  else
    echo "validacion:::Error: El artefacto a desplegar [$2] NO ESTA en la ruta [$ruta_jar], se cancela ejecución."
    apps_con_diferencias+=("$nombre_app_actual: jar NO EXISTE en origen")
    echo "validacion:: No existe $artifact1 cambio se cancela la ejecucion"
    echo "validacion:: Llamando enviar_correo, por fallo en ubicacion de $artifact1"
    enviar_correo
    exit 1
  fi
}

realizar_depliegue() {
  origen=$1
  destino=$2
  fecha_bakup=$(date +%Y_%m_%d_%H_%m)
  local app_path # Se definirá más adelante
    # Verificar si el microservicio existe en la ruta antes del despliegue y hacer backup
    if [[ -e "$destino" ]]; then
      #sudo mv "$2" "$ruta_backup/${app}_$fecha_bakup"
      echo "realizar_depliegue:: tomando backup de $destino en  $ruta_backup/${app}_$fecha_bakup"
      sudo cp -p "$destino" "$ruta_backup/${app}_$fecha_bakup"
      ls  -ltr $ruta_backup/${app}_$fecha_bakup
      sleep 2
      if [[ -e "$ruta_backup/${app}_$fecha_bakup" ]]; then
	echo "realizar_depliegue::verificando que se haya tomando el backup $ruta_backup/${app}_$fecha_bakup"
	echo "realizar_depliegue:: hace copia de origen a destino"
        sudo cp -p "$origen" "$destino"
        sudo chown "$usuario_app:$usuario_app" "$destino"
        sudo chmod 644 "$destino"
      else
        echo "realizar_depliegue::Error: No se pudo crear un backup confiable para $destino. DESPLIEGUE CANCELADO."
	apps_con_diferencias+=("$destino: NO SE PUDO HACER BACKUP")
	echo "realizar_depliegue::saliendo del programa, con fallo, llama envio de correo"
        enviar_correo
        exit 1
      fi
    else
      echo
      echo "realizar_depliegue::Es un jar NUEVO, no existe.. se desplegara $origen"
      sudo cp -p "$origen" "$destino"
      sudo chown "$usuario_app:$usuario_app" "$destino"
      sudo chmod 644 "$destino"
    fi
}

stop_micro() {
  local pid=$1
  if [[ $app == *.jar ]]; then
    pid=$(pgrep -f "java(.*)$app")
    if [ -n "$pid" ]; then
      echo 
      echo "stop_micro::Bajando el microservicio $app con el id $pid"
      ps -fea|grep $pid
      #comentado sudo kill -9 "$pid" &>/dev/null
    else
      echo
      echo "stop_micro::ALERTA, No se encontró el proceso para $app parece estaba caido!!"
    fi
  fi
}

start_micro() {
  local script_inicio2="$1"
  local directorio=$2
  local ap=$3
  echo
  echo "start_micro::ejecutando $script_inicio2 para los micro de  $2"
  sudo -u "$usuario_app" sh "$script_inicio2" >/dev/null 2>&1 #sube todo lo que encuentre abajo
  pid=$(pgrep -f "java(.*)$directorio")
  if [ -n "$pid" ]; then
	  echo "start_micro:: el microservicio $directorio/$app fue iniciado, sus nuevos pid son $pid"
  else
	  echo
	  echo "start_micro::Alerta!!!!! parece no subió el o los jar del micro $directorio/$app.. hay que validar porque no ha subido"
	  apps_con_diferencias+=("$destino: NO HAY PID DE LOS PROCESOS DE $directorio/$app")
  fi
}

restart_all() {
  local list_pids
  script_name1=$2
  directorio1=$1
  nom_app=$3
  echo
  echo "restart_all:: identificando todos los jar asociados al jar $3"
  list_pids=$(pgrep -f "java(.*)$directorio1") #validar si se busca con $app o mejor con  app_name, debe retornar varios PID..
  echo "restart_all:: Estos son los procesos PID de los jar: [$list_pids]"
  for pid in $list_pids; do
      if [ -n "$pid" ]; then
        echo "restart_all::Bajando los microservicios asociados a $nom_app, bajando  el id $pid"
        #comentado sudo kill -9 $pid &>/dev/null
      fi
  done
  echo "restart_all::arrancado todos los micro del proyecto del $nom_app"
  start_micro $script_name1 $directorio1 $nom_app
}

declare -a apps_exitosas=()
declare -a apps_con_diferencias=()
declare -a apps_exitosas_info=()

valida_deploy() {
  local nombre_app_actual="$1"
  local artefacto_fuente="$2"
  local ruta_desplegada_app="$3"
  local md5_sum_actual
  echo valida_deploy::: Vamos a validar el despliegue para $nombre_app_actual, $ruta_desplegada_app
  pid=$(pgrep -f "java(.*)$ruta_desplegada_app")
  if diff -q "$artefacto_fuente" "$ruta_desplegada_app" >/dev/null 2>&1; then
    md5_sum_actual=$(md5sum "$ruta_desplegada_app" | awk '{print $1}')
    apps_exitosas_info+=("$nombre_app_actual (MD5: $md5_sum_actual)")
    echo
    echo valida_deploy::md5_sum: los artefactos son iguales para $nombre_app_actual
  else
    apps_con_diferencias+=("$nombre_app_actual")
    echo
    echo valida_deploy:::md5_sum  los artefactos NO  son iguales para $nombre_app_actual
  fi
  if [[ $(sudo netstat -anop|grep  $pid|grep tcp|grep LISTEN) ]]; then
	echo
	echo hay puertos en escucha de la aplicación app
	echo valida_deploy:::puertos OK levanto puertos para $nombre_app_actual
	apps_exitosas_info+=("$nombre_app_actual : Puertos LISTEN OK")
  else
	echo "valida_deploy:::ALERTA es probable que la aplicacion $nombre_app_actual no haya subido adecuadamente.. valide!!"
	echo "valida_deploy::: NO hay puertos en LISTEN para  $nombre_app_actual"
	apps_con_diferencias+=("$nombre_app_actual: Puertos LISTEN NO HAY")

  fi
}
{% raw %}
   enviar_correo() {
  local asunto_final=""
  local cuerpo_mensaje_final=""
  local detalles_exitosas=""
  local detalles_diferencias=""

  if [[ ${#apps_exitosas_info[@]} -gt 0 ]]; then
    for ((i=0; i<${#apps_exitosas_info[@]}; i++)); do
      detalles_exitosas+="    - ${apps_exitosas_info[i]}\n"
    done
  else
    detalles_exitosas="    (Ninguna)\n"
  fi

  if [[ ${#apps_con_diferencias[@]} -gt 0 ]]; then
    for ((i=0; i<${#apps_con_diferencias[@]}; i++)); do
      detalles_diferencias+="    - ${apps_con_diferencias[i]}\n"
    done
  else
    detalles_diferencias="    (Ninguna)\n"
  fi
  echo
  echo enviar_correo:: detalles_diferencias es: $detalles_diferencias
  echo enviar_correo:: detalles_exitosas es: $detalles_exitosas
  echo
   if [[ ${#apps_con_diferencias[@]} -eq 0 ]]; then
     asunto_final="[Despliegue Exitoso General] $id_cambio - Todas las aplicaciones OK en $servidor"
#
    printf -v cuerpo_mensaje_final "
Estimado equipo,

El proceso de verificación de despliegue para el cambio $id_cambio en el servidor $servidor se ha realizado correctamente.
Solicitamos de su colaboración realizando las pruebas respectivas para validar el correcto funcionamiento de los cambios implementados.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: Éxito
Hora: $(date +'%d/%m/%Y %H:%M')
Servidor: $servidor
Versión(es) desplegada(s):
$detalles_exitosas

Saludos,
Sistema de Automatización de Despliegues
"$id_cambio" "$servidor" "$Hora"  "$detalles_exitosas"
"
   else
    asunto_final="[ERROR] $id_cambio - Fallo en despliegue en $servidor"
    printf -v cuerpo_mensaje_final "
Estimado equipo,

Se detectaron problemas durante el despliegue para el cambio $id_cambio  en el servidor $servidor.

Aplicación(es) con diferencias:
$detalles_diferencias

Estado: Fallido
Hora: $(date +'%d/%m/%Y %H:%M')
Servidor: {{ servidor }}

Recomendación:
Revise el archivo de log correspondiente para identificar la causa del fallo y vuelva a ejecutar el playbook si es necesario.

Quedamos atentos ante cualquier duda.

Saludos,
Sistema de Automatización de Despliegues
 "$id_cambio" "$servidor" "$detalles_diferencias" "$Hora" 
" 
   fi

  echo ""
  echo "$asunto_final"
  echo ""
  echo -e "$cuerpo_mensaje_final"

 # Enviar correo electrónico usando sendmail
  echo -e "$cuerpo_mensaje_final" | /usr/sbin/sendmail -f "$sender_email" "$lista_mail"
}
{% endraw %}
#############################################################################################
# Inicia programan principal Procesar la lista de aplicaciones

#
echo ---------------
IFS=$' ' read -r -a lista_apps <<< "$aplicaciones"
echo
echo "PRINCIPAL::La lista Principal de jars a desplegar es: "${lista_apps[@]}""
for app_entry in "${lista_apps[@]}";
do
  IFS=';' read -r app_name script_name reinicio_flag <<< "$app_entry"
  app="${app_name##*/}"
  directorio="${app_name%/*}"
  artifact="$ruta_jar/$app"
  echo
  echo "PRINCIPAL::Desplegando: $app en $app_name y opcion de reinicio $reinicio_flag"
  echo "PRINCIPAL::llamando a la funcion  'validacion'  para $app"
  validacion $artifact $app_name
  echo "PRINCIPAL::llamando a funcion  'realizar_depliegue'  para $app"
  realizar_depliegue  $artifact $app_name 
  if [[ "$reinicio_flag" -eq 1 ]]; then
     	  echo "PRINCIPAL::llamando  a  restart_all para reiniciar todo los jar de $app en $directorio- tiene la opcion 1"
  	  restart_all $directorio $script_name $app
  else
	  echo "PRNCIPAL::No tiene opcion de Reinicio, está en 0, solo reinicio el jar $app actualizado"
	  echo "PRINCIPAL::llamando a stop_micro "
	  stop_micro $app
	  echo "PRINCIPAL::llamando a  start_micro"
	  start_micro $script_name $app_name $app
  fi
  echo "PRINCIPAL::vamos a  validar que el jar $app haya quedado bien desplegado"
  echo "PRINCIPAL::llamando a valida_deploy para $app"
  valida_deploy "$app" "$artifact" "$app_name"
done
echo
echo "PRINCIPAL:: llamando la funcion de enviar_correo"
enviar_correo
