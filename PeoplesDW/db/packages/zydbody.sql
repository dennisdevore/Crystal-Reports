create or replace package body alps.zyard as
--
-- $Id: zydbody.sql 727 2006-03-27 16:12:12Z ed $
--
procedure get_yard_totals
(in_yard in varchar2
,out_empties_in_yard out number
,out_loaded_in_yard out number
,out_empties_in_door out number
,out_loading_in_door out number
,out_loaded_in_door out number
,out_msg out varchar2
)
is

begin

out_msg := 'OKAY';

select count(1)
  into out_empties_in_yard
  from trailer
 where facility = in_yard
   and nvl(contents_status,'z') = 'E';

select count(1)
  into out_loaded_in_yard
  from trailer
 where facility = in_yard
   and nvl(contents_status,'z') != 'E';
/*
select count(1)
  into out_empties_in_door
  from loads l, door d
 where d.facility in
   (select dc_facility
      from facilities_for_yard fy
     where fy.yard_facility = in_yard)
   and d.loadno = l.loadno
   and l.loadstatus = 'E';

select count(1)
  into out_loading_in_door
  from loads l, door d
 where d.facility in
   (select dc_facility
      from facilities_for_yard fy
     where fy.yard_facility = in_yard)
   and d.loadno = l.loadno
   and l.loadstatus not in ('E','8');

select count(1)
  into out_loaded_in_door
  from loads l, door d
 where d.facility in
   (select dc_facility
      from facilities_for_yard fy
     where fy.yard_facility = in_yard)
   and d.loadno = l.loadno
   and l.loadstatus = '8';

*/
select count(1)
  into out_empties_in_door
  from loads l, door d
 where d.facility = in_yard
   and d.loadno = l.loadno
   and l.loadstatus = 'E';

select count(1)
  into out_loading_in_door
  from loads l, door d
 where d.facility = in_yard
   and d.loadno = l.loadno
   and l.loadstatus not in ('E','8');

select count(1)
  into out_loaded_in_door
  from loads l, door d
 where d.facility = in_yard
   and d.loadno = l.loadno
   and l.loadstatus = '8';

exception when OTHERS then
  out_msg := substr(sqlerrm, 1, 80);
end get_yard_totals;

procedure validate_trailer
(in_loadno in number
,in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,in_facility in varchar2
,out_errorno out number
,out_message out varchar2
)
is

l_loadno trailer.loadno%type;
l_disposition trailer.disposition%type;
l_use_yard facility.use_yard%type;
l_facility facility.facility%type;
l_loadstatus loads.loadstatus%type;
l_current_trailer loads.trailer%type;
begin

out_errorno := 0;
out_message := 'OKAY';
l_loadno := 0;

if rtrim(in_trailer_number) is null then
  return;
end if;

if rtrim(in_carrier) is null then
  out_errorno := -1;
  out_message := 'Carrier required for trailer assignment';
  return;
end if;

begin
   select nvl(USE_YARD,'N'), l_facility into l_use_yard, l_facility
      from facility
      where facility = in_facility;
exception when no_data_found then
   return;
end;

if l_use_yard = 'N' then
   return;
end if;

begin
  select nvl(loadno,0), nvl(disposition,'non')
    into l_loadno, l_disposition
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_message := 'Trailer ' || in_trailer_number || ' not found';
  return;
end;

if (l_loadno != 0) and
   (l_loadno != in_loadno) then
  out_errorno := -2;
  out_message := 'This trailer is already assigned to load ' || l_loadno;
end if;

if l_facility != in_facility then
   out_errorno := -3;
   out_message := 'This trailer is not in facility ' || in_facility;
end if;
/*
if l_disposition not in ('INY','DC') then --load status
if
   out_errorno := -4;
   out_message := 'This trailer is not in the yard or DC ' || in_facility || ' ' || l_disposition;
end if;
*/

