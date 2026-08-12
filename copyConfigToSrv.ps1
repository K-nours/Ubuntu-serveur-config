Write-Host "=== Déploiement de scripts vers un serveur Ubuntu ==="

# Demande des informations à l'utilisateur
$username   = Read-Host "Nom d'utilisateur SSH"
$hostDest   = Read-Host "Adresse du serveur (ex: 192.168.1.50)"
$remotePath = Read-Host "Chemin de destination sur le serveur (ex: /home/user/scripts)"
$localPath  = Read-Host "Chemin local des scripts à envoyer (ex: C:\Scripts)"

Write-Host "`n=== Création du dossier distant si nécessaire ==="
Write-Host "(Vous devrez entrer le mot de passe SSH)"

# Création du dossier distant
ssh.exe "$username@$hostDest" "mkdir -p '$remotePath'"

Write-Host "`nDossier distant prêt."
Write-Host "=== Copie des fichiers via SCP ==="
Write-Host "(Vous devrez entrer le mot de passe SSH)"

# Copie des fichiers
scp.exe -r "$localPath\*" "$username@${hostDest}:$remotePath"

Write-Host "`n=== Application des permissions d'exécution sur le serveur ==="
Write-Host "(Vous devrez entrer le mot de passe SSH)"

# chmod +x sur tous les fichiers copiés
ssh.exe "$username@$hostDest" "chmod +x '$remotePath'/*"

Write-Host "`n=== Déploiement terminé avec succès ==="
