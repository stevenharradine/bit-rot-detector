#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
number_of_files_ok=0
number_of_files_disk=0
error_untracked_file_counter=0
error_log=""
error_md5_match_flag=true

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
			if [ "$hashing_algorithm" == "crc" ] ; then
				hashing_algorithm_bash_prefix="ck"
			else
				hashing_algorithm_bash_prefix=$hashing_algorithm
			fi
		fi
    fi

    ((argument_index++))
done

cd $path

number_of_files_datastore=`redis-cli keys "$root:$folder:*:$hashing_algorithm" | wc -l`
files=`redis-cli keys "$root:$folder:*:$hashing_algorithm" | cut --field=3 --delimiter=:`

for line in $files; do
	if $is_verbose ; then
		echo -n "$line "
	fi

	# do the md5 hashs match
	md5_on_record=`redis-cli get "$root:$folder:$line:$hashing_algorithm"`
	md5_current="`$hashing_algorithm_bash_prefix""sum $line | cut --field=1 --delimiter=' '`"
	if [[ $md5_current != $md5_on_record ]] ; then
		if $is_verbose ; then
			echo "$hashing_algorithm mismatch $md5_on_record $md5_current"
		fi
		error_log+="$hashing_algorithm does not match $line $md5_on_record $md5_current\n"
		error_md5_match_flag=false
	else
		if $is_verbose ; then
			echo "OK"
		fi
		((number_of_files_ok++))
	fi
done

# count number of files on disk
if $is_verbose ; then
	echo "Counting files on disk"
fi
for line in $(find ./); do
	if [ -f "${line}" ] ; then
		if $is_verbose ; then
			echo -n "$line "
		fi
		((number_of_files_disk++))
		md5="`redis-cli get "$root:$folder:$line:$hashing_algorithm"`"
		if [ "$md5" == "" ] ; then
			if $is_verbose ; then
				echo "Untracked"
			fi
			((error_untracked_file_counter++))
			error_log+="untracked file $line\n"
		else
			if $is_verbose ; then
				echo "OK"
			fi
		fi
	fi
done

audit_status="fail"
if [ $number_of_files_datastore -eq $number_of_files_disk ] && [ $number_of_files_datastore -eq $number_of_files_ok ] ; then
	audit_status="pass"
fi

cd $current_working_directory

echo ""
echo "$root/$folder"
echo "  Number of files in datastore: $number_of_files_datastore"
echo "   Number of files that are OK: $number_of_files_ok"
echo "    Number of that are on disk: $number_of_files_disk"
echo "Files on disk not in datastore: $error_untracked_file_counter"
echo "                         Audit: $audit_status"
if [ $audit_status == "fail" ] ; then
	echo "                  Failed log:"
	echo -e "$error_log"
fi
