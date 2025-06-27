#!/bin/bash

#####Autor: William Caicedo, Julio Cesar Rodriguez Ibague- fecha: 2025/03  Version:1.0- Kyndryl WME Colombia

# Validación de parámetros
#if [ "$#" -ne 6 ]; then
#  echo "Uso: $0 <app> <version> <instancia> <script> <user> <ruta>"
#  exit 1
#fi

# Asignación de variables desde los argumentos del script
# apps: aplicaciones, emails, cambio,reinicio
#opcionales: instancia, version jboss
#Lista de aplicaciones a desplegar en este server- variables globales.
apps="{{apps}}"
lista_mail="{{emails}}"
cambio={{cambio}}
ruta="/home/scripts/automata_ansible"
reinicio={{reinicio}}
instancia="{{instancia}}"
version="{{version}}"

###########################################Inicia funcion validacion=========
validacion() {
  if [[ -e "$artifact" ]]; then
    realizar_despliegue
  else
    echo "El artefacto a desplegar no esta en la ruta $artifact, se cancela ejecución."
    exit 1
  fi
}
###########################################Termina funcion validacion=========
###########################################Inicia funcion restart_j7=========
restart_j7() {
  echo iniciando reinicio, ejecutando la funcion: restart_j7
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia/")
  if [ -n "$pid" ]; then
    sudo kill -9 "$pid" &>/dev/null
    sleep 1
  fi
  sleep 2
  echo " "
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia/")
  if [ -n "$pid" ]; then
    echo "La instancia $instancia ya se encuentra en ejecución. No se ejecutan acciones administrativas."
    return 1
  else
    sudo -u "$user" sh "$JBOSS_DOMAIN"/bin/"$script" >/dev/null 2>&1 &
    sleep 2
    last_line=$(cat -n "$JBOSS_HOME"/log/server.log | tail -n 1 | awk '{print $1}')
    while true; do
      linea=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME"/log/server.log | grep -Eo "started in|inició en|Start completed|with errors")
      if [[ "$linea" = "started in" || "$linea" = "inició en" || "$linea" = "Start completed" ]]; then
        break
      elif [[ "$linea" = "with errors" || "$linea" = "con errores" ]]; then
        echo "La instancia $instancia en el servidor $server subio con errores, por favor validar los logs"
        echo " "
        exit 1
      fi
      sleep 5
    done
  fi
}
###########################################Termina funcion restart_j7==========

###########################################Inicia funcion restart_j4===========
restart_j4() {
  echo iniciando reinicio, ejecutando la funcion: restart_j4
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  if [ -n "$pid" ]; then
    sudo kill -9 "$pid" &>/dev/null
  fi
  sleep 2
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  if [ -n "$pid" ]; then
    echo " La instancia $instancia ya se encuentra en ejecución. No se ejecutan acciones administrativas."
    return 1
  else
    sudo -u "$user" sh "$JBOSS_DOMAIN"/bin/"$script" >/dev/null 2>&1 &
    sleep 2
    last_line=$(cat -n "$JBOSS_HOME"/log/server.log | tail -n 1 | awk '{print $1}')
    while true; do
      linea=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME"/log/server.log | grep -Eo "Started in|Starting failed")
      if [[ "$linea" = "Started in" ]]; then
        break
      elif [[ "$linea" = "Starting failed" ]]; then
        echo "La instancia $instancia en el servidor $server fallo al iniciar, validar los logs"
        echo " "
        exit 1
      fi
      sleep 5
    done
  fi
}
###########################################Termina funcion restart_j4================

###########################################Inicia funcion valida_deploy============
max_retries=3
retry_count=0

