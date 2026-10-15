# ================================================================
# Kill Chain — Simulation d'intrusion complète
# Laboratoire de Détection Personnel — Purple Team Home Lab
#
# Simule un scénario d'intrusion réaliste en 5 étapes :
# Reconnaissance → Exécution → Persistence →
# Évasion de défense → Exfiltration
#
# Prérequis :
#   - Atomic Red Team installé dans C:\AtomicRedTeam\
#   - Agent Wazuh en cours d'exécution (surveillance active)
#   - Carte NAT connectée pour l'étape 5 (accès Internet)
# ================================================================

# Chargement du module Atomic Red Team
Import-Module "C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1" -Force

Write-Host "`n================================================" -ForegroundColor Yellow
Write-Host "  SIMULATION DE KILL CHAIN — Lab Détection" -ForegroundColor Yellow
Write-Host "  Surveiller les alertes Wazuh sur la VM manager" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Yellow

# ------------------------------------------------------------------
# Étape 1 — Reconnaissance (T1087.001)
# Énumération des comptes utilisateurs locaux
# ------------------------------------------------------------------
Write-Host "[*] Étape 1/5 — Reconnaissance : énumération des comptes locaux" -ForegroundColor Cyan
Invoke-AtomicTest T1087.001 -TestNumbers 8
Write-Host "[+] Étape 1 terminée`n" -ForegroundColor Green
Start-Sleep -Seconds 15

# ------------------------------------------------------------------
# Étape 2 — Exécution (T1059.001)
# Exécution de commande PowerShell suspecte
# ------------------------------------------------------------------
Write-Host "[*] Étape 2/5 — Exécution : commande PowerShell suspecte" -ForegroundColor Cyan
Invoke-AtomicTest T1059.001 -TestNumbers 17
Write-Host "[+] Étape 2 terminée`n" -ForegroundColor Green
Start-Sleep -Seconds 15

# ------------------------------------------------------------------
# Étape 3 — Persistence (T1569.002)
# Création d'un service malveillant pour la persistence
# ------------------------------------------------------------------
Write-Host "[*] Étape 3/5 — Persistence : création d'un service malveillant" -ForegroundColor Cyan
Invoke-AtomicTest T1569.002 -TestNumbers 1
Write-Host "[+] Étape 3 terminée`n" -ForegroundColor Green
Start-Sleep -Seconds 15

# ------------------------------------------------------------------
# Étape 4 — Évasion de défense (T1070)
# Suppression des indicateurs via FSUtil
# ------------------------------------------------------------------
Write-Host "[*] Étape 4/5 — Évasion de défense : suppression des indicateurs (fsutil)" -ForegroundColor Cyan
Invoke-AtomicTest T1070 -TestNumbers 1
Write-Host "[+] Étape 4 terminée`n" -ForegroundColor Green
Start-Sleep -Seconds 15

# ------------------------------------------------------------------
# Étape 5 — Exfiltration (T1048.002)
# Simulation d'exfiltration de données via HTTPS/curl
# Note : nécessite que la carte NAT soit connectée
# ------------------------------------------------------------------
Write-Host "[*] Étape 5/5 — Exfiltration : envoi de données via HTTPS/curl" -ForegroundColor Cyan
Invoke-AtomicTest T1048.002 -TestNumbers 1 -GetPrereqs
Invoke-AtomicTest T1048.002 -TestNumbers 1
Write-Host "[+] Étape 5 terminée`n" -ForegroundColor Green

Write-Host "================================================" -ForegroundColor Yellow
Write-Host "  KILL CHAIN TERMINÉE" -ForegroundColor Yellow
Write-Host "  Vérifier les alertes Wazuh :" -ForegroundColor Yellow
Write-Host "  sudo tail -F /var/ossec/logs/alerts/alerts.json | jq -r" -ForegroundColor Yellow
Write-Host "  'select(.agent.name==""WIN-CIBLE-01"") | [.timestamp,.rule.level,.rule.description] | @tsv'" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Yellow

# ------------------------------------------------------------------
# Nettoyage — suppression des artefacts laissés par les tests
# ------------------------------------------------------------------
Write-Host "[*] Nettoyage des artefacts..." -ForegroundColor Gray
Invoke-AtomicTest T1569.002 -TestNumbers 1 -Cleanup
Invoke-AtomicTest T1048.002 -TestNumbers 1 -Cleanup
Write-Host "[+] Nettoyage terminé`n" -ForegroundColor Green
