#!/bin/bash

#Chargement de la configuration

. ../cfg/get_file.cfg

#declaration des variable

FILE="get_file"
LOG_LOCATION="../log"
DATE=`date '+%Y%m%d%H%M%S'`
LOG_FILE=${LOG_LOCATION}/${FILE}_${DATE}".log"
LOCAL_DIR="../data"
SFTP_DIR="data"

function connexion_sftp {

ServerSFTP=$1
UserSFTP=$2
#PORT="22"
    echo "    COMMAND : sftp -o Port=$PORT $UserSFTP@$ServerSFTP <<FIN"
    sftp -o Port=$PORT $UserSFTP@$ServerSFTP<<FIN | tee $LOG_FILE
cd $SFTP_DIR
ls -lrt
quit
FIN
	
}

function getfiles {
ServerSFTP=$1
UserSFTP=$2
echo "    COMMAND : sftp -o Port=$PORT $UserSFTP@$ServerSFTP"
sftp -o Port=$PORT $UserSFTP@$ServerSFTP<<FIN | tee $LOG_FILE
cd $SFTP_DIR
lcd $LOCAL_DIR
get *.csv
quit
FIN
}

case "$MACHINE" in
    AP1)
      user="adm1"
      MACHINE_SFTP="REC1" ;;

    AP2)
      user="adm1"
      MACHINE_SFTP="REC2" ;;

    *)
     echo "Impossible de determiner la bande de test AP"
     exit 1
esac

# Check de renseignement de la machine client
if [ "x$MACHINE_SFTP" = "x" ]; then
  echo "$(date '+%d-%m-%Y %H:%M:%S') > ERROR : la machine distant n a  pas ete renseigne. " | tee $LOG_FILE
  exit 1
fi

#Check de la disponibité de la machine cliente

NBR_RETRY_EFFECTIF=1
code_retour=""

while [ $NBR_RETRY_EFFECTIF -le $FORCE_NBR_RETRY ] && [ "$code_retour" != "0" ]
do
sftp -o Port=$PORT $user@$MACHINE_SFTP<<FIN > /dev/null 2>&1
quit
FIN
code_retour=$?

if [ $code_retour -ne 0 ]
then
	echo "Connexion SFTP KO - Nouvelle tentative de connexion apres un TIMER : $TIMER_RETRY secondes" | tee $LOG_FILE
	sleep $TIMER_RETRY
fi

NBR_RETRY_EFFECTIF=$((NBR_RETRY_EFFECTIF+1))

done

if [ $code_retour -ne 0 ]
then
        echo "ERROR : la machine distante est injoignable."
	echo "$(date '+%d-%m-%Y %H:%M:%S') > ERROR : la machine distante est injoignable. " >> $LOG_FILE 2>&1
exit 1
fi

#Test de la presence de fichiers csv

file_number=$(connexion_sftp $MACHINE_SFTP $user | grep .csv | wc -l)

if [ $file_number == 0 ]
then
	echo "Le repertoire data de la machine clinte ne contient aucun fichier csv"
        exit 0
fi	

connexion_sftp $MACHINE_SFTP $user 

getfiles $MACHINE_SFTP $user

#MESSAGE_MAIL=".HEAD_Message"
#FIN_MESSAGE_MAIL=".FIN_Message"
#email="oukalisari@gmail.com"

#echo "Message mail" | mail -s "Test envoi mail" salimgrdf@gmail.com
#echo $MESSAGE_MAIL | mail -s $FIN_MESSAGE_MAIL $email
#if [ $? == 0 ]
#then
#	echo "Mail envoyé a $email"
#else
#	echo "Erreur lors d'envie de mail"
#fi
