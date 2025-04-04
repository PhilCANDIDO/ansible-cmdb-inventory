#!/bin/bash
version='1.0'

### START FUNCTION ###
# Function USAGE
function usage() {
    echo -e "Version ${version}\nUsage: $0 -p <ansible_path> [-f -v]" 1>&2
    echo ""
    echo "Purpose :"
    echo " Initialize ansible directories"
    echo "Parameters"
    echo " -p Ansible path"
    echo " -f force re-initialize if directory already exist. If directory exist, it will deleted before creation."
    echo " -v verbose"
    echo ""
    echo "Examples :"
    echo "  - Launch ansible directories initialisation"
    echo -e "\tbash $0 -p /opt/ansible"
    echo ""
    echo ""
    exit 1
}

function get_oslinux() {
    OSLinux=$(cat /etc/os-release | grep -e '^ID=' | cut -f2 -d '=' | cut -f1 -d '.' | sed -e 's/^ //' -e 's/ $//' | sed "s/'//g" | sed 's/"//g')
    echo "${OSLinux}"
}

function get_osversion() {
    OSversion=$(cat /etc/os-release | grep 'VERSION_ID' | cut -f2 -d '=' | cut -f1 -d '.' | sed -e 's/^ //' -e 's/ $//' | sed "s/'//g" | sed 's/"//g')
    echo "${OSversion}"
}

function fct_wrlog() {
    filename=$(basename "$0")
    # Check if interactive mode
    if [ ! -z "$2" ]; then
        # Check if output colour
        if [ -z "$3" ]; then
            echo -e "$1"
        else
            # display with colour
            echo -e "$3$1${NC}"
        fi
    fi
    sudo echo -e "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >>$LOGFILE
}

function create_dir {
	#Directory Argument
	DIRECTORY=$1

	#Create mkdir command
        mkdir_cmd="$MKDIR -p $DIRECTORY"

    if [ ! -d "$DIRECTORY" ] ; then 
        mkdir -p $DIRECTORY
        if [ $? -eq 0 ]; then
                fct_wrlog " -> Directory $DIRECTORY created." "i" "${GREEN}"
        else 
                fct_wrlog " -> Directory $DIRECTORY cannot be created." "i" "${RED}"
        fi
        return
    fi

    if [ -z ${force} ] ; then
        fct_wrlog " -> Directory $DIRECTORY already exist." "i" "${GREEN}"
    else
        rm -Rf $DIRECTORY
        if [ $? -eq 0 ]; then
                fct_wrlog " -> Directory $DIRECTORY deleted." "i" "${purple}"
        else 
                fct_wrlog " -> Directory $DIRECTORY cannot be deleted." "i" "${RED}"
                return
        fi
        mkdir -p $DIRECTORY
         if [ $? -eq 0 ]; then
                fct_wrlog " -> Directory $DIRECTORY created." "i" "${purple}"
        else 
                fct_wrlog " -> Directory $DIRECTORY cannot be created." "i" "${RED}"
                return
        fi
    fi
    return
}


### CONSTANTS ######
# Load constant
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m'

### END FUNCTION ###

# Init server
# Global Variable
filename=$(basename "$0")
BASEDIR=$(dirname $0)
ABSPATH=$(readlink -f $0)
ABSDIR=$(dirname $ABSPATH)
LOGDIR="${ABSDIR}"
if [ -z ${LOGFILE} ]; then
    LOGFILE="${LOGDIR}/${filename%.*}.log"
fi
TEMPFOLDER="/tmp"

# Get variable
while getopts ":p:vf" o; do
    case "${o}" in
    p)
        ansible_path=${OPTARG}
        ;;
    f)
        force=true
        ;;
    v)
        verbose=true
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${ansible_path}" ]; then
    echo "Argument -p is missing."
    usage
    exit 1
fi

### Binary
MKDIR=`which mkdir`
TOUCH=`which touch`
RM=`which rm`

fct_wrlog "-- Ansible init --" "i" "${YELLOW}"

# Get OS Version
OSLinux=$(get_oslinux)
OSversion=$(get_osversion)
fct_wrlog "  OS Linux   : ${OSLinux}" "i" "${GREEN}"
fct_wrlog "  OS Version : ${OSversion}" "i" "${GREEN}"

# Create tree directory
# ansible_inventory="$ansible_path/inventory"
# fct_wrlog "Create directory $ansible_inventory" "i" "${GREEN}"
# create_dir $ansible_inventory

ansible_dir="$ansible_path/environments"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/environments/prod"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/environments/prod/group_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/environments/prod/host_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

if [ ! -f "$ansible_path/environments/prod/hosts" ] ; then
    $TOUCH "$ansible_path/environments/prod/hosts"
    fct_wrlog " -> File $ansible_path/environments/prod/hosts created" "i" "${GREEN}"
fi

ansible_dir="$ansible_path/environments/dev"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/environments/dev/group_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/environments/dev/host_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

if [ ! -f "$ansible_path/environments/dev/hosts" ] ; then
    $TOUCH "$ansible_path/environments/dev/hosts"
    fct_wrlog " -> File $ansible_path/environments/dev/hosts created" "i" "${GREEN}"
fi

ansible_dir="$ansible_path/group_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/host_vars"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/library"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/module_utils"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/filter_plugins"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir

ansible_dir="$ansible_path/roles"
fct_wrlog "Create directory $ansible_dir" "i" "${GREEN}"
create_dir $ansible_dir
