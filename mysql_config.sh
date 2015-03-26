#!/bin/bash
#Modified script based on http://www.bluepiccadilly.com/2011/12/creating-mysql-database-and-user-command-line-and-bash-script-automate-process
  
EXPECTED_ARGS=4
E_BADARGS=65
MYSQL=`which mysql`
  
Q1="CREATE DATABASE IF NOT EXISTS $1;"
Q2="GRANT USAGE ON *.* TO $2@localhost IDENTIFIED BY '$3';"
Q3="GRANT ALL PRIVILEGES ON $1.* TO $2@localhost;"
Q4="FLUSH PRIVILEGES;"
Q5="use $1;"
Q6="source $4;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}"
  
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass source"
  exit $E_BADARGS
fi
  
$MYSQL -u root -p -e "$SQL"