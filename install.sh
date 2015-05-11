#!/bin/bash

#Get the current directory
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "** installing packages"
echo ""
apt-get install fail2ban incron clamav clamav-daemon inotify-tools sendmail apache2 mysql-server mysql-client php5 libapache2-mod-php5 php5-mysql php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt
echo "** configuring fail2ban"
echo ""
cd /etc/fail2ban/filter.d/
wget http://plugins.svn.wordpress.org/wp-fail2ban/trunk/wordpress.conf
cd $DIR
cp fail2ban/wordpress.conf /etc/fail2ban/jail.d/
cp fail2ban/jail.local /etc/fail2ban/

echo "** Configuring virus scan on web folder"
#cp clamav/clamav_daemon_script.sh /etc/clamav_daemon_script.sh

#find /var/www/ -name "uploads" -type d -print0 | xargs -0 -I{} echo "{} IN_CLOSE_WRITE,IN_CREATE,IN_DELETE clamscan -r --remove {}" > /etc/incron.d/webroot.conf

mysql_secure_installation
