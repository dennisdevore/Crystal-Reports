create or replace PACKAGE BODY alps.zloadentry
is
--
-- $Id$
--

FUNCTION inbound_variance_on_order
(in_orderid IN number
,in_shipid IN number
)
return varchar2

is

l_variance_count number;

begin

l_variance_count := 0;

select count(1)
  into l_variance_count
  from orderhdr oh
 where orderid = in_orderid
   and shipid = in_shipid
   and ((exists (select 1
                 from orderdtl od
                where od.orderid = oh.orderid
                  and od.shipid = oh.shipid
                  and od.linestatus != 'X'
                  and nvl(od.qtyorder,0) <> nvl(od.qtyrcvd,0)))
          or
        (nvl(asnvariance,'N') = 'Y'));

if l_variance_count <> 0 then
  return 'Y';
else
  return 'N';
end if;

exception when others then
  return 'N';
end inbound_variance_on_order;

PROCEDURE get_next_loadno
(out_loadno OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select loadseq.nextval
    into out_loadno
    from dual;
  select count(1)
    into currcount
    from loads
   where loadno = out_loadno;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldgnl ' || sqlerrm;
end get_next_loadno;

FUNCTION loadtype_abbrev
(in_loadtype IN varchar2
) return varchar2 is

out loadtypes%rowtype;

begin

out.abbrev := '';

select abbrev
  into out.abbrev
  from loadtypes
 where code = in_loadtype;

return out.abbrev;

exception when others then
  return 'Unknown';
end loadtype_abbrev;

FUNCTION loads_rcvddate
(in_loadno IN number
) return date is

out_rcvddate date;

begin

out_rcvddate := null;

select rcvddate
  into out_rcvddate
  from loads
 where loadno = in_loadno;

return out_rcvddate;

exception when others then
  return out_rcvddate;
end loads_rcvddate;

FUNCTION unknown_lip_count
(in_loadno IN number
) return number is

out_count integer;

begin

out_count := 0;

select count(1)
  into out_count
  from plate
 where loadno = in_loadno
   and item = 'UNKNOWN';

return out_count;

exception when others then
  return 0;
end unknown_lip_count;

PROCEDURE assign_inbound_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

theApt number;
theAptDate date;

cursor Corderhdr is
  select nvl(OH.orderstatus,'?') as orderstatus,
         nvl(OH.loadno,0) as loadno,
         nvl(OH.ordertype,'?') as ordertype,
         nvl(OH.tofacility,' ') as tofacility,
         nvl(OH.qtyorder,0) as qtyorder,
         nvl(OH.weightorder,0) as weightorder,
         nvl(OH.cubeorder,0) as cubeorder,
         nvl(OH.amtorder,0) as amtorder,
         OH.carrier,
         nvl(CU.paperbased, 'N') as paperbased,
         nvl(OH.weight_entered_lbs,0) as weight_entered_lbs,
         nvl(OH.weight_entered_kgs,0) as weight_entered_kgs
    from orderhdr OH, customer CU
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and CU.custid (+) = OH.custid;
oh Corderhdr%rowtype;

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         billoflading,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

cursor curCarrier(in_carrier in varchar2) is
  select nvl(multiship,'N') as multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

begin

out_msg := '';

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;

if oh.paperbased = 'Y' then
  out_msg := 'Order is for an Aggregate Inventory Customer.  This order may not be assigned to a load.';
  return;
end if;

if (oh.ordertype not in ('R', 'Q', 'T', 'C', 'U')) or
   (oh.ordertype in ('T','U') and oh.tofacility != in_facility) then
  out_msg := 'Not an inbound order';
  return;
end if;

if oh.orderstatus != '1' then
  out_msg := 'Order must be in Entered status';
  return;
end if;

if oh.loadno != 0 then
  out_msg := 'Order is already assigned to load ' || oh.loadno;
  return;
end if;

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if io_loadno <> 0 then
  open Cloads;
  fetch Cloads into ld;
  if Cloads%notfound then
    close Cloads;
    out_msg := 'Load not found: ' || io_loadno;
    return;
  end if;
  close Cloads;
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus > '2' then
    out_msg := 'Invalid load status for assignment: ' || ld.loadstatus;
    return;
  end if;
  if ( (oh.ordertype not in ('T','U')) and (ld.loadtype <> 'INC') ) or
     ( (oh.ordertype in ('T','U'))     and (ld.loadtype <> 'INT') )
  then
    out_msg := 'Load/Order Type mismatch: ' ||
      ld.loadtype || '/' || oh.ordertype;
    return;
  end if;
  if rtrim(in_carrier) is not null then
    ld.carrier := in_carrier;
  end if;
  if rtrim(in_trailer) is not null then
    ld.trailer := in_trailer;
  end if;
  if rtrim(in_seal) is not null then
    ld.seal := in_seal;
  end if;
  if rtrim(in_billoflading) is not null then
    ld.billoflading := in_billoflading;
  end if;
  if rtrim(in_stageloc) is not null then
    ld.stageloc := in_stageloc;
  end if;
  if rtrim(in_doorloc) is not null then
    ld.doorloc := in_doorloc;
  end if;
  update loads
     set loadstatus = '2',
         carrier = ld.carrier,
         trailer = ld.trailer,
         seal = ld.seal,
         billoflading = ld.billoflading,
         stageloc = ld.stageloc,
         doorloc = ld.doorloc,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno;
  update loadstop
     set loadstopstatus = '2',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno;
  if sql%rowcount = 0 then
    out_msg := 'Load/Stop not found: ' ||
      io_loadno || '/' || io_stopno;
    return;
  end if;
  update loadstopship
     set qtyorder = nvl(qtyorder,0) + oh.qtyorder,
         weightorder = nvl(weightorder,0) + oh.weightorder,
         weight_entered_lbs = nvl(weight_entered_lbs,0) + oh.weight_entered_lbs,
         weight_entered_kgs = nvl(weight_entered_kgs,0) + oh.weight_entered_kgs,
         cubeorder = nvl(cubeorder,0) + oh.cubeorder,
         amtorder = nvl(amtorder,0) + oh.amtorder,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and shipno = io_shipno;
  if sql%rowcount = 0 then
    out_msg := 'Load/Stop/Shipment not found: ' ||
      io_loadno || '/' || io_stopno || '/' || io_shipno;
    return;
  end if;
  update orderhdr
     set orderstatus = '3',
         loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
else
  get_next_loadno(io_loadno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
  io_stopno := 1;
  io_shipno := 1;
  if oh.ordertype in ('R', 'Q', 'C') then
    ld.loadtype := 'INC';
  else
    ld.loadtype := 'INT';
  end if;
  insert into loads
   (loadno,entrydate,loadstatus,
    trailer,seal,facility,
    doorloc,stageloc,carrier,
    statususer,statusupdate,
    lastuser,lastupdate,
    billoflading, loadtype)
  values
   (io_loadno,sysdate,'2',
    in_trailer,in_seal,in_facility,
    in_doorloc,in_stageloc,in_carrier,
    in_userid,sysdate,
    in_userid,sysdate,
    in_billoflading, ld.loadtype);
  insert into loadstop
   (loadno,stopno,entrydate,
    loadstopstatus,
    statususer,statusupdate,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,sysdate,
    '2',
    in_userid,sysdate,
    in_userid,sysdate);
  insert into loadstopship
   (loadno,stopno,shipno,
    entrydate,qtyorder,weightorder,
    cubeorder,amtorder,
    lastuser,lastupdate,weight_entered_lbs,weight_entered_kgs)
  values
   (io_loadno,io_stopno,io_shipno,
    sysdate,oh.qtyorder,oh.weightorder,
    oh.cubeorder,oh.amtorder,
    in_userid,sysdate,oh.weight_entered_lbs,oh.weight_entered_kgs);
  if rtrim(in_carrier) is null then
    ld.carrier := oh.carrier;
  else
    ld.carrier := in_carrier;
  end if;
  update orderhdr
     set orderstatus = '3',
         loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         carrier = ld.carrier,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
end if;

-- update appointments
-- if assigning a load with an apt, update the order's apt info
-- else if assigning a load to an order with an apt, update the load's apt info.

select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from loads where loadno = io_loadno;

if theApt > 0 then
   update orderhdr
      set appointmentid = theApt,
                 apptdate = theAptDate
      where orderid = in_orderid
         and shipid = in_shipid;
else
   select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from orderhdr
      where orderid = in_orderid
         and shipid = in_shipid;
     if theApt > 0 then
      update loads
         set appointmentid = theApt,
                   apptdate = theAptDate
      where loadno = io_loadno;

      update orderhdr
         set appointmentid = theApt,
                       apptdate = theAptDate,
             lastuser = in_userid,
                       lastupdate = sysdate
            where loadno = io_loadno;

      update docappointments
         set loadno = io_loadno,
         lastuser = in_userid,
               lastupdate = sysdate
      where appointmentid = theApt;
    end if;
end if;


zoh.add_orderhistory(in_orderid, in_shipid,
     'Order To Load',
     'Order Assigned to Load '||io_loadno||'/'||io_stopno||'/'||io_shipno,
     in_userid, out_msg);

zlh.add_loadhistory(io_loadno,
     'Order To Load',
     'Order '|| in_orderid ||'-'||in_shipid || ' Assigned to Stop/Ship ' ||io_stopno||'/'||io_shipno,
     in_userid, out_msg);



out_msg := 'OKAY';

exception when others then
  out_msg := 'ldaio ' || substr(sqlerrm,1,80);
end assign_inbound_order_to_load;

function calccheckdigit (in_Data in varchar2)
  RETURN varchar2 IS
OutData varchar2(17);
VarData varchar2 (16);
VarNumber number;
BEGIN

  VarData := NULL;

  IF LENGTH(in_Data) <> 16 THEN
    zut.prt(substr('Invalid Field length' || length(in_data),1,60));
    OutData := '99999999999999999';
    RETURN OutData;
  END IF;

  --This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
  VarNumber := TO_NUMBER(SUBSTR(in_Data,1,7));

  --This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
  VarNumber := TO_NUMBER(SUBSTR(in_Data,8,9));

  VarNumber := 10 - MOD(TO_NUMBER(SUBSTR(TRIM(in_Data),1,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),2,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),3,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),4,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),5,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),6,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),7,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),8,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),9,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),10,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),11,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),12,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),13,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),14,1)) * 3 +
    TO_NUMBER(SUBSTR(TRIM(in_Data),15,1)) +
    TO_NUMBER(SUBSTR(TRIM(in_Data),16,1)) * 3,10);

  IF VarNumber = 10 THEN
    VarNumber := 0;
  END IF;

  OutData := in_Data || TO_CHAR(VarNumber);

  RETURN OutData;
EXCEPTION
  WHEN OTHERS THEN
    RETURN '99999999999999999';
end calccheckdigit;

PROCEDURE assign_outbound_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

theApt number;
theAptDate date;

cursor Corderhdr is
  select nvl(OH.orderstatus,'?') as orderstatus,
         nvl(OH.loadno,0) as loadno,
         nvl(OH.stopno,0) as stopno,
         nvl(OH.ordertype,'?') as ordertype,
         nvl(OH.fromfacility,' ') as fromfacility,
         nvl(OH.qtyorder,0) as qtyorder,
         nvl(OH.weightorder,0) as weightorder,
         nvl(OH.cubeorder,0) as cubeorder,
         nvl(OH.amtorder,0) as amtorder,
         nvl(OH.qtyship,0) as qtyship,
         nvl(OH.weightship,0) as weightship,
         nvl(OH.cubeship,0) as cubeship,
         nvl(OH.amtship,0) as amtship,
         OH.carrier,
         nvl(CU.paperbased, 'N') as paperbased,
         nvl(CU.allow_paperbased_loads, 'N') as allow_paperbased_loads,
         OH.wave,
         nvl(OH.weight_entered_lbs,0) as weight_entered_lbs,
         nvl(OH.weight_entered_kgs,0) as weight_entered_kgs,
         OH.custid as custid,
         trim(OH.hdrpassthruchar27) hdrpassthruchar27,
         trim(oh.hdrpassthruchar50) hdrpassthruchar50,
         trim(oh.billoflading) billoflading,
         nvl(OH.shipto, '') as shipto,
         nvl(OH.shiptoname, OH.shipto) as shiptoname,
         decode(oh.shiptoname,null,oh.shipto,oh.shiptoname||oh.shiptoaddr1||oh.shiptoaddr2||oh.shiptocity||oh.shiptostate||oh.shiptopostalcode) as shiptoaddr1addr2,
         oh.shipdate,
         oh.shipterms,
         oh.shiptype,
         OH.original_wave_before_combine
    from orderhdr OH, customer CU
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and CU.custid (+) = OH.custid;
oh Corderhdr%rowtype;

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         trim(billoflading) billoflading,
         trim(ldpassthruchar02) ldpassthruchar02,
         trim(ldpassthruchar40) ldpassthruchar40,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         shipterms,
         shiptype
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

cursor curCarrier(in_carrier in varchar2) is
  select nvl(multiship,'N') as multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

cursor curVICSBOLByLoadHPT50(in_loadno in number, in_facility varchar2, in_hdrpassthruchar50 varchar2) is
   select distinct trim(hdrpassthruchar27) hdrpassthruchar27
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and trim(hdrpassthruchar50) = in_hdrpassthruchar50
      and nvl(trim(hdrpassthruchar27),'(none)') != '(none)'
      and nvl(trim(hdrpassthruchar50),'(none)') != '(none)';
cvbolhpt50 curVICSBOLByLoadHPT50%rowtype;

cursor curVICSBOLByLoadShipTo(in_loadno in number, in_facility varchar2, in_shiptoaddr1addr2 varchar2) is
   select distinct billoflading
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and decode(shiptoname,null,shipto,shiptoname||shiptoaddr1||shiptoaddr2) = in_shiptoaddr1addr2
      and nvl(trim(billoflading),'(none)') != '(none)';
cvbolst curVICSBOLByLoadShipTo%rowtype;

cursor curCustUCC128(in_custid varchar2) is
   select nvl(substr(rpad(manufacturerucc,7,'0'),0,7),'0000000') as manufacturerucc
     from customer
    where custid = in_custid;
cucc curCustUCC128%rowtype;

newloadstatus varchar2(2);
cordid waves.wave%type;
ccombinedwave waves.wave%type;
splitfac_order boolean := false;
l_cnt pls_integer;
stop_flag boolean;
newbilloflading varchar2(40);
custUCC128 varchar2(7);
freightaccessorials varchar2(4000) := '';

begin

out_msg := '';
stop_flag := FALSE;

if io_stopno < 0 then
    stop_flag := TRUE;
    io_stopno := -io_stopno;
end if;

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;

if in_userid = zbbb.AUTHOR then
  cordid := 0;
  ccombinedwave := 0;
else
  cordid := zcord.cons_orderid(in_orderid, in_shipid);
  if (nvl(oh.original_wave_before_combine,0) <> 0) then
    ccombinedwave := zcord.cons_orderid(oh.original_wave_before_combine, 0);
  else
    ccombinedwave := 0;
  end if;
end if;

if oh.paperbased = 'Y' and oh.allow_paperbased_loads <> 'Y' then
  out_msg := 'Order is for an Aggregate Inventory Customer.  This order may not be assigned to a load.';
  return;
end if;

if (oh.ordertype in ('R', 'Q', 'P', 'A', 'C', 'I')) or
   (oh.ordertype in ('T','U') and oh.fromfacility != in_facility) then
  out_msg := 'Not an outbound order';
  return;
end if;

if oh.orderstatus > '6' then
  out_msg := 'Invalid order status: ' || oh.orderstatus;
  return;
end if;

if oh.loadno != 0 then
  out_msg := 'Order is already assigned to load ' || oh.loadno;
  return;
end if;

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if oh.carrier is not null then
  ca := null;
  open curCarrier(oh.carrier);
  fetch curCarrier into ca;
  close curCarrier;
  if ca.multiship = 'Y' then
    out_msg := 'Order is associated with a MultiShip Carrier: ' || oh.carrier;
    return;
  end if;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

begin
  select ca.freight_accessorials
    into freightaccessorials
    from ConsigneeAccessorials ca
   where ca.Consignee = oh.shipto
     and Tariff =
        (select Tariff from custfacility where custid = oh.custid and facility = oh.fromfacility);
exception when no_data_found then
  null;
when others then
  out_msg := 'ldafo ' || substr(sqlerrm,1,80);
  return;
end;

splitfac_order := is_split_facility_order(in_orderid, in_shipid);
if io_loadno <> 0 then
  open Cloads;
  fetch Cloads into ld;
  if Cloads%notfound then
    close Cloads;
    out_msg := 'Load not found: ' || io_loadno;
    return;
  end if;
  close Cloads;
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus > '8' then
    out_msg := 'Invalid load status for assignment: ' || ld.loadstatus;
    return;
  end if;
  if ( (oh.ordertype not in ('T','U'))  and (ld.loadtype <> 'OUTC') ) or
     ( (oh.ordertype in ('T','U'))      and (ld.loadtype <> 'OUTT') )
  then
    out_msg := 'Load/Order Type mismatch: ' ||
      ld.loadtype || '/' || oh.ordertype;
    return;
  end if;
  select count(1) into l_cnt
    from orderhdr
    where loadno = io_loadno;
  if l_cnt > 0 then
    select count(1) into l_cnt
      from orderhdr
      where loadno = io_loadno
        and ordertype = 'U';
    if (l_cnt = 0 and oh.ordertype = 'U')
    or (l_cnt != 0 and oh.ordertype != 'U') then
      out_msg := 'Transfer of ownership orders cannot be mixed with other order types';
      return;
    end if;
  end if;
  if rtrim(in_carrier) is not null then
    ld.carrier := in_carrier;
  end if;
  if rtrim(in_trailer) is not null then
    ld.trailer := in_trailer;
  end if;
  if rtrim(in_seal) is not null then
    ld.seal := in_seal;
  end if;
  if rtrim(in_billoflading) is not null then
    ld.billoflading := in_billoflading;
  end if;
  if rtrim(in_stageloc) is not null then
    ld.stageloc := in_stageloc;
  end if;
  if rtrim(in_doorloc) is not null then
    ld.doorloc := in_doorloc;
  end if;
  update loads
     set carrier = ld.carrier,
         trailer = ld.trailer,
         seal = ld.seal,
         billoflading = ld.billoflading,
         stageloc = ld.stageloc,
         doorloc = ld.doorloc,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno;
  update loadstopship
     set qtyorder = nvl(qtyorder,0) + oh.qtyorder,
         weightorder = nvl(weightorder,0) + oh.weightorder,
         weight_entered_lbs = nvl(weight_entered_lbs,0) + oh.weight_entered_lbs,
         weight_entered_kgs = nvl(weight_entered_kgs,0) + oh.weight_entered_kgs,
         cubeorder = nvl(cubeorder,0) + oh.cubeorder,
         amtorder = nvl(amtorder,0) + oh.amtorder,
         qtyship = nvl(qtyship,0) + oh.qtyship,
         weightship = nvl(weightship,0) + oh.weightship,
         weightship_kgs = nvl(weightship_kgs,0)
                        + nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0),
         cubeship = nvl(cubeship,0) + oh.cubeship,
         amtship = nvl(amtship,0) + oh.amtship,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and shipno = io_shipno;
  if sql%rowcount = 0 then
    if stop_flag then

      insert into loadstop
       (loadno,stopno,entrydate,
        loadstopstatus, FREIGHT_ACCESSSORIALS,
        statususer,statusupdate,
        lastuser,lastupdate)
      values
       (io_loadno,io_stopno,sysdate,
        '2', freightaccessorials,
        in_userid,sysdate,
        in_userid,sysdate);
      insert into loadstopship
       (loadno,stopno,shipno,
        entrydate,
        qtyorder,weightorder,
        cubeorder,amtorder,
        qtyship,weightship,
        cubeship,amtship,
        lastuser,lastupdate,
        weight_entered_lbs,weight_entered_kgs,
        weightship_kgs)
      values
       (io_loadno,io_stopno,io_shipno,
        sysdate,
        oh.qtyorder,oh.weightorder,
        oh.cubeorder,oh.amtorder,
        oh.qtyship,oh.weightship,
        oh.cubeship,oh.amtship,
        in_userid,sysdate,
        oh.weight_entered_lbs,oh.weight_entered_kgs,
        nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0));
    else
        out_msg := 'Load/Stop/Shipment not found: ' ||
        io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
    end if;
  end if;
  if splitfac_order then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and orderstatus != 'X'
       and nvl(loadno,0) = 0;
    for soh in (select qtyorder, weightorder, cubeorder, amtorder,
                       qtyship, weightship, cubeship, amtship,
                       weight_entered_lbs, weight_entered_kgs, custid
                  from orderhdr
                 where orderid = in_orderid
                   and shipid != in_shipid
                   and loadno = io_loadno) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + soh.qtyorder,
             weightorder = nvl(weightorder,0) + soh.weightorder,
             weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(soh.weight_entered_lbs,0),
             weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(soh.weight_entered_kgs,0),
             cubeorder = nvl(cubeorder,0) + soh.cubeorder,
             amtorder = nvl(amtorder,0) + soh.amtorder,
             qtyship = nvl(qtyship,0) + soh.qtyship,
             weightship = nvl(weightship,0) + soh.weightship,
             weightship_kgs = nvl(weightship_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(soh.custid,soh.weightship),0),
             cubeship = nvl(cubeship,0) + soh.cubeship,
             amtship = nvl(amtship,0) + soh.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
      if sql%rowcount = 0 then
        out_msg := 'Load/Stop/Shipment not found: ' ||
          io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
      end if;
    end loop;
  elsif cordid = 0 then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;
  else
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and orderstatus != 'X';
    for ch in (select qtyorder, weightorder, cubeorder, amtorder,
                      qtyship, weightship, cubeship, amtship,
                      weight_entered_lbs, weight_entered_kgs, custid
                 from orderhdr
                 where wave = oh.wave
                   and orderstatus != 'X'
                   and (orderid != in_orderid or shipid != in_shipid)) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + ch.qtyorder,
             weightorder = nvl(weightorder,0) + ch.weightorder,
             weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(ch.weight_entered_lbs,0),
             weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(ch.weight_entered_kgs,0),
             cubeorder = nvl(cubeorder,0) + ch.cubeorder,
             amtorder = nvl(amtorder,0) + ch.amtorder,
             qtyship = nvl(qtyship,0) + ch.qtyship,
             weightship = nvl(weightship,0) + ch.weightship,
             weightship_kgs = nvl(weightship_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(ch.custid,ch.weightship),0),
             cubeship = nvl(cubeship,0) + ch.cubeship,
             amtship = nvl(amtship,0) + ch.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
    end loop;
  end if;
else
  get_next_loadno(io_loadno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
  io_stopno := 1;
  io_shipno := 1;
  if oh.ordertype not in ('T','U') then
    ld.loadtype := 'OUTC';
  else
    ld.loadtype := 'OUTT';
  end if;
  ld.shipterms := oh.shipterms;
  ld.shiptype := oh.shiptype;
  insert into loads
   (loadno,entrydate,loadstatus,
    trailer,seal,facility,
    doorloc,stageloc,carrier,
    statususer,statusupdate,
    lastuser,lastupdate,
    billoflading, loadtype,
    shipterms, shiptype)
  values
   (io_loadno,sysdate,'2',
    in_trailer,in_seal,oh.fromfacility,
    in_doorloc,in_stageloc,in_carrier,
    in_userid,sysdate,
    in_userid,sysdate,
    in_billoflading, ld.loadtype,
    ld.shipterms, ld.shiptype);
  insert into loadstop
   (loadno,stopno,entrydate,
    loadstopstatus, FREIGHT_ACCESSSORIALS,
    statususer,statusupdate,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,sysdate,
    '2', freightaccessorials,
    in_userid,sysdate,
    in_userid,sysdate);
  insert into loadstopship
   (loadno,stopno,shipno,
    entrydate,
    qtyorder,weightorder,
    cubeorder,amtorder,
    qtyship,weightship,
    cubeship,amtship,
    lastuser,lastupdate,
    weight_entered_lbs,weight_entered_kgs,
    weightship_kgs)
  values
   (io_loadno,io_stopno,io_shipno,
    sysdate,
    oh.qtyorder,oh.weightorder,
    oh.cubeorder,oh.amtorder,
    oh.qtyship,oh.weightship,
    oh.cubeship,oh.amtship,
    in_userid,sysdate,
    oh.weight_entered_lbs,oh.weight_entered_kgs,
    nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0));
  if rtrim(in_carrier) is null then
    ld.carrier := oh.carrier;
  else
    ld.carrier := in_carrier;
  end if;
  if splitfac_order then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and orderstatus != 'X'
       and nvl(loadno,0) = 0;
    for soh in (select qtyorder, weightorder, cubeorder, amtorder,
                       qtyship, weightship, cubeship, amtship,
                       weight_entered_lbs, weight_entered_kgs,
                       custid
                  from orderhdr
                 where orderid = in_orderid
                   and shipid != in_shipid
                   and loadno = io_loadno) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + soh.qtyorder,
             weightorder = nvl(weightorder,0) + soh.weightorder,
             weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(soh.weight_entered_lbs,0),
             weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(soh.weight_entered_kgs,0),
             cubeorder = nvl(cubeorder,0) + soh.cubeorder,
             amtorder = nvl(amtorder,0) + soh.amtorder,
             qtyship = nvl(qtyship,0) + soh.qtyship,
             weightship = nvl(weightship,0) + soh.weightship,
             weightship_kgs = nvl(weightship_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(soh.custid,soh.weightship),0),
             cubeship = nvl(cubeship,0) + soh.cubeship,
             amtship = nvl(amtship,0) + soh.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
      if sql%rowcount = 0 then
        out_msg := 'Load/Stop/Shipment not found: ' ||
          io_loadno || '/' || io_stopno || '/' || io_shipno;
        return;
      end if;
    end loop;
  elsif cordid = 0 then
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;
  else
    update orderhdr
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           carrier = ld.carrier,
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and orderstatus != 'X';
    for ch in (select qtyorder, weightorder, cubeorder, amtorder,
                      qtyship, weightship, cubeship, amtship,
                      weight_entered_lbs, weight_entered_kgs,
                      custid
                 from orderhdr
                 where wave = oh.wave
                   and orderstatus != 'X'
                   and (orderid != in_orderid or shipid != in_shipid)) loop
      update loadstopship
         set qtyorder = nvl(qtyorder,0) + ch.qtyorder,
             weightorder = nvl(weightorder,0) + ch.weightorder,
             weight_entered_lbs = nvl(weight_entered_lbs,0) + nvl(ch.weight_entered_lbs,0),
             weight_entered_kgs = nvl(weight_entered_kgs,0) + nvl(ch.weight_entered_kgs,0),
             cubeorder = nvl(cubeorder,0) + ch.cubeorder,
             amtorder = nvl(amtorder,0) + ch.amtorder,
             qtyship = nvl(qtyship,0) + ch.qtyship,
             weightship = nvl(weightship,0) + ch.weightship,
             weightship_kgs = nvl(weightship_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(ch.custid,ch.weightship),0),
             cubeship = nvl(cubeship,0) + ch.cubeship,
             amtship = nvl(amtship,0) + ch.amtship,
             lastuser = in_userid,
             lastupdate = sysdate
       where loadno = io_loadno
         and stopno = io_stopno
         and shipno = io_shipno;
    end loop;
  end if;

end if;

if splitfac_order then
  update shippingplate
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and nvl(loadno,0) = 0;
else
  update shippingplate a
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid
     and (item is null or exists (select 1
                                  from orderdtl
                                  where orderid = a.orderid and shipid = a.shipid
                                    and item = a.item
                                    and linestatus <> 'X'));
  if (cordid != 0) and (cordid != in_orderid) then
    update shippingplate
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = cordid
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update shippingplate a
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and nvl(loadno,0) != io_loadno
       and (item is null or exists (select 1
                                    from orderdtl
                                    where orderid = a.orderid and shipid = a.shipid
                                      and item = a.item
                                      and linestatus <> 'X'));
  end if;
  if (ccombinedwave != 0) and (ccombinedwave != in_orderid) then
    update shippingplate
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = ccombinedwave
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update shippingplate
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where original_wave_before_combine = oh.original_wave_before_combine)
       and nvl(loadno,0) != io_loadno;
  end if;
end if;

if splitfac_order then
  update batchtasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and nvl(loadno,0) = 0;
else
  update batchtasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
  if (cordid != 0) and (cordid != in_orderid) then
    update batchtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = cordid
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update batchtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and nvl(loadno,0) != io_loadno;
  end if;
  if (ccombinedwave != 0) and (ccombinedwave != in_orderid) then
    update batchtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = ccombinedwave
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update batchtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where original_wave_before_combine = oh.original_wave_before_combine)
       and nvl(loadno,0) != io_loadno;
  end if;
end if;

if splitfac_order then
  update subtasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and nvl(loadno,0) = 0;
else
  update subtasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
  if (cordid != 0) and (cordid != in_orderid) then
    update subtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = cordid
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update subtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and nvl(loadno,0) != io_loadno;
  end if;
  if (ccombinedwave != 0) and (ccombinedwave != in_orderid) then
    update subtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = ccombinedwave
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update subtasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where original_wave_before_combine = oh.original_wave_before_combine)
       and nvl(loadno,0) != io_loadno;
  end if;
end if;

if splitfac_order then
  update tasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and nvl(loadno,0) = 0;
else
  update tasks
     set loadno = io_loadno,
         stopno = io_stopno,
         shipno = io_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
  if (cordid != 0) and (cordid != in_orderid) then
    update tasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = cordid
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update tasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and nvl(loadno,0) != io_loadno;
  end if;
  if (ccombinedwave != 0) and (ccombinedwave != in_orderid) then
    update tasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = ccombinedwave
       and shipid = 0
       and nvl(loadno,0) != io_loadno;
    update tasks
       set loadno = io_loadno,
           stopno = io_stopno,
           shipno = io_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where (orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where original_wave_before_combine = oh.original_wave_before_combine)
       and nvl(loadno,0) != io_loadno;
  end if;
