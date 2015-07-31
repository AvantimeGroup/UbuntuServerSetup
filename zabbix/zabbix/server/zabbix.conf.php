<?php
global $DB;

$DB["TYPE"]           = 'MYSQL';
$DB["SERVER"]         = 'localhost';
# $DB["PORT"]           = '0';

$DB["DATABASE"]       = '-ZABBIX_DB_NAME-';
$DB["USER"]           = '-ZABBIX_DB_USER-';
$DB["PASSWORD"]       = '-ZABBIX_DB_PASS-';

$ZBX_SERVER           = 'localhost';
$ZBX_SERVER_PORT      = '10051';
$ZBX_SERVER_NAME      = '';

$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
