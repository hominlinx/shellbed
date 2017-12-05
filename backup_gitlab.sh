#!/bin/sh

#source ~/.bashrc
BACKUPDIR="/home/server/docker-gitlab/gitlab"
GITLABDIR="/srv/docker/gitlab/gitlab/backups"
REMOTEDIR="/mnt/home/fgitlab"
REMOTEIP="fgitlab@180.76.243.131"
IP=`ifconfig eno1 | grep 'inet ' | sed s/^.*addr://g | sed s/Bcast.*$//g`

rm -rf $BACKUPDIR/*
new_file_name=''
for i in `ls $GITLABDIR`;
do
    echo "This file come from $IP by server" > $BACKUPDIR/log.txt;
    echo $i >> $BACKUPDIR/log.txt;
    echo "gitlab dir: $GITLABDIR" >> $BACKUPDIR/log.txt;
    echo "gitlab's backup dir: $BACKUPDIR" >> $BACKUPDIR/log.txt;
    sshpass -p fgitlab scp $BACKUPDIR/log.txt $REMOTEIP:$REMOTEDIR
    new_file_name=$i;
done
if [ "$new_file_name" = "" ]; then
   echo "This file come from $IP by server" > $BACKUPDIR/log.txt;
   echo "gitlab dir: $GITLABDIR " >> $BACKUPDIR/log.txt
   echo "gitlab's file is not exist." >> $BACKUPDIR/log.txt
   echo "ls: cannot access '$GITLABDIR': No such file or directory" >> $BACKUPDIR/log.txt
   sshpass -p fgitlab scp $BACKUPDIR/log.txt $REMOTEIP:$REMOTEDIR
   exit 0
fi
   
cp $GITLABDIR/$new_file_name $BACKUPDIR/
sshpass -p fgitlab scp $BACKUPDIR/$new_file_name $REMOTEIP:$REMOTEDIR
#sshpass -p fangyan@yocto scp $BACKUPDIR/$new_file_name yocto-dev@192.168.3.201:/opt/yocto-dev/share/backup
