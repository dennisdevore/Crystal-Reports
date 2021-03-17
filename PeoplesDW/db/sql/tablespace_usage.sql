--
-- $Id$
--
set termout off
set echo off
set heading on
set feedback off
set verify off
set trimspool on
set linesize 120
set pagesize 100
COLUMN TBLSPCE  FORMAT A15
COLUMN ALLOC    FORMAT 9999,999,999.99
COLUMN USED     FORMAT 9999,999,999.99
COLUMN UNUSED   FORMAT 9999,999,999.99
COLUMN USEDPCT  FORMAT 999.99
break on report
compute sum of ALLOC sum of USED sum of UNUSED on report
spool tablespace_usage.out
set termout on
select u.tblspc TBLSPCE,
       round(a.fbytes/1073741824,2) ALLOC,
       round(u.ebytes/1073741824,2) USED,
       round((a.fbytes-u.ebytes)/1073741824) UNUSED,
       round((u.ebytes/a.fbytes)*100) USEDPCT
   from (select tablespace_name tblspc, sum(bytes) ebytes
            from sys.dba_extents
            group by tablespace_name) u,
        (select tablespace_name tblspc, sum(bytes) fbytes
            from sys.dba_data_files
            group by tablespace_name) a
   where u.tblspc = a.tblspc;
spool off
exit;