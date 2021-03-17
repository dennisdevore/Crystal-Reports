#!/bin/sh

EXPDP_CONTENT=ALL
DUMPFILEPREFIX=`uname -n`_${ORACLE_SID}

cd ..

# setuid on dumps sub-directory so synapse user can access file
chmod g+s dumps

. ./scripts/create_dir_objects.sh
# . ./scripts/create_import_sqlfile.sh 0 0 $EXPDP_CONTENT

expdp ${ALPS_DBLOGON} directory=SYNAPSE_$$_DUMPS dumpfile=${DUMPFILEPREFIX}.dmp exclude=statistics logfile=export_data_only_${DUMPFILEPREFIX}.log content=data_only

cd dumps
gzip ${DUMPFILEPREFIX}.dmp
cd ..

. ./scripts/drop_dir_objects.sh $$

cd scripts
