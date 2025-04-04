#!/bin/bash
# Script pour installer les dépendances Python à partir d'un fichier requirements.yml
# Usage: ./install_dependencies.sh [chemin_vers_requirements.yml]

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

TEMP_PIP_REQUIREMENTS="/tmp/ansible_pip_requirements.txt"

echo -e "${YELLOW}=== Installation des dépendances Python depuis $REQUIREMENTS_FILE ===${NC}"

# Vérifier si le fichier existe
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Le fichier $REQUIREMENTS_FILE n'existe pas!${NC}"
    exit 1
fi

# Extraire la section python du fichier YAML
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
" > $TEMP_PIP_REQUIREMENTS

# Vérifier si l'extraction a réussi
if [ $? -ne 0 ] || [ ! -s "$TEMP_PIP_REQUIREMENTS" ]; then
    echo -e "${RED}Échec de l'extraction des dépendances Python!${NC}"
    cat $TEMP_PIP_REQUIREMENTS
    rm -f $TEMP_PIP_REQUIREMENTS
    exit 1
fi

# Afficher les dépendances trouvées
echo -e "${GREEN}Dépendances Python trouvées:${NC}"
cat $TEMP_PIP_REQUIREMENTS

# Demander confirmation avant installation
read -p "Voulez-vous installer ces dépendances? (o/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Oo]$ ]]; then
    echo -e "${YELLOW}Installation des dépendances...${NC}"
    
    # Détecter si nous sommes dans un environnement virtuel
    if [ -n "$VIRTUAL_ENV" ]; then
        echo -e "Installation dans l'environnement virtuel: ${GREEN}$VIRTUAL_ENV${NC}"
        pip install -r $TEMP_PIP_REQUIREMENTS
    else
        echo -e "${YELLOW}Aucun environnement virtuel détecté.${NC}"
        read -p "Installer pour l'utilisateur courant uniquement? (o/N, 'n' pour installer à l'échelle du système) " -n 1 -r USER_ONLY
        echo
        
        if [[ $USER_ONLY =~ ^[Oo]$ ]]; then
            echo -e "Installation pour l'utilisateur courant..."
            pip install --user -r $TEMP_PIP_REQUIREMENTS
        else
            echo -e "Installation à l'échelle du système (peut nécessiter des droits sudo)..."
            sudo pip install -r $TEMP_PIP_REQUIREMENTS
        fi
    fi
    
    # Vérifier le succès de l'installation
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Installation réussie!${NC}"
    else
        echo -e "${RED}Échec de l'installation!${NC}"
    fi
else
    echo -e "${YELLOW}Installation annulée.${NC}"
fi

# Nettoyage
rm -f $TEMP_PIP_REQUIREMENTS

echo -e "${YELLOW}=== Terminé ===${NC}"