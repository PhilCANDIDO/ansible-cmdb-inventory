#!/bin/bash
# setup_cmdb_report.sh - Script de préparation et diagnostic pour cmdb_report.yml
# Version: 1.0
#
# Ce script vérifie et prépare l'environnement pour l'exécution du playbook cmdb_report.yml
# Il vérifie les dépendances Python, crée l'environnement virtuel et teste l'accès au repository

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Diagnostic et configuration pour cmdb_report.yml =====${NC}"
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Fonction pour vérifier les prérequis
check_prerequisites() {
    echo -e "${BLUE}[1/5] Vérification des prérequis...${NC}"
    
    # Vérifier Python 3
    if command -v python3 &>/dev/null; then
        PY_VERSION=$(python3 --version)
        echo -e "${GREEN}✓ Python 3 trouvé: $PY_VERSION${NC}"
    else
        echo -e "${RED}✗ Python 3 non trouvé. Il est requis pour le fonctionnement du rapport.${NC}"
        return 1
    fi
    
    # Vérifier pip
    if command -v pip3 &>/dev/null; then
        PIP_VERSION=$(pip3 --version | cut -d' ' -f1,2)
        echo -e "${GREEN}✓ pip trouvé: $PIP_VERSION${NC}"
    else
        echo -e "${YELLOW}! pip non trouvé. Installation recommandée.${NC}"
        
        # Proposer d'installer pip
        read -p "Voulez-vous installer pip? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            # Détecter la distribution Linux
            if [ -f /etc/debian_version ]; then
                echo "Installation de pip via apt..."
                sudo apt update && sudo apt install -y python3-pip
            elif [ -f /etc/redhat-release ]; then
                echo "Installation de pip via yum/dnf..."
                sudo yum install -y python3-pip || sudo dnf install -y python3-pip
            else
                echo -e "${YELLOW}Distribution non reconnue. Veuillez installer pip manuellement.${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}Installation de pip ignorée. Le script pourrait échouer plus tard.${NC}"
        fi
    fi
    
    # Vérifier python-venv
    if python3 -c "import venv" &>/dev/null; then
        echo -e "${GREEN}✓ Module venv de Python disponible${NC}"
    else
        echo -e "${YELLOW}! Module venv de Python non trouvé. Installation recommandée.${NC}"
        
        # Proposer d'installer python-venv
        read -p "Voulez-vous installer le module venv? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            # Détecter la distribution Linux
            if [ -f /etc/debian_version ]; then
                echo "Installation de python3-venv via apt..."
                sudo apt update && sudo apt install -y python3-venv
            elif [ -f /etc/redhat-release ]; then
                echo "Installation de python3-venv via yum/dnf..."
                sudo yum install -y python3-devel || sudo dnf install -y python3-devel
            else
                echo -e "${YELLOW}Distribution non reconnue. Veuillez installer python3-venv manuellement.${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}Installation de venv ignorée. Le script pourrait échouer plus tard.${NC}"
        fi
    fi
    
    # Vérifier ansible
    if command -v ansible &>/dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1)
        echo -e "${GREEN}✓ Ansible trouvé: $ANSIBLE_VERSION${NC}"
    else
        echo -e "${RED}✗ Ansible non trouvé. Il est requis pour exécuter le playbook.${NC}"
        return 1
    fi
    
    # Vérifier vault-password-file
    if [ -f .vault_pass ]; then
        echo -e "${GREEN}✓ Fichier .vault_pass trouvé${NC}"
    else
        echo -e "${YELLOW}! Fichier .vault_pass non trouvé. Il est nécessaire pour décrypter les variables vault.${NC}"
        echo -e "${YELLOW}  Créez ce fichier avec le mot de passe vault.${NC}"
        
        # Proposer de créer le fichier vault pass
        read -p "Voulez-vous créer le fichier .vault_pass maintenant? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            read -s -p "Entrez le mot de passe vault: " VAULT_PASS
            echo
            echo "$VAULT_PASS" > .vault_pass
            chmod 600 .vault_pass
            echo -e "${GREEN}✓ Fichier .vault_pass créé avec permissions 600${NC}"
        else
            echo -e "${YELLOW}Création du fichier .vault_pass ignorée.${NC}"
        fi
    fi
    
    return 0
}

