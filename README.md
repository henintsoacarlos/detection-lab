# Laboratoire de Détection — Purple Team Home Lab

> Projet personnel de cybersécurité  
> Focus : déploiement SIEM, simulation d'attaques, évaluation des règles de détection

---

## Description

Ce projet est un laboratoire de détection entièrement isolé, conçu pour évaluer les règles SIEM contre des techniques d'attaque réelles (MITRE ATT&CK) sans impacter aucun environnement de production. Il combine des outils blue team (Wazuh, Sysmon) avec une simulation red team (Atomic Red Team) pour mesurer le taux de couverture et réduire les faux positifs.

Cette approche s'appelle le **purple teaming** — l'attaquant et le défenseur travaillent ensemble dans un environnement contrôlé pour améliorer la détection.

---

## Architecture

```
[Machine hôte 192.168.56.1]
        |
        | Réseau host-only VirtualBox (192.168.56.0/24 — isolé)
        |
   +-----------+           +-----------+
   | VM Wazuh  |           |  VM WIN   |
   | Manager   |<----------| CIBLE-01  |
   | .56.10    |  alertes  |  .56.20   |
   |  Ubuntu   |           | Win Srv   |
   |  26.04    |           | Core 2022 |
   +-----------+           +-----------+
                           + Sysmon64
                           + Agent Wazuh
                           + Atomic Red Team
```

**Pile technique :**
- **Hyperviseur** : VirtualBox 7.x — réseau host-only, totalement isolé
- **SIEM** : Wazuh 4.14 (mode manager seul, 2 Go de RAM)
- **Cible Windows** : Windows Server 2022 Core + Sysmon (config SwiftOnSecurity)
- **Simulation d'attaques** : Atomic Red Team (Invoke-AtomicRedTeam)

---

## Structure du dépôt

```
detection-lab/
├── README.md
├── configs/
│   ├── ossec.conf              # Configuration agent Wazuh (Windows)
│   ├── sysmonconfig.xml        # Configuration Sysmon (SwiftOnSecurity)
│   └── netplan-lab.yaml        # Configuration réseau Ubuntu (host-only)
├── scripts/
│   ├── killchain.ps1           # Script kill chain complète (5 étapes)
│   └── generate-noise.ps1      # Générateur de bruit de fond (activité légitime)
└── docs/
    └── Detection_Lab_Portfolio.pdf
```

---

## Phases du projet

### Phase 1 — Déploiement de l'infrastructure ✅

| Tâche                                    | Statut |
|------------------------------------------|--------|
| VirtualBox + réseau host-only            | ✅     |
| Ubuntu Server + Wazuh Manager            | ✅     |
| Windows Server Core + Sysmon             | ✅     |
| Connexion agent Wazuh Windows → manager  | ✅     |
| Validation bout-en-bout (alerte en < 2s) | ✅     |

**Test de validation :**
```powershell
net user testlab P@ssw0rd123! /add
net user testlab /delete
```
→ Wazuh génère : `User account enabled or created (niveau 8)` + `User account disabled or deleted (niveau 8)`

---

### Phase 2 — Données synthétiques ✅

**Taux de détection : 5/7 techniques (71%)**

| Technique MITRE | Description                     | Détecté    | Niveau max |
|-----------------|---------------------------------|------------|------------|
| T1082           |      System Info Discovery      |  ❌ Non   |      —     |
| T1087.001       |     Local Account Discovery     |   ✅ Oui  |      3     |
| T1098/T1531     |      Account Manipulation       |   ✅ Oui  |      8     |
| T1003.001       | Dump LSASS (Credential Dumping) | ⛔ Bloqué |      —     |
| T1069.001       |   Permission Groups Discovery   |   ✅ Oui  |      4     |
| T1012           |          Query Registry         |   ✅ Oui  |      4     |
| T1569.002       |       Service Execution         |   ✅ Oui  |      9     |

**Notes :**
- T1082 ne génère aucune alerte par défaut (usage légitime trop fréquent — une règle Sigma personnalisée serait nécessaire)
- T1003.001 a été bloqué par une protection Windows native avant d'atteindre Wazuh (défense en profondeur fonctionnelle)

---

