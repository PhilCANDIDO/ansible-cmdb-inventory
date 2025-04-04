#!/bin/bash
# Script pour vérifier si jmespath est installé
# Usage: ./check-jmespath.sh

# Définir les couleurs pour une sortie lisible
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Vérification de l'environnement Python pour Ansible ===${NC}"

# Déterminer l'environnement Python utilisé par Ansible
ANSIBLE_PYTHON_PATH=$(ansible --version | grep "python version" | awk '{print $4}')
PYTHON_PATH=$(which python3 || which python)

echo -e "Python d'Ansible trouvé: ${ANSIBLE_PYTHON_PATH}"
echo -e "Python par défaut du système: ${PYTHON_PATH}"

# Vérifier jmespath
echo -e "\n${YELLOW}=== Vérification de jmespath ===${NC}"
if $PYTHON_PATH -c "import jmespath; print('JMESPath version: ' + jmespath.__version__)" 2>/dev/null; then
    echo -e "${GREEN}✓ jmespath est correctement installé.${NC}"
else
    echo -e "${RED}✗ jmespath n'est pas installé dans le Python par défaut.${NC}"
    echo -e "${YELLOW}Installation recommandée:${NC} pip install jmespath"
fi

# Vérifier si on est dans un environnement virtuel
echo -e "\n${YELLOW}=== Environnement Python ===${NC}"
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "Environnement virtuel actif: ${GREEN}$VIRTUAL_ENV${NC}"
else
    echo -e "Aucun environnement virtuel actif détecté."
fi

# Vérifier AWX/Tower si pertinent
echo -e "\n${YELLOW}=== AWX/Tower ===${NC}"
if [ -d "/var/lib/awx" ] || [ -d "/var/lib/tower" ]; then
    echo -e "Environnement AWX/Tower détecté."
    echo -e "${YELLOW}Note:${NC} Assurez-vous que collections/requirements.yml contient la section python avec jmespath."
    echo -e "      Et que l'option 'Mettre à jour les dépendances Galaxy et Python à la mise à jour' est activée."
else
    echo -e "AWX/Tower non détecté. Si vous utilisez AWX/Tower, ce script doit être exécuté sur le serveur approprié."
fi

echo -e "\n${YELLOW}=== Conclusion ===${NC}"
if $PYTHON_PATH -c "import jmespath" 2>/dev/null; then
    echo -e "${GREEN}✓ Votre environnement est correctement configuré pour utiliser json_query.${NC}"
else
    echo -e "${RED}✗ jmespath doit être installé pour utiliser json_query.${NC}"
    echo -e "  Options d'installation:"
    echo -e "  1. ${YELLOW}Pour l'utilisateur courant:${NC} pip install --user jmespath"
    echo -e "  2. ${YELLOW}Pour le système entier:${NC} sudo pip install jmespath"
    echo -e "  3. ${YELLOW}Pour l'environnement virtuel:${NC} pip install jmespath"
    echo -e "  4. ${YELLOW}Pour AWX/Tower:${NC} Ajouter à collections/requirements.yml"
fi

exit 0