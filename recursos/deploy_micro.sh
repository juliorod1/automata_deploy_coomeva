#!/bin/bash

# Variables
date=$(date +%d_%m_%Y_%H)
hora=$(date +%d/%m/%Y" "%H:%M)
servidor=$(hostname)
ruta_jar=/home/scripts/automata_ansible/microservicios/cdplin93
ruta_backup=/home/versiones
historico=/home/scripts/automata_ansible/microservicios/cdplin81/historico_instalados #si es exitoso se mueve
aplicaciones="/opt/contenerizacion/microservices/fabrica-soluciones-backend.jar /opt/contenerizacion/microservices/fabrica-soluciones-cotizador.jar"
script=/opt/contenerizacion/microservices/scripts/subir_micros.sh
lista_mail=william.caicedo1@kyndryl.com
user=root
id_cambio=CRQ0000031634
reinicio=0


validacion() {
  if [[ -e "$artifact" ]]; then
    realizar_depliegue
  else
    echo "El artefacto a desplegar no esta en la ruta $ruta, se cancela ejecución."
    exit 1
  fi
}

realizar_depliegue() {
  # Verificar si el microservicio existe en la ruta antes del despliegue y hacer backup
  if [[ -e "$app_path" ]]; then
    sudo mv "$app_path" "$ruta_backup/${app}_${date}"
    sleep 2

    # Validar si el backup se realizó correctamente, si el backup es exitoso realiza la actualización del componente
    if [[ -e "$ruta_backup/${app}_${date}" ]]; then
      sudo cp "$artifact" "$app_path"
      sudo chown "$user:$user" "$app_path"
      sudo chmod 644 "$app_path"
    else
      echo "Error: No se pudo crear un backup confiable. Despliegue cancelado."
      return 1
    fi
  fi
}

stop_micro() {
  if [[ $micro == *.jar ]]; then
    pid=$(pgrep -f "java(.*)$micro")
    if [ -n "$pid" ]; then
      echo "Bajando el microservicio $micro con el id $pid"
      sudo kill -9 "$pid" &>/dev/null
    else
      return
    fi
  fi
}

start_micro() {
  sudo -u "$user" sh "$script" >/dev/null 2>&1
}

restart_all() {
  list_pids=$(pgrep -f "java(.*)$path")
  for pid in $(echo "$list_pids"); do
    if [ -n "$pid" ]; then
      echo "Bajando el microservicio con el id $pid"
      sudo kill -9 $pid &>/dev/null
    fi
  done
  start_micro
  enviar_correo
  exit 0
}

declare -a apps_exitosas=()
declare -a apps_diferencias=()

valida_deploy() {
  local nombre_app_actual="$1"
  local artefacto_fuente="$2"
  local ruta_desplegada_app="$3"
  local md5_sum_actual

  if diff -q "$artefacto_fuente" "$ruta_desplegada_app" >/dev/null 2>&1; then
    md5_sum_actual=$(md5sum "$ruta_desplegada_app" | awk '{print $1}') # Obtener solo el hash
    apps_exitosas_info+=("$nombre_app_actual (MD5: $md5_sum_actual)")
  else
    apps_con_diferencias+=("$nombre_app_actual")
  fi
}

enviar_correo() {
  local asunto_final=""
  local cuerpo_mensaje_final="" # Usaremos printf para el formato final

  # Construir el cuerpo del mensaje
  local detalles_exitosas=""
  local detalles_diferencias=""
  local i

  if [[ ${#apps_exitosas_info[@]} -gt 0 ]]; then
    for ((i=0; i<${#apps_exitosas_info[@]}; i++)); do
      detalles_exitosas+="      - ${apps_exitosas_info[i]}\n"
    done
  else
    detalles_exitosas="      (Ninguna)\n"
  fi

  if [[ ${#apps_con_diferencias[@]} -gt 0 ]]; then
    for ((i=0; i<${#apps_con_diferencias[@]}; i++)); do
      detalles_diferencias+="      - ${apps_con_diferencias[i]}\n"
    done
  else
    detalles_diferencias="      (Ninguna)\n"
  fi

  if [[ ${#apps_con_diferencias[@]} -eq 0 ]]; then
    asunto_final="[Despliegue Exitoso General] $id_cambio - Todas las aplicaciones OK"
    #cuerpo_mensaje_final=$(printf "Estimado equipo,\n\nEl proceso de verificación de despliegue para el cambio '%s' en el servidor '%s' se ha realizado y TODAS las aplicaciones están correctas.\n\nEstado: Éxito General\nHora: %s\n\nAplicaciones Verificadas Correctamente:\n%s\nSolicitamos de su colaboración realizando las pruebas respectivas.\n\nQuedamos atentos,\nSistema de Automatización" \
      #"$id_cambio" "$servidor" "$hora" "$detalles_exitosas")
printf -v cuerpo_mensaje_final "
Estimado equipo,

El proceso de verificación de despliegue para el cambio '%s' en el directorio '%s' servidor '%s' se ha realizado correctamente.
Solicitamos de su colaboración realizando las pruebas respectivas para validar el correcto funcionamiento de los cambios implementados.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: Éxito
Hora: %s
Versión desplegada:
%s

Saludos,
Sistema de Automatización de Despliegues
" "$id_cambio" "$path" "$servidor" "$hora" "$detalles_exitosas"
  else
printf -v asunto_final "[ERROR] %s despliegue fallido" "$id_cambio"
printf -v cuerpo_mensaje_final "
Estimado equipo,

Se detectaron problemas durante el despliegue para el cambio '%s' en el directorio '%s' servidor '%s'.

Aplicación(es): 
'%s'

Estado: Fallido
Hora: %s

Recomendación:
Revise el archivo de log correspondiente para identificar la causa del fallo y vuelva a ejecutar el script de despliegue si es necesario.

Quedamos atentos ante cualquier duda.

Saludos,
Sistema de Automatización de Despliegues
" "$id_cambio" "$path" "$servidor" "$detalles_diferencias" "$hora"
  fi

  echo ""
  echo "$asunto_final"
  echo ""
  echo -e "$cuerpo_mensaje_final" # -e para interpretar \n si printf no los manejó ya (depende de cómo se construyó)
  # Para enviar un correo real, aquí iría el comando:
  # echo -e "$cuerpo_mensaje_final" | mail -s "$asunto_final" "destinatario@example.com"
}


lista_apps=($aplicaciones)
for app_path in "${lista_apps[@]}";
do
  app="${app_path##*/}"
  path="${app_path%/*}"
  artifact="$ruta_jar"/"$app"
  validacion
done

if [[ "$reinicio" -eq 1 ]]; then
  restart_all
fi

for micro_path in "${lista_apps[@]}";
do
  micro="${micro_path##*/}"
  stop_micro
done

start_micro

for app_path in "${lista_apps[@]}";
do
  app="${app_path##*/}"
  path="${app_path%/*}"
  artifact="$ruta_jar"/"$app"
  valida_deploy "$app" "$artifact" "$app_path"
done

enviar_correo
