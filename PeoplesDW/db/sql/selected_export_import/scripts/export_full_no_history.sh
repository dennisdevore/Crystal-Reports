#!/bin/sh

EXPDP_CONTENT=ALL
case $# in
0) ;;
1) EXPDP_CONTENT=$1 ;;
*) echo -e "\nusage: $IAM <ALL|DATA_ONLY|METADATA_ONLY\n"
   return ;;
esac

cd ..
# setuid on dumps sub-directory so synapse user can access file
chmod g+s dumps
. ./scripts/create_dir_objects.sh
. ./scripts/check_objects_in_txtfiles.sh
. ./scripts/create_export_parfile_for_no_history.sh full no_history $EXPDP_CONTENT
. ./scripts/create_import_sqlfile.sh 0 0 $EXPDP_CONTENT
expdp ${ALPS_DBLOGON} parfile=dumps/exp_full_no_history_$EXPDP_CONTENT.par
. ./scripts/drop_dir_objects.sh $$
gzip dumps/exp_full_no_history_$EXPDP_CONTENT.dmp
cd - >/dev/null

