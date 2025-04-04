#!/bin/bash
#
# ansible_user_setup.sh - Create and configure Ansible user on various Linux distributions
# Version: 1.0.1
#
# CHANGELOG:
# 1.0.1 - 2025-03-24 - Fix group creation logic
# 1.0.0 - 2025-03-24 - Initial version
#   - User creation with no password
#   - SSH key setup
#   - Account set to never expire
#   - Support for various Linux distributions (RHEL/CentOS/Oracle, Debian/Ubuntu)
#   - Logging

set -euo pipefail

VERSION="1.0.1"

# Default variables
LOG_FILE="/var/log/ansible_user_setup.log"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") --user USERNAME --key "SSH_PUBLIC_KEY"

Deploy Ansible connection user on Linux servers with SSH key authentication.

Options:
  -h, --help              Display this help message and exit
  -v, --version           Display script version
  -u, --user USERNAME     Specify the username to create (required)
  -k, --key "SSH_KEY"     SSH public key for authentication (required)
  -g, --group GROUP       Specify the primary group (default: same as username)
  -l, --log FILE          Log file location (default: /var/log/ansible_user_setup.log)
  -s, --shell SHELL       User shell (default: /bin/bash)
  -n, --no-sudo           Do not configure sudo access (default: with sudo)

Examples:
  $(basename "$0") --user ansible --key "ssh-rsa AAAAB3Nza..."
  $(basename "$0") --user automation --key "ssh-rsa AAAAB3Nza..." --group wheel
  $(basename "$0") --user ansible --key "ssh-rsa AAAAB3Nza..." --shell /bin/sh --no-sudo

EOF
    exit 0
}

# Function to display version
show_version() {
    echo "$(basename "$0") version $VERSION"
    exit 0
}

# Log function
log() {
    local message="$1"
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $message" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR: This script must be run as root"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION_ID=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        if grep -q "CentOS" /etc/redhat-release; then
            DISTRO="centos"
            VERSION_ID=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
        elif grep -q "Red Hat" /etc/redhat-release; then
            DISTRO="rhel"
            VERSION_ID=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
        elif grep -q "Oracle" /etc/redhat-release; then
            DISTRO="oracle"
            VERSION_ID=$(cat /etc/redhat-release | tr -dc '0-9.' | cut -d \. -f1)
        fi
    elif [[ -f /etc/debian_version ]]; then
        if [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
            DISTRO="ubuntu"
            VERSION_ID=$(cat /etc/debian_version)
        else
            DISTRO="debian"
            VERSION_ID=$(cat /etc/debian_version | cut -d '.' -f1)
        fi
    else
        DISTRO="unknown"
        VERSION_ID="unknown"
    fi
    
    log "Detected distribution: $DISTRO $VERSION_ID"
}

# Check if user exists
user_exists() {
    local username="$1"
    if id "$username" &>/dev/null; then
        return 0  # True, user exists
    else
        return 1  # False, user does not exist
    fi
}

# Create user account
create_user() {
    local username="$1"
    local group="$2"
    local shell="$3"
    
    # If user already exists, skip creation
    if user_exists "$username"; then
        log "User $username already exists"
    else
        # Create group if it doesn't exist (regardless of whether it matches username or not)
        if ! getent group "$group" &>/dev/null; then
            log "Creating group $group"
            groupadd "$group"
        fi
        
        # Create user based on distribution
        case $DISTRO in
            centos|rhel|oracle)
                if [[ "$VERSION_ID" -ge 7 ]]; then
                    useradd -m -g "$group" -s "$shell" -c "Ansible automation user" "$username"
                else
                    useradd -m -g "$group" -s "$shell" -c "Ansible automation user" "$username"
                fi
                ;;
            debian|ubuntu)
                useradd -m -g "$group" -s "$shell" -c "Ansible automation user" "$username"
                ;;
            *)
                # Generic approach for unknown distributions
                useradd -m -g "$group" -s "$shell" -c "Ansible automation user" "$username"
                ;;
        esac
        log "Created user $username"
    fi
    
    # Lock password for user (different commands for different distributions)
    case $DISTRO in
        centos|rhel|oracle)
            passwd -l "$username" &>/dev/null
            ;;
        debian|ubuntu)
            passwd -l "$username" &>/dev/null
            ;;
        *)
            passwd -l "$username" &>/dev/null
            ;;
    esac
    
    # Set account to never expire
    case $DISTRO in
        centos|rhel|oracle)
            if [[ "$VERSION_ID" -ge 7 ]]; then
                chage -E -1 -M 99999 "$username"
            else
                chage -I -1 -m 0 -M 99999 -E -1 "$username"
            fi
            ;;
        debian|ubuntu)
            chage -E -1 -M 99999 "$username"
            ;;
        *)
            chage -E -1 -M 99999 "$username"
            ;;
    esac
    log "Set account $username to never expire"
}

