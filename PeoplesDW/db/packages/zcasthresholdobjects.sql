drop table casthresholdrpt;

create table casthresholdrpt
(sessionid       number
,reporteddate    date
,facility        varchar2(3)
,custid          varchar2(10)
,custname        varchar2(40)
,item            varchar2(50)
,itemdescr       varchar2(255)
,baseuom         varchar2(4)
,cascode         varchar2(12)
,dea_threshold   number(17,8)
,dhs_threshold   number(17,8)
,psm_threshold   number(17,8)
,rpm_threshold   number(17,8)
,casnumber       varchar2(12)
,caspercent      number(5,2)
,qtyonhand       number(10)
,weightonhand    number(17,8)
,casweightonhand number(17,8)
,lastupdate      date
);

create unique index casthresholdrpt_unique_idx
 on casthresholdrpt(sessionid,reporteddate,facility,custid,cascode,item);

create index casthresholdrpt_lastupdate_idx
 on casthresholdrpt(lastupdate);

create or replace package casthresholdrptPKG
as type cas_type is ref cursor return casthresholdrpt%rowtype;
	procedure casthresholdrptPROC
	(cas_cursor IN OUT casthresholdrptpkg.cas_type
	,in_custid IN varchar2
	,in_facility IN varchar2
	,in_begdate IN date
	,in_enddate IN date);
end casthresholdrptpkg;
/

create or replace procedure casthresholdrptPROC
(cas_cursor IN OUT casthresholdrptpkg.cas_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date)
as

cursor curCustomer is
  select custid, name
    from customer
   where custid = in_custid
      or in_custid = 'ALL';
cu curCustomer%rowtype;

cursor curFacility(in_custid IN varchar2) is
  select facility
    from facility fa
   where (facility = in_facility
      or in_facility = 'ALL')
     and exists(
     select 1
       from asofinventory
      where facility=fa.facility
        and custid=in_custid
        and rownum=1);
cf curFacility%rowtype;

cursor curCasNumbers(in_facility IN varchar2,in_custid IN varchar2) is
	select casnumber,
	       nvl(dea_weight,0) dea_weight,
	       nvl(dhs_weight,0) dhs_weight,
	       nvl(psm_weight,0) psm_weight,
	       nvl(rpm_weight,0) rpm_weight
	  from casthreshold ct
	 where exists (select 1
	                 from custitem ci
                    where ci.custid = in_custid
                      and (ci.sara_cas_number1 like ct.casnumber || '%'
                       or  ci.sara_cas_number2 like ct.casnumber || '%'
                       or  ci.sara_cas_number3 like ct.casnumber || '%'
                       or  ci.sara_cas_number4 like ct.casnumber || '%'
                       or  ci.sara_cas_number5 like ct.casnumber || '%'
                       or  ci.sara_cas_number6 like ct.casnumber || '%'
                       or  ci.sara_cas_number7 like ct.casnumber || '%'
                       or  ci.sara_cas_number8 like ct.casnumber || '%'
                       or  ci.sara_cas_number9 like ct.casnumber || '%'
                       or  ci.sara_cas_number10 like ct.casnumber || '%'
                       or  ci.sara_cas_number11 like ct.casnumber || '%'
                       or  ci.sara_cas_number12 like ct.casnumber || '%'
                       or  ci.sara_cas_number13 like ct.casnumber || '%'
                       or  ci.sara_cas_number14 like ct.casnumber || '%'
                       or  ci.sara_cas_number15 like ct.casnumber || '%'
                       or  ci.sara_cas_number16 like ct.casnumber || '%'
                       or  ci.sara_cas_number17 like ct.casnumber || '%'
                       or  ci.sara_cas_number18 like ct.casnumber || '%'
                       or  ci.sara_cas_number19 like ct.casnumber || '%'
                       or  ci.sara_cas_number20 like ct.casnumber || '%')
                      and rownum=1
                      and exists(
                      select 1
                        from asofinventory
                       where facility=in_facility
                         and custid=in_custid
                         and item=ci.item
                         and rownum=1));
ccn curCasNumbers%rowtype;

