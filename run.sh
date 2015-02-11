#!/bin/bash

PWDAA=`pwd`
TEMPFILE=$PWDAA/temp.txt
SERVERDIR=$XDK_SOURCE_PATH/Elastos/Frameworks/Droid/Base/Services/Server/src
COREDIR=$XDK_SOURCE_PATH/Elastos/Frameworks/Droid/Base/Core

source $XDK_SETUP_PATH/SetEnv.sh arm_android
echo "emake Elastos.Droid.Server.eco"
cd $SERVERDIR
#emake  2>&1 | tee $PWDAA/temp.txt
emake 2>&1 | tee $TEMPFILE
egrep "Error|error" $PWDAA/temp.txt 
if [ $? = 0 ]; then
    echo Hominlinx--has error
    rm $TEMPFILE
    exit
fi

echo "emake Elastos.Droid.Core.eco"
cd $COREDIR
#emake &> $TEMPFILE
emake 2>&1 | tee $TEMPFILE
egrep "Error|error" $PWDAA/temp.txt
if [ $? = 0 ]; then
    echo Hominlinx--has error
    rm $TEMPFILE
    exit
fi

echo "adb push eco to system/lib"
adb push ~/elastos/ElastosRDK4_2_2/Targets/rdk/arm.gnu.android.dbg/bin/Elastos.Droid.Server.eco /system/lib
adb push ~/elastos/ElastosRDK4_2_2/Targets/rdk/arm.gnu.android.dbg/bin/Elastos.Droid.Core.eco /system/lib

echo "kill elsystemserver"
ELPID=`adb shell ps | grep elsystemserver | awk '{print $2}'`
echo "pid is " $ELPID
adb shell kill -9 $ELPID