end if;

if oh.orderstatus > '3' then
  if oh.orderstatus > '4' then
    newloadstatus := '5';
  else
    newloadstatus := '3';
  end if;
  min_load_status(io_loadno,in_facility,newloadstatus,in_userid);
  min_loadstop_status(io_loadno,io_stopno,in_facility,newloadstatus,in_userid);
elsif oh.orderstatus in ('1','2','3') then
  newloadstatus := '5';
  update loadstop
     set loadstopstatus = newloadstatus,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and loadstopstatus > newloadstatus;

  update loads
     set loadstatus = newloadstatus,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and loadstatus > newloadstatus;
end if;


-- update appointments
-- if assigning a load with an apt, update the order's apt info
-- else if assigning a load to an order with an apt, update the load's apt info.

select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from loads where loadno = io_loadno;

if theApt > 0 then
   update orderhdr
      set appointmentid = theApt,
                 apptdate = theAptDate
      where orderid = in_orderid
         and shipid = in_shipid;
else
   select nvl(appointmentid,0),apptdate  into
       theApt, theAptDate
   from orderhdr
      where orderid = in_orderid
         and shipid = in_shipid;
      if theApt > 0 then
      update loads
         set appointmentid = theApt,
                   apptdate = theAptDate
      where loadno = io_loadno;

      update orderhdr
         set appointmentid = theApt,
                       apptdate = theAptDate,
             lastuser = in_userid,
                       lastupdate = sysdate
            where loadno = io_loadno;

      update docappointments
         set loadno = io_loadno,
         lastuser = in_userid,
               lastupdate = sysdate
      where appointmentid = theApt;
    end if;
end if;


