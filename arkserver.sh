#!/bin/bash

if [ -z $0 ]; then
    CMD=$BASH_SOURCE
else
    CMD=$0
fi

# ReadLink Function
function ReadLink
{
    local target_file=$1

    cd `dirname $target_file`
    target_file=`basename $target_file`

    while [ -L "$target_file" ]; do
        target_file=`readlink $target_file`
        cd `dirname $target_file`
        target_file=`basename $target_file`
    done

    echo `pwd -P`/$target_file
}

# Script Github Repository
SCRIPT_REPOSITORY_USER="ComputerBaer"
SCRIPT_REPOSITORY_NAME="ARK-Linux-Server-Script-v2"
SCRIPT_REPOSITORY_BRANCH="master"
SCRIPT_REPOSITORY_URL="https://raw.githubusercontent.com/${SCRIPT_REPOSITORY_USER}/${SCRIPT_REPOSITORY_NAME}/${SCRIPT_REPOSITORY_BRANCH}/"

# Other Settings
SCRIPT_COLOR=true
SCRIPT_UPDATES=true
SCRIPT_LANGUAGE="en"

SCRIPT_FILE_NAME=$(basename $(ReadLink $CMD))
SCRIPT_BASE_DIR=$(dirname $(ReadLink $CMD))/
SCRIPT_SCRIPT_DIR="${SCRIPT_BASE_DIR}.script/"
SCRIPT_ACTION_DIR="${SCRIPT_SCRIPT_DIR}actions/"
SCRIPT_LANG_DIR="${SCRIPT_SCRIPT_DIR}languages/"
SCRIPT_TEMP_DIR="${SCRIPT_BASE_DIR}.temp/"
SCRIPT_BACKUP_DIR="${SCRIPT_BASE_DIR}backups/"
SCRIPT_CONFIG="${SCRIPT_BASE_DIR}configuration.ini"
SCRIPT_CONFIG_SAMPLE="${SCRIPT_BASE_DIR}.script/config-samples/configuration-sample.ini"
SCRIPT_PARAMETER=$*

GAME_APPID=376030
GAME_DIR="${SCRIPT_BASE_DIR}game/"
GAME_EXECUTABLE="${GAME_DIR}ShooterGame/Binaries/Linux/ShooterGameServer"
GAME_SAVED_DIR="${GAME_DIR}ShooterGame/Saved/"
GAME_CONFIG1="${GAME_DIR}ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
GAME_CONFIG1_EDIT="${SCRIPT_BASE_DIR}GameUserSettings.ini"
GAME_CONFIG1_SAMPLE="${SCRIPT_BASE_DIR}.script/config-samples/GameUserSettings-sample.ini"
GAME_CONFIG2="${GAME_DIR}ShooterGame/Saved/Config/LinuxServer/Game.ini"
GAME_CONFIG2_EDIT="${SCRIPT_BASE_DIR}Game.ini"
GAME_VERSION_LATEST=0
GAME_VERSION_CURRENT=0
GAME_STOP_WAIT=7

STEAM_CLEAR_CACHE=true
STEAM_UPDATE_BACKGROUND=true
STEAM_CMD_DIR="${SCRIPT_BASE_DIR}steamcmd/"
STEAM_APPS_DIR="${GAME_DIR}steamapps/"
STEAM_CHACHE_DIR="${HOME}/Steam/appcache"

# Some Strings
STR_YES="yes"
STR_NO="no"
STR_YES_OR_NO="Enter '${STR_YES}' or '${STR_NO}'"

STR_DEPENDENCIES_MISSING="You must install '{0}' to run this script!"
STR_DEPENDENCIES_INSTALL="Install missing dependencies? ${STR_YES}/${STR_NO}"

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

# CheckScriptDependencies Function
function CheckScriptDependencies
{
    # Check Dependencies
    local dependencies=""
    if [[ $(IsInstalled curl) == false ]]; then
        dependencies="${dependencies} curl"
    fi
    if [[ $(IsInstalled screen) == false ]]; then
        dependencies="${dependencies} screen"
    fi

    # Missing Dependencies found?
    if [[ -z $dependencies ]]; then
        return
    fi
    echo -e "${FG_RED}${STR_DEPENDENCIES_MISSING/'{0}'/${dependencies:1}}${RESET_ALL}"

    # Is root user
    if [[ $(whoami) == "root" ]]; then
        # Install missing Dependencies?
        echo -e "${FG_YELLOW}${STR_DEPENDENCIES_INSTALL}${RESET_ALL}"
        if [[ $(DialogYesNo) == true ]]; then
            echo # Line break
            apt-get install $dependencies
            echo # Line break
            return
        fi
    fi

    ExitScript
}

# IsInstalled Function
function IsInstalled
{
    if hash $1 2>/dev/null; then
        echo true
    else
        echo false
    fi
}

# DialogYesNo Function
function DialogYesNo
{
    while [[ $input != $STR_YES ]]; do
        #read -p "$STR_YES / $STR_NO : " input
        read -p "${STR_YES_OR_NO}: " input
        if [[ $input == $STR_NO ]]; then
            echo false
            return
        elif [[ $input == $STR_YES ]]; then
            echo true
            return
        fi
    done
}

