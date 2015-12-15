#!/bin/bash

if [[ $SCRIPT_COLOR == true ]]; then
    # Formatting
    FORM_BOLD='\e[1m'
    FORM_UNDERLINED='\e[4m'

    # Reset
    RESET_ALL='\e[0m'

    # Foreground Colors
    FG_DEFAULT='\e[39m'
    FG_BLACK='\e[30m'
    FG_RED='\e[31m'
    FG_GREEN='\e[32m'
    FG_YELLOW='\e[33m'
    FG_BLUE='\e[34m'
    FG_MAGENTA='\e[35m'
    FG_CYAN='\e[36m'
    FG_LIGHT_GRAY='\e[37m'
    FG_DARK_GRAY='\e[90m'
    FG_LIGHT_RED='\e[91m'
    FG_LIGHT_GREEN='\e[92m'
    FG_LIGHT_YELLOW='\e[93m'
    FG_LIGHT_BLUE='\e[94m'
    FG_LIGHT_MAGENTA='\e[95m'
    FG_LIGHT_CYAN='\e[96m'
    FG_WHITE='\e[97m'

    # Background Colors
    BG_DEFAULT='\e[49m'
    BG_BLACK='\e[40m'
    BG_RED='\e[41m'
    BG_GREEN='\e[42m'
    BG_YELLOW='\e[43m'
    BG_BLUE='\e[44m'
    BG_MAGENTA='\e[45m'
    BG_CYAN='\e[46m'
    BG_LIGHT_GRAY='\e[47m'
    BG_DARK_GRAY='\e[100m'
    BG_LIGHT_RED='\e[101m'
    BG_LIGHT_GREEN='\e[102m'
    BG_LIGHT_YELLOW='\e[103m'
    BG_LIGHT_BLUE='\e[104m'
    BG_LIGHT_MAGENTA='\e[105m'
    BG_LIGHT_CYAN='\e[106m'
    BG_WHITE='\e[107m'
else
    # Formatting
    FORM_BOLD=''
    FORM_UNDERLINED=''

    # Reset
    RESET_ALL=''

    # Foreground Colors
    FG_DEFAULT=''
    FG_BLACK=''
    FG_RED=''
    FG_GREEN=''
    FG_YELLOW=''
    FG_BLUE=''
    FG_MAGENTA=''
    FG_CYAN=''
    FG_LIGHT_GRAY=''
    FG_DARK_GRAY=''
    FG_LIGHT_RED=''
    FG_LIGHT_GREEN=''
    FG_LIGHT_YELLOW=''
    FG_LIGHT_BLUE=''
    FG_LIGHT_MAGENTA=''
    FG_LIGHT_CYAN=''
    FG_WHITE=''

    # Background Colors
    BG_DEFAULT=''
    BG_BLACK=''
    BG_RED=''
    BG_GREEN=''
    BG_YELLOW=''
    BG_BLUE=''
    BG_MAGENTA=''
    BG_CYAN=''
    BG_LIGHT_GRAY=''
    BG_DARK_GRAY=''
    BG_LIGHT_RED=''
    BG_LIGHT_GREEN=''
    BG_LIGHT_YELLOW=''
    BG_LIGHT_BLUE=''
    BG_LIGHT_MAGENTA=''
    BG_LIGHT_CYAN=''
    BG_WHITE=''
fi
