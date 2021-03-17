#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM table_name\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on feedback off verify off heading off linesize 1000
spool $1_audit_trigger.sql

prompt create or replace trigger audit#$1
prompt after update on $1
prompt for each row
prompt begin

declare
	cursor c_idx is
  		select index_name
         from user_indexes
   		where table_name = upper('$1')
           and uniqueness = 'UNIQUE'
           and index_name not like 'SYS_%';
	cursor c_col(p_idx_name varchar2) is
  		select lower(column_name) as column_name
         from user_ind_columns
   		where index_name = p_idx_name
   		order by column_position;
   cursor c_aud is
      select lower(column_name) as column_name
         from user_tab_columns
         where table_name = upper('$1')
           and column_name not in ('LASTUSER','LASTUPDATE')
           and (data_type = 'DATE'
             or data_type = 'NUMBER'
             or data_type like '%CHAR%')
       order by lower(column_name);
   l_origin varchar2(1000) := null;
   l_cnt pls_integer;
begin
   dbms_output.enable(1000000);

   select count(1) into l_cnt
      from user_tab_columns
      where table_name = upper('$1')
        and column_name = 'LASTUSER';
   if l_cnt = 0 then
      raise_application_error(-20001, 'Table $1 has no lastuser column');
   end if;

	for idx in c_idx loop
      l_origin := null;
		for col in c_col(idx.index_name) loop
         if c_col%rowcount = 1 then
            l_origin := ''''||col.column_name||'=''||:new.'||col.column_name;
         else
            l_origin := l_origin||'||''|'||col.column_name||'=''||:new.'||col.column_name;
         end if;
		end loop;
      exit;
	end loop;

   if l_origin is null then
      raise_application_error(-20002, 'Table $1 has no unique key');
   end if;

   for aud in c_aud loop
      dbms_output.put_line('    zaud.check_val(''$1'', ''' || aud.column_name
          || ''', :new.lastuser'
          || ', :new.' || aud.column_name
          || ', :old.' || aud.column_name
          || ', ' || l_origin || ');');
   end loop;
end;
/
prompt end;;
prompt /
prompt show error trigger audit#$1;;
prompt exit;;
exit
EOF
sqlplus $ALPS_DBLOGON @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
sqlplus $ALPS_DBLOGON @$1_audit_trigger


