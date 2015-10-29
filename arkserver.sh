#!/bin/bash

# Script Github Repository
SCRIPT_REPOSITORY_USER="ComputerBaer"
SCRIPT_REPOSITORY_NAME="ARK-Linux-Server-Script-v2"
SCRIPT_REPOSITORY_BRANCH="master"
SCRIPT_REPOSITORY_URL="https://raw.githubusercontent.com/${SCRIPT_REPOSITORY_USER}/${SCRIPT_REPOSITORY_NAME}/${SCRIPT_REPOSITORY_BRANCH}/"

# Other Settings
CHECK_FOR_UPDATES=true

SCRIPT_FILE_NAME=$(basename $(readlink -fn $0))
SCRIPT_BASE_DIR=$(dirname $(readlink -fn $0))/
SCRIPT_TEMP_DIR="${SCRIPT_BASE_DIR}.temp/"

# Some Colors
FG_RED='\e[31m'
FG_GREEN='\e[32m'
FG_YELLOW='\e[33m'
RESET_ALL='\e[0m'

# Case Insensitive String Comparison
shopt -s nocasematch

# UpdateScript Function
function UpdateScript
{
    local CHECKSUMS_FILE="${SCRIPT_TEMP_DIR}checksums"

    if [[ $CHECK_FOR_UPDATES != true ]]; then
        echo -e "${FG_RED}Update check disabled!${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}Checking for updates ...${RESET_ALL}"

    # Download Checksums
    local Checksums=$(curl -s "${SCRIPT_REPOSITORY_URL}checksums")
    if [[ $Checksums == "Not Found" ]]; then
        echo -e "${FG_RED}Update check failed! (Can not download checksums)${RESET_ALL}"
        return
    fi
    echo "$Checksums" > $CHECKSUMS_FILE

    # Compare Checksums
    local CheckResult=$(md5sum -c $CHECKSUMS_FILE --quiet 2> /dev/null)
    if [[ $CheckResult == "" ]]; then
        echo -e "${FG_GREEN}All files are up to date!${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}Update found! Installing it now ...${RESET_ALL}"

    # Update Files
    local error=false
    local selfUpdated=false
    while IFS=':' read -ra LINE; do
        local FileContent=$(curl -s "${SCRIPT_REPOSITORY_URL}${LINE[0]}")
        if [[ $FileContent == "Not Found" ]]; then
            echo -e "${FG_RED}Update '${LINE[0]}' failed! (Can not download file)${RESET_ALL}"
            error=true
        else
            local dir=$(dirname "${LINE[0]}")
            if [ ! -d $dir ]; then
                mkdir -p $dir
            fi
            echo "$FileContent" > "${LINE[0]}"

            if [[ $(basename ${LINE[0]}) == $SCRIPT_FILE_NAME ]]; then
                selfUpdated=true
            fi
        fi
    done <<< "$CheckResult"

    # Main Script was updated
    if [[ $selfUpdated == true ]]; then
        echo -e "${FG_YELLOW}Main Script was updated! Restarting script in 5 Seconds ...${RESET_ALL}"
        sleep 5s
        $0 $1
        exit 0
    fi

    # Error while updating
    if [[ $error == true ]]; then
        echo -e "${FG_YELLOW}Error while updating! Try to continue? yes/no ${RESET_ALL}"
        while [[ $input != "yes" ]]; do
            read input
            if [[ $input == "no" ]]; then
                exit 0
            elif [[ $input != "yes" ]]; then
                echo -e "${FG_YELLOW}Type 'yes' or 'no'${RESET_ALL}"
            fi
        done
    else
        echo -e "${FG_GREEN}Update completed successfully!${RESET_ALL}"
    fi
}

# ScriptConfiguration Function
function ScriptConfiguration
{
    local CONFIG_FILE="configuration.ini"
    local CONFIG_SAMPLE_FILE="configuration-sample.ini"

    if [ ! -f $CONFIG_FILE ]; then
        curl -s "${SCRIPT_REPOSITORY_URL}${CONFIG_SAMPLE_FILE}" -o $CONFIG_FILE
    fi
    source $CONFIG_FILE

    if [ ! -z $ScriptBranch ]; then
        SCRIPT_REPOSITORY_BRANCH=$ScriptBranch
    fi
    if [ ! -z $ScriptUpdates ]; then
        CHECK_FOR_UPDATES=$ScriptUpdates
    fi
}

# Main Function
function Main
{
    if [ ! -d $SCRIPT_TEMP_DIR ]; then
        mkdir -p $SCRIPT_TEMP_DIR
    fi

    ScriptConfiguration
    UpdateScript
}

# Run Main Function
Main
exit 0
