#!/bin/bash

DESTINATARIO="juliorod@kyndryl.com,William.Caicedo1@kyndryl.com"
ASUNTO="Asunto dinámico desde el script shell usando python"
CUERPO="Este es el cuerpo del correo que se genera en el script shell llamando script python "
PYTHON_SCRIPT="/home/deployuser/bin/enviar_correo_relay_python.py" # Reemplaza con la ruta real de tu script de Python

python3 "$PYTHON_SCRIPT" "$DESTINATARIO" "$ASUNTO" "$CUERPO"
