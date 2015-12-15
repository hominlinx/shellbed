#!/bin/bash

EMPTYDIR="/tmp/deltest"
g_delDir=""

function usage()
{
    echo "`basename $0` [-d|-h]... [DIR]";
    echo "  -h                  print this help info"
    echo "  -d <dirname>        del big dir"
}

function deleteBigDirect()
{
    mkdir $EMPTYDIR
    # Judge $g_delDir is Dir or not.
    if [ -d ${g_delDir} ]
        then
            rsync --delete-before -a -H -v --progress --stats $g_delDir $EMPTYDIR
        else
            echo "${g_delDir} is NOT a dir!!"
    fi

}

if [ "X$1" = X ]; then
    usage;
    exit;
fi
for moption
do
    case $moption in
        "-d") g_delDir=$2 deleteBigDirect;break;
            ;;
        "-h") usage;break;
            ;;
        *)
            if [ "X$moption" != "X" ]; then
                usage;exit;
            fi
            ;;
    esac
done
