#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
md5_path=$current_working_directory/$folder.md5
size_path=$current_working_directory/$folder.size

cd $path

# reset logs
echo -n "" > $md5_path
echo -n "" > $size_path

for line in $(find ./); do 
	if [ -f "${line}" ] ; then
		md5sum $line >> $md5_path
		ls --all --size --human-readable $line >> $size_path
	fi
done

cd $current_working_directory
