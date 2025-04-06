# Ansible Role: cmdb_report

Ce rôle Ansible génère un rapport Excel consolidé à partir des données collectées par le rôle `cmdb_inventory` et l'envoie par email. Il est conçu pour être utilisé avec AWX/Tower dans le cadre d'un inventaire CMDB de grands parcs de serveurs.

## Fonctionnalités

Le rôle `cmdb_report` offre les fonctionnalités suivantes :

- **Collecte automatique** des fichiers JSON générés par `cmdb_inventory`
- **Génération d'un rapport Excel** structuré en plusieurs onglets :
  - Résumé global avec statistiques et graphiques
  - Liste des serveurs avec informations clés
  - Détails matériels (CPU, mémoire, disques)
  - Informations logicielles (OS, packages, services)
  - Configuration réseau
  - État de sécurité (mises à jour, utilisateurs, certificats)
  - Informations organisationnelles
- **Envoi par email** du rapport généré
  - Support des formats HTML et texte pour le corps du message
  - Possibilité de joindre le rapport Excel
  - Configuration complète du serveur SMTP

## Prérequis

- Ansible 2.9+
- Python 3.6+ avec les modules suivants :
  - openpyxl (pour la génération Excel)
  - jmespath (pour le traitement des données JSON)
- Rôle `cmdb_inventory` pour la collecte des données (optionnel si vous avez déjà des données JSON)

## Variables

Toutes les variables sont définies dans `defaults/main.yml` et peuvent être personnalisées :

### Configuration du repository

```yaml
cmdb_repository:
  mode: "manager"             # Mode repository (local ou manager)
  manager_group: "cmdb_repository"  # Groupe contenant le serveur manager
  directory: "/opt/cmdb/inventory"  # Répertoire pour les rapports
  fallback_directory: "/tmp/cmdb_inventory_repository"  # Répertoire de secours
```

### Configuration du rapport Excel

```yaml
cmdb_report:
  filename: "cmdb_inventory_report_{{ ansible_date_time.date }}.xlsx"  # Nom du fichier
  temp_dir: "/tmp/cmdb_report_{{ ansible_date_time.epoch }}"  # Répertoire temporaire
  server_limit: 0            # Limite du nombre de serveurs (0 = pas de limite)
  max_age_days: 30           # Âge maximum des rapports en jours
  date_format: "%d/%m/%Y %H:%M:%S"  # Format de date
  sheets:                     # Onglets à inclure
    summary: true
    servers: true
    hardware: true
    software: true
    network: true
    security: true
    organizational: true
    certificates: true
    updates: true
```

### Configuration de l'email

```yaml
cmdb_email:
  enabled: true              # Activer/désactiver l'envoi par email
  smtp:
    host: "smtp.example.com"  # Serveur SMTP
    port: 25                  # Port SMTP
    use_tls: false            # Utiliser TLS
    use_ssl: false            # Utiliser SSL
    username: ""              # Nom d'utilisateur SMTP
    password: ""              # Mot de passe SMTP
  from: "cmdb-report@example.com"  # Expéditeur
  to: ["admin@example.com"]   # Destinataires
  cc: []                      # Copies
  subject: "Rapport d'inventaire CMDB - {{ ansible_date_time.date }}"  # Sujet
  body_type: "html"           # Type de corps (html ou plain)
  attach_report: true         # Joindre le rapport
```

## Installation

### Via Ansible Galaxy

```bash
ansible-galaxy install git+https://github.com/your-username/ansible-cmdb-report.git
```

### Manuellement

```bash
git clone https://github.com/your-username/ansible-cmdb-report.git /etc/ansible/roles/cmdb_report
```

## Utilisation

### Dans un playbook simple

```yaml
---
- name: Générer et envoyer le rapport CMDB
  hosts: localhost
  roles:
    - role: cmdb_report
      vars:
        cmdb_repository:
          mode: "local"
          directory: "/opt/cmdb/inventory"
        cmdb_email:
          smtp:
            host: "smtp.votre-entreprise.com"
            username: "rapports"
            password: "{{ vault_smtp_password }}"
          to: ["equipe-infrastructure@votre-entreprise.com"]
```

### Avec un serveur repository dédié

```yaml
---
- name: Générer et envoyer le rapport CMDB
  hosts: cmdb_repository
  roles:
    - role: cmdb_report
      vars:
        cmdb_repository:
          mode: "manager"
          manager_group: "cmdb_repository"
        cmdb_email:
          to: ["equipe-infrastructure@votre-entreprise.com", "direction@votre-entreprise.com"]
```

### Vault pour les informations sensibles

Il est recommandé d'utiliser Ansible Vault pour les informations sensibles comme les mots de passe SMTP :

```yaml
# group_vars/all/vault.yml (crypté)
vault_smtp_password: "motdepasse_tres_securise"
```

Puis référencez-les dans votre configuration :

```yaml
cmdb_email:
  smtp:
    password: "{{ vault_smtp_password }}"
```

## Intégration avec AWX/Tower

Ce rôle est conçu pour fonctionner de manière optimale avec AWX/Tower :

1. Configurez un modèle de tâche pour le rôle `cmdb_inventory` avec un planning régulier
2. Configurez un deuxième modèle de tâche pour le rôle `cmdb_report` avec un planning moins fréquent
3. Définissez les variables dans un inventaire AWX ou comme variables supplémentaires du modèle
4. Utilisez les informations d'identification chiffrées d'AWX pour stocker les identifiants SMTP

## Auteur

- Philippe CANDIDO ([philippe.candido@cpf-informatique.fr](mailto:philippe.candido@cpf-informatique.fr))

## Licence

MIT