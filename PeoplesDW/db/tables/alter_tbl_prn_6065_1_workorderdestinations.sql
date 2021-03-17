--
-- $Id$
--
create table workorderdestinations
(custid varchar2(10) not null
,item varchar2(50) not null
,kitted_class varchar2(2) default 'no'
,seq number(8) not null
,facility varchar2(3) not null
,location varchar2(10)
,loctype varchar2(3)
,lastuser varchar2(12)
,lastupdate date
,constraint workorderdestinations_pk primary key (custid,item,kitted_class,seq,facility) enable
);

set serveroutput on;

declare
cntRows integer;

begin

for woi in (select *
              from workorderinstructions
             where destfacility is not null)
loop
  insert into workorderdestinations
    (custid,item,seq,facility,location,loctype,lastuser,lastupdate)
  values
    (woi.custid,woi.item,woi.seq,woi.destfacility,woi.destlocation,woi.destloctype,
     'SYNAPSE',sysdate);
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/

exit;
