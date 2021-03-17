create or replace trigger userhistory_au
--
-- $Id: userhistory_trigger.sql 7072 2011-08-01 11:27:00Z ed $
--
after update
on userhistory
for each row
declare
begin
   if :old.endtime is null
   and :new.endtime is not null
   and :new.custid is not null then

      if :new.event in ('1LIP',
                        'ALIP',
                        'BPAL',
                        'BURT',
                        'BUUL',
                        'DRTN',
                        'DTRT',
                        'DUNK',
                        'MTTR',
                        'RETR',
                        'RLPW') then
         zoo.inboundactivity(:new.facility, :new.custid, (:new.endtime-:new.begtime)*24);

      elsif :new.event in ('AUDT',
                           'COMP',
                           'DKLD',
                           'DKUL',
                           'DPIK',
                           'LPLD',
                           'LPUL',
                           'OCHK',
                           'REST',
                           'SPMP')
      or (:new.event in ('PICK','STGP') and :new.etc != 'RPPK') then
         zoo.outboundactivity(:new.facility, :new.custid, (:new.endtime-:new.begtime)*24);

      end if;
   end if;
end;
/

show error trigger userhistory_au;

create or replace
trigger userhistory_bu
before update
on userhistory
for each row
declare

function getEquipmentCost (in_equipment varchar2,
                           in_facility varchar2,
                           in_begtime date,
                           in_endtime date)
return number
is
  equipcost equipmentcost.hourlycost%type;
begin
   select round(trunc(((hourlycost/60)/60)*(trunc((in_endtime - in_begtime)*(60*60*24))),2),2)
      into equipcost
      from equipmentcost
	  where equipid = in_equipment
      and facility = in_facility;
	return equipcost;
    exception when others then
      return 0;   
end getEquipmentCost;

function getemployeecost(in_nameid varchar2,
						             in_facility varchar2,
                         in_begtime date,
						             in_endtime date)
return number
is
  empcost userhistory.employeecost%type;
begin
    select round(trunc(((hourlycost/60)/60)*(trunc((in_endtime - in_begtime)*(60*60*24))),2),2)
      into empcost
	  from userheader
	  where nameid = in_nameid
        and facility = in_facility;
	return empcost;	
	exception when others then
      return 0; 
end getEmployeeCost;

begin
  if :old.endtime is null and
      :new.endtime is not null and
      :new.custid is not null then
	      :new.equipmentcost := getequipmentcost(:old.equipment, :old.facility, :old.begtime, :new.endtime);
        :new.employeecost := getemployeecost(:old.nameid, :old.facility, :old.begtime, :new.endtime);
   end if;
end;
/

show error trigger userhistory_bu;
exit;
