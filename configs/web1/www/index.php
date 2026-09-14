<?php
$hostname = gethostname();
header('Content-Type: application/json');
echo json_encode([
    'status' => 'ok',
    'node' => $hostname,
    'service' => 'tp-ha-web',
], JSON_PRETTY_PRINT);
