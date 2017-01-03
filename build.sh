#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
is_verbose=false
path=$root/$folder
number_of_files_disk=0
number_of_files_added=0

if [ "$3" == "--verbose" ] ; then
	is_verbose=true
fi

cd $path

for line in $(find ./); do
	if [ -f "${line}" ] ; then	# if the file exists and
		if $is_verbose ; then
			echo -n "$line "
		fi

		((number_of_files_disk++))
		if [ "`redis-cli get $root:$folder:$line:size`" == "" ] ; then	# there is no index of it in redis
			if $is_verbose ; then
				echo -n "adding "
			fi

			((number_of_files_added++))
			redis-cli set $root:$folder:$line:size "`ls -l --all --size $line | cut --field=6 --delimiter=' '`"
			redis-cli set $root:$folder:$line:md5 "`md5sum $line | cut --field=1 --delimiter=' '`"
		fi
		if $is_verbose ; then
			echo "done"
		fi
	fi
done

number_of_files_datastore=`redis-cli keys "$root:$folder:*:md5" | wc -l`

cd $current_working_directory

echo ""
echo "build:$root/$folder"
echo "         Number of files added: $number_of_files_added"
echo "    Number of that are on disk: $number_of_files_disk"
echo "  Number of files in datastore: $number_of_files_datastore"