begin
select loadstatus, trailer
   into l_loadstatus, l_current_trailer
    from loads
   where loadno = in_loadno
     and facility = in_facility;
exception when no_data_found then
   return;
end;

if l_loadstatus in ('A') and l_current_trailer is not null then
    out_errorno := -4;
    out_message := 'You can not assign the trailer since the load status is ' || l_loadstatus || ' and trailer already assigned' ;
end if;

exception when others then
  out_errorno := sqlcode;
  out_message := substr(sqlerrm,1,80);
end validate_trailer;

procedure update_trailer
(in_loadno in number
,in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,out_errorno out number
,out_message out varchar2
,in_location in varchar2 default null
)

is

cursor curLoad is
  select *
    from loads
   where loadno = in_loadno;
LOD loads%rowtype;

cursor curTrailer is
  select *
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
TRL trailer%rowtype;

l_old_trailer_number trailer.trailer_number%type;
LDCount integer;
begin

out_errorno := 0;
out_message := 'OKAY';

LOD :=  null;
open curLoad;
fetch curLoad into LOD;
close curLoad;

if LOD.loadno is null then
  out_errorno := -1;
  out_message := 'Load not found';
  return;
end if;

begin
  select trailer_number
    into l_old_trailer_number
    from trailer
   where loadno = in_loadno;
  if l_old_trailer_number != nvl(in_trailer_number,'x') then
    update trailer
       set loadno = null,
           activity_type = 'DFL',
           location = decode(in_location,null,location,in_location),
           lastuser = in_userid,
           lastupdate = sysdate
     where carrier = in_carrier
       and trailer_number = l_old_trailer_number;
  end if;
exception when others then
  l_old_trailer_number := null;
end;

TRL :=  null;
open curTrailer;
fetch curTrailer into TRL;
close curTrailer;

if TRL.trailer_number is not null then
  if nvl(TRL.loadno,0) != 0 and
     TRL.loadno != in_loadno then
    out_errorno := -3;
    out_message := 'This trailer is already assigned to load ' || TRL.loadno;
    return;
  end if;
  /*
  if LOD.loadstatus = '9' and
     nvl(TRL.loadno,0) != 0 then
    update trailer
       set loadno = null,
           disposition = 'SHP',
           activity_type = 'DFL',
           lastuser = in_userid,
           lastupdate = sysdate
     where nvl(carrier,'(xx)') = nvl(TRL.carrier,'(xx)')
       and trailer_number = TRL.trailer_number;
  end if;
  */
  if LOD.loadstatus in ('R','X') and
     nvl(TRL.loadno,0) != 0 then
    update trailer
       set loadno = null,
           activity_type = 'DFL',
           disposition = 'DC',
           contents_status = 'E',
           lastuser = in_userid,
           lastupdate = sysdate
     where nvl(carrier,'(xx)') = nvl(TRL.carrier,'(xx)')
       and trailer_number = TRL.trailer_number;
     return;
  end if;
  if nvl(TRL.loadno,0) != 0 and
     TRL.carrier = LOD.carrier and
     TRL.appointment_date = LOD.apptdate then
    return;
  end if;
end if;

TRL.carrier := LOD.carrier;
TRL.contents_status := 'H';
TRL.trailer_status := 'OK';
TRL.loadno := LOD.loadno;
TRL.disposition := 'DC';

if substr(LOD.loadtype,1,1) = 'I' then
  TRL.expected_time_in := LOD.apptdate;
  TRL.expected_time_out := NULL;
  TRL.activity_type := 'ATI';
else
  TRL.expected_time_out := LOD.apptdate;
  TRL.expected_time_in := NULL;
  TRL.activity_type := 'ATO';
end if;

