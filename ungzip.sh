#!/bin/bash
# 执行logtest， 生成log，解压，判断，

LOG_PATH="/home/hominlinx/native/build/bin/LOG/SYSTEM/"
CONFFILE="/home/hominlinx/log_config.txt"
EXEPATH="/home/hominlinx/native/build/bin/"
PWDAA=`pwd`
TOTAL=1000004

function test()
{
    while true
    do
        # find *.log
        cd ${LOG_PATH}

        logfiles=`ls *.log 2>/dev/null| wc -l`
        echo ${logfiles}
        if [ 0 -ne ${logfiles} ];  then
            echo "XXXXXXXXXXX"
            rm ${LOG_PATH}/*
        fi

        cd ${EXEPATH}
        time ./logtest-navi ${CONFFILE}

        # unzip
        cd ${LOG_PATH}
        ls *.log | while read a; do mv $a $a.gz; done
        ls *
        echo "rename ok!!!"
        gunzip *.gz
        line=`find . -name "*.log" | xargs cat | wc -l`
        echo ${line}
        if [ ${TOTAL} -ne ${line} ]
        then
            break;
        fi
    done

}

test;