cursor curCustItems(in_facility IN varchar2, in_custid IN varchar2, in_casnumber IN varchar2) is
  select *
    from custitem ci
   where custid = in_custid
     and (sara_cas_number1 like in_casnumber || '%'
      or  sara_cas_number2 like in_casnumber || '%'
      or  sara_cas_number3 like in_casnumber || '%'
      or  sara_cas_number4 like in_casnumber || '%'
      or  sara_cas_number5 like in_casnumber || '%'
      or  sara_cas_number6 like in_casnumber || '%'
      or  sara_cas_number7 like in_casnumber || '%'
      or  sara_cas_number8 like in_casnumber || '%'
      or  sara_cas_number9 like in_casnumber || '%'
      or  sara_cas_number10 like in_casnumber || '%'
      or  sara_cas_number11 like in_casnumber || '%'
      or  sara_cas_number12 like in_casnumber || '%'
      or  sara_cas_number13 like in_casnumber || '%'
      or  sara_cas_number14 like in_casnumber || '%'
      or  sara_cas_number15 like in_casnumber || '%'
      or  sara_cas_number16 like in_casnumber || '%'
      or  sara_cas_number17 like in_casnumber || '%'
      or  sara_cas_number18 like in_casnumber || '%'
      or  sara_cas_number19 like in_casnumber || '%'
      or  sara_cas_number20 like in_casnumber || '%')
     and exists(
     select 1
       from asofinventory
      where facility=in_facility
        and custid=in_custid
        and item=ci.item
        and rownum=1);
cit curCustItems%rowtype;

cursor curAsOf(in_custid IN varchar2, in_facility IN varchar2, in_item IN varchar2) is
  select distinct lotnumber,uom,invstatus,inventoryclass
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and invstatus != 'SU'
     and (currentqty <> 0
      or  previousqty <> 0);
cao curAsOf%rowtype;

cursor curAsOfSearch(in_custid IN varchar2, in_facility IN varchar2, in_item IN varchar2,
  in_lotnumber IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2,
  in_effdate IN date) is
  select effdate,
         nvl(currentqty,0) as qty,
         nvl(currentweight,0) as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate = in_effdate
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and nvl(currentqty,0) <> 0
  union
  select effdate,
         nvl(currentqty,0) as qty,
         nvl(currentweight,0) as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate = (select max(aoi2.effdate)
                      from asofinventory aoi2
                     where aoi1.facility = aoi2.facility
                       and aoi1.custid = aoi2.custid
                       and aoi1.item = aoi2.item
                       and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                       and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                       and aoi2.effdate < in_effdate
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx')
                       and nvl(aoi1.currentqty,0) <> 0)
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and nvl(currentqty,0) <> 0
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi1.facility = aoi2.facility
                        and aoi1.custid = aoi2.custid
                        and aoi1.item = aoi2.item
                        and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                        and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                        and aoi2.effdate = in_effdate
                        and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                        and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx')
                        and nvl(aoi1.currentqty,0) <> 0);
caos curAsOfSearch%rowtype;

numSessionId number;
lCASPercent number(5,2);
lCASNumber varchar2(12);
lLastDate date;


begin

if trunc(in_begdate) > trunc(in_enddate) then
	return;
end if;

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from casthresholdrpt
where sessionid = numSessionId;
commit;

delete from casthresholdrpt
where lastupdate < trunc(sysdate);
commit;

