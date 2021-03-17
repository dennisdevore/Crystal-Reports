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

echo -n "Preparing to IMPORT INTO `uname -n` $ORACLE_SID (y/n)? "
read REPLY
if [ "$REPLY" != "Y" ] && [ "$REPLY" != "y" ]; then
  return
fi

ZIPFILENAME=$(basename $1)
DMPFILENAME=`echo $ZIPFILENAME | rev | cut -c 4- | rev`
FILENAME=`echo $DMPFILENAME | rev | cut -c 5- | rev`

cd ..
sqls @dumps/$FILENAME.sql
. ./scripts/create_facility_dir_objects.sh
. ./scripts/create_import_parfile.sh $FILENAME
gunzip dumps/$ZIPFILENAME
impdp ${ALPS_DBLOGON} parfile=dumps/imp_$FILENAME.par transform=storage:n
. ./scripts/drop_dir_objects.sh $$
gzip dumps/$DMPFILENAME
. ~/sql/start_all_qs.sh
recomp
co
sqls @scripts/import_by_facility_cleanup.sql
cd ~/sql
sqlf start_jobs
start_sys
cd - >/dev/null
