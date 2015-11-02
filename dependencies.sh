#!/bin/bash

#
# If you want, you can do all steps manually.
#
# Install "lib32gcc1" (Steam Dependency)
#    apt-get install lib32gcc1
#
# Add Line to "/etc/sysctl.conf"
#    fs.file-max=100000
# Run Command
#    sysctl -p /etc/sysctl.conf
#
# Add Lines to "/etc/security/limits.conf"
#    *               soft    nofile          100000
#    *               hard    nofile          100000
#    root            soft    nofile          100000
#    root            hard    nofile          100000
# You can make these changes only to your ARK-user. If you know what you're doing.
#
# Add Line to "/etc/pam.d/common-session"
#    session required pam_limits.so
#
# You have to start a new terminal session, please log out.
#

# Some Colors
FG_RED='\e[31m'
FG_YELLOW='\e[33m'
FG_CYAN='\e[36m'
RESET_ALL='\e[0m'

# Warning
if [ -z $1 ] || [[ $1 != "run" ]]; then
    echo -e "${FG_YELLOW}This script may cause damage the system. Are you really sure that you want to do it? Execute the script with the following command:${RESET_ALL}"
    echo -e "${FG_CYAN}    sudo ${0} run${RESET_ALL}"
    exit 0
fi

# Is root user
USER=$(whoami)
if [[ $USER != "root" ]]; then
    echo -e "${FG_RED}This script requires root permissions. Execute the script with the following command:${RESET_ALL}"
    echo -e "${FG_CYAN}    sudo ${0} ${1}${RESET_ALL}"
    exit 0
fi

# Steam Dependency
apt-get install lib32gcc1

# File Limit
REQUIRED_LIMIT=100000
CURRENT_LIMIT=$(ulimit -n)

if [ $CURRENT_LIMIT -lt $REQUIRED_LIMIT ]; then
    FILE="/etc/sysctl.conf"
    echo "" >> $FILE
    echo "# ARK - Linux Server Script v2" >> $FILE
    echo "fs.file-max=${REQUIRED_LIMIT}" >> $FILE
    sysctl -p /etc/sysctl.conf > /dev/null

    FILE="/etc/security/limits.conf"
    echo "" >> $FILE
    echo "# ARK - Linux Server Script v2" >> $FILE
    echo "*               soft    nofile          ${REQUIRED_LIMIT}" >> $FILE
    echo "*               hard    nofile          ${REQUIRED_LIMIT}" >> $FILE
    echo "root            soft    nofile          ${REQUIRED_LIMIT}" >> $FILE
    echo "root            hard    nofile          ${REQUIRED_LIMIT}" >> $FILE

    FILE="/etc/pam.d/common-session"
    echo "" >> $FILE
    echo "# ARK - Linux Server Script v2" >> $FILE
    echo "session required pam_limits.so" >> $FILE
fi

echo -e "${FG_RED}You have to start a new terminal session, please log out.${RESET_ALL}"
