--
-- $Id$
--
set heading off feedback off verify off

select 'set heading off feedback off verify off' from dual;

select 'select ''' || tableid || ''' from dual;' || chr(10)
		|| 'select '' '' from dual;' || chr(10)
		|| 'select code, descr, abbrev, dtlupdate from ' || tableid || ' order by code;' || chr(10)
      || 'set heading off'
   from tabledefs
   order by tableid

spool dmptdefsxx.sql
/

spool off
spool dmptdefs.lst
@dmptdefsxx
!rm dmptdefsxx.sql
exit;
