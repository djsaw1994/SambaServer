#! /bin/bash
# Nombre del script: smba
# Programador: Paulo Gustavo Soares Teixeira <pauloxti@gmail.com>
# Fecha: 14/04/2016
# Explicación del programa:

# El programa consta de 9 funciones:
#  1. dir() --------> Permite crear o borrar directorios compartidos mendiante samba, creando el directorio tanto como escribiendo en /etc/samba/smb.conf
#  2. sysUsers()----> Permite crear y borrar usuarios del sistema
#  3. smbUsers()----> Permite crear y borrar usuarios de SAMBA
#  4. permissions()-> Permite gestionar permisos y gestionar el propietario o el grupo al que pertenece un directorio o fichero
#  5. rootcheck() --> Comprueba que el usuario que ejecuta el programa es root, si no es root no deja iniciar el programa.
#  6. groups() -----> Permite crear o borrar grupos facilmente, ademas de añadir o eliminar un usuario de un grupo indicado
#  7. sysInfo() ----> Permite ver informacion del sistema asi como los usuarios, los grupos, los directorios que se estan compartiendo etc.
#  8. commmaands() -> Muestra en pantalla una breve explicacion sobre el uso de los comandos mas frecuentes
#  9. password() ---> Nos permite cambiar la contraseña de los usuarios del sistema y de SAMBA.
# 10. smbLog() -----> Muestra un log de las actividades en los directorios compartidos

miDistribucion=NULL

# Funcion: Realiza una pausa en el terminal hasta que el usuario pulsa cualquier tecla
pause()
{
    echo -e "\033[0m"
    read -p "Pulsa la tecla intro para continuar..." tecla
}

# Funcion: Comprueba que el usuario que ejecuta el script tiene permisos de administrador
comprobarRoot()
{
    ROOT_UID=0   # El $UID de root es 0.
    if [ "$UID" -ne "$ROOT_UID" ]; then
    	  clear
          zenity --error --text "El script debe ser ejecutado con permisos de administrador."
      exit
    fi
}

#Comprueba que distribucion de linux esta ejecutando el script
comprobarDistribucion()
{
    #Almacena la distribucion de linux del sistema
    distribucionSistema=`lsb_release -a | grep "Distributor ID" | cut -d: -f2`

    if [ $distribucionSistema == 'Ubuntu' ]; then
        $miDistribucion=$distrucionSistema
    elif [ $distribucionSistema == 'Debian' ]; then
        $miDistribucion=$distrucionSistema
    elif [ $distribucionSistema == 'CentOS' ]; then
        $miDistribucion=$distrucionSistema
    else
      zenity --error --text "Distribucion no compatible."
      break
      exit
    fi
}

#Reinicia el servicio samba
reiniciarSamba()
{
    if [ $miDistribucion == 'Ubuntu' ]; then
        zenity --info --text "Reiniciando servidor samba"
        service smbd restart
        pause
    elif [ $miDistribucion == 'Debian' ]; then
        zenity --info --text "Reiniciando servidor samba"
        service smbd restart
        pause
    elif [ $miDistribucion == 'CentOS' ]; then
        /etc/init.d/smb restart
        pause
    fi
}

#Instala samba en el equipo
instalarSamba()
{
    if [ $miDistribucion == 'Ubuntu' ]; then
        sudo apt-get install samba
    elif [ $miDistribucion == 'Debian' ]; then
        sudo apt-get install samba
    elif [ $miDistribucion == 'CentOS' ]; then
        sudo yum install samba4
    fi

    #Comprobamos que la instalacion fue correcta
    if [ $? == 0 ]; then
        zenity --info --text "Se ha instalado samba correctamente"
    else
        zenity --error --text "Se ha producido un error instalado samba"
    fi
    pause
}

