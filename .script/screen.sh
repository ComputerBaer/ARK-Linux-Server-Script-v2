#!/bin/bash

GAME_IS_RUNNING=false

function StartGame
{
    local REQUIRED_LIMIT=100000
    local CURRENT_LIMIT=$(ulimit -n)
    if [ $CURRENT_LIMIT -lt $REQUIRED_LIMIT ]; then
        echo -e "${FG_RED}${STR_EXEC_DEPENDENCIES}${RESET_ALL}"
        CleanUp
        exit 0
    fi

    GameStatus
    if [[ $GAME_IS_RUNNING == true ]]; then
        echo -e "${FG_RED}${STR_GAME_ALREADY_RUNNING}${RESET_ALL}"
        ExitScript
    fi
    echo -e "${FG_YELLOW}${STR_GAME_START}${RESET_ALL}"

    local EXEC_DIR=$(dirname $GAME_EXECUTABLE)
    local EXEC_NAME=$(basename $GAME_EXECUTABLE)

    cd $EXEC_DIR
    screen -A -m -d -S $InstanceName "./${EXEC_NAME}" "TheIsland?listen"
    cd $SCRIPT_BASE_DIR
}

function StopGame
{
    GameStatus
    if [[ $GAME_IS_RUNNING == true ]]; then
        screen -S $InstanceName -X quit
    fi
    echo -e "${FG_YELLOW}${STR_GAME_STOPPED}${RESET_ALL}"
}

function GameStatus
{
    if screen -list | grep -q $InstanceName; then
        GAME_IS_RUNNING=true
    else
        GAME_IS_RUNNING=false
    fi
}
