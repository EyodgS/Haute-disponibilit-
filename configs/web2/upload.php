<?php
$dataDir = "/var/www/data";
@mkdir($dataDir, 0755, true);

$message = "";
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_FILES["fichier"])) {
    $target = $dataDir . "/" . basename($_FILES["fichier"]["name"]);
    if (move_uploaded_file($_FILES["fichier"]["tmp_name"], $target)) {
        $message = "Fichier depose sur " . gethostname() . " : " . basename($target);
    } else {
        $message = "Erreur lors du depot";
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><title>Depot de fichier</title></head>
<body>
<h1>Depot de piece jointe</h1>
<?php if ($message): ?><p><strong><?php echo htmlspecialchars($message); ?></strong></p><?php endif; ?>
<form method="post" enctype="multipart/form-data">
    <input type="file" name="fichier" required>
    <button type="submit">Envoyer</button>
</form>

<h2>Fichiers presents sur <?php echo gethostname(); ?></h2>
<ul>
<?php
$files = scandir($dataDir);
foreach ($files as $f) {
    if ($f !== "." && $f !== "..") {
        echo "<li>" . htmlspecialchars($f) . " (" . filesize("$dataDir/$f") . " octets)</li>";
    }
}
?>
</ul>
</body>
</html>