if (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') in ('Y','L')) then
  if (nvl(ld.ldpassthruchar40,'(none)') = '(none)') and
     (nvl(ld.ldpassthruchar02,'(none)') != '(none)') then
    cucc := null;
    open curCustUCC128(oh.custid);
    fetch curCustUCC128 into cucc;
    close curCustUCC128;

    ld.ldpassthruchar40 := calccheckdigit(cucc.manufacturerucc||trim(to_char(io_loadno,'000000000')));

    update loads
       set ldpassthruchar40 = ld.ldpassthruchar40
     where loadno=io_loadno;
  end if;

  if (cordid = 0) and (ccombinedwave = 0) then
    cvbolhpt50 := null;
    open curVICSBOLByLoadHPT50(io_loadno, in_facility, oh.hdrpassthruchar50);
    fetch curVICSBOLByLoadHPT50 into cvbolhpt50;
    close curVICSBOLByLoadHPT50;

    if nvl(cvbolhpt50.hdrpassthruchar27,'(none)') = '(none)' then
      cucc := null;
      open curCustUCC128(oh.custid);
      fetch curCustUCC128 into cucc;
      close curCustUCC128;

      newbilloflading := calccheckdigit(cucc.manufacturerucc||trim(to_char(in_orderid,'0000000'))||trim(to_char(in_shipid,'00')));

      update orderhdr
         set hdrpassthruchar27 = newbilloflading,
             autogenerated_vicsbol = 'Y'
       where orderid = in_orderid
         and shipid = in_shipid;

    elsif nvl(oh.hdrpassthruchar27,'(none)') = '(none)' then
      update orderhdr
         set hdrpassthruchar27 = cvbolhpt50.hdrpassthruchar27,
             autogenerated_vicsbol = 'Y'
       where orderid = in_orderid
         and shipid = in_shipid;
    end if;
  elsif (cordid <> 0) then
    for coh in (select orderid,
                       shipid,
                       custid,
                       trim(hdrpassthruchar50) hdrpassthruchar50,
                       trim(hdrpassthruchar27) hdrpassthruchar27
                 from orderhdr
                 where wave = oh.wave
                   and nvl(trim(hdrpassthruchar27),'(none)') = '(none)'
                   and orderstatus != 'X') loop
      cvbolhpt50 := null;
      open curVICSBOLByLoadHPT50(io_loadno, in_facility, coh.hdrpassthruchar50);
      fetch curVICSBOLByLoadHPT50 into cvbolhpt50;
      close curVICSBOLByLoadHPT50;

      if nvl(cvbolhpt50.hdrpassthruchar27,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(coh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(cucc.manufacturerucc||trim(to_char(coh.orderid,'0000000'))||trim(to_char(coh.shipid,'00')));

        update orderhdr
           set hdrpassthruchar27 = newbilloflading,
               autogenerated_vicsbol = 'Y'
         where orderid = coh.orderid
           and shipid = coh.shipid;

      elsif nvl(coh.hdrpassthruchar27,'(none)') = '(none)' then
        update orderhdr
           set hdrpassthruchar27 = cvbolhpt50.hdrpassthruchar27,
               autogenerated_vicsbol = 'Y'
         where orderid = coh.orderid
           and shipid = coh.shipid;
      end if;
    end loop;
  else
    for coh in (select orderid,
                       shipid,
                       custid,
                       trim(hdrpassthruchar27) hdrpassthruchar27,
                       trim(hdrpassthruchar50) hdrpassthruchar50
                  from orderhdr
                 where recent_order_id like 'Y%'
                   and original_wave_before_combine = oh.original_wave_before_combine
                   and orderstatus != 'X'
                   and nvl(trim(hdrpassthruchar27),'(none)') = '(none)'
                   and nvl(original_wave_before_combine,0) <> 0) loop
      cvbolhpt50 := null;
      open curVICSBOLByLoadHPT50(io_loadno, in_facility, coh.hdrpassthruchar50);
      fetch curVICSBOLByLoadHPT50 into cvbolhpt50;
      close curVICSBOLByLoadHPT50;

     if nvl(cvbolhpt50.hdrpassthruchar27,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(coh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(cucc.manufacturerucc||trim(to_char(coh.orderid,'0000000'))||trim(to_char(coh.shipid,'00')));

        update orderhdr
           set hdrpassthruchar27 = newbilloflading,
               autogenerated_vicsbol = 'Y'
         where orderid = coh.orderid
           and shipid = coh.shipid;

      elsif nvl(coh.hdrpassthruchar27,'(none)') = '(none)' then
        update orderhdr
           set hdrpassthruchar27 = cvbolhpt50.hdrpassthruchar27,
               autogenerated_vicsbol = 'Y'
         where orderid = coh.orderid
           and shipid = coh.shipid;
      end if;
    end loop;
  end if;
elsif (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N')= 'P') then
  if nvl(ld.billoflading,'(none)') = '(none)' then
    cucc := null;
    open curCustUCC128(oh.custid);
    fetch curCustUCC128 into cucc;
    close curCustUCC128;

    ld.billoflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                      trim(to_char(io_loadno,'000000000')));

    update loads
       set billoflading = ld.billoflading
     where loadno=io_loadno;
  end if;

  if (cordid = 0) and (ccombinedwave = 0) then
    cvbolst := null;
    open curVICSBOLByLoadShipTo(io_loadno, in_facility, oh.shiptoaddr1addr2);
    fetch curVICSBOLByLoadShipTo into cvbolst;
    close curVICSBOLByLoadShipTo;

    if nvl(cvbolst.billoflading,'(none)') = '(none)' then
      cucc := null;
      open curCustUCC128(oh.custid);
      fetch curCustUCC128 into cucc;
      close curCustUCC128;

      newbilloflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                        trim(to_char(in_orderid,'0000000'))||
                                        trim(to_char(in_shipid,'00')));

      update orderhdr
         set billoflading = newbilloflading
       where orderid = in_orderid
         and shipid = in_shipid;


    elsif nvl(oh.billoflading,'(none)') = '(none)' then
      update orderhdr
         set billoflading = cvbolst.billoflading
       where orderid = in_orderid
         and shipid = in_shipid;
    end if;
  elsif (cordid <> 0) then
    for coh in (select orderid,
                       shipid,
                       custid,
                       trim(billoflading) billoflading,
                       decode(shiptoname,null,shipto,shiptoname||shiptoaddr1||shiptoaddr2||shiptocity||shiptostate||shiptopostalcode) shiptoaddr1addr2
                 from orderhdr
                 where wave = oh.wave
                   and orderstatus != 'X') loop
      cvbolst := null;
      open curVICSBOLByLoadShipTo(io_loadno, in_facility, coh.shiptoaddr1addr2);
      fetch curVICSBOLByLoadShipTo into cvbolst;
      close curVICSBOLByLoadShipTo;

      if nvl(cvbolst.billoflading,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(coh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                          trim(to_char(coh.orderid,'0000000'))||
                                          trim(to_char(coh.shipid,'00')));

        update orderhdr
           set billoflading = newbilloflading
         where orderid = coh.orderid
           and shipid = coh.shipid;


      elsif nvl(coh.billoflading,'(none)') = '(none)' then
        update orderhdr
           set billoflading = cvbolst.billoflading
         where orderid = coh.orderid
           and shipid = coh.shipid;
      end if;
    end loop;
  else
    for coh in (select orderid,
                       shipid,
                       custid,
                       trim(billoflading) billoflading,
                       decode(shiptoname,null,shipto,shiptoname||shiptoaddr1||shiptoaddr2||shiptocity||shiptostate||shiptopostalcode) shiptoaddr1addr2
                  from orderhdr
                 where original_wave_before_combine = oh.original_wave_before_combine
                   and orderstatus != 'X'
                   and nvl(original_wave_before_combine,0) <> 0
                   and recent_order_id like 'Y%') loop
      cvbolst := null;
      open curVICSBOLByLoadShipTo(io_loadno, in_facility, coh.shiptoaddr1addr2);
      fetch curVICSBOLByLoadShipTo into cvbolst;
      close curVICSBOLByLoadShipTo;

      if nvl(cvbolst.billoflading,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(coh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                          trim(to_char(coh.orderid,'0000000'))||
                                          trim(to_char(coh.shipid,'00')));

        update orderhdr
           set billoflading = newbilloflading
         where orderid = coh.orderid
           and shipid = coh.shipid;


      elsif nvl(coh.billoflading,'(none)') = '(none)' then
        update orderhdr
           set billoflading = cvbolst.billoflading
         where orderid = coh.orderid
           and shipid = coh.shipid;
      end if;
    end loop;
  end if;
end if;

l_cnt := 0;
if splitfac_order then
  for soh in (select shipid from orderhdr
               where orderid = in_orderid
                 and loadno = io_loadno) loop
    zoh.add_orderhistory(in_orderid, soh.shipid,
         'Order To Load',
         'Order Assigned to Load '||io_loadno||'/'||io_stopno||'/'||io_shipno,
         in_userid, out_msg);
   zlh.add_loadhistory(io_loadno,
        'Order To Load',
        'Order '|| in_orderid ||'-'||soh.shipid || ' Assigned to Stop/Ship ' ||io_stopno||'/'||io_shipno,
        in_userid, out_msg);

    l_cnt := l_cnt + 1;
  end loop;
else
  zoh.add_orderhistory(in_orderid, in_shipid,
       'Order To Load',
       'Order Assigned to Load '||io_loadno||'/'||io_stopno||'/'||io_shipno,
       in_userid, out_msg);
  zlh.add_loadhistory(io_loadno,
       'Order To Load',
       'Order '|| in_orderid ||'-'||in_shipid || ' Assigned to Stop/Ship ' ||io_stopno||'/'||io_shipno,
       in_userid, out_msg);
end if;

if l_cnt > 1 then
   out_msg := 'OKAYMULTI';
elsif cordid = 0 then
  out_msg := 'OKAY';
else
  out_msg := 'OKAYCONS';
end if;

exception when others then
  out_msg := 'ldaoo ' || substr(sqlerrm,1,80);
end assign_outbound_order_to_load;

PROCEDURE assign_freight_order_to_load
(in_orderid IN number
,in_shipid IN number
,in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

theApt number;
theAptDate date;

cursor Corderhdr is
  select nvl(OH.orderstatus,'?') as orderstatus,
         nvl(OH.loadno,0) as loadno,
         nvl(OH.stopno,0) as stopno,
         nvl(OH.ordertype,'?') as ordertype,
         nvl(OH.fromfacility,' ') as fromfacility,
         nvl(OH.qtyorder,0) as qtyorder,
         nvl(OH.weightorder,0) as weightorder,
         nvl(OH.cubeorder,0) as cubeorder,
         nvl(OH.amtorder,0) as amtorder,
         nvl(OH.qtyship,0) as qtyship,
         nvl(OH.weightship,0) as weightship,
         nvl(OH.cubeship,0) as cubeship,
         nvl(OH.amtship,0) as amtship,
         OH.carrier,
         nvl(CU.paperbased, 'N') as paperbased,
         OH.wave,
         nvl(OH.weight_entered_lbs,0) as weight_entered_lbs,
         nvl(OH.weight_entered_kgs,0) as weight_entered_kgs,
         OH.custid as custid,
         trim(OH.hdrpassthruchar27) hdrpassthruchar27,
         trim(oh.hdrpassthruchar50) hdrpassthruchar50,
         nvl(OH.shipto, '') as shipto
    from orderhdr OH, customer CU
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and CU.custid (+) = OH.custid;
oh Corderhdr%rowtype;

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         billoflading,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         trim(ldpassthruchar02) ldpassthruchar02,
         trim(ldpassthruchar40) ldpassthruchar40
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

cursor curCarrier(in_carrier in varchar2) is
  select nvl(multiship,'N') as multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

newloadstatus varchar2(2);
cordid waves.wave%type;
splitfac_order boolean := false;
l_cnt pls_integer;
stop_flag boolean;
newbilloflading varchar2(40);
custUCC128 varchar2(7);
freightaccessorials varchar2(4000) := '';

begin

out_msg := '';
stop_flag := FALSE;

if io_stopno < 0 then
    stop_flag := TRUE;
    io_stopno := -io_stopno;
end if;

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;
cordid := zcord.cons_orderid(in_orderid, in_shipid);

if (oh.ordertype <> 'F') then
  out_msg := 'Not a freight order';
  return;
end if;

if oh.orderstatus > '1' then
  out_msg := 'Invalid order status: ' || oh.orderstatus;
  return;
end if;

if oh.loadno != 0 then
  out_msg := 'Order is already assigned to load ' || oh.loadno;
  return;
end if;

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if oh.carrier is not null then
  ca := null;
  open curCarrier(oh.carrier);
  fetch curCarrier into ca;
  close curCarrier;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

get_next_loadno(io_loadno,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  return;
end if;

begin
  select ca.freight_accessorials
    into freightaccessorials
    from ConsigneeAccessorials ca
   where ca.Consignee = oh.shipto
     and Tariff =
        (select Tariff from custfacility where custid = oh.custid and facility = oh.fromfacility);
exception when no_data_found then
  null;
when others then
  out_msg := 'ldafo ' || substr(sqlerrm,1,80);
  return;
end;

io_stopno := 1;
io_shipno := 1;
ld.loadtype := 'OUTC';
insert into loads
 (loadno,entrydate,loadstatus,
  trailer,seal,facility,
  doorloc,stageloc,carrier,
  statususer,statusupdate,
  lastuser,lastupdate,
  billoflading, loadtype)
values
 (io_loadno,sysdate,'8',
  in_trailer,in_seal,oh.fromfacility,
  in_doorloc,in_stageloc,in_carrier,
  in_userid,sysdate,
  in_userid,sysdate,
  in_billoflading, 'OUTC');

insert into loadstop
 (loadno,stopno,entrydate,
  loadstopstatus,FREIGHT_ACCESSSORIALS,
  statususer,statusupdate,
  lastuser,lastupdate)
values
 (io_loadno,io_stopno,sysdate,
  '8', freightaccessorials,
  in_userid,sysdate,
  in_userid,sysdate);
insert into loadstopship
 (loadno,stopno,shipno,
  entrydate,
  qtyorder,weightorder,
  cubeorder,amtorder,
  qtyship,weightship,
  cubeship,amtship,
  lastuser,lastupdate,
  weight_entered_lbs,weight_entered_kgs,
  weightship_kgs)
values
 (io_loadno,io_stopno,io_shipno,
  sysdate,
  oh.qtyorder,oh.weightorder,
  oh.cubeorder,oh.amtorder,
  oh.qtyship,oh.weightship,
  oh.cubeship,oh.amtship,
  in_userid,sysdate,
  oh.weight_entered_lbs,oh.weight_entered_kgs,
  nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0));
if rtrim(in_carrier) is null then
  ld.carrier := oh.carrier;
else
  ld.carrier := in_carrier;
end if;

update orderhdr
   set loadno = io_loadno,
       stopno = io_stopno,
       shipno = io_shipno,
       orderstatus = '8',
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

update orderdtl
   set qtyship = qtyorder,
       cubeship = cubeorder,
       weightship = weightorder,
       amtship = amtorder,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid
   and linestatus != 'X';

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldafo ' || substr(sqlerrm,1,80);
end assign_freight_order_to_load;

PROCEDURE arrive_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_receiptdate IN date
,in_useplateloc IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

cursor c_itm(p_custid varchar2, p_item varchar2) is
   select status
      from custitem
      where custid = p_custid
        and item = p_item;
itm c_itm%rowtype;

ohcount integer;
strMsg varchar2(255);
intErrorno integer;
l_ownertransfer boolean := false;
l_rcvddate loads.rcvddate%type;
l_loadstatus loads.loadstatus%type := 'A';
l_orderstatus orderhdr.orderstatus%type := 'A';
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_use_yard char(1);

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if substr(ld.loadtype,1,1) != 'I' then
  out_msg := 'Invalid load type: ' || ld.loadtype;
  return;
end if;

if ld.loadtype != 'INT' then
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus != '2' then
    out_msg := 'Invalid load status for arrival: ' || ld.loadstatus;
    return;
  end if;
else
  select count(1)
    into ohcount
    from orderhdr
   where loadno = in_loadno
     and orderstatus = '9'
     and tofacility = in_facility;
  if ohcount = 0 then
    out_msg := 'No shipped transfers are assigned to this facility: '
      || in_facility;
    return;
  end if;

  select count(1)
    into ohcount
    from orderhdr
   where loadno = in_loadno
     and ordertype = 'U';
  if ohcount != 0 then
    l_ownertransfer := true;
    l_orderstatus := '9';
    l_loadstatus := 'E';
  end if;
end if;

select count(1)
  into ohcount
  from orderhdr
 where loadno = in_loadno
   and orderstatus != 'X';

if ohcount = 0 then
  out_msg := 'No open orders are assigned to this load';
  return;
end if;

if ld.carrier is null then
  out_msg := 'A Carrier entry is required';
  return;
end if;

if ld.doorloc is null then
  out_msg := 'A Door Location entry is required';
  return;
end if;

select nvl(use_yard,'N') into l_use_yard
   from facility
  where facility = in_facility;

if l_use_yard = 'Y' and
   ld.trailer is null then
   out_msg := 'A Trailer entry is required';
   return;
end if;


zva.validate_location(in_facility,ld.doorloc,'DOR','FIE',
  'Door Location', out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  return;
end if;

if ld.stageloc is not null then
  zva.validate_location(in_facility,ld.stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

for ls in Cloadstop
loop
/*
  if ls.stageloc is null and
     ld.stageloc is null  then
    out_msg := 'A Stage location entry is required';
    return;
  end if;
*/
  if ls.stageloc is not null then
    zva.validate_location(in_facility,ls.stageloc,'STG','FIE',
      'Stop ' || ls.stopno || ' Stage Location', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      return;
    end if;
  end if;
end loop;

open Cdoor(in_facility,ld.doorloc);
fetch Cdoor into dr;
if Cdoor%notfound then
  close Cdoor;
  out_msg := 'Door not found: ' || ld.doorloc;
  return;
end if;
close Cdoor;

if (dr.loadno != 0) and (dr.loadno != in_loadno) then
  out_msg := ld.doorloc || ' is being used by Load ' || dr.loadno;
  return;
end if;

if l_ownertransfer then
   l_rcvddate := nvl(in_receiptdate, sysdate);
else
   l_rcvddate := sysdate;
end if;

update loads
   set loadstatus = l_loadstatus,
       rcvddate = l_rcvddate,
       facility = in_facility,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and (loadstatus < 'A'
    or  rcvddate is null);

if ld.loadtype = 'INT' then
  update loadstop
     set loadstopstatus = 'A',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and loadstopstatus < 'A'
     and exists (select * from orderhdr
                  where loadstop.loadno = orderhdr.loadno
                    and loadstop.stopno = orderhdr.stopno
                    and orderhdr.orderstatus = '9'
                    and orderhdr.tofacility = in_facility);
  update orderhdr
     set orderstatus = l_orderstatus,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderstatus = '9'
     and tofacility = in_facility;
else
  update loadstop
     set loadstopstatus = 'A',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and loadstopstatus < 'A';
  update orderhdr
     set orderstatus = 'A',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderstatus < 'A';
end if;

if (dr.loadno = 0) then
  update door
     set loadno = in_loadno,
         lastuser = in_userid,
         lastupdate = sysdate
   where facility = in_facility
     and doorloc = ld.doorloc;
end if;

for oh in curOrderHdr
loop
  zid.unhold_outbound_xdock_orders(oh.orderid,oh.shipid,in_userid,intErrorno,
    out_msg);
  if intErrorno != 0 then
    zms.log_msg('LOADARRIVE', oh.fromfacility, '',
         'Unhold XDock: ' || out_msg,
         'E', in_userid, strMsg);
  end if;

  if oh.ordertype = 'U' then
    zcl.clone_ownerxfer_order(oh.orderid, oh.shipid, null, in_userid, l_orderid,
         l_shipid, out_msg);
    if out_msg != 'OKAY' then
      return;
    end if;
    for sp in (select fromlpid, item, pickedfromloc from shippingplate
                  where orderid = oh.orderid
                    and shipid = oh.shipid) loop
      itm := null;
      open c_itm(oh.xfercustid, sp.item);
      fetch c_itm into itm;
      close c_itm;
      if itm.status is null then
         out_msg := 'Customer '||oh.xfercustid||' does not have item '||sp.item||' defined.';
         return;
      end if;

      update plate
        set custid = oh.xfercustid,
            location = decode(in_useplateloc,'Y',sp.pickedfromloc,ld.stageloc),
            status = 'A',
            po = nvl(oh.po, oh.reference),
            loadno = oh.loadno,
            stopno = oh.stopno,
            shipno = oh.shipno,
            orderid = l_orderid,
            shipid = l_shipid,
            lasttask = 'OT',
            lastoperator = in_userid,
            lastuser = in_userid,
            lastupdate = sysdate,
            disposition = null
        where lpid = sp.fromlpid;

      zrf.tally_lp_receipt(sp.fromlpid, in_userid, out_msg);
      if out_msg is not null then
        return;
      end if;
    end loop;
    oh.orderid := l_orderid;
    oh.shipid := l_shipid;
  end if;

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Arrived',
     'Order Arrived at '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);

  zlh.add_loadhistory(oh.loadno,
     'Load Arrived',
     'Load ' || in_loadno || ' representing PO ' || oh.po ||
            ', Trailer ' || ld.trailer || ' has been arrived at Facility ' || in_facility,
     in_userid, out_msg);

  zms.log_msg('LOADARRIVE', in_facility, oh.custid,
            'Load ' || in_loadno || ' representing PO ' || oh.po ||
            ', Trailer ' || ld.trailer || ' has been arrived at Facility ' || in_facility,
            'I', in_userid, strMsg);

end loop;

update trailer
   set disposition = 'DC',
       activity_type = 'ADC',
       facility = ld.facility,
       location = ld.doorloc,
       contents_status = 'A',
       lastuser = in_userid,
       lastupdate = sysdate
 where carrier = ld.carrier
   and trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldail ' || substr(sqlerrm,1,80);
end arrive_inbound_load;

PROCEDURE arrive_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where loadno = in_loadno
     and fromfacility = in_facility
     and orderstatus != 'X';

ohcount integer;
reopened boolean := false;
l_ohstatus orderhdr.orderstatus%type;
l_use_yard char(1);
begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if (ld.facility != in_facility) and (ld.loadstatus = '9') then
  select count(1) into ohcount
    from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and orderstatus < '8';
  if ohcount > 0 then
    reopened := true;

    select min(orderstatus) into l_ohstatus
      from orderhdr
     where loadno = in_loadno
       and fromfacility = in_facility;

    update loads
      set facility = in_facility,
          loadstatus = l_ohstatus
      where loadno = in_loadno;
  end if;
end if;

if not reopened then
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;

  if ld.loadstatus > '8' then
    out_msg := 'Invalid load status for arrival: ' || ld.loadstatus;
    return;
  end if;

  select count(1)
    into ohcount
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

  if ohcount = 0 then
    out_msg := 'No open orders are assigned to this load';
    return;
  end if;
end if;

if ld.carrier is null then
  out_msg := 'A Carrier entry is required';
  return;
end if;

if ld.doorloc is null then
  out_msg := 'A Door Location entry is required';
  return;
end if;

zva.validate_location(in_facility,ld.doorloc,'DOR','FIE',
  'Door Location', out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  return;
end if;

if ld.stageloc is not null then
  zva.validate_location(in_facility,ld.stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

select nvl(use_yard,'N') into l_use_yard
   from facility
  where facility = in_facility;

if l_use_yard = 'Y' and
   ld.trailer is null then
   out_msg := 'A Trailer entry is required';
   return;
end if;

for ls in Cloadstop
loop
/*
  if ls.stageloc is null and
     ld.stageloc is null  then
    out_msg := 'A Stage location entry is required';
    return;
  end if;
*/
  if ls.stageloc is not null then
    zva.validate_location(in_facility,ls.stageloc,'STG','FIE',
      'Stop ' || ls.stopno || ' Stage Location', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      return;
    end if;
  end if;

  if reopened then
    select min(orderstatus) into l_ohstatus
      from orderhdr
     where loadno = in_loadno
       and stopno = ls.stopno
       and fromfacility = in_facility;

    update loadstop
      set facility = in_facility,
          loadstopstatus = l_ohstatus
      where loadno = in_loadno;
  end if;
end loop;

open Cdoor(in_facility,ld.doorloc);
fetch Cdoor into dr;
if Cdoor%notfound then
  close Cdoor;
  out_msg := 'Door not found: ' || ld.doorloc;
  return;
end if;
close Cdoor;

if (dr.loadno != 0) and (dr.loadno != in_loadno) then
  out_msg := ld.doorloc || ' is being used by Load ' || dr.loadno;
  return;
end if;

if (dr.loadno = 0) then
  update door
     set loadno = in_loadno,
         lastuser = in_userid,
         lastupdate = sysdate
   where facility = in_facility
     and doorloc = ld.doorloc;
end if;

for oh in curOrderHdr
loop
  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Arrived',
     'Order Arrived at '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);
end loop;
zlh.add_loadhistory(in_loadno,
   'Load Arrived',
   'Load has been arrived at Facility ' || in_facility ||
          '. Trailer ' || ld.trailer ,
   in_userid, out_msg);

update trailer
   set disposition = 'DC',
       activity_type = 'ADC',
       facility = ld.facility,
       location = ld.doorloc,
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldaol ' || substr(sqlerrm,1,80);
end arrive_outbound_load;

PROCEDURE close_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
,in_yard IN varchar2 default null
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         rcvddate,
         trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor curUnknownPlates is
  select count(1) as count
    from plate
   where loadno = in_loadno
     and item = zunk.UNK_RCPT_ITEM;
up curUnknownPlates%rowtype;

cursor curOrderNeedsTemp is
   select oh.orderid, oh.shipid
     from orderhdr oh, customer cu
    where oh.loadno = in_loadno
      and oh.ordertype = 'U'
      and oh.orderstatus = 'A'
      and oh.custid = cu.custid
      and nvl(cu.tracktrailertemps,'N') = 'Y'
      and (oh.trailernosetemp is null
         or  oh.trailermiddletemp is null
         or  oh.trailertailtemp is null);
ohnt curOrderNeedsTemp%rowtype;

cursor curOrderNeedsConsumable is
   select oh.orderid, oh.shipid
     from orderhdr oh, customer cu
    where oh.loadno = in_loadno
      and oh.ordertype = 'R'
      and oh.custid = cu.custid
      and oh.has_consumables = 'Y'
      and not exists
          (select 1
             from consumehistory
            where custid = oh.custid
              and facility = oh.tofacility
              and orderid = oh.orderid
              and shipid = oh.shipid);
ohnc curOrderNeedsConsumable%rowtype;
cursor curDoor is
  select count(1) as count
    from door
   where loadno = in_loadno;
dr curDoor%rowtype;

cursor curAsnOrder(in_orderid number, in_shipid number) is
  select trackingno
    from asncartondtl
   where orderid = in_orderid
     and shipid = in_shipid;
asnoh curAsnOrder%rowtype;

cursor curOrders is
  select orderid,
         shipid,
         custid,
         ordertype
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';


cursor curOrderDtl(in_orderid number, in_shipid number) is
  select item,lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

cursor curCust(in_custid varchar2) is
 select QAHoldReceipt,
        nvl(recv_line_check_yn,'N') as recv_line_check_yn,
        nvl(carryover_unrcvd_qty_yn,'N') as carryover_unrcvd_qty_yn
   from customer
  where custid = in_custid;

CUST curCust%rowtype;
cnt integer;


cursor curOrderLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid;

cursor curCustAuxOrdClosePrc is
  select distinct c.custid, c.order_close_procedure
    from orderhdr o, customer_aux c
   where o.custid = c.custid
     and o.loadno = in_loadno
	 and orderstatus != 'X';
	 
cntAsnVariance integer;
cntRows integer;
dteStart date;
dteEnd date;
strMsg varchar2(255);
ohcount integer;
itlpcount integer;
intErrorNo integer;
l_msg varchar2(255);
l_err varchar2(1);
l_cube orderdtl.cubercvd%type;
l_amt orderdtl.amtrcvd%type;
in_new_orderid integer;
in_new_shipid  integer;
CD cdata;   -- Custom code data structure

begin

out_msg := '';

dteStart := sysdate;
zms.log_msg('LoadClose', in_facility, '',
  'Begin Load Close Inbound  ' || in_loadno,
  'I', in_userid, strMsg);

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

up.count := 0;
open curUnknownPlates;
fetch curUnknownPlates into up;
close curUnknownPlates;
if up.count != 0 then
  out_msg := 'Unknown items require processing';
  if ld.loadstatus = 'E' then
    dr.count := 0;
    open curDoor;
    fetch curDoor into dr;
    close curDoor;
    if dr.count = 1 then
      out_msg := 'FREEDOOR';
    end if;
  end if;
  return;
end if;
if nvl(in_yard,'N') = 'Y' then
   if ld.trailer is null then
     out_msg := 'A Trailer entry is required';
     return;
   end if;
end if;


open curOrderNeedsTemp;
fetch curOrderNeedsTemp into ohnt;
if ohnt.orderid is not null then
  close curOrderNeedsTemp;
  out_msg := 'Trailer temperature required for order ' || ohnt.orderid || '-' || ohnt.shipid;
  return;
end if;
close curOrderNeedsTemp;
ohnc := null;
open curOrderNeedsConsumable;
fetch curOrderNeedsConsumable into ohnc;
close curOrderNeedsConsumable;
if ohnc.orderid is not null then
  out_msg := 'Consumables entry required for order ' || ohnc.orderid || '-' || ohnc.shipid;
  return;
end if;

if ld.loadtype = 'INT' then
   select count(1)
      into itlpcount
      from plate P, shippingplate S
      where S.loadno = in_loadno
        and P.lpid = S.fromlpid
        and P.status = 'I';
   if itlpcount != 0 then
      out_msg := 'Load has in-transit plates';
      return;
   end if;
end if;

if ld.facility != in_facility then
  if ld.loadtype = 'INT' then
    select count(1)
      into ohcount
      from orderhdr
     where loadno = in_loadno
       and orderstatus = 'A'
       and tofacility = in_facility;
    if ohcount = 0 then
      out_msg := 'No arrived transfers are assigned to this facility: '
        || in_facility;
      return;
    else
      goto continue_close;
    end if;
  end if;
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

<<continue_close>>

if ld.loadstatus != 'E' then
  out_msg := 'Invalid load status for close: ' || ld.loadstatus;
  return;
end if;


for crec in curOrders loop
    CUST := null;
    OPEN curCust(crec.custid);
    FETCH curCust into CUST;
    CLOSE curCust;

    if CUST.QAHoldReceipt = 'Y' then
       cnt := 0;
       select count(1)
         into cnt
         from qcresult
        where orderid = crec.orderid
          and shipid = crec.shipid
          and status = 'OP';
      if cnt > 0 then
         out_msg := 'Order '
                 ||crec.orderid||'-'||crec.shipid
                 || ' has QA inspection open.';
         return;
      end if;
    end if;

    if cust.recv_line_check_yn = 'Y' then
      for od in curOrderDtl(crec.orderid,crec.shipid)
      loop
        zrec.check_line_qty(crec.custid,crec.orderid,crec.shipid,
         od.item,od.lotnumber,0,interrorno,out_msg);
        if intErrorNo != 0 then
          out_msg := 'Order ' || crec.orderid || '-' ||
            crec.shipid || ' Item ' || od.item || ' Lot ' ||
            nvl(od.lotnumber,'(none)') || ': Line number quantity exceeded';
          return;
        end if;
      end loop;
    end if;

end loop;

-- Check for receipt close custom processing for this load
CD := zcus.init_cdata;
CD.loadno := in_loadno;
zcus.execute('RECO',CD);
if nvl(CD.out_no,0 ) != 0 then
    out_msg := CD.out_char;
    return;
end if;

update orderhdr
   set orderstatus = 'R',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and orderstatus < 'R'
   and ordertype != 'U';

update orderhdr
   set orderstatus = 'R',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and orderstatus = 'A'
   and ordertype = 'U';

update loadstop
   set loadstopstatus = 'R',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstopstatus < 'R';

update loads
   set loadstatus = 'R',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstatus < 'R';

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

for lp in (select * from plate
            where loadno = in_loadno
              and zlbl.is_lp_unprocessed_autogen(lpid) = 'Y'
              and type = 'PA') loop
   zrf.decrease_lp(lp.lpid, lp.custid, lp.item, lp.quantity, lp.lotnumber,
         lp.unitofmeasure, in_userid, null, lp.invstatus, lp.inventoryclass, l_err, l_msg);
   if l_msg is not null then
      out_msg := l_msg;
      return;
   end if;

   l_cube := zci.item_cube(lp.custid, lp.item, lp.unitofmeasure) * lp.quantity;
   l_amt := zci.item_amt(lp.custid, lp.orderid, lp.shipid, lp.item, lp.lotnumber) * lp.quantity;  --prn 25133

   delete orderdtlrcpt where lpid = lp.lpid;

   update loadstopship
      set qtyrcvd = nvl(qtyrcvd, 0) - lp.quantity,
          weightrcvd = nvl(weightrcvd, 0) - lp.weight,
          weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                         - nvl(zwt.from_lbs_to_kgs(lp.custid,lp.weight),0),
          cubercvd = nvl(cubercvd, 0) - l_cube,
          amtrcvd = nvl(amtrcvd, 0) - l_amt,
          lastuser = in_userid,
          lastupdate = sysdate
      where loadno = lp.loadno
        and stopno = lp.stopno
        and shipno = lp.shipno;

   update orderdtl
      set qtyrcvd = nvl(qtyrcvd,0) - lp.quantity,
          qtyrcvdgood = nvl(qtyrcvdgood,0) - lp.quantity,
          weightrcvd = nvl(weightrcvd,0) - lp.weight,
          weightrcvdgood = nvl(weightrcvdgood,0) - lp.weight,
          cubercvd = nvl(cubercvd,0) - l_cube,
          cubercvdgood = nvl(cubercvdgood,0) - l_cube,
          amtrcvd = nvl(amtrcvd,0) - l_amt,
          amtrcvdgood = nvl(amtrcvdgood,0) - l_amt,
          lastuser = in_userid,
          lastupdate = sysdate
      where orderid = lp.orderid
        and shipid = lp.shipid
        and item = lp.item
        and nvl(lotnumber, '(none)') = nvl(lp.lotnumber, '(none)');

   zoh.add_orderhistory(lp.orderid, lp.shipid,
      'LP deleted',
      'Deleted autogen lp '||lp.lpid,
      in_userid, l_msg);

   delete shippingplate
      where fromlpid = lp.lpid
        and status = 'P'
        and type ='F'
      returning orderid, shipid into lp.orderid, lp.shipid;

   update orderdtl
      set qtypick = nvl(qtypick,0) - lp.quantity,
          weightpick = nvl(weightpick,0) - lp.weight,
          cubepick = nvl(cubepick,0) - l_cube,
          amtpick = nvl(amtpick,0) - l_amt,
          lastuser = in_userid,
          lastupdate = sysdate
      where orderid = lp.orderid
        and shipid = lp.shipid
        and item = lp.item
        and nvl(lotnumber, '(none)') = nvl(lp.lotnumber, '(none)');

end loop;

for oh in curOrders
loop
  asnoh := null;
  cntAsnVariance := 0;
  open curAsnOrder(oh.orderid,oh.shipid);
  fetch curAsnOrder into asnoh;
  close curAsnOrder;
  if asnoh.trackingno is not null then
    for ol in curOrderLines(oh.orderid,oh.shipid)
    loop
      cntRows := 0;
      select count(1)
        into cntRows
        from asnreceiptview
       where orderid = oh.orderid
         and shipid = oh.shipid
         and item = ol.item
         and nvl(lotnumber,'x') = nvl(ol.lotnumber,'x')
         and asnqtyorder = 0;
      if cntRows <> 0 then
        update orderdtl
           set asnvariance = 'Y'
         where orderid = oh.orderid
           and shipid = oh.shipid
           and item = ol.item
           and nvl(lotnumber,'x') = nvl(ol.lotnumber,'x');
        cntAsnVariance := cntAsnVariance + 1;
      end if;
    end loop;
  end if;
  if cntAsnVariance <> 0 then
    update orderhdr
       set asnvariance = 'Y'
     where orderid = oh.orderid
       and shipid = oh.shipid;
  end if;

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Closed',
     'Order Closed',
     in_userid, out_msg);

  in_new_orderid := null;
  in_new_shipid  := null;

 -- Carry over unreceived expected items.
  if nvl(CUST.carryover_unrcvd_qty_yn, 'N') = 'Y' and oh.ordertype in ('R','C') then
    zld.receipt_carryover(oh.orderid, oh.shipid, in_new_orderid, in_new_shipid, in_userid, out_msg);
  end if;
  if out_msg != 'OKAY' then
    return;
  end if;

end loop;

for r in curCustAuxOrdClosePrc loop
  close_inbound_upadj (in_loadno, in_facility, in_userid, out_msg); 
end loop;

zbill.receipt_load_add_asof(in_loadno, ld.rcvddate,in_userid, out_msg);

zoo.closeload(in_facility, in_loadno, ld.loadtype);

--  notify carrier and/or customer by email that inbound load is closed
zsmtp.notify_load_closed(in_loadno);

update trailer
   set loadno = null,
       activity_type = 'DFL',
       contents_status = 'E',
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno = in_loadno;

dteEnd := sysdate;
zms.log_msg('LoadClose', in_facility, '',
  'End Load Close Inbound  ' || in_loadno || ' (' ||
  rtrim(substr(zlb.formatted_staffhrs((dteEnd - dteStart)*24),1,12)) || ')',
  'I', in_userid, strMsg);
zlh.add_loadhistory(in_loadno,
   'Load Closed',
   'Load Closed',
   in_userid, out_msg);

--if zbr.calc_receipt_bills(in_loadno, in_userid, out_msg) = zbill.GOOD then
out_msg := 'OKAY';
--end if;

exception when others then
  out_msg := 'ldcil ' || substr(sqlerrm,1,80);
end close_inbound_load;

PROCEDURE close_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_prono IN varchar2
,in_shipdate IN date
,in_userid IN varchar2
,in_force_close IN varchar2
,out_regen_needed OUT varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         trailer,
         seal,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyship,0) as qtyship,
         trim(billoflading) billoflading,
         trim(ldpassthruchar02) ldpassthruchar02,
         trim(ldpassthruchar40) ldpassthruchar40
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Corders is
  select oh.orderid,
         oh.shipid,
         nvl(oh.wave,0) as wave,
         oh.orderstatus,
         oh.ordertype,
         oh.tofacility,
         nvl(oh.qtyorder,0) as qtyorder,
         nvl(oh.qtyship,0) as qtyship,
         oh.fromfacility,
         oh.custid,
         oh.xdockorderid,
         nvl(oh.shiptoname,oh.shipto) as shipto,
         decode(oh.shiptoname,null,cn.postalcode,oh.shiptopostalcode) as shiptopostalcode,
         decode(oh.shiptoname,null,oh.shipto,oh.shiptoname||oh.shiptoaddr1||oh.shiptoaddr2) as shiptoaddr1addr2,
         oh.shipterms,
         trim(oh.billoflading) billoflading,
         trim(oh.hdrpassthruchar50) hdrpassthruchar50,
         trim(oh.hdrpassthruchar27) hdrpassthruchar27
    from orderhdr oh, consignee cn
   where loadno = in_loadno
     and fromfacility = in_facility
     and oh.shipto = cn.consignee (+);
ords Corders%rowtype;

cursor curUnitsBackOrderLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and nvl(qtyorder,0) > nvl(qtyship,0)
     and nvl(qtyentered,0) != 0;

cursor curWeightsBackOrderLines(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         nvl(weight_entered_lbs,0) as weight_entered_lbs,
         nvl(weight_entered_kgs,0) as weight_entered_kgs,
         nvl(weightpick,0) as weightpick,
         decode(nvl(variancepct_use_default,'Y'),'N',
                nvl(variancepct,0),zci.variancepct(custid,item)) as variancepct,
         qtytype,
         weightship,
         decode(nvl(weight_entered_lbs,0),0,zwt.from_kgs_to_lbs(custid,nvl(weight_entered_kgs,0)),
                weight_entered_lbs) as weightorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and backorder in ('A','P')
     and ( nvl(weight_entered_lbs,0) != 0 or nvl(weight_entered_kgs,0) != 0 );

cursor curPlatesToDelete is
  select lpid, parentlpid, quantity, weight
    from plate
   where lpid in (select distinct fromlpid
                    from shippingplate
                   where loadno = in_loadno
                     and type = 'F'
                     and status in ('L','SH'))
     and status = 'P';

cursor curChildrenToDelete(in_parentlpid varchar2) is
  select lpid
    from plate
   where parentlpid = in_parentlpid
     and status = 'P';

cursor curCustAux(in_custid in varchar2) is
   select generatebolnumber
     from customer_aux
    where custid = in_custid;
caux curCustAux%rowtype;

cursor curBOLByLoadShipTo(in_loadno in number, in_facility varchar2, in_shipto varchar2) is
   select billoflading
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and nvl(shiptoname,shipto) = in_shipto
      and trim(billoflading) is not null;
cbol curBOLByLoadShipTo%rowtype;

cursor curBOLByLoadShipTerms(in_loadno in number, in_facility varchar2, in_shipterms varchar2, in_postalcode varchar2) is
   select oh.billoflading
     from orderhdr oh, consignee cn
    where oh.loadno = in_loadno
      and oh.shipto = cn.consignee (+)
      and oh.fromfacility = in_facility
      and oh.shipterms = in_shipterms
      and substr(decode(oh.shiptoname,null,cn.postalcode,oh.shiptopostalcode),1,5) = substr(in_postalcode,1,5)
      and trim(oh.billoflading) is not null;

cursor curBOLByLoadCustShipTo(in_loadno in number, in_facility varchar2, in_custid varchar2, in_shipto varchar2) is
   select billoflading
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and custid = in_custid
      and nvl(shiptoname,shipto) = in_shipto
      and trim(billoflading) is not null;

cursor curBOLByLoadCustShipTerms(in_loadno in number, in_facility varchar2, in_custid varchar2, in_shipterms varchar2, in_postalcode varchar2) is
   select oh.billoflading
     from orderhdr oh, consignee cn
    where oh.loadno = in_loadno
      and oh.shipto = cn.consignee (+)
      and oh.fromfacility = in_facility
      and custid = in_custid
      and oh.shipterms = in_shipterms
      and substr(decode(oh.shiptoname,null,cn.postalcode,oh.shiptopostalcode),1,5) = substr(in_postalcode,1,5)
      and trim(oh.billoflading) is not null;

cursor curVICSBOLByLoadHPT50(in_loadno in number, in_facility varchar2, in_hdrpassthruchar50 varchar2) is
   select hdrpassthruchar27
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and hdrpassthruchar50 = in_hdrpassthruchar50
      and trim(hdrpassthruchar27) is not null;
cvbolhpt50 curVICSBOLByLoadHPT50%rowtype;

cursor curVICSBOLByLoadShipTo(in_loadno in number, in_facility varchar2, in_shiptoaddr1addr2 varchar2) is
   select billoflading
     from orderhdr
    where loadno = in_loadno
      and fromfacility = in_facility
      and decode(shiptoname,null,shipto,shiptoname||shiptoaddr1||shiptoaddr2) = in_shiptoaddr1addr2
      and trim(billoflading) is not null;
cvbolst curVICSBOLByLoadShipTo%rowtype;

cursor curCustUCC128(in_custid varchar2) is
   select nvl(substr(rpad(manufacturerucc,7,'0'),0,7),'0000000') as manufacturerucc
     from customer
    where custid = in_custid;
cucc curCustUCC128%rowtype;

cursor curOrderNeedsConsumable is
   select oh.orderid, oh.shipid
     from orderhdr oh, customer cu
    where oh.loadno = in_loadno
      and oh.ordertype = 'O'
      and oh.custid = cu.custid
      and oh.has_consumables = 'Y'
      and not exists
          (select 1
             from consumehistory
            where custid = oh.custid
              and facility = oh.fromfacility
              and orderid = oh.orderid
              and shipid = oh.shipid);
ohnc curOrderNeedsConsumable%rowtype;
cntRows integer;
cntStockTransfer integer;
minorderstatus orderhdr.orderstatus%type;
intErrorno integer;
dteStart date;
dteEnd date;
dteShipDate date;
strMsg varchar2(255);
l_finalclose char(1);
l_out varchar2(255);
l_var_wt_lower number;
bol_flag varchar2(1);
newbilloflading varchar2(40);
custUCC128 varchar2(7);
nbolseq number(8);
l_argcnt pls_integer;
l_schema varchar2(255);
l_obj varchar2(255);
l_auxdata varchar2(255);
l_skiplblcheck varchar2(1);
l_seal_required customer_aux.seal_required%type := 'N';


FUNCTION specify_changeproc
(in_changeproc IN varchar2
) return varchar2 is
out_changeproc caselabels.changeproc%type;
pos pls_integer;

begin
/* if labels were generated using the _PLATE version, use the order level version
   to check all labels are correct instead of one plate's worth of labels */
pos := instr(in_changeProc, '_PLATE');
if pos > 0 then
   out_changeproc := substr(in_changeproc, 1, pos - 1);
else
   out_changeproc := in_changeproc;
end if;

return out_changeproc;
end specify_changeproc;

begin

out_msg := '';
out_regen_needed := 'N';
dteStart := sysdate;

select count(1) into cntRows
  from orderhdr
 where loadno = in_loadno
   and ordertype = 'F';

if cntRows != 0 then
   close_freight_load(in_loadno, in_facility, in_prono, in_shipdate, in_userid, out_msg);
   return;
end if;

select count(1) into cntRows
  from orderhdr
 where loadno = in_loadno
   and fromfacility != in_facility
   and orderstatus < '8';
if cntRows != 0 then
  l_finalclose := 'N';
  zms.log_msg('LoadClose', in_facility, '',
    'Begin (Partial) Load Close Outbound ' || in_loadno,
    'I', in_userid, strMsg);
else
  l_finalclose := 'Y';
  zms.log_msg('LoadClose', in_facility, '',
    'Begin Load Close Outbound ' || in_loadno,
    'I', in_userid, strMsg);
end if;

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

open Corders;
fetch Corders into ords;
if Corders%notfound then
  close Corders;
  out_msg := 'Order not found for loadno: ' || in_loadno;
  return;
end if;
close Corders;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus not in ('7','8') then
  out_msg := 'Invalid load status for close: ' || ld.loadstatus;
  return;
end if;

select count(1)
  into cntRows
  from orderhdr
 where loadno = in_loadno
   and fromfacility = in_facility
   and orderstatus = 'X';
if cntRows != 0 then
  out_msg := 'Cannot close--Cancelled order count on load: ' || cntRows;
  return;
end if;

select count(1)
  into cntRows
  from orderhdr
 where loadno = in_loadno
   and fromfacility = in_facility
   and priority = 'E';
if cntRows != 0 then
  out_msg := 'Cannot close--Exception priority order count on load: ' || cntRows;
  return;
end if;

l_out := null;
for cr in (select distinct custid
             from orderhdr
            where loadno = in_loadno
              and 'Y' = zcu.credit_hold(custid))
loop
    if l_out is null then
        l_out := cr.custid;
    else
        l_out := l_out || ', ' || cr.custid;
    end if;
end loop;
if l_out is not null then
    out_msg := 'Cannot close--Customers '||l_out||' are on credit hold';
    return;
end if;

select count(1)
  into cntRows
  from orderhdr
 where loadno = in_loadno
   and orderstatus in ('1','2','3');
if cntRows != 0 then
  out_msg := 'Cannot close--Unreleased Orders on load: ' || cntRows;
  return;
end if;

select count(1)
  into cntRows
  from shippingplate sp
 where loadno = in_loadno
   and facility = in_facility
   and type in ('F','P')
   and status in ('L')
   and exists
       (select *
          from orderdtl od
         where sp.orderid = od.orderid
           and sp.shipid = od.shipid
           and sp.orderitem = od.item
           and nvl(sp.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
           and od.linestatus = 'X');

if cntRows != 0 then
  out_msg := 'Cannot close--Cancelled line count on load: ' || cntRows;
  return;
end if;

if ld.trailer is null then
  out_msg := 'A Trailer entry is required';
  return;
end if;

for cu in (select distinct custid,shipto
             from orderhdr
            where loadno = in_loadno)
loop
  begin
    select nvl(seal_required,'N')
      into l_seal_required
      from customer_aux
     where custid = cu.custid;
  exception when others then
    l_seal_required := 'N';
  end;
  if l_seal_required = 'Y' then
    exit;
  end if;
  if rtrim(cu.shipto) is not null then
    begin
      select nvl(seal_required,'N')
        into l_seal_required
        from consignee
       where consignee = cu.shipto;
    exception when others then
      l_seal_required := 'N';
    end;
  end if;
  if l_seal_required = 'Y' then
    exit;
  end if;
end loop;

if (l_seal_required = 'Y') and
   (ld.seal is null) then
  out_msg := 'A Seal entry is required';
  return;
end if;


begin
  if (in_shipdate is null)
  or (trunc(in_shipdate) = to_date('12/30/1899','mm/dd/yyyy')) then
    dteShipDate := sysdate;
  else
    dteShipDate := in_shipdate;
  end if;
exception when others then
  dteShipDate := null;
end;

select count(1)
  into cntRows
  from tasks
 where loadno = in_loadno
   and facility = in_facility
   and priority = '0';
if cntRows != 0 then
  out_msg := 'There are active tasks for this load';
  return;
end if;

select count(1)
  into cntRows
  from subtasks
 where loadno = in_loadno
   and facility = in_facility
   and priority = '0';
if cntRows != 0 then
  out_msg := 'There are active sub-tasks for this load';
  return;
end if;

select count(1)
  into cntRows
  from shippingplate SP, orderhdr OH
 where SP.status in ('P','S','FA','M')
   and SP.loadno = in_loadno
   and SP.facility = in_facility
   and OH.orderid = SP.orderid
   and OH.shipid = SP.shipid
   and OH.xdockorderid is null;
if cntRows != 0 then
  out_msg := 'There are unloaded shipping plates for this load';
  return;
end if;

for crec in (select distinct W.wave, W.consolidated, W.shipcost
               from waves W, orderhdr OH
              where OH.loadno = in_loadno
                and OH.fromfacility = in_facility
                and W.wave = OH.wave)
loop
    if crec.consolidated = 'Y' then
        select count(1)
          into cntRows
          from orderhdr
         where wave = crec.wave
           and orderstatus != 'X'
           and nvl(loadno,-1) != in_loadno;
        if cntRows != 0 then
            out_msg := 'The consolidated wave ' || crec.wave
                || ' does not have all orders on this load.';
            return;
        end if;

        if nvl(crec.shipcost,0) = 0 then
            out_msg := 'The consolidated wave ' || crec.wave
                || ' does not have a shipment cost specified.';
            return;
        end if;

    end if;
    out_msg := null;
    for ID in (select OH.custid
                 from orderhdr OH, customer_aux CA
                 where OH.wave = crec.wave
                   and oh.custid = CA.custid
                   and orderstatus <> 'X'
                   and nvl(international_dimensions,'N') = 'Y') loop
        for OH in (select OH.orderid, OH.shipid, nvl(C.countrycode, nvl(OH.shiptocountrycode, 'USA')) countrycode
                     from orderhdr OH, consignee C
                    where OH.loadno = in_loadno
                      and oh.custid = ID.custid
                      and orderstatus <> 'X'
                      and c.consignee (+) = nvl(oh.shipto,'(none)'))  loop
           if OH.countrycode <> 'USA' then
              select count(1) into cntRows
                 from shippingplate
                where orderid = crec.wave
                  and shipid = 0
                  and (nvl(height,0) = 0
                     or nvl(length,0) = 0
                     or nvl(width,0) = 0);
              if cntRows > 0 then
                  out_msg := 'Cannot close -- the following wave needs dimensions: '|| crec.wave;
                  return;
              end if;
           end if;
        end loop;
    end loop;

end loop;

select count(1)
  into cntRows
  from orderhdr OH, orderdtl OD, customer_aux CX
 where OH.loadno = in_loadno
   and OH.fromfacility = in_facility
   and OH.xdockorderid is null
   and OD.orderid = OH.orderid
   and OD.shipid = OH.shipid
   and nvl(OD.qtyship,0) > nvl(OD.qtyorder,0)
   and CX.custid = OH.custid
   and nvl(CX.allow_overpicking,'N') = 'N';
if cntRows != 0 then
  out_msg := 'Cannot close--quantity shipped would exceed quantity ordered';
  return;
end if;
/*
begin
   select upper(nvl(defaultvalue, 'N')) into l_skiplblcheck
      from systemdefaults
      where defaultid = 'SKIPRESTAGEDCLOSELABELCHECK';
exception
   when OTHERS then
      l_skiplblcheck := 'N';
end;

for lbl in (select distinct OH.orderid, OH.shipid, CS.changeproc
               from orderhdr OH, caselabels CS, waves W
               where OH.loadno = in_loadno
                 and CS.orderid = OH.orderid
                 and CS.shipid = OH.shipid
                 and CS.changeproc is not null
                 and (l_skiplblcheck = 'N' or nvl(OH.restaged_yn,'N') = 'N')
                 and OH.wave = W.wave
                 and nvl(W.consolidated,'N') != 'Y') loop
   lbl.changeproc := zld.specify_changeproc(lbl.changeproc);

   zlbl.parse_db_object(lbl.changeproc, l_schema, l_obj);
   select count(1) into l_argcnt
      from user_arguments
      where package_name = l_schema
        and object_name = l_obj;

   for slp in (select lpid from shippingplate
                  where orderid = lbl.orderid
                    and shipid = lbl.shipid
                    and status != 'U'
                    and parentlpid is null) loop

      if l_argcnt = 4 then
         execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
               || ''', ''Q'', ''C'', :OUT1); end;'
               using out l_out;
      else
         l_auxdata := 'ORDER|' || lbl.orderid || '|' || lbl.shipid;
         execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
               || ''', ''Q'', ''C'', '''|| l_auxdata || ''', :OUT1); end;'
               using out l_out;
      end if;

      if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
         if out_msg is null then
            out_msg := 'Cannot close -- the following orders need labels regenerated: ';
         end if;
         if nvl(length(out_msg),0) < 200 then
            out_msg := out_msg || ' ' || lbl.orderid || '-' || lbl.shipid;
         elsif substr(out_msg, -3) != '...' then
            out_msg := out_msg || '...';
         end if;
      end if;
      exit;
   end loop;
end loop;

-- check for consolidated orders
for wav in (select distinct OH.wave
            from orderhdr OH, waves W
            where OH.loadno = in_loadno
              and OH.wave = W.wave
              and nvl(W.consolidated,'N') = 'Y'
              and OH.original_wave_before_combine is null
            union
               select distinct OH.wave
                 from orderhdr OH, waves W
                where OH.loadno = in_loadno
                 and OH.original_wave_before_combine = W.wave
              and nvl(W.consolidated,'N') = 'Y'
                 and OH.original_wave_before_combine is not null) loop

   for lbl in (select distinct CS.changeproc
               from orderhdr OH, caselabels CS
               where OH.wave = wav.wave
                 and (l_skiplblcheck = 'N' or nvl(OH.restaged_yn,'N') = 'N')
                 and CS.orderid = OH.orderid
                 and CS.shipid = OH.shipid
                 and CS.changeproc is not null
                       and OH.original_wave_before_combine is null
               union
                   select distinct CS.changeproc
                    from orderhdr OH, caselabels CS
                   where OH.original_wave_before_combine = wav.wave
                 and (l_skiplblcheck = 'N' or nvl(OH.restaged_yn,'N') = 'N')
                 and CS.orderid = OH.orderid
                 and CS.shipid = OH.shipid
                 and CS.changeproc is not null
                 and OH.original_wave_before_combine is not null) loop
      lbl.changeproc := zld.specify_changeproc(lbl.changeproc);
      zlbl.parse_db_object(lbl.changeproc, l_schema, l_obj);
      select count(1) into l_argcnt
         from user_arguments
         where package_name = l_schema
           and object_name = l_obj;

      for slp in (select lpid from shippingplate
                  where orderid = wav.wave
                    and shipid = 0
                    and status != 'U'
                    and parentlpid is null) loop

         if l_argcnt = 4 then
            execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                  || ''', ''Q'', ''C'', :OUT1); end;'
                  using out l_out;
         else
            l_auxdata := 'ORDER|' || wav.wave || '|0';
            execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                  || ''', ''Q'', ''C'', '''|| l_auxdata || ''', :OUT1); end;'
                  using out l_out;
         end if;

         if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
            if out_msg is null then
               out_msg := 'Cannot close -- the following consolidated orders need labels regenerated:';
            end if;
            if instr(out_msg, wav.wave || '-0') = 0 then
               if nvl(length(out_msg),0) < 200 then
                  out_msg := out_msg || ' ' || wav.wave || '-0';
               elsif substr(out_msg, -3) != '...' then
                  out_msg := out_msg || '...';
               end if;
            end if;
         end if;
         exit;
      end loop;
   end loop;
end loop;
*/
if nvl(in_force_close, 'N') <> 'Y' then
   zld.check_labels(in_loadno, 'N', out_regen_needed, l_out);
   if l_out <> 'NONE' then
      out_msg := l_out;
      return;
   end if;
end if;

select count(1)
  into cntRows
  from orderhdr OH, customer_aux CX
 where OH.loadno = in_loadno
   and (OH.trailernosetemp is null
     or OH.trailermiddletemp is null
     or OH.trailertailtemp is null)
   and CX.custid (+) = OH.custid
   and nvl(CX.trackoutboundtemps,'N') = 'Y';
if cntRows != 0 then
  out_msg := 'Cannot close--trailer temperatures are required';
  return;
end if;

ohnc := null;
open curOrderNeedsConsumable;
fetch curOrderNeedsConsumable into ohnc;
close curOrderNeedsConsumable;
if ohnc.orderid is not null then
  out_msg := 'Consumables entry required for order ' || ohnc.orderid || '-' || ohnc.shipid;
  return;
end if;

for ID in (select OH.custid
               from orderhdr OH, customer_aux CA
               where OH.loadno = in_loadno
                 and oh.custid = CA.custid
                 and orderstatus <> 'X'
                 and nvl(international_dimensions,'N') = 'Y') loop
   for OH in (select OH.orderid, OH.shipid, nvl(C.countrycode, nvl(OH.shiptocountrycode, 'USA')) countrycode
                from orderhdr OH, consignee C
               where OH.loadno = in_loadno
                 and oh.custid = ID.custid
                 and orderstatus <> 'X'
                 and c.consignee (+) = nvl(oh.shipto,'(none)'))  loop
      if OH.countrycode <> 'USA' then
         select count(1) into cntRows
            from shippingplate
           where orderid = OH.orderid
             and shipid = OH.shipid
             and parentlpid is null
             and (nvl(height,0) = 0 or
                  nvl(length,0) = 0 or
                  nvl(width,0) = 0);
         if cntRows > 0 then
            if out_msg is null then
               out_msg := 'Cannot close -- the following orders need dimensions: ';
            else
               out_msg := out_msg || '; ';
            end if;
            out_msg := out_msg || OH.orderid || '-' || OH.shipid;
         end if;
      end if;
   end loop;
end loop;

if out_msg is not null then
   return;
end if;

ztk.delete_subtasks_by_loadno(in_loadno,in_userid,in_facility,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('LoadClose', in_facility, '',
       'Delete subtask: ' || out_msg,
       'E', in_userid, strMsg);
end if;

if ld.loadtype = 'OUTT' then
  ld.loadtype := 'INT';
  ld.doorloc := null;
end if;

/* PRN 25132 - if this is a stock transfer order, then copy the ship date to the receive date on the load */
select count(1)
into cntStockTransfer
from orderhdr
where loadno = in_loadno
   and ordertype = 'U' and fromfacility = tofacility;

if ld.loadtype = 'OUTT' then
  ld.loadtype := 'INT';
  if cntStockTransfer = 0 then
    ld.doorloc := null;
  end if;
end if;

update loads
   set loadstatus = '9',
       stageloc = null,
       doorloc = decode(l_finalclose, 'Y', ld.doorloc, null),
       loadtype = ld.loadtype,
      rcvddate = case when cntStockTransfer > 0 then dteShipDate else rcvddate end,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstatus < '9';

update loadstop
   set loadstopstatus = '9',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstopstatus < '9';

if l_finalclose = 'Y' then
  update shippingplate
     set status = 'SH',
         location = substr(ld.trailer,1,10),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and status = 'L';

  update orderhdr
     set orderstatus = '9',
         stageloc = null,
         prono = nvl(rtrim(in_prono),prono),
         lastuser = in_userid,
         lastupdate = sysdate,
         dateshipped = dteShipDate
   where loadno = in_loadno
     and orderstatus < '9';
else
  update shippingplate
     set location = substr(ld.trailer,1,10),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and facility = in_facility
     and status = 'L';

  update orderhdr
     set orderstatus = '9',           -- undone later, needed for waves update
         stageloc = null,
         prono = nvl(rtrim(in_prono),prono),
         lastuser = in_userid,
         lastupdate = sysdate,
         dateshipped = dteShipDate
   where loadno = in_loadno
     and fromfacility = in_facility
     and orderstatus < '9';
end if;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

for oh in Corders
loop
  delete from commitments
   where orderid = oh.orderid
     and shipid = oh.shipid;
  delete from orderlabor
   where orderid = oh.orderid
     and shipid = oh.shipid;
  delete from itemdemand
   where orderid = oh.orderid
     and shipid = oh.shipid;
  if oh.wave != 0 then
    begin
      select min(orderstatus)
        into minorderstatus
        from orderhdr
       where fromfacility = ld.facility
         and wave = oh.wave
         and ordertype not in ('W','K');
    exception when no_data_found then
      minorderstatus := '9';
    end;
    if minorderstatus > '8' then
      update waves
         set wavestatus = '4',
             lastuser = in_userid,
             lastupdate = sysdate
       where wave = oh.wave
         and wavestatus < '4';
    end if;
  end if;
  if oh.ordertype in ('T','U') then
    update plate
       set status = 'I',
           facility = oh.tofacility,
           parentfacility = decode(parentfacility,null,null,oh.tofacility),
           location = substr(ld.trailer,1,10),
           lasttask = 'LC',
           lastuser = in_userid,
           lastupdate = sysdate
     where lpid in (select distinct fromlpid
                      from shippingplate
                     where orderid = oh.orderid
                       and shipid = oh.shipid
                       and type in ('P','F'))
       and status = 'P';
  end if;
  if (oh.orderstatus != 'X') and
     (oh.xdockorderid is null) and
     (not is_split_facility_order(oh.orderid, oh.shipid)) then
    for bo in curUnitsBackOrderLines(oh.orderid,oh.shipid)
    loop
      zbo.create_back_order_item(oh.orderid,oh.shipid,bo.item,
        bo.lotnumber,in_userid,intErrorno,out_msg);
      if intErrorno != 0 then
        zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
          'Back Order: ' || oh.orderid || '-' || oh.shipid || ' ' ||
          bo.item || ' ' || bo.lotnumber || ' ' ||
          out_msg, 'E', in_userid, strMsg);
      end if;
    end loop;
    for bo in curWeightsBackOrderLines(oh.orderid,oh.shipid)
    loop
      if bo.weightship >= bo.weightorder then
        goto continue_weight_loop;
      end if;
      l_var_wt_lower := (bo.variancepct/100) * bo.weightorder;
      if bo.weightship >= l_var_wt_lower then
        goto continue_weight_loop;
      end if;
      zbo.create_back_order_item(oh.orderid,oh.shipid,bo.item,
        bo.lotnumber,in_userid,intErrorno,out_msg);
      if intErrorno != 0 then
        zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
          'Back Order: ' || oh.orderid || '-' || oh.shipid || ' ' ||
          bo.item || ' ' || bo.lotnumber || ' ' ||
          out_msg, 'E', in_userid, strMsg);
      end if;
    << continue_weight_loop >>
      null;
    end loop;
  end if;
  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Closed',
     'Order Closed',
     in_userid, out_msg);

  zcus.ship_order(oh.orderid, oh.shipid);

  zprono.check_for_prono_assignment
  (oh.orderid
  ,oh.shipid
  ,'Load Close'
  ,intErrorno
  ,strMsg
  );

  if l_finalclose = 'Y' then
    caux := null;
    open curCustAux(oh.custid);
    fetch curCustAux into caux;
    close curCustAux;
    bol_flag := nvl(caux.generatebolnumber,'N');

    if bol_flag <> 'N' then
      cucc := null;
      open curCustUCC128(oh.custid);
      fetch curCustUCC128 into cucc;
      close curCustUCC128;

      custUCC128 := cucc.manufacturerucc;

      cbol := null;
      if bol_flag = 'Y' then
        open curBOLByLoadShipTo(in_loadno, in_facility, oh.shipto);
        fetch curBOLByLoadShipTo into cbol;
        close curBOLByLoadShipTo;
      elsif bol_flag = 'Z' then
        open curBOLByLoadShipTerms(in_loadno, in_facility, oh.shipterms, oh.shiptopostalcode);
        fetch curBOLByLoadShipTerms into cbol;
        close curBOLByLoadShipTerms;
      elsif bol_flag = 'C' then
        open curBOLByLoadCustShipTo(in_loadno, in_facility, oh.custid, oh.shipto);
        fetch curBOLByLoadCustShipTo into cbol;
        close curBOLByLoadCustShipTo;
      elsif bol_flag = 'S' then
        open curBOLByLoadCustShipTerms(in_loadno, in_facility, oh.custid, oh.shipterms, oh.shiptopostalcode);
        fetch curBOLByLoadCustShipTerms into cbol;
        close curBOLByLoadCustShipTerms;
      end if;

      if cbol.billoflading is not null then
         newbilloflading := cbol.billoflading;
      else
         select bolseq.nextval into nbolseq from dual;
         newbilloflading := trim(to_char(nbolseq,'0000000'));
      end if;

      update orderhdr
         set billoflading = decode(bol_flag,'N',billoflading,newbilloflading)
       where orderid = oh.orderid
         and shipid = oh.shipid;
    end if;

    if (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') in ('Y','L')) then
      if (nvl(ld.ldpassthruchar40,'(none)') = '(none)') and
         (nvl(ld.ldpassthruchar02,'(none)') != '(none)') then
        cucc := null;
        open curCustUCC128(oh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        ld.ldpassthruchar40 := calccheckdigit(cucc.manufacturerucc||trim(to_char(in_loadno,'000000000')));

        update loads
           set ldpassthruchar40 = ld.ldpassthruchar40
         where loadno=in_loadno;
      end if;

      cvbolhpt50 := null;
      open curVICSBOLByLoadHPT50(in_loadno, in_facility, oh.hdrpassthruchar50);
      fetch curVICSBOLByLoadHPT50 into cvbolhpt50;
      close curVICSBOLByLoadHPT50;

      if nvl(cvbolhpt50.hdrpassthruchar27,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(oh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(cucc.manufacturerucc||trim(to_char(oh.orderid,'0000000'))||trim(to_char(oh.shipid,'00')));

        update orderhdr
           set hdrpassthruchar27 = newbilloflading,
               autogenerated_vicsbol = 'Y'
         where orderid = oh.orderid
           and shipid = oh.shipid;

      elsif nvl(oh.hdrpassthruchar27,'(none)') = '(none)' then
        update orderhdr
           set hdrpassthruchar27 = cvbolhpt50.hdrpassthruchar27,
               autogenerated_vicsbol = 'Y'
         where orderid = oh.orderid
           and shipid = oh.shipid;
      end if;
    elsif (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'P') then
      if nvl(ld.billoflading,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(oh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        ld.billoflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                          trim(to_char(in_loadno,'000000000')));

        update loads
           set billoflading = ld.billoflading
         where loadno=in_loadno;
      end if;

      cvbolst := null;
      open curVICSBOLByLoadShipTo(in_loadno, in_facility, oh.shiptoaddr1addr2);
      fetch curVICSBOLByLoadShipTo into cvbolst;
      close curVICSBOLByLoadShipTo;

      if nvl(cvbolst.billoflading,'(none)') = '(none)' then
        cucc := null;
        open curCustUCC128(oh.custid);
        fetch curCustUCC128 into cucc;
        close curCustUCC128;

        newbilloflading := calccheckdigit(nvl(cucc.manufacturerucc,'0000000')||
                                          trim(to_char(oh.orderid,'0000000'))||
                                          trim(to_char(oh.shipid,'00')));

        update orderhdr
           set billoflading = newbilloflading
         where orderid = oh.orderid
           and shipid = oh.shipid;

      elsif nvl(oh.billoflading,'(none)') = '(none)' then
        update orderhdr
           set billoflading = cvbolst.billoflading
         where orderid = oh.orderid
           and shipid = oh.shipid;
      end if;
    end if;

    zsmtp.notify_order_shipped(oh.orderid, oh.shipid);
  end if;

end loop;

for cwt in (select SP.custid, SP.item, SP.lotnumber, SP.weight
               from shippingplate SP, custitemview CI
               where SP.loadno = in_loadno
                 and SP.type in ('P','F')
                 and CI.custid = SP.custid
                 and CI.item = SP.item
                 and CI.use_catch_weights = 'Y') loop
   zcwt.add_item_lot_catch_weight(in_facility, cwt.custid, cwt.item, cwt.lotnumber,
         -cwt.weight, out_msg);
end loop;

if l_finalclose = 'N' then
  update orderhdr
     set orderstatus = '8'
   where loadno = in_loadno
     and fromfacility = in_facility;

  dteEnd := sysdate;
  zms.log_msg('LoadClose', in_facility, '',
    'End (Partial) Load Close Outbound ' || in_loadno || ' (' ||
    rtrim(substr(zlb.formatted_staffhrs((dteEnd - dteStart)*24),1,12)) || ')',
    'I', in_userid, strMsg);

  out_msg := 'OKAYPART';
else

  for x in curPlatesToDelete
  loop
    zlp.plate_to_deletedplate(x.lpid,in_userid,'LC',out_msg);
    if (x.parentlpid is not null) then
      zplp.decrease_parent(x.parentlpid, x.quantity, x.weight, in_userid, 'LC', out_msg);
    end if;
    for y in curChildrenToDelete(x.lpid)
    loop
      zlp.plate_to_deletedplate(y.lpid,in_userid,'LC',out_msg);
    end loop;
  end loop;

  zbill.ship_load_add_asof(in_loadno, dteShipDate, in_userid, out_msg);

  --  notify carrier and/or customer by email that outbound load is closed
  zsmtp.notify_load_closed(in_loadno);
  /*
  update trailer
     set loadno = null,
         disposition = 'SHP',
         activity_type = 'DFL',
         facility = null,
         location = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where trailer_number = ld.trailer
     and carrier = ld.carrier
     and loadno is not null;
  */

  update trailer
     set loadno = null,
         contents_status = 'F',
         activity_type = 'DFL',
--         disposition = 'INY',
         lastuser = in_userid,
         lastupdate = sysdate
   where trailer_number = ld.trailer
     and carrier = ld.carrier
     and loadno is not null;

  out_msg := 'OKAY';
  zlh.add_loadhistory(in_loadno,
     'Load Closed',
     'Load Closed',
     in_userid, out_msg);

  dteEnd := sysdate;
  zms.log_msg('LoadClose', in_facility, '',
    'End Load Close Outbound ' || in_loadno || ' (' ||
    rtrim(substr(zlb.formatted_staffhrs((dteEnd - dteStart)*24),1,12)) || ')',
    'I', in_userid, strMsg);

  out_msg := 'OKAY';
end if;

zoo.closeload(in_facility, in_loadno, ld.loadtype);

if nvl(in_force_close, 'N') = 'Y'  then
   zld.log_no_regen_close(in_loadno, in_userid, in_facility, out_msg);
end if;
exception when others then
  out_msg := 'ldcol ' || substr(sqlerrm,1,80);
end close_outbound_load;

PROCEDURE deassign_order_from_load
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_manual IN varchar2  -- 'Y' deassign request from order form;
                        -- all other callers use 'N'
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
)
is
cursor Corderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility,
         nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(amtorder,0) as amtorder,
         nvl(qtyrcvd,0) as rcvdorder,
         wave,
         nvl(weight_entered_lbs,0) as weight_entered_lbs,
         nvl(weight_entered_kgs,0) as weight_entered_kgs,
         trim(hdrpassthruchar27) as hdrpassthruchar27,
         original_wave_before_combine
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

cursor Cloads(in_loadno number) is
  select nvl(loadstatus,'?') as loadstatus,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

currcount integer;
minstatus orderhdr.orderstatus%type;
maxstatus orderhdr.orderstatus%type;
newstatus loadstop.loadstopstatus%type;
cordid waves.wave%type;
ccombinedwave waves.wave%type;
oldstatus orderhdr.orderstatus%type;
splitfac_order boolean := false;
l_qtyship orderhdr.qtyship%type;
l_mlip shippingplate.lpid%type;
l_builtmlip shippingplate.lpid%type;
l_msg varchar2(255);
l_cnt pls_integer;
v_count number;

begin

out_msg := '';
out_errorno := 0;

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  out_errorno := 1;
  return;
end if;
close Corderhdr;
cordid := zcord.cons_orderid(in_orderid, in_shipid);
if (nvl(oh.original_wave_before_combine,0) <> 0) then
  ccombinedwave := zcord.cons_orderid(oh.original_wave_before_combine, 0);
else
  ccombinedwave := 0;
end if;
oldstatus := oh.orderstatus;

if oh.loadno = 0 then
  out_msg := 'Order not assigned to load: ' || in_orderid || '-' || in_shipid;
  out_errorno := 2;
  return;
end if;

if oh.rcvdorder > 0 then
  out_msg := 'Order already began receiving.';
  out_errorno := 8;
  return;
end if;

if oh.orderstatus != 'X' then
  if (oh.orderstatus > '6') or
    ( (in_manual = 'Y') and
      (oh.ordertype in ('R','Q','C')) and
      (oh.orderstatus > '3') ) then
    out_msg := 'Invalid order status for removal: ' || oh.orderstatus;
    out_errorno := 3;
    return;
  end if;
end if;

open Cloads(oh.loadno);
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || oh.loadno;
  out_errorno := 4;
  return;
end if;
close Cloads;

splitfac_order := is_split_facility_order(in_orderid, in_shipid);
if (ld.facility != in_facility) and not splitfac_order then
  out_msg := 'Load not at your facility: ' || ld.facility;
  out_errorno := 5;
  return;
end if;

if (in_manual = 'Y') and
   (oh.orderstatus != 'X') and
   (oh.ordertype in ('R','Q','C')) then
  if ld.loadstatus > '2' then
    out_msg := 'Invalid load status for removal: ' || ld.loadstatus;
    out_errorno := 6;
    return;
  end if;
end if;

if (in_manual = 'Y') and
   (oh.orderstatus != 'X') and
   (oh.ordertype in ('R','Q','C')) then
  oh.orderstatus := '1';
end if;

if (cordid != 0) and (oldstatus != 'X') then
  select sum(nvl(qtyorder,0)), sum(nvl(weightorder,0)), sum(nvl(cubeorder,0)),
         sum(nvl(amtorder,0)), sum(nvl(qtyship,0))
    into oh.qtyorder, oh.weightorder, oh.cubeorder,
         oh.amtorder, l_qtyship
    from orderhdr
    where wave = oh.wave
      and nvl(loadno,0) != 0;
  if l_qtyship != 0 then
    out_msg := 'Consolidated order has loaded items - removal not allowed.';
    out_errorno := 9;
    return;
  end if;
  update orderhdr
     set loadno = null,
         stopno = null,
         shipno = null,
         appointmentid = 0,
         hdrpassthruchar27 = decode(nvl(autogenerated_vicsbol,'N'),'Y',null,hdrpassthruchar27),
         autogenerated_vicsbol = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where wave = oh.wave
     and nvl(loadno,0) != 0;
else
  update orderhdr
     set orderstatus = oh.orderstatus,
         loadno = null,
         stopno = null,
         shipno = null,
         appointmentid = 0,
         hdrpassthruchar27 = decode(nvl(autogenerated_vicsbol,'N'),'Y',null,hdrpassthruchar27),
         autogenerated_vicsbol = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
end if;

-- need to split off any child shippingplates for this order from top-level
-- shippingplates which have an order of 0/0 but the correct loadno
l_mlip := null;
for sp in (select lpid from shippingplate
            where loadno = oh.loadno
              and nvl(orderid,0) = 0
              and nvl(shipid,0) = 0
              and parentlpid is null) loop

   l_cnt := 0;
   for cp in (select lpid, parentlpid from shippingplate
               where nvl(orderid,0) = in_orderid
                 and nvl(shipid,0) = in_shipid
               start with lpid = sp.lpid
               connect by prior lpid = parentlpid) loop

      if (cp.parentlpid is not null and cp.parentlpid <> sp.lpid) then
        select count(1) into v_count
        from shippingplate
        where lpid = cp.parentlpid and nvl(orderid,0) = in_orderid and nvl(shipid,0) = in_shipid;

        if (v_count > 0) then
          goto continue_loop;
        end if;
      end if;

      l_cnt := l_cnt + 1;
      if l_mlip is null then                 -- create XP on first hit
         zrf.get_next_lpid(l_mlip, l_msg);
         if l_msg is not null then
            out_msg := l_msg;
            return;
         end if;
      end if;

      zrfpk.build_mast_shlp(l_mlip, cp.lpid, in_userid, null, l_builtmlip, l_msg);
      if l_msg is not null then
         out_msg := l_msg;
         return;
      end if;

      l_mlip := nvl(l_builtmlip, l_mlip);

      << continue_loop >>
        null;
   end loop;

   if l_cnt > 0 then                         -- at least 1 moved, rebalance
      update shippingplate
         set (quantity, weight) =
            (select nvl(sum(quantity), 0), nvl(sum(weight), 0)
               from shippingplate
               where type in ('F', 'P')
               start with lpid = sp.lpid
               connect by prior lpid = parentlpid)
         where lpid = sp.lpid;

      zrfld.set_ancestor_data(sp.lpid, l_msg);
      if l_msg is not null then
         out_msg := l_msg;
         return;
      end if;
   end if;
end loop;

-- hdrpassthruchar27 should be cleared
-- if it's populated with a generated VISC BOL number
if (nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') in ('Y','L')) then
  if (cordid = 0) and (ccombinedwave = 0) then
    update orderhdr oh1
       set hdrpassthruchar27 = null
     where orderid = in_orderid
       and shipid = in_shipid
       and exists(
         select 1
           from orderhdr
          where wave = oh.wave
            and oh1.hdrpassthruchar27 like '%'||orderid||'%');
  elsif (cordid != 0) then
    update orderhdr oh1
       set hdrpassthruchar27 = null
     where wave = oh.wave
       and orderstatus != 'X'
       and nvl(trim(hdrpassthruchar27),'(none)') <> '(none)'
       and recent_order_id like 'Y%'
       and exists(
         select 1
           from orderhdr
          where wave = oh.wave
            and oh1.hdrpassthruchar27 like '%'||orderid||'%'
            and recent_order_id like 'Y%');
  else
    update orderhdr oh1
       set hdrpassthruchar27 = null
     where original_wave_before_combine = oh.original_wave_before_combine
       and orderstatus != 'X'
       and nvl(trim(hdrpassthruchar27),'(none)') <> '(none)'
       and nvl(original_wave_before_combine,0) <> 0
       and recent_order_id like 'Y%'
       and exists(
         select 1
           from orderhdr
          where original_wave_before_combine = oh.original_wave_before_combine
            and oh1.hdrpassthruchar27 like '%'||orderid||'%'
            and nvl(original_wave_before_combine,0) <> 0
            and recent_order_id like 'Y%');
  end if;
end if;

update shippingplate
   set loadno = null,
       stopno = null,
       shipno = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;
if (cordid != 0) and (oldstatus != 'X') then
  update shippingplate
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = cordid
     and shipid = 0
     and nvl(loadno,0) != 0;
  update shippingplate
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where wave = oh.wave)
     and nvl(loadno,0) != 0;
end if;

if (ccombinedwave != 0) and (oldstatus != 'X') then
  update shippingplate
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = ccombinedwave
     and shipid = 0
     and nvl(loadno,0) != 0;
  update shippingplate
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where original_wave_before_combine = oh.original_wave_before_combine)
     and nvl(loadno,0) != 0;
end if;

update batchtasks
   set loadno = null,
       stopno = null,
       shipno = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;
if (cordid != 0) and (oldstatus != 'X') then
  update batchtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = cordid
     and shipid = 0
     and nvl(loadno,0) != 0;
  update batchtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where wave = oh.wave)
     and nvl(loadno,0) != 0;
end if;

if (ccombinedwave != 0) and (oldstatus != 'X') then
  update batchtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = ccombinedwave
     and shipid = 0
     and nvl(loadno,0) != 0;
  update batchtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where original_wave_before_combine = oh.original_wave_before_combine)
     and nvl(loadno,0) != 0;
end if;

update subtasks
   set loadno = null,
       stopno = null,
       shipno = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;
if (cordid != 0) and (oldstatus != 'X') then
  update subtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = cordid
     and shipid = 0
     and nvl(loadno,0) != 0;
  update subtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where wave = oh.wave)
     and nvl(loadno,0) != 0;
end if;

if (ccombinedwave != 0) and (oldstatus != 'X') then
  update subtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = ccombinedwave
     and shipid = 0
     and nvl(loadno,0) != 0;
  update subtasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where original_wave_before_combine = oh.original_wave_before_combine)
     and nvl(loadno,0) != 0;
end if;

update tasks
   set loadno = null,
       stopno = null,
       shipno = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;
if (cordid != 0) and (oldstatus != 'X') then
  update tasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = cordid
     and shipid = 0
     and nvl(loadno,0) != 0;
  update tasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where wave = oh.wave)
     and nvl(loadno,0) != 0;
end if;

if (ccombinedwave != 0) and (oldstatus != 'X') then
  update tasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = ccombinedwave
     and shipid = 0
     and nvl(loadno,0) != 0;
  update tasks
     set loadno = null,
         stopno = null,
         shipno = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where (orderid, shipid) in
            (select orderid, shipid from orderhdr
               where original_wave_before_combine = oh.original_wave_before_combine)
     and nvl(loadno,0) != 0;
end if;

update loadstopship
   set qtyorder = nvl(qtyorder,0) - oh.qtyorder,
       weightorder = nvl(weightorder,0) - oh.weightorder,
       weight_entered_lbs = nvl(weight_entered_lbs,0) - oh.weight_entered_lbs,
       weight_entered_kgs = nvl(weight_entered_kgs,0) - oh.weight_entered_kgs,
       cubeorder = nvl(cubeorder,0) - oh.cubeorder,
       amtorder = nvl(amtorder,0) - oh.amtorder,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = oh.loadno
   and stopno = oh.stopno
   and shipno = oh.shipno;
if sql%rowcount = 0 then
  out_msg := 'Load/Stop/Shipment not found: ' ||
    oh.loadno || '/' || oh.stopno || '/' || oh.shipno;
  out_errorno := 7;
  return;
end if;

select min(orderstatus), max(orderstatus)
   into minstatus, maxstatus
   from orderhdr
   where loadno = oh.loadno
     and stopno = oh.stopno
     and fromfacility = in_facility
     and orderstatus != 'X';
if (minstatus is null) then
   select least(nvl(min(loadstopstatus), '1'), '4')
      into newstatus
      from loadstop
      where loadno = oh.loadno
        and stopno != oh.stopno;
elsif (minstatus = maxstatus) then
   if (minstatus = '2') then
      newstatus := '1';
   elsif (minstatus = '3') then
      newstatus := '2';
   else
      newstatus := minstatus;
   end if;
else
   if (maxstatus = '8') then
      newstatus := '7';
   elsif (maxstatus = '6') then
      newstatus := '5';
   else
      newstatus := maxstatus;
   end if;
end if;

update loadstop
   set loadstopstatus = newstatus,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = oh.loadno
   and stopno = oh.stopno
   and newstatus != loadstopstatus;

if ld.loadstatus = '2' then
  select count(1)
    into currcount
    from orderhdr
   where loadno = oh.loadno
     and stopno = oh.stopno
     and shipno = oh.shipno;
  if currcount = 0 then
    delete from loadstopship
     where loadno = oh.loadno
       and stopno = oh.stopno
       and shipno = oh.shipno;
  end if;
  select count(1)
    into currcount
    from orderhdr
   where loadno = oh.loadno
     and stopno = oh.stopno;
  if currcount = 0 then
    delete from loadstop
     where loadno = oh.loadno
       and stopno = oh.stopno;
  end if;
  select count(1)
    into currcount
    from orderhdr
   where loadno = oh.loadno;
  if currcount = 0 then
    update loads
       set loadstatus = '1',
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = oh.loadno;
  end if;
else
  update loads
     set loadstatus = newstatus,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = oh.loadno
     and loadstatus < newstatus;
end if;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Removed',
     'Order Removed from load '||oh.loadno||'/'||oh.stopno||'/'||oh.shipno,
     in_userid, out_msg);

zlh.add_loadhistory(oh.loadno,
     'Order Removed',
     'Order ' || in_orderid || '-' || in_shipid || 'Removed from stop/ship ' ||oh.stopno||'/'||oh.shipno,
     in_userid, out_msg);

if (cordid != 0) and (oldstatus != 'X') then
  out_msg := 'OKAYCONS';
else
  out_msg := 'OKAY';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := 'lddol ' || sqlerrm;
end deassign_order_from_load;

PROCEDURE unarrive_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_trailer_location in varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyrcvd,0) as qtyrcvd,
             trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select orderid, shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

orig_fac  orderhdr.fromfacility%type;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus != 'A' then
  out_msg := 'Invalid load status for un-arrival: ' || ld.loadstatus;
  return;
end if;

if ld.qtyrcvd > 0 then
  out_msg := 'Receipt activity has already been processed';
  return;
end if;

update loads
   set loadstatus = '2',
       rcvddate = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;
-- PRN: 5896 - If you are unarriving a transfer order, reset the loads.facility -- to the original one from the orders and reset the load status to shipped.
if ld.loadtype = 'INT' then
   select distinct fromfacility
     into orig_fac
     from orderhdr
    where loadno = in_loadno;

   update loads
      set facility = orig_fac,
          loadstatus = '9',
          lastuser = in_userid,
          lastupdate = sysdate
    where loadno = in_loadno;
end if;

update loadstop
   set loadstopstatus = '2',
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstopstatus = 'A';

-- PRN: 5896 If you unarrive a transfer load you must reset the order status
-- to shipped, because the arrival set it to Planned.
if ld.loadtype = 'INT' then
   update orderhdr
      set orderstatus = '9',
          lastuser = in_userid,
          lastupdate = sysdate
      where loadno = in_loadno
        and orderstatus = 'A';
else
   update orderhdr
      set orderstatus = '3',
          lastuser = in_userid,
          lastupdate = sysdate
      where loadno = in_loadno
        and orderstatus = 'A';
end if;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where facility = in_facility
   and loadno = in_loadno;


for oh in curOrderHdr
loop

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order UnArrived',
     'Order Unarrived from '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);

  if(out_msg <> 'OKAY') then
    exit;
  end if;

end loop;

if( out_msg <> 'OKAY') then
  return;
end if;
zlh.add_loadhistory(in_loadno,
   'Load UnArrived',
   'Load Unarrived from '||in_facility||'/'||ld.doorloc,
   in_userid, out_msg);

update trailer
   set activity_type = 'UDC',
       disposition = 'INY',
       contents_status = 'F',
       location = in_trailer_location,
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldul ' || substr(sqlerrm,1,80);
end unarrive_inbound_load;

PROCEDURE unarrive_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_trailer_location in varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyship,0) as qtyship,
             trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select *
    from orderhdr
   where loadno = in_loadno
     and fromfacility = in_facility
     and orderstatus != 'X';

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus > '8' then
  out_msg := 'Invalid load status for un-arrival: ' || ld.loadstatus;
  return;
end if;

if ld.qtyship != 0 then
  out_msg := 'Loading activity has already been processed';
  return;
end if;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where facility = in_facility
   and loadno = in_loadno;

for oh in curOrderHdr
loop

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order UnArrived',
     'Order Unarrived from '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);


end loop;
zlh.add_loadhistory(in_loadno,
   'Load UnArrived',
   'Load Unarrived from '||in_facility||'/'||ld.doorloc,
   in_userid, out_msg);

update trailer
   set activity_type = 'UDC',
       location = in_trailer_location,
       disposition = 'INY',
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldul ' || substr(sqlerrm,1,80);
end unarrive_outbound_load;

PROCEDURE cancel_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyship,0) as qtyship,
             trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

ohcount integer;
l_use_yard char(1);
begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

/* don't check status
if ld.loadstatus not in ('1','2') then
  out_msg := 'Invalid load status for cancel: ' || ld.loadstatus;
  return;
end if;
*/

if ld.qtyrcvd != 0 then
  out_msg := 'Receipt activity has already been processed';
  return;
end if;

if ld.qtyship != 0 then
  out_msg := 'Shipment activity has already been processed';
  return;
end if;

select count(1)
  into ohcount
  from orderhdr
 where loadno = in_loadno
   and orderstatus != 'X';

if ohcount != 0 then
  out_msg := 'There are open orders are assigned to this load';
  return;
end if;
begin
   select nvl(use_yard,'N') into l_use_yard
      from facility
     where facility = in_facility;
exception when no_data_found then
   l_use_yard := 'N';
end;
if l_use_yard = 'Y' then
   update loads
      set loadstatus = 'X',
          trailer = null,
          lastuser = in_userid,
          lastupdate = sysdate
    where loadno = in_loadno;
else
   update loads
      set loadstatus = 'X',
          lastuser = in_userid,
          lastupdate = sysdate
    where loadno = in_loadno;
end if;

update loadstop
   set loadstopstatus = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

 update trailer
   set loadno = null,
       activity_type = 'DFL',
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and carrier = ld.carrier
   and loadno is not null;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldcl ' || substr(sqlerrm,1,80);
end cancel_load;

PROCEDURE min_load_status
(in_loadno in number
,in_facility varchar2
,in_min_status varchar2
,in_userid varchar2) is

strMsg varchar2(2000);
cursor curOrders is
  select min(orderstatus) as min_orderstatus,
         max(orderstatus) as max_orderstatus  -- /*+ index(ORDERHDR ORDERHDR_LOAD_IDX) */
    from orderhdr
   where loadno = in_loadno
     and fromfacility = in_facility
     and orderstatus != 'X';
oh curOrders%rowtype;
newstatus varchar2(1);

begin

newstatus := in_min_status;

open curOrders;
fetch curOrders into oh;
if curOrders%notfound then
  oh.min_orderstatus := '1';
  oh.max_orderstatus := '1';
end if;
close curOrders;

if oh.min_orderstatus = oh.max_orderstatus then
      newstatus := oh.max_orderstatus;
elsif oh.max_orderstatus = '4' or
      oh.max_orderstatus = '6' or
      oh.max_orderstatus = '8' then
         newstatus := oh.max_orderstatus - 1;
else
      newstatus := oh.max_orderstatus;
end if;

update loads
   set loadstatus = newstatus,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstatus <> newstatus;

end;

PROCEDURE min_loadstop_status
(in_loadno in number
,in_stopno in number
,in_facility in varchar2
,in_min_status varchar2
,in_userid varchar2) is

strMsg varchar2(2000);

cursor curOrders is
  select min(orderstatus) as min_orderstatus,
          max(orderstatus) as max_orderstatus  --/*+ index(ORDERHDR ORDERHDR_LOAD_IDX) */
    from orderhdr
   where loadno = in_loadno
     and stopno = in_stopno
     and fromfacility = in_facility;
oh curOrders%rowtype;
newstatus varchar2(1);

begin

newstatus := in_min_status;

open curOrders;
fetch curOrders into oh;
if curOrders%notfound then
  oh.min_orderstatus := '1';
  oh.max_orderstatus := '1';
end if;
close curOrders;

if in_min_status <= '3' then -- partial release
  if oh.min_orderstatus > '3' and
     oh.max_orderstatus < '5' then -- min. order released
     newstatus := '4';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.max_orderstatus < '3' then
    newstatus := oh.max_orderstatus;
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5') and
        oh.max_orderstatus in ('5','6') then
    newstatus := '5';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('6') and oh.max_orderstatus in ('6') then
    newstatus := '6';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5','6','7') and
        oh.max_orderstatus in ('7','8') then
    newstatus := '7';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('8') and
        oh.max_orderstatus in ('8') then
    newstatus := '8';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
    return;
  end if;
end if;

if in_min_status = '5' then -- picking
  if oh.min_orderstatus > '3' and
     oh.max_orderstatus < '5' then -- min. order released
     newstatus := '4';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5') and
        oh.max_orderstatus in ('5','6') then
    newstatus := '5';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('6') and oh.max_orderstatus in ('6') then
    newstatus := '6';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5','6','7') and
        oh.max_orderstatus in ('7','8') then
    newstatus := '7';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('8') and
        oh.max_orderstatus in ('8') then
    newstatus := '8';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
    return;
  end if;
end if;

if in_min_status = '7' then -- loading
  if oh.min_orderstatus > '3' and
     oh.max_orderstatus < '5' then -- min. order released
     newstatus := '4';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5') and
        oh.max_orderstatus in ('5','6') then
    newstatus := '5';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('6') and oh.max_orderstatus in ('6') then
    newstatus := '6';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('1','2','3','4','5','6','7') and
        oh.max_orderstatus in ('7','8') then
    newstatus := '7';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
  elsif oh.min_orderstatus in ('8') and
        oh.max_orderstatus in ('8') then
    newstatus := '8';
     update loadstop
        set loadstopstatus = newstatus,
            lastuser = in_userid,
            lastupdate = sysdate
      where loadno = in_loadno and stopno = in_stopno;
    return;
  end if;
end if;

end;

PROCEDURE release_inbound_door
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         rcvddate
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus != 'E' then
  out_msg := 'Invalid load status for door release: ' || ld.loadstatus;
  return;
end if;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

if sql%rowcount = 1 then
  out_msg := 'OKAY';
else
  out_msg := 'No door was attached to this load';
end if;

exception when others then
  out_msg := 'ldcil ' || substr(sqlerrm,1,80);
end release_inbound_door;

PROCEDURE free_door
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         rcvddate
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus != 'E' then
  out_msg := 'Invalid load status for close: ' || ld.loadstatus;
  return;
end if;

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldfd ' || substr(sqlerrm,1,80);
end free_door;

PROCEDURE check_for_interface
(in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_regordtypeparam IN varchar2
,in_regfmtparam IN varchar2
,in_retordtypeparam IN varchar2
,in_retfmtparam IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         rcvddate
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor curOrdersByLoad is
  select orderid,
         shipid,
         custid,
         ordertype,
         shipto,
         shiptoname,
         orderstatus,
         carrier,
         nvl(fromfacility,tofacility) as facility
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

cursor curOrderHdr is
  select orderid,
         shipid,
         custid,
         ordertype,
         fromfacility,
         loadno,
         orderstatus,
         shipto,
         shiptoname,
         carrier,
         nvl(fromfacility,tofacility) as facility
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curSpecificConsigneeNotice(in_custid varchar2, in_ShipTo varchar2,
  in_ordertype varchar2) is
  select formatname
    from custconsigneenotice
   where custid = in_custid
     and ShipTo = in_ShipTo
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );

cursor curSpecificCarrierNotice(in_custid varchar2, in_carrier varchar2,
  in_ordertype varchar2) is
  select formatname
    from custcarriernotice
   where custid = in_custid
     and carrier = in_carrier
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );

