drop table sararpt;
drop table sararpt_dates;

create table sararpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,custname        varchar2(40)
,casnumber       varchar2(20)
,chemname        varchar2(255)
,ehsname         varchar2(255)
,prodtypedescr   varchar2(255)
,haztypedescr    varchar2(255)
,conttypedescr   varchar2(255)
,productcodes    varchar2(4000)
,storagearea     varchar2(12)
,tradesecret     varchar2(1)
,maxdailyamt     number(30,2)
,avgdailyamt     number(30,2)
,daysonhand      number(4)
,building        varchar2(50)
,largestuom      varchar2(12)
,uomabbrev       varchar2(12)
,largestwght     number(30,2)
,caspercent      number(5,2)
,lastupdate      date
,physicalhazard  varchar2(512)
,healthharzard   varchar2(512)
);

create index sararpt_sessionid_idx
 on sararpt(sessionid,facility,custid,casnumber);

create index sararpt_lastupdate_idx
 on sararpt(lastupdate);

create global temporary table sararpt_dates
(reporteddate date,
 reportedamt number(30,2)
) on commit preserve rows;

create or replace package SARARPTPKG
as 
    type sara_type is ref cursor return sararpt%rowtype;
    
	procedure SARARPTPROC
	(sara_cursor IN OUT sararptpkg.sara_type
	,in_custid IN varchar2
	,in_facility IN varchar2
	,in_begdate IN date
	,in_enddate IN date
	,in_debug_yn IN varchar2);
    
    function get_physicalhazard
    ( p_custid  varchar2
    , p_item    varchar2
    ) 
    return varchar2;

    function get_healthhazard
    ( p_custid  varchar2
    , p_item    varchar2
    ) 
    return varchar2;

end sararptpkg;
/

