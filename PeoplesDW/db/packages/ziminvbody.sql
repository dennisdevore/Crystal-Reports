create or replace package body alps.zimportprocinv as
--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';


-------------------------------------------------------------------------------
-- import_inventory_all import all fields directly into plate table
-------------------------------------------------------------------------------

procedure import_inventory_all
( in_lpid in varchar2
,in_item in varchar2
,in_custid in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_status in varchar2
,in_holdreason in varchar2
,in_unitofmeasure in varchar2
,in_quantity in number
,in_type in varchar2
,in_serialnumber in varchar2
,in_lotnumber in varchar2
,in_creationdate in date
,in_manufacturedate in date
,in_expirationdate in date
,in_expiryaction in varchar2
,in_lastcountdate in date
,in_po in varchar2
,in_recmethod in varchar2
,in_condition in varchar2
,in_lastoperator in varchar2
,in_lasttask in varchar2
,in_fifodate in date
,in_destlocation in varchar2
,in_destfacility in varchar2
,in_countryof in varchar2
,in_parentlpid in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_disposition in varchar2
,in_lastuser in varchar2
,in_lastupdate in date
,in_invstatus in varchar2
,in_qtyentered in number
,in_itementered in varchar2
,in_uomentered in varchar2
,in_inventoryclass in varchar2
,in_loadno in number
,in_stopno in number
,in_shipno in number
,in_orderid in number
,in_shipid in number
,in_weight in number
,in_adjreason in varchar2
,in_qtyrcvd in number
,in_controlnumber in varchar2
,in_qcdisposition in varchar2
,in_fromlpid in varchar2
,in_taskid in number
,in_dropseq in number
,in_fromshippinglpid in varchar2
,in_workorderseq in number
,in_workordersubseq in number
,in_qtytasked in number
,in_childfacility in varchar2
,in_childitem in varchar2
,in_parentfacility in varchar2
,in_parentitem in varchar2
,in_prevlocation in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

tmp_lpid varchar2(15);

begin



tmp_lpid :=  in_lpid;

if rtrim(in_location) is null then
  out_errorno := -2;
  out_msg := 'Location value is required';
  return;
end if;

insert into plate
    (lpid, item, custid, facility, location, status, holdreason,
     unitofmeasure, quantity, type, serialnumber, lotnumber, creationdate,
     manufacturedate, expirationdate, expiryaction, lastcountdate, po,
     recmethod, condition, lastoperator, lasttask, fifodate, destlocation,
     destfacility, countryof, parentlpid, useritem1, useritem2, useritem3,
     disposition, lastuser, lastupdate, invstatus, qtyentered, itementered,
     uomentered, inventoryclass, loadno, stopno, shipno, orderid, shipid,
     weight, adjreason, qtyrcvd, controlnumber, qcdisposition, fromlpid,
     taskid, dropseq, fromshippinglpid, workorderseq, workordersubseq,
     qtytasked, childfacility, childitem, parentfacility, parentitem,
     prevlocation)
    values
     (in_lpid, in_item, in_custid, in_facility , in_location, in_status,
      in_holdreason, in_unitofmeasure, in_quantity, in_type, in_serialnumber,
      in_lotnumber, in_creationdate, in_manufacturedate, in_expirationdate,
      in_expiryaction, in_lastcountdate, in_po, in_recmethod, in_condition,
      in_lastoperator, in_lasttask, in_fifodate, in_destlocation,
      in_destfacility, in_countryof, in_parentlpid, in_useritem1, in_useritem2,
      in_useritem3, in_disposition, in_lastuser, in_lastupdate, in_invstatus,
      in_qtyentered, in_itementered, in_uomentered, in_inventoryclass,
      in_loadno, in_stopno, in_shipno, in_orderid, in_shipid, in_weight,
      in_adjreason, in_qtyrcvd, in_controlnumber, in_qcdisposition,
      in_fromlpid, in_taskid, in_dropseq, in_fromshippinglpid, in_workorderseq,
      in_workordersubseq, in_qtytasked, in_childfacility, in_childitem,
      in_parentfacility, in_parentitem, in_prevlocation);

exception when others then
  out_msg := 'zimiia ' || sqlerrm || in_lpid;
  out_errorno := sqlcode;
end import_inventory_all;


-------------------------------------------------------------------------------
-- import_inv
-------------------------------------------------------------------------------
procedure import_inv
(in_lpid in varchar2
,in_item in varchar2
,in_custid in varchar2
,in_facility in varchar2
,in_location in varchar2
,in_unitofmeasure in varchar2
,in_quantity in number
,in_serialnumber in varchar2
,in_lotnumber in varchar2
,in_creationdate in varchar2
,in_manufacturedate in varchar2
,in_expirationdate in varchar2
,in_po in varchar2
,in_recmethod in varchar2
,in_condition in varchar2
,in_countryof in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_invstatus in varchar2
,in_inventoryclass in varchar2
,in_orderid in number
,in_shipid in number
,in_weight in number
,in_qtyrcvd in number
,in_masterlpid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

recseq integer;
oi integer;
si integer;
strItem custitem.item%type;
cntRows integer;
begin
   strItem := in_item;
   select count(1) into cntRows
      from custitem
      where custid = in_custid
        and item = in_item;
   if cntRows = 0 then
      begin
         select item into strItem
            from custitemalias
            where custid = in_custid
              and itemalias = in_item;
      exception when no_data_found then
         strItem := in_item;
      end;
   end if;

   select nvl(max(record_sequence),0) into recseq
      from import_plate
      where load_sequence = 0;
   recseq := recseq + 1;
   if in_orderid = 0 then
      oi := NULL;
   else
      oi := in_orderid;
   end if;
   if in_shipid = 0 then
      si := NULL;
   else
      si := in_shipid;
   end if;
   insert into import_plate
        (load_sequence, record_sequence, lpid, item, custid, facility, location,
         unitofmeasure, quantity, serialnumber, lotnumber, creationdate,
         manufacturedate, expirationdate, po, recmethod, condition,  countryof,
         useritem1, useritem2, useritem3, invstatus, inventoryclass,
         orderid, shipid, weight, qtyrcvd, masterlpid)
       values
        (0, recseq, in_lpid, strItem, in_custid, in_facility , in_location,
         in_unitofmeasure, in_quantity, in_serialnumber, in_lotnumber,in_creationdate,
         in_manufacturedate, in_expirationdate, in_po,in_recmethod, in_condition, in_countryof,
         in_useritem1, in_useritem2, in_useritem3, in_invstatus, in_inventoryclass,
         oi, si, in_weight, in_qtyrcvd, in_masterlpid);

exception when others then
  out_msg := 'ziminviip ' || sqlerrm || in_lpid || ' ' || in_item;
  out_errorno := sqlcode;
end import_inv;


-------------------------------------------------------------------------------
-- end_import_inv
-------------------------------------------------------------------------------
procedure end_import_inv
(in_update IN varchar2
,in_datefmt IN varchar2
,in_min_date IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) as

ip_max integer;
ipe_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;

cntCustid integer;
cntItem integer;
cntLotnumber integer;
cntInvstatus integer;
cntInventoryclass integer;
cntOrderid integer;
cntShipid integer;
cntLoadno integer;
cntStopno integer;
cntShipno integer;

strMsg appmsgs.msgtext%type;


cursor C_IP(in_seq integer)
return import_plate%rowtype
is
  select *
    from import_plate
   where load_sequence = in_seq
   order by record_sequence;

cip import_plate%rowtype;

cursor C_MIP(in_seq integer)
is
   select distinct masterlpid as masterlpid,
         (select count(distinct location) from import_plate where masterlpid = p.masterlpid) as loccount
   from import_plate p
   where masterlpid is not null;

--##############################################################################
-- err_msg
--##############################################################################
procedure err_msg
(ip in import_plate%rowtype
,error_msg in varchar2) is
begin
/* zut.prt(error_msg);

zut.prt(to_char(ip.load_sequence, '99') || ' ' || to_char(ip.record_sequence, '99') ||
        ' ' || ip.lpid || ' ' || ip.item || ' ' || ip.custid || ' ' || ip.facility ||
        ' ' || ip.location || ' ' ||  ip.unitofmeasure || ' ' ||
        to_char(ip.quantity, '9999') || ' ' || error_msg);
*/
insert into import_plate_error
  (load_sequence, record_sequence, lpid, item, custid,
  facility, location, unitofmeasure, quantity, comments)
 values
  (ip.load_sequence, ip.record_sequence, ip.lpid, ip.item, ip.custid,
   ip.facility, ip.location, ip.unitofmeasure, ip.quantity, error_msg);
end err_msg;
--##############################################################################
-- cip_validation
--##############################################################################
function cip_validation
(ip in import_plate%rowtype,
 datefmt varchar2)
return integer
is
out_err integer;
cntRows integer;
lt varchar2(3);
cdt date;
mdt date;
edt date;
xdt date;

sn varchar2(40);
ln varchar2(40);
u1 varchar(40);
u2 varchar(40);
u3 varchar(40);
cty varchar(3);


cdate varchar2(40);
date_err varchar2(20);
ruleid varchar2(20);
pstring varchar2(20);
lot varchar2(30);
serialno varchar2(30);
user1 varchar2(20);
user2 varchar2(20);
user3 varchar2(20);
mfgdate varchar2(20);
expdate varchar2(20);
country varchar2(20);


 CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
RETURN custitemview%rowtype
IS
 select *
   from custitemview I
  where I.custid = in_custid
    and I.item = in_item;

civ custitemview%rowtype;
begin
out_err := 0;
date_err := null;
-- validate lpid doesn't already exist
select count(1) into cntRows
   from plate
   where lpid = ip.lpid;

if cntRows > 0 then
   out_err := out_err + 1;
   err_msg(ip, 'LiP already exists: ' || ip.lpid);
end if;

select count(1) into cntRows
   from deletedplate
   where lpid = ip.lpid;

if cntRows > 0 then
   out_err := out_err + 1;
   err_msg(ip, 'LiP already exists in deletedplate table: ' || ip.lpid);
end if;

select count(1) into cntRows
   from import_plate
   where lpid = ip.lpid;

if cntRows > 1 then
   out_err := out_err + 1;
   err_msg(ip, 'LiP ID duplicated in import data : ' || ip.lpid);
end if;


-- validate facility
select count(1) into cntRows
  from facility
  where facility = ip.facility;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ip, 'Invalid Facility: ' || ip.facility);
end if;

-- validate location, get lt for pickfront check later
lt := null;
select count(1) into cntRows
   from location
   where facility = ip.facility and
         locid = ip.location;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ip, 'Invalid Location: ' || ip.location);
