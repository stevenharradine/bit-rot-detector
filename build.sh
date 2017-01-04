#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
number_of_files_disk=0
number_of_files_added=0

argument_index=0
is_verbose=false
hashing_algorithm=md5
hashing_algorithm_bash_prefix=md5
for var in "$@"
do
	if [ $argument_index -ge 2 ] ; then
    	if [ "$var" == "--verbose" ] ; then
			is_verbose=true
		fi
		if [[ $var =~ ^--hashing-algorithm ]] ; then
			hashing_algorithm=`echo $var | cut --field=2 --delimiter="="`
			if [ "$hashing_algorithm" = "crc" ] ; then
				hashing_algorithm_bash_prefix="ck"
			else
				hashing_algorithm_bash_prefix="$hashing_algorithm"
			fi
			if [ "$hashing_algorithm" != "crc" ] && [ "$hashing_algorithm" != "md5" ] && [ "$hashing_algorithm" != "sha1" ] ; then
				echo "Error: invalid hashing-algorithm $hashing_algorithm, should be a comma delimited list of 'crc', 'md5', and/or 'sha1'"
				exit
			fi
		fi
    fi

    ((argument_index++))
done

cd $path

for line in $(find ./); do
	if [ -f "${line}" ] ; then	# if the file exists and
		if $is_verbose ; then
			echo -n "$line "
		fi

		((number_of_files_disk++))
		if [ "`redis-cli get $root:$folder:$line:$hashing_algorithm`" == "" ] ; then	# there is no index of it in redis
			if $is_verbose ; then
				echo -n "adding "
			fi

			((number_of_files_added++))
			redis-cli set $root:$folder:$line:size "`ls -l --all --size $line | cut --field=6 --delimiter=' '`"
			redis-cli set $root:$folder:$line:$hashing_algorithm "`$hashing_algorithm_bash_prefix""sum $line | cut --field=1 --delimiter=' '`"
		fi
		if $is_verbose ; then
			echo "done"
		fi
	fi
done

number_of_files_datastore=`redis-cli keys "$root:$folder:*:$hashing_algorithm" | wc -l`

cd $current_working_directory

echo ""
echo "build:$root/$folder"
echo "         Number of files added: $number_of_files_added"
echo "    Number of that are on disk: $number_of_files_disk"
echo "  Number of files in datastore: $number_of_files_datastore"
