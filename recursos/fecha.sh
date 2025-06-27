#set -x
alias date=gdate
## se debe ingresar la fecha sin comillas, ni simples no dobles para que funcione la validacion
echo Indique la Hora en la cual se ejecutará en el servidor $server esta actividad, en formato "yyyy-mm-dd hh:mm:ss"
echo
echo "**Ingrese la fecha en el formato indicado en una sola linea y SIN comillas**"
echo Ejemplo: `date +"%Y-%m-%d 19:00:00"`
echo
now=`date +"%Y-%m-%d %H:%M:%S"`
read at_tiempo
#gdate -d "$at_tiempo" >/dev/null 2>&1 && echo "Es una fecha en formato valido!!!" || echo "NO"
#a=`gdate -d "$at_tiempo" >/dev/null 2>&1 && echo "SI" || echo "NO"`
a=`date -d "$at_tiempo" >/dev/null 2>&1 && echo "SI" || echo "NO"`
echo  Esta es la fecha de ejecución que está ingresando: $at_tiempo  .. Vamos a comprobar que es válida..
echo
  if [[ $now < $at_tiempo ]] && [ "$a" == "SI"  ]; then
     echo fecha es valida para programar en crontab la ejecución!!.
  else
     echo "****Fecha ingresada es INVALIDA!! revise que esté en el formato requerido y sea futura****"
     sleep 5
     break 1
  fi
