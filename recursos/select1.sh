app=""
echo   "APLICACIONES DISPONIBLE PARA SERVERN"
opciones=(`cat Lista_aplicaciones/cdplin115.txt|awk 'BEGIN{FS="/"} { print $6 }'` Salir)
PS3="				 Elige una opción:  ó ENTER para continuar.."
select opt in "${opciones[@]}"
do
    #echo   "APLICACIONES SELECCIONADAS  PARA SERVERN:"
    for i in "${opciones[($REPLY-1)]}"; do
     #echo el valor de REPLY es: $REPLY y "${opciones[($REPLY-1)]}"
    if [ $REPLY  ]; then
       #echo valor de REPLY es: $REPLY y de i es: $i
       if [ "$i" != "Salir" ]; then
          #echo "REPLY es: $REPLY" y de i es $i
          #app="$app $i"
          app=""$app" "${opciones[($REPLY-1)]}""
          echo Aplicaciones1 selecionadas es: $app
       else
          #echo Aplicaciones selecionadas es: $app
          break 2
       fi
    fi
    done
done
clear
echo   "APLICACIONES SELECCIONADAS  PARA SERVERN:"
echo contenido de apps es: $app
exit 0
