--
-- $Id$
--
set heading off;
set verify off;
set echo off;
set term off;
set pagesize 0;
set trimspool on;

spool cols.orderhdr.sql

select column_name || ','
  from user_tab_columns
 where table_name = 'ORDERHDR'
 order by column_id;

spool off;
exit;
