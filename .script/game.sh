#!/bin/bash

GAME_IS_RUNNING=false
GAME_EXECUTABLE_INSTANCE="${GAME_EXECUTABLE}.${InstanceName}"

# StartGame Function
function StartGame
{
    # Check Dependencies
    local REQUIRED_LIMIT=100000
    local CURRENT_LIMIT=$(ulimit -n)
    if [ $CURRENT_LIMIT -lt $REQUIRED_LIMIT ]; then
        echo -e "${FG_RED}${STR_EXEC_DEPENDENCIES}${RESET_ALL}"
        CleanUp
        exit 0
    fi

    # Check Server Status
    GameStatus
    if [[ $GAME_IS_RUNNING == true ]]; then
        echo -e "${FG_RED}${STR_GAME_ALREADY_RUNNING}${RESET_ALL}"
        ExitScript
    fi
    echo -e "${FG_YELLOW}${STR_GAME_START}${RESET_ALL}"

    # Update Game Config and prepare Server Start
    UpdateGameConfig

    local EXEC_DIR=$(dirname $GAME_EXECUTABLE_INSTANCE)
    local EXEC_NAME=$(basename $GAME_EXECUTABLE_INSTANCE)

    cp $GAME_EXECUTABLE $GAME_EXECUTABLE_INSTANCE

    # Check Params
    if [ -z $MapName ]; then
        MapName="TheIsland"
    fi
    GamePort=$(CheckInteger $GamePort 7777)
    QueryPort=$(CheckInteger $QueryPort 27015)
    RconPort=$(CheckInteger $RconPort 32330)
    RconEnabled=$(CheckBoolean $RconEnabled false)

    local params="${MapName}?listen"
    params="${params}?Port=${GamePort}"
    params="${params}?QueryPort=${QueryPort}"
    params="${params}?RCONEnabled=${RconEnabled}"
    params="${params}?RCONPort=${RconPort}"

    # Start Server
    cd $EXEC_DIR
    screen -A -m -d -S $InstanceName "./${EXEC_NAME}" "${params} -server -log"
    cd $SCRIPT_BASE_DIR
}

# StopGame Function
function StopGame
{
    GameStatus
    if [[ $GAME_IS_RUNNING == true ]]; then
        screen -S $InstanceName -X quit > /dev/null

        sleep $GAME_STOP_WAIT &
        WaitForBackgroundProcess $! $FG_YELLOW

        local EXEC_NAME=$(basename $GAME_EXECUTABLE_INSTANCE)
        local PROCESS_IDS=$(pgrep -f $EXEC_NAME)

        if [[ ! -z $PROCESS_IDS ]]; then
            kill -9 $(pgrep -f $EXEC_NAME)
        fi
    fi

    echo -e "${FG_YELLOW}${STR_GAME_STOPPED}${RESET_ALL}"
}

# GameStatus Function
function GameStatus
{
    if screen -list | grep -q $InstanceName; then
        GAME_IS_RUNNING=true
    else
        local EXEC_NAME=$(basename $GAME_EXECUTABLE_INSTANCE)
        local PROCESS_IDS=$(pgrep -f $EXEC_NAME)

        if [[ ! -z $PROCESS_IDS ]]; then
            GAME_IS_RUNNING=true
        fi

        GAME_IS_RUNNING=false
    fi
}

# CheckGameConfig Function
function CheckGameConfig
{
    # GameUserSettings.ini
    if [ ! -f $GAME_CONFIG1_EDIT ]; then
        local CONFIG1_EDIT_DIR=$(dirname $GAME_CONFIG1_EDIT)

        if [ ! -d $CONFIG1_EDIT_DIR ]; then
            mkdir -p $CONFIG1_EDIT_DIR
        fi

        cp $GAME_CONFIG1_SAMPLE $GAME_CONFIG1_EDIT
    fi

    #Game.ini
    if [ ! -f $GAME_CONFIG2_EDIT ]; then
        local CONFIG2_EDIT_DIR=$(dirname $GAME_CONFIG2_EDIT)

        if [ ! -d $CONFIG2_EDIT_DIR ]; then
            mkdir -p $CONFIG2_EDIT_DIR
        fi

        echo "; You can edit this file" > $GAME_CONFIG2_EDIT
        echo "" >> $GAME_CONFIG2_EDIT
    fi
}

# UpdateGameConfig Function
function UpdateGameConfig
{
    # GameUserSettings.ini
    local CONFIG1_DIR=$(dirname $GAME_CONFIG1)

    if [ ! -d $CONFIG1_DIR ]; then
        mkdir -p $CONFIG1_DIR
    fi

    cp $GAME_CONFIG1_EDIT $GAME_CONFIG1

    echo "" >> $GAME_CONFIG1
    echo "[/Script/ShooterGame.ShooterGameUserSettings]" >> $GAME_CONFIG1
    echo "Version=5" >> $GAME_CONFIG1

    #Game.ini
    local CONFIG2_DIR=$(dirname $GAME_CONFIG2)

    if [ ! -d $CONFIG2_DIR ]; then
        mkdir -p $CONFIG2_DIR
    fi

    cp $GAME_CONFIG2_EDIT $GAME_CONFIG2
}