create or replace procedure SARARPTPROC
(sara_cursor IN OUT sararptpkg.sara_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select custid, name
    from customer
   where custid = in_custid
      or in_custid = 'ALL';
cu curCustomer%rowtype;

cursor curFacility is
  select facility
    from facility
   where facility = in_facility
      or in_facility = 'ALL';
cf curFacility%rowtype;

cursor curCasNumbers(in_custid IN varchar2) is
	select cas, descr, weight, ehs
	  from casnumbers cn
	 where exists (select 1
	                 from custitem ci
                    where ci.custid = in_custid
                      and ((ci.sara_cas_number1 = cn.cas
                      and   nvl(ci.sara_reportable1,'N') = 'Y')
                       or  (ci.sara_cas_number2 = cn.cas
                      and   nvl(ci.sara_reportable2,'N') = 'Y')
                       or  (ci.sara_cas_number3 = cn.cas
                      and   nvl(ci.sara_reportable3,'N') = 'Y')
                       or  (ci.sara_cas_number4 = cn.cas
                      and   nvl(ci.sara_reportable4,'N') = 'Y')
                       or  (ci.sara_cas_number5 = cn.cas
                      and   nvl(ci.sara_reportable5,'N') = 'Y')
                       or  (ci.sara_cas_number6 = cn.cas
                      and   nvl(ci.sara_reportable6,'N') = 'Y')
                       or  (ci.sara_cas_number7 = cn.cas
                      and   nvl(ci.sara_reportable7,'N') = 'Y')
                       or  (ci.sara_cas_number8 = cn.cas
                      and   nvl(ci.sara_reportable8,'N') = 'Y')
                       or  (ci.sara_cas_number9 = cn.cas
                      and   nvl(ci.sara_reportable9,'N') = 'Y')
                       or  (ci.sara_cas_number10 = cn.cas
                      and   nvl(ci.sara_reportable10,'N') = 'Y')
                       or  (ci.sara_cas_number11 = cn.cas
                      and   nvl(ci.sara_reportable11,'N') = 'Y')
                       or  (ci.sara_cas_number12 = cn.cas
                      and   nvl(ci.sara_reportable12,'N') = 'Y')
                       or  (ci.sara_cas_number13 = cn.cas
                      and   nvl(ci.sara_reportable13,'N') = 'Y')
                       or  (ci.sara_cas_number14 = cn.cas
                      and   nvl(ci.sara_reportable14,'N') = 'Y')
                       or  (ci.sara_cas_number15 = cn.cas
                      and   nvl(ci.sara_reportable15,'N') = 'Y')
                       or  (ci.sara_cas_number16 = cn.cas
                      and   nvl(ci.sara_reportable16,'N') = 'Y')
                       or  (ci.sara_cas_number17 = cn.cas
                      and   nvl(ci.sara_reportable17,'N') = 'Y')
                       or  (ci.sara_cas_number18 = cn.cas
                      and   nvl(ci.sara_reportable18,'N') = 'Y')
                       or  (ci.sara_cas_number19 = cn.cas
                      and   nvl(ci.sara_reportable19,'N') = 'Y')
                       or  (ci.sara_cas_number20 = cn.cas
                      and   nvl(ci.sara_reportable20,'N') = 'Y'))
                      and rownum=1)
   order by cn.cas;
ccn curCasNumbers%rowtype;

cursor curCustItems(in_custid IN varchar2, in_casnumber IN varchar2) is
  select *
    from custitem
   where custid = in_custid
     and ((sara_cas_number1 = in_casnumber
     and   nvl(sara_reportable1,'N') = 'Y')
      or  (sara_cas_number2 = in_casnumber
     and   nvl(sara_reportable2,'N') = 'Y')
      or  (sara_cas_number3 = in_casnumber
     and   nvl(sara_reportable3,'N') = 'Y')
      or  (sara_cas_number4 = in_casnumber
     and   nvl(sara_reportable4,'N') = 'Y')
      or  (sara_cas_number5 = in_casnumber
     and   nvl(sara_reportable5,'N') = 'Y')
      or  (sara_cas_number6 = in_casnumber
     and   nvl(sara_reportable6,'N') = 'Y')
      or  (sara_cas_number7 = in_casnumber
     and   nvl(sara_reportable7,'N') = 'Y')
      or  (sara_cas_number8 = in_casnumber
     and   nvl(sara_reportable8,'N') = 'Y')
      or  (sara_cas_number9 = in_casnumber
     and   nvl(sara_reportable9,'N') = 'Y')
      or  (sara_cas_number10 = in_casnumber
     and   nvl(sara_reportable10,'N') = 'Y')
      or  (sara_cas_number11 = in_casnumber
     and   nvl(sara_reportable11,'N') = 'Y')
      or  (sara_cas_number12 = in_casnumber
     and   nvl(sara_reportable12,'N') = 'Y')
      or  (sara_cas_number13 = in_casnumber
     and   nvl(sara_reportable13,'N') = 'Y')
      or  (sara_cas_number14 = in_casnumber
     and   nvl(sara_reportable14,'N') = 'Y')
      or  (sara_cas_number15 = in_casnumber
     and   nvl(sara_reportable15,'N') = 'Y')
      or  (sara_cas_number16 = in_casnumber
     and   nvl(sara_reportable16,'N') = 'Y')
      or  (sara_cas_number17 = in_casnumber
     and   nvl(sara_reportable17,'N') = 'Y')
      or  (sara_cas_number18 = in_casnumber
     and   nvl(sara_reportable18,'N') = 'Y')
      or  (sara_cas_number19 = in_casnumber
     and   nvl(sara_reportable19,'N') = 'Y')
      or  (sara_cas_number20 = in_casnumber
     and   nvl(sara_reportable20,'N') = 'Y'))
   order by item;
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
  in_lotnumber IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2) is
  select effdate,previousqty as qty,previousweight as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and (currentqty <> 0
      or  previousqty <> 0)
  union
  select in_enddate+1 effdate,currentqty as qty,currentweight as weight
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
                       and aoi2.effdate >= trunc(in_begdate)
                       and aoi2.effdate <= trunc(in_enddate)
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and currentqty <> 0
  union
  select effdate,previousqty as qty,previousweight as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate = (select min(aoi2.effdate)
                      from asofinventory aoi2
                     where aoi1.facility = aoi2.facility
                       and aoi1.custid = aoi2.custid
                       and aoi1.item = aoi2.item
                       and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                       and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                       and aoi2.effdate > trunc(in_enddate)
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and previousqty <> 0
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi1.facility = aoi2.facility
                        and aoi1.custid = aoi2.custid
                        and aoi1.item = aoi2.item
                        and aoi2.effdate >= trunc(in_begdate)
                        and aoi2.effdate <= trunc(in_enddate)
                        and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                        and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                        and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                        and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
  union
  select effdate,currentqty as qty,currentweight as weight
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
                       and aoi2.effdate < trunc(in_begdate)
                       and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                       and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and currentqty <> 0
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi1.facility = aoi2.facility
                        and aoi1.custid = aoi2.custid
                        and aoi1.item = aoi2.item
                        and aoi2.effdate >= trunc(in_begdate)
                        and aoi2.effdate <= trunc(in_enddate)
                        and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                        and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                        and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                        and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
  order by effdate;
caos curAsOfSearch%rowtype;

cursor curStorareArea(in_custid IN varchar2, in_item IN varchar2) is
	select ppl.zoneid
	  from custitem ci,
	       putawayprofline ppl
	 where ci.custid = in_custid
	   and ci.item = in_item
	   and ci.profid = ppl.profid
	 order by ppl.priority;
csa curStorareArea%rowtype;

cursor curBuilding(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2) is
  select distinct nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from platehistory ph,
         location lo
   where ph.lpid in(
    select lpid
      from plate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and creationdate <= trunc(in_enddate)
     union
    select lpid
      from deletedplate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and creationdate <= trunc(in_enddate)
       and lastupdate >= trunc(in_begdate))
     and ph.whenoccurred >= trunc(in_begdate)
     and ph.whenoccurred <= trunc(in_enddate)
     and lo.facility = ph.facility
     and lo.locid = ph.location
   union
  select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from plate pl,
         location lo
   where pl.facility = in_facility
     and pl.custid = in_custid
     and pl.item = in_item
     and pl.creationdate <= trunc(in_enddate)
     and lo.facility = pl.facility
     and lo.locid = pl.location
   union
  select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from deletedplate pl,
         location lo
   where pl.facility = in_facility
     and pl.custid = in_custid
     and pl.item = in_item
     and pl.creationdate <= trunc(in_enddate)
     and pl.lastupdate >= trunc(in_begdate)
     and lo.facility = pl.facility
     and lo.locid = pl.location;
cb curBuilding%rowtype;

numSessionId number;
caspercent number(5,2);
chemname varchar2(255);
ehsname varchar2(255);
producttype varchar2(255);
hazardclass varchar2(255);
containertype varchar2(255);
productcodes varchar2(4000);
storagearea varchar2(12);
tradesecret varchar2(1);
maxdailyamt number(30,2);
dailyamt number(30,2);
totdailyamt number(30,2);
avgdailyamt number(30,2);
daysonhand number(4);
building varchar2(50);
l_building varchar2(3);
largestuom varchar2(12);
uomabbrev varchar2(12);
largestwght number(30,2);
topcaspercent number(5,2);
lastdate date;
physicalhazard varchar2(512);
healthharzard varchar2(512);

procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

begin

if trunc(in_begdate) > trunc(in_enddate) then
	return;
end if;

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from sararpt
where sessionid = numSessionId;
commit;

delete from sararpt
where lastupdate < trunc(sysdate);
commit;

delete from sararpt_dates;

lastdate := trunc(in_begdate);
while lastdate <= trunc(in_enddate)
loop
	insert into sararpt_dates values(lastdate, 0);
	lastdate := lastdate + 1;
end loop;

for cu in curCustomer
loop
  for cf in curFacility
  loop
  	for ccn in curCasNumbers(cu.custid)
  	loop
  		chemname := null;
  		ehsname := null;
  		producttype := null;
  		hazardclass := null;
  		containertype := null;
  		productcodes := null;
  		tradesecret := null;
  		building := null;
  		largestuom := null;
  		uomabbrev := null;
  		largestwght := 0.0;
  		topcaspercent := 0.0;
        physicalhazard := null;
        healthharzard := null;
      
      update sararpt_dates
      set reportedamt = 0;
  		
      for cit in curCustItems(cu.custid, ccn.cas)
      loop
      	caspercent := 0.0;
      	if cit.sara_cas_number1 = ccn.cas then
      		caspercent := cit.sara_cas_percent1;
      	elsif cit.sara_cas_number2 = ccn.cas then
      		caspercent := cit.sara_cas_percent2;
      	elsif cit.sara_cas_number3 = ccn.cas then
      		caspercent := cit.sara_cas_percent3;
      	elsif cit.sara_cas_number4 = ccn.cas then
      		caspercent := cit.sara_cas_percent5;
      	elsif cit.sara_cas_number5 = ccn.cas then
      		caspercent := cit.sara_cas_percent5;
      	elsif cit.sara_cas_number6 = ccn.cas then
      		caspercent := cit.sara_cas_percent6;
      	elsif cit.sara_cas_number7 = ccn.cas then
      		caspercent := cit.sara_cas_percent7;
      	elsif cit.sara_cas_number8 = ccn.cas then
      		caspercent := cit.sara_cas_percent8;
      	elsif cit.sara_cas_number9 = ccn.cas then
      		caspercent := cit.sara_cas_percent9;
      	elsif cit.sara_cas_number10 = ccn.cas then
      		caspercent := cit.sara_cas_percent10;
      	elsif cit.sara_cas_number11 = ccn.cas then
      		caspercent := cit.sara_cas_percent11;
      	elsif cit.sara_cas_number12 = ccn.cas then
      		caspercent := cit.sara_cas_percent12;
      	elsif cit.sara_cas_number13 = ccn.cas then
      		caspercent := cit.sara_cas_percent13;
      	elsif cit.sara_cas_number14 = ccn.cas then
      		caspercent := cit.sara_cas_percent14;
      	elsif cit.sara_cas_number15 = ccn.cas then
      		caspercent := cit.sara_cas_percent15;
      	elsif cit.sara_cas_number16 = ccn.cas then
      		caspercent := cit.sara_cas_percent16;
      	elsif cit.sara_cas_number17 = ccn.cas then
      		caspercent := cit.sara_cas_percent17;
      	elsif cit.sara_cas_number18 = ccn.cas then
      		caspercent := cit.sara_cas_percent18;
      	elsif cit.sara_cas_number19 = ccn.cas then
      		caspercent := cit.sara_cas_percent19;
      	elsif cit.sara_cas_number20 = ccn.cas then
      		caspercent := cit.sara_cas_percent20;
      	end if;

        if nvl(cit.weight,0.0) > largestwght then
          largestwght := cit.weight;
          largestuom := cit.baseuom;
          topcaspercent := caspercent;
        end if;
      	
      	if producttype is null then
      	  if nvl(cit.sara_pt_pure_yn,'N') = 'Y' then
       		  producttype := producttype||'Pure';
      		end if;
      	  if nvl(cit.sara_pt_mixture_yn,'N') = 'Y' then
      	  	if producttype is not null then
      	  		producttype := producttype||'/';
      	  	end if;
      		  producttype := producttype||'Mixture';
      		end if;
      	  if nvl(cit.sara_pt_gas_yn,'N') = 'Y' then
      	  	if producttype is not null then
      	  		producttype := producttype||'/';
      	  	end if;
      		  producttype := 'Gas';
      		end if;
      	  if nvl(cit.sara_pt_liquid_yn,'N') = 'Y' then
      	  	if producttype is not null then
      	  		producttype := producttype||'/';
      	  	end if;
      		  producttype := producttype||'Liquid';
      		end if;
      	  if nvl(cit.sara_pt_solid_yn,'N') = 'Y' then
      	  	if producttype is not null then
      	  		producttype := producttype||'/';
      	  	end if;
      		  producttype := producttype||'Solid';
      		end if;
     	end if;
      	
      	if hazardclass is null then
      	  if nvl(cit.sara_hc_delayed_yn,'N') = 'Y' then
      		  hazardclass := 'Delayed (chronic)';
      		end if;
      	  if nvl(cit.sara_hc_immediate_yn,'N') = 'Y' then
      	  	if hazardclass is not null then
      	  		hazardclass := hazardclass||'/';
      	  	end if;
      		  hazardclass := hazardclass||'Immediate (acute)';
      		end if;
      	  if nvl(cit.sara_hc_fire_yn,'N') = 'Y' then
      	  	if hazardclass is not null then
      	  		hazardclass := hazardclass||'/';
      	  	end if;
      		  hazardclass := hazardclass||'Fire';
      		end if;
      	  if nvl(cit.sara_hc_reactivity_yn,'N') = 'Y' then
      	  	if hazardclass is not null then
      	  		hazardclass := hazardclass||'/';
      	  	end if;
      		  hazardclass := hazardclass||'Reactivity';
      		end if;
      	  if nvl(cit.sara_hc_pressure_yn,'N') = 'Y' then
      	  	if hazardclass is not null then
      	  		hazardclass := hazardclass||'/';
      	  	end if;
      		  hazardclass := hazardclass||'Sudden release of pressure';
      		end if;
     		end if;

        physicalhazard := sararptpkg.get_physicalhazard(cit.custid, cit.item);
        healthharzard  := sararptpkg.get_healthhazard(cit.custid,cit.item);
            
      	if containertype is null then
      	  containertype := nvl(cit.sara_ct_container,'')||nvl(cit.sara_ct_pressure,'')||nvl(cit.sara_ct_temperature,'');
      	end if;
      	
      	if tradesecret is null then
      		tradesecret := nvl(cit.sara_trade_secret_yn,'N');
      	end if;
      	
      	if storagearea is null then
          open curStorareArea(cu.custid, cit.item);
          fetch curStorareArea into csa;
          close curStorareArea;
          
          storagearea := csa.zoneid;
        end if;


        for cao in curAsOf(cu.custid, cf.facility, cit.item)
        loop
        	lastdate := trunc(in_begdate) - 1;
          for caos in curAsOfSearch(cu.custid, cf.facility, cit.item, cao.lotnumber,
            cao.uom, cao.invstatus, cao.inventoryclass)
          loop
        		if caos.effdate < trunc(in_begdate) then
        			update sararpt_dates
                 set reportedamt = reportedamt + (caos.weight * caspercent / 100.0);
        	  elsif (caos.effdate > trunc(in_enddate)) and (lastdate < trunc(in_begdate)) then
        			update sararpt_dates
                 set reportedamt = reportedamt + (caos.weight * caspercent / 100.0);
        	  else
        			update sararpt_dates
                 set reportedamt = reportedamt + (caos.weight * caspercent / 100.0)
               where reporteddate > lastdate
                 and reporteddate <= caos.effdate;
         	  end if;
        		if instr(', '||productcodes||',',', '||cit.item||',') = 0 then
        			if productcodes is not null then
        				productcodes := productcodes||', ';
      	  		end if;
      		  	productcodes := productcodes||cit.item;
      	  	end if;
      	  	lastdate := caos.effdate;
          end loop;
        end loop;

        for cb in curBuilding(cf.facility, cu.custid, cit.item)
        loop
      	  if (cb.building = '8' or cb.building = '89') then
      	    l_building := '9';
      	  else
            l_building := cb.building;
      	  end if;

      		if instr(', '||building||',',', '||l_building||',') = 0 then
      			if building is not null then
      				building := building||', ';
    	  		end if;
    		  	building := building||l_building;
    	  	end if;
        end loop;
      end loop;
      
      totdailyamt := 0;
      maxdailyamt := 0;
      daysonhand := 0;
      
      select nvl(sum(reportedamt),0), nvl(max(reportedamt),0), count(1)
        into totdailyamt, maxdailyamt, daysonhand
        from sararpt_dates
       where reportedamt > 0;

      if totdailyamt <> 0 then
        avgdailyamt := totdailyamt / ((trunc(in_enddate) - trunc(in_begdate)) + 1);
        
        if ccn.ehs = 'Y' then
            ehsname := ccn.descr;
        else 
            chemname := ccn.descr;
        end if;

        select abbrev
          into uomabbrev
          from unitsofmeasure
         where code = largestuom;
         
        insert into sararpt values(numSessionId, cf.facility, cu.custid, cu.name, ccn.cas, chemname, ehsname,
                                   producttype, hazardclass, containertype, productcodes, storagearea,
                                   tradesecret, maxdailyamt, avgdailyamt, daysonhand, building, largestuom,
                                   uomabbrev, largestwght, topcaspercent, sysdate, physicalhazard, healthharzard);
        commit;
      end if;
    end loop;
  end loop;
end loop;

open sara_cursor for
select *
  from sararpt
 where sessionid = numSessionId;

end SARARPTPROC;
/

create or replace procedure SARARPTNOCASPROC
(sara_cursor IN OUT sararptpkg.sara_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as

cursor curCustomer is
  select custid, name
    from customer
   where custid = in_custid
      or in_custid = 'ALL';
cu curCustomer%rowtype;

cursor curFacility is
  select facility
    from facility
   where facility = in_facility
      or in_facility = 'ALL';
cf curFacility%rowtype;

cursor curCustItems(in_custid IN varchar2) is
  select ci.*,
         cis.sara_ph_explosive,
         cis.sara_ph_flamable,
         cis.sara_ph_oxidizer,
         cis.sara_ph_self_reactive,
         cis.sara_ph_pyroph_liq_solid,
         cis.sara_ph_pyrophoric_gas,
         cis.sara_ph_self_heating,
         cis.sara_ph_organic_peroxide,
         cis.sara_ph_corrosive_to_metal,
         cis.sara_ph_gas_under_press_comp,
         cis.sara_ph_wtr_cont_emit_flam_gas,
         cis.sara_ph_combustible_dust,
         cis.sara_ph_haz_not_othrwise_class,
         cis.sara_hh_acute_toxicity,
         cis.sara_hh_skin_corros_or_irrita,
         cis.sara_hh_seri_eye_dam_or_irrit,
         cis.sara_hh_respir_or_skin_sensi,
         cis.sara_hh_germ_cell_mutagenicity,
         cis.sara_hh_carcinogenicity,
         cis.sara_hh_reproductive_toxicity,
         cis.sara_hh_specific_targ_org_toxi,
         cis.sara_hh_aspiration_hazard,
         cis.sara_hh_simple_asphyxiant,
         cis.sara_hh_hazard_not_classified  
    from custitem ci,
         custitem_sara cis
   where custid = in_custid
     and ci.custid = cis.sara_custid
     and ci.item = cis.sara_item
     and 
	 (    nvl(sara_ph_explosive                     ,'N') = 'Y'
      or  nvl(sara_ph_flamable                      ,'N') = 'Y'
      or  nvl(sara_ph_oxidizer                      ,'N') = 'Y'
      or  nvl(sara_ph_self_reactive                 ,'N') = 'Y'
      or  nvl(sara_ph_pyroph_liq_solid              ,'N') = 'Y'
      or  nvl(sara_ph_pyrophoric_gas                ,'N') = 'Y'
      or  nvl(sara_ph_self_heating                  ,'N') = 'Y'
      or  nvl(sara_ph_organic_peroxide              ,'N') = 'Y'
      or  nvl(sara_ph_corrosive_to_metal            ,'N') = 'Y'
      or  nvl(sara_ph_gas_under_press_comp          ,'N') = 'Y'
      or  nvl(sara_ph_wtr_cont_emit_flam_gas        ,'N') = 'Y'
      or  nvl(sara_ph_combustible_dust              ,'N') = 'Y'
      or  nvl(sara_ph_haz_not_othrwise_class        ,'N') = 'Y'
      or  nvl(sara_hh_acute_toxicity                ,'N') = 'Y'
      or  nvl(sara_hh_skin_corros_or_irrita         ,'N') = 'Y'
      or  nvl(sara_hh_seri_eye_dam_or_irrit         ,'N') = 'Y'
      or  nvl(sara_hh_respir_or_skin_sensi          ,'N') = 'Y'
      or  nvl(sara_hh_germ_cell_mutagenicity        ,'N') = 'Y'
      or  nvl(sara_hh_carcinogenicity               ,'N') = 'Y'
      or  nvl(sara_hh_reproductive_toxicity         ,'N') = 'Y'
      or  nvl(sara_hh_specific_targ_org_toxi        ,'N') = 'Y'
      or  nvl(sara_hh_aspiration_hazard             ,'N') = 'Y'
      or  nvl(sara_hh_simple_asphyxiant             ,'N') = 'Y'
      or  nvl(sara_hh_hazard_not_classified         ,'N') = 'Y'
	 )
     and  nvl(sara_reportable1  ,'N') = 'N'
     and  nvl(sara_reportable2  ,'N') = 'N'
     and  nvl(sara_reportable3  ,'N') = 'N'
     and  nvl(sara_reportable4  ,'N') = 'N'
     and  nvl(sara_reportable5  ,'N') = 'N'
     and  nvl(sara_reportable6  ,'N') = 'N'
     and  nvl(sara_reportable7  ,'N') = 'N'
     and  nvl(sara_reportable8  ,'N') = 'N'
     and  nvl(sara_reportable9  ,'N') = 'N'
     and  nvl(sara_reportable10 ,'N') = 'N'
     and  nvl(sara_reportable11 ,'N') = 'N'
     and  nvl(sara_reportable12 ,'N') = 'N'
     and  nvl(sara_reportable13 ,'N') = 'N'
     and  nvl(sara_reportable14 ,'N') = 'N'
     and  nvl(sara_reportable15 ,'N') = 'N'
     and  nvl(sara_reportable16 ,'N') = 'N'
     and  nvl(sara_reportable17 ,'N') = 'N'
     and  nvl(sara_reportable18 ,'N') = 'N'
     and  nvl(sara_reportable19 ,'N') = 'N'
     and  nvl(sara_reportable20 ,'N') = 'N'
   order by item;
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
  in_lotnumber IN varchar2, in_uom IN varchar2, in_invstatus IN varchar2, in_inventoryclass IN varchar2) is
  select effdate,previousqty as qty,previousweight as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate >= trunc(in_begdate)
     and effdate <= trunc(in_enddate)
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and (currentqty <> 0
      or  previousqty <> 0)
  union
  select in_enddate+1 effdate,currentqty as qty,currentweight as weight
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
                       and aoi2.effdate >= trunc(in_begdate)
                       and aoi2.effdate <= trunc(in_enddate)
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and currentqty <> 0
  union
  select effdate,previousqty as qty,previousweight as weight
    from asofinventory aoi1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and nvl(lotnumber,'xxx') = nvl(in_lotnumber,'xxx')
     and nvl(uom,'xxx') = nvl(in_uom,'xxx')
     and effdate = (select min(aoi2.effdate)
                      from asofinventory aoi2
                     where aoi1.facility = aoi2.facility
                       and aoi1.custid = aoi2.custid
                       and aoi1.item = aoi2.item
                       and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                       and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                       and aoi2.effdate > trunc(in_enddate)
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and previousqty <> 0
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi1.facility = aoi2.facility
                        and aoi1.custid = aoi2.custid
                        and aoi1.item = aoi2.item
                        and aoi2.effdate >= trunc(in_begdate)
                        and aoi2.effdate <= trunc(in_enddate)
                        and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                        and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                        and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                        and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
  union
  select effdate,currentqty as qty,currentweight as weight
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
                       and aoi2.effdate < trunc(in_begdate)
                       and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                       and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                       and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                       and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
     and nvl(invstatus,'xxx') = nvl(in_invstatus,'xxx')
     and nvl(inventoryclass,'xxx') = nvl(in_inventoryclass,'xxx')
     and currentqty <> 0
     and not exists (select 1
                       from asofinventory aoi2
                      where aoi1.facility = aoi2.facility
                        and aoi1.custid = aoi2.custid
                        and aoi1.item = aoi2.item
                        and aoi2.effdate >= trunc(in_begdate)
                        and aoi2.effdate <= trunc(in_enddate)
                        and nvl(aoi1.lotnumber,'xxx') = nvl(aoi2.lotnumber,'xxx')
                        and nvl(aoi1.uom,'xxx') = nvl(aoi2.uom,'xxx')
                        and nvl(aoi1.invstatus,'xxx') = nvl(aoi2.invstatus,'xxx')
                        and nvl(aoi1.inventoryclass,'xxx') = nvl(aoi2.inventoryclass,'xxx'))
  order by effdate;
caos curAsOfSearch%rowtype;

cursor curStorareArea(in_custid IN varchar2, in_item IN varchar2) is
    select ppl.zoneid
      from custitem ci,
           putawayprofline ppl
     where ci.custid = in_custid
       and ci.item = in_item
       and ci.profid = ppl.profid
     order by ppl.priority;
csa curStorareArea%rowtype;

cursor curBuilding(in_facility IN varchar2, in_custid IN varchar2, in_item IN varchar2) is
  select distinct nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from platehistory ph,
         location lo
   where ph.lpid in(
    select lpid
      from plate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and creationdate <= trunc(in_enddate)
     union
    select lpid
      from deletedplate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and creationdate <= trunc(in_enddate)
       and lastupdate >= trunc(in_begdate))
     and ph.whenoccurred >= trunc(in_begdate)
     and ph.whenoccurred <= trunc(in_enddate)
     and lo.facility = ph.facility
     and lo.locid = ph.location
   union
  select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from plate pl,
         location lo
   where pl.facility = in_facility
     and pl.custid = in_custid
     and pl.item = in_item
     and pl.creationdate <= trunc(in_enddate)
     and lo.facility = pl.facility
     and lo.locid = pl.location
   union
  select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,1,2))),'?') building
    from deletedplate pl,
         location lo
   where pl.facility = in_facility
     and pl.custid = in_custid
     and pl.item = in_item
     and pl.creationdate <= trunc(in_enddate)
     and pl.lastupdate >= trunc(in_begdate)
     and lo.facility = pl.facility
     and lo.locid = pl.location;