else
   select loctype into lt
      from location
      where facility = ip.facility and
            locid = ip.location;
end if;
-- if not null, recmethod mustbe in handling types table
if ip.recmethod is not null then
  select count(1) into cntRows
     from handlingtypes
     where code = ip.recmethod;
  if cntRows = 0 then
     out_err := out_err + 1;
     err_msg(ip, 'Invalid Receipt Method: ' || ip.recmethod);
  end if;
end if;
-- if not null, invstatus must be valid
if ip.invstatus is not null then
   select count(1) into cntRows
      from inventorystatus
      where code = ip.invstatus;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ip, 'Invalid Inventory Status: ' || ip.invstatus);
   end if;

end if;
-- if not null, inventoryclass must be valid
if ip.inventoryclass is not null then
   select count(1) into cntRows
     from inventoryclass
     where code = ip.inventoryclass;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(ip, 'Invalid Inventory Class: ' || ip.inventoryclass);
   end if;
end if;

-- if not null, condition validation
--    if invstatus  = 'DM', must be in damageditemresaons table
--    if plate is a customer return, must be in custreturnreasons table
if ip.condition is not null then
   if ip.invstatus = 'DM' then
      select count(1) into cntRows
         from damageditemreasons
         where code = ip.condition;
      if cntRows = 0 then
         out_err := out_err + 1;
         err_msg(ip, 'Invalid condition for damaged inventory: ' || ip.condition);
      end if;
   end if; -- if invstatus = 'DM'
   if ip.inventoryclass in ('SL', 'SC', 'UT') then
      select count(1) into cntRows
         from custreturnreasons
         where code = ip.condition;
      if cntRows = 0 then
         out_err := out_err + 1;
         err_msg(ip, 'Invalid condition for returned inventory: ' || ip.condition);
      end if;
   end if;
