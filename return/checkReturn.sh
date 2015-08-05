#!/bin/bash

g_content=""
g_fileInput=""
g_dirInput=""
g_return=0
E_FILE_NOT_FOUND=100;
E_FILE_INVALID=101;
E_RETURN_INVALID=101;


function usage()
{
    echo "`basename $0` [-h|-f]... [FILE]";
    echo "  -h                  print this help info"
    echo "  -f <filename>       \"return\" replaced by \"RETURN\" in filename"
    echo "  -d <dirname>        \"return\" replaced by \"RETURN\" in dir"
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

function detectDir()
{
    if [ "X$g_dirInput" = "X" ]; then
        usage;
        exit $E_FILE_NOT_FOUND
    fi

    if [ ! -d $g_dirInput ]
    then
        echo "dir: $g_dirInput not found"
        exit $E_FILE_NOT_FOUND
    fi
}

function ergodic()
{
    for file in `ls $1`
    do
        if [ -d $1"/"$file ]
        then
            ergodic $1"/"$file
        else
            local path=$1"/"$file
            if [ ${file##*.} = cpp ] || [ ${file##*.} = h ]; then
                g_fileInput=$1"/"$file
                #echo $g_fileInput $path $file
                handle_file;
            fi
        fi
    done
}


#echo "find in file ==============$g_fileInput"
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
    findLines_return=""
    findLines_other=""

    if [ "$1" = "RETURN\(new\(" ] || [ "$1" = "RETURN\(\snew\(" ] || [ "$1" = "RETURN\(NULL\)" ] || [ "$1" = "RETURN\(null\)" ]
    then
        findLines_other=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`
    else
        findLines_return=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|grep -E -v "RETURN\s*\([a-zA-Z0-9_]*\);"|grep -E -v "RETURN\s*\(new\("|grep -E -v "RETURN\s*\(NULL\)"|grep -E -v "RETURN\s*\(null\)"|sed 's/:.*$//g'`
    fi

    #findLines_return=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`
    #findLines_return=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`


    #echo $1=== return: $findLines_return , $findLines_other

    if [ "$findLines_return" = "" ] && [ "$findLines_other" = "" ]
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
        # for return
        for line in $findLines_return
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
                #echo "============line:$line is in comments"
                findLines_return=`echo "$findLines_return" | grep -v "$line"`
                #echo "************remain result: $findLines_return"
            fi
        done

        # for others
        for line in $findLines_other
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
                #echo "============line:$line is in comments"
                findLines_other=`echo "$findLines_other" | grep -v "$line"`
                #echo "************remain result: $findLines_return"
            fi
        done

        i=$((i+1))
        j=$((j+1))
    done

    if [ "$findLines_return" = "" ] && [ "$findLines_other" = "" ]
    then
        echo "can't find \"$1\" in file: \"$g_fileInput\""
        g_return=$((g_return+0))
        return
    else
        echo "find \"$1\" in file : \"$g_fileInput\""
        #exit $E_RETURN_INVALID
    fi


}


function handle_file()
{
    detectFile;
    # first handle return NULL key
    getFileCleanContent $g_fileInput

    for ((ii=0; ii < ${#aItems[@]}; ii++)) {
        handle_key "${aItems[$ii]}"
    }

    echo $g_fileInput replaced ok...
}

function handle_dir()
{
    detectDir;
    ergodic $g_dirInput
}


aItems=(
    "RETURN\s*\("
    "RETURN\(new\("
    "RETURN\(\snew\("
    "RETURN\(NULL\)"
    "RETURN\(null\)"
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
        "-f") g_fileInput=$2;handle_file;break;
            ;;
        "-d") g_dirInput=$2;handle_dir;break;
            ;;
        *)
            if [ "X$motion" != "X" ]; then
                usage;exit;
            fi
            ;;
    esac
done