# Fonction pour préparer l'environnement virtuel Python
setup_python_venv() {
    echo -e "\n${BLUE}[2/5] Préparation de l'environnement virtuel Python...${NC}"
    
    VENV_DIR="$HOME/.cmdb_venv"
    
    # Supprimer l'environnement virtuel s'il existe déjà
    if [ -d "$VENV_DIR" ]; then
        echo "Suppression de l'ancien environnement virtuel..."
        rm -rf "$VENV_DIR"
    fi
    
    # Créer un nouvel environnement virtuel
    echo "Création d'un nouvel environnement virtuel dans $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}✗ Échec de la création de l'environnement virtuel.${NC}"
        return 1
    fi
    
    # Mettre à jour pip
    echo "Mise à jour de pip dans l'environnement virtuel..."
    "$VENV_DIR/bin/pip" install --upgrade pip
    
    # Installer les dépendances Python
    echo "Installation des dépendances Python requises..."
    "$VENV_DIR/bin/pip" install openpyxl>=3.0.0 jmespath>=0.10.0
    
    # Vérifier l'installation
    echo "Vérification de l'installation des modules..."
    MODULES_OK=true
    
    for module in openpyxl jmespath; do
        if ! "$VENV_DIR/bin/python" -c "import $module" &>/dev/null; then
            echo -e "${RED}✗ Module $module non installé correctement.${NC}"
            MODULES_OK=false
        else
            echo -e "${GREEN}✓ Module $module installé correctement.${NC}"
        fi
    done
    
    if [ "$MODULES_OK" = false ]; then
        echo -e "${RED}✗ Certains modules n'ont pas été installés correctement.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Environnement virtuel Python prêt dans $VENV_DIR${NC}"
    return 0
}

# Fonction pour vérifier le repository CMDB
check_cmdb_repository() {
    echo -e "\n${BLUE}[3/5] Vérification du repository CMDB...${NC}"
    
    # Extraire les chemins du repository depuis les fichiers
    DEFAULT_REPO_DIR=$(grep -r "directory:" roles/cmdb_report/defaults/main.yml | head -n1 | awk '{print $2}' | tr -d '"')
    if [ -z "$DEFAULT_REPO_DIR" ]; then
        DEFAULT_REPO_DIR="/opt/cmdb/inventory"
    fi
    
    # Vérifier si le répertoire existe ou le créer
    if [ -d "$DEFAULT_REPO_DIR" ]; then
        echo -e "${GREEN}✓ Répertoire repository CMDB trouvé: $DEFAULT_REPO_DIR${NC}"
    else
        echo -e "${YELLOW}! Répertoire repository CMDB non trouvé: $DEFAULT_REPO_DIR${NC}"
        
        # Proposer de créer le répertoire
        read -p "Voulez-vous créer le répertoire repository? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            sudo mkdir -p "$DEFAULT_REPO_DIR/reports" "$DEFAULT_REPO_DIR/diagnostics"
            sudo chown -R $(whoami):$(whoami) "$DEFAULT_REPO_DIR"
            echo -e "${GREEN}✓ Répertoire repository CMDB créé: $DEFAULT_REPO_DIR${NC}"
        else
            echo -e "${YELLOW}Création du répertoire repository ignorée.${NC}"
            echo -e "${YELLOW}Le playbook utilisera le répertoire de secours.${NC}"
        fi
    fi
    
    # Vérifier le sous-répertoire reports
    if [ -d "$DEFAULT_REPO_DIR/reports" ]; then
        echo -e "${GREEN}✓ Sous-répertoire reports trouvé${NC}"
    else
        echo -e "${YELLOW}! Sous-répertoire reports non trouvé${NC}"
        
        # Proposer de créer le sous-répertoire
        read -p "Voulez-vous créer le sous-répertoire reports? (o/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            sudo mkdir -p "$DEFAULT_REPO_DIR/reports"
            sudo chown -R $(whoami):$(whoami) "$DEFAULT_REPO_DIR/reports"
            echo -e "${GREEN}✓ Sous-répertoire reports créé${NC}"
        fi
    fi
    
    # Tester les permissions
    touch "$DEFAULT_REPO_DIR/test_write_permissions" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Permissions d'écriture OK pour $DEFAULT_REPO_DIR${NC}"
        rm -f "$DEFAULT_REPO_DIR/test_write_permissions"
    else
        echo -e "${RED}✗ Problème de permissions sur $DEFAULT_REPO_DIR${NC}"
        echo -e "${YELLOW}  Utilisation du script fix_cmdb_permissions.sh recommandée${NC}"
        return 1
    fi
    
    return 0
}