else
   if ip.invstatus = 'DM' then
      out_err := out_err + 1;
      err_msg(ip, 'Damaged inventory with no condition');
   else
      if ip.inventoryclass in ('SL', 'SC', 'UT') then
         out_err := out_err + 1;
         err_msg(ip, 'Returned inventory with no condition');
      end if;
   end if;
end if;
-- validate customer - if customer invalid return
select count(1) into cntRows
   from customer
   where custid = ip.custid;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(ip, 'Invalid Customer: ' || ip.custid);
   return out_err;
end if;

--validate item, if item is invalid return
civ := null;
open C_ITEM(ip.custid, ip.item);
fetch C_ITEM into civ;
close C_ITEM;
if civ.custid is null then
   out_err := out_err + 1;
   err_msg(ip, 'Invalid Item: ' || ip.item);
   return out_err;
end if;

--if loc is pick front, must be for item
if lt = 'PF' then
   select count(1) into cntRows
      from itempickfronts
      where custid = ip.custid and
            item = ip.item and
            facility = ip.facility and
            pickfront = ip.location;
   if cntRows = 0 then
        out_err := out_err + 1;
        err_msg(ip, 'Loction not pickfront for item ' ||ip.location || ' ' || ip.item);
   end if;
end if;

--uom must be valid for customer / item
if ip.unitofmeasure <> civ.baseuom then
   select count(1) into cntRows
      from custitemuom
      where custid = ip.custid and
            item = ip.item and
            touom = ip.unitofmeasure;
   if cntRows = 0 then
        out_err := out_err + 1;
        err_msg(ip, 'Invalid UOM for cust/item: ' || ip.unitofmeasure);
   end if;
