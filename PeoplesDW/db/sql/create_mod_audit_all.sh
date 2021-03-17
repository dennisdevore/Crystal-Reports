#!/bin/bash

cat create_mod_audit_table_list.txt | while read TABLE_TO_AUDIT
do
  echo ${TABLE_TO_AUDIT}...
  . ./create_mod_audit_table_scripts.sh ${TABLE_TO_AUDIT}
  . ./create_mod_audit_trigger_scripts.sh ${TABLE_TO_AUDIT}
done
