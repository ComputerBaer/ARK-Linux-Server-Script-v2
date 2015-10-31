#!/bin/bash

for file in $SCRIPT_ACTION_DIR*; do
    if [ -f $file ]; then
        local filename=$(basename $file)
        echo -e "  ${FG_CYAN}- ${filename%.*}${RESET_ALL}"
    fi
done
