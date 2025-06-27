
**1. Variables:**

* `date=$(date +%d_%m_%Y_%H)`: Almacena la fecha actual en formato día\_mes\_año\_hora (ej: 22\_05\_2025\_16).
* `hora=$(date +%d/%m/%Y" "%H:%M)`: Almacena la fecha y hora actual en formato día/mes/año hora:minuto (ej: 22/05/2025 16:48).
* `servidor=$(hostname)`: Almacena el nombre del servidor donde se ejecuta el script.
* `ruta_jar=/home/scripts/automata_ansible/microservicios/cdplin93`: Define la ruta donde se esperan encontrar los archivos JAR a desplegar.
* `ruta_backup=/home/versiones`: Define la ruta donde se guardarán las copias de seguridad de los microservicios existentes.
* `historico=/home/scripts/automata_ansible/microserviciosP0+r\P0+r\P0+r\P0+r\P0+r\/cdplin81/historico_instalados`: Define una ruta que parece ser utilizada para mover los archivos exitosamente desplegados (aunque esto no se ve explícitamente en el código proporcionado).
* `aplicaciones="/opt/contenerizacion/microservices/fabrica-soluciones-backend.jar /opt/contenerizacion/microservices/fabrica-soluciones-cotizador.jar"`: Define una cadena que contiene los nombres de los archivos JAR de las aplicaciones que se van a desplegar, separados por espacios.
* `script=/opt/contenerizacion/microservices/scripts/subir_micros.sh`: Define la ruta de un script que se utiliza para iniciar los microservicios.
* `lista_mail=william.caicedo1@kyndryl.com`: Define la dirección de correo electrónico del destinatario para las notificaciones.
* `user=root`: Define el usuario bajo el cual se realizarán ciertas operaciones (copia, permisos, ejecución de script).
* `id_cambio=CRQ0000031634`: Define el ID del cambio asociado a este despliegue.
* `reinicio=0`: Define una variable para controlar si se debe realizar un reinicio de todos los microservicios (actualmente configurado en 0, lo que significa que no se reiniciarán).
* `apps_exitosas=()`: Declara un array para almacenar información sobre las aplicaciones desplegadas exitosamente.
* `apps_diferencias=()`: Declara un array para almacenar información sobre las aplicaciones donde se encontraron diferencias durante la validación.

**2. Función `validacion()`:**

* Esta función toma como contexto la variable global `artifact` (ruta completa del archivo JAR a desplegar).
* Verifica si el archivo especificado en `$artifact` existe (`-e`).
* Si el archivo existe, llama a la función `realizar_depliegue`.
* Si el archivo no existe, muestra un mensaje de error indicando la ruta donde se esperaba el artefacto y termina la ejecución del script con código de salida 1.

**3. Función `realizar_depliegue()`:**

* Esta función toma como contexto las variables globales `app_path` (ruta donde se encuentra el microservicio en el servidor), `app` (nombre del archivo JAR), `date` (fecha actual), `ruta_backup` (ruta para backups) y `artifact` (ruta completa del nuevo artefacto).
* **Backup del microservicio existente:**
    * Verifica si ya existe un archivo con el mismo nombre (`"$app_path"`) en la ruta de despliegue.
    * Si existe, mueve el archivo existente a la ruta de backup, renombrándolo con el nombre de la aplicación y la fecha (`"${app}_${date}"`).
    * Espera 2 segundos (`sleep 2`).
* **Validación del backup y despliegue:**
    * Verifica si el archivo de backup se creó correctamente en la ruta de backup.
    * Si el backup es exitoso:
        * Copia el nuevo artefacto (`"$artifact"`) a la ruta de despliegue (`"$app_path"`), reemplazando la versión anterior (si existía).
        * Cambia la propiedad del archivo desplegado al usuario `root` y grupo `root`.
        * Establece los permisos del archivo desplegado a 644 (lectura y escritura para el propietario, lectura para el grupo y otros).
    * Si el backup falla, muestra un mensaje de error y la función retorna con código de salida 1 (indicando fallo).

**4. Función `stop_micro()`:**

