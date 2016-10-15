#!/bin/bash
#Funcionamiento: Instala el script en el sistema
#El instalador los ejecutables del programa en la ruta de binarios del sistema linux
#El instalador asigna permisos de ejecuccion a los programas instalados

ROJO='\033[0;31m'
VERDE='\033[0;32m'
NC='\033[0m' # No Color

contadorExitos=0
sudo cp colorlog.pl /usr/bin/
if [ $? == 0 ]; then
    echo "Se copio el fichero colorlog.pl a /usr/bin/"
    ((contadorExitos++))

fi
sudo chmod +x /usr/bin/colorlog.pl
if [ $? == 0 ]; then
    echo "Se asignaron permisos de ejecucion al fichero /usr/bin/colorlog.pl "
    ((contadorExitos++))
fi

sudo cp smba /usr/bin/
if [ $? == 0 ]; then
    echo "Se copio el fichero smba a /usr/bin/"
    ((contadorExitos++))
fi
sudo chmod +x /usr/bin/smba
if [ $? == 0 ]; then
    echo "Se asignaron permisos de ejecucion al fichero /usr/bin/smba"
    ((contadorExitos++))
fi

#Si todo los pasos anteriores se completaron correctamente
if [ $contadorExitos == 4 ]; then
    echo "Instalacion completada correctamente"
else
    echo "Error en la instalacion"
fi 
