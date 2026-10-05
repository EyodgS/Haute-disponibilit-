<?php
header("Content-Type: text/plain");

if (!function_exists("phpversion")) {
    http_response_code(500);
    echo "PHP KO\n";
    exit;
}

$dataDir = "/var/www/data";
if (!is_dir($dataDir)) {
    @mkdir($dataDir, 0755, true);
}
if (!is_writable($dataDir)) {
    http_response_code(503);
    echo "DATA KO\n";
    exit;
}

if (file_exists("/etc/tp/maintenance")) {
    http_response_code(503);
    echo "MAINTENANCE\n";
    exit;
}

echo "OK\n";