cursor curAllConsigneeNotice(in_custid varchar2, in_ordertype varchar2) is
  select formatname
    from custconsigneenotice
   where custid = in_custid
     and ShipTo is null
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );

cursor curOneTimeConsigneeNotice(in_custid varchar2, in_ordertype varchar2) is
  select formatname
    from custconsigneenotice
   where custid = in_custid
     and ShipTo = '1TIME'
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );

cursor curCustomer(in_custid varchar2) is
  select PoMapFile,
         rcptnote_include_cancelled_yn,
         outAckBatchMap,
         shipnote_include_cancelled_yn,
         pallet_tracking_export_map,
         freight_bill_export_format,
         tms_actual_ship_format,
         shiptopriority,
         nvl(shipnote_include_cross_cust,'N') shipnote_include_cross_cust,
         nvl(shipping_acknowledgment_status, 'S') shipping_acknowledgment_status,
         nvl(rcptnote_include_cross_cust_yn,'N') rcptnote_include_cross_cust_yn
    from customer c, customer_aux ca
   where c.custid = in_custid
     and c.custid = ca.custid(+);
cu curCustomer%rowtype;

cursor curFormatInfo(in_formatid varchar2) is
  select sip_format_yn
    from impexp_definitions
   where upper(name) = upper(in_formatid);
