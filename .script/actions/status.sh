#!/bin/bash

GameStatus
if [[ $GAME_IS_RUNNING == true ]]; then
    echo -e "${FG_CYAN}${STR_GAME_STATUS} ${FG_GREEN}${STR_GAME_RUNNING}${RESET_ALL}"
else
    echo -e "${FG_CYAN}${STR_GAME_STATUS} ${FG_RED}${STR_GAME_RUNNING_NOT}${RESET_ALL}"
fi