if (TRL.trailer_number is null) or
   (nvl(TRL.loadno,0) != in_loadno) then
  TRL.put_on_water := LOD.putonwater;
  TRL.eta_to_port := LOD.etatoport;
  TRL.arrived_at_port := LOD.arrivedatport;
  TRL.last_free_date := LOD.lastfreedate;
  TRL.carrier_contact_date := LOD.carriercontactdate;
  TRL.arrived_in_yard := LOD.arrivedinyard;
  TRL.appointment_date := LOD.appointmentdate;
  TRL.due_back := LOD.dueback;
  TRL.returned_to_port := LOD.returnedtoport;
end if;

if TRL.trailer_number is null then
  begin
    select default_trailer_style, default_trailer_type
      into TRL.style, TRL.trailer_type
      from carrier
     where carrier = LOD.carrier;
  exception when others then
    TRL.style := '???';
    TRL.trailer_type := '???';
  end;
  if rtrim(in_trailer_number) is not null then
    insert into trailer
     (TRAILER_NUMBER,TRAILER_LPID,FACILITY,LOCATION,CARRIER,CONTENTS_STATUS,
      TRAILER_STATUS,LOADNO,STYLE,TRAILER_TYPE,DISPOSITION,ACTIVITY_TYPE,
      EXPECTED_TIME_IN,GATE_TIME_IN,EXPECTED_TIME_OUT,GATE_TIME_OUT,PUT_ON_WATER,
      ETA_TO_PORT,ARRIVED_AT_PORT,LAST_FREE_DATE,CARRIER_CONTACT_DATE,
      ARRIVED_IN_YARD,APPOINTMENT_DATE,DUE_BACK,RETURNED_TO_PORT,LASTUSER,
      LASTUPDATE)
     values
     (in_trailer_number,TRL.TRAILER_LPID,TRL.FACILITY,TRL.LOCATION,TRL.CARRIER,
      TRL.CONTENTS_STATUS,TRL.TRAILER_STATUS,TRL.LOADNO,TRL.STYLE,TRL.TRAILER_TYPE,
      TRL.DISPOSITION,TRL.ACTIVITY_TYPE,TRL.EXPECTED_TIME_IN,TRL.GATE_TIME_IN,
      TRL.EXPECTED_TIME_OUT,TRL.GATE_TIME_OUT,TRL.PUT_ON_WATER,TRL.ETA_TO_PORT,
      TRL.ARRIVED_AT_PORT,TRL.LAST_FREE_DATE,TRL.CARRIER_CONTACT_DATE,TRL.ARRIVED_IN_YARD,
      TRL.APPOINTMENT_DATE,TRL.DUE_BACK,TRL.RETURNED_TO_PORT,in_userid,sysdate);
  end if;
else
  select count(1) into LDCount
     from location
     where facility = LOD.facility
       and locid = nvl(LOD.doorloc,'(none)')
       and loctype = 'DOR';
  if LDCount > 0 and
     LOD.loadstatus > '2' and
     LOD.loadtype <> 'OUTC' then
     update trailer
        set activity_type = TRL.activity_type,
            expected_time_in = TRL.expected_time_in,
            expected_time_out = TRL.expected_time_out,
            loadno = in_loadno,
            location = LOD.doorloc,
            disposition = 'DC',
            lastuser = in_userid,
            lastupdate = sysdate
        where carrier = in_carrier
        and trailer_number = in_trailer_number;
  else
     update trailer
        set activity_type = TRL.activity_type,
            expected_time_in = TRL.expected_time_in,
            expected_time_out = TRL.expected_time_out,
            loadno = in_loadno,
            lastuser = in_userid,
            lastupdate = sysdate
        where carrier = in_carrier
        and trailer_number = in_trailer_number;
  end if;
end if;

exception when others then
  out_errorno := sqlcode;
  out_message := substr(sqlerrm,1,80);
end update_trailer;

function has_cust_data
(in_loadno in number
,in_disposition in varchar2
,in_custid in varchar2
,in_item in varchar2
)
return varchar2

is

l_rowcount pls_integer;

begin

if nvl(in_disposition,'x') != 'INY' then
  return 'N';
end if;

if nvl(in_loadno,0) = 0 then
  return 'N';
end if;