cb curBuilding%rowtype;

numSessionId number;
producttype varchar2(255);
hazardclass varchar2(255);
containertype varchar2(255);
storagearea varchar2(12);
tradesecret varchar2(1);
maxdailyamt number(30,2);
dailyamt number(30,2);
totdailyamt number(30,2);
avgdailyamt number(30,2);
daysonhand number(4);
building varchar2(50);
l_building varchar2(3);
uomabbrev varchar2(12);
lastdate date;
physicalhazard varchar2(512);
healthharzard varchar2(512);


procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;


begin

if trunc(in_begdate) > trunc(in_enddate) then
    return;
end if;

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from sararpt
where sessionid = numSessionId;
commit;

delete from sararpt
where lastupdate < trunc(sysdate);
commit;

delete from sararpt_dates;

lastdate := trunc(in_begdate);
while lastdate <= trunc(in_enddate)
loop
    insert into sararpt_dates values(lastdate, 0);
    lastdate := lastdate + 1;
end loop;

for cu in curCustomer
loop
  for cf in curFacility
  loop
    for cit in curCustItems(cu.custid)
    loop
      producttype := null;
      hazardclass := null;
      containertype := null;
      tradesecret := null;
      building := null;
      uomabbrev := null;
      physicalhazard := null;
      healthharzard := null;
    
      update sararpt_dates
      set reportedamt = 0;
        
      if nvl(cit.sara_pt_pure_yn,'N') = 'Y' then
        producttype := producttype||'Pure';
      end if;
      if nvl(cit.sara_pt_mixture_yn,'N') = 'Y' then
      	if producttype is not null then
      		producttype := producttype||'/';
      	end if;
        producttype := producttype||'Mixture';
      end if;
      if nvl(cit.sara_pt_gas_yn,'N') = 'Y' then
      	if producttype is not null then
      		producttype := producttype||'/';
      	end if;
        producttype := 'Gas';
      end if;
      if nvl(cit.sara_pt_liquid_yn,'N') = 'Y' then
      	if producttype is not null then
      		producttype := producttype||'/';
      	end if;
        producttype := producttype||'Liquid';
      end if;
      if nvl(cit.sara_pt_solid_yn,'N') = 'Y' then
      	if producttype is not null then
      		producttype := producttype||'/';
      	end if;
        producttype := producttype||'Solid';
      end if;
    
      if nvl(cit.sara_hc_delayed_yn,'N') = 'Y' then
          hazardclass := 'Delayed (chronic)';
      end if;
      if nvl(cit.sara_hc_immediate_yn,'N') = 'Y' then
          if hazardclass is not null then
              hazardclass := hazardclass||'/';
          end if;
          hazardclass := hazardclass||'Immediate (acute)';
      end if;
      if nvl(cit.sara_hc_fire_yn,'N') = 'Y' then
          if hazardclass is not null then
              hazardclass := hazardclass||'/';
          end if;
          hazardclass := hazardclass||'Fire';
      end if;
      if nvl(cit.sara_hc_reactivity_yn,'N') = 'Y' then
          if hazardclass is not null then
              hazardclass := hazardclass||'/';
          end if;
          hazardclass := hazardclass||'Reactivity';
      end if;
      if nvl(cit.sara_hc_pressure_yn,'N') = 'Y' then
          if hazardclass is not null then
              hazardclass := hazardclass||'/';
          end if;
          hazardclass := hazardclass||'Sudden release of pressure';
      end if;

      physicalhazard := sararptpkg.get_physicalhazard(cit.custid, cit.item);
      healthharzard  := sararptpkg.get_healthhazard(cit.custid,cit.item);
      
      containertype := nvl(cit.sara_ct_container,'')||nvl(cit.sara_ct_pressure,'')||nvl(cit.sara_ct_temperature,'');
      tradesecret := nvl(cit.sara_trade_secret_yn,'N');
      
      open curStorareArea(cu.custid, cit.item);
      fetch curStorareArea into csa;
      close curStorareArea;
      storagearea := csa.zoneid;

      for cao in curAsOf(cu.custid, cf.facility, cit.item)
      loop
        lastdate := trunc(in_begdate) - 1;
        for caos in curAsOfSearch(cu.custid, cf.facility, cit.item, cao.lotnumber,
          cao.uom, cao.invstatus, cao.inventoryclass)
        loop
          if caos.effdate < trunc(in_begdate) then
            update sararpt_dates
               set reportedamt = reportedamt + caos.weight;
          elsif (caos.effdate > trunc(in_enddate)) and (lastdate < trunc(in_begdate)) then
            update sararpt_dates
               set reportedamt = reportedamt + caos.weight;
          else
            update sararpt_dates
               set reportedamt = reportedamt + caos.weight
             where reporteddate > lastdate
               and reporteddate <= caos.effdate;
          end if;
          lastdate := caos.effdate;
        end loop;
      end loop;

      for cb in curBuilding(cf.facility, cu.custid, cit.item)
      loop
        if (cb.building = '8' or cb.building = '89') then
          l_building := '9';
        else
          l_building := cb.building;
        end if;

        if instr(', '||building||',',', '||l_building||',') = 0 then
          if building is not null then
            building := building||', ';
          end if;
          building := building||l_building;
        end if;
      end loop;
    
      totdailyamt := 0;
      maxdailyamt := 0;
      daysonhand := 0;
      
      select nvl(sum(reportedamt),0), nvl(max(reportedamt),0), count(1)
        into totdailyamt, maxdailyamt, daysonhand
        from sararpt_dates
       where reportedamt > 0;
  
      if totdailyamt <> 0 then
        avgdailyamt := totdailyamt / ((trunc(in_enddate) - trunc(in_begdate)) + 1);
        
        select abbrev
          into uomabbrev
          from unitsofmeasure
         where code = cit.baseuom;
         
        insert into sararpt values(numSessionId, cf.facility, cu.custid, cu.name, cit.item, cit.descr, null,
                                   producttype, hazardclass, containertype, null, storagearea,
                                   tradesecret, maxdailyamt, avgdailyamt, daysonhand, building, cit.baseuom,
                                   uomabbrev, cit.weight, null, sysdate, physicalhazard, healthharzard);
        commit;
      end if;
    end loop;
  end loop;
