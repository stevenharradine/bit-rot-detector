#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
md5_path=$current_working_directory/$folder.md5
size_path=$current_working_directory/$folder.size
number_of_files_disk=0
number_of_files_added=0

cd $path

for line in $(find ./); do
	if [ -f "${line}" ] ; then	# if the file exists and
		((number_of_files_disk++))
		if [ "`redis-cli get $folder:$line:size`" == "" ] ; then	# there is no index of it in redis
			((number_of_files_added++))
			redis-cli set $folder:$line:size "`ls -l --all --size $line | cut --field=6 --delimiter=' '`"
			redis-cli set $folder:$line:md5 "`md5sum $line | cut --field=1 --delimiter=' '`"
		fi
	fi
done

number_of_files_datastore=`redis-cli keys "*" | grep ":md5$" | wc -l`

cd $current_working_directory

echo ""
echo "build:$root/$folder"
echo "         Number of files added: $number_of_files_added"
echo "    Number of that are on disk: $number_of_files_disk"
echo "  Number of files in datastore: $number_of_files_datastore"
