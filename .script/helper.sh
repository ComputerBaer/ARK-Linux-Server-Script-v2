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

# CheckInteger Function
# Param1 - Value to check
# Param2 - Default, if value is invalid
function CheckInteger
{
    local num=$1
    local default=$2
    local regex='^[0-9]+$' # Positive Numbers
    #local regex='^-?[0-9]+$' # Positive and negative Numbers

    if [[ $num =~ $regex ]]; then
        # Is valid Integer
        echo $num
    else
        # Is invalid Integer
        echo $default
    fi
}

# CheckDouble Function
# Param1 - Value to check
# Param2 - Default, if value is invalid
function CheckDouble
{
    local num=$1
    local default=$2
    local regex='^[0-9]+([.][0-9]+)?$' # Positive Numbers
    #local regex='^-?[0-9]+([.][0-9]+)?$' # Positive and negative Numbers

    if [[ $num =~ $regex ]]; then
        # Is valid Double
        echo $num
    else
        # Is invalid Double
        echo $default
    fi
}

# InvertBoolean Function
# Param1 - Boolean to invert
function InvertBoolean
{
    local bool=$1

    if [[ $bool =~ true ]]; then
        echo "false"
    elif [[ $bool =~ false ]]; then
        echo "true"
    else
        # Is invalid Boolean, return Input
        echo $bool
    fi
}
