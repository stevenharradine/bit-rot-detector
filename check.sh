#!/bin/bash
current_working_directory=`pwd`

root=$1
folder=$2
path=$root/$folder
md5_path=$current_working_directory/$folder.md5
number_of_files=`cat $current_working_directory/$folder.md5 | wc -l`
temp_file_path=/tmp/$folder

# make sure the temp file exists before trying to write it
if [ -a "${current_working_directory}" ] ; then
	touch $temp_file_path
fi

cd $path
md5sum --check $md5_path 2>&1 | tee $temp_file_path
cd $current_working_directory

number_of_files_ok=`cat $temp_file_path | grep OK | wc -l`
audit_status="fail"

if [ $number_of_files -eq $number_of_files_ok ] ; then
	audit_status="pass"
fi

echo ""
echo "$md5_path"
echo "      Number of files: $number_of_files"
echo "Number of that are OK: $number_of_files_ok"
echo "                Audit: $audit_status"
echo "           Failed log:"
if [ $audit_status == "fail" ] ; then
	cat $temp_file_path | grep -v OK
fi
