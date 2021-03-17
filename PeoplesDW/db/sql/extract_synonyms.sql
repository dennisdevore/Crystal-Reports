--
-- $Id$
--
set echo off
--
--Creates a file of "create synonym" commands for each
--synonym referencing a table
--in the schema specified by the user running this script.
--
set verify off

--so user doesn't see feedback about the number of rows selected.
set feedback off

--Tell the user what we are going to do, and prompt for
--the neccessary values.
prompt
prompt
prompt This script allows you to build a SQL*Plus script file
prompt which will recreate all PUBLIC synonyms referencing
prompt objects in a specified schema.
prompt
prompt To abort execution, press ctrl-C.
prompt
accept SynRefsOwner char prompt 'Schema >'
accept SynScriptFileName char prompt 'Output File >'

--Build the script file with the requested "create synonym" commands.
--First set session settings so the output looks nice.
set linesize 132
set pagesize 0
set termout off
set trimspool on
set trimout on

--Spool the output the file requested by the user.
spool &SynScriptFileName

select 'create public synonym '
       || synonym_name
       || ' for '
       || table_owner || '.' || table_name
       || ';'
  from dba_synonyms
 where table_owner = upper('&SynRefsOwner')
   and owner = 'PUBLIC'
UNION
select '--No public synonyms were found referencing the schema '''
       || upper('&SynRefsOwner')
       || '''.'
  from dual
 where not exists (
       select *
         from dba_synonyms
        where table_owner = upper('&SynRefsOwner')
          and owner = 'PUBLIC'
       );

--Turn spooling off to close the file.
spool off

--Reset session settings back to their defaults.
set verify on
set feedback 6
set linesize 80
set termout on
set pagesize 24
set trimspool off
set trimout on
set echo on