end if;

--qty must be 1 if maxqty of 1 = 'Y'
if civ.maxqtyof1 = 'Y' then
   if ip.quantity <> 1 then
        out_err := out_err + 1;
        err_msg(ip, 'Single Quantity License Plate set to yes, quantity not 1: ' || ltrim(to_char(ip.quantity, '9999999999')));
   end if;
end if;

-- validate country if present
if ip.countryof is not null then

   select count(1) into cntRows
      from countrycodes
      where code = ip.countryof;
   if cntRows = 0 then
      err_msg(ip, 'Country of Origin invalid: ' || ip.countryof);
   end if;
end if;



-- orderid required if ai customer
-- shipid required if ai customer
-- validate customer - if customer invalid return
select count(1) into cntRows
   from customer
   where custid = ip.custid and
         paperbased = 'Y';
if cntRows > 0 then
   if ip.orderid is null then
        out_err := out_err + 1;
        err_msg(ip, 'Order ID is required for AI customers');
   end if;
   if ip.shipid is null then
        out_err := out_err + 1;
        err_msg(ip, 'Ship ID is required for AI customers');
   end if;
end if;
-- dates validation
if in_min_date is not null then
    xdt := to_date(in_min_date, datefmt);
else
    xdt := to_date('01/01/2000', 'mm/dd/yyyy');
end if;
-- creation date validation
if ip.creationdate is not null then
   date_err := ' creation date ';
   cDate := ip.creationdate;
   cdt := to_date(ip.creationdate, datefmt);
   if cdt < xdt then
       out_err := out_err + 1;
       err_msg(ip, 'Creation date < 1/1/2000: ' || to_char(cdt, 'mm/dd/yyyy'));
   end if;
   if cdt > sysdate then
      out_err := out_err + 1;
      err_msg(ip, 'Creation date > today: ' || to_char(cdt, 'mm/dd/yyyy'));
   end if;
end if;

-- manufacture date validation
date_err := ' creation date ';
cDate := ip.creationdate;

if ip.manufacturedate is not null then
   date_err := ' manufacture date ';
   cDate := ip.manufacturedate;
   mdt := to_date(ip.manufacturedate, datefmt);
   if mdt < xdt then
      out_err := out_err + 1;
      err_msg(ip, 'Manufacture date < 1/1/2000: ' || to_char(mdt, 'mm/dd/yyyy'));
   end if;
   if mdt > sysdate then
      out_err := out_err + 1;
      err_msg(ip, 'Manufacture date > today: ' || to_char(mdt, 'mm/dd/yyyy'));
   end if;
end if;
-- expiration date validation
if ip.expirationdate is not null then
   date_err := ' expiration date ';
   cDate := ip.expirationdate;
   edt := to_date(ip.expirationdate, datefmt);
   if edt < xdt then
       out_err := out_err + 1;
       err_msg(ip, 'Expiration date < 1/1/2000: ' || to_char(edt, 'mm/dd/yyyy'));
   end if;
end if;


sn := ip.serialnumber;
ln := ip.lotnumber;
u1 := ip.useritem1;
u2 := ip.useritem2;
u3 := ip.useritem3;
cty := ip.countryof;
--mdt
--edt

-- check parse rule
if civ.parseruleaction = 'Y' then
   pstring := null;
   ruleid := civ.parseruleid;
   if civ.parseentryfield = 'LOTNUMBER' then
      pstring := ip.lotnumber;
   end if;
   if civ.parseentryfield = 'SERIALNUMBER' then
      pstring := ip.serialnumber;
   end if;
   if civ.parseentryfield = 'USERITEM1' then
      pstring := ip.useritem1;
   end if;
   if civ.parseentryfield = 'USERITEM2' then
      pstring := ip.useritem2;
   end if;
   if civ.parseentryfield = 'USERITEM3' then
      pstring := ip.useritem3;
   end if;

   if pstring is null then
      return out_err;
   end if;
   zpr.parse_string(ruleid, pstring, serialno, lot, user1, user2, user3, mfgdate, expdate, country, out_msg);
   if out_msg <> 'OKAY' then
       out_err := out_err + 1;
       err_msg(ip, 'Parse ' || out_msg);
       return out_err;
   end if;
   if mfgdate = 'Invalid Date Value' then
       out_err := out_err + 1;
       err_msg(ip, 'Parse rule resulted in invalid mfgdate' || pstring);
   end if;
   if expdate = 'Invalid Date Value' then
       out_err := out_err + 1;
       err_msg(ip, 'Parse rule resulted in invalid expdate' || pstring);
   end if;
   if serialno is not null then
      sn := serialno;
   end if;
   if lot is not null then
      ln := lot;
   end if;
   if user1 is not null then
      u1 := user1;
   end if;
   if user2 is not null then
      u1 := user2;
   end if;
   if user3 is not null then
      u1 := user3;
   end if;
   if mfgdate is not null then
      mdt := to_date(mfgdate, 'mm/dd/yyyy');
   end if;
   if expdate is not null then
      edt := to_date(expdate, 'mm/dd/yyyy');
   end if;
   if country is not null then
      cty := country;
   end if;
