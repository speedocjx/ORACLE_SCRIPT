#!/bin/bash
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/11.2.0.4/db_1
LD_LIBRARY_PATH=${ORACLE_HOME}/lib
MYPATH=`pwd`

temp_path="/u01/app/oracle/oradata"
path1=${temp_path//\//\\/}

TEMPLATE_CONTROLFILE_PATH1=${path1}
TEMPLATE_ONLINELOG_PATH1=${path1}
TEMPLATE_DATAFILE_PATH=${path1}

TEMPLATE_CONTROLFILE_PATH2=""
TEMPLATE_ONLINELOG_PATH2=""

TEMPLATE_DBNAME="TEST1"
TEMPLATE_MEMORYTARGET=450
TEMPLATE_LOG_SIZE=100
TEMPLATE_LOGGROUP_SIZE=4
PASSWORD="123456"

TEMPLATE_GDB="${TEMPLATE_DBNAME}.HAHAHA.COM"

# COPY an template file to modify
############################################################################
cp ${MYPATH}/TEMPLATE.dbt ${MYPATH}/${TEMPLATE_DBNAME}.dbt

#modify redo group size 
############################################################################
if [[ ${TEMPLATE_LOGGROUP_SIZE}>5 || ${TEMPLATE_LOGGROUP_SIZE}<3 ]]; then
    echo -e "6 logfile groups\n"
else 
    numlines=$[7*$[6-${TEMPLATE_LOGGROUP_SIZE}]]
    #echo $numlines
    beginline=`awk "/<RedoLogGroupAttributes id=\"$[${TEMPLATE_LOGGROUP_SIZE}+1]\"/ {print NR}" ${MYPATH}/${TEMPLATE_DBNAME}.dbt`
    endline=$[ ${beginline}+${numlines}-1 ]
    #echo $endline
    sed -i "${beginline},${endline}"d ${MYPATH}/${TEMPLATE_DBNAME}.dbt
fi


if [ ${TEMPLATE_ONLINELOG_PATH2} =='' ]; then
    sed -i '/TEMPLATE_ONLINELOG_PATH2/d' ${MYPATH}/${TEMPLATE_DBNAME}.dbt
else
    sed -i "s/TEMPLATE_ONLINELOG_PATH2/${TEMPLATE_ONLINELOG_PATH2}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
fi


if [ ${TEMPLATE_CONTROLFILE_PATH2} =='' ]; then
    sed -i "s/TEMPLATE_CONTROLFILE_PATH2/${TEMPLATE_CONTROLFILE_PATH1}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
else
    sed -i "s/TEMPLATE_CONTROLFILE_PATH2/${TEMPLATE_CONTROLFILE_PATH2}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
fi


sed -i "s/TEMPLATE_CONTROLFILE_PATH1/${TEMPLATE_CONTROLFILE_PATH1}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
sed -i "s/TEMPLATE_DATAFILE_PATH/${TEMPLATE_DATAFILE_PATH}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
sed -i "s/TEMPLATE_ONLINELOG_PATH1/${TEMPLATE_ONLINELOG_PATH1}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
sed -i "s/TEMPLATE_MEMORYTARGET/${TEMPLATE_MEMORYTARGET}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
sed -i "s/TEMPLATE_DBNAME/${TEMPLATE_DBNAME}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt
sed -i "s/TEMPLATE_LOG_SIZE/${TEMPLATE_LOG_SIZE}/" ${MYPATH}/${TEMPLATE_DBNAME}.dbt


dbca -silent -createDatabase -templateName ${MYPATH}/${TEMPLATE_DBNAME}.dbt  -gdbName ${TEMPLATE_GDB} -sysPassword ${PASSWORD} -systemPassword ${PASSWORD} >${MYPATH}/${TEMPLATE_DBNAME}_CREATE.LOG
logfile=`cat ${MYPATH}/${TEMPLATE_DBNAME}_CREATE.LOG |grep cfgtoollogs|awk -F '"' '{print $2}'`

if [[ `cat ${MYPATH}/${TEMPLATE_DBNAME}_CREATE.LOG|grep "100%"|wc -l` -eq 1 && `cat ${logfile}|grep ORA-|wc -l` -eq 0 ]]; then 
    echo "CREATE DATABASE ${TEMPLATE_DBNAME} SUCCESS!\n logfile in ${logfile}"
    
else
    echo -e "ERROR!SEE LOGFILE ${logfile}"
fi 




#dbca -silent -deleteDatabase -sourceDB ${TEMPLATE_DBNAME}
