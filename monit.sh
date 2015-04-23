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
	echo -e $"Which email address should monit send alerts to?"
	read email
done

while [ "$mailserver" == "" ]
do
	echo -e $"Which mail server should monit use to send alerts?"
	read mailserver
done

apt-get install monit

#start monit on startup
/etc/init.d/monit stop && update-rc.d -f monit remove
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

echo "
" >> $CONFIG
echo "set alert $email" >> $CONFIG
echo "set mailserver $mailserver" >> $CONFIG

for f in /etc/monit/monitrc.d/*
do
 read -p "Do you want to include configuration from the standard configuration file $f? " -n 1 -r
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
         request /?monit=1 with content = 'Monit [0-9.]+'
      then alert" >> $CONFIG
    done

  fi;

else
   echo "skiping $f"
fi

 # do something on $f
done

echo "Finished asking about the default configurations."
echo "Going to ask about our own default setups."

for f in monit_config/config/*
  do
    read -p "Do you want to include our custom conf file $f? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
    then
      cat $f >> $CONFIG
      echo "
      " >> $CONFIG
    else
      echo "skiping $f"
  fi;
done

chmod 700 $CONFIG
start monit

