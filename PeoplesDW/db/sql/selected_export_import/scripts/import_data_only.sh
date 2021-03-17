#!/bin/sh

case $# in
1) ;;
*) echo -e "\nusage: $IAM <dumpfilename>\n"
   return ;;
esac

if [ ! -f $1 ] && [ ! -f ../dumps/$1 ]; then
  echo File not found: $1
  return
fi

FULLFILENAME=${1}
TEMPFILENAME=${FULLFILENAME##*/}
DUMPFILEPREFIX=`echo ${TEMPFILENAME%%.*}`

echo -n "Preparing to IMPORT INTO `uname -n` $ORACLE_SID (y/n)? "
read REPLY
if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]; then
  return
fi

cd ../dumps
gunzip ${DUMPFILEPREFIX}.dmp.gz
cd ..

. ./scripts/create_dir_objects.sh
chmod 755 ./scripts/disable_all_triggers.sh
./scripts/disable_all_triggers.sh

# sqls @dumps/exp_order_0_0_ALL.sql

impdp ${ALPS_DBLOGON} directory=SYNAPSE_$$_DUMPS dumpfile=${DUMPFILEPREFIX}.dmp logfile=import_data_only_`uname -n`_${ORACLE_SID}.log transform=storage:n,segment_attributes:n content=data_only table_exists_action=append

chmod 755 ./scripts/enable_all_triggers.sh
./scripts/enable_all_triggers.sh

gzip dumps/${DUMPFILEPREFIX}.dmp

. ./scripts/drop_dir_objects.sh $$

#. ~/sql/start_all_qs.sh
#recomp
#co
#cd ~/sql
#sqlf start_jobs
#start_sys
cd - >/dev/null
