#!/bin/sh

EXPDP_CONTENT=ALL
case $# in
1) ;;
2) EXPDP_CONTENT=$2 ;;
*) echo -e "\nusage: $IAM <facility_list> <ALL|DATA_ONLY|METADATA_ONLY\n"
   return ;;
esac

FACILITIES=`echo $1 |  sed 's/,/_/g'`

cd ..
# setuid on dumps sub-directory so synapse user can access file
chmod g+s dumps
. ./scripts/create_facility_dir_objects.sh
. ./scripts/check_facility_objects_in_txtfiles.sh
. ./scripts/create_export_parfile_for_facility.sh $1 $EXPDP_CONTENT
. ./scripts/create_facility_import_sqlfile.sh $FACILITIES $EXPDP_CONTENT
expdp ${ALPS_DBLOGON} parfile=dumps/exp_facility_${FACILITIES}_${EXPDP_CONTENT}.par
. ./scripts/drop_dir_objects.sh $$
gzip dumps/exp_facility_${FACILITIES}_${EXPDP_CONTENT}.dmp
cd - >/dev/null

