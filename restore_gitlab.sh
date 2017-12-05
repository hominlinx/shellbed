#!/bin/sh

#source ~/.bashrc
BACKUPDIR="/mnt/home/fgitlab/gitlab"
GITLABDIR="/mnt/srv/docker/fgitlab/gitlab/backups"
DOCKERID=`docker ps | grep fgitlabconf_gitlab_1 | awk '{print $1}'`

rm -rf $GITLABDIR/*
new_file_name=''
for i in `ls $BACKUPDIR`;
do
    new_file_name=$i;
done
if [ "$new_file_name" = "" ]; then
   echo "ls: cannot access '$GITLABDIR': No such file or directory" > $BACKUPDIR/../errorlog.txt
   exit 0
fi

cp $BACKUPDIR/$new_file_name $GITLABDIR/

if [ "$DOCKERID" = "" ]; then
    echo "gitlab docker is not exist." > $BACKUPDIR/../dockererror.txt
    exit 0
fi

chmod 777 $GITLABDIR/$new_file_name

docker exec -it $DOCKERID sudo -HEu git bundle exec rake gitlab:backup:restore force=yes RAILS_ENV=production
