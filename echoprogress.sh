#!/bin/bash

begin=10
end=30
#cat /tmp/my_fifo | awk '{print $2}' | sed "s/%/""/g"
while read line
do
    d=`echo $line| awk -F' ' '{print $2}' | sed "s/%/""/g"`
    #d=`echo $line`
    #c=`expr \($end - $begin\)/100*$d + 10`
    c=`echo "scale=2;($end - $begin)/100*$d + $begin" | bc`
    echo $d ==== $c
    length=`expr length + 1`

    #echo $line
done < /tmp/my_fifo
echo "done"
