#!/bin/bash

IAM=mod_trigger

case $# in
1) ;;
*) echo "\nusage: $IAM <table_name>"
   exit ;;
esac

UPPER_PARM_01=`echo ${1} | tr 'a-z' 'A-Z'`
LOWER_PARM_01=`echo ${1} | tr 'A-Z' 'a-z'`

cat >/tmp/$IAM_sql.$$.sql <<EOF
set serveroutput on format wrapped;
set heading off;
set verify off;
set echo off;
set term off;
set pagesize 0;
set linesize 32000;
set trimspool on;
spool ${LOWER_PARM_01}_mod_trigger.sql


declare

type exclude_col_record_type is record
(table_name user_tables.table_name%type
,column_name user_tab_columns.column_name%type
);

type exclude_col_table_type is table of exclude_col_record_type
     index by pls_integer;
ECT exclude_col_table_type;
ectx pls_integer;

l_excluded_column boolean;
l_column_name varchar2(4000);
l_data_type varchar2(255);
l_col_count pls_integer;
l_ind_col_count pls_integer;
l_index_name varchar2(255);
l_table_name varchar2(255);
l_table_name_old varchar2(255);
l_table_name_new varchar2(255);
l_table_name_parm varchar2(255);
l_trigger_name varchar2(255);
l_unique_index_count pls_integer;
l_object_suffix varchar2(4);
l_unique_index_col_count pls_integer;
l_loop_count pls_integer;
l_if_needed boolean;
l_sql varchar2(4000);

begin

dbms_output.enable(1000000);

l_table_name_parm := '${UPPER_PARM_01}';

ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'LPCOUNT';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'PICKCOUNT';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'DROPCOUNT';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'LASTPICKEDFROM';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'LASTPUTAWAYTO';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'LASTRANKED';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'PICKRANK';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'PUTAWAYRANK';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'STATUS';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'USERHEADER';
ECT(ectx).column_name := 'CLEANLOGOUT';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'ITEMPICKFRONTS';
ECT(ectx).column_name := 'LASTPICKEDDATE';
ectx := ECT.count + 1;
ECT(ectx).table_name := 'LOCATION';
ECT(ectx).column_name := 'USED_UOS';

l_table_name_old := zaud.table_name(l_table_name_parm || '_OLD');

l_table_name_new := zaud.table_name(l_table_name_parm || '_NEW');

l_trigger_name := zaud.table_name(l_table_name_parm || '_MOD_UPD');
dbms_output.put_line('create or replace trigger ' || l_trigger_name);
dbms_output.put_line('after update ' || ' on ' ||
  l_table_name_parm);
dbms_output.put_line('for each row');
dbms_output.put_line('declare');
dbms_output.put_line('ms number(10);');
dbms_output.put_line('mti date;');
dbms_output.put_line('mty char(1);');
dbms_output.put_line('mg varchar2(255);');
dbms_output.put_line('o ' || l_table_name_parm || '%rowtype;');
dbms_output.put_line('n ' || l_table_name_parm || '%rowtype;');
dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');
dbms_output.put_line('mti := sysdate;');
dbms_output.put_line('');
l_if_needed := True;
for utc in (select column_name,data_type
            from user_tab_columns
           where table_name = l_table_name_parm
           order by column_name)