crearCarpetaCompartida()
{ 
    carpeta=NULL
    clear
    echo ""
    echo "1. Crear una carpeta."
    echo "2. Borrar una carpeta."
    echo "3. Salir."
    echo ""
    read -p "Selecciona que accion desea realizar: " eleccion
    case $eleccion in
        # Crear directorio comparido
        1) clear
           #Seleccionamos la carpeta que queremos compartir
           carpeta=`zenity --file-selection --directory`
           while [[ ! -d $carpeta ]]; do
               carpeta=`zenity --file-selection --directory`
           done
           
           mkdir -p $carpeta; chmod 770 $carpeta; chmod g+s $carpeta
           creadorCarpeta=`sudo who | cut -d " " -f1`
           $creadorCarpeta=`$creadorCarpeta | cut -d " " -f1`
           chown $creadorCarpeta:$creadorCarpeta $carpeta

           descripcion=`zenity --entry --text "Introduce una descripcion para el rescurso"`
           while [[ $descripcion == NULL ]]; do
               descripcion=`zenity --entry --text "Introduce una descripcion para el rescurso"`
           done
           
           echo "" >> /etc/samba/smb.conf
           echo "[$(basename $carpeta)]" >> /etc/samba/smb.conf
           echo "	comment = $descripcion" >> /etc/samba/smb.conf
           echo "	path = $carpeta" >> /etc/samba/smb.conf
           echo "        create mask = 770" >> /etc/samba/smb.conf
           echo "        directory mask = 770" >> /etc/samba/smb.conf
           echo "        force create mode = 770" >> /etc/samba/smb.conf
           echo "        force directory mode = 770" >> /etc/samba/smb.conf
           echo "	read only = No" >> /etc/samba/smb.conf

           auditar=`zenity --entry --text "Desea auditar este recurso(S/n): "`
           while [[ $auditar != 'S' && $auditar != 'n' ]]; do
               auditar=`zenity --entry --text "Desea auditar este recurso(S/n): "`
           done

           case $auditar in
               'S') clear
                    #Si no existe el script colorlog lo instalamos en el sistema
                    if [ ! -f /usr/bin/colorlog.pl ]; then
                        sudo cp colorlog.pl /usr/bin/colorlog.pl
                        sudo chmod 777 /usr/bin/colorlog.pl
                    fi

                    echo "        vfs objects = full_audit" >> /etc/samba/smb.conf
                    echo "        full_audit:prefix = %u|%I|%m|%S" >> /etc/samba/smb.conf
                    echo "        full_audit:success = mkdir rename unlink rmdir pwrite pread connect disconnect" >> /etc/samba/smb.conf
                    echo "        full_audit:failure = none" >> /etc/samba/smb.conf
                    echo "        full_audit:facility = local7" >> /etc/samba/smb.conf
                    echo "        full_audit:priority = NOTICE" >> /etc/samba/smb.conf;;
               'n') clear;;
                 *) clear
                  zenity --error --text "No ha seleccionado ninguna opcion valida"
                  pause;;
           esac
           if [ $? = 0 ] ; then
               zenity --info --text "El directorio $carpeta se a creado correctamente"
           else
               zenity --erro --text "No se a podido crear el directorio $carpeta"
           fi 
           reiniciarSamba;;
        # Borrar directorio compartido
        2) clear
           #Seleccionamos la carpeta que queremos eliminar
           carpeta=`zenity --file-selection --directory`
           while [[ ! -d $carpeta ]]; do
               carpeta=`zenity --file-selection --directory`
           done

           rm -rf $carpeta
           sed '/^\['$(basename $carpeta)'\]$/,/^\[.*\]$/ { /^\['$(basename $carpeta)'\]$/ {d}; /^\[.*\]$/ !{d} }' /etc/samba/smb.conf > /etc/samba/smb.temp
           rm -rf /etc/samba/smb.conf; mv /etc/samba/smb.temp /etc/samba/smb.conf; rm -rf /etc/samba/smb.temp
           if [ $? = 0 ] ; then
             echo -e "\033[32;1mLa carpeta $(basename $carpeta) se ha borrado correctamente.\033[0m"
           else
             echo -e "\033[31;1mLa carpeta $(basename $carpeta) no se ha borrado correctamente.\033[0m"
           fi
           reiniciarSamba;;
        3) clear;; 
        *) clear
           echo "No ha seleccionado ninguna opcion valida"
           pause;;
      esac
}

