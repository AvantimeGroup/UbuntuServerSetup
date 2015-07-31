#!/usr/bin/env php
<?php

require 'config.inc.php';

$api = new ZabbixApi\ZabbixApi(ZABBIX_URL);
$version = $api->apiinfoVersion();
echo "Zabbix API version: {$version}\n";
