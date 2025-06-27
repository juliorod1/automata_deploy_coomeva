app=""
opciones=(`cat Lista_aplicaciones/cdplin115.txt|awk 'BEGIN{FS="/"} { print $6 }'` Salir)
PS3="				 Elige una opción:  ó ENTER para continuar.."
select opt in "${opciones[@]}"
do
    case $opt in

        "DonacionesCovid19Web.war") echo "has elegido $opt"
		     app="$app $opt" 
		     echo valor de apps: $app
		     echo ==el valor de opt es : $opt
		     echo == el valor de REPLY es: $REPLY	
		     echo ==el valor de opciones es : "${opciones[$REPLY]}"	
        ;;

        "DonacionesAsociadosWeb.war") echo echo "has elegido $opt"
                     app="$app $opt"
                     echo valor de apps: $app
                     echo ==el valor de opt es : $opt
		     echo == el valor de REPLY es: $REPLY
                     echo ==el valor de opciones es : "${opciones[$REPLY]}"
        ;;

        "Salir") break 2

        ;;
        *) echo "Opcion no válida."
    esac
done
echo el valor final de apps es: $app