end if;


if mdt is null then
   if civ.mfgdaterequired = 'Y' then
        out_err := out_err + 1;
        err_msg(ip, 'Manufacture date is required');
   end if;
end if;


--serial number must be present if required
if civ.serialrequired = 'Y' then
   if sn is null then
        out_err := out_err + 1;
        err_msg(ip, 'Serial number is required for this item');
   end if;
end if;

--lot must be present if required
if civ.lotrequired in ('Y','O','S','A') then
   if ln is null then
        out_err := out_err + 1;
        err_msg(ip, 'Lot Number is required for this item');
   end if;
end if;


if cty is null then
   if civ.countryrequired = 'Y' then
        out_err := out_err + 1;
        err_msg(ip, 'Country of Origin is required');
   end if;
end if;

-- useritem1 present if
if civ.user1required = 'Y' then
   if u1 is null then
        out_err := out_err + 1;
        err_msg(ip, 'User Item 1 is required for this item');
   end if;
end if;

-- useritem2 present if required
if civ.user2required = 'Y' then
   if u2 is null then
        out_err := out_err + 1;
        err_msg(ip, 'User Item 2 is required for this item');
   end if;
end if;

-- useritem3 present if required
if civ.user3required = 'Y' then
   if u3 is null then
        out_err := out_err + 1;
        err_msg(ip, 'User Item 3 is required for this item');
   end if;
end if;

return out_err;

exception when others then
  out_msg := 'zinvplate ' || sqlerrm || ip.lpid;
  out_errorno := sqlcode;
  if date_err is not null then
      out_err := out_err + 1;
      err_msg(ip, cDate ||' '||datefmt|| date_err || sqlerrm);
  end if;
  return out_err;


end cip_validation;
--##############################################################################
-- cip insert plate
--##############################################################################
procedure cip_insert_plate
(ip in import_plate%rowtype,
 datefmt in varchar2
)
is
CURSOR C_ITEM(in_custid varchar2, in_item varchar2)
RETURN custitemview%rowtype
IS
 select *
   from custitemview I
  where I.custid = in_custid
    and I.item = in_item;

civ custitemview%rowtype;

msg varchar2(80);
qty number;
lpid varchar2(15);
crdt date;
exdt date;
madt date;
sn varchar2(40);
ln varchar2(40);
u1 varchar(40);
u2 varchar(40);
u3 varchar(40);
cty varchar(3);

ruleid varchar2(20);
pstring varchar2(20);
lot varchar2(30);
serialno varchar2(30);
user1 varchar2(20);
user2 varchar2(20);
user3 varchar2(20);
mfgdate varchar2(20);
expdate varchar2(20);
country varchar2(20);
virtualLpid varchar2(15);
masterLpid varchar2(15);



rm varchar2(4);
invstat varchar2(4);
iclass varchar2(4);
wght number(17,8);
qtyrec number;
cntRows integer;


begin
civ := null;

open C_ITEM(ip.custid, ip.item);
fetch C_ITEM into civ;
close C_ITEM;

-- default values

-- fill in lpid if null
lpid := ip.lpid;
if ip.lpid is null then
   zrf.get_next_lpid(lpid, msg);
   if msg is not null then
        err_msg(ip,'Plate not inserted: ' || msg);
        return;
   end if;
   end if;
if length(lpid) < 15 then
   lpid := substr('000000000000000',1,15 - length(lpid)) || lpid;
end if;

-- in not already base uom, translate uom/qty
qty := ip.quantity;
if ip.unitofmeasure <> civ.baseuom then
   zbut.translate_uom(ip.custid, ip.item, ip.quantity, ip.unitofmeasure,
                      civ.baseuom, qty, msg);
   if substr(msg,1,4) != 'OKAY' then
      err_msg(ip, 'Plate not inserted: ' || msg);
      return;
   end if;
end if;

-- if creation date is null, make is sysdate
if ip.creationdate is null then
   select sysdate into crdt from dual;
