--
-- $Id$
--
set heading off feedback off verify off

select 'set heading off trimspool on linesize 120;' || chr(10)
    || 'select ''' || tableid || ''' from dual;' || chr(10)
    || 'set heading on;' || chr(10)
    || 'select * from ' || tableid || ' order by 1;'
   from tabledefs
   order by tableid

spool tbldefstemp.sql
/

spool off
spool tbldefs.lst
@tbldefstemp
!rm tbldefstemp.sql
exit;
