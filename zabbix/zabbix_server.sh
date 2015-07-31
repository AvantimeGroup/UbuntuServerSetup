#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -e

if [ "$(whoami)" != 'root' ]; then
  echo $"You have no permission to run $0 as non-root user. Use sudo -s"
  exit 1
fi

### CONFIG
# use variables if set, initialize otherwise
MYSQL_PASS=${MYSQL_PASS:="root"}
ZABBIX_MYSQL_DB=${ZABBIX_MYSQL_DB:="zabbix"}
ZABBIX_MYSQL_USER=${ZABBIX_MYSQL_USER:="zabbix"}
ZABBIX_MYSQL_PASS=${ZABBIX_MYSQL_PASS:="zabbix"}
ZABBIX_PHP_TIMEZONE=${ZABBIX_PHP_TIMEZONE:="UTC"}

ZABBIX_PASS=${ZABBIX_PASS:="secret"}

# Generate random 32-char auto-registration token
RANDOM_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
ZABBIX_REGISTRATION_TOKEN=${ZABBIX_REGISTRATION_TOKEN:=$RANDOM_TOKEN}

### EXECUTION

export DEBIAN_FRONTEND=noninteractive
export ZABBIX_USER=admin
export ZABBIX_PASS
export ZABBIX_REGISTRATION_TOKEN

echo "Updating package list..."
apt-get -qq update

echo "mysql-server-5.6 mysql-server/root_password password $MYSQL_PASS" | debconf-set-selections
echo "mysql-server-5.6 mysql-server/root_password_again password $MYSQL_PASS" | debconf-set-selections
apt-get -qq --yes install mysql-server-5.6

apt-get -qq --yes install apache2

echo "Installing zabbix..."
apt-get -qq --yes install zabbix-server-mysql php5-mysql php5-curl zabbix-frontend-php

echo "Adding zabbix to apache2..."
cat >/etc/apache2/conf-available/zabbix.conf <<EOF
Alias /zabbix /usr/share/zabbix
<Directory /usr/share/zabbix>
  php_value post_max_size "16M"
  php_value max_execution_time 300
  php_value max_input_time 300
  php_value date.timezone "${ZABBIX_PHP_TIMEZONE}"
</Directory>
EOF
a2enmod --quiet alias
a2enconf --quiet zabbix
service apache2 reload

echo "Configuring zabbix server..."
mv /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.orig
cp $DIR/zabbix/server/zabbix_server.conf /etc/zabbix/zabbix_server.conf
sed -e "s/-ZABBIX_DB_NAME-/${ZABBIX_MYSQL_DB}/g" \
    -e "s/-ZABBIX_DB_USER-/${ZABBIX_MYSQL_USER}/g" \
    -e "s/-ZABBIX_DB_PASS-/${ZABBIX_MYSQL_PASS}/g" \
    -i /etc/zabbix/zabbix_server.conf

cp $DIR/zabbix/server/zabbix.conf.php /etc/zabbix/zabbix.conf.php
sed -e "s/-ZABBIX_DB_NAME-/${ZABBIX_MYSQL_DB}/g" \
    -e "s/-ZABBIX_DB_USER-/${ZABBIX_MYSQL_USER}/g" \
    -e "s/-ZABBIX_DB_PASS-/${ZABBIX_MYSQL_PASS}/g" \
    -i /etc/zabbix/zabbix.conf.php

echo "Enable zabbix server autostart..."
sed -e 's/^START=.*/START=yes/' -i /etc/default/zabbix-server

echo "Creating zabbix database and db user..."
mysql --user=root --password=${MYSQL_PASS} --execute="
  CREATE DATABASE ${ZABBIX_MYSQL_DB};
  CREATE USER '${ZABBIX_MYSQL_USER}'@'localhost' IDENTIFIED BY '${ZABBIX_MYSQL_PASS}';
  GRANT ALL PRIVILEGES ON ${ZABBIX_MYSQL_DB}.* TO '${ZABBIX_MYSQL_USER}'@'localhost';
"

echo "Loading zabbix initial data..."
zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql \
  --user=${ZABBIX_MYSQL_USER} \
  --password=${ZABBIX_MYSQL_PASS} \
  ${ZABBIX_MYSQL_DB}

zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql \
  --user=${ZABBIX_MYSQL_USER} \
  --password=${ZABBIX_MYSQL_PASS} \
  ${ZABBIX_MYSQL_DB}

zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql \
  --user=${ZABBIX_MYSQL_USER} \
  --password=${ZABBIX_MYSQL_PASS} \
  ${ZABBIX_MYSQL_DB}

echo "Starting zabbix server..."
service zabbix-server start

sleep 5

echo "Changing default password..."
## Override zabbix pass with default password
/usr/bin/env ZABBIX_PASS=zabbix $DIR/zabbix/utils/change_pass.php $ZABBIX_PASS

echo "Setup automatic registration of trusted nodes..."
$DIR/zabbix/utils/setup_autoregistration.php $ZABBIX_REGISTRATION_TOKEN

cat <<EOF

####################################
Zabbix installation done!

          !NOTE!

MySQL root password used for installation: ${MYSQL_PASS}

Zabbix setup details:
  Database: ${ZABBIX_MYSQL_DB}
  DB user:  ${ZABBIX_MYSQL_USER}
  DB pass:  ${ZABBIX_MYSQL_PASS}

Zabbix installation is accessible at

  http://<IP>/zabbix
  user: admin
  pass: $ZABBIX_PASS

To allow automatically add trusted discovered nodes to monitoring use following
token:

  AUTO_REGISTRATION_TOKEN=${ZABBIX_REGISTRATION_TOKEN}

####################################
EOF
