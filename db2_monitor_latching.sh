https://github.com/dgodson/db2-scripts

#!/bin/ksh

#Base script for data collection. 
#Adapted form the monitoring script @ https://www-01.ibm.com/support/docview.wss?uid=swg22005477

#The absolute path where this script resides
SCRIPT_PATH=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

# The absolute path where the diagnostic data will be stored (default to the script path)
DATA_STAGING_PATH="${SCRIPT_PATH}"

# Get the first argument passed in (the database name)

SCRIPT_NAME='default_script.sh'
DBNAME=$1
LOOP_COUNTER=$2
LOOP_INTERVAL=$3
COLLECTION_ROUND=1
COLLECTION_MAX=$LOOP_COUNTER

#Get DB2 versions
db2_version=`db2level | grep "DB2 v" | awk '{print $5}' | sed 's/[^0-9\.]//g' | cut -c1-2`

#Check if all arguements are passed in via script call
if [ -z "$DBNAME" ]
	then
   		echo Specify a database '<SID>' to connect to
   		echo Script should be called as: $SCRIPT_NAME '<SID>' '<COUNTER>' '<INTERVAL>'
   		exit 1
elif [ -z "$LOOP_COUNTER" ]
	then
		echo Specify a counter 
		echo Script should be called as: $SCRIPT_NAME '<SID>' '<COUNTER>' '<INTERVAL>'
		exit 1
elif [ -z "$LOOP_INTERVAL" ]
	then
		echo Specify an interval
		echo Script should be called as: $SCRIPT_NAME '<SID>' '<COUNTER>' '<INTERVAL>'
		exit 1
fi

# Determine some values of the host system
h=`hostname`
OSname=`/bin/uname`
Username=`whoami`
db2sysc_pid=`db2pd -edus | awk '/db2sysc PID/ {print $3}'`

# Create a folder for unique day, and change-directory into this folder.
date_mmddyy=$(/bin/date +'%m%d%y')
folder_for_todays_data="${DATA_STAGING_PATH}/DB2_dataCollection_${DBNAME}.${date_mmddyy}"
if [ ! -d ${folder_for_todays_data} ]; then
  mkdir -p ${folder_for_todays_data}
fi
cd ${folder_for_todays_data}

#create folder for storing OS informations
folder_for_OS_data="${folder_for_todays_data}/OS_data"
if [ ! -d ${folder_for_OS_data} ]; then
  mkdir -p ${folder_for_OS_data}
fi

#create folder for storing db2pd informations
folder_for_db2pd_data="${folder_for_todays_data}/db2pd_data"
if [ ! -d ${folder_for_db2pd_data} ]; then
  mkdir -p ${folder_for_db2pd_data}
fi

#create folder for storing general db informations
folder_for_generalDB_data="${folder_for_todays_data}/generalDB_data"
if [ ! -d ${folder_for_generalDB_data} ]; then
  mkdir -p ${folder_for_generalDB_data}
fi

db2 connect to $DBNAME >> connect.$DBNAME.$(date "+%Y%m%d.%H%M%S").txt;

