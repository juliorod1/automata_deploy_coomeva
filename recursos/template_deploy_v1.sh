#!/bin/bash

#####Autor: William Caicedo, Julio Cesar Rodriguez Ibague- fecha: 2025/03  Version:1.0- Kyndryl WME Colombia

# Validación de parámetros
#if [ "$#" -ne 6 ]; then
#  echo "Uso: $0 <app> <version> <instancia> <script> <user> <ruta>"
#  exit 1
#fi

# Asignación de variables desde los argumentos del script
#app:es nombre del war, versio:es la version de jboss, instancia: es instancia jboos, script: es nombre script para subir
#user: usuario con el que sube el jboss, ruta:  es la fuente del war en servidor de archivos, dato1: cadena ubicación aplicación 
## /opt/jboss-eap-7.1/standalone-transversales/deployments/golden.transformation.service-1.0.0.war

#Lista de aplicaciones a desplegar en este server- variables globales.

#apps="listener.war fabrica_soluciones.war counter.war sor-web18.war"
apps="counter.war sor-web18.war listener.war"
lista_mail="juliorod@kyndryl.com william.caicedo1@kyndryl.com david.naranjo.torres@kyndryl.com joan.alexis.guisao@kyndryl.com johan.lopera@kyndryl.com dlborjac@kyndryl.com robertoa_bravo@coomeva.com.co pedro"
cambio=CRQ000000XXXX79
asunto_fail="FALLO EJECUCION $cambio "
asunto_exitoso="EJECUCION EXITOSA $cambio"
ruta="/home/scripts/automata_ansible"
reinicio=0
instancia="standalone_01"
###########################################Inicia funcion restart_j7=========
restart_j7() {
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia/")
  if [ -n "$pid" ]; then
    sudo kill -9 "$pid" &>/dev/null
    sleep 1
    echo " "
    echo "Se detuvo la instancia $instancia de manera exitosa"
  else
    echo " "
  fi
  sleep 2
  echo " "
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia/")
  if [ -n "$pid" ]; then
    echo " "
  else
    sudo -u "$user" sh "$JBOSS_DOMAIN"/bin/"$script" >/dev/null 2>&1 &
    sleep 2
    last_line=$(cat -n "$JBOSS_HOME"/log/server.log | tail -n 1 | awk '{print $1}')
    echo "Iniciando la instancia $instancia..."
    echo " "
    while true; do
      linea=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME"/log/server.log | grep -Eo "started in|inició en|with errors")
      if [[ "$linea" = "started in" || "$linea" = "inició en" ]]; then
        id=$(pgrep -fa "java.*$JBOSS_DOMAIN.*$instancia/")
        echo "Instancia $instancia en el servidor $server quedo iniciado con el proceso $PID"
        echo " "
        echo "$id"
        break
      elif [[ "$linea" = "with errors" ]]; then
        echo "La instancia $instancia en el servidor $server subio con errores, por favor validar los logs"
        echo " "
        break
      fi
      sleep 5
    done
  fi
}
###########################################Termina funcion restart_j7==========

