--
-- $Id$
--
set feedback off
set trimspool on
set termout off
create table xxx_show_facs_xxx
(
   tbl   varchar2(30),
   col   varchar2(30),
   fac   varchar2(4)
)
/

declare
   dmy   varchar2(255);
begin
   for s in (select distinct C.table_name tbl, C.column_name col
               from user_tab_columns C, user_objects O
               where (C.column_name = 'FACILITY'
                   or  (C.column_name like '%FAC%'
                    and C.data_type = 'VARCHAR2'
                    and C.data_length = 3))
                 and O.object_name = C.table_name
                 and O.object_type = 'TABLE'
               order by 1, 2)
   loop
      execute immediate 'insert into xxx_show_facs_xxx select distinct '''
            || s.tbl || ''',''' || s.col || ''',' || s.col
            || ' from ' || s.tbl || ' order by 1';
   end loop;
end;
/

set feedback on
set termout on
column tbl heading "Table"
column col heading "Column"
column fac format a5 heading "Value"
break on tbl on col
select * from xxx_show_facs_xxx
   where fac is not null
   order by 1, 2, 3;

set feedback off
set termout off
drop table xxx_show_facs_xxx;