loop

  l_excluded_column := False;
  if (utc.column_name = 'LASTUSER') or
     (utc.column_name = 'LASTUPDATE') then
    l_excluded_column := True;
  else
    for ectx in 1..ECT.count
    loop
      if l_table_name_parm = ECT(ectx).table_name and
         utc.column_name = ECT(ectx).column_name then
        l_excluded_column := True;
        exit;
      end if;
    end loop;
  end if;
  if not l_excluded_column then
    if l_if_needed then
      l_sql := l_sql || 'if';
      l_if_needed := False;
    else
      l_sql := l_sql || 'and';
    end if;
    if utc.data_type = 'BLOB' then
      l_sql := l_sql ||' nvl(length(:old.' || utc.column_name || '),0)';
      l_sql := l_sql || ' = nvl(length(:new.' || utc.column_name || '),0) ';
    else
      l_sql := l_sql || ' nvl(:old.' || utc.column_name || ',';
      if utc.data_type in ('FLOAT','NUMBER') then
        l_sql := l_sql || '0';
      elsif utc.data_type in ('DATE','TIMESTAMP(6)','TIMESTAMP(9)') then
        l_sql := l_sql || 'mti';
      else
        l_sql := l_sql || '''x''';
      end if;
      l_sql := l_sql || ') = nvl(:new.' || utc.column_name || ',';
      if utc.data_type in ('FLOAT','NUMBER') then
        l_sql := l_sql || '0';
      elsif utc.data_type in ('DATE','TIMESTAMP(6)','TIMESTAMP(9)') then
        l_sql := l_sql || 'mti';
      else
        l_sql := l_sql || '''x''';
      end if;
      l_sql := l_sql || ')';
    end if;
    dbms_output.put_line(l_sql);
    l_sql := '';
  end if;
  
end loop;
dbms_output.put_line('then');
dbms_output.put_line('  return;');
dbms_output.put_line('end if;');
dbms_output.put_line('');

