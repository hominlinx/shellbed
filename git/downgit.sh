#!/bin/bash

#输入：git@example.com:framework/app_manager.git
#输出：app_manager
GetGitRepsName()
{
    #echo "git@example.com:framework/app_manager.git"|sed 's;^.*\/\(.*\)\.git;\1;g'

    #这里提供了两种方法去找到app_manager
    #gname=`echo $1 | cut -d / -f 2 | cut -d . -f1`
    gname=`echo $1 |sed 's;^.*\/\(.*\)\.git;\1;g'`
    echo $gname
}

DownloadGitCode()
{
    echo "processing : $1"
    git clone $1

    echo "get target dir"
    dirname=`GetGitRepsName $1`
    echo "$dirname"

    cd $dirname
    pwd
    #忽略权限检查，这是为什么要获取dirname的原因
    git config --add core.filemode false
    cd ..
    pwd
    echo
}

target_dir=default_git
if [ $# -eq 1 ];then
    target_dir=$1
fi

echo "create target folder:$target_dir"
mkdir -p $target_dir
rm -rf $target_dir/*
cd $target_dir

#将所需要的权限放到数组中，**注意‘\’前有一个空格**
GIT_LIST_ARRAY=(
"BootLoader.git"
"MCU_IO.git"
)

COMMONGIT="gitlab@gitlab.autoio.org:"
GITPREFIX="MCU/"

#遍历数组，逐步处理
for gg in ${GIT_LIST_ARRAY[@]}
do
    gitlab="$COMMONGIT$GITPREFIX$gg"
    echo input:$gitlab
    DownloadGitCode $gitlab
done

cd ..