end loop;

open sara_cursor for
select *
  from sararpt
 where sessionid = numSessionId;

end SARARPTNOCASPROC;
/

create or replace PACKAGE Body SARARPTPKG AS
--
-- $Id: zsaraobjects.sql 1417 2007-01-03 00:00:00Z eric $
--

procedure SARARPTPROC
(sara_cursor IN OUT sararptpkg.sara_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
,in_debug_yn IN varchar2)
as
begin
	SARARPTPROC(sara_cursor, in_custid, in_facility, in_begdate, in_enddate, in_debug_yn);
end SARARPTPROC;

function get_physicalhazard
    ( p_custid  varchar2
    , p_item    varchar2
    ) 
    return varchar2
is
    v_result    varchar2(512);
    
begin
    select ltrim( decode(SARA_PH_EXPLOSIVE,              'Y',  '/Explosive'                         ) ||  
                  decode(SARA_PH_FLAMABLE,               'Y',  '/Flammable'                         ) ||
                  decode(SARA_PH_OXIDIZER,               'Y',  '/Oxidizer'                          ) ||
                  decode(SARA_PH_SELF_REACTIVE,          'Y',  '/Self-Reactive'                     ) ||
                  decode(SARA_PH_PYROPH_LIQ_SOLID,       'Y',  '/Pyrophoric (Liquid/Solid)'         ) ||
                  decode(SARA_PH_PYROPHORIC_GAS,         'Y',  '/Pyrophoric Gas'                    ) ||
                  decode(SARA_PH_SELF_HEATING,           'Y',  '/Self-heating'                      ) ||
                  decode(SARA_PH_ORGANIC_PEROXIDE,       'Y',  '/Organic Peroxide'                  ) ||
                  decode(SARA_PH_CORROSIVE_TO_METAL,     'Y',  '/Corrosive to metal'                ) ||
                  decode(SARA_PH_GAS_UNDER_PRESS_COMP,   'Y',  '/Gas under pressure (compressed)'   ) ||
                  decode(SARA_PH_WTR_CONT_EMIT_FLAM_GAS, 'Y',  '/Water contact emits flammable gas' ) ||
                  decode(SARA_PH_COMBUSTIBLE_DUST,       'Y',  '/Combustible Dust'                  ) ||
                  decode(SARA_PH_HAZ_NOT_OTHRWISE_CLASS, 'Y',  '/Hazard Not Otherwise Classified'   ) 
                , '/') 
    into    v_result                
    from    custitem_sara
    where   sara_custid = p_custid
    and     sara_item = p_item;
    
    return  v_result;
        