crearUsuariosSistema(){ clear
echo ""
echo "1. Crear un usuario en el sistema."
echo "2. Borrar un usuario en el sistema."
echo "3. Salir"
echo ""
read -p "Selecciona que accion desea realizar: " eleccion
case $eleccion in
    # Crear usuario en el sistema
    1) clear
       read -p "Escriba el nombre de usuario que desea crear: " cUser
       useradd $cUser
       passwd  $cUser
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl usuario $cUser se ha creado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl usuario $cUser no se ha creado correctamente.\033[0m"
       fi
       pause;;
    # Borrar usuario en el sistema
    2) clear
       read -p "Escriba el nombre de usuario que desea eliminar: " bUser
       userdel $bUser
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl usuario $bUser se ha borrado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl usuario $bUser no se ha borrado correctamente.\033[0m"
       fi
      pause;;
    3) clear;;
    *) clear
       echo "No ha seleccionado ninguna opcion valida"
       pause;;
esac
}

crearUsuariosSamba(){ 
clear
echo ""
echo "1. Crear un usuario en SAMBA"
echo "2. Borrar un usuario en SAMBA"
echo "3. Salir"
echo ""
read -p "Selecciona que accion desea realizar: " eleccion
case $eleccion in
    # Crear usuario en SAMBA
    1) clear
       read -p "Escriba el nombre de usuario que desea crear: " cUser
       smbpasswd -a $cUser
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl usuario $cUser se ha creado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl usuario $cUser no se ha creado correctamente.\033[0m"
       fi
       pause;;
    # Borrar usuario en SAMBA
    2) clear
       read -p "Escriba el nombre de usuario que desea eliminar: " bUser
       smbpasswd -x $bUser
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl usuario $bUser se ha borrado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl usuario $bUser no se ha borrado correctamente.\033[0m"
       fi
       pause;;
    3) clear;;
    *) clear
       echo "No ha seleccionado ninguna opcion valida"
       pause;;
  esac
}

configurarPermisos(){
clear
echo ""
echo "1. Cambiar permisos."
echo "2. Cambiar propietario."
echo "3. Cambiar grupo."
echo "4. Salir."
read -p "Selecciona la accion que desea realizar: " choice
case $choice in
    # Cambiar permisos de un objeto del sistema
    1) clear;
       read -p "Escriba la ruta de la carpeta o fichero que desea gestionar: " objeto
       echo "La el objeto $objeto tiene los siguientes permisos: "
       ls -lhd $objeto | cut -f1 -d" "
       echo ""
       echo "Este es el valor de permisos que puede aplicarse:"
       echo "0 = Ningún permiso (Lectura = 0 + Escritura = 0 + Ejecución = 0)"
       echo "1 = Permiso de Ejecución (Lectura = 0 + Escritura = 0 + Ejecución = 1)"
       echo "2 = Permiso de Escritura (Lectura = 0 + Escritura = 2 + Ejecución = 0)"
       echo "3 = Permiso de Escritura y Ejecución (Lectura = 0, Escritura = 2, Ejecución = 1)"
       echo "4 = Permiso de Lectura (Lectura = 4 + Escritura = 0 + Ejecución = 0)"
       echo "5 = Permiso de Lectura y Ejecución (Lectura = 4 + Escritura = 0 + Ejecución = 1)"
       echo "6 = Permiso de Lectura y Escritura (Lectura = 4 + Escritura = 2 + Ejecución = 0)"
       echo "7 = Permiso de Lectura, Escritura y Ejecución (Lectura = 4 + Escritura = 2 + Ejecución = 1)"
       echo ""
       echo "Un ejemplo:"
       echo "Ejecutamos: chmod 644 carpeta1" 
       echo "Propietario = 6 (Puede Leer y Escribir)"
       echo "Grupo = 4 (solo puede Leer)"
       echo "Otros = 4 (solo puede Leer)"
       echo ""
       read -p "Escriba que permisos quiere asignar con el formato XXX: " permisos
       chmod $permisos $objeto
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl objeto $objeto se ha modificado correctamente.\033[0m"
         echo "Estos son los nuevos permisos para $objeto"; ls -lhd $objeto | cut -f1 -d" "
       else
         echo -e "\033[31;1mEl grupo $cG no se ha modificado correctamente.\033[0m"
       fi
       pause;;
    # Cambiar propietario de un objeto
    2) clear
       read -p "Escriba la ruta de la carpeta o fichero que desea gestionar: " objeto
       read -p "Escriba el nuevo propietario que quiere asignar: " prop
       chown $prop $objeto
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl propietario de $objeto se ha modificado correctamente, el nuevo propietario es $prop.\033[0m"
       else
         echo -e "\033[31;1mEl no se ha podido cambiar el propietario para $objeto.\033[0m"
       fi
       pause;;
    # Cambiar grupo de un objeto
    3) clear
       read -p "Escriba la ruta de la carpeta o fichero que desea gestionar: " objeto
       read -p "Escriba el nuevo grupo al que quiere asignar: " grupo
       chgrp $grupo $objeto
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl objeto $objeto se ha añadido al grupo $grupo correctamente.\033[0m"
       else
         echo -e "\033[31;1mNo se ha podido añadir $objeto al grupo $grupo.\033[0m"
       fi
       pause;;              
    4) clear;;
    *) clear
       echo "No ha seleccionado ninguna opcion valida"
       pause;;
