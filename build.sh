#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
md5_path=$current_working_directory/$folder.md5
list_path=$current_working_directory/$folder.list

cd $path

# reset logs
echo -n "" > $md5_path
echo -n "" > $list_path

for line in $(find ./); do 
	if [ -f "${line}" ] ; then
		ls -lash $line >> $list_path
		md5sum $line >> $md5_path
	fi
done

cd $current_working_directory