fi curFormatInfo%rowtype;

cursor curSipOrdersByLoad is
  select distinct
         custid
    from orderhdr
   where loadno = in_loadno
     and orderstatus = '9';

cursor curSipConsigneesByLoad is
  select distinct
         custid,
         shipto,
         shiptoname,
         orderid,
         shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus = '9';

cursor curCustConsignee(in_custid varchar2, in_shipto varchar2) is
  select *
    from custconsignee
   where custid = in_custid
     and consignee = in_shipto;
cc curCustConsignee%rowtype;

cursor curGet856Format is
  select descr
    from sip_parameters
   where code = '856FMT';
f8 curGet856Format%rowtype;

cursor curMasterCustomer(in_tradingpartner varchar2) is
  select custid
    from custtradingpartner
   where tradingpartner = in_tradingpartner
     union
  select custid
    from custtradingpartner
   where custid = in_tradingpartner;
mc curMasterCustomer%rowtype;

cursor curMasterCount(in_custid varchar2) is
  select count(1) as count
    from custtradingpartner
   where custid = in_custid;
mcnt curMasterCount%rowtype;

cursor curLoadCusts is
  select distinct custid,fromfacility
    from orderhdr
   where loadno = in_loadno
     and ordertype in ('O','V','T','U')
     and fromfacility || '' = in_facility;

cursor curOrderCust is
  select custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;

cntRows integer;
intErrorNo integer;
cmdSql varchar2(500);

type exportrequest_rcd is record (
  custid    orderhdr.custid%type,
  shipto    orderhdr.shipto%type,
  format    customer.outconfirmbatchmap%type
);

type exportrequest_tbl is table of exportrequest_rcd
     index by binary_integer;

expreqs exportrequest_tbl;
expix integer;
exp licenseplatestatus%rowtype;
expdup boolean;
strMsg varchar2(255);
strFilePath varchar2(255);
strShipTo varchar2(10);
expOrderId orderhdr.orderid%type;
expShipId orderhdr.shipid%type;
request856 boolean;
request945 boolean;
request810 boolean;
expsingleexpmultcons customer_aux.singleexpmultcons%type;
type master_rcd is record (
  custid   orderhdr.custid%type
);
type master_tbl is table of master_rcd
     index by binary_integer;
masters master_tbl;
masterx integer;
masterfound boolean;
strDebug char(1);

TYPE cur_type is REF CURSOR;
clo cur_type;


procedure add_ie_request
(in_custid varchar2
,in_facility varchar2
,in_map varchar2
,in_loadno number
,in_orderid number
,in_shipid number)
is
begin


if strDebug = 'Y' then
  zut.prt('Req for Cust: ' || in_custid || ' fac: ' || in_facility || ' map: ' || in_map || ' Load: ' ||
    in_loadno || ' order: ' || in_orderid || '-' || in_shipid);
end if;

if upper(rtrim(in_map)) = '(NONE)' then
  return;
end if;

if strDebug != 'Y' then
  ziem.impexp_request(
    'E', -- reqtype
    in_facility, -- facility
    in_custid, -- custid
    in_map, -- formatid
    null, -- importfilepath
    'NOW', -- when
    in_loadno, -- loadno
    in_orderid, -- orderid
    in_shipid, -- shipid
    in_userid, --userid
    null, -- tablename
    null,  --columnname
    null, --filtercolumnname
    null, -- company
    null, -- warehouse
    null, -- begindatestr
    null, -- enddatestr
    intErrorno,out_msg);
  if intErrorno != 0 then
    zms.log_msg('LoadClose', in_facility, '',
         'Request Export: ' || out_msg,
         'E', in_userid, strMsg);
  end if;
end if;

end;

procedure load_exportrequest_tbl(in_custid varchar2,
                                 in_shipto varchar2,
                                 in_formatname varchar2) is
begin

  if upper(rtrim(in_formatname)) = '(NONE)' then
    return;
  end if;

  expdup := False;
  for expix in 1..expreqs.count
  loop
    if expreqs(expix).custid = in_custid and
       nvl(expreqs(expix).shipto,'x') = nvl(in_shipto,'x') and
       expreqs(expix).format = in_formatname then
      expdup := True;
      exit;
    end if;
  end loop;
  if expdup = False then
    expix := expreqs.count + 1;
    expreqs(expix).custid := in_custid;
    expreqs(expix).shipto := in_shipto;
    expreqs(expix).format := in_formatname;
  end if;
exception when others then
  null;
end load_exportrequest_tbl;

procedure std_export_check(in_reg_or_return_order varchar2,
  in_custid varchar2, in_ordertypeparms varchar2, in_formatparm varchar2,
  in_ordertype varchar2, in_do_master_yn varchar2)
is

strOutOrderType varchar2(32);
strInOrderType varchar2(32);

begin

if strDebug = 'Y' then
  zut.prt('std check ' || in_reg_or_return_order || ' ' || in_custid || ' ' ||
    in_ordertypeparms || ' ' || in_formatparm || ' ' || in_ordertype || ' ' ||
    in_do_master_yn);
end if;

if in_do_master_yn != 'Y' then
  open curMasterCount(in_custid);
  fetch curMasterCount into mcnt;
  close curMasterCount;
  if mcnt.count > 0 then
    if strDebug = 'Y' then
      zut.prt('skipping master ' || in_custid);
    end if;
    return;
  end if;
end if;

if in_reg_or_return_order = 'REG' then
  strInOrderType := 'R';
  strOutOrderType := 'O';
else
  strInOrderType := 'Q';
  strOutOrderType := 'V';
end if;

exp.abbrev := null;
exp.descr := null;
zmi3.get_cust_parm_value(in_custid,in_ordertypeparms,exp.descr,exp.abbrev);
if rtrim(exp.abbrev) is not null then
  if strDebug = 'Y' then
    zut.prt('use parm tables');
  end if;
  if instr(exp.abbrev,in_ordertype) <> 0 then
    zmi3.get_cust_parm_value(in_custid,in_formatparm,exp.descr,exp.abbrev);
  else
    exp.abbrev := null;
    exp.descr := null;
  end if;
else
  exp.descr := null;
  if strDebug = 'Y' then
    zut.prt('use cust config for types ' || strInOrderType || ' ' ||
      strOutOrderType);
  end if;
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  if in_ordertype = strInOrderType then
    exp.descr := cu.pomapfile;
  elsif in_ordertype = strOutOrderType then
     if cu.shipping_acknowledgment_status in ('S','B') then
       exp.descr := cu.outackbatchmap;
     end if;
  elsif in_ordertype = 'U' then
    if cu.shipnote_include_cross_cust = 'Y' and
        in_reg_or_return_order = 'REG' then
    exp.descr := cu.outackbatchmap;
    end if;
    if cu.rcptnote_include_cross_cust_yn = 'Y' and
       in_reg_or_return_order = 'REG' then
         exp.descr := cu.pomapfile;
    end if;
  end if;
end if;

if rtrim(exp.descr) is not null then
  if strDebug = 'Y' then
    zut.prt('found format ' || exp.descr);
  end if;
  fi := null;
  open curFormatInfo(exp.descr);
  fetch curFormatInfo into fi;
  close curFormatInfo;
  if nvl(fi.sip_format_yn,'N') = 'Y' then --skip Sip-Related Exports
    if strDebug = 'Y' then
      zut.prt('  (SIP format skipped) ');
    end if;
    exp.descr := null;
  end if;
  load_exportrequest_tbl(in_custid,null,exp.descr);
else
  if strDebug = 'Y' then
    zut.prt('no format found');
  end if;
end if;

exception when others then
  exp.descr := null;
end std_export_check;

begin

expreqs.delete;
if upper(out_msg) = 'DEBUG' then
  strDebug := 'Y';
else
  strDebug := 'N';
end if;
out_msg := '';

if in_loadno != 0 then
  expOrderId := 0;
  expShipId := 0;
  open Cloads;
  fetch Cloads into ld;
  if Cloads%notfound then
    close Cloads;
    out_msg := 'Load not found: ' || in_loadno;
    return;
  end if;
  close Cloads;

  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;

  if ld.loadstatus not in ('R','9') then
    out_msg := 'Invalid load status for impexp check: ' || ld.loadstatus;
    return;
  end if;
else
  expOrderId := in_orderid;
  expShipId := in_shipid;
  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;
  if oh.orderid is null then
    out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
    return;
  end if;
  if oh.fromfacility <> in_facility then
    out_msg := 'Order not at your facility: ' || in_orderid || '-' || in_shipid;
    return;
  end if;
  cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;
  if oh.orderstatus not in ('R','9') then
    if oh.orderstatus = 'X' then
      if oh.ordertype in ('R','Q','C') and
         cu.pomapfile is not null and
         cu.rcptnote_include_cancelled_yn = 'Y' then
        goto continue_oh_validation;
      end if;
      if oh.ordertype in ('O','V') and
         cu.shipnote_include_cancelled_yn = 'Y' then
        goto continue_oh_validation;
      end if;
    end if;
    out_msg := 'Invalid Order status for Import/Export: ' ||
      in_orderid || '-' || in_shipid || ': ' ||oh.orderstatus;
    zms.log_msg('ImpExpChk', oh.facility, '',
         'Request Export: ' || out_msg,
         'I', in_userid, strMsg);
    out_msg := 'OKAY--' || out_msg;
    return;
  end if;
<< continue_oh_validation >>
  if oh.loadno != 0 then
    out_msg := 'Order assigned to load ' || oh.loadno || ': ' ||
      in_orderid || '-' || in_shipid;
    return;
  end if;
end if;

if in_loadno != 0 then
  masters.delete;
  for ohs in curOrdersByLoad
  loop
    if ohs.orderstatus = 'X' then
      cu := null;
      open curCustomer(ohs.custid);
      fetch curCustomer into cu;
      close curCustomer;
      if ohs.ordertype in ('R','Q','C') and
         cu.pomapfile is not null and
         cu.rcptnote_include_cancelled_yn = 'N' then
        goto continue_load;
      end if;
      if ohs.ordertype in ('O','V') and
         cu.outackbatchmap is not null and
         cu.shipnote_include_cancelled_yn = 'N' then
        goto continue_load;
      end if;
    end if;
    std_export_check('REG',ohs.custid,in_regordtypeparam,in_regfmtparam,ohs.ordertype,'N');
    std_export_check('RET',ohs.custid,in_retordtypeparam,in_retfmtparam,ohs.ordertype,'N');
    mc := null;
    if strDebug = 'Y' then
      zut.prt('open curMc');
    end if;
    open curMasterCustomer(ohs.custid);
    fetch curMasterCustomer into mc;
    close curMasterCustomer;
    if mc.custid is not null then
      masterfound := False;
      for masterx in 1..masters.count
      loop
        if masters(masterx).custid = mc.custid then
          if strDebug = 'Y' then
            zut.prt('master found: ' || mc.custid);
          end if;
          masterfound := True;
          exit;
        end if;
      end loop;
      if masterfound = False then
        masterx := masters.count + 1;
        masters(masterx).custid := mc.custid;
        std_export_check('REG',mc.custid,in_regordtypeparam,in_regfmtparam,ohs.ordertype,'Y');
        std_export_check('RET',mc.custid,in_retordtypeparam,in_retfmtparam,ohs.ordertype,'Y');
      end if;
    end if;
  << continue_load >>
    null;
  end loop;
else
  std_export_check('REG',oh.custid,in_regordtypeparam,in_regfmtparam,oh.ordertype,'N');
  std_export_check('RET',oh.custid,in_retordtypeparam,in_retfmtparam,oh.ordertype,'N');
  mc := null;
  open curMasterCustomer(oh.custid);
  fetch curMasterCustomer into mc;
  close curMasterCustomer;
  if mc.custid is not null then
    std_export_check('REG',mc.custid,in_regordtypeparam,in_regfmtparam,oh.ordertype,'Y');
    std_export_check('RET',mc.custid,in_retordtypeparam,in_retfmtparam,oh.ordertype,'Y');
  end if;
  end if;
-- check for notice by carrier
if in_loadno != 0 then
   for ohs in (select distinct custid, carrier, ordertype from orderhdr where loadno = in_loadno) loop
      for scn in curSpecificCarrierNotice(ohs.custid,ohs.carrier,ohs.ordertype)
      loop
        load_exportrequest_tbl(ohs.custid,null,scn.formatname);
        cntRows := cntRows + 1;
      end loop;
   end loop;
else
   for scn in curSpecificCarrierNotice(oh.custid,oh.carrier,oh.ordertype)
   loop
     load_exportrequest_tbl(oh.custid,null,scn.formatname);
     cntRows := cntRows + 1;
   end loop;
end if;

-- check for notice by consignee
if in_loadno != 0 then
  for ohs in curOrdersByLoad
  loop
    if ohs.shipto is null then
      for ocn in curOneTimeConsigneeNotice(ohs.custid,ohs.ordertype)
      loop
        load_exportrequest_tbl(ohs.custid,null,ocn.formatname);
      end loop;
    else
      cntRows := 0;
      for scn in curSpecificConsigneeNotice(ohs.custid,ohs.shipto,ohs.ordertype)
      loop
        load_exportrequest_tbl(ohs.custid,null,scn.formatname);
        cntRows := cntRows + 1;
      end loop;
      if cntRows = 0 then
        for acn in curAllConsigneeNOtice(ohs.custid,ohs.ordertype)
        loop
          load_exportrequest_tbl(ohs.custid,null,acn.formatname);
        end loop;
      end if;
    end if;
  end loop;
else
  if oh.shipto is null then
    for ocn in curOneTimeConsigneeNotice(oh.custid,oh.ordertype)
    loop
      load_exportrequest_tbl(oh.custid,null,ocn.formatname);
    end loop;
  else
    cntRows := 0;
    for scn in curSpecificConsigneeNotice(oh.custid,oh.shipto,oh.ordertype)
    loop
      load_exportrequest_tbl(oh.custid,null,scn.formatname);
      cntRows := cntRows + 1;
    end loop;
    if cntRows = 0 then
      for acn in curAllConsigneeNotice(oh.custid,oh.ordertype)
      loop
        load_exportrequest_tbl(oh.custid,null,acn.formatname);
      end loop;
    end if;
  end if;
end if;

-- check for SIP 945 Warehouse Ship Advice
if in_loadno != 0 then
  for ohs in curSipOrdersByLoad
  loop
    cu := null;
    open curCustomer(ohs.custid);
    fetch curCustomer into cu;
    close curCustomer;
    if cu.outackbatchmap is not null then
      fi := null;
      open curFormatInfo(cu.outackbatchmap);
      fetch curFormatInfo into fi;
      close curFormatInfo;
      if nvl(fi.sip_format_yn,'N') = 'Y' then
        load_exportrequest_tbl(ohs.custid,null,cu.outackbatchmap);
      end if;
    end if;
  end loop;
else
  if oh.orderstatus = '9' then
    cu := null;
    open curCustomer(oh.custid);
    fetch curCustomer into cu;
    close curCustomer;
    if cu.outackbatchmap is not null then
      fi := null;
      open curFormatInfo(cu.outackbatchmap);
      fetch curFormatInfo into fi;
      close curFormatInfo;
      if nvl(fi.sip_format_yn,'N') = 'Y' then
        load_exportrequest_tbl(oh.custid,null,cu.outackbatchmap);
      end if;
      end if;
    end if;
  end if;
if strDebug = 'Y' then
   zut.prt('sip 856 ');
end if;

-- check for SIP 856 Advance Ship Notice
if in_loadno != 0 then
  request856 := false;
  request945 := false;
  request810 := false;

  for ohs in curSipConsigneesByLoad
  loop
    if strDebug = 'Y' then
      zut.prt(ohs.custid || ' ' || ohs.orderid || ' ' || ohs.shipid);
    end if;
    begin
       select nvl(singleexpmultcons, 'N') into expsingleexpmultcons
          from customer_aux
          where custid = ohs.custid;
    exception when others then
       expsingleexpmultcons := 'N';
    end;
    if ohs.shipto is null or
       (ohs.shipto is not null and nvl(cu.shiptopriority,'N') = 'Y') then
      strShipTo := zimsip.sip_consignee_match(ohs.custid,ohs.orderid,ohs.shipid);
      if strShipto is null then
         strShipto := ohs.shipto;
      end if;
    else
      strShipto := ohs.shipto;
    end if;
    if strShipTo is not null then
      cc := null;
      open curCustConsignee(ohs.custid,strShipTo);
      fetch curCustConsignee into cc;
      close curCustConsignee;
      if cc.generate_ship_notice = 'Y' then
        if cc.export_format_856 = 'Use SIP Default' then
          f8 := null;
          open curGet856Format;
          fetch curGet856Format into f8;
          close curGet856Format;
          cc.export_format_856 := f8.descr;
        end if;
        if cc.export_format_856 is not null then
          if request856 = false then
          load_exportrequest_tbl(ohs.custid,strShipTo,cc.export_format_856);
             --request856 := true;
          end if;
        end if;
      end if;
      if cc.generate_945 = 'Y' then
         if request945 = false then
            load_exportrequest_tbl(ohs.custid,strShipTo,cc.export_format945);
            --request945 := true;
         end if;
      end if;
      if cc.generate_810 = 'Y' then
         if request810 = false then
            load_exportrequest_tbl(ohs.custid,strShipTo,cc.export_format810);
            --request810 := true;
        end if;
      end if;
    end if;
  end loop;
else
  if (oh.orderstatus = '9') or
     (oh.orderstatus = 'X' and 
      oh.ordertype in ('O','V') and
      cu.shipnote_include_cancelled_yn = 'Y') then
     if oh.shipto is null or
        (oh.shipto is not null and nvl(cu.shiptopriority,'N') = 'Y') then
      strShipTo := zimsip.sip_consignee_match(oh.custid,oh.orderid,oh.shipid);
      if strShipto is null then
         strShipto := oh.shipto;
      end if;
    else
      strShipto := oh.shipto;
    end if;
    if strShipTo is not null then
      cc := null;
      open curCustConsignee(oh.custid,strShipTo);
      fetch curCustConsignee into cc;
      close curCustConsignee;
      if cc.generate_ship_notice = 'Y' then
        if cc.export_format_856 = 'Use SIP Default' then
          f8 := null;
          open curGet856Format;
          fetch curGet856Format into f8;
          close curGet856Format;
          cc.export_format_856 := f8.descr;
        end if;
        if cc.export_format_856 is not null then
          load_exportrequest_tbl(oh.custid,strShipTo,cc.export_format_856);
        end if;
      end if;
      if cc.generate_945 = 'Y' then
        load_exportrequest_tbl(oh.custid,strShipTo,cc.export_format945);
        end if;
      if cc.generate_810 = 'Y' then
        load_exportrequest_tbl(oh.custid,strShipTo,cc.export_format810);
      end if;
    end if;
  end if;
end if;

-- request all configured exports
for expix in 1..expreqs.count
loop
  if expreqs(expix).shipto is null then
    strFilePath := null;
  else
    strFilePath := 'CONSIGNEE:' || expreqs(expix).shipto;
  end if;
  if strDebug = 'Y' then
    zut.prt('request ' || expreqs(expix).custid || ' ' ||
        expreqs(expix).format || ' ' || strFilePath || ' ' ||
        expOrderId || '-' || expShipId);
  end if;
  if strDebug != 'Y' then
    ziem.impexp_request(
      'E', -- reqtype
      null, -- facility
      expreqs(expix).custid, -- custid
      expreqs(expix).format, -- formatid
      strFilePath, -- importfilepath
      'NOW', -- when
      in_loadno, -- loadno
      expOrderId, -- orderid
      expShipId, -- shipid
      in_userid, --userid
      null, -- tablename
      null,  --columnname
      null, --filtercolumnname
      null, -- company
      null, -- warehouse
      null, -- begindatestr
      null, -- enddatestr
      intErrorno,out_msg);
    if intErrorno != 0 then
      zms.log_msg('LoadClose', in_facility, '',
           'Request Export: ' || out_msg,
           'E', in_userid, strMsg);
    end if;
  end if;
end loop;

--check for pallet tracking interface and customer export interfaces
if in_loadno != 0 then
  for lc in curLoadCusts
  loop
    if strDebug = 'Y' then
      zut.prt('Load additional shipment interface for cust ' || lc.custid);
    end if;
    cu := null;
    open curCustomer(lc.custid);
    fetch curCustomer into cu;
    close curCustomer;
    if cu.pallet_tracking_export_map is not null then
      add_ie_request(lc.custid,lc.fromfacility,
        cu.pallet_tracking_export_map,in_loadno,0,0);
    end if;
    if cu.freight_bill_export_format is not null then
      add_ie_request(lc.custid,lc.fromfacility,
        cu.freight_bill_export_format,in_loadno,0,0);
    end if;
    if cu.tms_actual_ship_format is not null then
      add_ie_request(lc.custid,lc.fromfacility,
        cu.tms_actual_ship_format,in_loadno,0,0);
    end if;
  end loop;
