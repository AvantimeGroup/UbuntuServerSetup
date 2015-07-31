#!/usr/bin/env php
<?php

# Usage: ./setup_autoregistration.php autoregistration_token
# Current username and password will be taken from ENV:
# - ZABBIX_USER
# - ZABBIX_PASS

# Reference:
# https://www.zabbix.com/documentation/2.2/manual/discovery/auto_registration
# https://www.zabbix.com/documentation/2.2/manual/api/reference/action/create

require 'config.inc.php';

$autoregistration_token = $argv[1];

# Authenticate
$api = new ZabbixApi\ZabbixApi(ZABBIX_URL, ZABBIX_USER, ZABBIX_PASS);

# Values are from default zabbix installation
$notify_user_group = 7;
$linux_host_group = 2;
$linux_template = 10001;

# Create action
$action_attributes = array(
  "name"          => "Auto registration action (Linux) 2",
  "eventsource"   => 2, # event created by active agent auto-registration
  "status"        => 0, # 0 - enabled, 1 - disabled
  "esc_period"    => 0, # ??? Default operation step duration. Must be greater than 60 seconds.
  "def_shortdata" => 'Auto registration: {HOST.HOST}',
  "def_longdata"  => '
    Host name: {HOST.HOST}
    Host IP: {HOST.IP}
    Agent port: {HOST.PORT}
  ',
  "evaltype"      => 1, # Action condition evaluation method. AND.
  "conditions"    => [
    array(
      "conditiontype" => 24, # host metadata; available operators: 2 - like, 3 - not like
      "operator"      => 2, # like
      "value"         => "Linux"
    ),
    array(
      "conditiontype" => 24, # host metadata; available operators: 2 - like, 3 - not like
      "operator"      => 2, # like
      "value"         => $autoregistration_token
    ),
  ],
  "operations" => [
    # notify admins
    array(
      "operationtype" => 0, # send message
      "mediatypeid"   => 0, # using all media
      "opmessage"     => array(
        "mediatypeid" => 0,
        "subject"     => 'Auto registration: {HOST.HOST}'
      ),
      "opmessage_grp" => [
        array(
          "usrgrpid" => $notify_user_group
        )
      ]
    ),
    # add to "Linux servers" group
    array(
      "operationtype" => 4, # add to host group
      "opgroup" => [
        array(
          "groupid" => $linux_host_group
        )
      ]
    ),
    # link with "Template OS Linux"
    array(
      "operationtype" => 6, # link to template
      "optemplate" => [
        array(
          "templateid" => $linux_template
        )
      ]
    )
  ]
);

$api->actionCreate($action_attributes);
echo "Automatic registration set up successfully!\n";