while [ $LOOP_COUNTER != 0 ] 
do 
	current_time=$(date +%Y_%m_%d_%H_%M_%S)

	echo '\n'
	echo Data Collection - Round: $COLLECTION_ROUND of $COLLECTION_MAX
	echo '--------------------------------------------------------------'

	#-----------------------------------------------------------------------------------
	# Collect OS information (AIX/LINUX)
	echo 'Phase 1 of 3: Collecting OS data'
	cd ${folder_for_OS_data}
	folder_for_OS_data_current_time="${folder_for_OS_data}/OS_data.${current_time}"
	if [ ! -d ${folder_for_OS_data_current_time} ]; then
	   mkdir -p ${folder_for_OS_data_current_time}
	fi
	cd ${folder_for_OS_data_current_time}

	if [[ $OSname == "AIX" ]]; then
	  # (AIX flavour)
	  db2pd -osinfo -file db2pd_osinfo.$(date "+%Y%m%d.%H%M%S").txt > /dev/null
	  vmstat -ltw 1 10  > OS_vmstat.$(date "+%Y%m%d.%H%M%S").txt &
	else
	  # (LINUX flavour)
	  db2pd -osinfo -file db2pd_osinfo.$(date "+%Y%m%d.%H%M%S").txt > /dev/null
	  vmstat -at 1 10  > OS_vmstat.$(date "+%Y%m%d.%H%M%S").txt &
	fi

	#-------------------------------------------------------------------------------------------------
	# Collect db2pd data
	echo 'Phase 2 of 3: Collecting db2pd data'
	cd ${folder_for_db2pd_data}
	folder_for_db2pd_data_current_time="${folder_for_db2pd_data}/db2pd_data.${current_time}"
	if [ ! -d ${folder_for_db2pd_data_current_time} ]; then
	   mkdir -p ${folder_for_db2pd_data_current_time}
	fi
	cd ${folder_for_db2pd_data_current_time}

	db2pd -latches -alldbpartitionnums -file db2pd_latches.$(date "+%Y%m%d.%H%M%S").txt > /dev/null
	db2pd -edus -alldbpartitionnums -file db2pd_edus.$(date "+%Y%m%d.%H%M%S").txt > /dev/null
	db2pd -db $DBNAME -app -agents -alldbpartitionnums -file db2pd_app_agents.$(date "+%Y%m%d.%H%M%S").txt > /dev/null
	db2pd -db $DBNAME -buff -file db2pd_buffer_pool.$(date "+%Y%m%d.%H%M%S").txt > /dev/null

	   
	#------------------------------------------------------------------------------------------------
	# Collect additional data specific to specific issue

	echo 'Phase 3 of 3: Collecting Monitoring & Additional data'
	cd ${folder_for_generalDB_data}
	folder_for_generalDB_data_current_time="${folder_for_generalDB_data}/generalDB_data.${current_time}"
	if [ ! -d ${folder_for_generalDB_data_current_time} ]; then
	    mkdir -p ${folder_for_generalDB_data_current_time}
	fi
	cd ${folder_for_generalDB_data_current_time}

	#SNAPSHOT DATA

	db2 get snapshot for applications on $DBNAME > SNAP_app.$(date "+%Y%m%d.%H%M%S").txt &
	db2 get snapshot for database on $DBNAME > SNAP_db.$(date "+%Y%m%d.%H%M%S").txt &

	#MONITORING DATA

	db2 "select current timestamp as collection_timestamp, substr(latch_name,1,70) as latch_name, total_extended_latch_waits as num_waits, total_extended_latch_wait_time as wait_time from table(mon_get_extended_latch_wait(-2)) as t order by wait_time desc" > MON_ext_latch_wait.$(date "+%Y%m%d.%H%M%S").txt &
	
	#MON_GET_LATCH only Db2 v11
	if [[ $db2_version = "11" ]]; then
		db2 "select substr(latch_name,1,40) as LATCH_NAME, edu_id, substr(edu_name,1,20) as EDU_NAME, application_handle, latch_status, latch_wait_time from table(mon_get_latch(null, -2)) order by latch_wait_time" > MON_get_latch.$(date "+%Y%m%d.%H%M%S").txt &
	else
		db2 "select application_handle, total_extended_latch_waits, total_extended_latch_wait_time from table(mon_get_activity(1, -2)) order by total_extended_latch_wait_time" > MON_get_activity.$(date "+%Y%m%d.%H%M%S").txt &
	fi
	
	#ADDITIONAL DATA
	echo Sleeping for: $LOOP_INTERVAL seconds
	sleep $LOOP_INTERVAL
	LOOP_COUNTER=`expr $LOOP_COUNTER - 1`
	COLLECTION_ROUND=`expr $COLLECTION_ROUND + 1`

done

db2 connect reset >> connect_reset.$DBNAME.$(date "+%Y%m%d.%H%M%S").txt;

cd ${SCRIPT_PATH}
tar cvf DB2_dataCollection.tar DB2_dataCollection_${DBNAME}.${date_mmddyy}; gzip DB2_dataCollection.tar
rm -r ${folder_for_todays_data}
#end script
