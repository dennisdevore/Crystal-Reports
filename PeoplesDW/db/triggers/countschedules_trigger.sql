create or replace trigger countschedules_ad
--
-- $Id$
--
after delete
on countschedules
for each row
declare
   l_cnt pls_integer;
   l_what varchar2(4000);
begin
   l_what := 'ZCC.EXECUTE_JOB('''||:old.countid||''','''||:old.facility||''');';
   select count(1) into l_cnt
      from user_jobs
      where job = :old.jobid
        and what = l_what;
   if l_cnt != 0 then
      dbms_job.remove(:old.jobid);
   end if;
end;
/

show error trigger countschedules_ad;

exit;
