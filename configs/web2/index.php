<?php
session_start();
if (!isset($_SESSION['visites'])) {
    $_SESSION['visites'] = 0;
}
$_SESSION['visites']++;
$version = file_exists('/var/www/html/version.txt')
    ? file_get_contents('/var/www/html/version.txt')
    : 'inconnue';
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Portail NovaSanté</title>
</head>
<body>
<h1>Portail de prise de rendez-vous</h1>
<p><strong>Serveur :</strong> <?php echo gethostname(); ?></p>
<p><strong>IP :</strong> <?php echo $_SERVER['SERVER_ADDR']; ?></p>
<p><strong>Date :</strong> <?php echo date('Y-m-d H:i:s'); ?></p>
<p><strong>Visites (session) :</strong> <?php echo $_SESSION['visites']; ?></p>
<p><strong>Version :</strong> <?php echo htmlspecialchars($version); ?></p>
</body>
</html>
