--
-- $Id$
--
set serveroutput on;
set heading off;
set verify off;
set echo off;
set term off;
set pagesize 0;
set trimspool on;
spool CUSTITEMddl.sql

declare

cursor curColumns is
  select *
    from user_tab_columns
   where table_name = 'CUSTITEM'
   order by table_name,column_id;

strPrevTableName varchar2(255);
strColumnName varchar2(255);
strDataType varchar2(255);
strNullClause varchar2(255);
begin

dbms_output.enable(1000000);

strPrevTableName := '(none)';

for x in curColumns
loop
  if strPrevTableName <> x.table_name then
    if strPrevTableName <> '(none)' then
      dbms_output.put_line(');');
    end if;
    dbms_output.put_line('create table ' || x.table_name || ' ');
  end if;
  strColumnName := x.column_name;
  strDataType := x.data_type;
  if x.data_type in ('NUMBER') then
    strDataType := strDataType || '(' || x.data_precision;
    if x.data_scale <> 0 then
      strDataType := strDataType || ',' || x.data_scale;
    end if;
    strDataType := strDataType || ')';
  end if;
  if x.data_type in ('CHAR','VARCHAR2') then
    strDataType := strDataType || '(' || x.data_length;
    strDataType := strDataType || ')';
  end if;
  if x.nullable = 'N' then
    strNullClause := 'not null';
  else
    strNullClause := null;
  end if;
  if strPrevTableName <> x.table_name then
    strPrevTableName := x.table_name;
    strColumnName := '(' || strColumnName;
  else
    strColumnName := ',' || strColumnName;
  end if;
  if strNullClause is not null then
    dbms_output.put_line(strColumnName || ' ' || strDataType || ' ' || strNullClause);
  else
    dbms_output.put_line(strColumnName || ' ' || strDataType);
  end if;
end loop;

dbms_output.put_line(');');

strPrevTableName := '(none)';

for x in curColumns
loop
  if strPrevTableName <> x.table_name then
    if strPrevTableName <> '(none)' then
      dbms_output.put_line(');');
    end if;
    dbms_output.put_line('type ' || x.table_name || '_type is record ');
  end if;
  if strPrevTableName <> x.table_name then
    strPrevTableName := x.table_name;
    strColumnName := '(';
  else
    strColumnName := ',';
  end if;
  strColumnName := strColumnName || x.column_name || ' ' || x.table_name || '.' || x.column_name || '%type';
  dbms_output.put_line(strColumnName);
end loop;

dbms_output.put_line(');');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
spool off;
exit;