else
   crdt := to_date(ip.creationdate, datefmt);
end if;

-- if manufacture date is not null, convert to a date
if ip.manufacturedate is null then
   madt := null;
else
   madt := to_date(ip.manufacturedate, datefmt);
end if;

if ip.expirationdate is not null then
   exdt := to_date(ip.expirationdate, datefmt);
else
   exdt := null;
end if;



-- recmethod is 'PL' if not present
if ip.recmethod is null then
   rm := 'PL';
else
   rm := ip.recmethod;
end if;

-- invstatus is 'AV' if not present
if ip.invstatus is null then
   invstat := 'AV';
else
   invstat := ip.invstatus;
end if;

-- inventoryclass is 'RG' if not present
if ip.inventoryclass is null then
   iclass := 'RG';
else
   iclass := ip.inventoryclass;
end if;

-- calculate weight if not present
if ip.weight is null then
   wght := null;
else
   if ip.weight = 0 then
      wght := null;
   else
      wght := ip.weight;
   end if;
end if;
if wght is null then
   -- zut.prt('calc weight ');
   wght := zci.item_weight(ip.custid, ip.item, ip.unitofmeasure) * ip.quantity;
end if;

-- qty received is quantity if null
if ip.qtyrcvd is null then
   qtyrec := qty;
else
   qtyrec := ip.qtyrcvd;
end if;

sn := ip.serialnumber;
ln := ip.lotnumber;
-- madt
-- exdt
u1 := ip.useritem1;
u2 := ip.useritem2;
u3 := ip.useritem3;
cty := ip.countryof;

if civ.parseruleaction = 'Y' then
   ruleid := civ.parseruleid;

   if civ.parseentryfield = 'LOTNUMBER' then
      pstring := ip.lotnumber;
   end if;
   if civ.parseentryfield = 'SERIALNUMBER' then
      pstring := ip.serialnumber;
   end if;
   if civ.parseentryfield = 'USERITEM1' then
      pstring := ip.useritem1;
   end if;
   if civ.parseentryfield = 'USERITEM2' then
      pstring := ip.useritem2;
   end if;
   if civ.parseentryfield = 'USERITEM3' then
      pstring := ip.useritem3;
   end if;
   zpr.parse_string(ruleid, pstring, serialno, lot, user1, user2, user3, mfgdate, expdate, country, out_msg);
   if serialno is not null then
      sn := serialno;
   end if;
   if lot is not null then
      ln := lot;
   end if;
   if user1 is not null then
      u1 := user1;
   end if;
   if user2 is not null then
      u1 := user2;
   end if;
   if user3 is not null then
      u1 := user3;
   end if;
   if mfgdate is not null then
      madt := to_date(mfgdate, 'mm/dd/yyyy');
   end if;
   if expdate is not null then
      exdt := to_date(expdate, 'mm/dd/yyyy');
   end if;
   if country is not null then
      cty := country;
   end if;
end if;

if civ.expdaterequired = 'Y' then
   if exdt is null then
       exdt := zrf.calc_expiration(exdt, madt, civ.shelflife);
   end if;
end if;

-- generate master lip if needed
if ip.masterlpid is not null then
   select count(1) into cntRows
      from import_plate_master
      where masterlpid = ip.masterlpid;
   if cntRows > 0 then
      select lpid into virtualLpid
         from import_plate_master
         where masterlpid = ip.masterlpid;
      update plate
         set quantity = quantity + qty,
             weight = weight + wght
         where lpid = virtualLpid;
   else
      zrf.get_next_vlpid(virtualLpid, msg);
      if msg is not null then
           err_msg(ip,'Plate not inserted: ' || msg);
           return;
      end if;
      insert into import_plate_master (masterlpid, lpid) values (ip.masterlpid, virtualLpID);
      insert into plate
         (lpid, item, custid, facility, location, status, unitofmeasure, quantity,
          type, serialnumber, lotnumber, creationdate, manufacturedate,
          expirationdate, expiryaction, po, recmethod, condition, countryof,
          useritem1, useritem2, useritem3, lastuser, lastupdate, invstatus,
          qtyentered, itementered, uomentered, inventoryclass, orderid, shipid,
          weight, qtyrcvd, parentfacility, parentitem, virtuallp)
         values
         (virtualLpID, ip.item, ip.custid, ip.facility, ip.location, 'A', civ.baseuom, qty,
          'MP', null, ln, crdt, null,
          null, null, ip.po, null, null,null,
          null, null, null, 'LDINV', sysdate, invstat,
          null, ip.item, null, iclass, ip.orderid, ip.shipid,
          wght, null, ip.facility, ip.item,'Y' );
   end if;
