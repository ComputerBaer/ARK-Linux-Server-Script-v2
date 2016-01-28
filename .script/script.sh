#!/bin/bash

# CheckAdditionalDependencies Function
function CheckAdditionalDependencies
{
    # Check Dependencies
    local dependencies=""
    if [[ $(IsInstalled screen) == false ]]; then
        dependencies="${dependencies} screen"
    fi
    #if [ ! -f "/usr/lib32/libgcc_s.so.1" ]; then
    #    dependencies="${dependencies} lib32gcc1"
    #fi

    # Missing Dependencies found?
    if [[ -z $dependencies ]]; then
        return
    fi
    echo -e "${FG_RED}${STR_DEPENDENCIES_MISSING/'{0}'/${dependencies:1}}${RESET_ALL}"

    # Is root user
    if [[ $SYSTEM_IS_ROOT == true ]] && [ ! -z "$SYSTEM_PACKAGE_MANAGER" ]; then
        # Install missing Dependencies?
        echo -e "${FG_YELLOW}${STR_DEPENDENCIES_INSTALL}${RESET_ALL}"
        if [[ $(DialogYesNo) == true ]]; then
            echo # Line break
            $SYSTEM_PACKAGE_MANAGER $SYSTEM_PACKAGE_MANAGER_INSTALL $dependencies
            echo # Line break
            return
        fi
    fi

    ExitScript
}

# CompleteInit Function
function CompleteInit
{
    # Generate Game Configuration (.script/game.sh)
    CheckGameConfig
}

# CompleteCleanUp Function
function CompleteCleanUp
{
    return # Empty Function
}
