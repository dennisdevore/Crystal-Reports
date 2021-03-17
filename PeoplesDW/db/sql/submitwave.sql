--
-- $Id$
--
set serveroutput on;

declare
newjob integer;


begin

dbms_job.submit(newjob,'zwv.submit_wave_request(' ||
  127 || ', ''N'');',sysdate+.012,null,null);

exception when others then
  zut.prt('other...');
  zut.prt(sqlerrm);
end;
/
--exit;