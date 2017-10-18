#!/bin/bash

# Only 1 parameter !
if [ $# != 1 ];then
    echo " Usage: .\read.sh filename!";
    exit
fi

# check the file !
if ! [ -f $1 ];then
    echo "file does not exist!"
    exit
elif ! [ -r $1 ];then
    echo "file can not be read !"
    exit
fi

# PRESS ANY KEY TO CONTITUE !
read -p "begin to read $1 "

# set IFS="\n" , read $1 file per line !
IFS="
"

# i is the line number
i=1
for line in `cat $1`
do
    echo line $i:$line
    let "i=$i+1"
done

echo "Finished reading file by line ! "
