#!/bin/bash

g_content=""
g_fileInput=""
g_return=0
E_FILE_NOT_FOUND=100;
E_FILE_INVALID=101;


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
    fi
    # invalid filename
    if [ ! -f $g_fileInput ]
    then
        echo "file : $g_fileInput not found"
        exit $E_FILE_NOT_FOUND
    fi
}


echo "find in file ==============$g_fileInput"
# clean single-line comments
function getFileCleanContent() {
    g_content=`sed 's/\/\*.*\*\///g' $1 | sed 's/\/\/.*$/$/g' | sed 's/\".*\"//g'`
}

function handle_key()
{
    declare -a mStart
    multiLineStart=`echo "$g_content" | grep -n "\/\*" | sed 's/:.*$//g'`
    mStart=($multiLineStart)
    #echo "multiLineStart : ${multiLineStart[@]}"

    declare -a mEnd
    multiLineEnd=`echo "$g_content" | grep -n "\*\/" | sed 's/:.*$//g'`
    mEnd=($multiLineEnd)
    #echo "multiLineEnd : ${multiLineEnd[@]}"

    if [ ${#mStart[*]} -ne ${#mEnd[*]} ]; then
        echo "file: $g_fileInput is invalid."
        exit $E_FILE_INVALID
    fi

    # find spec content and exclude them from multiline commens.
    if [ "$1" != "return" ]
    then
        findLines_null=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "\<$1\>"|sed 's/:.*$//g'`
    else
        findLines=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "\<$1\>\s*"| grep -E -v "\<$1\>\s*(\bnull\b)" | grep -E -v "\<$1\>\s*(\bNULL\b)"|sed 's/:.*$//g'`
    fi

    echo $1=== find: $findLines 

    if [ "$findLines" = "" ]
    then
        return
    fi

    i=0
    j=0
    cnt=${#mStart[*]}

    while [ $i -lt $cnt ]
    do
        if [ $i -gt 0 ] && [ ${mStart[$i]} -lt ${mEnd[$((j-1))]} ]
        then
            i=$((i+1))
            continue
        fi

        #echo "multiline comments line: ${mStart[$i]}  -- ${mEnd[$j]}"
        for line in $findLines
        do
            # line is increment
            #echo "handle line:$line , all:$findLines cnt:$cnt"
            if [ $line -ge ${mEnd[$j]} ]
            then
                #echo "ge ${mEnd[$j]}"
                break
            fi

            # line < ${mEnd[$i]}
            if [ $line -gt ${mStart[$i]} ]
            then
                echo "============line:$line is in comments"
                findLines=`echo "$findLines" | grep -v "$line"`
                echo "************remain result: $findLines"
            fi
        done
        i=$((i+1))
        j=$((j+1))
    done

    if [ "$findLines" = "" ]
    then
        echo "can't find \"$1\" in file: \"$g_fileInput\""
        g_return=$((g_return+0))
        return
    fi

    #handle the key word
    for line in $findLines
    do
        echo $1 $line $g_fileInput
        #sed -i ""$line"s/$1/RETURN()/g" $g_fileInput
    done


}



aItems=(
    "return NULL"
    "return null"
    "return  NULL"
    "return  null"
    "return"
)

if [ "X$1" = X ]; then
    usage;
    exit;
fi
for motion
do
    case $motion in
        "-h") usage;break
            ;;
        "-f") g_fileInput=$2;detectFile;break;
            ;;
        *)
            if [ "X$motion" != "X" ]; then
                usage;exit;
            fi
            ;;
    esac
done

# first handle return NULL key
getFileCleanContent $g_fileInput

for ((ii=0; ii < ${#aItems[@]}; ii++)) {
    handle_key "${aItems[$ii]}"
}


