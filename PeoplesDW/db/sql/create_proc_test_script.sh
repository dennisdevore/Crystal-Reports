#!/bin/bash

IAM=`basename $0`

case $# in
1) ;;
*) echo "\nusage: $IAM <syn.procedure_name>"
   exit ;;
esac

SYN_PROC_IDENTIFIER=`echo ${1} | tr ' ' '_'`
SYN_UPPER=`echo ${1} | tr 'a-z' 'A-Z'`

cat >/tmp/$IAM_run.$$.sql <<EOF
set serveroutput on format wrapped
set feedback off
set heading off
set verify off
set echo off
set term off
set pagesize 0
set trimspool on
spool run_${SYN_PROC_IDENTIFIER}.sql

declare

cursor curArguments(in_package_name varchar2, in_object_name varchar2) is
  select lower(package_name) package_name,
         lower(argument_name) argument_name,
         data_type,
         in_out
    from user_arguments
   where package_name = upper(in_package_name)
     and object_name = upper(in_object_name)
   order by position;

cursor curRealName(in_synonym_name varchar2) is
  select table_name
    from all_synonyms
   where synonym_name = in_synonym_name;
CRN curRealName%rowtype;
   
l_text varchar2(4000);
l_package_name user_arguments.package_name%type;
l_col_total pls_integer;
l_col_count pls_integer;
l_object_name user_arguments.object_name%type;
l_real_name user_objects.object_name%type;
l_synonym_name  user_objects.object_name%type;
l_pos pls_integer;
l_len pls_integer;
l_param varchar2(4000);

begin

dbms_output.enable(1000000);

l_synonym_name := substr('${SYN_UPPER}',1,instr('${SYN_UPPER}','.')-1); 

CRN := null;
open curRealName(l_synonym_name);
fetch curRealName into CRN;
close curRealName;
if CRN.table_name is null then
  dbms_output.put_line('Synonym not found: ' || l_synonym_name);
  return;
end if;

l_object_name := substr('${SYN_UPPER}',instr('${SYN_UPPER}','.')+1);

dbms_output.put_line('set serveroutput on');
dbms_output.put_line('');
dbms_output.put_line('declare');

l_col_count := 0;
l_col_total := 0;

for x in curArguments(CRN.table_name,l_object_name)
loop
  l_text := x.argument_name || ' ';
  if x.data_type in ('VARCHAR2','CHAR') then
    l_text := l_text || 'varchar2(4000);';
  elsif x.data_type = 'DATE' then
    l_text := 'date;';
  else
    l_text := l_text || 'number;';
  end if;
  dbms_output.put_line(l_text);
  l_col_total := l_col_total + 1;
end loop;

dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');

l_col_count := 0;
l_package_name := null;

for x in curArguments(CRN.table_name,l_object_name)
loop
  if x.data_type in ('VARCHAR2','CHAR') then
    l_param := '''''';
  elsif x.data_type = 'DATE' then
    l_param := 'to_date(''' ||
               to_char(sysdate, 'yyyymmddhh24miss') ||
               ''', ''yyyymmddhh24miss'')'';';
  else
    l_param := '0';
  end if;
  l_text := x.argument_name || ' := ' || l_param || ';';
  dbms_output.put_line(l_text);
end loop;

dbms_output.put_line('');
dbms_output.put_line('zut.prt(''execute ' || l_object_name || ''');');
dbms_output.put_line('');

l_text := l_synonym_name || '.' || l_object_name || '(';
dbms_output.put_line(l_text);

l_col_count := 0;

for x in curArguments(CRN.table_name,l_object_name)
loop
  if (l_col_count > 0) and
     (l_col_count <> l_col_total) then
    dbms_output.put_line(',');
  end if;
  l_col_count := l_col_count + 1;
  l_text := x.argument_name;
  dbms_output.put(l_text);
  if (l_col_count = l_col_total) then
    dbms_output.put_line(');');
  end if;
end loop;

dbms_output.put_line('');

for x in curArguments(CRN.table_name,l_object_name)
loop
  if instr(x.in_out,'OUT') <> 0 then
    l_text := 'zut.prt(''' || 
               x.argument_name || ' is >'' || ' || 
               x.argument_name || ' || ''<'');';          
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line('');
dbms_output.put_line('zut.prt(''(remember to commit or rollback)'');');
dbms_output.put_line('');

dbms_output.put_line('exception when others then');
dbms_output.put_line('  dbms_output.put_line(''others...'');');
dbms_output.put_line('  dbms_output.put_line(sqlerrm);');
dbms_output.put_line('  rollback;');
dbms_output.put_line('end;');
dbms_output.put_line('/');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM_run.$$.sql
# rm /tmp/$IAM_run.$$.sql