esac
}

configurarGrupos(){
clear
echo ""
echo "1. Crear grupos."
echo "2. Borrar grupos."
echo "3. Añadir/eliminar usuarios de un grupo."
echo "4. Salir."
echo ""
read -p "Seleccione que desea hacer: " eleccion
case $eleccion in
    # Crear grupo del sistema
    1) clear
       read -p "Escriba el nombre del grupo que desea crear: " cG
       groupadd $cG
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl grupo $cG se ha creado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl grupo $cG no se ha creado correctamente.\033[0m"
       fi
       pause;;
    # Borrar grupo del sistema
    2) clear
       read -p "Escriba el nombre del grupo que desea eliminar: " bG
       groupdel $bG
       if [ $? = 0 ] ; then
         echo -e "\033[32;1mEl grupo $bG se ha borrado correctamente.\033[0m"
       else
         echo -e "\033[31;1mEl grupo $bG no se ha borrado correctamente.\033[0m"
       fi
       pause;;
    # Añadir o eliminar un usuario de un grupo
    3) clear
       read -p "Introduzca el usuario que desea gestionar: " user
       echo "El usuario $user pertenece al grupo o grupos: "; id $user | cut -f3 -d " "
       echo ""
       echo "1. Añadirlo a un grupo."
       echo "2. Eliminarlo de un grupo."
       echo "3. Salir"
       echo ""
       read -p "Seleccione lo que desea hacer: " choice
       case $choice in
           # Añadir usuario a un grupo
           1) clear
              read -p "Escriba el grupo al que lo desea añadir: " group
              gpasswd -a  $user $group
              if [ $? = 0 ] ; then
                echo -e "\033[32;1mEl usuario $user se ha añadido al grupo $group correctamente.\033[0m"
              else
                echo -e "\033[31;1mEl usuario $user no se ha añadido al grupo $grupo correctamente.\033[0m"
              fi
              pause;;
           # Eliminar usuario de un grupo
           2) clear
              read -p "Escriba el grupo del que desea sacar el usuario: " group
              gpasswd -d $user $group
              if [ $? = 0 ] ; then
                echo -e "\033[32;1mEl usuario $user se ha eliminado del grupo $grupo  correctamente.\033[0m"
              else
                echo -e "\033[31;1mEl usuario $user no se ha eliminado del grupo $grupo correctamente.\033[0m"
              fi
              pause;;
       esac;;
    4) clear;;
esac
} 

informacionSistema(){
clear
echo ""
echo "1. Ver Carpetas compartidas."
echo "2. Ver Usuarios del sistema."
echo "3. Ver Usuarios de SAMBA."
echo "4. Ver Grupos del sistema."
echo "5. Ver el / los grupos de cada usuario."
echo "6. Ver que usuarios pertenecen a un grupo."
echo "7. Ver estado de una fichero o directorio."
echo "8. Salir."
echo ""
read -p "Selecciona que accion desea realizar: " accion
case $accion in
    1) clear; sed '/#Carpetas compartidas/,$ !{ d }' /etc/samba/smb.conf; pause;;
    2) clear; cat /etc/passwd | cut -d":" -f1; pause;;
    3) clear; pdbedit -L; pause;;
    4) clear; cat /etc/group | cut -d":" -f1; pause;;
    5) clear
       read -p "Introduzca el usuario que quiere ver: " user
       echo "El usuario $user pertenece al grupo o grupos: "
       id $user | cut -f3 -d " "
       pause;;
    6) clear
       read -p "Introduce el nombre del grupo: " group
       echo "Al grupo $group pertenecen los usuarios:"
       cat /etc/group | grep $group | cut -f4 -d :
       echo ""
       pause;;
    7) clear; 
       read -p "Introduce la localizacion del fichero o directorio que desea ver: " file
       echo "Permisos|Propietario|Grupo|Tamaño|Fecha|Nombre del recurso"
       echo ""
       ls -lhd $file
       pause;;
    8) clear;;
    *) clear;
       echo "No ha seleccionado ninguna opcion valida"
       pause;;
  esac
}