valida_deploy() {
  # Espera a que el despliegue se complete
  echo  ejecutando : funcion valida_deploy
  while true; do
    echo max_retries es: $max_retries y retry_count es: $retry_count
    if [[ $version == "jboss-4.2.2.GA" ]]; then
      deploy_deployed=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME"/log/server.log | grep -Eo "End deployment start on package: $app")
      deploy_failed=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME"/log/server.log | grep -Eo "Failed to deploy:|url=file:$dir_deployments4/$app")
    else
      deploy_deployed=$(ls "$dir_deploy/${app}.deployed" 2>/dev/null)
      deploy_failed=$(ls "$dir_deploy/${app}.failed" 2>/dev/null)
    fi
    # Se valida si el despliegue es exitoso o fallido
    if [[ -n "$deploy_deployed" ]]; then
      listar=$(ls -l "$dir_deploy/${app}"*)
      if [[ $retry_count -eq 1 ]]; then
        printf -v asunto_rollback "[Rollback Ejecutado] Aplicación %s" "$app"
        echo "$mensaje_rollback" |mailx -s "$asunto_rollback" "$lista_mail"
        break
      elif [[ $retry_count -eq 0 ]]; then
printf -v mensaje_exito "
Estimado equipo,

El despliegue de la aplicación '%s' en la instancia '%s' servidor '%s' se ha realizado correctamente.
Solicitamos de su colaboración realizando las pruebas respectivas para validar el correcto funcionamiento de los cambios implementados.

Quedamos atentos a cualquier consulta o retroalimentación adicional.

Estado: Éxito
Hora: %s
Versión desplegada:
%s

Saludos,
Sistema de Automatización de Despliegues
" "$app" "$instancia" "$server" "$hora" "$listar"
        printf -v asunto_exito "[Despliegue Exitoso] aplicación %s" "$app"
        echo "$mensaje_exito" |mailx -s "$asunto_exito" "$lista_mail"
	return
      fi
    elif [[ -n "$deploy_failed" ]]; then
      if [[ $retry_count -eq 0 ]]; then
printf -v mensaje_fallo "
Estimado equipo,

Se ha producido un fallo durante el despliegue de la aplicación '%s' en la instancia '%s' servidor '%s'.

Estado: Fallido
Hora: %s

Recomendación:
Revise el archivo de log correspondiente para identificar la causa del fallo y vuelva a ejecutar el script de despliegue si es necesario.

Quedamos atentos ante cualquier duda.

Saludos,
Sistema de Automatización de Despliegues
" "$app" "$instancia" "$server" "$hora"
        printf -v asunto_fallo "[ERROR] Despliegue fallido aplicación %s" "$app"
        echo "$mensaje_fallo" |mailx -s "$asunto_fallo" "$lista_mail"
      fi
      rollback
      ((retry_count++))
      if [[ $retry_count -gt $max_retries ]]; then
        echo "Máximos intentos alcanzados. Abortando."
        return 1
      fi
      continue
      valida_deploy
    fi
    sleep 10 # Evitar un bucle infinito con demasiadas iteraciones rápidas
  done
}
###########################################Termina funcion valida_deploy===========

###########################################Inicia funcion rollback=========
rollback() {
  echo INICIANDO REVERSA DE LA APLICACION. rollback
  sudo rm -f "$dir_deploy/${app}"* 2>/dev/null
  sleep 5
  app_roll=$(ls "$dir_backup/${app}"* |tail -1)
  sudo cp -p "$app_roll" "$dir_deploy/$app"
  sudo chown "$user:$user" "$dir_deploy/$app"
  sudo chmod 644 "$dir_deploy/$app"
printf -v mensaje_rollback "
Estimado equipo,

Se ha realizado un rollback de la aplicación '%s' en la instancia '%s' servidor '%s' debido a una falla detectada durante el despliegue más reciente.

Estado: Rollback ejecutado exitosamente
Hora: %s
Versión restaurada: %s

Recomendación:
Revisar los logs para identificar el origen de la falla original y validar que la versión restaurada esté funcionando correctamente.

Saludos,
Sistema de Automatización de Despliegues
" "$app" "$instancia" "$server" "$hora" "$app_roll"
}
###########################################Termina funcion rollback=========

