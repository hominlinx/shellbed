#!/bin/bash
set +e
cur_date=`date +%y%m%d`
navi_master_dir=~/suntec/${cur_date}

function get_navi_master()
{
    mkdir -p ${navi_master_dir}
    cd ${navi_master_dir}
    repo init -u ssh://igerrit.storm:29418/Src/17Model/17Cy/manifest.git -b 17Cy/release/Navi -m navi.xml
    repo sync -c
    repo start master --all
}

function build_all()
{
    cd ${navi_master_dir}
    source build/envsetup.sh
    lunch generic_x86L2-eng
    make -j8
}

get_navi_master
build_all