else
  if oh.ordertype in ('O','V') then
    if strDebug = 'Y' then
      zut.prt('Order additional shipment interface for cust ' || oh.custid);
    end if;
    if oh.loadno != 0 then
      if cu.pallet_tracking_export_map is not null then
        add_ie_request(oh.custid,oh.fromfacility,
          cu.pallet_tracking_export_map,0,oh.orderid,oh.shipid);
      end if;
    end if;
    if cu.tms_actual_ship_format is not null then
      add_ie_request(oh.custid,oh.fromfacility,
        cu.tms_actual_ship_format,0,oh.orderid,oh.shipid);
    end if;
    if cu.freight_bill_export_format is not null then
      add_ie_request(oh.custid,oh.fromfacility,
        cu.freight_bill_export_format,0,oh.orderid,oh.shipid);
    end if;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldcfi ' || substr(sqlerrm,1,80);
end check_for_interface;

PROCEDURE begin_inbound_load
(in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         billoflading,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

begin

out_msg := '';

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if io_loadno <> 0 then
  open Cloads;
  fetch Cloads into ld;
  if Cloads%notfound then
    close Cloads;
    out_msg := 'Load not found: ' || io_loadno;
    return;
  end if;
  close Cloads;
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus > '2' then
    out_msg := 'Invalid load status for assignment: ' || ld.loadstatus;
    return;
  end if;
--  if ( (oh.ordertype not in ('T')) and (ld.loadtype <> 'INC') ) or
--     ( (oh.ordertype in ('T'))     and (ld.loadtype <> 'INT') )
--  then
--    out_msg := 'Load/Order Type mismatch: ' ||
--      ld.loadtype || '/' || oh.ordertype;
--    return;
--  end if;
  if rtrim(in_carrier) is not null then
    ld.carrier := in_carrier;
  end if;
  if rtrim(in_trailer) is not null then
    ld.trailer := in_trailer;
  end if;
  if rtrim(in_seal) is not null then
    ld.seal := in_seal;
  end if;
  if rtrim(in_billoflading) is not null then
    ld.billoflading := in_billoflading;
  end if;
  if rtrim(in_stageloc) is not null then
    ld.stageloc := in_stageloc;
  end if;
  if rtrim(in_doorloc) is not null then
    ld.doorloc := in_doorloc;
  end if;
  update loads
     set loadstatus = '2',
         carrier = ld.carrier,
         trailer = ld.trailer,
         seal = ld.seal,
         billoflading = ld.billoflading,
         stageloc = ld.stageloc,
         doorloc = ld.doorloc,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno;
  update loadstop
     set loadstopstatus = '2',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno;
  if sql%rowcount = 0 then
    out_msg := 'Load/Stop not found: ' ||
      io_loadno || '/' || io_stopno;
    return;
  end if;
  update loadstopship
     set qtyorder = nvl(qtyorder,0),
         weightorder = nvl(weightorder,0),
         weight_entered_lbs = nvl(weight_entered_lbs,0),
         weight_entered_kgs = nvl(weight_entered_kgs,0),
         cubeorder = nvl(cubeorder,0),
         amtorder = nvl(amtorder,0),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and shipno = io_shipno;
  if sql%rowcount = 0 then
    out_msg := 'Load/Stop/Shipment not found: ' ||
      io_loadno || '/' || io_stopno || '/' || io_shipno;
    return;
  end if;
else
  get_next_loadno(io_loadno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
  io_stopno := 1;
  io_shipno := 1;
--  if oh.ordertype in ('R', 'Q') then
    ld.loadtype := 'INC';
--  else
--    ld.loadtype := 'INT';
--  end if;
  if ld.loadtype <> 'INC' then
     out_msg := 'Load type not inbound: ';
     return;
  end if;
  insert into loads
   (loadno,entrydate,loadstatus,
    trailer,seal,facility,
    doorloc,stageloc,carrier,
    statususer,statusupdate,
    lastuser,lastupdate,
    billoflading, loadtype)
  values
   (io_loadno,sysdate,'2',
    in_trailer,in_seal,in_facility,
    in_doorloc,in_stageloc,in_carrier,
    in_userid,sysdate,
    in_userid,sysdate,
    in_billoflading, ld.loadtype);
  insert into loadstop
   (loadno,stopno,entrydate,
    loadstopstatus,
    statususer,statusupdate,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,sysdate,
    '2',
    in_userid,sysdate,
    in_userid,sysdate);
  insert into loadstopship
   (loadno,stopno,shipno,
    entrydate,qtyorder,weightorder,
    cubeorder,amtorder,
    lastuser,lastupdate,
    weight_entered_lbs,weight_entered_kgs)
  values
   (io_loadno,io_stopno,io_shipno,
    sysdate,0,0,
    0,0,
    in_userid,sysdate,
    0,0);
  ld.carrier := in_carrier;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldbil ' || substr(sqlerrm,1,80);
end begin_inbound_load;

PROCEDURE begin_outbound_load
(in_carrier IN varchar2
,in_trailer IN varchar2
,in_seal IN varchar2
,in_billoflading IN varchar2
,in_stageloc IN varchar2
,in_doorloc IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,io_loadno IN OUT number
,io_stopno IN OUT number
,io_shipno IN OUT number
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         carrier,
         trailer,
         seal,
         billoflading,
         stageloc,
         doorloc,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = io_loadno;
ld Cloads%rowtype;

cursor curCarrier(in_carrier in varchar2) is
  select nvl(multiship,'N') as multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

newloadstatus varchar2(2);

begin

out_msg := '';

if rtrim(in_carrier) is not null then
  zva.validate_carrier(in_carrier,null,'A',out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if rtrim(in_doorloc) is not null then
  zva.validate_location(in_facility,in_doorloc,'DOR',null,
    'Door Location', out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
end if;

if io_loadno <> 0 then
  open Cloads;
  fetch Cloads into ld;
  if Cloads%notfound then
    close Cloads;
    out_msg := 'Load not found: ' || io_loadno;
    return;
  end if;
  close Cloads;
  if ld.facility != in_facility then
    out_msg := 'Load not at your facility: ' || ld.facility;
    return;
  end if;
  if ld.loadstatus > '8' then
    out_msg := 'Invalid load status for assignment: ' || ld.loadstatus;
    return;
  end if;
--  if ( (oh.ordertype not in ('T'))  and (ld.loadtype <> 'OUTC') ) or
--     ( (oh.ordertype in ('T'))      and (ld.loadtype <> 'OUTT') )
--  then
--    out_msg := 'Load/Order Type mismatch: ' ||
--      ld.loadtype || '/' || oh.ordertype;
--    return;
--  end if;
  if ld.loadtype <> 'OUTC' then
     out_msg := 'Load type not outbound: ';
     return;
  end if;
  if rtrim(in_carrier) is not null then
    ld.carrier := in_carrier;
  end if;
  if rtrim(in_trailer) is not null then
    ld.trailer := in_trailer;
  end if;
  if rtrim(in_seal) is not null then
    ld.seal := in_seal;
  end if;
  if rtrim(in_billoflading) is not null then
    ld.billoflading := in_billoflading;
  end if;
  if rtrim(in_stageloc) is not null then
    ld.stageloc := in_stageloc;
  end if;
  if rtrim(in_doorloc) is not null then
    ld.doorloc := in_doorloc;
  end if;
  update loads
     set carrier = ld.carrier,
         trailer = ld.trailer,
         seal = ld.seal,
         billoflading = ld.billoflading,
         stageloc = ld.stageloc,
         doorloc = ld.doorloc,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno;
  update loadstopship
     set qtyorder = nvl(qtyorder,0),
         weightorder = nvl(weightorder,0),
         weight_entered_lbs = nvl(weight_entered_lbs,0),
         weight_entered_kgs = nvl(weight_entered_kgs,0),
         cubeorder = nvl(cubeorder,0),
         amtorder = nvl(amtorder,0),
         qtyship = nvl(qtyship,0),
         weightship = nvl(weightship,0),
         weightship_kgs = nvl(weightship_kgs,0),
         cubeship = nvl(cubeship,0),
         amtship = nvl(amtship,0),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = io_loadno
     and stopno = io_stopno
     and shipno = io_shipno;
  if sql%rowcount = 0 then
    out_msg := 'Load/Stop/Shipment not found: ' ||
      io_loadno || '/' || io_stopno || '/' || io_shipno;
    return;
  end if;
else
  get_next_loadno(io_loadno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    return;
  end if;
  io_stopno := 1;
  io_shipno := 1;
--  if oh.ordertype not in ('T') then
    ld.loadtype := 'OUTC';
--  else
--    ld.loadtype := 'OUTT';
--  end if;
  insert into loads
   (loadno,entrydate,loadstatus,
    trailer,seal,facility,
    doorloc,stageloc,carrier,
    statususer,statusupdate,
    lastuser,lastupdate,
    billoflading, loadtype)
  values
   (io_loadno,sysdate,'2',
    in_trailer,in_seal,in_facility,
    in_doorloc,in_stageloc,in_carrier,
    in_userid,sysdate,
    in_userid,sysdate,
    in_billoflading, ld.loadtype);
  insert into loadstop
   (loadno,stopno,entrydate,
    loadstopstatus,
    statususer,statusupdate,
    lastuser,lastupdate)
  values
   (io_loadno,io_stopno,sysdate,
    '2',
    in_userid,sysdate,
    in_userid,sysdate);
  insert into loadstopship
   (loadno,stopno,shipno,
    entrydate,
    qtyorder,weightorder,
    cubeorder,amtorder,
    qtyship,weightship,
    cubeship,amtship,
    lastuser,lastupdate,
    weight_entered_lbs,weight_entered_kgs,
    weightship_kgs)
  values
   (io_loadno,io_stopno,io_shipno,
    sysdate,
    0,0,
    0,0,
    0,0,
    0,0,
    in_userid,sysdate,
    0,0,
    0);
 ld.carrier := in_carrier;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldbol ' || substr(sqlerrm,1,80);
end begin_outbound_load;

FUNCTION loadstopstatus_abbrev
(in_loadstopstatus IN varchar2
) return varchar2 is

out_abbrev loadstatus.abbrev%type;

begin

out_abbrev := null;

select abbrev
  into out_abbrev
  from loadstatus
 where code = in_loadstopstatus;

return out_abbrev;

exception when others then
  return in_loadstopstatus;
end loadstopstatus_abbrev;

FUNCTION loadstatus_abbrev
(in_loadstatus IN varchar2
) return varchar2 is

out_abbrev loadstatus.abbrev%type;

begin

out_abbrev := null;

select abbrev
  into out_abbrev
  from loadstatus
 where code = in_loadstatus;

return out_abbrev;

exception when others then
  return in_loadstatus;
end loadstatus_abbrev;

PROCEDURE check_for_vics
(in_loadno IN number
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor curCustVicsBol(in_custid varchar2, in_shipto varchar2, in_ordertype varchar2) is
  select rowid,custid,shipto,ordertype,reportname
    from custvicsbol
   where custid = in_custid
     and nvl(shipto,'x') = nvl(in_shipto,'x')
     and ( (ordertype = in_ordertype) or
           (ordertype = 'A') );
cvb curCustVicsBol%rowtype;
out_errorno integer;

begin

for oh in (select distinct custid,shipto,ordertype,
                  loadno,stopno,shipno,orderid,shipid
             from orderhdr
            where loadno = in_loadno
            order by loadno,stopno,shipno,orderid,shipid)
loop
  cvb := null;
  open curCustVicsBol(oh.custid,oh.shipto,oh.ordertype);
  fetch curCustVicsBol into cvb;
  close curCustVicsBol;
  if cvb.reportname is not null then
    exit;
  end if;
  open curCustVicsBol(oh.custid,null,oh.ordertype);
  fetch curCustVicsBol into cvb;
  close curCustVicsBol;
  if cvb.reportname is not null then
    exit;
  end if;
end loop;

if (cvb.reportname is not null) then
  if in_userid = '$CHECK$' then
    out_msg := 'VICS';
    return;
  else
    zvm.send_vics_bol_request(in_userid,in_loadno,0,0,'VICS','NONE',out_errorno,out_msg);
  end if;
end if;

<<return_okay_message>>

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end check_for_vics;

function is_split_facility_order
   (in_orderid in number,
    in_shipid  in number)
return boolean is
   cursor c_oh(p_orderid number, p_shipid number) is
      select nvl(C.multifac_picking, 'N') as multifac_picking
         from orderhdr O, customer C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and C.custid = O.custid;
   oh c_oh%rowtype;
   l_cnt pls_integer;
begin
   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

/* remove multifac picking option, since it doesn't work correctly
   if oh.multifac_picking = 'Y' then
      select count(1)
         into l_cnt
         from orderhdr
         where orderid = in_orderid;

      if l_cnt > 1 then
         return true;
      end if;
   end if; */
   return false;

exception when others then
  return false;
end is_split_facility_order;

PROCEDURE check_reopen_inbound
(in_loadno IN number
,out_msg  IN OUT varchar2
)
IS

CURSOR C_LD(in_loadno number)
IS
SELECT loadno, loadstatus,loadtype, statusupdate, lastupdate
  FROM loads
 WHERE loadno = in_loadno;

LD C_LD%rowtype;

CURSOR C_DBR
IS
    SELECT *
      FROM daily_billing_run
     WHERE effdate = (select max(effdate) from daily_billing_run);

DBR daily_billing_run%rowtype;

CURSOR C_INV(in_loadno number)
IS
    SELECT *
      FROM invoicehdr
     WHERE loadno = in_loadno;

INV invoicehdr%rowtype;


BEGIN
    out_msg := 'N';

/* verify load is in status for closing */
    LD := null;
    OPEN C_LD(in_loadno);
    FETCH C_LD into LD;
    CLOSE C_LD;

    if LD.loadno is null
    or LD.loadtype != 'INC'
    or LD.loadstatus != 'R' then
        return;
    end if;


    INV := null;
    OPEN C_INV(in_loadno);
    FETCH C_INV into INV;
    CLOSE C_INV;

    if INV.invoice is not null
    and INV.invstatus = '3' then
        return;
    end if;

    if INV.masterinvoice is not null then
        return;
    end if;


    DBR := null;
    OPEN C_DBR;
    FETCH C_DBR into DBR;
    CLOSE C_DBR;

    if DBR.effdate < LD.statusupdate then
        out_msg := 'Y';
    end if;


EXCEPTION WHEN OTHERS THEN
    out_msg := 'N';
    return;
END check_reopen_inbound;


PROCEDURE reopen_inbound
(in_loadno IN number
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
IS

CURSOR C_LD(in_loadno number)
IS
SELECT *
  FROM loads
 WHERE loadno = in_loadno;

LD loads%rowtype;

CURSOR C_DBR
IS
    SELECT *
      FROM daily_billing_run
     WHERE effdate = (select max(effdate) from daily_billing_run);

DBR daily_billing_run%rowtype;

CURSOR C_INV(in_loadno number)
IS
    SELECT *
      FROM invoicehdr
     WHERE loadno = in_loadno;

INV invoicehdr%rowtype;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cnt integer;

CURSOR C_SLP(in_facility varchar2, in_custid varchar2, in_item varchar2,
    in_lpid varchar2)
IS
    SELECT *
      FROM plate
     WHERE facility = in_facility
       AND custid = in_custid
       AND item = in_item
       AND fromlpid = in_lpid;

SLP plate%rowtype;

ordarrived boolean;
dtarrived date;
out_logmsg varchar2(1000);

BEGIN
    out_msg := 'OKAY';

/* verify load is in status for closing */
    LD := null;
    OPEN C_LD(in_loadno);
    FETCH C_LD into LD;
    CLOSE C_LD;

    if LD.loadno is null
    or LD.loadtype != 'INC'
    or LD.loadstatus != 'R' then
        out_msg := 'Invalid load for reopening';
        return;
    end if;

    INV := null;
    OPEN C_INV(in_loadno);
    FETCH C_INV into INV;
    CLOSE C_INV;

    if INV.invoice is not null
    and INV.invstatus = '3' then
        out_msg := 'Receipt invoice already posted';
        return;
    end if;

    if INV.masterinvoice is not null then
        out_msg := 'Receipt invoice in posting process';
        return;
    end if;

    cnt := 0;
    select count(1)
      into cnt
      from invoicedtl
     where invoice = INV.invoice
       and billstatus in ('2','3');

    if nvl(cnt,0) > 0 then
        out_msg := 'Receipt invoice has approved charges. Unapprove then try again.';
        return;
    end if;

    DBR := null;
    OPEN C_DBR;
    FETCH C_DBR into DBR;
    CLOSE C_DBR;

    if DBR.effdate >= LD.statusupdate then
        out_msg := 'Close Date before last billing run.';
        return;
    end if;

-- Everything appears to be OK so continue with the reopen
    if LD.carrier is null then
        out_msg := 'A Carrier entry is required';
        return;
    end if;

    if LD.doorloc is null then
        out_msg := 'A Door Location entry is required';
        return;
    end if;

    zva.validate_location(LD.facility,LD.doorloc,'DOR','FIE',
        'Door Location', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
        return;
    end if;

    if LD.stageloc is not null then
        zva.validate_location(LD.facility,LD.stageloc,'STG','FIE',
            'Stage Location', out_msg);
        if substr(out_msg,1,4) != 'OKAY' then
            return;
        end if;
    end if;

-- Check if all customers on load are paperbased
    cnt := 0;
    select count(1)
      into cnt
      from customer C, orderhdr O
     where O.loadno = in_loadno
       and C.custid = O.custid
       and nvl(C.paperbased,'N') = 'N';

    cnt := nvl(cnt,0);

    if cnt > 0 then
      open Cdoor(LD.facility,LD.doorloc);
      fetch Cdoor into dr;
      if Cdoor%notfound then
          close Cdoor;
          out_msg := 'Door not found: ' || ld.doorloc;
          return;
      end if;
      close Cdoor;


      if (dr.loadno != 0) and (dr.loadno != in_loadno) then
        out_msg := ld.doorloc || ' is being used by Load ' || dr.loadno;
        return;
      end if;
    end if;

-- Verify there are no cycle count adjustments for the loads pallets
    for oh in (select orderid, shipid from orderhdr
                where loadno = in_loadno) loop
      for lp in (select * from orderdtlrcpt
                  where orderid = oh.orderid and shipid = oh.shipid) loop

        for cc in (select rowid, cca.*
                     from cyclecountactivity cca
                    where lpid = lp.lpid
                      and adjustmenttype in ('ADJ','SUS')
                    order by whenoccurred desc) loop
            out_msg :=
                'Cycle count adjustments have been made for this loads plates';
            return;

        end loop;


      end loop;

    end loop;


    UPDATE orderhdr
       SET orderstatus = 'A',
           asnvariance = null,
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE loadno = in_loadno;

    UPDATE loadstop
       SET loadstopstatus = 'A',
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE loadno = in_loadno;

    UPDATE loads
       SET loadstatus = 'A',
           billdate = null,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno;


    if (dr.loadno = 0) then
        UPDATE door
           SET loadno = in_loadno,
               lastuser = in_userid,
               lastupdate = sysdate
         WHERE facility = LD.facility
           AND doorloc = LD.doorloc;
    end if;

    for oh in (select * from orderhdr where loadno = in_loadno)
    loop

        UPDATE orderdtl
           SET asnvariance = null
         WHERE orderid = oh.orderid
           AND shipid = oh.shipid;


        zoh.add_orderhistory(oh.orderid, oh.shipid,
            'Receipt Reopened',
            'Order reopened at '||ld.facility||'/'||ld.doorloc,
            in_userid, out_msg);


    end loop;

-- Remove the asofinventory by creating offsetting transactions
    zbill.receipt_load_remove_asof(in_loadno, ld.rcvddate,
        in_userid, out_msg);

-- Remove invoice information
   DELETE from invoicedtl
    WHERE invoice = INV.invoice
      AND statusrsn in (zbill.SR_RECEIPT, zbill.SR_MISC);

   DELETE invoicehdr
    WHERE invoice = INV.invoice;

   UPDATE invoicedtl
      SET billstatus = zbill.UNCHARGED,
          invoice = 0
    WHERE invoice = INV.invoice
      AND billstatus not in  (zbill.DELETED, zbill.BILLED);

-- For invadjactivity apply to orderdtlrcpt and remove
    for oh in (select orderid, shipid from orderhdr
                where loadno = in_loadno) loop
      for lp in (select * from orderdtlrcpt
                  where orderid = oh.orderid and shipid = oh.shipid) loop
        for ia in (select rowid, invadjactivity.*
                     from invadjactivity
                    where lpid = lp.lpid
                      and adjreason != 'CC'
                    order by whenoccurred desc) loop

        -- If old and new are not set just adjust quantities
            if ia.olditem is null and ia.newitem is null then
                ordarrived := false;
                for ohist in (select *
                                from orderhistory
                               where orderid = oh.orderid
                                 and shipid = oh.shipid
                               order by chgdate) loop
                    if (ohist.action in ('Order Arrived','Reopen Receipt')) then
                        dtarrived := ohist.chgdate;
                    elsif ((ohist.action = 'Order Closed') and
                             (ia.whenoccurred >= dtarrived) and
                             (ia.whenoccurred <= ohist.chgdate)) then
                        ordarrived := true;
                    end if;
                end loop;

                -- if the order was arrived when the inventory adjustment
                -- occurred, then update the orderdtlrcpt
                if (ordarrived) then
                    update orderdtlrcpt
                       set qtyrcvd = qtyrcvd - ia.adjqty,
                           qtyrcvdgood = decode(ia.invstatus, 'DM',
                                0, qtyrcvdgood - ia.adjqty),
                           qtyrcvddmgd = decode(ia.invstatus, 'DM',
                                qtyrcvddmgd - ia.adjqty, 0),
                           weight = weight - ia.adjweight
                     where lpid = ia.lpid;

                    zbill.add_asof_inventory(ld.facility, ia.custid, ia.item,
                        ia.lotnumber, ia.uom, ia.whenoccurred,
                        -ia.adjqty, -ia.adjweight, 'Reopen Rcpt', 'RR',
                        ia.inventoryclass, ia.invstatus,
                        oh.orderid, oh.shipid, ia.lpid, in_userid, out_msg);
               if out_msg != 'OKAY' then
                  zms.log_msg('Reopen-Rcpt1', ld.facility, ia.custid,
                     out_msg, 'E', in_userid, out_logmsg);
                  return;
               end if;
                end if;




            elsif ia.custid = ia.oldcustid
                and ia.item = ia.olditem then

                update orderdtlrcpt
                   set lotnumber = ia.lotnumber,
                       invstatus = ia.invstatus,
                       inventoryclass = ia.inventoryclass
                 where lpid = ia.lpid;

                zbill.add_asof_inventory(ld.facility, ia.custid, ia.item,
                    ia.lotnumber, ia.uom, ia.whenoccurred,
                    ia.adjqty, ia.adjweight, 'Reopen Rcpt', 'RR',
                    ia.inventoryclass, ia.invstatus,
                    oh.orderid, oh.shipid, ia.lpid, in_userid, out_msg);
            if out_msg != 'OKAY' then
               zms.log_msg('Reopen-Rcpt2', ld.facility, ia.custid,
                  out_msg, 'E', in_userid, out_logmsg);
               return;
            end if;
                zbill.add_asof_inventory(ld.facility, ia.custid, ia.item,
                    ia.oldlotnumber, ia.uom, ia.whenoccurred,
                    -ia.adjqty, -ia.adjweight, 'Reopen Rcpt', 'RR',
                    ia.oldinventoryclass, ia.oldinvstatus,
                    oh.orderid, oh.shipid, ia.lpid, in_userid, out_msg);
            if out_msg != 'OKAY' then
               zms.log_msg('Reopen-Rcpt3', ld.facility, ia.custid,
                  out_msg, 'E', in_userid, out_logmsg);
               return;
            end if;

                delete from invadjactivity
                  where rowid = ia.rowid;

            elsif ia.custid = ia.newcustid
                and ia.item = ia.newitem then
            -- Adjusment done from old entry
                delete from invadjactivity
                  where rowid = ia.rowid;
            else
        -- If item changed we can't do it
                out_msg := 'Inv Adj changed item. Can''t reopen.';
                return;
            end if;
        end loop;
      end loop;

      zoh.add_orderhistory(oh.orderid, oh.shipid,
         'Reopen Receipt',
         'Receipt Order reopened ',
         in_userid, out_msg);

    end loop;

-- For cyclecountactivity apply to orderdtlrcpt and remove?



EXCEPTION WHEN OTHERS THEN
    out_msg := sqlerrm;
    return;
END reopen_inbound;

PROCEDURE move_out_inbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_yard_facility varchar2
,in_yard_location varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyrcvd,0) as qtyrcvd
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select orderid, shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';


trl trailer%rowtype;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus != 'A' then
  out_msg := 'Invalid load status for move: ' || ld.loadstatus;
  return;
end if;

if ld.qtyrcvd > 0 then
   -- insert a new temporary location to hold any plates that are on the
   -- door location.
  begin
   insert into location
          (locid,
           facility,
           loctype,
           status,
           lastuser,
           lastupdate)
   values ('LOD' || in_loadno,
           in_facility,
           'LOD',
           'I',
           in_userid,
           sysdate);

   update plate
      set location = 'LOD' || in_loadno
    where loadno = in_loadno
      and location = ld.doorloc;

  exception when others then
    out_msg := 'ldmv newloc ' || substr(sqlerrm,1,80);
    return;
  end;

end if;

update loads
   set loadstatus = 'S',
       doorloc = 'LOD' || in_loadno,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

update loadstop
   set loadstopstatus = 'S',
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstopstatus = 'A';

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where facility = in_facility
   and loadno = in_loadno;


for oh in curOrderHdr
loop

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Moved',
     'Order Moved from '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);
  zlh.add_loadhistory(in_loadno,
     'Load Moved',
     'Load Moved from '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);

  if(out_msg <> 'OKAY') then
    exit;
  end if;

end loop;

if( out_msg <> 'OKAY') then
  return;
end if;

if rtrim(in_yard_facility) is not null then
  if rtrim(in_yard_location) is not null then
    trl.disposition := 'INY';
  else
    trl.disposition := 'DC';
  end if;
  update trailer
     set facility = in_yard_facility,
         location = in_yard_location,
         disposition = trl.disposition,
         activity_type = 'MVD',
         trailer_status = 'OK',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldmv ' || substr(sqlerrm,1,80);

end move_out_inbound_load;

PROCEDURE move_out_outbound_load
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,in_yard_facility varchar2
,in_yard_location varchar2
,out_msg  IN OUT varchar2
) is

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyship,0) as qtyship,
         trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select orderid, shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

trl trailer%rowtype;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus > '8' then
  out_msg := 'Invalid load status for move: ' || ld.loadstatus;
  return;
end if;

if ld.qtyship > 0 then
   -- insert a new temporary location to hold any plates that are on the
   -- door location.
  begin
   insert into location
          (locid,
           facility,
           loctype,
           status,
           lastuser,
           lastupdate)
   values ('LOD' || in_loadno,
           in_facility,
           'LOD',
           'I',
           in_userid,
           sysdate);

   update plate
      set location = 'LOD' || in_loadno
    where loadno = in_loadno
      and location = ld.doorloc;

   update shippingplate
      set location = 'LOD' || in_loadno
    where loadno = in_loadno
      and location = ld.doorloc;

  exception when others then
    out_msg := 'ldmv newloc ' || substr(sqlerrm,1,80);
    return;
  end;

end if;

update loads
   set loadstatus = 'S',
       doorloc = 'LOD' || in_loadno,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;

update loadstop
   set loadstopstatus = 'S',
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno;
--   and loadstopstatus = 'A';

update door
   set loadno = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where facility = in_facility
   and loadno = in_loadno;


for oh in curOrderHdr
loop

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Moved',
     'Order Moved from '||in_facility||'/'||ld.doorloc,
     in_userid, out_msg);

  if(out_msg <> 'OKAY') then
    exit;
  end if;

end loop;
if ld.trailer is not null then
  zlh.add_loadhistory(in_loadno,
     'Load Moved',
     'Load Moved from '||in_facility||'/'||ld.doorloc || ', Trailer ' || ld.trailer,
     in_userid, out_msg);
else
   zlh.add_loadhistory(in_loadno,
      'Load Moved',
      'Load Moved from '||in_facility||'/'||ld.doorloc,
      in_userid, out_msg);
end if;

if rtrim(in_yard_facility) is not null then
  if rtrim(in_yard_location) is not null then
    trl.disposition := 'INY';
  else
    trl.disposition := 'DC';
  end if;
  update trailer
     set facility = in_yard_facility,
         location = in_yard_location,
         disposition = trl.disposition,
         activity_type = 'MVD',
         trailer_status = 'OK',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno;
end if;

if( out_msg <> 'OKAY') then
  return;
end if;

if rtrim(in_yard_facility) is not null then
  if rtrim(in_yard_location) is not null then
    trl.disposition := 'INY';
  else
    trl.disposition := 'DC';
  end if;
  update trailer
     set facility = in_yard_facility,
         location = in_yard_location,
         disposition = trl.disposition,
         trailer_status = 'OK',
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldmv ' || substr(sqlerrm,1,80);
end move_out_outbound_load;

PROCEDURE move_load_in
(in_loadno IN number
,in_facility IN varchar2
,in_doorloc IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

row_cnt number;

cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyship,0) as qtyship,
         nvl(qtyrcvd,0) as qtyrcvd,
             trailer
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Cloadstop is
  select stopno,
         nvl(loadstopstatus,'?') as loadstopstatus,
         stageloc
    from loadstop
   where loadno = in_loadno
     and loadstopstatus != 'X'
   order by stopno;

cursor Cdoor(in_facility varchar2, in_doorloc varchar2) is
  select nvl(loadno,0) as loadno
    from door
   where facility = in_facility
     and doorloc = in_doorloc;
dr Cdoor%rowtype;

cursor curOrderHdr is
  select orderid, shipid
    from orderhdr
   where loadno = in_loadno
     and orderstatus != 'X';

min_order_status orderhdr.orderstatus%type;

begin

out_msg := '';

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.facility != in_facility then
  out_msg := 'Load not at your facility: ' || ld.facility;
  return;
end if;

if ld.loadstatus != 'S' then
  out_msg := 'Invalid load status for move: ' || ld.loadstatus;
  return;
end if;


open Cdoor(in_facility,in_doorloc);
fetch Cdoor into dr;
if Cdoor%notfound then
  close Cdoor;
  out_msg := 'Door not found: ' || in_doorloc;
  return;
end if;
close Cdoor;

if (dr.loadno != 0) and (dr.loadno != in_loadno) then
  out_msg := in_doorloc || ' is being used by Load ' || dr.loadno;
  return;
end if;

if (ld.qtyship > 0) or (ld.qtyrcvd > 0) then
   -- Move the plates to the door location specified. Then remove the loc.
  begin
   update plate
      set location = in_doorloc
    where loadno = in_loadno
      and location = 'LOD'||in_loadno;

  exception when no_data_found then
    null;
  when others then
    out_msg := 'ldmvin plates ' || substr(sqlerrm,1,80);
    return;
  end;
  begin
   update shippingplate
      set location = in_doorloc
    where loadno = in_loadno
      and location = 'LOD' || in_loadno;
  exception when no_data_found then
    null;
  when others then
    out_msg := 'ldmvin shippingplates ' || substr(sqlerrm,1,80);
    return;
  end;

  begin
     delete from location
      where locid = 'LOD'||in_loadno;

  exception when no_data_found then
    null;
  when others then
    out_msg := 'ldmvin loc ' || substr(sqlerrm,1,80);
    return;
  end;


end if;

if( substr(ld.loadtype,1,1) = 'I' ) then
   update loads
      set loadstatus = 'A',
     doorloc =  in_doorloc,
     lastuser = in_userid,
     lastupdate = sysdate
    where loadno = in_loadno;
   update loadstop
      set loadstopstatus = 'A',
     lastuser = in_userid,
     lastupdate = sysdate
    where loadno = in_loadno;
else
   begin
     select max(orderstatus)
       into min_order_status
        from orderhdr
      where loadno = in_loadno
        and orderstatus <= zrf.ORD_LOADED;
   exception when no_data_found then
       begin
        select min(orderstatus)
          into min_order_status
          from orderhdr
         where loadno = in_loadno;
        exception when no_data_found then
          min_order_status := null;
     end;
   end;

   update loads
      set loadstatus = nvl(min_order_status,'A'),
     doorloc =  in_doorloc,
     lastuser = in_userid,
     lastupdate = sysdate
    where loadno = in_loadno;
   update loadstop
      set loadstopstatus = nvl(min_order_status,'A'),
     lastuser = in_userid,
     lastupdate = sysdate
    where loadno = in_loadno;

end if;


update door
   set loadno = in_loadno,
       lastuser = in_userid,
       lastupdate = sysdate
 where facility = in_facility
   and doorloc = in_doorloc;


for oh in curOrderHdr
loop

  zoh.add_orderhistory(oh.orderid, oh.shipid,
     'Order Moved',
     'Order Moved to '||in_facility||'/'||in_doorloc,
     in_userid, out_msg);

  if(out_msg <> 'OKAY') then
    exit;
  end if;

end loop;
  zlh.add_loadhistory(in_loadno,
     'Load Moved',
     'Load Moved to '||in_facility||'/'||in_doorloc || ', Trailer: ' || ld.trailer,
     in_userid, out_msg);

if( out_msg <> 'OKAY') then
  return;
end if;

update trailer
   set disposition = 'DC',
       activity_type = 'MVD',
       location = in_doorloc,
       trailer_status = 'OK',
       lastuser = in_userid,
       lastupdate = sysdate
 where trailer_number = ld.trailer
   and facility = in_facility
   and carrier = ld.carrier
   and loadno = in_loadno;

out_msg := 'OKAY';

exception when others then
  out_msg := 'ldmvin ' || substr(sqlerrm,1,80);
end move_load_in;

procedure set_trailer_temps
(in_loadno IN number
,in_user IN varchar2
,in_nosetemp IN number
,in_middletemp IN number
,in_tailtemp IN number
,out_msg IN OUT varchar2
) is
begin
   out_msg := 'OKAY';

   for oh in (select OH.rowid from orderhdr OH, customer_aux CX
                  where OH.loadno = in_loadno
                    and CX.custid (+) = OH.custid
                    and nvl(CX.trackoutboundtemps,'N') = 'Y') loop
      update orderhdr
         set trailernosetemp = in_nosetemp,
             trailermiddletemp = in_middletemp,
             trailertailtemp = in_tailtemp,
             lastuser = in_user,
             lastupdate = sysdate
         where rowid = oh.rowid;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end set_trailer_temps;

PROCEDURE close_freight_load
(in_loadno IN number
,in_facility IN varchar2
,in_prono IN varchar2
,in_shipdate IN date
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is
cursor Cloads is
  select nvl(loadstatus,'?') as loadstatus,
         doorloc,
         stageloc,
         trailer,
         seal,
         carrier,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyship,0) as qtyship,
         trim(ldpassthruchar02) ldpassthruchar02,
         trim(ldpassthruchar40) ldpassthruchar40
    from loads
   where loadno = in_loadno;
ld Cloads%rowtype;

cursor Corders is
  select oh.orderid,
         oh.shipid,
         nvl(oh.wave,0) as wave,
         oh.orderstatus,
         oh.ordertype,
         oh.tofacility,
         nvl(oh.qtyorder,0) as qtyorder,
         nvl(oh.qtyship,0) as qtyship,
         oh.fromfacility,
         oh.custid,
         oh.xdockorderid,
         nvl(oh.shiptoname,oh.shipto) as shipto,
         decode(oh.shiptoname,null,cn.postalcode,oh.shiptopostalcode) as shiptopostalcode,
         oh.shipterms,
         trim(oh.hdrpassthruchar50) hdrpassthruchar50,
         trim(oh.hdrpassthruchar27) hdrpassthruchar27
    from orderhdr oh, consignee cn
   where loadno = in_loadno
     and fromfacility = in_facility
     and oh.shipto = cn.consignee (+);

cntRows integer;
minorderstatus orderhdr.orderstatus%type;
intErrorno integer;
dteStart date;
dteEnd date;
dteShipDate date;
strMsg varchar2(255);
l_finalclose char(1);
l_out varchar2(255);
l_var_wt_lower number;
bol_flag varchar2(1);
newbilloflading varchar2(40);
custUCC128 varchar2(7);
nbolseq number(8);
l_argcnt pls_integer;
l_schema varchar2(255);
l_obj varchar2(255);
l_auxdata varchar2(255);

begin

out_msg := 'OKAY';
dteStart := sysdate;

select count(1) into cntRows
  from orderhdr
 where loadno = in_loadno
   and orderstatus < '9'
   and ( ordertype = 'F');

if cntRows != 0 then
  zms.log_msg('LoadClose', in_facility, '',
    'Begin Load Close Freight' || in_loadno,
    'I', in_userid, strMsg);
end if;

open Cloads;
fetch Cloads into ld;
if Cloads%notfound then
  close Cloads;
  out_msg := 'Load not found: ' || in_loadno;
  return;
end if;
close Cloads;

if ld.loadstatus not in ('7','8') then
  out_msg := 'Invalid load status for close: ' || ld.loadstatus;
  return;
end if;

select count(1)
  into cntRows
  from orderhdr
 where loadno = in_loadno
   and fromfacility = in_facility
   and orderstatus = 'X';
if cntRows != 0 then
  out_msg := 'Cannot close--Cancelled order count on load: ' || cntRows;
  return;
end if;

select count(1)
  into cntRows
  from orderhdr
 where loadno = in_loadno
   and fromfacility = in_facility
   and priority = 'E';
if cntRows != 0 then
  out_msg := 'Cannot close--Exception priority order count on load: ' || cntRows;
  return;
end if;

begin
  if (in_shipdate is null)
  or (trunc(in_shipdate) = to_date('12/30/1899','mm/dd/yyyy')) then
    dteShipDate := sysdate;
  else
    dteShipDate := in_shipdate;
  end if;
exception when others then
  dteShipDate := null;
end;


if ld.loadtype = 'OUTT' then
  ld.loadtype := 'INT';
  ld.doorloc := null;
end if;

update loads
   set loadstatus = '9',
       stageloc = null,
       doorloc = null,
       loadtype = ld.loadtype,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstatus < '9';

update loadstop
   set loadstopstatus = '9',
       stageloc = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where loadno = in_loadno
   and loadstopstatus < '9';

  update orderhdr
     set orderstatus = '9',
         stageloc = null,
         prono = nvl(rtrim(in_prono),prono),
         lastuser = in_userid,
         lastupdate = sysdate,
         dateshipped = dteShipDate
   where loadno = in_loadno
     and orderstatus < '9';

for oh in Corders
loop
   zoh.add_orderhistory(oh.orderid, oh.shipid,
   'Order Closed',
   'Order Closed',
   in_userid, out_msg);

   zcus.ship_order(oh.orderid, oh.shipid);

     zprono.check_for_prono_assignment
     (oh.orderid
     ,oh.shipid
     ,'Load Close'
     ,intErrorno
     ,strMsg);
end loop;
  zlh.add_loadhistory(in_loadno,
     'Load Closed',
     'Load Closed',
     in_userid, out_msg);

  dteEnd := sysdate;
  zms.log_msg('LoadClose', in_facility, '',
    'End Load Close Freight ' || in_loadno || ' (' ||
    rtrim(substr(zlb.formatted_staffhrs((dteEnd - dteStart)*24),1,12)) || ')',
    'I', in_userid, strMsg);

exception when others then
  out_msg := 'close_freight_load ' || substr(sqlerrm,1,80);
end close_freight_load;

procedure request_pack_lists
(in_loadno number
,in_printer varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
)
is

l_order_count pls_integer;
l_errmsg varchar(255);
l_packlistrptfile customer.packlistrptfile%type;
l_packlist customer.packlist%type;

begin

out_msg := 'OKAY';
l_order_count := 0;

for oh in(select orderid, shipid, custid
           from orderhdr
          where loadno = in_loadno
            and orderstatus >= '4'
            and orderstatus != 'X')
loop

  zcu.pack_list_format(oh.orderid,oh.shipid,l_packlist,l_packlistrptfile);

  if l_packlistrptfile is not null then
    zmnq.send_shipping_msg(oh.orderid,
                          oh.shipid,
                          in_printer,
                          l_packlistrptfile,
                          null,
			  null,
                          l_errmsg);
    l_order_count := l_order_count + 1;
  end if;

end loop;

out_msg := 'OKAY--Pack List Request Count: ' || l_order_count;

exception when others then
  out_msg := 'wvtba ' || sqlerrm;
end request_pack_lists;

FUNCTION outbound_arrivaldate
(in_loadno IN number
) return date is

out_arrivaldate date;

begin

out_arrivaldate := null;

select max(hi.chgdate)
  into out_arrivaldate
  from orderhdr oh, orderhistory hi
 where oh.loadno = in_loadno
   and hi.orderid = oh.orderid
   and hi.shipid = oh.shipid
   and hi.action = 'Order Arrived';

return out_arrivaldate;

exception when others then
  return out_arrivaldate;
end outbound_arrivaldate;

procedure calc_door_rankings
(in_facility varchar2
,in_loadtype varchar2 -- 'inbound' or 'outbound'
,in_loadno number
,in_orderid number
,in_shipid number
,in_userid varchar2
,out_msg OUT varchar2
)
is
cursor curSectionSearch(in_facility varchar2, in_section varchar2) is
  select *
    from sectionsearch
   where facility = in_facility
     and sectionid = in_section;
ss curSectionSearch%rowtype;
l_oh_count pls_integer;
lp plate%rowtype;
l_errmsg varchar2(255);
l_put_facility varchar2(3);
l_location varchar2(10);
l_expdaterequired custitemview.expdaterequired%type;
l_enter_min_days_to_expire_yn customer_aux.enter_min_days_to_expire_yn%type;
findlpid plate.lpid%type;
findbaseqty plate.quantity%type;
findbaseuom tasks.pickuom%type;
findpickuom tasks.pickuom%type;
findpickqty plate.quantity%type;
findpicktotype custitem.picktotype%type;
findcartontype custitem.cartontype%type;
findpickfront char(1);
findpicktype waves.picktype%type;
findloctype location.loctype%type;
findwholeunitsonly char(1);
findlabeluom tasks.pickuom%type;
findorderedbyweight char(1);
findweight plate.weight%type;
uomtofind varchar2(12);
l_from_section location.section%type;
l_door_section location.section%type;
l_to_section   location.section%type;
l_searchstr sectionsearch.searchstr%type;
l_section_count number;
l_hops door_rankings.hops%type;
l_section_found boolean;
l_ranking door_rankings.ranking%type;
begin
out_msg := 'NONE';
delete from door_item_class_summary;
if in_loadno > 0 then
  insert into door_item_class_summary
    select oh.loadno, oh.custid, od.item,
           substr(od.inventoryclass,1,2),
           nvl(od.min_days_to_expiration,0),
           sum(nvl(od.qtyorder,0)),
           sum(nvl(od.weight_entered_lbs,0)),
           sum(nvl(od.weight_entered_kgs,0)),
           in_userid, sysdate
      from orderdtl od, orderhdr oh
     where oh.loadno = in_loadno
       and oh.orderid = od.orderid
       and oh.shipid = od.shipid
       and od.linestatus != 'X'
     group by oh.loadno,oh.custid,od.item,
              substr(od.inventoryclass,1,2),
              nvl(od.min_days_to_expiration,0);
end if;
if in_orderid != 0 then
  l_oh_count := 0;
  if in_loadno > 0 then
    select count(1)
      into l_oh_count
      from orderhdr
     where loadno = in_loadno
       and orderid = in_orderid
       and shipid = in_shipid;
    if l_oh_count <> 0 then
      goto continue_ranking;
    end if;
  end if;
  insert into door_item_class_summary
    select in_loadno, oh.custid, od.item,
           substr(od.inventoryclass,1,2),
           nvl(od.min_days_to_expiration,0),
           sum(nvl(od.qtyorder,0)),
           sum(nvl(od.weight_entered_lbs,0)),
           sum(nvl(od.weight_entered_kgs,0)),
           in_userid, sysdate
      from orderdtl od, orderhdr oh
     where oh.orderid = in_orderid
       and oh.shipid = in_shipid
       and oh.orderid = od.orderid
       and oh.shipid = od.shipid
       and od.linestatus != 'X'
     group by oh.loadno,oh.custid,od.item,
              substr(od.inventoryclass,1,2),
              nvl(od.min_days_to_expiration,0);
end if;
<< continue_ranking >>
for itm in (select custid, item, invclass, min_days_to_expiration,
                   sum(qtyorder) as qtyorder,
                   sum(weight_entered_lbs) as weight_entered_lbs,
                   sum(weight_entered_kgs) as weight_entered_kgs
              from door_item_class_summary
             where loadno = in_loadno
             group by custid, item, invclass, min_days_to_expiration
             order by 5 desc,
                      6 desc,
                      7 desc)
loop
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
             'Item is ' || itm.custid || ' ' || itm.item ||
             ' Class is ' || nvl(itm.invclass,'RG'),
             'T', in_userid);
  lp := null;
  lp.lpid := '~' || in_loadno || '~';
  lp.facility := in_facility;
  lp.custid := itm.custid;
  lp.type := 'PA';
  lp.location := 'PROBLEM';
  lp.item := itm.item;
  lp.itementered := itm.item;
  lp.status := 'A';
  lp.invstatus := 'AV';
  lp.inventoryclass := nvl(itm.invclass,'RG');
  lp.uomentered := nvl(zci.default_value('PALLETSUOM'),'PLT');
  lp.qtyentered := 1;
  begin
    select baseuom, expdaterequired
      into lp.unitofmeasure, l_expdaterequired
      from custitemview
     where custid = lp.custid
       and item = lp.item;
  exception when others then
    lp.unitofmeasure := 'EA';
  end;
  zbut.translate_uom(lp.custid,lp.item,1,lp.uomentered,
                     lp.unitofmeasure,lp.quantity,l_errmsg);
  if substr(l_errmsg,1,4) != 'OKAY' then
    zld.ld_debug_msg('DRDEBUG', in_facility, null,
                 'unable to convert uom ' ||
                 lp.custid || ' ' ||
                 lp.item || ' ' ||
                 lp.uomentered || ' ' ||
                 lp.unitofmeasure || ' ' ||
                 lp.inventoryclass || ' ' ||
                 lp.quantity || ' ' ||
                 l_errmsg,
                 'T', in_userid);
    lp.quantity := 1;
  end if;
  lp.weight := lp.qtyentered * zci.item_weight(lp.custid,lp.item,lp.uomentered);
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
               'lpid is ' ||
               lp.lpid  || ' ' ||
               lp.item || ' ' ||
               lp.uomentered || ' ' ||
               lp.qtyentered || ' ' ||
               lp.unitofmeasure || ' ' ||
               lp.quantity,
               'T', in_userid);
  if in_loadtype = 'inbound' then
    zld.insert_dummy_plate_row(lp, out_msg);
    if out_msg <> 'NONE' then
      return;
    end if;
    zput.putaway_lp('RESP', lp.lpid, lp.facility, lp.location, in_userid,
               'Y', null, l_errmsg, l_put_facility, l_location);
    zld.delete_dummy_plate_row(lp.lpid, out_msg);
    if (l_errmsg is not null) then
      l_location := 'PROBLEM';
      zld.ld_debug_msg('DRDEBUG', in_facility, null,
                   'ldcdr-putaway_lp ' || l_errmsg,
                   'T', in_userid);
    end if;
  else
    begin
      select enter_min_days_to_expire_yn
        into l_enter_min_days_to_expire_yn
        from customer_aux
       where custid = lp.custid;
    exception when others then
      l_enter_min_days_to_expire_yn := 'N';
    end;
    if itm.qtyorder = 0 then
      findorderedbyweight := 'Y';
      if itm.weight_entered_lbs = 0 then
        lp.quantity :=
          zwt.from_kgs_to_lbs(lp.custid,itm.weight_entered_kgs);
      else
        lp.quantity := itm.weight_entered_lbs;
      end if;
    else
      findorderedbyweight := 'N';
      lp.quantity := itm.qtyorder;
    end if;
    findloctype := 'STO';
    uomtofind := null;
    << find_again >>
    zwv.find_a_pick(lp.facility,
                    lp.custid,
                    null,
                    null,
                    lp.item,
                    lp.lotnumber,
                    lp.invstatus,
                    lp.inventoryclass,
                    lp.quantity,
                    uomtofind, --uom: leave blank to get standard allocation rule, 'IGNORE' to ignore rules
                    'N', -- NOT a replenish request
                    findloctype,
                    findorderedbyweight,
                    'E', --qtytype
                    0,   --wave
                    'N', --bat_zone_only
                    null, -- parallel_pick_zones
                    l_expdaterequired,
                    l_enter_min_days_to_expire_yn,
                    itm.min_days_to_expiration,
                    null,
                    null, -- passcount
                    findlpid,
                    findbaseuom,
                    findbaseqty,
                    findpickuom,
                    findpickqty,
                    findpickfront,
                    findpicktotype,
                    findcartontype,
                    findpicktype,
                    findwholeunitsonly,
                    findweight,
                    'N',
                    l_errmsg);
    if substr(l_errmsg,1,4) <> 'OKAY' then
      if uomtofind is null then
        zld.ld_debug_msg('DRDEBUG', in_facility, null,
                     'ldcdr-find_a_pick1 ' || l_errmsg,
                     'T', in_userid);
        uomtofind := 'IGNORE';
        goto find_again;
      end if;
      l_location := 'PROBLEM';
      zld.ld_debug_msg('DRDEBUG', in_facility, null,
                   'ldcdr-find_a_pick2 ' || l_errmsg,
                   'T', in_userid);
      exit;
    end if;
    zld.ld_debug_msg('DRDEBUG', in_facility, null,
             'findlpid is ' || findlpid,
             'T', in_userid);
    if findpickfront = 'Y' then
      l_location := findlpid;
    else
      begin
        select location
          into l_location
          from plate
         where lpid = findlpid;
      exception when others then
        l_location := 'PROBLEM';
      end;
    end if;
  end if;
  exit;
end loop;
delete from door_rankings;
begin
  select section
    into l_from_section
    from location
   where facility = in_facility
     and locid = l_location;
exception when others then
  l_from_section := '?';
end;
zld.ld_debug_msg('DRDEBUG', in_facility, null,
             'Location is ' || l_location ||
             ' Section is ' || l_from_section,
             'T', in_userid);
ss := null;
open curSectionSearch(in_facility, l_from_section);
fetch curSectionSearch into ss;
close curSectionSearch;
if ss.sectionid is null then
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
               'Unable to find sectionsearch ' ||
               in_facility || ' ' || nvl(l_from_section,null),
               'T', in_userid);
  ss.searchstr := '|??????????';
end if;
l_searchstr := substr(ss.searchstr,2,4000);
l_section_count := length(l_searchstr) - length(replace(l_searchstr, '|', ''));
for dr in (select doorloc
             from door
            where facility = in_facility
              and nvl(loadno,0) = 0)
loop
  begin
    select section
      into l_door_section
      from location
     where facility = in_facility
       and locid = dr.doorloc;
  exception when others then
    l_door_section := '?';
  end;
  l_hops := 0;
  if l_door_section = l_from_section then
    l_section_found := True;
  else
    l_section_found := False;
    for i in 1 .. l_section_count loop
      l_hops := l_hops + 1;
      select regexp_substr(l_searchstr,'[^|]+', 1, i)
        into l_to_section
        from dual;
      if l_door_section = rtrim(l_to_section) then
        l_section_found := True;
        exit;
      end if;
    end loop;
  end if;
  if l_section_found = False then
    l_hops := 9998;
  end if;
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
            'Door ' || dr.doorloc || ' Section ' ||
            l_door_section || ' hops ' || l_hops,
            'T', in_userid);
  insert into door_rankings
    (facility,loadno,doorloc,location,hops,ranking,
     lastuser,lastupdate)
    values
    (in_facility,in_loadno,dr.doorloc,l_location,l_hops,0,
     in_userid,sysdate);
