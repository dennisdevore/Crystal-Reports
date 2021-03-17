--
-- $Id$
--
create table workorderclasses
(custid varchar2(10) not null
,item varchar2(50) not null
,kitted_class varchar2(2) default 'no'
,descr varchar2(32)
,lastuser varchar2(12)
,lastupdate date
,constraint workorderclasses_pk primary key (custid,item,kitted_class) enable
);

set serveroutput on;

declare
cntRows integer;

begin

for woi in (select distinct custid,item
              from workorderinstructions)
loop
  insert into workorderclasses
    (custid,item,kitted_class,descr,lastuser,lastupdate)
  values
    (woi.custid,woi.item,'no','(Kit Item)','SYNAPSE',sysdate);
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/

exit;