l_rowcount := 0;
if rtrim(in_custid) is not null and
  rtrim(in_item) is not null then
  select count(1)
    into l_rowcount
    from orderdtl od, orderhdr oh
   where oh.loadno = in_loadno
     and oh.custid = in_custid
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and od.item = in_item;
elsif rtrim(in_custid) is not null then
  select count(1)
    into l_rowcount
    from orderhdr
   where loadno = in_loadno
     and custid = in_custid
     and orderstatus != 'X';
elsif rtrim(in_item) is not null then
  select count(1)
    into l_rowcount
    from orderhdr
   where loadno = in_loadno
     and custid = in_custid
     and orderstatus != 'X';
  select count(1)
    into l_rowcount
    from orderdtl od, orderhdr oh
   where oh.loadno = in_loadno
     and oh.custid = in_custid
     and oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and od.item = in_item;
end if;

if l_rowcount != 0 then
  return 'Y';
else
  return 'N';
end if;

exception when others then
  return 'N';
end has_cust_data;

procedure move_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is

l_disposition trailer.disposition%type;
l_loc_status location.status%type;
l_loctype location.loctype%type;
begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition
    into l_disposition
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Carrier/trailer not found';
  return;
end;

if l_disposition not in ('INY','DC') then
  out_errorno := -2;
  out_msg := 'Trailer is not in yard';
  return;
end if;

begin
  select status, loctype
    into l_loc_status, l_loctype
    from location
   where facility = in_yard_facility
     and locid = in_yard_location;
exception when others then
  out_errorno := -3;
  out_msg := 'Location not found';
  return;
end;
if l_loctype != 'YRD' then
   out_errorno := -4;
   out_msg := 'Location not in Yard';
   return;
end if;


update trailer
   set location = in_yard_location,
       activity_type = 'MVD',
       disposition = 'INY',
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

if sql%rowcount = 0 then
  out_errorno := -4;
  out_msg := 'Trailer not updated';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end move_trailer;

procedure move_closed_load_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is

l_disposition trailer.disposition%type;
l_loc_status location.status%type;

begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition
    into l_disposition
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Carrier/trailer not found';
  return;
end;

begin
  select status
    into l_loc_status
    from location
   where facility = in_yard_facility
     and locid = in_yard_location;
exception when others then
  out_errorno := -3;
  out_msg := 'Location not found';
  return;
end;

update trailer
   set location = in_yard_location,
       facility = in_yard_facility,
       disposition = 'INY',
       activity_type = 'MVD',
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

if sql%rowcount = 0 then
  out_errorno := -4;
  out_msg := 'Trailer not updated';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end move_closed_load_trailer;

procedure assign_trailer_to_load
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_loadno varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is

l_disposition trailer.disposition%type;
l_loadno trailer.loadno%type;
l_activity_type trailer.activity_type%type;
l_loadtype loads.loadtype%type;
l_loadstatus loads.loadstatus%type;
l_trailer loads.trailer%type;
l_carrier loads.carrier%type;
l_facility loads.facility%type;
l_doorloc loads.doorloc%type;
LDCount integer;
begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition, loadno
    into l_disposition, l_loadno
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Trailer not found';
  return;
end;

if nvl(l_loadno,0) != 0 then
  out_errorno := -2;
  out_msg := 'Trailer is already assigned to a load';
end if;

begin
  select loadtype, loadstatus, trailer, carrier, facility, doorloc
    into l_loadtype, l_loadstatus, l_trailer, l_carrier, l_facility, l_doorloc
    from loads
   where loadno = in_loadno;
exception when others then
  out_errorno := -3;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end;

if rtrim(l_trailer) is not null then
  out_errorno := -4;
  out_msg := 'Load already has a trailer assignment';
  return;
end if;
if l_carrier <> in_carrier then
  out_msg := 'Load carrier ' || l_carrier || ' does not match trailer carrier ';
  out_errorno := -5;
  return;