for cu in curCustomer
loop
  for cf in curFacility(cu.custid)
  loop
  	for ccn in curCasNumbers(cf.facility, cu.custid)
  	loop
      for cit in curCustItems(cf.facility, cu.custid, ccn.casnumber)
      loop
      	lCASPercent := 0.0;
      	if cit.sara_cas_number1 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent1;
      		lCASNumber := cit.sara_cas_number1;
      	elsif cit.sara_cas_number2 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent2;
      		lCASNumber := cit.sara_cas_number2;
      	elsif cit.sara_cas_number3 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent3;
      		lCASNumber := cit.sara_cas_number3;
      	elsif cit.sara_cas_number4 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent5;
      		lCASNumber := cit.sara_cas_number4;
      	elsif cit.sara_cas_number5 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent5;
      		lCASNumber := cit.sara_cas_number5;
      	elsif cit.sara_cas_number6 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent6;
      		lCASNumber := cit.sara_cas_number6;
      	elsif cit.sara_cas_number7 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent7;
      		lCASNumber := cit.sara_cas_number7;
      	elsif cit.sara_cas_number8 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent8;
      		lCASNumber := cit.sara_cas_number8;
      	elsif cit.sara_cas_number9 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent9;
      		lCASNumber := cit.sara_cas_number9;
      	elsif cit.sara_cas_number10 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent10;
      		lCASNumber := cit.sara_cas_number10;
      	elsif cit.sara_cas_number11 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent11;
      		lCASNumber := cit.sara_cas_number11;
      	elsif cit.sara_cas_number12 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent12;
      		lCASNumber := cit.sara_cas_number12;
      	elsif cit.sara_cas_number13 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent13;
      		lCASNumber := cit.sara_cas_number13;
      	elsif cit.sara_cas_number14 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent14;
      		lCASNumber := cit.sara_cas_number14;
      	elsif cit.sara_cas_number15 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent15;
      		lCASNumber := cit.sara_cas_number15;
      	elsif cit.sara_cas_number16 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent16;
      		lCASNumber := cit.sara_cas_number16;
      	elsif cit.sara_cas_number17 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent17;
      		lCASNumber := cit.sara_cas_number17;
      	elsif cit.sara_cas_number18 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent18;
      		lCASNumber := cit.sara_cas_number18;
      	elsif cit.sara_cas_number19 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent19;
      		lCASNumber := cit.sara_cas_number19;
      	elsif cit.sara_cas_number20 like ccn.casnumber || '%' then
      		lCASPercent := cit.sara_cas_percent20;
      		lCASNumber := cit.sara_cas_number20;
      	end if;

        if (nvl(lCASPercent,0.0) > 0.0)
        then
          for cao in curAsOf(cu.custid, cf.facility, cit.item)
          loop
          	lLastDate := trunc(in_begdate);
          	while (lLastDate <= trunc(in_enddate))
          	loop
              for caos in curAsOfSearch(cu.custid, cf.facility, cit.item, cao.lotnumber,
                cao.uom, cao.invstatus, cao.inventoryclass, lLastDate)
              loop
                if (caos.qty <> 0) and (caos.weight*lCASPercent/100.0 > 0.0) then
                  begin
                    insert into casthresholdrpt values(numSessionId, lLastDate, cf.facility, cu.custid, cu.name,
                      cit.item, cit.descr, cit.baseuom, ccn.casnumber, ccn.dea_weight, ccn.dhs_weight, ccn.psm_weight,
                      ccn.rpm_weight, lCASNumber, lCASPercent, caos.qty, caos.weight, caos.weight*lCASPercent/100.0,
                      sysdate);
                  exception when dup_val_on_index then
                    update casthresholdrpt
                       set qtyonhand = qtyonhand + caos.qty,
                           weightonhand = weightonhand + caos.weight,
                           casweightonhand = casweightonhand + caos.weight * lCASPercent/100.0,
                           lastupdate = sysdate
                     where sessionid = numSessionId
                       and reporteddate = lLastDate
                       and facility = cf.facility
                       and custid = cu.custid
                       and casnumber = lCASNumber
                       and item = cit.item;
                  end;
                end if;
              end loop;
        	  	lLastDate := lLastDate + 1;
            end loop;
          end loop;
        end if;

        commit;
      end loop;
    end loop;
  end loop;
end loop;

delete
from casthresholdrpt cas
where sessionid = numSessionId
and dea_threshold != 999999
and dhs_threshold != 999999
and psm_threshold != 999999
and rpm_threshold != 999999
and dea_threshold > 
(select sum(casweightonhand)
   from casthresholdrpt
  where sessionid = numSessionId
    and facility = cas.facility
    and cascode = cas.cascode
    and reporteddate = cas.reporteddate)
and dhs_threshold > 
(select sum(casweightonhand)
   from casthresholdrpt
  where sessionid = numSessionId
    and facility = cas.facility
    and cascode = cas.cascode
    and reporteddate = cas.reporteddate)
and psm_threshold > 
(select sum(casweightonhand)
   from casthresholdrpt
  where sessionid = numSessionId
    and facility = cas.facility
    and cascode = cas.cascode
    and reporteddate = cas.reporteddate)
and rpm_threshold > 
(select sum(casweightonhand)
   from casthresholdrpt
  where sessionid = numSessionId
    and facility = cas.facility
    and cascode = cas.cascode
    and reporteddate = cas.reporteddate);
commit;

open cas_cursor for
select *
  from casthresholdrpt
 where sessionid = numSessionId;

end casthresholdrptPROC;
/

CREATE OR REPLACE PACKAGE Body casthresholdrptPKG AS
--
-- $Id: zcasthresholdrptobjects.sql 1417 2007-01-03 00:00:00Z eric $
--

procedure casthresholdrptPROC
(cas_cursor IN OUT casthresholdrptpkg.cas_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date)
as
begin
	casthresholdrptPROC(cas_cursor, in_custid, in_facility, in_begdate, in_enddate);
end casthresholdrptPROC;
end casthresholdrptPKG;
/


show errors package casthresholdrptPKG;
show errors procedure casthresholdrptPROC;
show errors package body casthresholdrptPKG;
exit;
