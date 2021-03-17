--
-- $Id$
--
drop table audit_table;

create table audit_table (
   origin      varchar2(1000),
   occurred    date,
   userid      varchar2(12),
   tbl_name    varchar2(30),
   col_name    varchar2(30),
   old_value   varchar2(2000),
   new_value   varchar2(2000)
);

exit;
