#!/bin/bash

this_script_path=$(dirname $0)
this_script_name=$(basename $0)

cd $(dirname $this_script_path)

# pull
# git pull
git pull
# pull fail, stop
if [[ $? -ne 0 ]];then
    exit
fi
# compile
compile_info=$(./compile.sh)
# compile fail, stop
if [[ $? -ne 0 ]];then
    echo $compile_info
    echo "compile failed, please check the output above"
    exit
fi

for smx in ./compiled/*
do
    if [[ $smx == *".smx" ]];then
        echo "installing $smx"
        ./install_plugin.sh $smx --silent
    fi
done

# refresh console now
./console_refresh.sh
