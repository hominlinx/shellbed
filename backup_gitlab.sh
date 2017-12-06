#!/bin/sh

#source ~/.bashrc
BACKUPDIR="/root/gitlab_backup/gitlab"
GITLABDIR="/srv/docker/gitlab/gitlab/backups"
REMOTEDIR="/mnt/home/fgitlab"
REMOTEIP="fgitlab@180.76.243.131"
IP=`ifconfig eno1 | grep 'inet ' | sed s/^.*addr://g | sed s/Bcast.*$//g`
DATE=`date '+%Y-%m-%d %H:%M:%S'`
rm -rf $BACKUPDIR/*
new_file_name=''
echo "Date: $DATE" > $BACKUPDIR/log.txt
echo "This file come from $IP by root" >> $BACKUPDIR/log.txt;
echo "gitlab dir: $GITLABDIR" >> $BACKUPDIR/log.txt;
echo "gitlab's backup dir: $BACKUPDIR" >> $BACKUPDIR/log.txt;
for i in `ls $GITLABDIR`;
do
    echo $i >> $BACKUPDIR/log.txt;
    new_file_name=$i;
done


if [ "$new_file_name" = "" ]; then
   echo "gitlab's file is not exist." >> $BACKUPDIR/log.txt
   echo "ls: cannot access '$GITLABDIR': No such file or directory" >> $BACKUPDIR/log.txt
   echo "scp failed!!!" >> $BACKUPDIR/log.txt
   sshpass -p fgitlab scp $BACKUPDIR/log.txt $REMOTEIP:$REMOTEDIR
   exit 0
fi
   
echo "before scp!!!" >> $BACKUPDIR/log.txt
sshpass -p fgitlab scp $BACKUPDIR/log.txt $REMOTEIP:$REMOTEDIR
cp $GITLABDIR/$new_file_name $BACKUPDIR/
sshpass -p fgitlab scp $BACKUPDIR/$new_file_name $REMOTEIP:$REMOTEDIR/gitlab/

DATEDONE=`date '+%Y-%m-%d %H:%M:%S'`
echo "$DATEDONE -->  scp done!!!" >> $BACKUPDIR/log.txt
sshpass -p fgitlab scp $BACKUPDIR/log.txt $REMOTEIP:$REMOTEDIR
