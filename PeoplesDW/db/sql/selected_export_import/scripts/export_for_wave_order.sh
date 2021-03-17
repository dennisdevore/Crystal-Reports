#!/bin/sh

EXPDP_CONTENT=ALL
case $# in
1) ;;
2) EXPDP_CONTENT=$2 ;;
*) echo -e "\nusage: $IAM <wave> <ALL|DATA_ONLY|METADATA_ONLY>\n"
   return ;;
esac

cd ..
# setuid on dumps sub-directory so synapse user can access file
chmod g+s dumps
. ./scripts/create_dir_objects.sh
. ./scripts/check_objects_in_txtfiles.sh
. ./scripts/create_export_parfile_for_wave_order.sh $1 WAVE $EXPDP_CONTENT
. ./scripts/create_import_sqlfile.sh $1 WAVE $EXPDP_CONTENT
expdp ${ALPS_DBLOGON} parfile=dumps/exp_order_$1_WAVE_$EXPDP_CONTENT.par
. ./scripts/drop_dir_objects.sh $$
gzip dumps/exp_order_$1_WAVE_$EXPDP_CONTENT.dmp
cd - >/dev/null

