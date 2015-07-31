<?php

class GraphImage {
  private $zabbix_url;
  private $cookie_file;

  public function __construct($zabbix_url = '', $user, $pass) {
    $this->zabbix_url  = $zabbix_url;
    $this->cookie_file = tempnam("/tmp", "zabbix_graph");
    $this->cleanup();
    $this->login($user, $pass);
  }

  public function cleanup() {
    unlink($this->cookie_file);
  }

  public function login($user, $pass) {
    $url = "{$this->zabbix_url}/index.php";

    $curl = $this->init_curl($url, 'POST');
    $auth_fields = array(
      'name'     => $user,
      'password' => $pass,
      'enter'    => "Sign in"
    );
    curl_setopt($curl, CURLOPT_POSTFIELDS, $auth_fields);
    $result = curl_exec($curl);
    curl_close($curl);

    return $result;
  }

  /**
   * @param $period Length of graph in seconds
   *   60*60*24*7
   */
  public function fetch($graphid, $width = 800, $height = 600, $period = 604800) {
    $url = sprintf("%s/chart2.php?graphid=%d&width=%d&height=%d&period=%d", $this->zabbix_url, $graphid, $width, $height, $period);
    $curl = $this->init_curl($url);
    $output = curl_exec($curl);
    return $output;
  }

  private function init_curl($url, $method = 'GET') {
    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, $url);
    // to debug - uncomment me
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);

    switch ($method) {
      case 'POST':
        curl_setopt($curl, CURLOPT_POST, true);
        break;
      default:
        curl_setopt($curl, CURLOPT_POST, false);
        break;
    }
    // curl_setopt($curl, CURLOPT_VERBOSE, $this->curl_verbose);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, FALSE);
    # Save cookie to this file
    curl_setopt($curl, CURLOPT_COOKIEJAR, $this->cookie_file);
    # Load cookie from this file
    curl_setopt($curl, CURLOPT_COOKIEFILE, $this->cookie_file);

    return $curl;
  }

  public function __destruct() {
    $this->cleanup();
  }
}
