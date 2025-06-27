#####WME Kyndryl Colombia Marzo/2023 - Autor: Julio Cesar Rodriguez Ibague, William Caicedo- Version: 1.0######
COMPARTIDO="/home/scripts/automata_ansible/Broker"
HISTORICO="/home/scripts/automata_ansible/Broker/historico_ejecutado"
PROJECT_HOME="/ansible"
INVENTORY="$PROJECT_HOME/hosts.cfg"
PROGRAMACION="/ansible/programacion/listado_programacion_soa.txt"
email="juliorod@kyndryl.com william.caicedo1@kyndryl.com david.naranjo.torres@kyndryl.com joan.alexis.guisao@kyndryl.com johan.lopera@kyndryl.com dlborjac@kyndryl.com robertoa_bravo@coomeva.com.co jhonfreddy.osorio@kyndryl.com edwin.giraldo@kyndryl.com"
prog=1
clear
echo "			AUTOMATIZACION DESPLIEGUE APPLICACIONES COOMEVA SOA"
echo "			==================================================="
echo

#########Funcion para cancelar la programacion de un cambio de jboss#####
cancela()
{
clear
PROGRAMACION="/ansible/programacion/listado_programacion_soa.txt"
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
echo " 				**LISTA DE CAMBIOS AGENDADOS PARA SOA**								     "
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
		    c1=/home/deployus/bin/template_deploy_$b.sh
		    echo El cambio a cancelar es: [$b] en los siguientes servidores: $s
		    sleep 3
		    for j in $s; do
			echo Cancelando programacion en $j...
			ansible-playbook -i $INVENTORY --limit $j $PROJECT_HOME/cancel-deploy_soa.yml --extra-vars "app_play=$c1"
			exit_code=$?
			echo "$exit_code"
			echo "Esté fue el codigo de respuesta al ejecutar el playbook, si es diferente de 0, esto ha fallado!!"
			sleep 5
			if [ "$exit_code" -ne 0 ]; then
				echo "La ejecución del playbook falló. Código de salida: $exit_code"
				echo FALLA LA CANCELACIO EN [$j]  DE ESTE CAMBIO POR FALLAS EN LA EJECUCION DE PLAYBOOK ANSIBLE
				sed -i "/$b/s/PROGRAMADO/PROGRAMADO/g" $PROGRAMACION
				sleep 5
				break
			fi
		        sed -i "/$b/s/PROGRAMADO/CANCELADO/g" $PROGRAMACION

		    done
                    #break # Salimos del bucle for cuando encontramos la opción
                fi
            done
            break
            ;;
    esac
done
}
############fin de cancelar_soa()######################################
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
lista_files=""
clear
for server in $list_servers; do
  #Se ejecuta para crear un nuevo grupo de ejecucion
  echo Empecemos!!!!!!
  echo
  echo -Este cambio requiere la creación de nuevos grupos de ejecucion en el Broker del servidor [$server]?
  echo *Digite 1 para SI
  echo *Digite 0 para NO
  echo Digite su Opcion..
  read crea_e
  if [ $crea_e -eq 1 ]; then
	lista_files+="NO_APLICA "
        echo hay los siguientes node Broker Disponibles en [$server]:
        grep  "Integration node"  $PROJECT_HOME/Lista_aplicaciones/datos_$server.txt
        echo *ESCRIBA el nombre Broker Node en el cual vá crear el grupo de ejecución..
	echo
        read nom_broker
        echo -Ahora debe indicarme el nombre que tendrá el nuevo grupo de ejecución: no debe incluir espacios, caracteres especiales..
        echo *ESCRIBA el nombre  para el nuevo grupo de ejecución..
        read nom_e
        echo
  else
          crea_e=NO
	  lista_files+="NO_APLICA "
          echo No se crearan un nuevo grupo de ejecución
  fi
  ####
  clear
  echo Ahora vamos a seleccionar grupos de ejecucion a actualizar en  [$server]  !!!!
  echo "				===PROGRAMANDO PARA EL SERVIDOR [$server]=====			"
  echo
  echo Recuperando listado de grupos de ejecucion del servidor..... wait...
  echo "				Listado de Grupos de Ejecucion en [$server]"
  echo "			======================================================================"
  echo  "Integration node $(grep  "Integration node"  $PROJECT_HOME/Lista_aplicaciones/datos_$server.txt)"
  Integration_node=`grep  "Integration node"  $PROJECT_HOME/Lista_aplicaciones/datos_$server.txt|awk '{ print $4 }'`
  echo "                       ====================================================================="
  list_wars=""
  list_node=""
  while [[ $list_wars == "" ]]; do
	  echo Aun No ha selecionado aplicaciones..
	  sleep 1
  echo   "				GRUPOS DE EJECUCION DISPONIBLES PARA [$server]"
  opciones=(`cat $PROJECT_HOME/Lista_aplicaciones/$server.txt|awk '{ print $1 }'` Continuar)
  PS3="                            Elige una opción o digite cualquier tecla: "
  select opt in "${opciones[@]}"
  do
     for i in "${opciones[($REPLY-1)]}"; do
       #echo el valor de REPLY es: $REPLY y "${opciones[($REPLY-1)]}"
      if [ $REPLY  ]; then
         #echo valor de REPLY es: $REPLY y de i es: $i
         if [ "$i" != "Continuar" ] && [ "$i" != "" ]; then
            #list_wars+="${opciones[($REPLY-1)]} "
	    if [ "${opciones[($REPLY-1)]}" == "NO_APLICA" ]; then
		    echo ***No se desplegará en ningún grupo de ejecución..
		    list_wars+="${opciones[($REPLY-1)]} "
		    lista_files+="NO_APLICA "
		    break 2
            fi
	    echo -Indique el nombre del archivo *.bar que será desplegado en: ["${opciones[($REPLY-1)]}"]
	    echo
	    echo ***hay Los siguientes bar disponibles:
	    ls   /home/scripts/automata_ansible/Broker/|grep -E '*.bar'
	    echo ***ESCRIBA a continuacion el nombre del war..ojo..
	    read bar
	    lista_files+="$bar "
	    echo
	    echo "-Indique si desea que el grupo de Ejecucion sea Reiniciado?"
	    echo "*Digite un 1 si desea que se reinicie el IS."
	    echo "*Digite un 0 Para no reinciar el IS"
	    echo ***DIGITE opcion..
	    read rein
	    s1=$(head -$REPLY $PROJECT_HOME/Lista_aplicaciones/$server.txt|tail -1|awk '{ print $2 }')
	    list_node+="$s1 "
	    list_wars+="${opciones[($REPLY-1)]};$bar;$rein;$s1 "
            echo "Grupos de Ejecución selecionadas son:[$list_wars]"
         else
            #echo Aplicaciones selecionadas son: $list_wars
	    if   [[ "$list_wars" == "" ]] && [ "$i" == "" ]; then
                 echo NO HA SELECCIONADO NINGUN GRUPO DE EJECUCION!!!. DEBE SELECCIONAR  UNA OPCION VALIDA.
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
  echo   "	GRUPOS DE EJECUCION SELECCIONADOS  PARA [$server]:"
  echo "[$list_wars]" #lista de $IS
  echo 
  #se define si es necesario crear un grupo de ejecución en el node integration y si es ne
  echo -Este cambio requiere la creacion de componetes del MQ como una una cola de ejecucion en este [$server]..?
  echo *Digite 1 para SI
  echo *Digite 0 para NO
  echo Digite su Opcion..
  read crea_mq
  if [ $crea_mq -eq 1 ]; then
	echo hay los siguientes gestores de colas Disponibles en [$server]:
	grep  "QMNAME"  $PROJECT_HOME/Lista_aplicaciones/datos_$server.txt
        echo *ESCRIBA el nombre del gestor de colas en el cual vá a crear una cola..
	read nom_gestor
	echo -Ahora debe indicarme el nombre del script para la creacion de la cola con extensión *.mqsc
	echo Hay los siguientes disponibles en la ruta:
	ls /home/scripts/automata_ansible/Broker/*.mqsc
	echo *ESCRIBA el nombre del script..
	read script_cola
	lista_files+="$script_cola "
	echo 
  else
	  crea_mq=NO
	  lista_files+="NO_APLICA"
	  echo No se crearan colas en el MQ
  fi
  ###########
  echo
  echo -Indique la Hora en la cual se ejecutará en el servidor [$server] esta actividad, en formato "YYYY-MM-DD HH:MI"
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
  echo at_datetime: '"'$fecha_hora'"' \#Hora de programacion  >$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo cambio: $CR >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo servidor: $server >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo "crea_ge: $crea_e  #creará un grupo de ejecucion" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo nombre_broker: $nom_broker >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo "nom_ge: $nom_e #nombre del grupo de ejecucion" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo aplicaciones: '"'$list_wars'"' \#bar a desplegar, grupo, reinicio >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo "crea_mqc: $crea_mq #creará una cola en el MQ" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo "nom_gestorMQ: $nom_gestor #nombre del MQ" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo script_colaMQ: $script_cola >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt 
  echo emails: '"'$email'"' >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo -e "archivos_a_transferir:" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  echo  $lista_files
  sleep 5
  for i in $lista_files; do
        echo " - $i" >>$PROJECT_HOME/deploy_soa_"$CR"_"$server".txt
  done
  cat $PROJECT_HOME/deploy_soa/vars/var_temp.txt > $PROJECT_HOME/deploy_soa/vars/main.yml
  cat $PROJECT_HOME/deploy_soa_"$CR"_"$server".txt >> $PROJECT_HOME/deploy_soa/vars/main.yml
  mv $PROJECT_HOME/deploy_soa_"$CR"_"$server".txt $PROJECT_HOME/historico/
  cd $PROJECT_HOME
   ########

   clear
   echo ===RESUMEN DE PROGRAMACION PARA EL [$cambio] en [$server] ES LA SIGUIENTE:
   cat $PROJECT_HOME/historico/deploy_soa_"$CR"_*.txt #$PROJECT_HOME/historico/cancelado_"$CR".txt
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
      ansible-playbook -i $INVENTORY --limit=$server  deploy-soa.yml 
      #ojo verificar si ansible fue exitoso sino se falla programacion
      exit_code=$?
      echo "$exit_code"
      echo "Esté fue el codigo de respuesta al ejecutar el playbook, si es diferente de 0, esto ha fallado!!"
      sleep 5
      if [ "$exit_code" -ne 0 ]; then
  	echo "La ejecución del playbook falló. Código de salida: $exit_code"
	echo FALLA LA PROGRAMACION DE ESTE CAMBIO POR FALLAS EN LA EJECUCION DE PLAYBOOK ANSIBLE
	sleep 5
	exit 1
  	##exit 1 # O cualquier otro código de salida no cero para indicar que el script también falló
      fi
      echo identificando job en caso de cancelar cambio.
      ansible $server -m command -a "at -lv"
      sleep 5
      #Genera datos de ejecucion en caso que se requiera cancelar el cambio posteriormente y estadisticas
      echo "$cambio;$fecha_hora;$server;/home/deployuser/bin/template_deploy_$cambio.sh;PROGRAMADO" >>$PROGRAMACION
   else
      echo
      echo cancelada la programación del cambio..
      echo "***CAMBIO CANCELADO en [$server] *****"  >> $PROJECT_HOME/historico/deploy_soa_"$CR"_"$server".txt
      mv $PROJECT_HOME/historico/deploy_soa_"$CR"_"$server".txt  $PROJECT_HOME/historico/cancelado_"$CR".txt
      break 2
   fi
done
clear
echo ===RESUMEN DE PROGRAMACION PARA EL [$cambio] ES LA SIGUIENTE:
cat $PROJECT_HOME/historico/deploy_soa_"$CR"_*.txt #$PROJECT_HOME/historico/cancelado_"$CR".txt
echo Digite cualquier tecla  para  continuar..
read pro
#moviendo archivos desde el directorio /home/scripts/automata_ansible/Broker/$server/ a historico_ejecutados/cambio
origen=$COMPARTIDO
dest=$HISTORICO/$cambio
sudo mkdir -p $dest
for i in $lista_files; do
	sudo mv $origen/$i $dest
done
}
#fin  funcion desplegar con ansible
#===============Menu principal soa==============
while [ $prog  -eq 1 ]; do
echo "										Fecha actual: $(date)" # Muestra la fecha actual
#PS3="Elige tu opción: "
opciones=(			 "Gestionar_soa" "Reinicios_soa" "Otros" "Reportes" "Salir" )
PS3="				 Elige una opción Válida,o ENTER para continuar.."
select opt in "${opciones[@]}"
do
    case $opt in 

        "Gestionar_soa") clear
			echo
			echo "			Has elegido Programar/Cancelar cambios de SOA IBM!!!! " 
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
					  echo -Seleccione de la Lista de  servidores de Microservicios a desplegar:
					  echo
					  echo ===========servidores Disponibles=====
					  servidores=""
					  echo   "SERVIDORES DE SOA-IBM DISPONIBLES"
					  echo
					  opciones=(`cat $PROJECT_HOME/hosts.cfg|grep broquer|awk 'BEGIN{FS=" "} { print $1 }'` Continuar)
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
				  "Cancelar Cambio")
					  echo "Vamos a realizar proceso de Cancelación de un Cambio de SOA!!!"
					  cancela
					  ;;
				  "Salir")  break; clear;
					  ;; 
				  *) echo "Opcion no válida."
		  		esac
			done #fin select cancelar	
        ;;

        "Reinicios_soa") echo "Has elegido reiniciar productos SOA IBM" 
                date; 
        ;;


	"Reportes") echo "Has Elegido generar un reporte de cambios programados de SOA"
                date; 
        ;;

        "Otros") echo "Has elegido gestionar Otras opciones"
                date;
        ;;
		
        "Salir") break 2
        	
        ;;
        *) echo "Opcion no válida."
    esac
done
prog=0
done
