#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
number_of_files_disk=0
number_of_files_size_added=0
number_of_crc_hashes_added=0
number_of_md5_hashes_added=0
number_of_sha1_hashes_added=0
number_of_files_size_not_added=0
number_of_crc_hashes_not_added=0
number_of_md5_hashes_not_added=0
number_of_sha1_hashes_not_added=0

argument_index=0
is_verbose=false
hashing_algorithms=("md5")
for var in "$@"
do
	if [ $argument_index -ge 2 ] ; then
    	if [ "$var" == "--verbose" ] ; then
			is_verbose=true
		fi
		if [[ $var =~ ^--hashing-algorithm ]] ; then
			hashing_algorithm_raw=`echo $var | cut --field=2 --delimiter="="`
			IFS=',' read -ra hashing_algorithms <<< "$hashing_algorithm_raw"
		fi
    fi

    ((argument_index++))
done

cd $path

for line in $(find ./); do
	if [ -f "${line}" ]; then	# if the file exists and
		if $is_verbose; then echo -n "Record $line "; fi

		((number_of_files_disk++))

		if $is_verbose; then echo -n "getting file size"; fi
		if [ "`redis-cli get $root:$folder:$line:size`" == "" ] ; then	# there is no index of it in redis
			redis-cli set $root:$folder:$line:size "`ls -l --all --size $line | cut --field=6 --delimiter=' '`" > /dev/null

			((number_of_files_size_added++))
			if $is_verbose; then echo -n "✓ "; fi
		else
			((number_of_files_size_not_added++))
			if $is_verbose; then echo -n "✗ "; fi
		fi

		if $is_verbose; then echo -n "generating hash(es) "; fi
		for this_hashing_algorithm in "${hashing_algorithms[@]}"; do :
			if $is_verbose; then echo -n "$this_hashing_algorithm"; fi
			if [ "$this_hashing_algorithm" != "crc" ] && [ "$this_hashing_algorithm" != "md5" ] && [ "$this_hashing_algorithm" != "sha1" ] ; then
				if $is_verbose; then echo -n "⚠ "; fi
			else
				if [ "`redis-cli get $root:$folder:$line:$this_hashing_algorithm`" == "" ] ; then	# there is no index of it in redis
					if [ "$this_hashing_algorithm" = "crc" ]; then
						bash_command_prefix="ck";
					else
						bash_command_prefix=$this_hashing_algorithm
					fi
					redis-cli set $root:$folder:$line:$this_hashing_algorithm "`$bash_command_prefix""sum $line | cut --field=1 --delimiter=' '`" > /dev/null

					if [ "$this_hashing_algorithm" == "ck" ]; then ((number_of_crc_hashes_added++)); fi
					if [ "$this_hashing_algorithm" == "md5" ]; then ((number_of_md5_hashes_added++)); fi
					if [ "$this_hashing_algorithm" == "sha1" ]; then ((number_of_sha1_hashes_added++)); fi

					if $is_verbose ; then echo -n "✓ "; fi
				else
					if [ "$this_hashing_algorithm" = "ck" ]; then ((number_of_crc_hashes_not_added++)); fi
					if [ "$this_hashing_algorithm" = "md5" ]; then ((number_of_md5_hashes_not_added++)); fi
					if [ "$this_hashing_algorithm" = "sha1" ]; then ((number_of_sha1_hashes_not_added++)); fi

					if $is_verbose ; then echo -n "✗ "; fi
				fi
			fi
		done
		if $is_verbose ; then
			echo "done"
		fi
	fi
done

cd $current_working_directory

number_of_file_size_datastore=`redis-cli keys "$root:$folder:*:size" | wc -l`
number_of_crc_hashes_datastore=`redis-cli keys "$root:$folder:*:crc" | wc -l`
number_of_md5_hashes_datastore=`redis-cli keys "$root:$folder:*:md5" | wc -l`
number_of_sha1_hashes_datastore=`redis-cli keys "$root:$folder:*:sha1" | wc -l`

echo ""
echo "build:$root/$folder"
echo "            Number of files on disk: $number_of_files_disk"
echo " Number of files sizes in datastore: $number_of_file_size_datastore"
for this_hashing_algorithm in "${hashing_algorithms[@]}"; do :
	if [ "$this_hashing_algorithm" = "crc" ]; then
		echo "         Number of crc hashes added: $number_of_crc_hashes_added"
		echo "     Number of crc hashes not added: $number_of_crc_hashes_not_added"
	fi
	if [ "$this_hashing_algorithm" = "md5" ]; then
		echo "         Number of md5 hashes added: $number_of_md5_hashes_added"
		echo "     Number of md5 hashes not added: $number_of_md5_hashes_not_added"
	fi
	if [ "$this_hashing_algorithm" = "sha1" ]; then
		echo "        Number of sha1 hashes added: $number_of_sha1_hashes_added"
		echo "    Number of sha1 hashes not added: $number_of_sha1_hashes_not_added"
	fi
done
echo "  Number of crc hashes in datastore: $number_of_crc_hashes_datastore"
echo "  Number of md5 hashes in datastore: $number_of_md5_hashes_datastore"
echo " Number of sha1 hashes in datastore: $number_of_sha1_hashes_datastore"
