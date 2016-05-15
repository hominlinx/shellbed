#!/bin/bash

g_content=""
g_fileInput=""
g_find="ssid=\"TP-LINK_Monkey\""

function usage()
{
    echo "`basename $0` [-h|-f]... [FILE]";
    echo "  -h                  print this help info"
    echo "  -f <filename>       \"return\" replaced by \"RETURN\" in filename"
}

function detectFile()
{
    if [ "X$g_fileInput" = "X" ]; then
        usage;
        exit $E_FILE_NOT_FOUND
    fi
    # invalid filename
    if [ ! -f $g_fileInput ]
    then
        echo "file : $g_fileInput not found"
        exit $E_FILE_NOT_FOUND
    fi
}

function handle_key()
{
    declare -a mStart
    multiLineStart=`echo "$g_content" | grep -n "network={" | sed 's/:.*$//g'`
    mStart=($multiLineStart)
    #echo "multiLineStart : ${multiLineStart[@]}"

    declare -a mEnd
    multiLineEnd=`echo "$g_content" | grep -n "}" | sed 's/:.*$//g'`
    mEnd=($multiLineEnd)
    #echo "multiLineEnd : ${multiLineEnd[@]}"

    if [ ${#mStart[*]} -ne ${#mEnd[*]} ]; then
        echo "file: $g_fileInput is invalid."
        exit -1
    fi

    i=0
    cnt=${#mStart[*]}
    j=$cnt
    while [ $j -gt 0 ]
    do
        #if [ $i -gt 0 ] && [ ${mStart[$i]} -lt ${mEnd[$((j-1))]} ]
        #then
            #echo i:$i
            #i=$((i+1))
            #continue
        #fi
        echo "====mstart:${mStart[j]}, mend:${mEnd[j]}"
        test=`sed -n "${mStart[j]},${mEnd[j]}p" $g_fileInput `
        echo "XXXX: $test"
        echo "$test" | grep $g_find
        if [ $? = 0 ]
        then
            sed  -i "${mStart[j]},${mEnd[j]}d" $g_fileInput
            echo "XXXXXXXXXXXXx delete"
        fi
        i=$((i+1))
        j=$((j-1))
    done


}

function handle_file()
{
    detectFile;
    g_content=`cat $g_fileInput`
    handle_key
}



if [ "X$1" = X ]; then
    usage;
    exit;
fi
for motion
do
    case $motion in
        "-h") usage;break
            ;;
        "-f") g_fileInput=$2;handle_file;break;
            ;;
        *)
            if [ "X$motion" != "X" ]; then
                usage;exit;
            fi
            ;;
    esac
done


