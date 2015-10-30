#!/bin/bash

# WaitForBackgroundProcess Function
# Param1 - ProcessID to wait on
# Param2 - Color of the dots (Optional)
function WaitForBackgroundProcess
{
    local PROCESS_ID=$1
    if [ -z $PROCESS_ID ]; then
        return
    fi

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

# SteamAppLatestVersion Function
function SteamAppLatestVersion
{
    local VERSION_FILE="${SCRIPT_TEMP_DIR}appversion"

    if [ $GAME_VERSION_LATEST -gt 0 ]; then
        echo -e "${FG_YELLOW}${STR_STEAM_VERSION_LATEST_DONE/'{0}'/$GAME_VERSION_LATEST}${RESET_ALL}"
        return
    fi

    if [ ! -d $STEAM_CMD_DIR ]; then
        InstallSteam
    fi

    if [[ $STEAM_CLEAR_CACHE == true ]]; then
        rm -r -f $STEAM_CHACHE_DIR
        echo -e "${FG_YELLOW}${STR_STEAM_CACHE_CLEARED}${RESET_ALL}"
    fi

    cd $STEAM_CMD_DIR
    echo -ne "${FG_YELLOW}${STR_STEAM_VERSION_LATEST_START}${RESET_ALL}"
    ./steamcmd.sh +login anonymous +app_info_print $GAME_APPID +quit | ParseSteamAcf "${GAME_APPID}.depots.branches.public.buildid" > $VERSION_FILE &
    WaitForBackgroundProcess $! $FG_YELLOW
    cd $SCRIPT_BASE_DIR

    GAME_VERSION_LATEST=$(cat $VERSION_FILE)
    echo -e "${FG_YELLOW}${STR_STEAM_VERSION_LATEST_DONE/'{0}'/$GAME_VERSION_LATEST}${RESET_ALL}"
}

# SteamAppCurrentVersion Function
function SteamAppCurrentVersion
{
    local APP_FILE="${STEAM_APPS_DIR}appmanifest_${GAME_APPID}.acf"
    if [ ! -f $APP_FILE ]; then
        return
    fi

    GAME_VERSION_CURRENT=$(cat $APP_FILE | ParseSteamAcf "AppState.buildid")
    echo -e "${FG_YELLOW}${STR_STEAM_VERSION_CURRENT_DONE/'{0}'/$GAME_VERSION_CURRENT}${RESET_ALL}"
}

# UpdateSteamApp Function
function UpdateSteamApp
{
    SteamAppLatestVersion
    SteamAppCurrentVersion

    if [ $GAME_VERSION_LATEST -eq $GAME_VERSION_CURRENT ]; then
        return
    fi

    cd $STEAM_CMD_DIR

    echo -ne "${FG_YELLOW}${STR_STEAM_UPDATE_START}${RESET_ALL}"
    ./steamcmd.sh +login anonymous +force_install_dir $GAME_DIR +app_update $GAME_APPID validate +quit > /dev/null &
    WaitForBackgroundProcess $! $FG_YELLOW

    cd $SCRIPT_BASE_DIR
    echo -e "${FG_YELLOW}${STR_STEAM_UPDATE_DONE}${RESET_ALL}"

    SteamAppCurrentVersion
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
