#!/bin/bash

source ~/.bashrc
rm -rf ./gitlab/*.tar
new_file_name=''
for i in `ssh server@192.168.3.200 ls /srv/docker/gitlab/gitlab/backups/`;
do
    echo $i > ./gitlab/new.txt;
    new_file_name=$i;
done
scp server@192.168.3.200:/srv/docker/gitlab/gitlab/backups/$new_file_name ./gitlab/