end loop;
l_ranking := 0;
for hop in (select distinct hops
              from door_rankings
             where loadno = in_loadno
             order by hops)
loop
  l_ranking := l_ranking + 1;
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
             'Update rank ' || l_ranking || ' hops ' || hop.hops,
             'T', in_userid);
  update door_rankings
     set ranking = l_ranking
   where loadno = in_loadno
     and hops = hop.hops;
end loop;
out_msg := 'OKAY';
exception when others then
  out_msg := sqlerrm;
  zld.ld_debug_msg('DRDEBUG', in_facility, null,
                   'ldcdr ' || sqlerrm,
                   'T', in_userid);
end calc_door_rankings;
procedure insert_dummy_plate_row
(lp IN plate%rowtype
,out_msg IN OUT varchar2
) is pragma autonomous_transaction;
begin
insert into plate
  (lpid,facility,custid,type,location,item,itementered,
   status,invstatus,inventoryclass,uomentered,qtyentered,
   unitofmeasure,quantity,weight)
  values
  (lp.lpid,lp.facility,lp.custid,lp.type,lp.location,lp.item,lp.itementered,
   lp.status,lp.invstatus,lp.inventoryclass,lp.uomentered,
   lp.qtyentered,lp.unitofmeasure,lp.quantity,lp.weight);
commit;
exception when others then
  out_msg := sqlerrm;
end insert_dummy_plate_row;
procedure delete_dummy_plate_row
(in_lpid IN varchar2
,out_msg IN OUT varchar2
) is pragma autonomous_transaction;
begin
delete from plate
 where lpid = in_lpid;
commit;
exception when others then
  out_msg := sqlerrm;