dbms_output.put_line('o := null;');
dbms_output.put_line('n := null;');
dbms_output.put_line('zaud.get_next_modseq(''' ||
  l_table_name_old || ''',''' || l_table_name_new ||
  ''',ms,mg);');
dbms_output.put_line(' mty := ''U'';');
dbms_output.put_line('');

for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
             order by column_name)
loop

  begin
    select count(1)
      into l_unique_index_col_count
      from user_indexes ui, user_ind_columns uc 
     where ui.table_name = l_table_name_parm
       and ui.table_name = uc.table_name
       and ui.index_name = uc.index_name
       and uc.column_name = utc.column_name
       and ui.uniqueness = 'UNIQUE';
  exception when others then
    l_unique_index_col_count := 0;
  end;

  if (l_unique_index_col_count != 0) or
     (utc.column_name = 'LASTUSER') or
     (utc.column_name = 'LASTUPDATE') then
    dbms_output.put_line('n.' || utc.column_name || ' := :new.' ||
      utc.column_name || ';');
    dbms_output.put_line('o.' || utc.column_name || ' := :old.' ||
      utc.column_name || ';');
  else
    if utc.data_type = 'BLOB' then
      l_sql := 'if nvl(length(:old.' || utc.column_name || '),0) ';
      l_sql := l_sql || '!= nvl(length(:new.' || utc.column_name || '),0) then';
    else
      l_sql := 'if nvl(:old.' || utc.column_name || ',';
      if utc.data_type in ('FLOAT','NUMBER') then
        l_sql := l_sql || '0';
      elsif utc.data_type in ('DATE','TIMESTAMP(6)','TIMESTAMP(9)') then
        l_sql := l_sql || 'mti';
      else
        l_sql := l_sql || '''x''';
      end if;
      l_sql := l_sql || ') != nvl(:new.' || utc.column_name || ',';
      if utc.data_type in ('FLOAT','NUMBER') then
        l_sql := l_sql || '0';
      elsif utc.data_type in ('DATE','TIMESTAMP(6)','TIMESTAMP(9)') then
        l_sql := l_sql || 'mti';
      else
        l_sql := l_sql || '''x''';
      end if;
      l_sql := l_sql || ') then';
    end if;
    dbms_output.put_line(l_sql);
    dbms_output.put_line('o.' || utc.column_name || ' := :old.' ||
      utc.column_name || ';');
    dbms_output.put_line('n.' || utc.column_name || ' := :new.' ||
      utc.column_name || ';');
    dbms_output.put_line('end if;');
  end if;
  
end loop;

dbms_output.put_line('insert into ' || l_table_name_old);
dbms_output.put_line('(MOD_SEQ,MOD_TABLE_NAME,MOD_TYPE,MOD_TIME');
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',' || utc.column_name);
end loop;

dbms_output.put_line(') values');
dbms_output.put_line('(ms,''' || l_table_name_parm ||
  ''',mty,mti');

for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',o.' || utc.column_name);
end loop;

dbms_output.put_line(');');

l_col_count := 0;
dbms_output.put_line('insert into ' || l_table_name_new);
dbms_output.put_line('(MOD_SEQ,MOD_TABLE_NAME,MOD_TYPE,MOD_TIME');
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',' || utc.column_name);
end loop;

dbms_output.put_line(') values');
dbms_output.put_line('(ms,''' || l_table_name_parm ||
  ''',mty,mti');


l_col_count := 0;
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',n.' || utc.column_name);
end loop;

dbms_output.put_line(');');

dbms_output.put_line('');
dbms_output.put_line('end;');
dbms_output.put_line('/');
l_trigger_name := zaud.table_name(l_table_name_parm || '_MOD_INS');
dbms_output.put_line('create or replace trigger ' || l_trigger_name);
dbms_output.put_line('after insert ' || ' on ' ||
  l_table_name_parm);
dbms_output.put_line('for each row');
dbms_output.put_line('declare');
dbms_output.put_line('ms number(10);');
dbms_output.put_line('mti date;');
dbms_output.put_line('mty char(1);');
dbms_output.put_line('mg varchar2(255);');
dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');
dbms_output.put_line('mti := sysdate;');
dbms_output.put_line('');
dbms_output.put_line('zaud.get_next_modseq(''' ||
  l_table_name_old || ''',''' || l_table_name_new ||
  ''',ms,mg);');
dbms_output.put_line(' mty := ''I'';');
dbms_output.put_line('');

dbms_output.put_line('insert into ' || l_table_name_new);
dbms_output.put_line('(MOD_SEQ,MOD_TABLE_NAME,MOD_TYPE,MOD_TIME');
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',' || utc.column_name);
end loop;

dbms_output.put_line(') values');
dbms_output.put_line('(ms,''' || l_table_name_parm ||
  ''',mty,mti');


l_col_count := 0;
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',:new.' || utc.column_name);
end loop;

dbms_output.put_line(');');

dbms_output.put_line('');
dbms_output.put_line('end;');
dbms_output.put_line('/');

l_trigger_name := zaud.table_name(l_table_name_parm || '_MOD_DEL');
dbms_output.put_line('create or replace trigger ' || l_trigger_name);
dbms_output.put_line('after delete ' || ' on ' ||
  l_table_name_parm);
dbms_output.put_line('for each row');
dbms_output.put_line('declare');
dbms_output.put_line('ms number(10);');
dbms_output.put_line('mti date;');
dbms_output.put_line('mty char(1);');
dbms_output.put_line('mg varchar2(255);');
dbms_output.put_line('o ' || l_table_name_parm || '%rowtype;');
dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');
dbms_output.put_line('mti := sysdate;');
dbms_output.put_line('');
dbms_output.put_line('zaud.get_next_modseq(''' ||
  l_table_name_old || ''',''' || l_table_name_new ||
  ''',ms,mg);');
dbms_output.put_line(' mty := ''D'';');
dbms_output.put_line('');

dbms_output.put_line('insert into ' || l_table_name_old);
dbms_output.put_line('(MOD_SEQ,MOD_TABLE_NAME,MOD_TYPE,MOD_TIME');
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',' || utc.column_name);
end loop;

dbms_output.put_line(') values');
dbms_output.put_line('(ms,''' || l_table_name_parm ||
  ''',mty,mti');

l_col_count := 0;
for utc in (select column_name,data_type
              from user_tab_columns
             where table_name = l_table_name_parm
               and column_name not in ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME')
             order by column_name)
loop
  dbms_output.put_line(',:old.' || utc.column_name);
end loop;

dbms_output.put_line(');');

dbms_output.put_line('');
dbms_output.put_line('end;');
dbms_output.put_line('/');

dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
exit;
spool off;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM_sql.$$.sql
rm /tmp/$IAM_sql.$$.sql
