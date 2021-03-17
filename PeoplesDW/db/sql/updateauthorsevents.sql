--
-- $Id: updateauthorsevents.sql 12194 2014-07-31 19:37:24Z brianb $
--
set serveroutput on;
declare
cursor curNomessageauthors is
  select distinct author
    from appmsgs
   where not exists
     (select *
        from messageauthors
       where messageauthors.code = appmsgs.author);

cursor curNoemployeeactivities is
  select distinct event
    from userhistory
   where not exists
     (select *
        from employeeactivities
       where employeeactivities.code = userhistory.event);

cntTotal integer;
updflag char(1);

begin

updflag := upper('&1');
cntTotal := 0;

for x in curNomessageauthors
loop
  if updflag = 'Y'  then
    insert into messageauthors
      (code,descr,abbrev,dtlupdate,lastuser,lastupdate)
     values
      (x.author,x.author,x.author,'Y','SYSTEM',sysdate);
  end if;
  zut.prt('Added messageauthors row: ' || x.author);
  cntTotal := cntTotal + 1;
end loop;

for x in curNoemployeeactivities
loop
  if updflag = 'Y' then
    insert into employeeactivities
    (code,descr,abbrev,dtlupdate,lastuser,lastupdate)
    values
    (x.event,x.event,x.event,'Y','SYSTEM',sysdate);
  end if;
  zut.prt('Added employeeactivities row: ' || x.event);
  cntTotal := cntTotal + 1;
end loop;

commit;

zut.prt('Rows inserted: ' || cntTotal);

exception when others then
  zut.prt('when others ' || sqlerrm);
end;
/
exit;
