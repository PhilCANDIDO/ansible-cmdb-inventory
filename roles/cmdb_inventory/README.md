# Rôle Ansible : cmdb_inventory

Ce rôle Ansible permet de collecter automatiquement un inventaire complet des serveurs Linux pour alimenter une CMDB (Configuration Management Database).

## Fonctionnalités

Le rôle recueille les informations suivantes :

### Informations matérielles
- Modèle et fabricant du serveur
- Numéro de série
- Type de processeur, nombre de cœurs/threads
- Capacité RAM totale
- Stockage (disques, capacités, RAID)
- Interfaces réseau (nombre, type, débit)
- Type de virtualisation (si applicable)

### Informations logicielles
- Version et distribution Linux
- Noyau Linux utilisé
- Nombre de packages installés
- Services en cours d'exécution
- Bases de données installées

### Informations réseau
- Adresses IP (IPv4/IPv6)
- Nom d'hôte et FQDN
- Configuration DNS
- Routes réseau
- Configuration firewall

### Informations de sécurité
- État des mises à jour
- Utilisateurs configurés (comptes shell, comptes sudo, etc.)
- SELinux/AppArmor
- Certificats et dates d'expiration
- Solutions de sauvegarde détectées

### Informations organisationnelles
- Rôle/fonction du serveur
- Criticité (production, test, développement)
- Applications hébergées
- Propriétaire métier
- Administrateur technique
- SLA/niveau de support
- Date de mise en service
- Date prévue pour fin de vie/remplacement
- Emplacement physique (datacenter, rack, position)

## Prérequis

- Ansible 2.9+
- Accès SSH aux serveurs cibles
- Droits sudo sur les serveurs cibles
- Python 2.7+ ou Python 3.5+ sur les serveurs cibles

## Variables

Toutes les variables sont définies dans `defaults/main.yml` et peuvent être personnalisées :

```yaml
# Répertoire où seront stockés les rapports sur le serveur Ansible
cmdb_inventory_local_dir: "/opt/cmdb/inventory"

# Répertoire temporaire sur les cibles
cmdb_inventory_remote_dir: "/tmp/cmdb_inventory"

# Format de sortie souhaité
cmdb_output_format: "json"  # Options: json, yaml, csv

# Informations à collecter
cmdb_collect:
  hardware: true
  software: true
  network: true
  security: true
  organizational: true
```

## Informations organisationnelles

Les informations organisationnelles peuvent être définies de plusieurs façons :

1. **Dans l'inventaire Ansible** : voir l'exemple `inventory.ini`
2. **Dans les group_vars ou host_vars**
3. **Sur les serveurs cibles** : fichiers dans `/etc/org_metadata.json` ou `/etc/server_*`

## Installation

1. Clonez ce dépôt dans votre répertoire de rôles Ansible :
   ```bash
   git clone https://[url-du-repo]/cmdb_inventory.git /etc/ansible/roles/cmdb_inventory
   ```

2. Modifiez votre inventaire Ansible pour inclure les informations organisationnelles (voir `inventory.ini` d'exemple)

3. Créez un playbook pour exécuter le rôle (voir `cmdb_inventory.yml` d'exemple)

## Utilisation

```bash
# Exécution sur tous les serveurs avec l'inventaire par défaut
ansible-playbook cmdb_inventory.yml

# Exécution sur un groupe spécifique
ansible-playbook cmdb_inventory.yml --limit webservers

# Exécution avec un inventaire personnalisé
ansible-playbook -i custom_inventory.ini cmdb_inventory.yml

# Exécution avec paramètres personnalisés
ansible-playbook cmdb_inventory.yml -e "cmdb_output_format=yaml cmdb_inventory_local_dir=/tmp/cmdb"
```

## Parallélisation pour grands parcs

Pour les parcs importants (plusieurs milliers de serveurs), utilisez l'option `--forks` pour augmenter la parallélisation :

```bash
ansible-playbook -i inventory.ini cmdb_inventory.yml --forks=100
```

## Intégration avec des CMDB

Les données collectées peuvent être facilement intégrées dans des solutions CMDB comme :
- ServiceNow
- iTop
- Device42
- Ralph CMDB

## Auteur
- Date : 29/03/2025
- Philippe CANDIDO ([philippe.candido@cpf-informatique.fr](philippe.candido@cpf-informatique.fr))

## Licence

MIT