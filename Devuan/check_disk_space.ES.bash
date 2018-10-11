#!/bin/bash
# Title      : check_disk_space.bash
# Description: Send alert by email if disk is filling up
# Author     : linuxitux
# Date       : 27-05-2014
# Usage      : ./check_disk_space.bash
# Notes      : Edit limit & mailto
# Notes      : Run this script every hour if you want
#33 * * * * root /root/scripts/check_disk_space.bash >> /var/log/check_disk_space.log 2>&1

# Uso m�ximo permitido (en porcentaje)
LIMITE="90"

# Destinatario del correo electr�nico
DESTINATARIO="sysadmin@linuxito.com"

# Configuraci�n de correo electr�nico
REMITENTE="Linuxito <root@linuxito.com>"
CLIENTE="/usr/bin/mail"
#CLIENTE="/root/scripts/mailgun-mta.sh --text"

# Nombre del servidor
SERVIDOR=$(hostname)

# Archivos temporales
USO="/tmp/df.tmp"
MAIL="/tmp/mail.tmp"

# Valores de utilizaci�n de espacio en cada dispositivo (excluye filesystems temporales)
df -P | grep "/dev" | grep -v "udev" | grep -v "tmpfs" > $USO

WARNING="no"

# Para cada valor verificar que no supere el l�mite
while read DEV
do
  PORCENTAJE=$(echo $DEV | awk '{print $5}' | sed -e 's/\%//')

  if [ $PORCENTAJE -gt $LIMITE ]
  then
    # Si supera el l�mite enviar correo
    WARNING="si"
    echo $DEV | awk '{print "Dispositivo: "$1", montado en: "$6", uso: "$5", disponible: "$4}' >> $MAIL
  fi
done < "$USO"

if [ $WARNING == "si" ]
then
  ASUNTO="Poco espacio en disco en ${SERVIDOR}"
  DETALLE=$(cat $MAIL)
  MENSAJE="Queda poco espacio disponible en los siguientes sistemas de archivos:\n\n${DETALLE}"
  echo -e "${MENSAJE}" | $CLIENTE -s "${ASUNTO}" -r "${REMITENTE}" ${DESTINATARIO}
fi

# Borrar archivos temporales
rm $USO > /dev/null 2>&1
if [ $WARNING == "si" ]; then rm $MAIL > /dev/null 2>&1; fi
