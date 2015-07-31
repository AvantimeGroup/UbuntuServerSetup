#!/bin/bash

# NOTE: script is expected to be added to crontab with a record like this:
#
# ln -s $DIR/zabbix_weekly_report.sh /etc/cron.weekly/zabbix_weekly_report.sh
#
# Or directly into /etc/crontab:
#
# 0 0 * * 7 root $DIR/zabbix_weekly_report.sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set -e

if [ "$(whoami)" != 'root' ]; then
  echo $"You have no permission to run $0 as non-root user. Use sudo -s"
  exit 1
fi

### CONFIG

ZABBIX_SERVER=${ZABBIX_SERVER:="172.16.84.10"}
ZABBIX_USER=${ZABBIX_USER:="admin"}
ZABBIX_PASS=${ZABBIX_PASS:="secret"}

### EXECUTION
export ZABBIX_SERVER
export ZABBIX_USER
export ZABBIX_PASS

TMPDIR=`mktemp -d`

echo "Downloading graphs..."
$DIR/zabbix/utils/fetch_graphs.php --dir $TMPDIR

echo "Mailing graphs..."
$DIR/zabbix/utils/mail_graphs.php --dir $TMPDIR

rm -rf $TMPDIR

echo "All done."
