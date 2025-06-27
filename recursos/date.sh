#!/bin/bash

read -p "Introduce la fecha y hora (YYYY-MM-DD HH:MI): " fecha_hora


if ! echo "$fecha_hora" | grep -Eq "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$"; then
    echo "Formato incorrecto. Usa YYYY-MM-DD HH:MM"
    exit  1
fi

# Validación del formato con grep
# Validación de la fecha y hora y conversión a segundos desde Epoch
fecha_hora_segundos=$(date -d "$fecha_hora" +%s 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "Fecha y hora no válidas"
    exit 1
fi

# Validación de fecha y hora futura
fecha_hora_actual_segundos=$(date +%s)

if [[ "$fecha_hora_segundos" -le "$fecha_hora_actual_segundos" ]]; then
    echo "La fecha y hora deben estar en el futuro"
    exit 1
fi

echo "Fecha y hora válidas y en el futuro: $fecha_hora"

# Aquí puedes agregar el código para continuar con tu script
