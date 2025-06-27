#####WME Kyndryl Colombia Marzo/2023 - Autor: Julio Cesar Rodriguez Ibague, William Caicedo- Version: 1.0######
LISTA_COPY=""
COMPARTIDO="/home/scripts/automata_ansible/jboss"
HISTORICO="/home/scripts/automata_ansible/jboss/historico_ejecutado"
PROJECT_HOME="/ansible"
INVENTORY="$PROJECT_HOME/hosts.cfg"
PROGRAMACION="/ansible/programacion/listado_programacion.txt"
email="juliorod@kyndryl.com william.caicedo1@kyndryl.com david.naranjo.torres@kyndryl.com joan.alexis.guisao@kyndryl.com johan.lopera@kyndryl.com dlborjac@kyndryl.com robertoa_bravo@coomeva.com.co"
prog=1
clear
echo "			AUTOMATIZACION DESPLIEGUE APPLICACIONES COOMEVA"
echo "			==============================================="
echo







echo "Este mensaje se muestra después de cada selección."

#########Funcion para cancelar la programacion de un cambio de jboss#####
cancela()
{
clear
PROGRAMACION="/ansible/programacion/listado_programacion.txt"
cambio=""
#para solo programacion sin ejecutar selecciona
archivo_temporal=$(mktemp -p /ansible/programacion)
fecha_actual_sg=$(date +%s)
while IFS= read -r linea; do
	fecha_pr_sg=`echo "$linea"|awk 'BEGIN{FS=";"} { print $2 }'`
	fecha_pr=$(date -d "$fecha_pr_sg" +%s 2>/dev/null)
	estado=`echo "$linea"|awk 'BEGIN{FS=";"} { print $5 }'`
	if [[ "$fecha_pr" -le "$fecha_actual_sg" ]] && [[ "$estado"=="PROGRAMADO" ]] ; then
		echo "$linea" | sed  's/PROGRAMADO/EJECUTADO/g' >>$archivo_temporal
	else
		echo "$linea" >>$archivo_temporal
	fi

done < "$PROGRAMACION"
mv $archivo_temporal $PROGRAMACION
echo
echo " 				**LISTA DE CAMBIOS AGENDADOS**								     "
echo
echo "======================================================================================================================="
echo "No CAMBIO		FECHA	     SERVIDOR				PROGRAMA		    	   ESTADO       |"
cat $PROGRAMACION|grep PROGRAMADO|awk 'BEGIN{FS=";"} { print $1" | "$2" | "$3" | "$4" | "$5" | "}'
echo "======================================================================================================================="
echo
echo "***Vamos a seleccionar el cambio a cancelar su ejecucion del siguiente menu, de acuerdo con el listado anterior"
echo
#opciones=(`cat $PROGRAMACION|grep PROGRAMADO|awk 'BEGIN{FS=";"} { print $1"::"$3}'` "Salir" "Continuar")
opciones=(`cat $PROGRAMACION|grep PROGRAMADO|awk 'BEGIN{FS=";"} { print $1 }'|sort -u` "Salir" "Continuar")
select opcion in "${opciones[@]}"; do
    case $opcion in
        "Salir")
            echo "Saliendo del menú..."
            break
            ;;
   "Continuar") echo continuando con el proceso de cancelacion..
	    ;;
        *)
            #echo "Has seleccionado: $opcion"
            for i in "${!opciones[@]}"; do # Iteramos sobre los índices del array
                if [[ "${opciones[$i]}" == "$opcion" ]]; then # Comparamos el contenido
                    #echo "Índice: $i"  y "${opciones[$i]}"
                    # Aquí puedes agregar el código para procesar el índice y el contenido
		    cambio+="${opciones[$i]}"
		    #b=`echo $cambio|awk 'BEGIN{ FS="::"} { print $1}'`
		    b=$cambio
		    s=$(grep $b $PROGRAMACION|grep PROGRAMADO|awk 'BEGIN{FS=";"} { print $3}')
		    c1=/home/deployuser/bin/template_deploy_$b.sh
		    echo El cambio a cancelar es: [$b] en los siguientes servidores: $s
		    sleep 3
		    for j in $s; do
			echo Cancelando programacion en $j...
			ansible-playbook -i $INVENTORY --limit $j cancel-deploy.yml --extra-vars "app_play=$c1"
		    done
		sed -i "/$b/s/PROGRAMADO/CANCELADO/g" $PROGRAMACION
                    #break # Salimos del bucle for cuando encontramos la opción
                fi
            done
            break
            ;;
    esac
