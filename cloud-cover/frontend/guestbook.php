<?php
ini_set('session.save_handler', 'redis');
//Redis URL
ini_set('session.save_path', 'tcp://10.128.0.201:30125');
session_start();
if (!array_key_exists('visit', $_SESSION)) {
$_SESSION['visit'] = 0;
}
$_SESSION['visit']++;
echo nl2br('Hello Cloud Cover, you have ' . $_SESSION['visit'] . ' visitors on this page.');
?>