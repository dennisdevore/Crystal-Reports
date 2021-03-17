drop table recallrpt;

create table recallrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,item            varchar2(50)
,lotnumber       varchar2(30)
,inventory_cnt   number(7)
,receipt_cnt     number(7)
,shipment_cnt    number(7)
,lastupdate      date
);

create index recallrpt_sessionid_idx
 on recallrpt(sessionid,facility,custid,item,lotnumber);

create index recallrpt_lastupdate_idx
 on recallrpt(lastupdate);

create or replace package recallrptpkg
as type r_type is ref cursor return recallrpt%rowtype;
end recallrptpkg;
/

create or replace procedure recallrptproc
(r_cursor IN OUT recallrptpkg.r_type
,in_facility IN varchar2
,in_custid IN varchar2
,in_lotnumber IN varchar2)
as

cursor curFacility is
  select facility
    from facility
   where instr(','||in_facility||',', ','||facility||',', 1, 1) > 0
      or in_facility='ALL';
cf curFacility%rowtype;

cursor curCustomer(in_facility varchar2) is
  select custid
    from customer cu
   where (instr(','||in_custid||',', ','||custid||',', 1, 1) > 0
      or in_custid='ALL')
     and exists(select 1
                  from asofinventory
                 where facility = in_facility
                   and custid = cu.custid
                   and upper(lotnumber) like upper('%'||in_lotnumber||'%')
                   and rownum = 1);
cu curCustomer%rowtype;

cursor curCustItems(in_facility varchar2, in_custid varchar2) is
  select item
    from custitem ci
   where custid = in_custid
     and exists(select 1
                  from asofinventory
                 where facility = in_facility
                   and custid = in_custid
                   and item = ci.item
                   and upper(lotnumber) like upper('%'||in_lotnumber||'%')
                   and rownum = 1);
cit curCustItems%rowtype;

cursor curAsof(in_facility varchar2, in_custid varchar2, in_item varchar2) is
  select distinct lotnumber
    from asofinventory
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and upper(lotnumber) like upper('%'||in_lotnumber||'%');
casof curAsof%rowtype;

numSessionId number;
wrk recallrpt%rowtype;
invCount integer;
rcptCount integer;
shipCount integer;
dtlCount integer;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from recallrpt
where sessionid = numSessionId;
commit;

delete from recallrpt
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from recallrpt
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table recallrpt';
end if;

for cf in curFacility
loop
  for cu in curCustomer(cf.facility)
  loop
    for cit in curCustItems(cf.facility, cu.custid)
    loop
      for casof in curAsof(cf.facility, cu.custid, cit.item)
      loop
        invCount := 0;
        rcptCount := 0;
        shipCount := 0;
        
        select count(1)
          into invCount
          from plate
         where facility = cf.facility
           and custid = cu.custid
           and item = cit.item
           and lotnumber = casof.lotnumber
           and type = 'PA'
           and rownum = 1;
        
        select count(1)
          into rcptCount
          from orderdtlrcpt
         where facility = cf.facility
           and custid = cu.custid
           and item = cit.item
           and lotnumber = casof.lotnumber
           and rownum = 1;
        
        select count(1)
          into shipCount
          from shippingplate
         where facility = cf.facility
           and custid = cu.custid
           and item = cit.item
           and lotnumber = casof.lotnumber
           and type in ('F','P')
           and status = 'SH'
           and rownum = 1;
           
        insert into recallrpt 
        (sessionid,facility,custid,item,lotnumber,
         inventory_cnt,receipt_cnt,shipment_cnt,lastupdate) values
        (numSessionId,cf.facility,cu.custid,cit.item,casof.lotnumber,
         invCount,rcptCount,shipCount,sysdate);
      end loop;
    end loop;
  end loop;
end loop;

open r_cursor for
select *
   from recallrpt
  where sessionid = numSessionId;

end recallrptproc;
/

show errors package recallrptpkg;
show errors procedure recallrptproc;
exit;
