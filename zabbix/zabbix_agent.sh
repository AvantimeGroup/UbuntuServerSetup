#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ZABBIX_SERVER=$1

set -e

if [ "$(whoami)" != 'root' ]; then
  echo $"You have no permission to run $0 as non-root user. Use sudo -s"
  exit 1
fi
while [ "$ZABBIX_SERVER" == "" ]
do
	echo -e $"Please provide ip to the zabbix server."
	read ZABBIX_SERVER
done
### CONFIG

ZABBIX_SERVER=${ZABBIX_SERVER:="172.16.84.10"}
ZABBIX_REGISTRATION_TOKEN=${ZABBIX_REGISTRATION_TOKEN:=""}

### EXECUTION

export DEBIAN_FRONTEND=noninteractive

echo "Updating package list..."
apt-get -qq update

echo "Installing zabbix..."
apt-get -qq --yes install zabbix-agent

echo "Configuring zabbix agent..."
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.orig
cp $DIR/zabbix/agent/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
sed -e "s/-SERVER_IP-/${ZABBIX_SERVER}/g" \
    -e "s/-AUTO_REGISTRATION_TOKEN-/${ZABBIX_REGISTRATION_TOKEN}/g" \
    -i /etc/zabbix/zabbix_agentd.conf

echo "Enable zabbix agent autostart..."
sed -e 's/^START=.*/START=yes/' -i /etc/default/zabbix-agent

echo "Starting zabbix agent..."
service zabbix-agent restart

cat <<EOF

####################################
Zabbix agent installation done!
####################################
EOF
