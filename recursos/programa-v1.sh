PROJECT_HOME="/Users/juliorod/ansible/jboss"
prog=1
#funcion desplegar con ansible
deploy()
{
list_servers=$2
CR=$1
clear
for server in $list_servers; do
  clear
  echo ===PROGRAMANDO PARA EL SERVIDOR $server=====
  echo
  echo Recuperando listado de aplicaciones del servidor..... wait...
  echo Listado de Aplicaciones Disponibles en $server
  echo ======================================================================
  #ansible 10.12.13.190 -m command -a listwars|awk 'BEGIN{FS="/"} {print "-Instancia: "$4 " App: *"$6 }'>apps_$server.list
  clear 
  cat $PROJECT_HOME/Lista_aplicaciones/$server.txt|awk 'BEGIN{FS="/"} { print "- "$6 }'
  echo =======================================================================
  echo 
  echo Indique la lista de wars a desplegar en jboss de == $server == :
  echo **Escriba el nombre de los wars,sin espacios en el nombre y separados por un espacio en la misma linea**
  echo Por ejemplo: "hello-word.war a1.war a2.war"
  read list_wars
  clear
  echo $list_wars
  echo vamos a comprobar que las aplicaciones están en el inventario...
  for l in $list_wars; do
    #if [ `grep "$l" $PROJECT_HOME/Lista_aplicaciones/$server.txt` ]; then
    if [ `grep "$l" $PROJECT_HOME/Lista_aplicaciones/cdplin115.txt` ]; then 
       echo ok $l
    else
    echo La app $l no está en el inventario de aplicaciones para $server.
    break 1
    fi
  done
  echo
  echo Indique la Hora en la cual se ejecutará en el servidor $server esta actividad, en formato "yyyy-mm-dd hh:mm:ss"
  echo
  echo **Ingrese los datos entre comillas dobles, son tratados como string***
  echo Ejemplo: '"2025-03-14 18:30:00"'
  echo
  now=`date +"%Y-%m-%d %H:%M:%S"`
  read at_tiempo
  echo  Esta es la fecha de ejecución que está ingresando: $at_tiempo  .. Vamos a comprobar que es válida.. 
  if [[  $now < $at_tiempo ]]; then 
     echo fecha Futura es correcta para programar en crontab la ejecución.
  else
     echo Fecha ingresada está en el pasado.. no sirve...
     break 1
  fi
  echo
  echo Indique si requiere que la instancia de Jboss en $server sea reiniciada una vez se instale las aplicaciones $list_wars
  echo el default/omision es No, Digite 0 para NO y 1 para SI.
  read rein
  echo generando plantilla para $server... un momento...
  echo ins_app: $ins_jboss >$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo src_app: $src_war >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo at_datetime: $at_tiempo >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo cambio: $CR >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo servidor: $server >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo apps: $list_wars >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  echo reinicio: $rein >>$PROJECT_HOME/var_jboss_"$CR"_"$server".txt
  cat $PROJECT_HOME/deploy_jboss/vars/var_temp.txt > $PROJECT_HOME/deploy_jboss/vars/main.yml
  cat $PROJECT_HOME/var_jboss_"$CR"_"$server".txt >> $PROJECT_HOME/deploy_jboss/vars/main.yml
  mv $PROJECT_HOME/var_jboss_"$CR"_"$server".txt $PROJECT_HOME/historico/
  cd $PROJECT_HOME
 # echo esta linea ejecutara..
  ##ansible-playbook --limit=$server  deploy-jboss.yml --extra-vars "cambio=$CR apps=$list_wars servidor=$server reinicio=$rein at_datetime=$at_tiempo"
   echo
   echo ===RESUMEN DE PROGRAMACION PARA EL $cambio en $server ES LA SIGUIENTE:
   cat $PROJECT_HOME/historico/var_jboss_"$CR"_*.txt
   echo
   echo Quiere continuar...? digite 1 para continuar y 0 o cualquier tecla  para cancelar.
   read nexts
   echo usted ha digitado $nexts..
   if [ $nexts == 1 ]; then
      echo Inicia preparacion y envio de programación y ejecucion a $server...
      ansible-playbook --limit=$server  deploy-jboss.yml 
   else
      echo cancelada la programación del cambio..
      echo ***CAMBIO CANCELADO*****  > $PROJECT_HOME/historico/var_jboss_"$CR"_"$server".txt
      break 1
   fi
done
echo
echo ===RESUMEN DE PROGRAMACION PARA EL $cambio ES LA SIGUIENTE:
cat $PROJECT_HOME/historico/var_jboss_"$CR"_*.txt

echo Digite cualquier tecla  para  continuar..
read prog
}

#===============Menu principal==
while [ $prog  -eq 1 ]; do
#PS3="Elige tu opción: "
opciones=("deploy_jboss" "deploy_micros" "deploy_docker" "Otros" "Salir" )
PS3="Elige una opción:  ó ENTER para continuar.."
select opt in "${opciones[@]}"
do
    case $opt in 

        "deploy_jboss") echo "Has elegido Programar el un  cambio en jboss!!!! " 
         	     echo Indique el  numero de cambio:
  		     echo Por ejemplo: CR9999
 		     read cambio 
		     echo Indique la Lista de  servidores de Jboss a desplegar:
		     echo ===========servidores Disponibles=====
		     cat hosts.cfg
                     echo ======================================
		     echo **Ingrese/escriba la lista de hostnames o IPs separados por espacio***
		     echo Ejemplo: "10.12.13.190 10.12.13.230 10.12.13.191"
		     read servidores
                     for s in $servidores; do
    		       if [ `grep "$s" $PROJECT_HOME/hosts.cfg` ]; then
			  echo ok $s
                       else
 			  echo servidor $s no está en el inventario de hosts manejados.
  			  break 1
		     fi  
                     done  
   		     deploy "$cambio" "$servidores"
		     clear
        ;;

        "deploy_micros") echo "Has elegido deploy_micros" 
                date; 
        ;;

        "deploy_docker") echo "Has elegido deploy_docker "
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