comandosBasicos(){
clear
echo "mkdir NOMBRE-CARPETA               --> Crea una carpeta"
echo "rmdir NOMBRE-CARPETA               --> Borra una carpeta"
echo "useradd NOMBRE-USUARIO             --> Crea un usuario"
echo "userdel NOMBRE-USUARIO             --> Borra un usuario"
echo "groupadd NOMBRE-GRUPO              --> Crear un grupo"
echo "groupdel NOMBRE-GRUPO              --> Borra un grupo"
echo "chmod PERMISO                      --> Modifica permisos"
echo "chgrp NOMBRE-FICHERO NOMBRE-GRUPO  --> Cambia de grupo un fichero o directorio"
echo "chown NOMBRE-PROPIETARIO           --> Cambia de propietario un fichero o directorio"
echo ""
echo "Para mas informacion ejecute en el terminal: man comando, por ejemplo: man adduser"
echo "nos mostrara por pantalla una explicacion mucho mas completa sobre el uso de estos comandos" 
pause
}

cambiarPassword(){
read -p "Introduce el usuario: " user
passwd $user
smbpasswd $user
service smbd restart
if [ $? = 0 ] ; then
  echo -e "\033[32;1mEl cambio de contraseña para el usuario $user se ha realizado correctamente.\033[0m"
else
  echo -e "\033[31;1mEl cambio de contraseña para el usuario $user no se ha realizado correctamente.\033[0m"
fi
pause
}

logSamba()
{
    # Muestra el log de la auditoria de samba
    echo "Recuerda añadir esta cadena 'local7.* /var/log/smbAudit.log' al fichero /etc/rsyslog.d/50-default.conf
    y ejecutar 'service rsyslog restart'  si no funciona el log de samba"
    pause
    cat /var/log/smbAudit.log | colorlog.pl | more
    pause
}

#Comprobamos que es ejecutado por el usuario administrador
comprobarRoot

#Comprobamos que distribucion esta instalada
comprobarDistribucion

#Instalamos dependecias

while true
do
    clear
    echo ""
    echo "  ***************************************************  "
    echo " ***************************************************** "
    echo "*******************************************************"
    echo "***                                                 ***"
    echo "***                 .::AdminSMBv1.0::.              ***"
    echo "***                                                 ***"
    echo "***    1. Instalar SAMBA                            ***"
    echo "***    2. Crear/borrar una carpeta para compartir.  ***"
    echo "***    3. Crear/borrar un usuario del sistema.      ***"
    echo "***    4. Crear/borrar un usuario de SAMBA.         ***"
    echo "***    5. Gestion de grupos.                        ***"
    echo "***    6. Gestion de permisos y propietarios.       ***"
    echo "***    7. Lista de comandos.                        ***"
    echo "***    8. Informacion del sistema.                  ***"
    echo "***    9. Restablecer contraseña.                   ***"
    echo "***   10. Ver log de actividades.                   ***"
    echo "**    11. Reiniciar servidor SAMBA (No el equipo)   ***"
    echo "***   12. Salir.                                    ***"
    echo "***                                                 ***"
    echo "*******************************************************"
    echo " ***************************************************** "
    echo "  ***************************************************  "
    echo ""
    read -p "Introduce que accion deseas realizar: " eleccionMenu

    case $eleccionMenu in
      1) clear; instalarSamba;;
      2) clear; crearCarpetaCompartida;; 
      3) clear; crearUsuariosSistema;;
      4) clear; crearUsuariosSamba;; 
      5) clear; configurarGrupos;;
      6) clear; configurarPermisos;;
      7) clear; comandosBasicos;;
      8) clear; informacionSistema;;
      9) clear; cambiarPassword;;
     10) clear; logSamba;;
     11) clear; reiniciarSamba;;
     12) clear; break;;  
      *) echo "No ha seleccionado ninguna opcion valida"
         pause;;
    esac
done
