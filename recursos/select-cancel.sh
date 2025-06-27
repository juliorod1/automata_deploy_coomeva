#!/bin/bash
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
echo "No CAMBIO		FECHA	     SERVIDOR				PROGRAMA		    	   ESTADO"	
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
		    b=`echo $cambio|awk 'BEGIN{ FS="::"} { print $1}'`
		    s=$(grep $b $PROGRAMACION|awk 'BEGIN{FS=";"} { print $3}')
		    c1=/home/deployuser/bin/template_deploy_$b.sh
		    echo comando a ejecutar es: $c1
		    echo El cambio a cancelar es: [$b] en los siguientes servidores: $s
		    sleep 3
		    for j in $s; do
			echo Cancelando programacion en $j...
			#ansible-playbook --limit $j cancel-deploy.yaml --extra-vars "app_play=$c1" 
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
echo invocando la función
cancela