# Configure SSH key for user
setup_ssh_key() {
    local username="$1"
    local ssh_key="$2"
    local home_dir
    
    # Get home directory
    home_dir=$(eval echo ~"$username")
    
    # Create .ssh directory if it doesn't exist
    if [[ ! -d "$home_dir/.ssh" ]]; then
        mkdir -p "$home_dir/.ssh"
        chmod 700 "$home_dir/.ssh"
    fi
    
    # Add or update authorized_keys file
    local auth_keys="$home_dir/.ssh/authorized_keys"
    
    # Check if key already exists in authorized_keys
    if [[ -f "$auth_keys" ]] && grep -q -F "$ssh_key" "$auth_keys"; then
        log "SSH key already exists for user $username"
    else
        echo "$ssh_key" >> "$auth_keys"
        log "Added SSH key for user $username"
    fi
    
    # Set correct permissions
    chmod 600 "$auth_keys"
    chown -R "$username:$(id -gn "$username")" "$home_dir/.ssh"
}

# Configure sudo access if needed
configure_sudo() {
    local username="$1"
    local no_sudo="$2"
    
    if [[ "$no_sudo" == "true" ]]; then
        log "Skipping sudo configuration as requested"
        return
    fi
    
    # Check if sudo is installed
    if ! command -v sudo &>/dev/null; then
        log "WARNING: sudo is not installed, skipping sudo configuration"
        return
    fi
    
    # Create sudoers.d directory if it doesn't exist
    if [[ ! -d "/etc/sudoers.d" ]]; then
        mkdir -p /etc/sudoers.d
        chmod 750 /etc/sudoers.d
    fi
    
    # Create/update sudoers file for the user
    local sudoers_file="/etc/sudoers.d/$username"
    
    # Only create if it doesn't exist or doesn't have the right content
    if [[ ! -f "$sudoers_file" ]] || ! grep -q "$username ALL=(ALL) NOPASSWD: ALL" "$sudoers_file"; then
        echo "$username ALL=(ALL) NOPASSWD: ALL" > "$sudoers_file"
        chmod 440 "$sudoers_file"
        log "Configured sudo access for user $username"
    else
        log "Sudo access already configured for user $username"
    fi
}

# Main execution
main() {
    # Parse arguments
    USERNAME=""
    SSH_KEY=""
    GROUP=""
    SHELL="/bin/bash"
    NO_SUDO="false"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
                ;;
            -u|--user)
                USERNAME="$2"
                shift 2
                ;;
            -k|--key)
                SSH_KEY="$2"
                shift 2
                ;;
            -g|--group)
                GROUP="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -s|--shell)
                SHELL="$2"
                shift 2
                ;;
            -n|--no-sudo)
                NO_SUDO="true"
                shift
                ;;
            *)
                log "ERROR: Unknown parameter: $1"
                show_help
                ;;
        esac
    done
    
    # Validate required parameters
    if [[ -z "$USERNAME" ]]; then
        log "ERROR: Username is required"
        show_help
    fi
    
    if [[ -z "$SSH_KEY" ]]; then
        log "ERROR: SSH public key is required"
        show_help
    fi
    
    # Set group to username if not specified
    if [[ -z "$GROUP" ]]; then
        GROUP="$USERNAME"
    fi
    
    # Check if running as root
    check_root
    
    # Detect Linux distribution
    detect_distro
    
    log "Starting setup for Ansible user $USERNAME"
    
    # Create user
    create_user "$USERNAME" "$GROUP" "$SHELL"
    
    # Setup SSH key
    setup_ssh_key "$USERNAME" "$SSH_KEY"
    
    # Configure sudo
    configure_sudo "$USERNAME" "$NO_SUDO"
    
    log "Setup completed successfully for user $USERNAME"
}

# Execute main function
main "$@"