end delete_dummy_plate_row;
PROCEDURE ld_debug_msg
   (in_author   in varchar2,
    in_facility in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    in_msgtype  in varchar2,
    in_userid   in varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   l_start pls_integer := 1;
   l_remain pls_integer := nvl(length(in_msgtext),0);
   l_len pls_integer;
begin
   if nvl(zci.default_value('LDDEBUG'),'N') = 'N' then
     return;
   end if;
   loop
      l_len := least(l_remain, 255);
      insert into appmsgs
         (created,
          author,
          facility,
          custid,
          msgtext,
          status,
          lastuser,
          lastupdate,
          msgtype)
      values
         (sysdate,
          upper(in_author),
          in_facility,
          in_custid,
          substr(in_msgtext, l_start, l_len),
          'UNRV',
          in_userid,
          sysdate,
          in_msgtype);
      exit when (l_len >= l_remain) or (l_remain <= 0);
      l_start := l_start+l_len;
      l_remain := l_remain-l_len;
   end loop;
   commit;
exception when others then
  rollback;
end ld_debug_msg;

PROCEDURE update_stop_shipment_stageloc
(in_facility IN varchar2
,in_loadno IN number
,in_wave IN number
,in_shipto IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_stopno IN OUT number
,in_shipno IN OUT number
,in_stageloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
)
is
cursor curLoads is
  select loadno,
         nvl(loadstatus,'?') as loadstatus,
         nvl(loadtype,'?') as loadtype,
         nvl(facility,'?') as facility
    from loads
   where loadno = in_loadno;
ld curLoads%rowtype;
l_msg varchar2(255);
l_cmd varchar2(4000);
cordid orderhdr.orderid%type;
TYPE cur_type is REF CURSOR;
l_cur_orders cur_type;
oh orderhdr%rowtype;
ls loadstop%rowtype := null;
l_count pls_integer;
l_max_orderstatus orderhdr.orderstatus%type := '1';
l_newloadstatus loads.loadstatus%type;
begin
out_errorno := 0;
out_msg := '';
if nvl(in_loadno, 0) = 0 then
  out_errorno := -1;
  out_msg := 'A load number is required';
  return;
end if;
ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;
if ld.loadno is null then
  out_errorno := -2;
  out_msg := 'Invalid Load number: ' || in_loadno;
  return;
end if;
if ld.facility != in_facility then
  out_errorno := -3;
  out_msg := 'Load ' || in_loadno || ' not at your facility(' || in_facility || '): ' || ld.facility;
  return;
end if;
if ld.loadtype not in ('OUTC','OUTT') then
  out_errorno := -4;
  out_msg := 'Load ' || in_loadno || ' is not an outbound load: ' || ld.loadtype;
  return;
end if;
if ld.loadstatus > '8' then
  out_errorno := -4;
  out_msg := 'Load ' || in_loadno || ' invalid status: ' || ld.loadstatus;
  return;
end if;
select count(1)
  into l_count
  from tasks
 where loadno = in_loadno
   and priority = '0';
if l_count != 0 then
  out_errorno := -41;
  out_msg := 'Load ' || in_loadno || ' has active tasks';
  return;
end if;
if rtrim(in_stageloc) is not null then
  zva.validate_location(in_facility,in_stageloc,'STG','FIE',
    'Stage Location', l_msg);
  if substr(l_msg,1,4) != 'OKAY' then
    out_errorno := -5;
    out_msg := l_msg;
    return;
  end if;
end if;
l_cmd := 'select orderid, shipid, stopno, shipno, orderstatus, ' ||
         'nvl(shipto_master,shipto) as shipto_master, ' ||
         'nvl(qtyorder,0) as qtyorder, ' ||
         'nvl(weightorder,0) as weightorder, ' ||
         'nvl(weight_entered_lbs,0) as weight_entered_lbs, ' ||
         'nvl(weight_entered_kgs,0) as weight_entered_kgs, ' ||
         'nvl(cubeorder,0) as cubeorder, ' ||
         'nvl(amtorder,0) as amtorder, ' ||
         'nvl(qtyship,0) as qtyship, ' ||
         'nvl(weightship,0) as weightship, ' ||
         'nvl(cubeship,0) as cubeship, ' ||
         'nvl(amtship,0) as amtship ' ||
         ' from orderhdr where loadno = ' || in_loadno;
if nvl(in_orderid,0) != 0 then
  l_cmd := l_cmd  || ' and orderid = ' || in_orderid || ' and shipid = ' || in_shipid;
elsif rtrim(in_shipto) is not null then
  l_cmd := l_cmd || ' and nvl(shipto_master,shipto) = ''' || in_shipto || '''';
elsif nvl(in_wave,0) != 0 then
  l_cmd := l_cmd || ' and wave = ' || in_wave;
end if;
open l_cur_orders for l_cmd;
loop
  fetch l_cur_orders into
    oh.orderid, oh.shipid, oh.stopno, oh.shipno, oh.orderstatus, oh.shipto_master,
    oh.qtyorder, oh.weightorder, oh.weight_entered_lbs, oh.weight_entered_kgs, oh.cubeorder,
    oh.amtorder, oh.qtyship, oh.weightship, oh.cubeship, oh.amtship;
  exit when l_cur_orders%notfound;
  if oh.stopno = in_stopno and
     oh.shipno = in_shipno then
    goto check_stageloc;
  end if;
  if ls.loadno is null then
    select count(1)
      into l_count
      from loadstop
     where loadno = in_loadno
       and stopno = in_stopno;
    if l_count = 0 then
      begin
        select *
          into ls
          from loadstop
         where loadno = in_loadno
           and stopno = oh.stopno;
      exception when others then
        null;
      end;
      insert into loadstop
        (loadno, stopno, entrydate, loadstopstatus,
         statususer, statusupdate, lastuser, lastupdate, facility,
         delpointtype, shipto)
        values
        (in_loadno, in_stopno, sysdate, '2',
         in_userid, sysdate, in_userid, sysdate, ls.facility,
         ls.delpointtype, ls.shipto);
    end if;
    select count(1)
      into l_count
      from loadstopship
     where loadno = in_loadno
       and stopno = in_stopno
       and shipno = in_shipno;
    if l_count = 0 then
      insert into loadstopship
        (loadno, stopno, shipno, entrydate,
         qtyorder, weightorder, cubeorder, amtorder,
         qtyship, weightship, cubeship, amtship,
         qtyrcvd, weightrcvd, cubercvd, amtrcvd,
         lastuser, lastupdate, weight_entered_lbs, weight_entered_kgs)
        values
        (in_loadno, in_stopno, in_shipno, sysdate,
         0, 0, 0, 0,
         0, 0, 0, 0,
         0, 0, 0, 0,
         in_userid, sysdate, 0, 0);
    end if;
    cordid := zcord.cons_orderid(oh.orderid, oh.shipid);
    if (cordid != 0) and
       (nvl(in_orderid,0) != 0 or rtrim(in_shipto) is not null) then
      out_errorno := -6;
      out_msg := 'Wave ' || cordid || ' is a consolidated order pick wave.'
                 || chr(13) ||
                 'Selection by Ship-To Master or Order ID is not allowed';
      close l_cur_orders;
      return;
    end if;
    select count(1)
      into l_count
      from batchtasks
     where loadno = in_loadno;
    if (l_count != 0) and
       (nvl(in_orderid,0) != 0 or rtrim(in_shipto) is not null) then
      out_errorno := -7;
      out_msg := 'Load contains Batch Picks.'
                 || chr(13) ||
                 'Selection by Ship-To Master or Order ID is not allowed';
      close l_cur_orders;
      return;
    end if;
  end if;
  update batchtasks
     set stopno = in_stopno,
         shipno = in_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderid = in_orderid
     and shipid = in_shipid
     and (stopno != in_stopno or shipno != in_shipno);
  if (cordid != 0) then
    update batchtasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and orderid = cordid
       and shipid = 0
       and (stopno != in_stopno or shipno != in_shipno);
    update batchtasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and(orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and (stopno != in_stopno or shipno != in_shipno);
  end if;
  update subtasks
     set stopno = in_stopno,
         shipno = in_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderid = in_orderid
     and shipid = in_shipid
     and (stopno != in_stopno or shipno != in_shipno);
  if (cordid != 0) then
    update subtasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and orderid = cordid
       and shipid = 0
       and (stopno != in_stopno or shipno != in_shipno);
    update subtasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and(orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and (stopno != in_stopno or shipno != in_shipno);
  end if;
  update tasks
     set stopno = in_stopno,
         shipno = in_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderid = in_orderid
     and shipid = in_shipid
     and (stopno != in_stopno or shipno != in_shipno);
  if (cordid != 0) then
    update tasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and orderid = cordid
       and shipid = 0
       and (stopno != in_stopno or shipno != in_shipno);
    update tasks
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and(orderid, shipid) in
              (select orderid, shipid from orderhdr
                 where wave = oh.wave)
       and (stopno != in_stopno or shipno != in_shipno);
  end if;
  update shippingplate
     set stopno = in_stopno,
         shipno = in_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and orderid = oh.orderid
     and shipid = oh.shipid
     and (stopno != in_stopno or shipno != in_shipno);
  if (cordid != 0) then
    update shippingplate
       set stopno = in_stopno,
           shipno = in_shipno,
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = in_loadno
       and orderid = cordid
       and shipid = 0
       and (stopno != in_stopno or shipno != in_shipno);
  end if;
  if oh.orderstatus > l_max_orderstatus then
    l_max_orderstatus := oh.orderstatus;
  end if;
  update loadstopship
     set qtyorder = nvl(qtyorder,0) - oh.qtyorder,
         weightorder = nvl(weightorder,0) - oh.weightorder,
         weight_entered_lbs = nvl(weight_entered_lbs,0) - oh.weight_entered_lbs,
         weight_entered_kgs = nvl(weight_entered_kgs,0) - oh.weight_entered_kgs,
         cubeorder = nvl(cubeorder,0) - oh.cubeorder,
         amtorder = nvl(amtorder,0) - oh.amtorder,
         qtyship = nvl(qtyship,0) - oh.qtyship,
         weightship = nvl(weightship,0) - oh.weightship,
         weightship_kgs = nvl(weightship_kgs,0)
                        - nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0),
         cubeship = nvl(cubeship,0) - oh.cubeship,
         amtship = nvl(amtship,0) - oh.amtship,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and stopno = oh.stopno
     and shipno = oh.shipno;
  update loadstopship
     set qtyorder = nvl(qtyorder,0) + oh.qtyorder,
         weightorder = nvl(weightorder,0) + oh.weightorder,
         weight_entered_lbs = nvl(weight_entered_lbs,0) + oh.weight_entered_lbs,
         weight_entered_kgs = nvl(weight_entered_kgs,0) + oh.weight_entered_kgs,
         cubeorder = nvl(cubeorder,0) + oh.cubeorder,
         amtorder = nvl(amtorder,0) + oh.amtorder,
         qtyship = nvl(qtyship,0) + oh.qtyship,
         weightship = nvl(weightship,0) + oh.weightship,
         weightship_kgs = nvl(weightship_kgs,0)
                        + nvl(zwt.from_lbs_to_kgs(oh.custid,oh.weightship),0),
         cubeship = nvl(cubeship,0) + oh.cubeship,
         amtship = nvl(amtship,0) + oh.amtship,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and stopno = in_stopno
     and shipno = in_shipno;
  update orderhdr
     set stopno = in_stopno,
         shipno = in_shipno,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = oh.orderid
     and shipid = oh.shipid;
  zoh.add_orderhistory(oh.orderid, oh.shipid,
       'StopShipChg',
       'Stop/Ship from ' || oh.stopno || '/' || oh.shipno ||
       ' to ' || in_stopno || '/' || in_shipno || ' on Load ' || in_loadno,
       in_userid, l_msg);
<< check_stageloc >>
  if rtrim(in_stageloc) is not null then
    update orderhdr
       set stageloc = in_stageloc,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = oh.orderid
       and shipid = oh.shipid;
  end if;
end loop;
if l_cur_orders%isopen then
  close l_cur_orders;
end if;
if l_max_orderstatus > '3' then
  if l_max_orderstatus > '4' then
    l_newloadstatus := '5';
  else
    l_newloadstatus := '3';
  end if;
  min_loadstop_status(in_loadno,in_stopno,in_facility,l_newloadstatus,in_userid);
elsif l_max_orderstatus in ('1','2','3') then
  l_newloadstatus := '2';
  update loadstop
     set loadstopstatus = l_newloadstatus,
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = in_loadno
     and stopno = in_stopno
     and loadstopstatus > l_newloadstatus;
end if;
for lss in (select rowid
             from loadstopship
            where loadno = in_loadno
              and qtyorder = 0)
loop
  delete from loadstopship
   where rowid = lss.rowid;
end loop;
for ls in (select rowid
             from loadstop
            where loadno = in_loadno
              and qtyorder = 0)
loop
  delete from loadstop
   where rowid = ls.rowid;
end loop;
out_msg := 'OKAY';
exception when others then
  out_errorno := sqlcode;
  out_msg := 'ldusss ' || substr(sqlerrm,1,80);
  if l_cur_orders%isopen then
    close l_cur_orders;
  end if;
end update_stop_shipment_stageloc;
PROCEDURE receipt_carryover
(in_orderid IN number
,in_shipid IN number
,in_new_orderid IN OUT number
,in_new_shipid IN OUT number
,in_userid IN varchar2
,out_msg OUT varchar2
)
IS

CURSOR C_ORD(in_orderid number, in_shipid number)
IS
 SELECT *
   FROM orderhdr
  WHERE orderid = in_orderid
    AND shipid = in_shipid;
ORD C_ORD%rowtype;

cnt integer;
modeApprvd integer;
totEntered integer;
totRcvd integer;
totRoll integer;
currLineEntered integer;
currLineRcvd integer;
currLineRoll integer;

BEGIN
    out_msg := 'OKAY';

-- Verify order is correct
    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_msg := 'orderid-shipid <'||in_orderid||'-'||in_shipid||'> does not exist';
        return;
    end if;

    if ORD.ordertype not in ('R','C') then
        out_msg := 'orderid-shipid <'||in_orderid||'-'||in_shipid||'> is not a receipt or crossdock order';
        return;
    end if;

-- Verify still something left to receive
    select count(1)
      into cnt
     from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and qtyorder > nvl(qtyrcvd,0);

    if nvl(cnt,0) = 0 then
        return;
    end if;

-- Setup new orderid shipid of not provided by calling routine
    if in_new_orderid is null then
        in_new_orderid := in_orderid;
    end if;

    if in_new_shipid is null then
      begin
        select max(shipid) + 1
          into in_new_shipid
          from orderhdr
         where orderid = in_orderid;
      exception when others then
        in_new_shipid := in_shipid + 1;
      end;
    end if;

-- Clone Order Header
    zcl.clone_table_row('ORDERHDR',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        in_new_orderid||','||in_new_shipid||',null,null,null,null',
        'ORDERID,SHIPID,LOADNO,STOPNO,SHIPNO,WAVE',
        null,
        in_userid,
        out_msg);

    if out_msg != 'OKAY' then
        return;
    end if;

-- Clean up the orderhdr
    update  orderhdr
       set  orderstatus = '0',
            commitstatus = '0',
            loadno = null,
            stopno = null,
            shipno = null,
            qtyorder = 0,
            weightorder = 0,
            cubeorder = 0,
            amtorder = 0,
            qtycommit = null,
            weightcommit = null,
            cubecommit = null,
            amtcommit = null,
            qtyship = null,
            weightship = null,
            cubeship = null,
            amtship = null,
            qtytotcommit = null,
            weighttotcommit = null,
            cubetotcommit = null,
            amttotcommit = null,
            qtyrcvd = null,
            weightrcvd = null,
            cubercvd = null,
            amtrcvd = null,
            statusupdate = sysdate,
            lastupdate = sysdate,
            wave = null,
            qtypick = null,
            weightpick = null,
            cubepick = null,
            amtpick = null,
            staffhrs = null,
            qty2sort = null,
            weight2sort = null,
            cube2sort = null,
            amt2sort = null,
            qty2pack = null,
            weight2pack = null,
            cube2pack = null,
            amt2pack = null,
            qty2check = null,
            weight2check = null,
            cube2check = null,
            amt2check = null,
            confirmed = null,
            rejectcode = null,
            rejecttext = null,
            dateshipped = null,
            origorderid = null,
            origshipid = null,
            bulkretorderid = null,
            bulkretshipid = null,
            returntrackingno = null,
            packlistshipdate = null,
            edicancelpending = null,
            --backorderyn = 'N',
            tms_status = decode(nvl(ORD.tms_status,'X'),'X','X','1'),
            tms_status_update = sysdate,
            tms_shipment_id = null,
            tms_release_id = null
     where orderid = in_new_orderid
       and shipid = in_new_shipid;

-- For each orderdtl
    for cod in (select * from orderdtl
                 where orderid = in_orderid
                  and shipid = in_shipid
                  and nvl(qtyrcvd,0) < nvl(qtyorder,0))
    loop
        zcl.clone_orderdtl(in_orderid, in_shipid, cod.item, cod.lotnumber,
                in_new_orderid, in_new_shipid, cod.item, cod.lotnumber,
                null, in_userid, out_msg);

        if out_msg != 'OKAY' then
            return;
        end if;

        update  orderdtl
           set  linestatus = 'A',
                commitstatus = null,
                qtyorder = GREATEST(nvl(cod.qtyorder,0)
                                  - nvl(cod.qtyrcvd,0),0),
                weightorder = GREATEST(nvl(cod.weightorder,0)
                                  - nvl(cod.weightrcvd,0),0),
                cubeorder = GREATEST(nvl(cod.cubeorder,0)
                                  - nvl(cod.cubercvd,0),0),
                amtorder = GREATEST(nvl(cod.amtorder,0)
                                  - nvl(cod.amtrcvd,0),0),
                qtyentered = GREATEST(nvl(cod.qtyorder,0)
                                  - nvl(cod.qtyrcvd,0),0),
                uomentered = uom,
                qtycommit = null,
                weightcommit = null,
                cubecommit = null,
                amtcommit = null,
                qtyship = null,
                weightship = null,
                cubeship = null,
                amtship = null,
                qtytotcommit = null,
                weighttotcommit = null,
                cubetotcommit = null,
                amttotcommit = null,
                qtyrcvd = null,
                weightrcvd = null,
                cubercvd = null,
                amtrcvd = null,
                qtyrcvdgood = null,
                weightrcvdgood = null,
                cubercvdgood = null,
                amtrcvdgood = null,
                qtyrcvddmgd = null,
                weightrcvddmgd = null,
                cubercvddmgd = null,
                amtrcvddmgd = null,
                qtypick = null,
                weightpick = null,
                cubepick = null,
                amtpick = null,
                childorderid = null,
                childshipid = null,
                staffhrs = null,
                qty2sort = null,
                weight2sort = null,
                cube2sort = null,
                amt2sort = null,
                qty2pack = null,
                weight2pack = null,
                cube2pack = null,
                amt2pack = null,
                qty2check = null,
                weight2check = null,
                cube2check = null,
                amt2check = null,
                asnvariance = null
         where orderid = in_new_orderid
           and shipid = in_new_shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');

        zcl.clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
                ||' and ITEM = '''||cod.item||''''
                ||' and nvl(LOTNUMBER,''(none)'') = '''
                    ||nvl(cod.lotnumber,'(none)')||'''',
            in_new_orderid||','||in_new_shipid||','''||cod.item
                ||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
            null,
            in_userid,
            out_msg);

        -- Receive against earliest delivery date instead of lowest line.
        -- Assumption made here that the 'dtlpassthrudate01' holds the delivery date of the line.
        -- Furthermore, the 'approved qty' on a line must also be taken into account and given priority.

        totEntered := nvl(cod.qtyorder,0);
        totRcvd := nvl(cod.qtyrcvd,0);
        totRoll := GREATEST(0,totEntered - totRcvd );
        currLineEntered := 0;
        currLineRcvd := 0;
        currLineRoll :=0;

        -- check if created clones need to support qty approved feature.
        select count(1)
         into modeApprvd
         from orderdtlline
         where orderid = in_orderid
          and shipid = in_shipid
          and item = cod.item
          and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
          and nvl(qtyapproved,0) > 0;

        -- Clone the order detail lines and handle any qtyapproved feature handling.
        for ol in (select *
                        from orderdtlline
                       where orderid = in_orderid
                         and shipid = in_shipid
                         and item = cod.item
                         and nvl(lotnumber,'(none)') =
                             nvl(cod.lotnumber,'(none)')
                        order by qtyapproved desc nulls last, dtlpassthrudate01 desc, linenumber desc)
        loop
           -- make a clone of the order detail line.
           zcl.clone_table_row('ORDERDTLLINE',
                    'ORDERID = '|| in_orderid ||' and SHIPID = '||in_shipid
                        ||' and ITEM = '''||ol.item||''''
                        ||' and nvl(LOTNUMBER,''(none)'') = '''
                            ||nvl(ol.lotnumber,'(none)')||''''
                        ||' and LINENUMBER = '|| ol.linenumber,
                            in_new_orderid||','||in_new_shipid||','''||ol.item
                        ||''','''||ol.lotnumber||''','||ol.linenumber,
                    'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER',
                    null, in_userid, out_msg);

           if out_msg != 'OKAY' then
              return;
           end if;

            -- The qty approval feature can change the entered qty distribution across the detail lines.
            if ( modeApprvd > 0 ) then
              -- determine the portion of recveived quantity to attribute to this line. Do not allow
              -- approved quantity to exceed total received quantity.
              currLineRcvd := LEAST( totRcvd, nvl(ol.qtyapproved,0) );

              -- If the entered qty on this line is less than approved, this line needs to take more
              -- of the total and a later line(s) will have to give up the difference.
              currLineEntered := GREATEST ( nvl(ol.qty,0), currLineRcvd );
              -- If the currLineEntered for this line exceeds the amount of entered qty remaining
              -- we are in a situation where and earlier line has grabbed more than originally
              -- entered. Limit this line to the remainder.
              currLineEntered := LEAST ( currLineEntered, totEntered);

              -- calculate the qty to rollover for this line
              currLineRoll := GREATEST(0, currLineEntered - currLineRcvd);
              -- if all quantity that needs to be rolled has been put on previous lines
              -- then this line does not need to rollover any qty.
              currLineRoll := LEAST ( currLineRoll, totRoll );

              -- update the clone with the proper rolled over qty.
              update orderdtlline
               set qty = currLineRoll,
                 qtyentered = currLineRoll,
                 qtyapproved = null,
                 uomentered = cod.uom
               where orderid = in_new_orderid
               and shipid = in_new_shipid
               and item = ol.item
               and nvl(lotnumber,'(none)') = nvl(ol.lotnumber,'(none)')
               and linenumber = ol.linenumber;

              -- Adjust the total counters in preparation for the next pass.
              -- When one of the totals hits zero it stays at zero and will affect
              -- what is available to the next line.
              totEntered := GREATEST(0, totEntered - currLineEntered);
              totRcvd := GREATEST(0, totRcvd - currLineRcvd );
              totRoll := GREATEST(0, totRoll - currLineRoll );
           else
              update orderdtlline
              set qty = LEAST(ol.qty, totRoll),
                qtyentered = LEAST(ol.qty, totRoll),
                uomentered = cod.uom
              where orderid = in_new_orderid
              and shipid = in_new_shipid
              and item = ol.item
              and nvl(lotnumber,'(none)') = nvl(ol.lotnumber,'(none)')
              and linenumber = ol.linenumber;
              -- decrement receipt qty tracker.  Do not allow negative number.
              totRoll := GREATEST(0, totRoll - LEAST(ol.qty, totRoll));
           end if;
        end loop;

        --  Clone Order Detail with remaining receipt qty or zero
        --    For each Order Detail Line
        --      Clone orderdtline with remaining receipt qty for line
    end loop;

EXCEPTION WHEN OTHERS THEN
    out_msg := sqlerrm;
END receipt_carryover;

FUNCTION get_load_for_plate
  (in_lpid IN varchar2)
return number
as
  v_plate plate%rowtype;
  v_loadno number;
begin

  begin
    select * into v_plate
    from plate
    where lpid = in_lpid;
  exception
    when others then
      return null;
  end;

  if (v_plate.type = 'XP') then
    begin
      select loadno into v_loadno
      from shippingplate
      where lpid = v_plate.parentlpid;
    exception
      when others then
        return null;
    end;

    return v_loadno;
  end if;

  if (v_plate.status in ('P','L')) then
    begin
      select loadno into v_loadno
      from shippingplate
      where fromlpid = in_lpid and type = 'F' and nvl(quantity,0) = nvl(v_plate.quantity,0)
        and status not in ('U','SH');
    exception
      when others then
        return null;
    end;

    return v_loadno;
  end if;

  return v_plate.loadno;

exception
  when others then
    return null;
end get_load_for_plate;

FUNCTION specify_changeproc
(in_changeproc IN varchar2
) return varchar2 is
out_changeproc caselabels.changeproc%type;
pos pls_integer;

begin
/* if labels were generated using the _PLATE version, use the order level version
   to check all labels are correct instead of one plate's worth of labels */
pos := instr(in_changeProc, '_PLATE');
if pos > 0 then
   out_changeproc := substr(in_changeproc, 1, pos - 1);
else
   out_changeproc := in_changeproc;
end if;

return out_changeproc;
end specify_changeproc;

PROCEDURE check_labels
(in_loadno IN number
,in_no_label_orders IN varchar2
,out_regen_needed OUT varchar2
,out_msg  IN OUT varchar2
)
is
l_out varchar2(255);
l_argcnt pls_integer;
l_schema varchar2(255);
l_obj varchar2(255);
l_auxdata varchar2(255);
l_skiplblcheck varchar2(1);
l_no_labels_msg varchar2(2000);
cntRows pls_integer;
begin
   out_msg := null;
   out_regen_needed := 'N';
   begin
      select upper(nvl(defaultvalue, 'N')) into l_skiplblcheck
         from systemdefaults
         where defaultid = 'SKIPRESTAGEDCLOSELABELCHECK';
   exception
      when OTHERS then
         l_skiplblcheck := 'N';
   end;

   for lbl in (select distinct OH.orderid, OH.shipid, CS.changeproc
                  from orderhdr OH, caselabels CS, waves W
                  where OH.loadno = in_loadno
                    and CS.orderid = OH.orderid
                    and CS.shipid = OH.shipid
                    and CS.changeproc is not null
                    and (l_skiplblcheck = 'N' or nvl(OH.restaged_yn,'N') = 'N')
                    and OH.wave = W.wave
                    and nvl(W.consolidated,'N') != 'Y') loop
      lbl.changeproc := zld.specify_changeproc(lbl.changeproc);
      zlbl.parse_db_object(lbl.changeproc, l_schema, l_obj);
      select count(1) into l_argcnt
         from user_arguments
         where package_name = l_schema
           and object_name = l_obj;

      for slp in (select lpid from shippingplate
                     where orderid = lbl.orderid
                       and shipid = lbl.shipid
                       and status != 'U'
                       and parentlpid is null) loop

         if l_argcnt = 4 then
            execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                  || ''', ''Q'', ''C'', :OUT1); end;'
                  using out l_out;
         else
            l_auxdata := 'ORDER|' || lbl.orderid || '|' || lbl.shipid;
            execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                  || ''', ''Q'', ''C'', '''|| l_auxdata || ''', :OUT1); end;'
                  using out l_out;
         end if;

         if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
            out_regen_needed := 'Y';
            if out_msg is null then
               out_msg := 'Cannot close -- the following orders need labels regenerated: ';
            end if;
            if nvl(length(out_msg),0) < 200 then
               out_msg := out_msg || ' ' || lbl.orderid || '-' || lbl.shipid;
            elsif substr(out_msg, -3) != '...' then
               out_msg := out_msg || '...';
            end if;
         end if;
         exit;
      end loop;
   end loop;

   /* check for consolidated orders */
   for wav in (select distinct OH.wave
               from orderhdr OH, waves W
               where OH.loadno = in_loadno
                 and OH.wave = W.wave
                 and nvl(W.consolidated,'N') = 'Y') loop

      for lbl in (select distinct CS.changeproc
                  from orderhdr OH, caselabels CS
                  where OH.wave = wav.wave
                    and (l_skiplblcheck = 'N' or nvl(OH.restaged_yn,'N') = 'N')
                    and CS.orderid = OH.orderid
                    and CS.shipid = OH.shipid
                    and CS.changeproc is not null) loop
         lbl.changeproc := zld.specify_changeproc(lbl.changeproc);
         zlbl.parse_db_object(lbl.changeproc, l_schema, l_obj);
         select count(1) into l_argcnt
            from user_arguments
            where package_name = l_schema
              and object_name = l_obj;

         for slp in (select lpid from shippingplate
                     where orderid = wav.wave
                       and shipid = 0
                       and status != 'U'
                       and parentlpid is null) loop

            if l_argcnt = 4 then
               execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                     || ''', ''Q'', ''C'', :OUT1); end;'
                     using out l_out;
            else
               l_auxdata := 'ORDER|' || wav.wave || '|0';
               execute immediate 'begin ' || lbl.changeproc || '(''' || slp.lpid
                     || ''', ''Q'', ''C'', '''|| l_auxdata || ''', :OUT1); end;'
                     using out l_out;
            end if;

            if substr(nvl(l_out,'NoWay'),1,4) = 'OKAY' then
               out_regen_needed := 'Y';
               if out_msg is null then
                  out_msg := 'Cannot close -- the following consolidated orders need labels regenerated:';
               end if;
               if instr(out_msg, wav.wave || '-0') = 0 then
                  if nvl(length(out_msg),0) < 200 then
                     out_msg := out_msg || ' ' || wav.wave || '-0';
                  elsif substr(out_msg, -3) != '...' then
                     out_msg := out_msg || '...';
                  end if;
               end if;
            end if;
            exit;
         end loop;
      end loop;
   end loop;


   if nvl(in_no_label_orders, 'N') = 'Y' then
      l_no_labels_msg := null;
      for lbl in (select OH.orderid, OH.shipid
                     from orderhdr OH, customer_aux CA
                     where OH.loadno = in_loadno
                       and CA.custid = OH.custid
                       and OH.orderstatus not in ('X', '0', '1', '2', '3', '9')
                       and nvl(CA.check_no_label_orders, 'N') = 'Y') loop
         select count(1) into cntRows
            from caselabels
            where orderid = lbl.orderid
              and shipid = lbl.shipid;
         if cntRows = 0 then
            if l_no_labels_msg is null then
               l_no_labels_msg := ' WARNING the following order(s) have no labels: ' || lbl.orderid || '-' || lbl.shipid;
            else
               l_no_labels_msg := l_no_labels_msg || ', ' || lbl.orderid || '-' || lbl.shipid;
            end if;

         end if;
      end loop;
      if l_no_labels_msg is not null then
         out_msg := out_msg || l_no_labels_msg;
      end if;
   end if;
   if out_msg is null then
      out_msg := 'NONE';
   end if;
end check_labels;

PROCEDURE log_no_regen_close
(in_loadno IN number
,in_userid IN varchar2
,in_facility IN varchar2
,out_msg  IN OUT varchar2)
is
strMsg varchar2(255);
begin
   zms.log_autonomous_msg('SYNAPSE', in_facility, '',
             'lorc: ' || in_loadno || ' ' || in_userid || ' ' || in_facility,
             'D', in_userid, strMsg);

   out_msg := 'OKAY';
   for OH in  (select orderid, shipid from orderhdr where loadno = in_loadno) loop
      zoh.add_orderhistory(OH.orderid, OH.shipid,
         'Ld Closed w/o Regen',
         'Load closed despite one or more orders needing label regeneration.',
     in_userid, out_msg);
   end loop;
   zlh.add_loadhistory(in_loadno,
         'Ld Closed w/o Regen',
         'Load closed despite labels needing regeneration.',
     in_userid, out_msg);
   insert into userhistory
      (nameid, begtime, endtime, facility, custid,
       equipment, event, units, etc, orderid,
       shipid, location, lpid, item, uom,
       baseuom, baseunits,
       cube,
       weight)
   values
      (in_userid, sysdate, sysdate, in_facility, null,
       null, 'LNRG', 0, 'Load closed without label regeneration', 0,
       0, null, null, null, null,
       null, 0, 0, 0);

exception when others then
  out_msg := substr(sqlerrm,1,80);
end log_no_regen_close;

PROCEDURE close_inbound_upadj
(in_loadno IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2) 
is
cursor curInvStatus is
select p.rowid pRowid, 
       o.rowid oRowid,
       i.itmpassthruchar07 newInvStatus
  from plate p, custitem i, orderdtlrcpt o
 where p.custid = i.custid
   and p.item = i.item
   and p.lpid = o.lpid
   and p.type = 'PA'
   and i.itmpassthrunum01 is not null
   and i.itmpassthruchar06 is not null
   and i.itmpassthruchar07 is not null
   and i.itmpassthruchar06 = 'QT'
   and p.invstatus = 'QT'
   and trunc(p.manufacturedate) + i.itmpassthrunum01 <= nvl(trunc(p.creationdate), trunc(sysdate))
   and p.facility = in_facility
   and p.loadno = in_loadno;
type t_InvStatus is table of curInvStatus%rowtype;
l_InvStatus t_InvStatus;

dteStart date;
dteEnd date;

out_msgs varchar2(255);
cntRows integer;

begin
out_msgs := '';

dteStart := sysdate;
zms.log_msg('LoadClsUpAdj', in_facility, '',
  'Begin Load Close Inbound UpAdj ' || in_loadno,
  'I', in_userid, out_msgs);

update (select p.manufacturedate, 
               p.expirationdate, 
			   p.lastupdate, 
			   i.shelflife
          from plate p, custitem i
		 where p.custid = i.custid
		   and p.item = i.item
		   and p.type = 'PA'
		   and p.facility = in_facility
		   and p.loadno = in_loadno) v
   set v.expirationdate = v.manufacturedate + v.shelflife,
       v.lastupdate = sysdate
 where v.manufacturedate is not null 
   and v.expirationdate is null
   and v.shelflife is not null;

cntRows := sql%rowcount;
commit;

if cntRows > 0 then
  zms.log_msg('LoadClsUpAdj', in_facility, '',
    cntRows || ' Expiration Date updated for Load ' || in_loadno,
    'I', in_userid, out_msgs);
end if;
   
update (select p.manufacturedate, 
               p.expirationdate, 
			   p.lastupdate, 
			   i.shelflife
          from plate p, custitem i
		 where p.custid = i.custid
		   and p.item = i.item
		   and p.type = 'PA'
		   and p.facility = in_facility
		   and p.loadno = in_loadno) v
   set v.manufacturedate = v.expirationdate - v.shelflife,
       v.lastupdate = sysdate
 where v.manufacturedate is null 
   and v.expirationdate is not null
   and v.shelflife is not null;

cntRows := sql%rowcount;

if cntRows > 0 then
  zms.log_msg('LoadClsUpAdj', in_facility, '',
    cntRows || ' Manufacture Date updated for Load ' || in_loadno,
    'I', in_userid, out_msgs);
end if;

cntRows := 0;

open curInvStatus;
fetch curInvStatus
 bulk collect into l_InvStatus;
close curInvStatus;
 
cntRows := l_InvStatus.count;

if cntRows > 0 then  
  forall i in l_InvStatus.first .. l_InvStatus.last
    update plate 
       set invstatus = l_InvStatus(i).newInvStatus
     where rowid = l_InvStatus(i).pRowid;

  forall i in l_InvStatus.first .. l_InvStatus.last
    update orderdtlrcpt
       set invstatus = l_InvStatus(i).newInvStatus
     where rowid = l_InvStatus(i).oRowid;

  zms.log_msg('LoadClsUpAdj', in_facility, '',
    cntRows || ' InvStatus updated for Load ' || in_loadno,
    'I', in_userid, out_msgs);
end if;

dteEnd := sysdate;

zms.log_msg('LoadClsUpAdj', in_facility, '',
            'End Load Close Inbound UpAdj ' || in_loadno || ' (' ||
            rtrim(substr(zlb.formatted_staffhrs((dteEnd - dteStart)*24),1,12)) || ')',
            'I', in_userid, out_msgs);
zlh.add_loadhistory(in_loadno,
                    'Load Close Inbound UpAdj',
                    'Load Close Inbound UpAdj',
                    in_userid, out_msgs);

out_msg := 'OKAY';

exception when others then
  rollback;
  out_msg := 'Load Close Inbound UpAdj ' || substr(sqlerrm,1,80);
end close_inbound_upadj;

end zloadentry;
/
show error package body zloadentry;
exit;