### Phase 3 — Kill chain complète ✅

**5/5 étapes détectées (100%)**

| Étape | Tactique        | Technique MITRE | Détecté |
|-------|-----------------|-----------------|---------|
|   1   | Reconnaissance  | T1087.001       | ✅      |
|   2   |    Exécution    | T1059.001       | ✅      |
|   3   | Persistence     | T1569.002       | ✅      |
|   4   | Defense Evasion | T1070           | ✅      |
|   5   | Exfiltration    | T1048.002       | ✅      |

Lancer la kill chain complète :
```powershell
.\scripts\killchain.ps1
```

---

## Commandes de surveillance essentielles

```bash
# Flux d'alertes en temps quasi réel (tous agents)
watch -n 1 -c "sudo tail -F /var/ossec/logs/alerts/alerts.json | \
  jq -r '[.timestamp, .agent.name, .rule.level, .rule.description] | @tsv'"

# Filtré sur la VM Windows uniquement
watch -n 1 -c "sudo tail -F /var/ossec/logs/alerts/alerts.json | \
  jq -r 'select(.agent.name=="WIN-CIBLE-01") | [.timestamp, .rule.level, .rule.description] | @tsv'"

# Statut des agents connectés
sudo /var/ossec/bin/agent_control -l
```

---

## Incidents et résolutions

| Incident                  | Cause                                    | Solution                                          |
|---------------------------|------------------------------------------|---------------------------------------------------|
| Disque LVM saturé (×3)    | Vulnerability Detector Wazuh (~4 Go CVE) | `lvextend` + désactivation du module VD           |
| Wazuh ne démarre pas      | Disque plein → wazuh-db ne peut écrire   | Vider `/var/ossec/queue/vd_updater/tmp/`          |
| Alertes non temps réel    | Buffering jq + inode recréé              | `tail -F` + `jq --unbuffered`                     |
| Désynchronisation horloge | Multiples arrêts/reprises de VM          | `ntpdate pool.ntp.org` + `hwclock --systohc`      |
| ProcDump bloqué sur LSASS | Protection Windows native                | Documenté comme résultat de défense en profondeur |

---

## Prérequis matériel

| Composant | Minimum              | Recommandé        |
|-----------|----------------------|-------------------|
| RAM       | 8 Go                 | 16 Go             |
| Disque    | SSD 60 Go libres     | SSD 100 Go libres |
| CPU       | 4 cœurs + VT-x/AMD-V | 6+ cœurs          |

---

## Outils et ressources

| Outil                         | Usage                              | Lien                                                                                         |
|-------------------------------|------------------------------------|----------------------------------------------------------------------------------------------|
| Wazuh                         | SIEM / moteur de détection         | [wazuh.com](https://wazuh.com)                                                               |
| Sysmon                        | Collecte logs Windows détaillés    | [Microsoft Sysinternals](https://learn.microsoft.com/sysinternals/downloads/sysmon)          |
| Atomic Red Team               | Simulation d'attaques MITRE ATT&CK | [github.com/redcanaryco/atomic-red-team](https://github.com/redcanaryco/atomic-red-team)     |
| MITRE ATT&CK Navigator        | Visualisation de la couverture     | [attack.mitre.org](https://mitre-attack.github.io/attack-navigator)                          |
| SigmaHQ                       | Règles de détection open-source    | [github.com/SigmaHQ/sigma](https://github.com/SigmaHQ/sigma)                                 |
| SwiftOnSecurity/sysmon-config | Config Sysmon de référence         | [github.com/SwiftOnSecurity/sysmon-config](https://github.com/SwiftOnSecurity/sysmon-config) |

---

## Feuille de route

- [ ] Ajouter une VM Linux cible (Ubuntu + auditd)
- [ ] Déployer pfSense pour les logs réseau + Suricata IDS
- [ ] Dashboard Wazuh (nécessite upgrade à 16 Go de RAM)
- [ ] Intégration des règles Sigma (SigmaHQ) via sigma-cli
- [ ] Heatmap MITRE ATT&CK Navigator pour la visualisation de la couverture
- [ ] Déploiement de Caldera pour l'orchestration automatisée

---

*Projet personnel — détection engineering & purple teaming*
