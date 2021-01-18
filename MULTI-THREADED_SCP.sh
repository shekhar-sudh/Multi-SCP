#!/bin/bash
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Name:    MULTI-THREADED_SCP.sh
# Version: 3.2
# Purpose: This script is used to perform SCP of multiple files in parallel using provided number of threads at a time
# Author:  Sudhanshu Shekhar
# Support: sudhanshu.cusat@gmail.com
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Change history:
#   Feb 19, 2018, version 1.0, Initial thought flow and development, basic version on scribe.
#   Feb 20, 2018, version 1.1, Re-designed & public version developed.
#	Feb 21, 2018, version 2.0, Added error traps for parent & child SCP processes.
#	Feb 22, 2018, version 2.1, Added basic HTML based formatting for output.
#	Feb 23, 2018, version 3.0, Added HTML & CSS based formatting for output.
#	Feb 24, 2018, version 3.1, Fixed RC table, added more error traps, fixed output format issues.
#	Feb 26, 2018, version 3.2, Added Throughput, Data transfer & Time in processing.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Current Script version
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
script_version=3.2
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Email recipients
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mailreceiver=sudhanshu.cusat@gmail.com
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Set Global Variables for the script & its functions
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SCRIPT_NAME=${0}
DIR_SOURCE=${1}
TARGET_USER=${2}
TARGET_HOST=${3}
DIR_TARGET=${4}
PARALLEL_THREADS=${5}
FILE_PATTERN=${6}
NUMBER_INPUTS="$#"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function: script_help()
# Purpose: provide a detailed usage instruction to the user
script_help()
{
	#clear
    echo ""
    echo "NAME:"
    echo "	MULTI-THREADED_SCP.sh"
    echo ""
    echo "DESCRIPTION:"
    echo "	This script is used to perform SCP of multiple files in parallel using provided number of threads at a time."
    echo ""
    echo "PREREQUISITE TO USE THIS SCRIPT:"
    echo "1. Configure 'SSH with No Password' between the Source & the Target servers."
    echo "2. Execute this script on the Source server where you have the files present currently."
    echo ""
	echo ""
    echo "GENERAL SYNTAX:::"
    echo "MULTI-THREADED_SCP.sh <DIR_SOURCE> <TARGET_USER> <TARGET_HOST> <DIR_TARGET> <PARALLEL_THREADS> <FILE_PATTERN>"
    echo ""
    echo "DIR_SOURCE::"
    echo " 	Provide the source directory for all files, make sure to have / at the end. e.g. - /Backup/SIDP/"
    echo "TARGET_USER::"
    echo "	Provide the TARGET_USER at the target host with which you have the password-less SSH setup"
    echo "TARGET_HOST:"
    echo "	Provide the fully qualified domain name of the target host"
    echo "DIR_TARGET::"
	echo "	WARNING ::: DO NOT USE /home or the root directory /, if you fill it up, your server might go down WARNING ::: "
    echo "	Provide the directory name at the target host where you would like the files transferred, make sure to have / at the end. e.g. - /Backup/SIDQ/ "
	echo "	Make sure that you have appropriate write permission on the directory"
    echo "PARALLEL_THREADS::"
    echo "	Provide the no. of parallel scp threads you would like to run on the source server"
	echo "	Try to be cautious of the available no. of CPUs at your source server, please don't choke it"
	echo "FILE_PATTERN::"
    echo "	Provide a pattern for searching the relevant files in your source directory"
	echo "	If you want all the files, no need to provide any pattern"
    echo ""
	echo ""
    echo "SCRIPT USAGE_EXAMPLE :::::::"
    echo "	MULTI-THREADED_SCP.sh /Backup/SIDP/ myuser siddbq001.example.com /Backup/SIDQ/ 10 SIDPIQDB_FULL"
    echo ""
	echo ""
    echo "OPTIONS:"
    echo "        -help               - for displaying the script help page "
    echo "        -h                  - for displaying the script help page "
    echo "        -version            - for displaying the script version information "
    echo "        -v                  - for displaying the script version information "
    echo "        -usage              - for displaying the script help page "
    echo ""
    echo "SUPPORT CONTACT:"
    echo "sudhanshu.cusat@gmail.com "
    echo ""
    exit 0
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function: script_version()
# Purpose: Script version page display
script_version()
{
    #clear
    echo ""
    echo "Current Version $script_version"
    echo ""
    echo " Change history:"
    echo "	Feb 19, 2018, version 1.0, Initial thought flow and development, basic version on scribe."
    echo "	Feb 20, 2018, version 1.1, Re-designed & public version developed."
	echo "	Feb 21, 2018, version 2.0, Added error traps for parent & child SCP processes."
	echo "	Feb 22, 2018, version 2.1, Added basic HTML based formatting for output."
	echo "	Feb 23, 2018, version 3.0, Added HTML & CSS based formatting for output."
	echo "	Feb 24, 2018, version 3.1, Fixed RC table, added more error traps, fixed output format issues."
	echo "	Feb 26, 2018, version 3.2, Added Throughput, Data transfer & Time in processing."
    exit 0
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function: script_verify_ssh()
# Purpose: Check if the 'SSH with No Password' between the Source & the Target servers is configured or not.
script_verify_ssh()
{
    echo "Checking for 'SSH' between the Source & the Target servers. Please wait.. "
    echo ""
    sleep 3

	#set the local variable counter & RC
	counter=1
    RC=0

	#check ssh from source to target server
    ssh -q -oBatchMode=yes -o StrictHostKeyChecking=no ${TARGET_USER}@${TARGET_HOST} uname > /dev/null 2>&1

	if [ `echo "$?"` -eq 0 ]
       then
	  echo "`whoami`@`hostname` to ${TARGET_USER}@${TARGET_HOST} : SSH is working "
          RC=$(( $RC +0 ))
       else
	  echo "`whoami`@`hostname` to ${TARGET_USER}@${TARGET_HOST} : SSH is not working"
          RC=$(( $RC +1 ))
       fi
       counter=$(( $counter + 1 ))

    if [ ${RC} -eq 0 ]
    then
       #echo "SSH is configured correctly between SAP hosts listed in the 'saphosts' file "
	   echo "Calling the secure copy function now"
	   echo ""
	   echo ""
	   echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	   echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	   perform_secure_copy
       echo ""
       exit 0
    else
       echo ""
       echo "Sorry, SSH is not configured between the Source & the Target servers."
       echo ""
       echo "Try once again after configuring SSH..Please check help page for more information ( $MY_NAME -help ) "
       echo ""
       exit 1
    fi
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Function: rename_logs_for_deletion()
#
# Purpose: Rename all the intermediate logs & mark them for deletion
#
rename_logs_for_deletion()
{
		#Rename all the log files for deletion
		mv ${COPY_START_LOG} ${COPY_START_LOG}.multiscp.deleteme
		mv ${COPY_FINISH_LOG} ${COPY_FINISH_LOG}.multiscp.deleteme
		mv ${SCP_CHILD_STATUS_LOG} ${SCP_CHILD_STATUS_LOG}.multiscp.deleteme
		mv ${SCP_PARENT_STATUS_LOG} ${SCP_PARENT_STATUS_LOG}.multiscp.deleteme
		mv ${SCP_STATUS_PASTED_LOG} ${SCP_STATUS_PASTED_LOG}.multiscp.deleteme
		mv ${FILE_LIST_FINISHED_LOG} ${FILE_LIST_FINISHED_LOG}.multiscp.deleteme
		mv ${COPY_START_LOG}.html ${COPY_START_LOG}.html.multiscp.deleteme
		mv ${COPY_FINISH_LOG}.html ${COPY_FINISH_LOG}.html.multiscp.deleteme
		mv ${SCP_STATUS_PASTED_LOG}.html ${SCP_STATUS_PASTED_LOG}.html.multiscp.deleteme
		mv ${SCP_STATUS_PASTED_LOG_HEADER}.html ${SCP_STATUS_PASTED_LOG_HEADER}.html.multiscp.deleteme
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function: perform_secure_copy()
# Purpose: Start performing the secure copy of files from the source to the target server.
perform_secure_copy()
{
    echo "Starting the secure copy (SCP) of files now. Please wait.. "
    echo ""
    sleep 3

	# Generate the Count of Files to be Transferred.
	FILE_COUNT="`ls ${DIR_SOURCE}*${FILE_PATTERN}* | wc -l`"

	# Throw warning and help info if no matching files found
	if [ ${FILE_COUNT} -eq 0 ] ; then
	echo ":: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR ::"
	echo "Dude!!! You do not have any matching files for SCP, check the provided pattern again "
	echo "Please see the help/usage information of the script again"
	script_help
	fi

	# Generate the List of Files to be Transferred.
	FILE_LIST="`ls ${DIR_SOURCE}*${FILE_PATTERN}*`"

	# Set the script log location and all the log files
	#LOG_LOC=${DIR_SOURCE}
	LOG_LOC="`pwd`/"
	COPY_START_LOG=${LOG_LOC}scp_start_log
	COPY_FINISH_LOG=${LOG_LOC}scp_finish_log
	SCP_CHILD_STATUS_LOG=${LOG_LOC}scp_child_processes_status_log
	SCP_PARENT_STATUS_LOG=${LOG_LOC}scp_parent_processes_status_log
	SCP_STATUS_PASTED_LOG=${LOG_LOC}scp_combined_status_log
	FILE_LIST_FINISHED_LOG=${LOG_LOC}scp_filelist_finished_log
	SCP_STATUS_PASTED_LOG_HEADER=${LOG_LOC}scp_pasted_log_header_log

	#Remove the old log files if any
	rm -f ${LOG_LOC}*.multiscp.deleteme
	#rm -f ${COPY_START_LOG}.multiscp.deleteme ${COPY_FINISH_LOG}.multiscp.deleteme ${SCP_CHILD_STATUS_LOG}.multiscp.deleteme ${SCP_STATUS_PASTED_LOG}.multiscp.deleteme
	#rm -f ${SCP_PARENT_STATUS_LOG}.multiscp.deleteme ${COPY_START_LOG}.html.multiscp.deleteme ${COPY_FINISH_LOG}.html.multiscp.deleteme ${SCP_STATUS_PASTED_LOG}.html.multiscp.deleteme
	#rm -f ${FILE_LIST_FINISHED_LOG}.multiscp.deleteme ${SCP_STATUS_PASTED_LOG_HEADER}.html.multiscp.deleteme

	# Script log location
		echo "This script is writing log files here - ${LOG_LOC}"
		echo ""
	# Set the SCP command
	scp_command="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet"

	#set the local variable counter
	counter=0
	RC=0

	#Remove any old scp status file"
	rm -f ${SCP_CHILD_STATUS_LOG} > /dev/null 2>&1

	# Set PARALLEL_THREADS = FILE_COUNT, if user sets PARALLEL_THREADS more than FILE_COUNT
	if [ ${PARALLEL_THREADS} -gt ${FILE_COUNT} ] ; then
	echo ""
	echo "You have only ${FILE_COUNT} files for SCP, hence resetting PARALLEL_THREADS to ${FILE_COUNT} "
	echo ""
	PARALLEL_THREADS=${FILE_COUNT}
	fi

	# Calculate the amount of data to be transferred in GB
	DATA_MB="`find ${DIR_SOURCE} -name "*${FILE_PATTERN}*" -ls | awk '{totalMB += $7 /1024 /1024} END {print totalMB}'`"
	echo ""
	echo "Total data to be transferred to ${TARGET_HOST} in MB = ${DATA_MB}"
	echo ""
	DATA_MB_INTEGER="${DATA_MB%.*}"

	# Set the timeticker now, to calculate the duration of SCP jobs in second
	SECONDS=0

	# Start the File Copy Process Now & Watch for the Child Jobs
	for FiletoCopy in ${FILE_LIST}; do
		echo "Begin the secure copy process (SCP) of the files: " ${FiletoCopy}
		# Start the Background jobs for the SCP commands
		(
		  echo "SCP_Begin `date +"%T"` ${FiletoCopy}" >> ${COPY_START_LOG}
		  # Start the child SCP commands & read status of each SCP command
		  scp_status=0

		  ${scp_command} -pq ${FiletoCopy} ${TARGET_USER}@${TARGET_HOST}:${DIR_TARGET} || scp_status=$?
		  echo " ${scp_status} " >> ${SCP_CHILD_STATUS_LOG}
		  sleep 2
		  echo "SCP_Ended `date +"%T"` ${FiletoCopy}" >> ${COPY_FINISH_LOG}
		  echo "${FiletoCopy}" >> ${FILE_LIST_FINISHED_LOG}
		) &
		# Set the counter for limiting the SCP threads to run in parallel
		counter=$(( $counter + 1 ))

		# Start setting the counter as per the PARALLEL_THREADS
		if [ ${counter} -eq ${PARALLEL_THREADS} ] ; then

			# Start the Background job watch for the parent jobs for the SCP commands :: ERROR-TRAP
			scp_parent_status=0
			for job in `jobs -p`; do
				echo "Parent Background Job PID ${job} Started"
				#wait ${job} || let "RC+=1"
				wait ${job} || scp_parent_status=$?
				echo " ${scp_parent_status} " >> ${SCP_PARENT_STATUS_LOG}
				echo "Parent Background Job PID ${job} has Return Code ${scp_parent_status}"
			done
			wait

		#Reset the counter to 1 now
		counter=1
		fi
	done
	wait
	# Compare number of exit codes for parent with child jobs & append for missing counts if any
		PARENT_SCP_RC_COUNT="`cat ${SCP_PARENT_STATUS_LOG} | wc -l`"
		CHILD_SCP_RC_COUNT="`cat ${SCP_CHILD_STATUS_LOG} | wc -l`"

		echo "Finding out if we captured all the RCs for parent & child SCP processes"
		echo "....."
		echo "....."
		if [ ${PARENT_SCP_RC_COUNT} -eq ${CHILD_SCP_RC_COUNT} ] ; then
		echo "Looks like we captured all the RCs for all Child & Parent SCP processes. "
		echo "Proceeding ahead now...."

		elif [ ${PARENT_SCP_RC_COUNT} -le ${CHILD_SCP_RC_COUNT} ] ; then
		PARENT_CHILD_COUNT_DIFF="`expr ${CHILD_SCP_RC_COUNT} - ${PARENT_SCP_RC_COUNT}`"
		echo "Looks like we could not capture RCs for ${PARENT_CHILD_COUNT_DIFF} parent SCP processes."
		echo "Lets fill up 00 in place of the un-captured RCs of the parent SCP processes."
			for ((i=1;i<=${PARENT_CHILD_COUNT_DIFF}; i++))
			do
			echo "00" >> ${SCP_PARENT_STATUS_LOG}
			done
		echo "Filling done, Proceeding ahead now...."
		fi

	# Verify the status of the parent SCP command, looking for exit codes other than 0 :: ERROR-TRAP
		PARENT_SCP_RC="`grep -v "0" ${SCP_PARENT_STATUS_LOG} | wc -l`"
		echo ""
		echo "Parent SCP Background Job Return Code is ${PARENT_SCP_RC}, Non-Zero code means failure"
		echo ""
	# Verify the status of the child SCP commands, looking for exit codes other than 0 :: ERROR-TRAP
		SCP_RC="`grep -v "0" ${SCP_CHILD_STATUS_LOG} | wc -l`"
		echo "Child SCP Background Job Return Code is ${SCP_RC}, Non-Zero code means failure"
		echo ""
	# Wait for last peocess to complete
	wait

	# Set the timeticker now, to calculate the duration of SCP jobs in second
	timeticker=${SECONDS}
	echo ""
	echo "Total time taken by the SCP processes is ${timeticker} seconds."

	# Data Transfer throughput calculation
	THROUGHPUT="`echo $((DATA_MB_INTEGER / timeticker))`"

	echo ""
	echo "Total Throughput Performance in this SCP transfer activity was ${THROUGHPUT} MB/Second."
	echo ""

	#Index with numbering the SCP_CHILD_STATUS_LOG file
		awk '{printf "%s\t%s\n",NR,$0}' ${SCP_CHILD_STATUS_LOG} > ${SCP_CHILD_STATUS_LOG}.tmp
		mv ${SCP_CHILD_STATUS_LOG}.tmp ${SCP_CHILD_STATUS_LOG}

	#Indexing & File Header with numbering the COPY_START_LOG file
		awk '{printf "%s\t%s\n",NR,$0}' ${COPY_START_LOG} > ${COPY_START_LOG}.tmp
		mv ${COPY_START_LOG}.tmp ${COPY_START_LOG}

		echo "Index SCP-Operation Timings File-Details" >> ${COPY_START_LOG}.tmp2
		cat ${COPY_START_LOG}.tmp2 ${COPY_START_LOG} >> ${COPY_START_LOG}.tmp3
		mv ${COPY_START_LOG}.tmp3  ${COPY_START_LOG}
		rm -f ${COPY_START_LOG}.tmp2

	#Indexing & File Header with numbering the COPY_FINISH_LOG file
		awk '{printf "%s\t%s\n",NR,$0}' ${COPY_FINISH_LOG} > ${COPY_FINISH_LOG}.tmp
		mv ${COPY_FINISH_LOG}.tmp ${COPY_FINISH_LOG}

		echo "Index SCP-Operation Timings File-Details" >> ${COPY_FINISH_LOG}.tmp2
		cat ${COPY_FINISH_LOG}.tmp2 ${COPY_FINISH_LOG} >> ${COPY_FINISH_LOG}.tmp3
		mv ${COPY_FINISH_LOG}.tmp3  ${COPY_FINISH_LOG}
		rm -f ${COPY_FINISH_LOG}.tmp2

	# Change the start & finish logs pattern to html format now -
		awk 'BEGIN {print "<table class=\"blueTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${COPY_START_LOG} >> ${COPY_START_LOG}.html

		awk 'BEGIN {print "<table class=\"blueTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${COPY_FINISH_LOG} >> ${COPY_FINISH_LOG}.html

	# Remove any old final html file
		rm -f ${LOG_LOC}multithreaded_scp_final_log.html

	# Prepare the multithreaded_scp_final_log.html file with CSS style
		echo "<style type="text/css">
				table.blueTable {
				  border: 1px solid #1C6EA4;
				  background-color: #EEEEEE;
				  width: 60%;
				  text-align: center;
				  border-collapse: collapse;
				}
				table.blueTable td, table.blueTable th {
				  border: 1px solid #AAAAAA;
				  padding: 3px 2px;
				}
				table.blueTable tbody td {
				  font-size: 13px;
				}
				table.blueTable tr:nth-child(even) {
				  background: #D0E4F5;
				}
				table.blueTable tfoot td {
				  font-size: 14px;
				}
				table.blueTable tfoot .links {
				  text-align: right;
				}
				table.blueTable tfoot .links a{
				  display: inline-block;
				  background: #1C6EA4;
				  color: #FFFFFF;
				  padding: 2px 8px;
				  border-radius: 5px;
				}
				</style>" > ${LOG_LOC}multithreaded_scp_final_log.html
		#echo "<address style="display:block\;color:Red\;text-align:right\;font-size:100%\;font-style:normal\;">Hey guys, see a bug!! <br> Report Here - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${LOG_LOC}multithreaded_scp_final_log.html
		echo "<h1 style="color:blue\;text-align:left\;font-size:150%\;"><u>Result Summary - Multithreaded SCP Activity [`hostname`] </u></h1>" >> ${LOG_LOC}multithreaded_scp_final_log.html
		echo "<table><tr><td><br>  <br></td></tr></table>" >> ${LOG_LOC}multithreaded_scp_final_log.html
		echo "<table><tr><td><p style="color:Blue\;"> <u><b>SCP-FileDetails-Operation-Timings-TABLE<br><br></b></u></p></td></tr></table>" >> ${LOG_LOC}multithreaded_scp_final_log.html

	# Merge the start & finish html logs to generate the final html file
		cat ${COPY_START_LOG}.html ${COPY_FINISH_LOG}.html >> ${LOG_LOC}multithreaded_scp_final_log.html

	# Prepare the header log file for the SCP Parent Child Return Codes with CSS style
		echo "<style type="text/css">
				table.redTable {
				  border: 3px solid #A40808;
				  background-color: #EEE7DB;
				  width: 60%;
				  text-align: center;
				  border-collapse: collapse;
				}
				table.redTable td, table.redTable th {
				  border: 1px solid #AAAAAA;
				  padding: 3px 2px;
				}
				table.redTable tbody td {
				  font-size: 13px;
				}
				table.redTable tr:nth-child(even) {
				  background: #F5C8BF;
				}
				table.redTable tfoot td {
				  font-size: 13px;
				}
				table.redTable tfoot .links {
				  text-align: right;
				}
				table.redTable tfoot .links a{
				  display: inline-block;
				  background: #FFFFFF;
				  color: #A40808;
				  padding: 2px 8px;
				  border-radius: 5px;
				}
				</style>" > ${SCP_STATUS_PASTED_LOG_HEADER}.html
		echo "<table><tr><td><p style="color:Blue\;"><b><u><br>SCP-Parent-Child-Return-Codes-TABLE</u></b></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		echo "<table><tr><td><p style="color:Blue\;"> <u><b>Note </b></u> - Verify & Retry SCP for the files with RC other than 0 or 00 as per the table below. <br> <br></p></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html


	# Append EXTRA notes for user if Child SCP process has failed
		if [ ${FILE_COUNT} -gt ${CHILD_SCP_RC_COUNT} ] ; then
		echo "<table><tr><td><p style="color:Blue\;"> <b><u>Data-Transfer-Info</u></b><br>Total Data Transferred = ${DATA_MB} MB.<br>Total Time Taken = ${timeticker} seconds.<br> Total Throughput = ${THROUGHPUT} MB per second.<br></p></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		echo "<table><tr><td><p style="color:Red\;"> <u><b>ALERT - FileCountMismatch</b></u><br>You had a total of ${FILE_COUNT} files for transfer. Looks like only ${CHILD_SCP_RC_COUNT} files were transferred. You must verify the return codes & perform SCP for failed or missing files.</p></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		else
		echo "<table><tr><td><p style="color:Blue\;"> <b><u>Data-Transfer-Info</u></b><br>Total Data Transferred = ${DATA_MB} MB.<br>Total Time Taken = ${timeticker} seconds.<br>Total Throughput = ${THROUGHPUT} MB per second.<br></p></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		echo "<table><tr><td><p style="color:Green\;"> <u><b>FileCountMatch</b></u><br>You had a total of ${FILE_COUNT} files for transfer & all ${CHILD_SCP_RC_COUNT} files were transferred, just double check the return codes now.<br></p></td></tr></table>" >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		fi

	# Verify the return codes & send mail with the log file as confirmation
	if [ ${PARENT_SCP_RC} -eq 0 ] && [ ${SCP_RC} -eq 0 ] ; then
		#Prepare the Log for Parent & Child SCP Process Return Codes
		echo "Index CHILD_RCs PARENT_RCs FILE-Detail" >> ${SCP_STATUS_PASTED_LOG}
		paste ${SCP_CHILD_STATUS_LOG} ${SCP_PARENT_STATUS_LOG} ${FILE_LIST_FINISHED_LOG} >> ${SCP_STATUS_PASTED_LOG}

		# Change the logs pattern to html format now
		awk 'BEGIN {print "<table class=\"redTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${SCP_STATUS_PASTED_LOG} > ${SCP_STATUS_PASTED_LOG}.html

		# Report Bugs to the developer
		echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${SCP_STATUS_PASTED_LOG}.html

		cat ${SCP_STATUS_PASTED_LOG}.html >> ${SCP_STATUS_PASTED_LOG_HEADER}.html
		#Merge the HTML Log for Child SCP Process Return Code to the final log file
		cat ${SCP_STATUS_PASTED_LOG_HEADER}.html >> ${LOG_LOC}multithreaded_scp_final_log.html
	   (
	   echo "To: ${mailreceiver}"
	   echo "MIME-Version: 1.0"
	   echo "Subject: SUCCESS - Multi-threaded SCP Process Has Completed For File Pattern ${DIR_SOURCE}${FILE_PATTERN}"
	   echo "Content-Type: text/html"
	   cat ${LOG_LOC}multithreaded_scp_final_log.html
	   ) | sendmail -t
		#Mark logs for deletion now
		rename_logs_for_deletion

	elif [ ${PARENT_SCP_RC} -eq 0 ] && [ ${SCP_RC} -ne 0 ] ; then
		#Prepare the Log for Parent & Child SCP Process Return Codes
		echo "Index CHILD_RCs PARENT_RCs FILE-Detail" >> ${SCP_STATUS_PASTED_LOG}
		paste ${SCP_CHILD_STATUS_LOG} ${SCP_PARENT_STATUS_LOG} ${FILE_LIST_FINISHED_LOG} >> ${SCP_STATUS_PASTED_LOG}

		# Change the logs pattern to html format now
		awk 'BEGIN {print "<table class=\"redTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${SCP_STATUS_PASTED_LOG} > ${SCP_STATUS_PASTED_LOG}.html
		# Report Bugs to the developer
		echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${SCP_STATUS_PASTED_LOG}.html

		cat ${SCP_STATUS_PASTED_LOG}.html >> ${SCP_STATUS_PASTED_LOG_HEADER}.html

		#Merge the HTML Log for Child SCP Process Return Code to the final log file
		cat ${SCP_STATUS_PASTED_LOG_HEADER}.html >> ${LOG_LOC}multithreaded_scp_final_log.html
	   	(
		echo "To: ${mailreceiver}"
		echo "MIME-Version: 1.0"
		echo "Subject: FAILURE in Multi-threaded SCP - Child SCP Process Had Issues, Check Mail Log for More Info - !!Needs Action!!"
		echo "Content-Type: text/html"
		cat ${LOG_LOC}multithreaded_scp_final_log.html
		) | sendmail -t
		#Mark logs for deletion now
		rename_logs_for_deletion

	elif [ ${PARENT_SCP_RC} -ne 0 ] && [ ${SCP_RC} -eq 0 ] ; then
		#Prepare the Log for Parent & Child SCP Process Return Codes
		echo "Index CHILD_RCs PARENT_RCs FILE-Detail" >> ${SCP_STATUS_PASTED_LOG}
		paste ${SCP_CHILD_STATUS_LOG} ${SCP_PARENT_STATUS_LOG} ${FILE_LIST_FINISHED_LOG} >> ${SCP_STATUS_PASTED_LOG}

		# Change the logs pattern to html format now
		awk 'BEGIN {print "<table class=\"redTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${SCP_STATUS_PASTED_LOG} > ${SCP_STATUS_PASTED_LOG}.html
		# Report Bugs to the developer
		echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${SCP_STATUS_PASTED_LOG}.html

		cat ${SCP_STATUS_PASTED_LOG}.html >> ${SCP_STATUS_PASTED_LOG_HEADER}.html

		#Merge the HTML Log for Child SCP Process Return Code to the final log file
		cat ${SCP_STATUS_PASTED_LOG_HEADER}.html >> ${LOG_LOC}multithreaded_scp_final_log.html
	   	(
		echo "To: ${mailreceiver}"
		echo "MIME-Version: 1.0"
		echo "Subject: FAILURE in Multi-threaded SCP - Child SCP Process Had Issues, Check Mail Log for More Info - !!Needs Action!!"
		echo "Content-Type: text/html"
		cat ${LOG_LOC}multithreaded_scp_final_log.html
		) | sendmail -t
		#Mark logs for deletion now
		rename_logs_for_deletion

	elif [ ${PARENT_SCP_RC} -ne 0 ] && [ ${SCP_RC} -ne 0 ] ; then
		#Prepare the Log for Parent & Child SCP Process Return Codes
		echo "Index CHILD_RCs PARENT_RCs FILE-Detail" >> ${SCP_STATUS_PASTED_LOG}
		paste ${SCP_CHILD_STATUS_LOG} ${SCP_PARENT_STATUS_LOG} ${FILE_LIST_FINISHED_LOG} >> ${SCP_STATUS_PASTED_LOG}

		# Change the logs pattern to html format now
		awk 'BEGIN {print "<table class=\"redTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${SCP_STATUS_PASTED_LOG} > ${SCP_STATUS_PASTED_LOG}.html
		# Report Bugs to the developer
		echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${SCP_STATUS_PASTED_LOG}.html

		cat ${SCP_STATUS_PASTED_LOG}.html >> ${SCP_STATUS_PASTED_LOG_HEADER}.html

		#Merge the HTML Log for Child SCP Process Return Code to the final log file
		cat ${SCP_STATUS_PASTED_LOG_HEADER}.html >> ${LOG_LOC}multithreaded_scp_final_log.html
	   	(
		echo "To: ${mailreceiver}"
		echo "MIME-Version: 1.0"
		echo "Subject: FAILURE in Multi-threaded SCP - Parent & Child Both SCP Processes Had Issues, Check Mail Log for More Info - !!Needs Action!!"
		echo "Content-Type: text/html"
		cat ${LOG_LOC}multithreaded_scp_final_log.html
		) | sendmail -t
		#Mark logs for deletion now
		rename_logs_for_deletion

    else
		#Prepare the Log for Parent & Child SCP Process Return Codes
		#Prepare the Log for Parent & Child SCP Process Return Codes
		echo "Index CHILD_RCs PARENT_RCs FILE-Detail" >> ${SCP_STATUS_PASTED_LOG}
		paste ${SCP_CHILD_STATUS_LOG} ${SCP_PARENT_STATUS_LOG} ${FILE_LIST_FINISHED_LOG} >> ${SCP_STATUS_PASTED_LOG}

		# Change the logs pattern to html format now
		awk 'BEGIN {print "<table class=\"redTable\">" "<tbody>"} {print "<tr>"; for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"} END {print "<tbody>" "</table>"}' ${SCP_STATUS_PASTED_LOG} > ${SCP_STATUS_PASTED_LOG}.html
		# Report Bugs to the developer
		echo "<address style="display:block\;color:Red\;text-align:left\;font-size:100%\;font-style:italic\;"> <br> Report Bugs - <a href="mailto:sudhanshu.cusat@gmail.com">Support</a></address>" >> ${SCP_STATUS_PASTED_LOG}.html

		cat ${SCP_STATUS_PASTED_LOG}.html >> ${SCP_STATUS_PASTED_LOG_HEADER}.html

		#Merge the HTML Log for Child SCP Process Return Code to the final log file
		cat ${SCP_STATUS_PASTED_LOG_HEADER}.html >> ${LOG_LOC}multithreaded_scp_final_log.html
	   	(
		echo "To: ${mailreceiver}"
		echo "MIME-Version: 1.0"
		echo "Subject: FAILURE in Multi-threaded SCP - Failure was undetermined, Cleanup & Rerun The Script, Report This Scenario to Support Contact"
		echo "Content-Type: text/html"
		cat ${LOG_LOC}multithreaded_scp_final_log.html
		) | sendmail -t
		#Mark logs for deletion now
		rename_logs_for_deletion

    fi
exit 0
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function: script_input_check()
# Purpose: Script input check
script_input_check()
{
echo "Time stamp: `date`"
echo ""
echo "MULTI-THREADED SCP SCRIPT"
echo ""
echo "You have entered: ${SCRIPT_NAME} ${DIR_SOURCE} ${TARGET_USER} ${TARGET_HOST} ${DIR_TARGET} ${PARALLEL_THREADS} ${FILE_PATTERN} "
echo ""
   if [ "${NUMBER_INPUTS}" -eq 5 ] || [ "${NUMBER_INPUTS}" -eq 6 ] ;then
		# Verify if the user input for DIR_TARGET starts with "/" :: ERROR-TRAP
			if [[ ${DIR_TARGET} == /*/ ]] && [[ ${DIR_TARGET} != /home* ]] ; then
				DIR_TARGET_INPUT_RC=0
			else
				DIR_TARGET_INPUT_RC=1
			fi
		# Verify if the user input for PARALLEL_THREADS is a numeric value :: ERROR-TRAP
			egrep -e "^[0-9]+$" <<< ${PARALLEL_THREADS}
			#PARALLEL_THREADS_INPUT_RC="`echo $?`"
			PARALLEL_THREADS_INPUT_RC="$?"

		# Proceed with SSH setup verification if inputs for DIR_TARGET & PARALLEL_THREADS look good :: ERROR-TRAP
			if [ "${PARALLEL_THREADS_INPUT_RC}" -eq 0 ] && [ "${DIR_TARGET_INPUT_RC}" -eq 0 ] ; then
				echo "Checked your input for DIR_TARGET & it seems to start with a /* & is not the /home/* , proceeding..."
				echo "Checked your input for PARALLEL_THREADS & it seems to be of correct numeric type, proceeding..."
				echo ""
				# Call the function for SSH verify
				script_verify_ssh
			else
				echo ""
				echo ""
				echo ":: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR ::"
				echo "Check your DIR_TARGET & PARALLEL_THREADS inputs again"
				# Call the function for script help
				script_help
			fi
   else
	echo ""
	echo ""
	echo ":: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR :: ERROR ::"
	echo "Check the inputs you provided to the script again and retry"
	script_help
   fi
}
# END OF FUNCTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Main Body of the Script

# Script running options
case ${DIR_SOURCE} in
	-help)                   script_help                                 ;;
	-version)                script_version                              ;;
	-h)                      script_help                                 ;;
	-v)                      script_version                              ;;
	*)                       script_input_check                          ;;
esac
#End of Main Body of the Script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