###########################################Inicia funcion restart_j4===========
restart_j4() {
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  if [ -n "$pid" ]; then
    sudo kill -9 "$pid" &>/dev/null
    sleep 1
    echo " "
    echo "Se detuvo la instancia $instancia de manera exitosa"
  else
    echo " "
  fi
  sleep 2
  echo " "
  pid=$(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  if [ -n "$pid" ]; then
    echo "########################################################################################"
    echo " La instancia $instancia ya se encuentra en ejecución. No se ejecutan acciones administrativas."
    echo "########################################################################################"
  else
    sudo -u "$user" sh "$JBOSS_DOMAIN"/bin/"$script" >/dev/null 2>&1 &
    sleep 2
    last_line=$(cat -n "$JBOSS_HOME4"/log/server.log | tail -n 1 | awk '{print $1}')
    echo "Iniciando instancia $instancia...."
    echo " "
    while true; do
      linea=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME4"/log/server.log | grep -Eo "Started in|Starting failed")
      if [[ "$linea" = "Started in" ]]; then
        id=$(pgrep -fa "java.*$JBOSS_DOMAIN.*$instancia")
        echo "Instancia $instancia en el servidor $server quedo iniciado con el proceso $PID"
        echo " "
        echo "$id"
        break
      elif [[ "$linea" = "Starting failed" ]]; then
        echo "La instancia $instancia en el servidor $server fallo al iniciar, validar los logs"
        echo " "
        break
      fi
      sleep 5
    done
  fi
}
###########################################Termina funcion restart_j4================

###########################################Inicia funcion realizar_despliegue=========
#Función para realizar el despliegue principal
realizar_despliegue() {
  echo -e "\n\n######################################################################"
  echo "#Iniciando despliegue en la instancia '$instancia' del '$version'     "
  echo "######################################################################"
  sleep 2

  # Definir rutas y comandos según la versión
  if [[ $version == "jboss-as-7.1.1.Final" || $version == "jboss-eap-7.2" || $version == "jboss-eap-7.1" ]]; then
    dir_deploy="$dir_deployments"
    restart_cmd="restart_j7"
  elif [[ $version == "jboss-4.2.2.GA" ]]; then
    dir_deploy="$dir_deployments4"
    restart_cmd="restart_j4"
  else
    echo "Versión de JBoss no soportada: $version"
    return 1
  fi

  # Verificar si la aplicación existe antes del despliegue y hacer backup
  if [[ -e "$dir_deploy/$app" &&  -e "$artifact"  ]]; then
    sudo mv "$dir_deploy/$app" "$dir_backup/${app}_${date}"
    echo -e "\nSe realizó backup de la aplicación: $dir_backup/${app}_${date}"

    # Validar si el backup se realizó correctamente, si el backup es exitoso realiza la actualización del componente
    if [[ -e "$dir_backup/${app}_${date}" ]]; then
      sleep 3
      sudo rm -f "$dir_deploy/${app}.undeployed" 2>/dev/null
      sudo cp "$artifact" "$dir_deploy/"
      sudo chown "$user:$user" "$dir_deploy/$app"
      sudo chmod 664 "$dir_deploy/$app"
      if [ $reinicio -eq 1 ]; then
      	echo -e "\nSe inicia reinicio de la instancia $instancia"
      	$restart_cmd
      fi

      # Esperar a que el despliegue se complete
      while true; do
        if [[ $version == "jboss-4.2.2.GA" ]]; then
          deploy_check=$(tail -n +"$((last_line + 1))" "$JBOSS_HOME4"/log/server.log | grep -Eo "End deployment start on package: $app")
        else
          deploy_check=$(ls "$dir_deploy/${app}.deployed" 2>/dev/null)
        fi

        if [[ -n "$deploy_check" ]]; then
          echo -e "\n###############################################"
          echo "# La aplicación se desplegó de manera exitosa #"
          echo "###############################################"
          echo " "
          ls -l "$dir_deploy/${app}"*
          echo " "
          mail
          break
        else
          echo "Error: el despliegue no se realizó de manera correcta, por favor validar la causa del error"
          echo "Hacer reversa de está aplicación: $app" 
          reversa
          mail1
        fi

        sleep 3 # Evitar un bucle infinito con demasiadas iteraciones rápidas
      done
    else
      echo "Error: No se pudo crear un backup confiable. Despliegue cancelado."
      mail1
      return 1
    fi
  else
    echo -e "\nLa aplicación $app no existe en $ruta o en $dir_deploy."
    echo -e "Validar si se debe hacer un despliegue nuevo y la existencia en $artifact"
    mail1
    return 1
  fi
  echo ===============================================================================================
}
###########################################Termina funcion realizar_despliegue=========

####FUNCIONES PARA NOTIFICACION MAIL Y ROOLBACK#########

mail1()
{
echo enviando notificación mail.. falla
}
 mail()
{
echo enviando notificacionmail.. exitosa 
}
reversa()
{
echo Realizando reversa de $app
echo la aplicacion en tiempo de despliegue falla, archivo de marca failed o error critico en el log del server.
}
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
	listwars1
fi
#valida si instancia está activa
for app in $apps; do
  #Qué pasa si la app está en mas de una version de jboss??
  echo =====================================================Inicia [$app]====================================
  echo Inicia Validaciones para la aplicacion [$app]
  echo
  version=`listwars|grep $app| awk 'BEGIN{FS="/"} {print $3 }'`
  JBOSS_DOMAIN=/opt/"$version"
  if [ `listwars|grep $app|grep jboss-4` ]; then
		  if [ $(listwars|grep $app|awk 'BEGIN{FS="/"} {print $5 }'|wc -l) -gt 1 ]; then 
			  instancia=$instancia
			  echo "***ESTA APLICACION ESTÁ DESPLEGADA EN MAS DE UNA INSTANCIA CON EL MISMO NOMBRE, NO SE PUEDE GESTIONAR**"
			  listwars|grep $app
			  #notifica mail
		  else
			  instancia=`listwars|grep $app|awk 'BEGIN{FS="/"} {print $5 }'`
		  fi
		  script="subir_"$instancia".sh"
		  JBOSS_HOME=/opt/"$version"/server/"$instancia"
		  dir_deployments="$JBOSS_HOME"/deploy
		  if [ $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia") ]; then
			  echo Instancia activa up!!!
			  user=$(ps -fea|grep -v grep |grep $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")|awk '{ print $1 }')
		  else
			  user=jboss
			  reinicio=0
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
		if [ $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia") ]; then
			  echo Instancia activa up!!!
			  user=$(ps -fea|grep -v grep |grep $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")|awk '{ print $1 }')
		else
			  echo Instancia esta caida hay que validar!!!!
			  user=jboss
			  reinicio=0
		fi
  fi
  
  #Variables
  date=$(date "+%d-%m-%Y_%H-%M")
  server=$(hostname)
  dir_backup=/home/versiones
  artifact="$ruta"/"$app"
  echo script: $script
  echo instancia: $instancia
  echo version: $version
  echo JBOSS_DOMAIN: $JBOSS_DOMAIN
  echo JBOSS_HOME: $JBOSS_HOME
  echo user:$user
  echo dir_deployments: $dir_deployments
  echo reinicio= $reinicio
  echo PID Instancia: $(pgrep -f "java.*$JBOSS_DOMAIN.*$instancia")
  echo Llamando la funcion de Despliegue para [$app]
  realizar_despliegue
  echo ===================================finalizando para [$app]========================================
done
echo
echo FINALIZA EJECUCION del cambio $cambio en `hostname`
