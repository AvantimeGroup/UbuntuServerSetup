#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG="/etc/monit/monitrc"
email=$1
mailserver=$2
if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo -s"
		exit 1;
fi

while [ "$email" == "" ]
do
	echo -e $"Which email address should monit send alerts to"
	read email
done

while [ "$mailserver" == "" ]
do
	echo -e $"Which mail server should monit use to send alerts"
	read mailserver
done

apt-get install monit

#start monit on startup
cp monit_config/monit.conf /etc/init/
cp $CONFIG "$CONFIG.bak"

initctl reload-configuration

cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
echo "<Location /server-status>
         SetHandler server-status
         Order deny,allow
         Deny from all
         Allow from 127.0.0.1
 </Location>" >> /etc/apache2/apache2.conf

/etc/init.d/apache2 restart
 
awk '$1~/^DocumentRoot/{print $2}' /etc/apache2/sites-available/* | while read -r line ; do  
    mkdir $line/monit
    echo "Monit 12966" > $line/monit/token.html   
    
done


echo "set alert $email" >> $CONFIG
echo "set mailserver $mailserver"

for f in /etc/monit/monitrc.d/*
do
 read -p "Do you want to include configuration from $f? " -n 1 -r
echo    # (optional) move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]
then
   echo "##############################################
#####        $f                   ##### 
##############################################" >> $CONFIG
  cat $f >> $CONFIG
  
  if [[ $f == *"apache2" ]]
    then
    awk '$1~/^ServerName/{print $2}' /etc/apache2/sites-available/* | while read -r host ; do  
    echo "check host $host with address $host
      if failed
         port 80 protocol http         
         request /monit/token.html with content = 'Monit [0-9.]+'        
      then alert" >> $CONFIG
    done
  
  fi;
  
else 
   echo "skiping $f"
fi
 
 # do something on $f
done    
chmod 700 $CONFIG
start monit
