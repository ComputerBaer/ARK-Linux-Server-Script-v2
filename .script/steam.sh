#!/bin/bash

function WaitForBackgroundProcess
{
    PROCESS_ID=$1

    while true; do
        if kill -0 $PROCESS_ID 2>/dev/null; then
            echo -ne "."
        else
            break
        fi
        sleep 0.5s
    done

    echo # Line break
}

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