end if;

if l_loadstatus = 'X' then
  out_errorno := -10;
  out_msg := 'Load is cancelled';
  return;
end if;

if substr(l_loadtype,1,1) = 'I' then
  if l_loadstatus = 'R' then
    out_errorno := -10;
    out_msg := 'Load is already received';
    return;
  end if;
  l_activity_type := 'ATI';
else
  if l_loadstatus = '9' then
    out_errorno := -10;
    out_msg := 'Load is already shipped';
    return;
  end if;
  l_activity_type := 'ATO';
end if;
select count(1) into LDCount
   from location
   where facility = l_facility
     and locid = nvl(l_doorloc,'(none)')
     and loctype = 'DOR';
if LDCount > 0 then
   if l_loadtype = 'INC' then
      if l_loadstatus > '2' then
     --   l_loadstatus >= '2' then
         update trailer
            set activity_type = l_activity_type,
                loadno = in_loadno,
                location = l_doorloc,
                disposition = 'DC',
                lastuser = in_userid,
                lastupdate = sysdate
            where carrier = in_carrier
            and trailer_number = in_trailer_number;
      else
         update trailer
            set loadno = in_loadno,
                activity_type = l_activity_type,
                lastuser = in_userid,
                lastupdate = sysdate
              where carrier = in_carrier
              and trailer_number = in_trailer_number;
      end if;
   else
      update trailer
         set loadno = in_loadno,
             activity_type = l_activity_type,
             lastuser = in_userid,
             lastupdate = sysdate
           where carrier = in_carrier
           and trailer_number = in_trailer_number;
   end if;
end if;
if sql%rowcount = 0 then
  out_errorno := -5;
  out_msg := 'Trailer update failed';
end if;

update loads
   set trailer = in_trailer_number,
       carrier = in_carrier,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

if sql%rowcount = 0 then
  out_errorno := -6;
  out_msg := 'Load update failed';
end if;

zlh.add_loadhistory(in_loadno,
     'Trailer To Load',
     'Trailer Assigned '|| in_trailer_number,
     in_userid, out_msg);


exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end assign_trailer_to_load;

procedure deassign_trailer_from_load
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is

l_disposition trailer.disposition%type;
l_loadno trailer.loadno%type;
l_loctype location.loctype%type;

begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition, loadno
    into l_disposition, l_loadno
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Trailer not found';
  return;
end;

if nvl(l_loadno,0) = 0 then
  out_errorno := -2;
  out_msg := 'Trailer is not assigned to a load';
end if;

if in_location is not null then
  begin
    select loctype
      into l_loctype
      from location
     where facility = in_facility
       and locid = in_location;
   exception when others then
    out_errorno := -5;
    out_msg := 'Location not found';
    return;
  end;
  if l_loctype != 'YRD' then
     out_errorno := -6;
     out_msg := 'Location not in Yard';
     return;
  end if;
end if;

update trailer
   set loadno = null,
       location = decode(in_location, null, location, in_location),
       activity_type = 'DFL',
       --disposition = 'INY',
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

if sql%rowcount = 0 then
  out_errorno := -3;
  out_msg := 'Trailer update failed';
end if;

update loads
   set trailer = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = l_loadno;

if sql%rowcount = 0 then
  out_errorno := -4;
  out_msg := 'Load update failed';
end if;
zlh.add_loadhistory(l_loadno,
     'Trailer Deassigned',
     'Trailer deassigned from load '|| in_trailer_number,
     in_userid, out_msg);

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end deassign_trailer_from_load;

procedure late_trailer_check

is

l_msg appmsgs.msgtext%type;
l_out_msg appmsgs.msgtext%type;
l_tot pls_integer;

begin

l_msg := 'Begin late trailer check...';
zms.log_autonomous_msg('SYNAPSE', null, null, l_msg, 'I', 'SYNAPSE', l_out_msg);

l_tot := 0;

