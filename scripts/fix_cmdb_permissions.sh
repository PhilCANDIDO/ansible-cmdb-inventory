#!/bin/bash
# fix_cmdb_permissions.sh - Script to fix permissions for CMDB repository
# Usage: sudo ./fix_cmdb_permissions.sh [username] [base_directory]

# Default values
USERNAME=${1:-$(whoami)}
BASE_DIR=${2:-"/opt/cmdb/inventory"}

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== CMDB Repository Permissions Fix ===${NC}"
echo "Username: $USERNAME"
echo "Base Directory: $BASE_DIR"

# Validate if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}Error: User $USERNAME does not exist${NC}"
    exit 1
fi

# Function to fix directory permissions
fix_directory() {
    local dir=$1
    
    # Create directory if it doesn't exist
    if [ ! -d "$dir" ]; then
        echo -e "Creating directory: $dir"
        mkdir -p "$dir"
    fi
    
    # Fix ownership and permissions
    echo -e "Setting ownership of $dir to $USERNAME"
    chown -R "$USERNAME":"$USERNAME" "$dir"
    chmod -R 755 "$dir"
    
    # Test write access
    sudo -u "$USERNAME" touch "$dir/test_write_access" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Directory $dir is writable by $USERNAME${NC}"
        rm -f "$dir/test_write_access"
    else
        echo -e "${RED}✗ Directory $dir is NOT writable by $USERNAME${NC}"
        return 1
    fi
    
    return 0
}

# Fix main directories
echo -e "\n${YELLOW}Fixing main repository directory${NC}"
fix_directory "$BASE_DIR"

# Fix subdirectories
echo -e "\n${YELLOW}Fixing diagnostics directory${NC}"
fix_directory "$BASE_DIR/diagnostics"

echo -e "\n${YELLOW}Fixing reports directory${NC}"
fix_directory "$BASE_DIR/reports"

echo -e "\n${YELLOW}Fixing fallback directory${NC}"
fix_directory "/tmp/cmdb_inventory_repository"

# Final verification
echo -e "\n${YELLOW}Final verification${NC}"
success=true

for dir in "$BASE_DIR" "$BASE_DIR/diagnostics" "$BASE_DIR/reports" "/tmp/cmdb_inventory_repository"; do
    sudo -u "$USERNAME" touch "$dir/test_write_access" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Directory $dir still has permission issues${NC}"
        success=false
    else
        rm -f "$dir/test_write_access"
    fi
done

if $success; then
    echo -e "\n${GREEN}All permissions fixed successfully!${NC}"
    echo -e "You can now run your Ansible playbook without permission issues."
else
    echo -e "\n${RED}Some permission issues could not be resolved.${NC}"
    echo -e "Please check file system permissions, SELinux/AppArmor settings, or mount options."
fi

exit 0