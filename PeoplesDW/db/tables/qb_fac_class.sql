create table QB_FAC_CLASS (
  code        varchar2 (12)  not null,
  descr       varchar2 (32)  not null,
  abbrev      varchar2 (12)  not null,
  dtlupdate   varchar2 (1),
  lastuser    varchar2 (12),
  lastupdate  date ) ;
/

set flush on;
set serveroutput on;

declare
out_errorno integer;
out_msg varchar2(255);
in_viewnum integer;
in_custid varchar2(255);
cmdSql varchar2(2000);

begin


insert into tabledefs
(tableid, hdrupdate, dtlupdate, codemask, lastuser, lastupdate)
values ('QB_FAC_CLASS','Y','Y','AAAA;0;_','SYNAPSE',sysdate);

for fa in (select facility, name from facility) loop
   insert into QB_FAC_CLASS
   (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
   values (fa.facility, substr(fa.name,1,32), fa.facility,'Y','SYNAPSE',sysdate);

end loop;

commit;
end;
/
exit;