###########################################Inicia funcion realizar_despliegue=========
#Función para realizar el despliegue
realizar_despliegue() {
  echo Inicia realizar_despliegue..
  # Definir rutas y comandos según la versión
  if [[ $version == "jboss-as-7.1.1.Final" || $version == "jboss-eap-7.2" ]]; then
    dir_deploy="$dir_deployments"
    restart_cmd="restart_j7"
  elif [[ $version == "jboss-4.2.2.GA" ]]; then
    dir_deploy="$dir_deployments4"
    restart_cmd="restart_j4"
  else
    echo "Versión de JBoss no soportada: $version"
    return 1
  fi

  # Verificar si la aplicación existe en la instancia antes del despliegue y hacer backup
  if [[ -e "$dir_deploy/$app" ]]; then
    sudo mv "$dir_deploy/$app" "$dir_backup/${app}_${date}"
    sleep 5

    # Validar si el backup se realizó correctamente, si el backup es exitoso realiza la actualización del componente
    if [[ -e "$dir_backup/${app}_${date}" ]]; then
      sudo rm -f "$dir_deploy/${app}"* 2>/dev/null
      last_line=$(cat -n "$JBOSS_HOME"/log/server.log | tail -n 1 | awk '{print $1}' >/dev/null)
      sudo cp "$artifact" "$dir_deploy/"
      sudo chown "$user:$user" "$dir_deploy/$app"
      sudo chmod 644 "$dir_deploy/$app"
      valida_deploy
      if [[ "$reinicio" -eq 1 ]]; then
        $restart_cmd
      fi
    else
      echo "Error: No se pudo crear un backup confiable. Despliegue cancelado."
      return 1
    fi
  else
    # La aplicación no existe y se ejecutara un despliegue nuevo.
    sudo cp "$artifact" "$dir_deploy/"
    echo REALIZANDO DESPLIEGUE...
    echo el valor de  JBOSS_HOME/log/server.log es: "$JBOSS_HOME"/log/server.log
    last_line=$(cat -n "$JBOSS_HOME"/log/server.log | tail -n 1 | awk '{print $1}')
    sudo chown "$user:$user" "$dir_deploy/$app"
    sudo chmod 644 "$dir_deploy/$app"
    valida_deploy
    if [[ "$reinicio" -eq 1 ]]; then
	echo ejecutando reinicio: llama restart_cmd
      $restart_cmd
    fi
  fi
}
###########################################Termina funcion realizar_despliegue=========

###################construte listwars si no existe########
make_listwars()
{
echo "#!/bin/bash" >/usr/local/bin/listwars
echo "       find /opt/jboss-* -maxdepth 4 -iwholename '*standalone*/deploy*/*.war' 2> /dev/null " >>/usr/local/bin/listwars
echo "        find /opt/jboss-4* -maxdepth 4 -iwholename '*server/*/deploy/*.war'| grep -v 'jmx-console.war' 2> /dev/null" >>/usr/local/bin/listwars
chmod 755 /usr/local/bin/listwars
}
########################fin construye listwars
#######################################################################################
#Este for itera con apps aplicaciónes a desplegar en este hostname.
#  Que pasa si la instancia esta abajo? no calcula user..
# Si apps es vacia o no existe? creo que tampoco calcula version, instancia, user.. ni nada.. para mejorar control
# Resolver cuando la app está instalada con el mismo nombre  en mas de una instancia: pasar nombre instancia en este caso
#set  -x
if [ `which listwars` ]; then 
	echo existe listwars
else
	echo no existe listwars !!!!!!!!
	echo creando el listwars...
	make_listwars
	listwars
