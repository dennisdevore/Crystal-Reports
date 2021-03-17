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
spool alterddl.sql

declare

cursor curColumns is
  select uc.table_name,uc.column_name
    from user_tab_columns uc
   where column_name like '%FAX%'
     and data_length = 15
     and exists
         (select *
            from user_tables ut
           where uc.table_name = ut.table_name)
   order by table_name,column_id;

strPrevTableName varchar2(255);
strColumnName varchar2(255);
strDataType varchar2(255);
strNullClause varchar2(255);
cntTotal integer;
begin


dbms_output.enable(1000000);

strPrevTableName := '(none)';

for x in curColumns
loop
  dbms_output.put_line('alter table ' || x.table_name || ' modify (' ||
      x.column_name || ' varchar2(25));');
end loop;

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
spool off;
--exit;
