#!/bin/sh

INCREMENTAL=N
NEED_FACILITY=Y
NEED_CUSTOMER=Y
EXPDP_CONTENT=ALL
case $# in
2) ;;
3) INCREMENTAL=$3 ;;
4) NEED_FACILITY=$4 ;;
5) NEED_CUSTOMER=$5 ;;
6) EXPDP_CONTENT=$6 ;;
*) echo -e "\nusage: $IAM <facility_list> <customer_list> <incremental?> <need fac data?> <need cust data?> <ALL|DATA_ONLY|METADATA_ONLY\n"
   return ;;
esac

FACILITIES=`echo $1 |  sed 's/,/_/g'`

cd ..
# setuid on dumps sub-directory so synapse user can access file
chmod g+s dumps
. ./scripts/create_facility_customer_dir_objects.sh
. ./scripts/check_facility_customer_objects_in_txtfiles.sh
. ./scripts/create_export_parfile_for_facility_customer.sh $1 $2 $INCREMENTAL $NEED_FACILITY $NEED_CUSTOMER $EXPDP_CONTENT
. ./scripts/create_facility_customer_import_sqlfile.sh $FACILITIES $EXPDP_CONTENT
expdp ${ALPS_DBLOGON} parfile=dumps/exp_fac_cust_${FACILITIES}_${EXPDP_CONTENT}.par
. ./scripts/drop_dir_objects.sh $$
gzip dumps/exp_fac_cust_${FACILITIES}_${EXPDP_CONTENT}.dmp
cd - >/dev/null