# UpdateScript Function
function UpdateScript
{
    local CHECKSUMS_FILE="${SCRIPT_TEMP_DIR}checksums"

    if [[ $SCRIPT_UPDATES != true ]]; then
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
    local CheckOutput=$(md5sum -c $CHECKSUMS_FILE 2> /dev/null)
    local CheckResult=""
    while IFS=':' read -ra LINE; do
        if [[ ${LINE[1]} != " OK" ]]; then
            CheckResult="${CheckResult}${LINE[0]}\n"
        fi
    done <<< "$CheckOutput"

    if [[ $CheckResult == "" ]]; then
        echo -e "${FG_GREEN}${STR_UPDATE_UPTODATE}${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}${STR_UPDATE_FOUND}${RESET_ALL}"

    # Update Files
    local error=false
    local selfUpdated=false
    while read -ra LINE; do
        local FileContent=$(curl -s "${SCRIPT_REPOSITORY_URL}${LINE[0]}")
        if [[ $FileContent == "Not Found" ]]; then
            echo -e "${FG_RED}${STR_UPDATE_FILE_FAILED/'{0}'/${LINE[0]}}${RESET_ALL}"
            error=true
        else
            local dir=$(dirname "${LINE[0]}")
            local file=$(basename "${LINE[0]}")
            if [ ! -d $dir ]; then
                mkdir -p $dir
            fi
            echo "$FileContent" > "${LINE[0]}"

            if [[ $dir == "." ]] && [[ ${file##*.} == "sh" ]]; then
                chmod +x "${LINE[0]}"
            fi

            if [[ $file == $SCRIPT_FILE_NAME ]]; then
                selfUpdated=true
            fi
        fi
    done <<< "$(echo -e $CheckResult)"

    # Main Script was updated
    if [[ $selfUpdated == true ]]; then
        echo -e "${FG_YELLOW}${STR_UPDATE_MAINFILE/'{0}'/5}${RESET_ALL}"
        sleep 5s
        $CMD $SCRIPT_PARAMETER
        exit 0
    fi

    # Error while updating
    if [[ $error == true ]]; then
        echo -e "${FG_YELLOW}${STR_UPDATE_ERROR_CONTINUE}${RESET_ALL}"
        if [[ $(DialogYesNo) == false ]]; then
            ExitScript
        fi
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
    if [ ! -f $SCRIPT_CONFIG_SAMPLE ]; then
        return
    fi
    source $SCRIPT_CONFIG_SAMPLE

    if [ ! -f $SCRIPT_CONFIG ]; then
        local CONFIG_DIR=$(dirname $SCRIPT_CONFIG)

        if [ ! -d $CONFIG_DIR ]; then
            mkdir -p $CONFIG_DIR
        fi

        cp $SCRIPT_CONFIG_SAMPLE $SCRIPT_CONFIG
    fi
    source $SCRIPT_CONFIG

    # Load Script Settings
    if [ ! -z $ScriptBranch ]; then
        SCRIPT_REPOSITORY_BRANCH=$ScriptBranch
    fi
    SCRIPT_UPDATES=$(CheckBoolean $ScriptUpdates true)
    if [ ! -z $ScriptLanguage ]; then
        SCRIPT_LANGUAGE=$ScriptLanguage
    fi
}

# ScriptColor Function
function ScriptColor
{
    if [[ $SCRIPT_COLOR == true ]]; then
        # Some Colors
        FG_RED='\e[31m'
        FG_GREEN='\e[32m'
        FG_YELLOW='\e[33m'
        RESET_ALL='\e[0m'
    else
        # Some Colors
        FG_RED=''
        FG_GREEN=''
        FG_YELLOW=''
        RESET_ALL=''
    fi
}

# ScriptLanguage Function
# Param1 - Missing Language is Error, 0/1
function ScriptLanguage
{
    local LANGUAGE_FILE="${SCRIPT_LANG_DIR}${SCRIPT_LANGUAGE}.lang"
    if [ -f $LANGUAGE_FILE ]; then
        source $LANGUAGE_FILE
    elif [ $1 -eq 1 ]; then
        # String in language file not required
        echo -e "${FG_RED}Language '${SCRIPT_LANGUAGE}' not found. Script execution is canceled.${RESET_ALL}"
        ExitScript
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
    ScriptColor
    ScriptLanguage 0

    # Check Script Dependencies
    CheckScriptDependencies
    # Update Script
    UpdateScript

    # Reload Configuration and Language
    ScriptConfiguration
    ScriptColor
    ScriptLanguage 1

    # Is root user
    if [[ $(whoami) == "root" ]]; then
        echo -e "${FG_RED}${STR_ROOT}${RESET_ALL}"
    fi

    # Load all Scripts
    LoadScripts

    # Generate Game Configuration (.script/game.sh)
    CheckGameConfig
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

# ExitScript Function
function ExitScript
{
    CleanUp
    exit 0
}

# Run Main Functions
InitScript
RunAction $1
ExitScript
