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
SCRIPT_SCRIPT_DIR="${SCRIPT_BASE_DIR}.script/"
SCRIPT_ACTION_DIR="${SCRIPT_SCRIPT_DIR}actions/"
SCRIPT_LANG_DIR="${SCRIPT_SCRIPT_DIR}languages/"
SCRIPT_TEMP_DIR="${SCRIPT_BASE_DIR}.temp/"

GAME_APPID=376030
GAME_DIR="${SCRIPT_BASE_DIR}game/"
GAME_EXECUTABLE="${GAME_DIR}ShooterGame/Binaries/Linux/ShooterGameServer"
GAME_VERSION_LATEST=0
GAME_VERSION_CURRENT=0

STEAM_CLEAR_CACHE=false
STEAM_UPDATE_BACKGROUND=true
STEAM_CMD_DIR="${SCRIPT_BASE_DIR}steamcmd/"
STEAM_APPS_DIR="${GAME_DIR}steamapps/"
STEAM_CHACHE_DIR="${HOME}/Steam/appcache"

# Some Colors
FG_RED='\e[31m'
FG_GREEN='\e[32m'
FG_YELLOW='\e[33m'
RESET_ALL='\e[0m'

# Some Strings
STR_YES="yes"
STR_NO="no"
STR_YES_OR_NO="Enter '${STR_YES}' or '${STR_NO}'"

STR_UPDATE_DISABLED="Automatic updating is disabled!"
STR_UPDATE_CHECKING="Search for updates ..."
STR_UPDATE_CHECK_FAILED="Search for updates failed!"
STR_UPDATE_UPTODATE="All files are up-to-date."
STR_UPDATE_FOUND="Update found! Install it now ..."
STR_UPDATE_FILE_FAILED="Updating the file '{0}' failed."
STR_UPDATE_MAINFILE="Main script has been updated. Restart script in {0} seconds ..."
STR_UPDATE_ERROR_CONTINUE="Error occurred during the update! Should be tried to continue? ${STR_YES}/${STR_NO}"
STR_UPDATE_SUCCESSFULL="Update completed successfully."

# Case Insensitive String Comparison
shopt -s nocasematch

# UpdateScript Function
function UpdateScript
{
    local CHECKSUMS_FILE="${SCRIPT_TEMP_DIR}checksums"

    if [[ $CHECK_FOR_UPDATES != true ]]; then
        echo -e "${FG_RED}${STR_UPDATE_DISABLED}${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}${STR_UPDATE_CHECKING}${RESET_ALL}"

    # Download Checksums
    local Checksums=$(curl -s "${SCRIPT_REPOSITORY_URL}checksums")
    if [[ $Checksums == "Not Found" ]]; then
        echo -e "${FG_RED}${STR_UPDATE_CHECK_FAILED}${RESET_ALL}"
        return
    fi
    echo "$Checksums" > $CHECKSUMS_FILE

    # Compare Checksums
    local CheckResult=$(md5sum -c $CHECKSUMS_FILE --quiet 2> /dev/null)
    if [[ $CheckResult == "" ]]; then
        echo -e "${FG_GREEN}${STR_UPDATE_UPTODATE}${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}${STR_UPDATE_FOUND}${RESET_ALL}"

    # Update Files
    local error=false
    local selfUpdated=false
    while IFS=':' read -ra LINE; do
        local FileContent=$(curl -s "${SCRIPT_REPOSITORY_URL}${LINE[0]}")
        if [[ $FileContent == "Not Found" ]]; then
            echo -e "${FG_RED}${STR_UPDATE_FILE_FAILED/'{0}'/${LINE[0]}}${RESET_ALL}"
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
        echo -e "${FG_YELLOW}${STR_UPDATE_MAINFILE/'{0}'/5}${RESET_ALL}"
        sleep 5s
        $0 $1
        exit 0
    fi

    # Error while updating
    if [[ $error == true ]]; then
        echo -e "${FG_YELLOW}${STR_UPDATE_ERROR_CONTINUE}${RESET_ALL}"
        while [[ $input != $STR_YES ]]; do
            read input
            if [[ $input == $STR_NO ]]; then
                exit 0
            elif [[ $input != $STR_YES ]]; then
                echo -e "${FG_YELLOW}${STR_YES_OR_NO}${RESET_ALL}"
            fi
        done
    else
        echo -e "${FG_GREEN}${STR_UPDATE_SUCCESSFULL}${RESET_ALL}"
    fi
}

# CheckBoolean Function
# Param1 - Value to check
# Param2 - Default, if value is invalid
function CheckBoolean
{
    local bool=$1
    local default=$2

    if [[ $bool == true ]] || [[ $bool == false ]]; then
        # Is valid Boolean
        echo ${bool,,}
    else
        # Is invalid Boolean
        echo ${default,,}
    fi
}

# ScriptConfiguration Function
function ScriptConfiguration
{
    local CONFIG_FILE="configuration.ini"
    local CONFIG_SAMPLE_FILE="configuration-sample.ini"

    if [ ! -f $CONFIG_SAMPLE_FILE ]; then
        curl -s "${SCRIPT_REPOSITORY_URL}${CONFIG_SAMPLE_FILE}" -o $CONFIG_SAMPLE_FILE
    fi
    source $CONFIG_SAMPLE_FILE

    if [ ! -f $CONFIG_FILE ]; then
        cp $CONFIG_SAMPLE_FILE $CONFIG_FILE
    fi
    source $CONFIG_FILE

    if [ ! -z $ScriptBranch ]; then
        SCRIPT_REPOSITORY_BRANCH=$ScriptBranch
    fi
    CHECK_FOR_UPDATES=$(CheckBoolean $ScriptUpdates true)
}

# ScriptLanguage Function
# Param1 - Missing Language is Error, 0/1
function ScriptLanguage
{
    if [ -z $ScriptLanguage ]; then
        return
    fi

    local LANGUAGE_FILE="${SCRIPT_LANG_DIR}${ScriptLanguage}.lang"
    if [ -f $LANGUAGE_FILE ]; then
        source $LANGUAGE_FILE
    elif [ $1 -eq 1 ]; then
        # String in language file not required
        echo -e "${FG_RED}Language '${ScriptLanguage}' not found. Script execution is canceled.${RESET_ALL}"
        exit 0
    fi
}

# LoadScripts Function
function LoadScripts
{
    for file in $SCRIPT_SCRIPT_DIR*; do
        if [ -f $file ]; then
            source $file
        fi
    done
}

# InitScript Function
function InitScript
{
    clear

    if [ ! -d $SCRIPT_TEMP_DIR ]; then
        mkdir -p $SCRIPT_TEMP_DIR
    fi

    # Load Configuration and Language
    ScriptConfiguration
    ScriptLanguage 0

    # Update Script
    UpdateScript
    # Reload Configuration and Language
    ScriptConfiguration
    ScriptLanguage 1

    # Load all Scripts
    LoadScripts
}

# RunAction Function
# Param1 - Name of the Action
function RunAction
{
    local name=$1
    if [ -z $name ]; then
        return
    fi

    local ACTION_FILE="${SCRIPT_ACTION_DIR}${name}.sh"
    if [ -f $ACTION_FILE ]; then
        source $ACTION_FILE
    else
        echo -e "${FG_RED}${STR_ACTION_UNKNOWN/'{0}'/$name}${RESET_ALL}"
    fi
}

# CleanUp Function
function CleanUp
{
    rm -r -f $SCRIPT_TEMP_DIR
}

# Run Main Functions
InitScript
RunAction $1
CleanUp

exit 0
