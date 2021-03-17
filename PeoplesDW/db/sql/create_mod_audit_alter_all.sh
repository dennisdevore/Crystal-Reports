#!/bin/bash

cat create_mod_audit_table_list.txt | while read TABLE_TO_AUDIT
do
  echo ${TABLE_TO_AUDIT}...
  . ./create_mod_audit_alter_scripts.sh ${TABLE_TO_AUDIT}
  . ./create_mod_audit_trigger_scripts.sh ${TABLE_TO_AUDIT}
done

cat create_mod_audit_table_list.txt | while read TABLE_TO_AUDIT
do
  SIZE=`stat -c %s ${TABLE_TO_AUDIT}_mod_alter.sql`
  if [ $SIZE -eq 49 ]; then 
    rm ${TABLE_TO_AUDIT}_mod_alter.sql
	rm ${TABLE_TO_AUDIT}_mod_trigger.sql
  fi
done
