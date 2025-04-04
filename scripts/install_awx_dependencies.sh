#!/bin/bash
# Script pour installer les dépendances Python dans AWX/Tower
# Usage: ./install_awx_dependencies.sh [chemin_vers_requirements.yml]

# Définir les couleurs pour la sortie
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Vérifier si un argument a été passé
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Aucun fichier spécifié, recherche des fichiers par défaut...${NC}"
    
    # Liste des chemins possibles par défaut, dans l'ordre de préférence
    POSSIBLE_PATHS=(
        "collections/requirements.yml"
        "roles/cmdb_inventory/requirements.yml"
        "requirements.yml"
    )
    
    REQUIREMENTS_FILE=""
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -f "$path" ]; then
            REQUIREMENTS_FILE="$path"
            echo -e "${GREEN}Fichier trouvé: $REQUIREMENTS_FILE${NC}"
            break
        fi
    done
    
    if [ -z "$REQUIREMENTS_FILE" ]; then
        echo -e "${RED}Aucun fichier requirements.yml trouvé dans les emplacements standards!${NC}"
        echo -e "Usage: $0 [chemin_vers_requirements.yml]"
        exit 1
    fi
else
    REQUIREMENTS_FILE="$1"
fi

# Chemins des environnements virtuels pour AWX et Tower
AWX_VENV="/var/lib/awx/venv/ansible"  # Chemin standard pour AWX
TOWER_VENV="/var/lib/tower/venv/ansible"  # Chemin standard pour Tower

# Détecter l'environnement virtuel d'AWX/Tower
if [ -d "$AWX_VENV" ]; then
    VENV_PATH="$AWX_VENV"
    echo -e "${GREEN}Environnement virtuel AWX trouvé: $VENV_PATH${NC}"
elif [ -d "$TOWER_VENV" ]; then
    VENV_PATH="$TOWER_VENV"
    echo -e "${GREEN}Environnement virtuel Tower trouvé: $VENV_PATH${NC}"
else
    echo -e "${RED}Environnement virtuel AWX/Tower non trouvé.${NC}"
    echo -e "${YELLOW}Voulez-vous spécifier le chemin manuellement? (o/N)${NC}"
    read -p "" -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        read -p "Veuillez entrer le chemin complet de l'environnement virtuel: " VENV_PATH
        if [ ! -d "$VENV_PATH" ]; then
            echo -e "${RED}Le chemin spécifié n'existe pas: $VENV_PATH${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Opération annulée.${NC}"
        exit 1
    fi
fi

# Vérifier si le fichier existe
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Le fichier $REQUIREMENTS_FILE n'existe pas!${NC}"
    exit 1
fi

echo -e "${YELLOW}=== Installation des dépendances Python dans l'environnement virtuel AWX/Tower ===${NC}"
echo -e "${YELLOW}Fichier de dépendances: $REQUIREMENTS_FILE${NC}"
echo -e "${YELLOW}Environnement virtuel: $VENV_PATH${NC}"

# Extraire les dépendances Python
echo -e "${YELLOW}Extraction des dépendances Python...${NC}"
python3 -c "
import yaml
import sys

try:
    with open('$REQUIREMENTS_FILE', 'r') as f:
        data = yaml.safe_load(f)
    
    if data and 'python' in data:
        for dep in data['python']:
            print(dep)
    else:
        print('Aucune dépendance Python trouvée dans le fichier', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f'Erreur lors de la lecture du fichier YAML: {e}', file=sys.stderr)
    sys.exit(1)
" > /tmp/awx_dependencies.txt

# Vérifier si l'extraction a réussi
if [ $? -ne 0 ] || [ ! -s "/tmp/awx_dependencies.txt" ]; then
    echo -e "${RED}Échec de l'extraction des dépendances Python!${NC}"
    cat /tmp/awx_dependencies.txt
    rm -f /tmp/awx_dependencies.txt
    exit 1
fi

# Afficher les dépendances trouvées
echo -e "${GREEN}Dépendances Python trouvées:${NC}"
cat /tmp/awx_dependencies.txt

# Demander confirmation avant installation
echo -e "${YELLOW}ATTENTION: La modification manuelle de l'environnement virtuel AWX/Tower peut causer des problèmes avec les mises à jour.${NC}"
echo -e "${YELLOW}La méthode recommandée est d'utiliser l'option 'Mettre à jour les dépendances' dans les paramètres du projet AWX/Tower.${NC}"
read -p "Voulez-vous tout de même installer ces dépendances? (o/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Oo]$ ]]; then
    echo -e "${YELLOW}Installation des dépendances...${NC}"
    
    # Si un nombre élevé d'environnements virtuels/conteneurs est concerné,
    # demander à l'utilisateur s'il souhaite générer un script ou exécuter directement
    read -p "Générer un script pour installation manuelle ultérieure? (o/N) " -n 1 -r GENERATE_SCRIPT
    echo
    
    if [[ $GENERATE_SCRIPT =~ ^[Oo]$ ]]; then
        SCRIPT_PATH="./install_awx_deps_$(date +%Y%m%d%H%M%S).sh"
        
        echo '#!/bin/bash' > $SCRIPT_PATH
        echo '# Script généré automatiquement pour installer des dépendances Python dans AWX/Tower' >> $SCRIPT_PATH
        echo "# Généré le $(date)" >> $SCRIPT_PATH
        echo "" >> $SCRIPT_PATH
        echo "VENV_PATH=\"$VENV_PATH\"" >> $SCRIPT_PATH
        echo "" >> $SCRIPT_PATH
        
        while read dep; do
            echo "echo \"Installation de: $dep\"" >> $SCRIPT_PATH
            echo "sudo \$VENV_PATH/bin/pip install $dep" >> $SCRIPT_PATH
        done < /tmp/awx_dependencies.txt
        
        chmod +x $SCRIPT_PATH
        echo -e "${GREEN}Script généré: $SCRIPT_PATH${NC}"
        echo -e "${YELLOW}Vous pouvez exécuter ce script sur le serveur AWX/Tower avec les droits appropriés.${NC}"
    else
        # Installation directe
        while read dep; do
            echo -e "${YELLOW}Installation de: $dep${NC}"
            sudo $VENV_PATH/bin/pip install $dep
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Installation réussie: $dep${NC}"
            else
                echo -e "${RED}✗ Échec de l'installation: $dep${NC}"
            fi
        done < /tmp/awx_dependencies.txt
        
        echo -e "${GREEN}Installation terminée!${NC}"
    fi
else
    echo -e "${YELLOW}Installation annulée.${NC}"
fi

# Nettoyage
rm -f /tmp/awx_dependencies.txt

echo -e "${YELLOW}=== Terminé ===${NC}"