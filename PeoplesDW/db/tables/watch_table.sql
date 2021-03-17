--
-- $Id$
--

create table watch_table (
   origin      varchar2(1000),
   occurred    date,
   userid      varchar2(12),
   tbl_name    varchar2(30),
   col_name    varchar2(30),
   old_value   varchar2(2000),
   new_value   varchar2(2000),
   module      varchar2(100),
   host        varchar2(100),
   ip_address  varchar2(32),
   os_user     varchar2(32)
);

exit;
