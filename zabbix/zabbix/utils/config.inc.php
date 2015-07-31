<?php

define('ZABBIX_HOST', getenv('ZABBIX_HOST') ?: 'localhost');
define('ZABBIX_BASE', "http://".ZABBIX_HOST."/zabbix");
define('ZABBIX_URL',  ZABBIX_BASE."/api_jsonrpc.php");
define('ZABBIX_USER', getenv('ZABBIX_USER'));
define('ZABBIX_PASS', getenv('ZABBIX_PASS'));

#########################
require_once 'lib/ZabbixApi.class.php';

function print_simple_backtrace() {
  echo "Backtrace:\n";
  $data = debug_backtrace();
  foreach ($data as $num => $line) {
    echo "  [$num]: {$line['file']}:{$line['line']} in {$line['function']}\n";
  }
}

function underscore_string($str) {
  return strtolower(preg_replace('/([a-z])([A-Z])/', '$1_$2', $str));
}

function escape_file_name($str) {
  return preg_replace('/[^a-z0-9_-]/i', '_', $str);
}
