--
-- $Id$
--
set heading off;
set verify off;
set feedback off;
set echo off;
set term off;
set pagesize 0;
set linesize 32000;
set trimspool on;

spool addsyn.sql

select 'create public synonym ' ||
       synonym_name ||
       ' for ' ||
       table_name ||
       ';'
  from all_synonyms
 where table_owner = 'ALPS'
 order by synonym_name;

select 'exit;' from dual;

spool off;

exit;