# Fonction pour vérifier l'inventaire Ansible
check_ansible_inventory() {
    echo -e "\n${BLUE}[4/5] Vérification de l'inventaire Ansible...${NC}"
    
    # Vérifier l'existence du fichier d'inventaire
    if [ -f "inventory/dev/inventory.ini" ]; then
        echo -e "${GREEN}✓ Fichier d'inventaire trouvé: inventory/dev/inventory.ini${NC}"
    else
        echo -e "${YELLOW}! Fichier d'inventaire non trouvé: inventory/dev/inventory.ini${NC}"
        
        # Vérifier l'existence du fichier exemple
        if [ -f "inventory/dev/hosts.example" ]; then
            echo -e "${YELLOW}  Un fichier exemple existe: inventory/dev/hosts.example${NC}"
            
            # Proposer de copier le fichier exemple
            read -p "Voulez-vous copier le fichier exemple comme inventaire? (o/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                cp "inventory/dev/hosts.example" "inventory/dev/inventory.ini"
                echo -e "${GREEN}✓ Fichier d'inventaire créé à partir de l'exemple${NC}"
            fi
        else
            echo -e "${RED}✗ Aucun fichier exemple d'inventaire trouvé${NC}"
            echo -e "${YELLOW}  Créez manuellement un fichier d'inventaire${NC}"
            return 1
        fi
    fi
    
    # Vérifier si le groupe cmdb_repository existe dans l'inventaire
    if [ -f "inventory/dev/inventory.ini" ] && grep -q "cmdb_repository" "inventory/dev/inventory.ini"; then
        echo -e "${GREEN}✓ Groupe cmdb_repository trouvé dans l'inventaire${NC}"
    else
        echo -e "${YELLOW}! Groupe cmdb_repository non trouvé dans l'inventaire${NC}"
        echo -e "${YELLOW}  Assurez-vous que votre inventaire contient une section [cmdb_repository]${NC}"
    fi
    
    return 0
}

# Fonction pour lancer le playbook
run_cmdb_report() {
    echo -e "\n${BLUE}[5/5] Exécution du playbook cmdb_report.yml...${NC}"
    
    echo -e "${YELLOW}Voulez-vous exécuter le playbook cmdb_report.yml maintenant?${NC}"
    echo -e "${YELLOW}Commande: ansible-playbook -i inventory/dev/inventory.ini cmdb_report.yml --vault-password-file=.vault_pass${NC}"
    read -p "Exécuter le playbook? (o/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        echo -e "${BLUE}Exécution du playbook...${NC}"
        ansible-playbook -i inventory/dev/inventory.ini cmdb_report.yml --vault-password-file=.vault_pass
        
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}✓ Playbook exécuté avec succès!${NC}"
        else
            echo -e "\n${RED}✗ Échec de l'exécution du playbook.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Exécution du playbook ignorée.${NC}"
    fi
    
    return 0
}

# Fonction principale
main() {
    # Exécuter les fonctions dans l'ordre
    check_prerequisites
    if [ $? -ne 0 ]; then
        echo -e "${RED}Échec de la vérification des prérequis. Correction des problèmes requise.${NC}"
        exit 1
    fi
    
    setup_python_venv
    if [ $? -ne 0 ]; then
        echo -e "${RED}Échec de la configuration de l'environnement virtuel. Correction des problèmes requise.${NC}"
        exit 1
    fi
    
    check_cmdb_repository
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Avertissement: Problèmes avec le repository CMDB. Le playbook pourrait utiliser le répertoire de secours.${NC}"
    fi
    
    check_ansible_inventory
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Avertissement: Problèmes avec l'inventaire Ansible. Le playbook pourrait échouer.${NC}"
    fi
    
    run_cmdb_report
    
    echo -e "\n${BLUE}===== Diagnostic et configuration terminés =====${NC}"
}

# Exécuter la fonction principale
main