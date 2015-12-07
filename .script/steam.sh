#!/bin/bash

ACF_KEY_NOT_FOUND="NOT FOUND! ERROR?"

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
        echo -e "${FG_YELLOW}${STR_GAME_VERSION_LATEST_DONE/'{0}'/$GAME_VERSION_LATEST}${RESET_ALL}"
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
    echo -ne "${FG_YELLOW}${STR_GAME_VERSION_LATEST_START}${RESET_ALL}"
    ./steamcmd.sh +login anonymous +app_info_print $GAME_APPID +quit | ParseSteamAcf "${GAME_APPID}.depots.branches.public.buildid" > $VERSION_FILE &
    WaitForBackgroundProcess $! $FG_YELLOW
    cd $SCRIPT_BASE_DIR

    GAME_VERSION_LATEST=$(cat $VERSION_FILE)
    echo -e "${FG_YELLOW}${STR_GAME_VERSION_LATEST_DONE/'{0}'/$GAME_VERSION_LATEST}${RESET_ALL}"

    if [[ $GAME_VERSION_LATEST == $ACF_KEY_NOT_FOUND ]]; then
        ExitScript
    fi
}

# SteamAppCurrentVersion Function
function SteamAppCurrentVersion
{
    local APP_FILE="${STEAM_APPS_DIR}appmanifest_${GAME_APPID}.acf"
    if [ ! -f $APP_FILE ]; then
        return
    fi

    GAME_VERSION_CURRENT=$(cat $APP_FILE | ParseSteamAcf "AppState.buildid")
    echo -e "${FG_YELLOW}${STR_GAME_VERSION_CURRENT/'{0}'/$GAME_VERSION_CURRENT}${RESET_ALL}"

    if [[ $GAME_VERSION_CURRENT == $ACF_KEY_NOT_FOUND ]]; then
        ExitScript
    fi
}

# UpdateSteamApp Function
function UpdateSteamApp
{
    local CHECK_VERSION=true
    if [ ! -z $1 ]; then
        CHECK_VERSION=$1
    fi

    if [[ $CHECK_VERSION == true ]]; then
        SteamAppLatestVersion
        SteamAppCurrentVersion

        if [ $GAME_VERSION_LATEST -eq $GAME_VERSION_CURRENT ]; then
            echo -e "${FG_YELLOW}${STR_GAME_VERSION_UPTODATE}${RESET_ALL}"
            return
        fi
    fi

    cd $STEAM_CMD_DIR

    echo -ne "${FG_YELLOW}${STR_GAME_UPDATE_START}${RESET_ALL}"
    if [[ $STEAM_UPDATE_BACKGROUND == true ]]; then
        ./steamcmd.sh +login anonymous +force_install_dir $GAME_DIR +app_update $GAME_APPID validate +quit > /dev/null &
        WaitForBackgroundProcess $! $FG_YELLOW
    else
        echo # Line break
        ./steamcmd.sh +login anonymous +force_install_dir $GAME_DIR +app_update $GAME_APPID validate +quit
    fi

    cd $SCRIPT_BASE_DIR
    echo -e "${FG_YELLOW}${STR_GAME_UPDATE_DONE}${RESET_ALL}"

    SteamAppCurrentVersion
}

# UpdateSteamWorkshop Function
function UpdateSteamWorkshop
{
    if [ -z $GameModIds ]; then
        return
    fi

    local workshop=""
    local dldir="${STEAM_WORKSHOP_DIR}downloads/${GAME_WORKSHOP_APPID}"

    IFS=',' read -ra modIds <<< $GameModIds
    for modId in ${modIds[@]}; do
        modId=$(CheckInteger $modId 0)
        if [ $modId -gt 0 ]; then
            workshop="${workshop} +workshop_download_item ${GAME_WORKSHOP_APPID} ${modId}"
        fi
    done

    if [[ -z $workshop ]]; then
        return
    fi

    rm -r -f $dldir

    cd $STEAM_CMD_DIR

    echo -ne "${FG_YELLOW}${STR_WORKSHOP_UPDATE_START}${RESET_ALL}"
    while true; do # Steam Workshop Update Timeout
        if [[ $STEAM_UPDATE_BACKGROUND == true ]]; then
            ./steamcmd.sh +login anonymous $workshop +quit > /dev/null &
            WaitForBackgroundProcess $! $FG_YELLOW
        else
            echo # Line break
            ./steamcmd.sh +login anonymous $workshop +quit
            echo # Line break
        fi

        if [ ! -d $dldir ]; then
            break;
        fi
        echo -ne "${COLOR}*${RESET_ALL}"
    done

    cd $SCRIPT_BASE_DIR

    UpdateGameWorkshop

    echo -e "${FG_YELLOW}${STR_WORKSHOP_UPDATE_DONE}${RESET_ALL}"

    return
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

    echo $ACF_KEY_NOT_FOUND
}