* Esta función toma como contexto la variable global `micro` (nombre del archivo JAR del microservicio).
* Verifica si el valor de la variable `micro` termina con la extensión `.jar`.
* Si es un archivo JAR:
    * Busca el ID del proceso (PID) del microservicio que contiene el nombre del archivo `$micro` en su línea de comandos usando `pgrep -f`.
    * Si se encuentra un PID (`-n "$pid"`):
        * Muestra un mensaje indicando que se está bajando el microservicio y su PID.
        * Termina el proceso con la señal KILL (-9), redirigiendo la salida y errores a `/dev/null` (para que no se muestren en la consola).
    * Si no se encuentra un PID, la función simplemente retorna sin hacer nada.

**5. Función `start_micro()`:**

* Esta función toma como contexto la variable global `user` (configurada como `root`) y `script` (ruta del script para subir microservicios).
* Ejecuta el script especificado en `$script` bajo el usuario definido en `$user` (`root` en este caso).
* Redirige la salida estándar y el error estándar del script a `/dev/null`.

**6. Función `restart_all()`:**

* Esta función toma como contexto la variable global `path` (ruta donde se encuentra el microservicio en el servidor).
* Busca los PIDs de todos los procesos Java que contengan la ruta `$path` en su línea de comandos.
* Itera sobre la lista de PIDs encontrados:
    * Si un PID es válido (`-n "$pid"`), muestra un mensaje indicando que se está bajando el microservicio con ese PID y termina el proceso con la señal KILL (-9), redirigiendo la salida y errores a `/dev/null`.
* Después de detener todos los microservicios encontrados, llama a la función `start_micro` para iniciarlos.
* Llama a la función `enviar_correo` para enviar una notificación.
* Termina la ejecución del script con código de salida 0 (indicando éxito).

**7. Función `valida_deploy()`:**

* Esta función toma tres argumentos locales:
    * `nombre_app_actual`: El nombre del archivo JAR de la aplicación.
    * `artefacto_fuente`: La ruta completa del artefacto fuente (en la ruta `$ruta_jar`).
    * `ruta_desplegada_app`: La ruta completa de la aplicación desplegada en el servidor.
* Compara de forma silenciosa (`>/dev/null 2>&1`) los dos archivos usando `diff -q`. Si los archivos son idénticos, `diff` no producirá salida y la condición será verdadera.
* Si los archivos son idénticos:
    * Calcula la suma MD5 del archivo desplegado (`"$ruta_desplegada_app"`), extrae solo el hash usando `awk`, y lo almacena en la variable local `md5_sum_actual`.
    * Añade una cadena con el nombre de la aplicación y su suma MD5 a la variable global `apps_exitosas_info`. **Ojo:** Hay un error tipográfico aquí. La variable debería ser `apps_exitosas` (declarada como array), pero se está usando `apps_exitosas_info` (que no está declarada como array). Esto probablemente causará problemas.
* Si los archivos son diferentes:
    * Añade el nombre de la aplicación a la variable global `apps_con_diferencias` (declarada como array).

**8. Función `enviar_correo()`:**

* Esta función construye un correo electrónico basado en el resultado de la validación del despliegue.
* Define variables locales para el asunto (`asunto_final`) y el cuerpo del mensaje (`cuerpo_mensaje_final`).
* Construye detalles formateados de las aplicaciones desplegadas exitosamente (`detalles_exitosas`) e incorrectamente (`detalles_diferencias`) recorriendo los arrays `apps_exitosas_info` y `apps_con_diferencias`.
* **Construcción del asunto y cuerpo del correo:**
    * Si el array `apps_con_diferencias` está vacío (todas las aplicaciones se desplegaron correctamente):
        * Crea un asunto indicando éxito general.
        * Crea un cuerpo del mensaje formateado informando sobre el éxito, la hora y la lista de aplicaciones verificadas correctamente. **Ojo:** Hay un comentario que sugiere el uso de `printf` para formatear, pero la versión comentada usa una variable `$path` que no está definida dentro de esta función. La versión descomentada de `printf` parece estar mejor estructurada, aunque también usa `$path`.
    * Si el array `apps_con_diferencias` no está vacío (hubo fallos):
        * Crea un asunto indicando un error y el ID del cambio.
        * Crea un cuerpo del mensaje formateado informando sobre el fallo, las aplicaciones con diferencias, la hora y una recomendación para revisar los logs.