for trl in
 (select trailer_number,rowid
    from trailer
   where disposition = 'INT'
     and exists (select 1
                   from loads
                  where trailer.loadno = loads.loadno
                    and substr(loadtype,1,1) = 'I'
                    and loadstatus < 'A')
     and sysdate > expected_time_in
     and trailer_status = 'OK')
loop
  update trailer
     set trailer_status = 'LFA',
         activity_type = 'LFA',
         lastuser = 'SYNAPSE',
         lastupdate = sysdate
   where rowid = trl.rowid;
end loop;

l_msg := 'End late trailer check--Update count: ' || l_tot;
zms.log_autonomous_msg('SYNAPSE', null, null, l_msg, 'I', 'SYNAPSE', l_out_msg);

exception when others then
  l_msg := 'Late trailer check exception: ' || substr(sqlerrm, 1, 200);
  zms.log_autonomous_msg('SYNAPSE', null, null, l_msg, 'E', 'SYNAPSE', l_out_msg);
end late_trailer_check;

procedure check_trailer_in
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_yard_facility in varchar2
,in_yard_location in varchar2
,in_loadno in number
,in_gate_time_in in date
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)

is

l_disposition trailer.disposition%type;
l_loadno trailer.loadno%type;
l_loc_status location.status%type;
l_carrier loads.carrier%type;
l_trailer loads.trailer%type;

begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition, loadno
    into l_disposition, l_loadno
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Trailer not found';
  return;
end;

if l_disposition not in ('INT','DC', 'SHP') then
  out_errorno := -2;
  out_msg := 'Trailer is not in transit';
  return;
end if;

if rtrim(in_yard_location) is not null then
  begin
    select status
      into l_loc_status
      from location
     where facility = in_yard_facility
       and locid = in_yard_location;
  exception when others then
    out_errorno := -3;
    out_msg := 'Location not found';
    return;
  end;
end if;

if nvl(l_loadno,0) != 0 then
  if l_loadno != in_loadno then
    out_errorno := -4;
    out_msg := 'Trailer is already assigned to a load';
    return;
  end if;
end if;
if nvl(in_loadno,0) != 0 then
  begin
     select nvl(carrier,'nOne'), nvl(trailer,'(none)') into l_carrier, l_trailer
        from loads
        where loadno = in_loadno;
  exception when no_data_found then
     out_errorno := -5;
     out_msg := 'Load does not exist';
     return;
  end;
  if l_trailer <> '(none)' and l_trailer <> in_trailer_number then
     out_errorno := -5;
     out_msg := 'Load already has trailer';
     return;
  end if;
  if l_carrier <> in_carrier and
     l_trailer <> '(none)' then
     out_errorno := -5;
     out_msg := 'Load carrier does not match: '||l_carrier;
     return;
  end if;
  update loads
     set trailer = in_trailer_number,
         carrier = decode(carrier, null, in_carrier, carrier)
     where loadno = in_loadno;
end if;

update trailer
   set location = in_yard_location,
      gate_time_in = in_gate_time_in,
      gate_time_out = null,
      activity_type = 'IN',
      carrier = decode(carrier,null,in_carrier, carrier),
      loadno = decode(in_loadno,0,null,in_loadno),
      facility = in_yard_facility,
      disposition = 'INY',
      lastuser = in_userid,
      lastupdate = sysdate
    where carrier = in_carrier
    and trailer_number = in_trailer_number;

if sql%rowcount = 0 then
  out_errorno := -5;
  out_msg := 'Trailer not updated';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end check_trailer_in;

procedure check_trailer_out
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,in_gate_time_out in date
,out_errorno out number
,out_msg out varchar2
)
is

l_disposition trailer.disposition%type;
l_loadno trailer.loadno%type;
l_loadtype loads.loadtype%type;

begin

out_msg := 'OKAY';
out_errorno := 0;

begin
  select disposition, loadno
    into l_disposition, l_loadno
    from trailer
     where carrier = in_carrier
     and trailer_number = in_trailer_number;
