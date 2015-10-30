#!/bin/bash

# WaitForBackgroundProcess Function
# Param1 - ProcessID to wait on
# Param2 - Color of the dots (Optional)
function WaitForBackgroundProcess
{
    local PROCESS_ID=$1

    local COLOR=$FG_WHITE
    if [ ! -z $2 ]; then
        COLOR=$2
    fi

    while true; do
        if kill -0 $PROCESS_ID 2>/dev/null; then
            echo -ne "${COLOR}.${RESET_ALL}"
        else
            break
        fi
        sleep 0.5s
    done

    echo # Line break
}

# InstallSteam Function
function InstallSteam
{
    local STEAMCMD_FILE="${SCRIPT_TEMP_DIR}steamcmd_linux.tar.gz"

    if [ -d $STEAM_CMD_DIR ]; then
        return
    fi
    echo -e "${FG_YELLOW}${STR_STEAM_INSTALL}${RESET_ALL}"

    echo -ne "${FG_YELLOW}${STR_STEAM_DOWNLOAD}${RESET_ALL}"
    curl -s https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o $STEAMCMD_FILE &
    WaitForBackgroundProcess $! $FG_YELLOW

    mkdir -p $STEAM_CMD_DIR
    cd $STEAM_CMD_DIR

    echo -ne "${FG_YELLOW}${STR_STEAM_EXTRACT}${RESET_ALL}"
    tar -xzf $STEAMCMD_FILE &
    WaitForBackgroundProcess $! $FG_YELLOW

    cd $SCRIPT_BASE_DIR
    echo -e "${FG_GREEN}${STR_STEAM_SUCCESSFULL}${RESET_ALL}"
}

# ParseSteamAcf Function
function ParseSteamAcf
{
    local path=$1
    if [ -z $path ]; then
        return
    fi

    local splitPos=`expr index "$path" .`
    local newPath=""
    local searchName="\"$path\""
    if [ $splitPos -gt 0 ]; then
        newPath=${path:$splitPos}
        searchName=${path:0:$splitPos-1}
        searchName="\"$searchName\""
    fi

    local count=0
    while read name val; do
        if [ -z $name ]; then
            continue
        fi

        if [ $name == $searchName ] && [ $count -lt 2 ]; then
            if [ -z $newPath ]; then
                local length=${#val}
                echo ${val:1:$length-2}
            else
                ParseSteamAcf $newPath
            fi
            return
        elif [ $name == "{" ]; then
            count=$((count+1))
        elif [ $name == "}" ]; then
            count=$((count-1))
            if [ $count -eq 0 ]; then
                break
            fi
        fi
    done

    echo "NOT FOUND! ERROR?"
}
