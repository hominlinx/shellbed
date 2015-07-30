#!/bin/bash

g_content=""
g_fileInput=""
g_dirInput=""
g_return=0
E_FILE_NOT_FOUND=100;
E_FILE_INVALID=101;


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
    findLines_null=""
    findLines_return=""
    findLines_new=""
    findLines_void=""
    if [ "$1" != "return" ] && [ "$1" != "return new\(" ] && [ "$1" != "return;" ]
    then
        findLines_null=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`
    elif [ "$1" = "return new\(" ]
    then
        findLines_new=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`
    elif [ "$1" = "return;" ]
    then
        findLines_void=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "$1"|sed 's/:.*$//g'`
    elif [ "$1" = "return" ] && [ "$1" != "return\snew\(" ] && [ "$1" != "return;" ]
    then
        findLines_return=`echo "$g_content" |sed 's/.*\*\///g'|sed 's/\/\*.*$/$/g'|grep -E -n "\<$1\>\s*" | grep -E -v "\<$1\>\s*(\bnull\b);" | grep -E -v "\<$1\>\s*(\bNULL\b);"| grep -E -v "$1\snew\(" | grep -E -v "$1;" | sed 's/:.*$//g'`
    fi

    #echo $1=== return: $findLines_return , null: $findLines_null , new: $findLines_new, void: $findLines_void

    if [ "$findLines_return" = "" ] && [ "$findLines_null" = "" ] && [ "$findLines_new" = "" ] && [ "$findLines_void" = "" ]
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

        #for return new(xx) xxx;
        for line in $findLines_new
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
                findLines_new=`echo "$findLines_new" | grep -v "$line"`
                #echo "************remain result: $findLines_new"
            fi
        done

        #for return;
        for line in $findLines_void
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
                findLines_void=`echo "$findLines_void" | grep -v "$line"`
                #echo "************remain result: $findLines_void"
            fi
        done


        # for return null; return NULL; return  null; return  NULL;
        for linenull in $findLines_null
        do
            if [ $linenull -ge ${mEnd[$j]} ]
            then
                break
            fi

            if [ $linenull -gt ${mStart[$j]} ]
            then
               # echo "============linenull:$linenull is in comments"
                findLines_null=`echo "$findLines_null" | grep -v "$linenull" `
               # echo "************remain result: $findLines_null"
            fi
        done

        i=$((i+1))
        j=$((j+1))
    done

    if [ "$findLines_return" = "" ] && [ "$findLines_null" = "" ] && [ "$findLines_new" = "" ] && [ "$findLines_void" = "" ]
    then
        echo "can't find \"$1\" in file: \"$g_fileInput\""
        g_return=$((g_return+0))
        return
    fi

    #handle the key word
    for line in $findLines_null
    do
        #echo $1 $line $g_fileInput
        sed -i ""$line"s/$1/RETURN_NULL;/g" $g_fileInput
    done

    for line in $findLines_return
    do
        #echo $1 $line $g_fileInput
        sed -i ""$line"s/$1 \([^;]*\);/RETURN(\1);/g" $g_fileInput
    done

    for line in $findLines_void
    do
        #echo $1 $line $g_fileInput
        sed -i ""$line"s/$1/RETURN();/g" $g_fileInput
    done

    for line in $findLines_new
    do
        #echo $1 $line $g_fileInput
        sed -i ""$line"s/return new(\([^;]*\);/RETURN_NEW(new\(\1);/g" $g_fileInput

    done


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
    "return NULL;"
    "return null;"
    "return  NULL;"
    "return  null;"
    "return"
    "return;"
    "return new\("
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



