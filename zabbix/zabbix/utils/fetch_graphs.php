#!/usr/bin/env php
<?php

# Usage: ./graphs.php --dir /output/dir

require 'config.inc.php';
require 'lib/GraphImage.class.php';

$options = getopt("", array('dir:'));
$out_dir = $options["dir"];

if(!$out_dir) {
  echo "Error: Specify output directory wtih `--dir`\n";
  exit(1);
}

if(!file_exists($out_dir)) {
  echo "Error: Specified directory does not exist!\n";
  exit(1);
}

if(!is_writable($out_dir)) {
  echo "Error: Directory is not writable!\n";
  exit(1);
}

# Authenticate
$api = new ZabbixApi\ZabbixApi(ZABBIX_URL, ZABBIX_USER, ZABBIX_PASS);

$hosts = $api->hostGet(array(
  "output" => "extend",
  "filter" => array(
    "status" => 0 # 0 - monitored host, 1 - not monitored
  )
));

$img = new GraphImage(ZABBIX_BASE, ZABBIX_USER, ZABBIX_PASS);

echo "Processing: \n";

$timestamp = time();

foreach($hosts as $host) {
  $host_name = escape_file_name(underscore_string($host->name));
  $host_id   = $host->hostid;

  $graphs = $api->graphGet(array(
    "hostids" => $host_id,
    "output" => "extend"
  ));

  echo "\n  Host: [$host_id] {$host->name}\n";

  foreach($graphs as $graph) {
    $graph_id = $graph->graphid;
    $graph_name = escape_file_name(underscore_string($graph->name));
    $filename = "$out_dir/$timestamp.$host_name.$host_id.$graph_name.$graph_id.png";

    $raw_img = $img->fetch($graph_id, 800, 600, 60*60*24*7);
    file_put_contents($filename, $raw_img);

    echo "  * Graph: [$graph_id] {$graph->name}\n";
  }

}