else
   virtualLpid := null;
end if;


insert into plate
   (lpid, item, custid, facility, location, status, unitofmeasure, quantity,
    type, serialnumber, lotnumber, creationdate, manufacturedate,
    expirationdate, expiryaction, po, recmethod, condition, countryof,
    useritem1, useritem2, useritem3, lastuser, lastupdate, invstatus,
    qtyentered, itementered, uomentered, inventoryclass, orderid, shipid,
    weight, qtyrcvd, parentfacility, parentitem, parentlpid)
   values
   (lpid, ip.item, ip.custid, ip.facility, ip.location, 'A', civ.baseuom, qty,
    'PA', sn, ln, crdt, madt,
    exdt, civ.expiryaction, ip.po, rm, ip.condition, cty,
    u1, u2, u3, 'LDINV', sysdate, invstat,
    qty, ip.item, civ.baseuom, iclass, ip.orderid, ip.shipid,
    wght, qtyrec, decode(virtualLpid, null, ip.facility, null),decode(virtuallpid, null, ip.item,null), virtualLpid );
if virtualLpid is not null then
   select count(distinct custid) into cntCustid
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct item) into cntItem
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct lotnumber) into cntLotnumber
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct invstatus) into cntInvstatus
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct inventoryclass) into cntInventoryclass
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct nvl(orderid,0)) into cntOrderid
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct nvl(shipid,0)) into cntShipid
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct nvl(loadno,0)) into cntLoadno
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct nvl(stopno,0)) into cntStopno
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   select count(distinct nvl(shipno,0)) into cntShipno
      from plate
      where custid = ip.custid
        and parentlpid = virtualLpid;

   if cntCustid > 1 or
      cntItem > 1 or
      cntLotnumber > 1or
      cntInvstatus > 1 or
      cntInventoryclass > 1 or
      cntOrderid > 1 or
      cntShipid > 1 or
      cntLoadno > 1 or
      cntStopno > 1 or
      cntShipno > 1 then

      if cntCustid > 1 or cntItem > 1 then
      -- mixed MP
         update plate
            set custid = decode(cntCustid, 1, ip.custid, null),
                item = null,
                parentfacility = null,
                parentitem = null
            where lpid = virtualLpid;
         update plate
            set childfacility = facility,
                childitem = item
            where parentlpid = virtualLpid;
      end if;

      if cntLotnumber > 1 then
         update plate
            set lotnumber = null
            where lpid = virtualLpid;
      end if;
      if cntInvstatus > 1 then
         update plate
            set invstatus = null
            where lpid = virtualLpid;
      end if;
      if cntInventoryclass > 1 then
         update plate
            set inventoryclass = null
            where lpid = virtualLpid;
      end if;
      if cntOrderid > 1 or cntShipid > 1 then
         update plate
            set orderid = null, shipid = null
            where lpid = virtualLpid;
      end if;
      if cntLoadno > 1 or cntStopno > 1 or cntShipno > 1 then
         update plate
            set orderid = null, shipid = null
            where lpid = virtualLpid;
      end if;

   end if;

end if;

exception when others then
  out_msg := 'zinvplate ' || sqlerrm || ip.lpid;
  out_errorno := sqlcode;

end cip_insert_plate;
--##############################################################################


begin
err_cnt := 0;

-- find the largest sequence existing the import_plate table or the
-- import_plate_error table add 1 and make it the load sequence
-- for the newly imported data (load_sequence = 0)
-- put out a message in the app_msgs with that sequence
select nvl(max(load_sequence),0) into ip_max from import_plate;
select nvl(max(load_sequence),0) into ipe_max from import_plate_error;
if ip_max > ipe_max  then
   new_seq := ip_max;
else
   new_seq := ipe_max;
end if;

new_seq := new_seq + 1;

zms.log_msg('ImpInv', 0, ' ', 'Inventory Import Sequence ' || to_char(new_seq, '9999'),
           'T', 'ImpInv', strMsg);


update import_plate
   set load_sequence = new_seq
   where load_sequence = 0;

for cip in C_IP(new_seq) loop
-- perform validation
   err_cnt := err_cnt + cip_validation(cip, in_datefmt);
end loop;

for mip in C_MIP(new_seq) loop
-- perform validation
   if mip.loccount > 1 then
      err_cnt := err_cnt + 1;
   insert into import_plate_error
     (load_sequence, record_sequence, lpid, item, custid,
     facility, location, unitofmeasure, quantity, comments)
   values
     (new_seq, 0, null, null, null,
      null, null, null, null, 'Master ' || mip.masterlpid || ' has multiple locations ');
end if;
end loop;



