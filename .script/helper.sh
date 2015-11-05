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
