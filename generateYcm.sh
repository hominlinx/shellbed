#!/bin/bash
declare -a dirs_to_recurse=('project1' 'project2' 'project3')

template_file="ycm-template.txt"

generate_ycm_config ()
{
    file=.ycmtmp.txt
    dir=$(echo "$1" | sed -e 's/ /\\ /g')
    if [ -d "$dir" ]; then
        cd "$dir"
        if [ -f "Makefile" ] && $(ls -U *.pro > /dev/null 2>&1); then
            list=""
            for i in DEFINES CXXFLAG INCPATH; do
                list="${list} '$(cat Makefile | grep "$i.*=" | sed -e "s/$i.*= //g" | sed -e "s/ \$(DEFINES)//g" | sed -e "s/ -Wno-unused-local-typedefs//g" | sed -e "s/ /\', \'/g")', "
            done
            echo "$list"
            rm -f $file
            preifs="$IFS"
            IFS=''
            while read line; do
                echo $line >> $file
                if [[ $line =~ ^compilation_database_folder ]]; then
                    read -r -d '' VAR << __EOF__

flags = [
$list
]

__EOF__
                    echo "$VAR" >> $file
                fi
            done < $template_file
            mv $file .ycm_extra_conf.py
            IFS=$preifs
        fi
    fi
}


generate_ycm_config $1

#for dir in ${dirs_to_recurse[@]}; do
    #echo "ff" $dir, $HOME/$dir
    #for i in $(find $HOME/$dir -type d 2> /dev/null); do
        #echo "fd"
        ##generate_ycm_config "$i"
    #done
#done
