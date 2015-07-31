#!/usr/bin/env php
<?php

# Usage: ./change_pass.php new_pass
# Current username and password will be taken from ENV:
# - ZABBIX_USER
# - ZABBIX_PASS

require 'config.inc.php';

$zabbix_new_pass = $argv[1];

# Authenticate

$api = new ZabbixApi\ZabbixApi(ZABBIX_URL, ZABBIX_USER, ZABBIX_PASS);

$update_data = array(
  "passwd" => $zabbix_new_pass
);

$api->userUpdateProfile($update_data);
echo "Password successfully updated!\n";