done
}
############fin de cancelar_jboss()######################################
#######funcion para validar fecha y hora####
fecha()
{

read -p "Introduce la fecha y hora (YYYY-MM-DD HH:MI): " fecha_hora

# Validación del formato con grep
if ! echo "$fecha_hora" | grep -Eq "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$"; then
    echo "Formato incorrecto. Usa YYYY-MM-DD HH:MM"
    return  1
fi

# Validación de la fecha y hora y conversión a segundos desde Epoch
fecha_hora_segundos=$(date -d "$fecha_hora" +%s 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "Fecha y hora no válidas"
    return 1
fi

# Validación de fecha y hora futura
fecha_hora_actual_segundos=$(date +%s)

if [[ "$fecha_hora_segundos" -le "$fecha_hora_actual_segundos" ]]; then
    echo "La fecha y hora deben estar en el futuro"
    return 1
fi

echo "Fecha y hora válidas y en el futuro: $fecha_hora"
return 0
}
###############################

#funcion desplegar con ansible
deploy()
{
list_servers=$2
CR=$1
clear
for server in $list_servers; do
  clear
  echo
  echo "				===PROGRAMANDO PARA EL SERVIDOR [$server]=====			"
  echo
  echo Recuperando listado de aplicaciones del servidor..... wait...
  echo "				Listado de Aplicaciones Disponibles en [$server]"
  echo "			======================================================================"
  list_wars=""
  while [[ $list_wars == "" ]]; do
	  #set -x
	  #echo List del while es:$list_wars
	  echo Aun No ha selecionado aplicaciones..
	  sleep 2
  echo   "				APLICACIONES DISPONIBLE PARA $server"
  #siempre hay que garantizar el campo 6  del archivo de aplicaciones con el nombre de la aplicacion.
  opciones=(`cat Lista_aplicaciones/$server.txt|awk 'BEGIN{FS="/"} { print $6 }'` Continuar) 
  #opciones=(`cat Lista_aplicaciones/$server.txt` Continuar) de esta forma se soluciona la misma app en mas de 1 instancia o version de jboss, en el template se ajusta
  PS3="                            Elige una opción o digite cualquier tecla: "
  select opt in "${opciones[@]}"
  do
     for i in "${opciones[($REPLY-1)]}"; do
       #echo el valor de REPLY es: $REPLY y "${opciones[($REPLY-1)]}"
      if [ $REPLY  ]; then
         #echo valor de REPLY es: $REPLY y de i es: $i
         if [ "$i" != "Continuar" ] && [ "$i" != "" ]; then
            #set -x
            #echo "REPLY es: $REPLY" y de i es $i:hola
            #app="$list_wars $i"
            #list_wars=""$list_wars" "${opciones[($REPLY-1)]}""
            list_wars+="${opciones[($REPLY-1)]} "
            echo Aplicaciones selecionadas son:[$list_wars]
         else
            #echo Aplicaciones selecionadas son: $list_wars
	    if   [[ "$list_wars" == "" ]] && [ "$i" == "" ]; then
                 echo NO HA SELECCIONADO NINGUNA APLICACION!!!. DEBE SELECCIONAR  UNA OPCION VALIDA.
                 sleep 2
	    else
		   #echo $i
		   if [ "$i" == "" ]; then
			   echo opcion Invalida!!
			   break
	            fi
		   #set x
		   #echo OK hay  app hay:$list_wars
		   break 2
            fi
            #break
         fi
      fi
     done #(for)
  done #(select)
  done #(while)
  clear
  echo   "	APLICACIONES SELECCIONADAS  PARA [$server]:"
  echo "[$list_wars"]
  #echo contenido de apps es:$list_wars
  ###########
  echo
  echo -Indique la Hora en la cual se ejecutará en el servidor $server esta actividad, en formato "YYYY-MM-DD HH:MI"
  alias date=gdate
  echo Ejemplo: `date +"%Y-%m-%d 19:00"`
  ## se debe ingresar la fecha sin comillas, ni simples no dobles para que funcione la validacion
  while (true); do
  fecha
  a=$(echo $?)
  #echo $a
  if [  $a -eq 0 ]; then 
	  echo fecha Valida!!
	  break
  else 
	  echo fecha Invalida!!
  fi 
  #echo $?
  done
  ########
  echo
  echo -Indique si requiere que la instancia de Jboss en [$server] sea reiniciada una vez se instale las aplicaciones [$list_wars]
  echo
  echo Digite el 0 para NO reinciar.
  echo Digite el 1 Para SI reiniciar
  read rein
  clear
  echo
  ########
  echo generando plantilla con ansible para las app [$list_wars] en el servidor  $server... un momento...
  sleep 2
  echo at_datetime: '"'$fecha_hora'"' >$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo cambio: $CR >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo servidor: $server >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo apps: '"'$list_wars'"' >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo reinicio: $rein >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo emails: '"'$email'"' >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo -e "archivos_a_transferir:" >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo  $list_wars
  sleep 1
  for i in $list_wars; do
        echo " - $i" >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  done
  cat $PROJECT_HOME/deploy_jboss/vars/var_temp.txt > $PROJECT_HOME/deploy_jboss/vars/main.yml
  cat $PROJECT_HOME/var_jboss_"$CR"_"$server".txt >> $PROJECT_HOME/deploy_jboss/vars/main.yml
  mv $PROJECT_HOME/var_jboss_"$CR"_"$server".txt $PROJECT_HOME/historico/

   clear
   echo ===RESUMEN DE PROGRAMACION PARA EL [$cambio] en [$server] ES LA SIGUIENTE:
   cat $PROJECT_HOME/historico/var_jboss_"$CR"_*.txt #$PROJECT_HOME/historico/cancelado_"$CR".txt
   echo
   echo -Desea continuar con la programación...? 
   echo
   echo "*Digite 1 para Continuar con la programacion."
   echo "*Digite 0 Para cancelar este proceso."
   echo
   read nexts
   echo usted ha digitado $nexts..
   if [ $nexts == 1 ]; then
      echo
      echo Inicia preparacion y envio de programación y ejecucion a $server...
      ansible-playbook -i $INVENTORY --limit=$server  deploy-jboss.yml 
      #valida ejecucion de ansible playbook
      exit_code=$?
      echo "$exit_code"
      echo "Esté fue el codigo de respuesta al ejecutar el playbook, si es diferente de 0, esto ha fallado!!"
      sleep 5
      if [ "$exit_code" -ne 0 ]; then
	echo
        echo "La ejecución del playbook falló. Código de salida: $exit_code"
        echo FALLA LA PROGRAMACION DE ESTE CAMBIO POR FALLAS EN LA EJECUCION DE PLAYBOOK ANSIBLE
        sleep 5
	exit $exit_code
        ##exit 1 # O cualquier otro código de salida no cero para indicar que el script también falló
      fi
      echo identificando job en caso de cancelar cambio.
      ansible $server -m command -a "at -l"
      #Genera datos de ejecucion en caso que se requiera cancelar el cambio posteriormente y estadisticas
      echo "$cambio;$fecha_hora;$server;/home/deployuser/bin/template_deploy_$cambio.sh;PROGRAMADO" >>$PROGRAMACION
   else
      echo
      echo cancelada la programación del cambio..
      echo "***CAMBIO CANCELADO en [$server] *****"  >> $PROJECT_HOME/historico/var_jboss_"$CR"_"$server".txt
      mv $PROJECT_HOME/historico/var_jboss_"$CR"_"$server".txt  $PROJECT_HOME/historico/cancelado_"$CR".txt
      break 2
   fi
done
#clear
echo ===RESUMEN DE PROGRAMACION PARA EL [$cambio] ES LA SIGUIENTE:
cat $PROJECT_HOME/historico/var_jboss_"$CR"_*.txt #$PROJECT_HOME/historico/cancelado_"$CR".txt
echo
echo La siguiente es la lista de artefactos que se usaran para el cambio $cambio en los servidores [$server]:
echo " [ $list_wars ]"
echo
echo Digite cualquier tecla  para  continuar..
read pro
}

