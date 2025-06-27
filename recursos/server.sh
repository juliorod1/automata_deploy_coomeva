app=""
echo   "SERVIDORES DE JBOSS DISPONIBLES"
opciones=(`cat hosts.cfg|grep servidor|awk 'BEGIN{FS=" "} { print $1 }'` Salir)
PS3="				 Elige una opción:  ó ENTER para continuar.."
select opt in "${opciones[@]}"
do
    #echo   "SERVIDORES DISPONIBLES DE JBOSS:"
    for i in "${opciones[($REPLY-1)]}"; do
     #echo el valor de REPLY es: $REPLY y "${opciones[($REPLY-1)]}"
    if [ $REPLY  ]; then
       #echo valor de REPLY es: $REPLY y de i es: $i
       if [ "$i" != "Salir" ]; then
          #echo "REPLY es: $REPLY" y de i es $i
          #app="$app $i"
          app=""$app" "${opciones[($REPLY-1)]}""
          echo Servidores selecionados es: $app
       else
          echo Servidores selecionados es: $app
          break 2
       fi
    fi
    done
done
clear
echo   "SERVIDORES SELECCIONADOS PARA ESTE CAMBIO:"
echo - $app
exit 0