exception when others then
    return null;

end;

function get_healthhazard
    ( p_custid  varchar2
    , p_item    varchar2
    ) 
    return varchar2
is
    v_result    varchar2(512);
    
begin
    select ltrim( decode(SARA_HH_ACUTE_TOXICITY                , 'Y',   '/Acute Toxicity'                     ) ||
                  decode(SARA_HH_SKIN_CORROS_OR_IRRITA         , 'Y',   '/Skin corrosion or irritation'       ) ||
                  decode(SARA_HH_SERI_EYE_DAM_OR_IRRIT         , 'Y',   '/Serious eye damage or irritation'   ) ||
                  decode(SARA_HH_RESPIR_OR_SKIN_SENSI          , 'Y',   '/Respiratory or skin sensitization'  ) ||
                  decode(SARA_HH_GERM_CELL_MUTAGENICITY        , 'Y',   '/Germ cell mutagenicite'             ) ||
                  decode(SARA_HH_CARCINOGENICITY               , 'Y',   '/Carcinogenicity'                    ) ||
                  decode(SARA_HH_REPRODUCTIVE_TOXICITY         , 'Y',   '/Reproductive toxicity'              ) ||
                  decode(SARA_HH_SPECIFIC_TARG_ORG_TOXI        , 'Y',   '/Specific target organ toxicity'     ) ||
                  decode(SARA_HH_ASPIRATION_HAZARD             , 'Y',   '/Aspiration hazard'                  ) ||
                  decode(SARA_HH_SIMPLE_ASPHYXIANT             , 'Y',   '/Simple asphixiant'                  ) ||
                  decode(SARA_HH_HAZARD_NOT_CLASSIFIED         , 'Y',   '/Hazard Not Classified'              )     
                , '/') 
    into    v_result                
    from    custitem_sara
    where   sara_custid = p_custid
    and     sara_item = p_item;
    
    return  v_result;
        