#===============Menu principal==============
while [ $prog  -eq 1 ]; do
#PS3="Elige tu opción: "
opciones=(			 "Deploy_jboss" "Deploy_micros" "Deploy_docker" "Deploy_tomcat" "Reinicios" "CheckList" "Deploy_soa" "Reportes" "Salir" )
PS3="				 Elige una opción Válida,o ENTER para continuar.."
select opt in "${opciones[@]}"
do
    case $opt in 

        "Deploy_jboss") clear
			echo
			echo "			Has elegido Programar/Cancelar  un  cambio en jboss  applicaciones!!!! " 
			echo
			echo "			Indiqueme Qué vá a hacer: "
			echo 
			opciones1=("Programar Cambio" "Cancelar Cambio" "Salir")
			PS3="Elige Una Opcion o ENTER:  "
			select opt1 in "${opciones1[@]}"; do
				case $opt1 in
					"Programar Cambio") clear
  		     			  echo Vamos a Ingresar la información minima necesaria para poder hacer esta tarea.
					  echo
         	     			  echo -Indique el  numero de cambio de Remedy:
  		   			  echo Por ejemplo: CRQ000000XXXX70
					  read cambio
					  echo   
					  echo Vamos a Indicar la lista de correos adicionales a los cuales notificaremos el resultado de este cambio.
					  echo
					  echo El proceso siempre notificará a la siguiente lista de buzones:
					  echo
					  echo [$email]
					  echo
					  echo -Escriba los buzones en la misma linea separados por un espacio:
					  echo
					  read email1
					  email="$email $email1"
					  echo
					  echo -Seleccione de la Lista de  servidores de Jboss a desplegar:
					  echo
					  echo ===========servidores Disponibles=====
					  servidores=""
					  echo   "SERVIDORES DE JBOSS DISPONIBLES"
					  echo
					  opciones=(`cat hosts.cfg|grep "servicios=jboss"|awk 'BEGIN{FS=" "} { print $1 }'` Continuar)
					  PS3="				 Elige una opción o digite cualquier tecla:   Para continuar.."
					  select opt in "${opciones[@]}"
					  do
					  for i in "${opciones[($REPLY-1)]}"; do
					  #echo el valor de REPLY es: $REPLY y "${opciones[($REPLY-1)]}"
					  if [ $REPLY  ]; then
					  #echo valor de REPLY es: $REPLY y de i es: $i
					  if [ "$i" != "Continuar" ]; then
					  #echo "REPLY es: $REPLY" y de i es $i
					  #servidores="$servidores $i"
					  servidores=""$servidores" "${opciones[($REPLY-1)]}""
					  echo Servidores selecionados son: [$servidores]
					  else
					  echo Servidores selecionados son: [$servidores]
					  if   [ "$servidores" == "" ]; then
					  echo NO HA SELECCIONADO NINGUN SERVIDOR!!!. DEBE SELECCIONAR ALMENOS UNO.
					  sleep 2
					  break
					  fi
					  sleep 2
					  break 2
					  fi
					  fi
					  done
					  done
					  clear
					  echo   "SERVIDORES SELECCIONADOS PARA ESTE CAMBIO:"
					  echo - [$servidores]
					  deploy "$cambio" "$servidores"
					  clear
					  ;;
				  "Cancelar Cambio") clear
					  cancela
					  ;;
				  "Salir")  break; clear;
					  ;; 
				  *) echo "Opcion no válida."
		  		esac
			done #fin select cancelar	
        ;;

        "Deploy_micros") echo "Has elegido deploy_micros" 
		/ansible/microservicios/programa_micros.sh
        ;;

        "Deploy_docker") echo "Has elegido deploy_docker "
                date; 
        ;;

        "Otros") echo "Has elegido gestionar Otras opciones"
                date;
        ;;
        "Deploy_soa") echo "VAMOS AGESTIONAR SOBRE PRODUCTOS IBM"
		clear
		/ansible/soa/programa_soa.sh
		;;
		
        "Salir") break 2
      
        ;;
        *) echo "Opcion no válida."
    esac
done
prog=0
done
