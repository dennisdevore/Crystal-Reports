#!/bin/sh

# setuid on dumps sub-directory so synapse user can access file
. ./create_objects.sh
. ./populate_temp_tables.sh
sqls @filter_by_custid_user_facility.sql
. ./drop_objects.sh $$
