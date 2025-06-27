servidores="cdplin125 cdplin141 cdplin120"
wars="war1.war war2.wa war.war3 war4.war"
server=""
for i in $servidores; do
	server+="$i,"
done
server1="${server%,}" ###comillas de expancion
echo $server1


IFS=' ' read -ra servidores_array <<< "$servidores"
cadena_con_comas=$(IFS=, ; echo "${servidores_array[*]}")
echo "$cadena_con_comas"


echo "lista_files:" >varlist.txt
lista_copy=""
for i in $wars; do
	echo " - $i" >>varlist.txt
done
cat  varlist.txt