* Imprime el asunto y el cuerpo del mensaje en la salida estándar. **Importante:** Hay un comentario que indica dónde iría el comando real para enviar el correo electrónico utilizando `mail`. La línea comentada utiliza `mail`, pero la variable `$detalles_exitosas` en la versión comentada del cuerpo del mensaje no se corresponde con la variable usada en la versión descomentada.

**9. Bloque de ejecución principal:**

* `lista_apps=($aplicaciones)`: Divide la cadena de nombres de aplicaciones `$aplicaciones` en un array llamado `lista_apps`, utilizando el espacio como delimitador.
* **Primer bucle para el despliegue:**
    * Itera sobre cada elemento (`app_path`) del array `lista_apps`.
    * Extrae el nombre del archivo JAR (`app`) de la ruta completa.
    * Extrae la ruta del directorio (`path`) de la ruta completa.
    * Construye la ruta completa del artefacto fuente (`artifact`) combinando `$ruta_jar` y `$app`.
    * Llama a la función `validacion` para verificar si el artefacto existe y realizar el despliegue.
* **Condicional para el reinicio:**
    * Verifica si la variable `reinicio` es igual a 1. Si lo es, llama a la función `restart_all` para reiniciar los microservicios.
* **Segundo bucle para detener microservicios:**
    * Itera sobre cada elemento (`micro_path`) del array `lista_apps`.
    * Extrae el nombre del archivo JAR (`micro`).
    * Llama a la función `stop_micro` para detener el microservicio.
* Llama a la función `start_micro` para iniciar los microservicios (probablemente después de detener las versiones anteriores).
* **Tercer bucle para la validación del despliegue:**
    * Itera sobre cada elemento (`app_path`) del array `lista_apps`.
    * Extrae el nombre del archivo JAR (`app`).
    * Extrae la ruta del directorio (`path`).
    * Construye la ruta completa del artefacto fuente (`artifact`).
    * Llama a la función `valida_deploy` para comparar la versión desplegada con la fuente.
* Llama a la función `enviar_correo` para enviar el correo electrónico con el resultado del despliegue.

**Resumen de la lógica general:**

El script parece diseñado para desplegar una lista de microservicios (archivos JAR) desde una ruta local (`$ruta_jar`) a una ruta de despliegue en el servidor (`/opt/contenerizacion/microservices/`). Realiza una copia de seguridad de la versión existente, copia la nueva versión, cambia la propiedad y los permisos. Luego, detiene los microservicios antiguos (si se encuentran en ejecución), inicia la nueva versión y finalmente valida el despliegue comparando los archivos desplegados con las fuentes, enviando una notificación por correo electrónico con el resultado.

**Posibles puntos a considerar:**

* **Manejo de errores:** El script tiene cierta lógica para verificar errores (por ejemplo, en la creación del backup), pero podría ampliarse para cubrir otros posibles fallos (por ejemplo, errores al copiar archivos, cambiar permisos, detener o iniciar microservicios).
* **Variable `historico`:** La variable `$historico` no se utiliza en el código proporcionado. Podría haber una intención de mover los archivos desplegados exitosamente a esta ruta, pero no se implementó.
* **Reinicio:** La variable `$reinicio` está configurada en 0, por lo que la función `restart_all` nunca se llama en su estado actual.
* **Variable `path` en `enviar_correo()`:** La variable `$path` se utiliza en la función `enviar_correo` pero no está definida dentro de ella. Probablemente se espera que la variable `$path` establecida en los bucles principales esté disponible, pero esto podría ser un problema de ámbito si la función se llamara desde otro contexto.
* **Variable `apps_exitosas_info` vs. `apps_exitosas`:** Hay una inconsistencia en el nombre de la variable para las aplicaciones exitosas (uso de `apps_exitosas_info` en `valida_deploy` pero `apps_exitosas` en la declaración). Esto debería corregirse.
* **Envío de correo real:** El script actualmente solo imprime la información del correo en la salida estándar. La línea para enviar el correo real está comentada.

En general, el script sigue una lógica clara para automatizar el despliegue de microservicios. La inclusión de backups y la validación son buenas prácticas.
