#!/bin/bash

if [[ -z $1 ]];then
    echo "need argument, for example: ./install_plugin compiled/acs.smx"
    exit
fi

this_script_path=$(dirname $0)
this_script_name=$(basename $0)

cp_file=./$1
base_filename="$(basename $cp_file)"

# echo $cp_file
# echo $base_filename

if [[ $2 != "--silent" ]]; then
    echo "rm $HOME/serverfiles/left4dead2/addons/sourcemod/plugins/$base_filename"
    echo "cp $cp_file $HOME/serverfiles/left4dead2/addons/sourcemod/plugins/"
fi

rm $HOME/serverfiles/left4dead2/addons/sourcemod/plugins/$base_filename
cp $cp_file $HOME/serverfiles/left4dead2/addons/sourcemod/plugins/

if [[ $2 == "--silent" ]]; then
    exit
fi

cd $this_script_path
./console_refresh.sh