exception when others then
  out_errorno := -1;
  out_msg := 'Trailer not found';
  return;
end;

if (l_disposition != 'INY') and not (l_disposition = 'DC' and nvl(l_loadno,0) = 0) then
  out_errorno := -2;
  out_msg := 'Trailer is not in yard';
  return;
end if;

if nvl(l_loadno,0) = 0 then
  l_disposition := 'SHP';
else
  begin
    select loadtype
      into l_loadtype
      from loads
     where loadno = l_loadno;
  exception when others then
    out_errorno := -3;
    out_msg := 'Load not found';
    return;
  end;
  if substr(l_loadtype,1,1) = 'I' then
    l_disposition := 'INT';
  else
    l_disposition := 'SHP';
  end if;
end if;
/* update twice to create 2 history records for reporting */
update trailer
   set location = null,
       gate_time_out = in_gate_time_out,
       disposition = l_disposition,
       activity_type = 'OUT',
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

update trailer
   set facility = null,
       activity_type = 'LFF'
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

if sql%rowcount = 0 then
  out_errorno := -5;
  out_msg := 'Trailer not updated';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end check_trailer_out;

procedure back_to_intransit
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is
  l_disposition trailer.disposition%type;
begin

  out_msg := 'OKAY';
  out_errorno := 0;

  begin
    select disposition
      into l_disposition
      from trailer
       where carrier = in_carrier
       and trailer_number = in_trailer_number;
  exception when others then
    out_errorno := -1;
    out_msg := 'Trailer not found';
    return;
  end;

  if l_disposition not in ('INY') then
    out_errorno := -2;
    out_msg := 'Trailer is not in yard';
    return;
  end if;

  update trailer
   set location = null,
       gate_time_in = null,
       disposition = 'INT',
       activity_type = 'UPD',
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

  if sql%rowcount = 0 then
    out_errorno := -5;
    out_msg := 'Trailer not updated';
  end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end back_to_intransit;

procedure release_trailer
(in_carrier in varchar2
,in_trailer_number in varchar2
,in_location in varchar2
,in_userid in varchar2
,out_errorno out number
,out_msg out varchar2
)
is
  l_loadno trailer.loadno%type;
  l_location trailer.location%type;
  l_facility trailer.facility%type;
  l_loctype location.loctype%type;
  l_disposition trailer.disposition%type;
begin

  out_msg := 'OKAY';
  out_errorno := 0;

  begin
    select disposition, location, facility, loadno
      into l_disposition, l_location, l_facility, l_loadno
      from trailer
       where carrier = in_carrier
       and trailer_number = in_trailer_number;
  exception when no_data_found then
    out_errorno := -1;
    out_msg := 'Trailer not found';
    return;
  end;

  if l_disposition not in ('DC') then
    out_errorno := -2;
    out_msg := 'Trailer is not in door';
    return;
  end if;
  begin
    select loctype into l_loctype
       from location
       where facility = l_facility
         and locid = l_location;
  exception when no_data_found then
    l_loctype := 'zz';
  end;
  if l_loctype <> 'DOR' then
     out_errorno := -3;
     out_msg := 'Trailer is not in door';
     return;
  end if;



  update trailer
   set location = nvl(in_location,location),
       disposition = decode(in_location, null, disposition, 'INY'),
       activity_type = 'REL',
       contents_status = 'E',
       loadno = null,
       lastuser = in_userid,
       lastupdate = sysdate
     where carrier = in_carrier
     and trailer_number = in_trailer_number;

  if sql%rowcount = 0 then
    out_errorno := -5;
    out_msg := 'Trailer not updated';
  end if;
zlh.add_loadhistory(l_loadno,
     'Trailer Released',
     'Trailer released '|| in_trailer_number,
     in_userid, out_msg);

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm, 1, 80);
end release_trailer;

end zyard;
/
show errors package zyard;
show errors package body zyard;

exit;
