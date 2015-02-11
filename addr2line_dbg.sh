#!/bin/bash
CRASH_FILE="crashinfo"
DEBUG_FILE="/home/kortide/elastos/debug/debug.txt"
REMOTE_DEBUG="/data/temp/debug.txt"

GET_DEBUG_FILE=false
LOGCAT_DEBUG_FILE=false
USE_CRASH_FILE=false
#adb command on the device(-e emulator)
ADB_OPT=-d

function usage()
{
    echo "`basename $0` [-h|-u]";
    echo "  -h  print this help info";
    echo "  -u  get the crashinfo from the target";
    echo "      through the adb pull command";
    echo "  -c  get the crashinfo from the target";
    echo "      through the adb logcat command";
    echo "  -d  use the crashinfo directly";
}


for moption
do
#echo $option
    case $moption in
        "-h") usage;break
            ;;
        "-u") GET_DEBUG_FILE=true
            ;;
        "-c") LOGCAT_DEBUG_FILE=true
            ;;
        "-d") USE_CRASH_FILE=true
            ;;
        *)
             if [ "X$moption" != "X" ]; then
                usage;exit;
             fi
            ;;
    esac
done

#LOGCAT_DEBUG_FILE is check first
#have higher priority than GET_DEBUG_FILE
if [ $LOGCAT_DEBUG_FILE == "true" ]; then
    echo "adb ${ADB_OPT} logcat -d > $DEBUG_FILE ..."
    adb ${ADB_OPT} logcat -d > $DEBUG_FILE
elif [ $GET_DEBUG_FILE == "true" ]; then
    echo "adb ${ADB_OPT} pull $REMOTE_DEBUG $DEBUG_FILE ..."
    adb ${ADB_OPT} pull $REMOTE_DEBUG $DEBUG_FILE
fi

if [ $USE_CRASH_FILE == "false" ]; then
    sed -n '/backtrace:/,/stack:/p' $DEBUG_FILE > $CRASH_FILE
#remove the DOS EOL symbol
    sed -i 's/\x0D$//' $CRASH_FILE
fi

cut $CRASH_FILE -d ' ' -f 13-15 > tempx8x9

echo "the backtrace from the coredump as below ......"
while read line
do
#    echo $line
    NUM=`echo $line | cut -d ' ' -f 1`
    F=`echo $line | cut -d ' ' -f 2 | cut -d '/' -f 4`

#echo "arm-linux-androideabi-addr2line -e $XDK_TARGETS/dbg_info/$F $NUM"
    if [ "X$NUM" != "X" ] && [ "X$F" != "X" ]; then
        arm-linux-androideabi-addr2line -e $XDK_TARGETS/dbg_info/$F $NUM
    fi

done < tempx8x9

#rm tempx8x9