exception when others then
    return null;

end;

end SARARPTPKG;
/

CREATE OR REPLACE PROCEDURE SARARPTBYYEARPROC
(sara_cursor IN OUT sararptpkg.sara_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_year IN number
,in_debug_yn IN varchar2)
as
year varchar2(4);
begin
	if (in_year >= 1000) and (in_year <= 9999) then
		year := to_char(in_year);
	else
		year := to_char(sysdate,'YYYY');
	end if;
	
	if (year != to_char(sysdate,'YYYY')) then
	  SARARPTPROC(sara_cursor, in_custid, in_facility, to_date('0101'||year,'MMDDYYYY'), to_date('1231'||year,'MMDDYYYY'), in_debug_yn);
	else
	  SARARPTPROC(sara_cursor, in_custid, in_facility, to_date('0101'||year,'MMDDYYYY'), trunc(sysdate), in_debug_yn);
	end if;
end SARARPTBYYEARPROC;
/

CREATE OR REPLACE PROCEDURE SARARPTBYYEARNOCASPROC
(sara_cursor IN OUT sararptpkg.sara_type
,in_custid IN varchar2
,in_facility IN varchar2
,in_year IN number
,in_debug_yn IN varchar2)
as
year varchar2(4);
begin
	if (in_year >= 1000) and (in_year <= 9999) then
		year := to_char(in_year);
	else
		year := to_char(sysdate,'YYYY');
	end if;
	
	if (year != to_char(sysdate,'YYYY')) then
	  SARARPTNOCASPROC(sara_cursor, in_custid, in_facility, to_date('0101'||year,'MMDDYYYY'), to_date('1231'||year,'MMDDYYYY'), in_debug_yn);
	else
	  SARARPTNOCASPROC(sara_cursor, in_custid, in_facility, to_date('0101'||year,'MMDDYYYY'), trunc(sysdate), in_debug_yn);
	end if;
end SARARPTBYYEARNOCASPROC;
/


show errors package SARARPTPKG;
show errors procedure SARARPTPROC;
show errors procedure SARARPTNOCASPROC;
show errors package body SARARPTPKG;
show errors procedure SARARPTBYYEARPROC;
show errors procedure SARARPTBYYEARNOCASPROC;
exit;
