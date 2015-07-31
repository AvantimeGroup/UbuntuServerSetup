#!/usr/bin/env php
<?php

# Usage: ./mail_graphs.php --dir graphs_dir

require 'config.inc.php';
require 'lib/class.smtp.php';
require 'lib/class.phpmailer.php';

$options = getopt("", array('dir:'));
$src_dir = $options["dir"];

if(!$src_dir) {
  echo "Error: Specify source directory wtih `--dir`\n";
  exit(1);
}

if(!file_exists($src_dir)) {
  echo "Error: Specified directory does not exist!\n";
  exit(1);
}

if(!is_readable($src_dir)) {
  echo "Error: Directory is not readable!\n";
  exit(1);
}

$graphs = array();

foreach (glob("$src_dir/*.png") as $graph) {
  $graphs[] = $graph;
}

if(count($graph) == 0) {
  echo "No graphs to send report! Exiting...";
  exit(1);
}


$mail = new PHPMailer();

$mail->isSMTP();
// Mailcatcher test setup
// http://mailcatcher.me/
// mailcatcher --ip 0.0.0.0 --smtp-port 2025 --http-port 2080 --foreground
$mail->Host = 'localhost';
$mail->Port = 2025;

// For all the options please visit PHPMailer website:
// https://github.com/PHPMailer/PHPMailer

// $mail->Host = 'smtp1.example.com';
// $mail->SMTPAuth = true;
// $mail->Username = 'user@example.com';
// $mail->Password = 'secret';
// $mail->SMTPSecure = 'tls';
// $mail->Port = 587;

$mail->From = 'zabbix@example.com';
$mail->FromName = 'Zabbix Mailer';
$mail->addAddress('joe@example.net', 'Joe User');     // Add a recipient

$mail->Subject = 'Zabbix Weekly Report';
$mail->isHTML(true);
$mail->Body    = 'Zabbix Weekly Report';
$mail->AltBody = 'Zabbix Weekly Report';

foreach($graphs as $file) {
  $mail->addAttachment($file);
}

if(!$mail->send()) {
    echo "Message could not be sent.\n";
    echo 'Mailer Error: ' . $mail->ErrorInfo;
    exit(1);
} else {
    echo "Message has been sent\n";
}
