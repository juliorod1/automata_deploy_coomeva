
list_servers="10.12.13.190 10.12.13.230 10.12.13.191"
CR="CR12345"
for server in list_servers; do
  echo Indique la lista de wars a desplegar en jboss de $server:
  echo **Escriba el nombre de los wars,sin espacios en el nombre y separados por un espacio**
  read list_wars
  echo $list_wars.
  echo
  echo Indique la Hora en la cual se ejecutará en el servidor $server esta actividad,en formato "yyyy-mm-dd hh:mm:ss" 
  echo Ejemplo: "2025-03-14 18:30:00"
  read at_tiempo
  echo $at_tiempo
  echo
  echo Indique si requiere que la instancia de Jboss en $server sea reiniciada una vez se instale la aplicacion.
  echo el default/omision es No, Digite 0 para NO y 1 para SI.
  read reinicio.
  echo $rein
  echo generando plantilla para $server... un momento...
  echo at_datetime: '"$at_tiempo"' >$PROJECT_HOME/var_jboss_$CR.txt
  echo cambio: '"$CR"' >>$PROJECT_HOME/var_jboss_$CR.txt
  echo servidor: '"$server"' >>$PROJECT_HOME/var_jboss_$CR.txt
  echo apps: '"$list_wars"' >>$PROJECT_HOME/var_jboss_$CR.txt
  echo reinicio: $rein >>$PROJECT_HOME/var_jboss_$CR.txts
  cat $PROJECT_HOME/deploy-jbos/vars/var_temp.txt > $PROJECT_HOME/deploy-jbos/vars/main.yml
  cat $PROJECT_HOME/var_jboss.txts >> $PROJECT_HOME/deploy-jbos/vars/main.yml
  mv $PROJECT_HOME/var_jboss_$CR.txts $PROJECT_HOME/historico/
  cd $PROJECT_HOME
  ansible-playbook --limit=$server  deploy-jboss.yml --extra-vars "cambio=$CR apps=$list_wars servidor=$server reinicio=$rein at_datetime=$at_tiempo"
done  