fi
#valida si instancia está activa
for app in $apps; do
  #Qué pasa si la app está en mas de una version de jboss??
  echo =====================================================Inicia [$app]====================================
  echo Inicia Validaciones para la aplicacion [$app]
  echo
  existe=`listwars|grep $app|wc -l`
  #validando existencia de aplicacion
  if [ $existe -eq 0 ]; then
	  echo "*****aplicacion [$app] no está desplegada actualmente !!!!!*****"
	  #break  #sale y continua con siguiente app
	  echo version es : $version
	  echo instancia es: $instancia
	  #dependiendo del tipo de version asignar los valores.. por implementar acá
	  JBOSS_DOMAIN=/opt/"$version"
	  echo JBOSS_DOMAIN es: $JBOSS_DOMAIN
	  script="subir_"$instancia".sh"
	  echo script es: $script
          JBOSS_HOME=/opt/"$version"/"$instancia"
	  echo JBOSS_HOME es: $JBOSS_HOME
          dir_deployments="$JBOSS_HOME"/deployments
	  echo dir_deployments es :$dir_deployments
	  user=$(ps -fea|grep -v grep |grep $(pgrep -f 'java(.*)jboss(.*)Djboss.home.dir=$JBOSS_DOMAIN(.*)$instancia ')|awk '{ print $1 }')
	  PID=$(pgrep -f 'java(.*)jboss(.*)Djboss.home.dir=$JBOSS_DOMAIN(.*)$instancia ')
  	  artifact="$ruta"/"$app"
	  echo PID es : $PID
	  echo user es: $user
	  sudo cp "$artifact" "$dir_deployments/"
	  ls  -ltr  $dir_deployments/$app
  fi
  version=`listwars|grep $app| awk 'BEGIN{FS="/"} {print $3 }'`
  JBOSS_DOMAIN=/opt/"$version"
  if [ `listwars|grep $app|grep jboss-4` ]; then
		  if [ $(listwars|grep $app|awk 'BEGIN{FS="/"} {print $5 }'|wc -l) -gt 1 ]; then 
			  instancia=$instancia
			  echo "***ESTA APLICACION ESTÁ DESPLEGADA EN MAS DE UNA INSTANCIA CON EL MISMO NOMBRE, NO SE PUEDE GESTIONAR**"
			  listwars|grep $app
		  else
			  instancia=`listwars|grep $app|awk 'BEGIN{FS="/"} {print $5 }'`
		  fi
		  script="subir_"$instancia".sh"
		  JBOSS_HOME=/opt/"$version"/server/"$instancia"
		  dir_deployments="$JBOSS_HOME"/deploy
		  if [ $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia") ]; then
			  echo Instancia activa up!!!
			  user=$(ps -fea|grep -v grep |grep $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")|awk '{ print $1 }')
			  PID=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
		  else
			  user=jboss
			  reinicio=1
			  PID="CAIDA"
		  fi
  else	
		if [ $(listwars|grep $app|awk 'BEGIN{FS="/"} {print $4 }'|wc -l) -gt 1 ]; then
			  instancia=$instancia
			  echo "***ESTA APLICACION [** $app **] ESTÁ DESPLEGADA EN MAS DE UNA INSTANCIA CON EL MISMO NOMBRE, NO SE PUEDE GESTIONAR**"
			  listwars|grep $app
		else
			 instancia=`listwars|grep $app|awk 'BEGIN{FS="/"} {print $4 }'`

		fi  
		script="subir_"$instancia".sh"
		JBOSS_HOME=/opt/"$version"/"$instancia"
		dir_deployments="$JBOSS_HOME"/deployments

		if [ -n $(pgrep -f 'java(.*)jboss(.*)Djboss.home.dir=$JBOSS_DOMAIN(.*)$instancia ') ]; then
			  echo Instancia activa up!!!
			  PR="pgrep -f 'java(.*)jboss(.*)Djboss.home.dir=$JBOSS_DOMAIN(.*)$instancia '"
			  PID=$(eval $PR)
			  echo Es PID: $PID
			  user=$(ps -fea|grep -v grep |grep $PID|awk '{ print $1 }')
		else
			  echo Instancia esta caida hay que validar!!!!
			  user=jboss
			  reinicio=1
			  PID="CAIDA"
		fi
  fi
  
  #Variables
  date=$(date "+%d-%m-%Y_%H-%M")
  hora=$(date "+%d/%m/%Y %H:%M")
  server=$(hostname)
  dir_backup=/home/versiones
  artifact="$ruta"/"$app"
  echo script: $script
  echo instancia: $instancia
  echo version: $version
  echo JBOSS_DOMAIN: $JBOSS_DOMAIN
  echo JBOSS_HOME: $JBOSS_HOME
  echo user:$user
  echo PID jboss: $PID
  echo dir_deployments: $dir_deployments
  echo reinicio= $reinicio
  echo PID Instancia: $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  echo Llamando la funcion de Despliegue para [$app]
  validacion
  echo ===================================finalizando para [$app]========================================
done
echo
echo FINALIZA EJECUCION del cambio $cambio en `hostname`