if in_update = 'Y' then
   if err_cnt = 0 then
      for cip in C_IP(new_seq) loop
         cip_insert_plate(cip, in_datefmt);
      end loop;
   end if;
end if;

commit;

zms.log_msg('ImpInv', 0, ' ', 'Inventory Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
           'T', 'ImpInv', strMsg);

out_msg := 'Error count ' || to_char(err_cnt,'99999999');
out_errorno := new_seq;

end end_import_inv;


procedure import_lot_receipt_rate
(
    in_facility IN  varchar2,
    in_custid   IN  varchar2,
    in_item     IN  varchar2,
    in_lot      IN  varchar2,
    in_receiptdate IN date,
    in_quantity IN  number,
    in_uom      IN  varchar2,
    in_weight   IN  number,
    in_renewalrate IN number,
    out_errorno IN OUT number,
    out_msg     OUT varchar2
)
is

cnt integer;

BEGIN
    out_errorno := 0;
    out_msg := '';

-- Verify Facility
    cnt := 0;
    select count(1)
      into cnt
      from facility
     where facility = in_facility;

    if nvl(cnt,0) < 1 then
        out_errorno := -1;
        out_msg := 'Invalid facility:'||in_facility;
        return;
    end if;

-- Verify Customer
    cnt := 0;
    select count(1)
      into cnt
      from customer
     where custid = in_custid;

    if nvl(cnt,0) < 1 then
        out_errorno := -1;
        out_msg := 'Invalid custid:'||in_custid;
        return;
    end if;

-- Verify Item
    cnt := 0;
    select count(1)
      into cnt
      from custitem
     where custid = in_custid
       and item = in_item;

    if nvl(cnt,0) < 1 then
        out_errorno := -1;
        out_msg := 'Invalid item:'||in_custid||'/'||in_item;
        return;
    end if;

-- Verify lots OK for Item
    if in_lot is not null then
        cnt := 0;
        select count(1)
          into cnt
          from custitemview
         where custid = in_custid
           and item = in_item
           and lotrequired in ('Y','O','S','A');

        if nvl(cnt,0) < 1 then
            out_errorno := -1;
            out_msg := 'Invalid lot not allowed for item:'
                ||in_custid||'/'||in_item;
            return;
        end if;

    end if;

-- Verify UOM
/*
    cnt := 0;
    select count(1)
      into cnt
      from custuomallview
     where custid = in_custid
       and item = in_item
       and uom = in_uom;

    if nvl(cnt,0) < 1 then
        out_errorno := -1;
        out_msg := 'Invalid item UOM:'||in_custid||'/'||in_item||'/'||in_uom;
        return;
    end if;
*/

    cnt := 0;
    select count(1)
      into cnt
      from unitsofmeasure
     where code = in_uom;

    if nvl(cnt,0) < 1 then
        out_errorno := -1;
        out_msg := 'Invalid UOM:'||in_uom;
        return;
    end if;


-- Check quantity, weight, renewalrate, receiptdate

    if nvl(in_quantity,0) <=0  then
        out_errorno := -1;
        out_msg := 'Quantity must be defined greater than zero';
        return;
    end if;

    if nvl(in_weight,0) <= 0  then
        out_errorno := -1;
        out_msg := 'Weight must be defined greater than zero';
        return;
    end if;

    if nvl(in_renewalrate,0) <= 0 then
        out_errorno := -1;
        out_msg := 'Renewal rate must be defined greater than zero';
        return;
    end if;

    if in_receiptdate is null then
        out_errorno := -1;
        out_msg := 'Receipt date must be defined';
        return;
    end if;



-- Add/replace rate in table bill_lot_renewal
    update bill_lot_renewal
       set quantity = in_quantity,
           weight = in_weight,
           receiptdate = trunc(in_receiptdate),
           renewalrate = in_renewalrate,
           uom = in_uom,
           lastuser = 'IMPORT',
           lastupdate = sysdate
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and nvl(lotnumber, '(none)') = nvl(in_lot, '(none)');

    if sql%rowcount = 0 then
        insert into bill_lot_renewal(facility, custid, item, lotnumber,
                receiptdate, quantity, uom, weight, renewalrate,
                lastuser, lastupdate)
        values (in_facility, in_custid, in_item, in_lot, trunc(in_receiptdate),
                in_quantity, in_uom, in_weight, in_renewalrate,
                'IMPORT', sysdate);

    end if;


EXCEPTION WHEN OTHERS THEN
    out_errorno := sqlcode;
    out_msg := sqlerrm;

END import_lot_receipt_rate;

-------------------------------------------------------------------------------

end zimportprocinv;
/
show error package body zimportprocinv;
exit;




