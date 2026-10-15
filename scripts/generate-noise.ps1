# ================================================================
# Générateur de bruit de fond — Laboratoire de Détection
# Purple Team Home Lab
#
# Simule une activité utilisateur légitime pour créer une baseline
# réaliste et calibrer les règles de détection Wazuh
# (réduction des faux positifs).
#
# Actions simulées :
#   1. Lancement et fermeture de Notepad (création/fin de processus)
#   2. Écriture dans des fichiers temporaires (accès fichiers)
#   3. Résolution DNS (activité réseau)
#   4. Consultation de la liste des processus (énumération système)
#
# Utilisation :
#   powershell -File generate-noise.ps1
#   OU en arrière-plan :
#   Start-Process powershell -ArgumentList "-File C:\LabScripts\generate-noise.ps1" -WindowStyle Hidden
# ================================================================

$fichiers = @("C:\Windows\Temp\rapport.txt", "C:\Windows\Temp\notes.txt")

function Ecrire-Journal($message) {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $message"
}

Write-Host "[*] Générateur de bruit de fond démarré. Appuyez sur Ctrl+C pour arrêter.`n"

while ($true) {
    $action = Get-Random -Minimum 1 -Maximum 5

    switch ($action) {
        1 {
            # Lancement et fermeture d'un processus légitime
            Start-Process "notepad.exe" -WindowStyle Hidden
            Start-Sleep -Seconds 2
            Get-Process notepad -ErrorAction SilentlyContinue | Stop-Process -Force
            Ecrire-Journal "Notepad lancé puis fermé"
        }
        2 {
            # Écriture légitime dans un fichier
            $f = $fichiers | Get-Random
            "Activité $(Get-Date)" | Out-File -FilePath $f -Append
            Ecrire-Journal "Écriture dans $f"
        }
        3 {
            # Résolution DNS légitime (désactivée si carte NAT déconnectée)
            Resolve-DnsName "www.microsoft.com" -ErrorAction SilentlyContinue | Out-Null
            Ecrire-Journal "Résolution DNS tentée"
        }
        4 {
            # Consultation de la liste des processus (anodine)
            Get-Process | Select-Object -First 5 | Out-Null
            Ecrire-Journal "Liste des processus consultée"
        }
    }

    Start-Sleep -Seconds (Get-Random -Minimum 15 -Maximum 45)
}
