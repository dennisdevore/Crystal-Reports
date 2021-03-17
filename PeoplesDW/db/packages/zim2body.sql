create or replace package body alps.zimportproc2 as

--
-- $Id$
--

IMP_USERID constant varchar2(8) := 'IMPORDER';

procedure aip_import_inventory
(in_location in varchar2
,in_serialno in varchar2
,in_batch_lot in varchar2
,in_warehouse in varchar2
,in_lm_locn in varchar2
,in_item in varchar2
,in_itemdsc in varchar2
,in_qty  in number
,in_rcptno in varchar2
,in_rcptdate in date
,in_custid in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

tmp_lpid varchar2(15);

begin



tmp_lpid := '00000' || in_serialno;

if rtrim(in_location) is null then
  out_errorno := -2;
  out_msg := 'Location value is required';
  return;
end if;

insert into plate
(lpid, item, custid, facility, location, invstatus, unitofmeasure,
quantity, inventoryclass, serialnumber, lotnumber, creationdate,
lastuser,lastupdate,status,type,qtyentered,itementered,uomentered,
parentfacility,parentitem,weight,recmethod)
values
(tmp_lpid, in_item, in_custid, in_warehouse, in_location,
 'AV', 'EA', in_qty, 'RG', in_serialno, 'NA',
in_rcptdate, 'CONV', sysdate,'A','PA',in_qty,in_item,'EA',
in_warehouse, in_item, zci.item_weight(in_custid, in_item, 'EA')*in_qty, 'PL');

exception when others then
  out_msg := 'zimin ' || sqlerrm || in_serialno;
  out_errorno := sqlcode;
end aip_import_inventory;

procedure import_inventory
(in_location in varchar2
,in_lpid in varchar2
,in_batch_lot in varchar2
,in_warehouse in varchar2
,in_item in varchar2
,in_itemdsc in varchar2
,in_uom in varchar2
,in_qty  in number
,in_rcptno in varchar2
,in_rcptdate in date
,in_custid in varchar2
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
(lpid, item, custid, facility, location, invstatus, unitofmeasure,
quantity, inventoryclass, lotnumber, creationdate,
lastuser,lastupdate,status,type,qtyentered,itementered,uomentered,
parentfacility,parentitem,weight,recmethod)
values
(in_lpid, in_item, in_custid, in_warehouse, in_location,
 'AV', in_uom, in_qty, 'RG', in_batch_lot,
in_rcptdate, 'CONV', sysdate,'A','PA',in_qty,in_item,in_uom,
in_warehouse, in_item, zci.item_weight(in_custid, in_item, in_uom)*in_qty, 'PL');

exception when others then
  out_msg := 'zimimi ' || sqlerrm || in_lpid;
  out_errorno := sqlcode;
end import_inventory;

procedure import_location
(in_facility in varchar2
,in_location in varchar2
,in_loctype in varchar2
,in_storagetype in varchar2
,in_section in varchar2
,in_checkdigit in varchar2
,in_status in varchar2
,in_pickingseq in number
,in_pickingzone in varchar2
,in_putawayseq in number
,in_putawayzone in varchar2
,in_inboundzone in varchar2
,in_outboundzone in varchar2
,in_panddlocation in varchar2
,in_equipprof in varchar2
,in_velocity in varchar2
,in_mixeditemsok in varchar2
,in_mixedlotsok in varchar2
,in_mixeduomok in varchar2
,in_countinterval in number
,in_unitofstorage in varchar2
,in_descr in varchar2
,in_weightlimit in number
,in_aisle in varchar2
,in_mixedcustsok in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

if rtrim(in_facility) is null then
  out_errorno := -1;
  out_msg := 'Facility value is required';
  return;
end if;

if rtrim(in_location) is null then
  out_errorno := -2;
  out_msg := 'Location value is required';
  return;
end if;

insert into location
(facility, locid, loctype, storagetype, section,
checkdigit, status, pickingseq, pickingzone,
putawayzone, putawayseq, inboundzone,
outboundzone, panddlocation, equipprof, velocity,
mixeditemsok, mixedlotsok, mixeduomok, mixedcustsok, countinterval,
unitofstorage, descr, weightlimit, aisle, lastuser, lastupdate)
values
(in_facility, in_location, in_loctype, in_storagetype, in_section,
in_checkdigit, in_status, in_pickingseq, in_pickingzone,
in_putawayzone, in_putawayseq, in_inboundzone,
in_outboundzone, in_panddlocation, in_equipprof, in_velocity,
in_mixeditemsok, in_mixedlotsok, in_mixeduomok, in_mixedcustsok, in_countinterval,
in_unitofstorage, in_descr, in_weightlimit, in_aisle, 'CONV', sysdate);


exception when others then
  out_msg := 'zimil ' || sqlerrm;
  out_errorno := sqlcode;
end import_location;

procedure import_loc_with_validation
(in_locid in varchar2
,in_facility in varchar2
,in_loctype in varchar2
,in_storagetype in varchar2
,in_section in varchar2
,in_checkdigit in varchar2
,in_status in varchar2
,in_pickingseq in number
,in_pickingzone in varchar2
,in_putawayseq in number
,in_putawayzone in varchar2
,in_inboundzone in varchar2
,in_outboundzone in varchar2
,in_panddlocation in varchar2
,in_equipprof in varchar2
,in_velocity in varchar2
,in_mixeditemsok in varchar2
,in_mixedlotsok in varchar2
,in_mixeduomok in varchar2
,in_countinterval in number
,in_unitofstorage in varchar2
,in_descr in varchar2
,in_weightlimit in number
,in_aisle in varchar2
,in_stackheight in number
,in_count_after_pick in varchar2
,in_mixedcustsok in varchar2
,out_errorno in out number
,out_msg in out varchar2
) is
recseq integer;
begin
select nvl(max(record_sequence),0) into recseq
   from import_location_table
   where load_sequence = 0;
recseq := recseq + 1;
insert into import_location_table
(load_sequence,record_sequence,locid,facility,loctype,storagetype,section,checkdigit,
status,pickingseq,pickingzone,putawayseq,putawayzone,inboundzone,outboundzone,
panddlocation,equipprof,velocity,mixeditemsok,mixedlotsok,mixeduomok,countinterval,
unitofstorage,descr,weightlimit,aisle,stackheight,count_after_pick,mixedcustsok,
lastuser,lastupdate)
values
(0,recseq,in_locid,in_facility,in_loctype,in_storagetype,
in_section,in_checkdigit,in_status,in_pickingseq,in_pickingzone,in_putawayseq,
in_putawayzone,in_inboundzone,in_outboundzone,in_panddlocation,in_equipprof,in_velocity,
in_mixeditemsok,in_mixedlotsok,in_mixeduomok,in_countinterval,in_unitofstorage,in_descr,
in_weightlimit,in_aisle,in_stackheight,in_count_after_pick,in_mixedcustsok,'IMP_LOC',
sysdate);
out_errorno := 0;
out_msg := 'OKAY';
exception when others then
  out_msg := 'zimilwv ' || in_locid || ' ' ||sqlerrm;
  out_errorno := sqlcode;
end import_loc_with_validation;
procedure end_import_loc
(in_update IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
il_max integer;
ile_max integer;
new_seq integer;
err_cnt integer;
cntRows integer;
strMsg varchar2(255);
cursor C_IL(in_seq integer)
return import_location_table%rowtype
is
  select *
    from import_location_table
   where load_sequence = in_seq
   order by record_sequence;
cil import_location_table%rowtype;
procedure err_msg
(il in import_location_table%rowtype
,error_msg in varchar2) is
begin
insert into import_location_error
  (load_sequence, record_sequence, locid, facility, comments)
 values
  (il.load_sequence, il.record_sequence, il.locid, il.facility, error_msg);
end err_msg;
function cil_validation
(il in import_location_table%rowtype)
return integer
is
out_err integer;
cntRows integer;
begin
out_err := 0;
select count(1) into cntRows
   from location
   where facility = il.facility
     and locid = il.locid;
if cntRows > 0 then
   out_err := out_err + 1;
   err_msg(il, 'Location already exists: ' || il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from import_location_table
   where facility = il.facility
     and locid = il.locid
     and load_sequence = il.load_sequence;
if cntRows > 1 then
   out_err := out_err + 1;
   err_msg(il, 'Location in import multiple times: ' || il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from facility
   where facility = il.facility;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid facility: ' || il.facility || ' ' ||il.locid);
end if;
if il.loctype is null  then
   out_err := out_err + 1;
   err_msg(il, 'Location type not present: ' || il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from LocationTypes
   where code = il.loctype;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid location type: ' || il.facility || ' ' ||il.locid);
end if;
if il.storagetype is null  then
   out_err := out_err + 1;
   err_msg(il, 'Storage type not present: ' || il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from StorageTypes
   where code = il.storagetype;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid storage type: ' || il.storagetype || ' ' || il.facility || ' ' ||il.locid);
end if;
if il.status is null  then
   out_err := out_err + 1;
   err_msg(il, 'Status not present: ' || il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from LocationStatus
   where code = il.status;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid status: ' || il.status || ' ' ||il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from section
   where facility = il.facility
     and sectionid = nvl(il.section,'(n)');
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid section: ' || il.status || ' ' ||il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from EquipmentProfiles
   where code = il.equipprof;
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid Equipment Profile: ' || il.equipprof || ' ' ||il.facility || ' ' ||il.locid);
end if;
select count(1) into cntRows
   from unitofstorage
   where unitofstorage = nvl(il.unitofstorage,'(none)');
if cntRows = 0 then
   out_err := out_err + 1;
   err_msg(il, 'Invalid Unit of Storage: ' || il.unitofstorage || ' ' ||il.facility || ' ' ||il.locid);
end if;
if il.pickingzone is not null then
   select count(1) into cntRows
      from zone
      where facility = il.facility
        and zoneid = il.pickingzone;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Picking Zone: ' || il.pickingzone || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if il.putawayzone is not null then
   select count(1) into cntRows
      from zone
      where facility = il.facility
        and zoneid = il.putawayzone;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Putaway Zone: ' || il.putawayzone || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if il.inboundzone is not null then
   select count(1) into cntRows
      from zone
      where facility = il.facility
        and zoneid = il.inboundzone;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Inbound Zone: ' || il.inboundzone || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if il.outboundzone is not null then
   select count(1) into cntRows
      from zone
      where facility = il.facility
        and zoneid = il.outboundzone;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Outbound Zone: ' || il.outboundzone || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if il.panddlocation is not null then
   select count(1) into cntRows
      from location
      where facility = il.facility
        and locid = il.panddlocation;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid P and D Location: ' || il.panddlocation || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if il.velocity is not null then
   select count(1) into cntRows
     from itemvelocitycodes
     where code = il.velocity;
   if cntRows = 0 then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Velocity: ' || il.velocity || ' ' ||il.facility || ' ' ||il.locid);
   end if;
end if;
if nvl(il.mixeditemsok, 'Y') <> 'Y' and
   nvl(il.mixeditemsok, 'Y') <> 'N' then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Mixed Items OK: ' || il.mixeditemsok || ' ' ||il.facility || ' ' ||il.locid);
end if;
if nvl(il.mixedlotsok, 'Y') <> 'Y' and
   nvl(il.mixedlotsok, 'Y') <> 'N' then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Mixed Lot OK: ' || il.mixedlotsok || ' ' ||il.facility || ' ' ||il.locid);
end if;
if nvl(il.mixeduomok, 'Y') <> 'Y' and
   nvl(il.mixeduomok, 'Y') <> 'N' then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Mixed Uom OK: ' || il.mixeduomok || ' ' ||il.facility || ' ' ||il.locid);
end if;
if nvl(il.mixeduomok, 'Y') <> 'Y' and
   nvl(il.mixeduomok, 'Y') <> 'N' then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Mixed Uom OK: ' || il.mixeduomok || ' ' ||il.facility || ' ' ||il.locid);
end if;
if nvl(il.mixedcustsok, 'Y') <> 'Y' and
   nvl(il.mixedcustsok, 'Y') <> 'N' then
      out_err := out_err + 1;
      err_msg(il, 'Invalid Mixed Custs OK: ' || il.mixedcustsok || ' ' ||il.facility || ' ' ||il.locid);
end if;
return out_err;
exception when others then
  out_msg := 'zinvloc ' || sqlerrm || il.locid;
  out_errorno := sqlcode;
  out_err := out_err + 1;
  return out_err;
end cil_validation;
procedure cil_insert_location
(il in import_location_table%rowtype)
is
begin
   insert into location (locid,facility,loctype,storagetype,section,
      checkdigit,status,pickingseq,pickingzone,putawayseq,putawayzone,
      inboundzone,outboundzone,panddlocation,equipprof,velocity,mixeditemsok,
      mixedlotsok,mixeduomok,
      countinterval,lastuser,lastupdate,unitofstorage,descr,weightlimit,
      aisle,stackheight,count_after_pick,
      mixedcustsok)
   values
      (il.locid,il.facility,il.loctype,il.storagetype,il.section,
      il.checkdigit,il.status,il.pickingseq,il.pickingzone,il.putawayseq,il.putawayzone,
      il.inboundzone,il.outboundzone,il.panddlocation,il.equipprof,il.velocity,il.mixeditemsok,
      il.mixedlotsok,il.mixeduomok,
      il.countinterval,il.lastuser,il.lastupdate,il.unitofstorage,il.descr,il.weightlimit,
      il.aisle,il.stackheight,il.count_after_pick,
      il.mixedcustsok);
 end cil_insert_location;
 begin
 select nvl(max(load_sequence),0) into il_max from import_location_table;
 select nvl(max(load_sequence),0) into ile_max from import_location_error;
 if il_max > ile_max  then
    new_seq := il_max;
 else
    new_seq := ile_max;
 end if;
 new_seq := new_seq + 1;
 zms.log_msg('ImpLoc', 0, ' ', 'Location Import Sequence ' || to_char(new_seq, '9999'),
            'T', 'ImpLoc', strMsg);
 update import_location_table
    set load_sequence = new_seq
    where load_sequence = 0;
 err_cnt := 0;
 for cil in C_IL(new_seq) loop
    err_cnt := err_cnt + cil_validation(cil);
 end loop;
 if in_update = 'Y' then
    if err_cnt = 0 then
       for cil in C_IL(new_seq) loop
          cil_insert_location(cil);
       end loop;
    end if;
 end if;
commit;
zms.log_msg('ImpLoc', 0, ' ', 'Location Import  ' || to_char(new_seq, '9999') || ' error count ' || to_char(err_cnt, '999999'),
           'T', 'ImpLoc', strMsg);
end end_import_loc;
procedure begin_ship_sum
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'ORDERCONFIRMVIEW_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create view orderconfirmview_' || strSuffix ||
' (ORDERID,SHIPID,CUSTID,ORDERTYPE,ENTRYDATE,APPTDATE,SHIPDATE,PO,RMA,ORDERSTATUS,' ||
'COMMITSTATUS,FROMFACILITY,TOFACILITY,LOADNO,STOPNO,SHIPNO,SHIPTO,DELAREA,QTYORDER,' ||
'WEIGHTORDER,CUBEORDER,AMTORDER,QTYCOMMIT,WEIGHTCOMMIT,CUBECOMMIT,AMTCOMMIT,QTYSHIP,' ||
'WEIGHTSHIP,CUBESHIP,AMTSHIP,QTYTOTCOMMIT,WEIGHTTOTCOMMIT,CUBETOTCOMMIT,AMTTOTCOMMIT,' ||
'QTYRCVD,WEIGHTRCVD,CUBERCVD,AMTRCVD,STATUSUSER,STATUSUPDATE,LASTUSER,' ||
'LASTUPDATE,BILLOFLADING,PRIORITY,SHIPPER,ARRIVALDATE,CONSIGNEE,SHIPTYPE,CARRIER,' ||
'REFERENCE,SHIPTERMS,WAVE,STAGELOC,QTYPICK,WEIGHTPICK,CUBEPICK,AMTPICK,SHIPTONAME,'||
'SHIPTOCONTACT,SHIPTOADDR1,SHIPTOADDR2,SHIPTOCITY,SHIPTOSTATE,SHIPTOPOSTALCODE,'||
'SHIPTOCOUNTRYCODE,SHIPTOPHONE,SHIPTOFAX,SHIPTOEMAIL,BILLTONAME,BILLTOCONTACT,'||
'BILLTOADDR1,BILLTOADDR2,BILLTOCITY,BILLTOSTATE,BILLTOPOSTALCODE,BILLTOCOUNTRYCODE,'||
'BILLTOPHONE,BILLTOFAX,BILLTOEMAIL,PARENTORDERID,PARENTSHIPID,PARENTORDERITEM,'||
'PARENTORDERLOT,WORKORDERSEQ,STAFFHRS,QTY2SORT,WEIGHT2SORT,CUBE2SORT,AMT2SORT,'||
'QTY2PACK,WEIGHT2PACK,CUBE2PACK,AMT2PACK,QTY2CHECK,WEIGHT2CHECK,CUBE2CHECK,'||
'AMT2CHECK,IMPORTFILEID,HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,'||
'HDRPASSTHRUCHAR04,HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,'||
'HDRPASSTHRUCHAR08,HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,'||
'HDRPASSTHRUCHAR12,HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,'||
'HDRPASSTHRUCHAR16,HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,'||
'HDRPASSTHRUCHAR20,HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,'||
'HDRPASSTHRUNUM04,HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,'||
'HDRPASSTHRUNUM08,HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,CONFIRMED,rejectcode,'||
'rejecttext,dateshipped,linecount,packlistshipdate,edicancelpending,'||
'deliveryservice,saturdaydelivery) as '||
' select ORDERID,SHIPID,CUSTID,ORDERTYPE,ENTRYDATE,APPTDATE,SHIPDATE,PO,'||
'RMA,ORDERSTATUS,COMMITSTATUS,FROMFACILITY,TOFACILITY,LOADNO,STOPNO,'||
'SHIPNO,SHIPTO,DELAREA,QTYORDER,WEIGHTORDER,CUBEORDER,AMTORDER,QTYCOMMIT,'||
'WEIGHTCOMMIT,CUBECOMMIT,AMTCOMMIT,QTYSHIP,WEIGHTSHIP,CUBESHIP,AMTSHIP,'||
'QTYTOTCOMMIT,WEIGHTTOTCOMMIT,CUBETOTCOMMIT,AMTTOTCOMMIT,QTYRCVD,WEIGHTRCVD,'||
'CUBERCVD,AMTRCVD,STATUSUSER,STATUSUPDATE,LASTUSER,LASTUPDATE,'||
'BILLOFLADING,PRIORITY,SHIPPER,ARRIVALDATE,CONSIGNEE,SHIPTYPE,CARRIER,'||
'REFERENCE,SHIPTERMS,WAVE,STAGELOC,QTYPICK,WEIGHTPICK,CUBEPICK,AMTPICK,'||
'SHIPTONAME,SHIPTOCONTACT,SHIPTOADDR1,SHIPTOADDR2,SHIPTOCITY,SHIPTOSTATE,'||
'SHIPTOPOSTALCODE,SHIPTOCOUNTRYCODE,SHIPTOPHONE,SHIPTOFAX,SHIPTOEMAIL,'||
'BILLTONAME,BILLTOCONTACT,BILLTOADDR1,BILLTOADDR2,BILLTOCITY,BILLTOSTATE,'||
'BILLTOPOSTALCODE,BILLTOCOUNTRYCODE,BILLTOPHONE,BILLTOFAX,BILLTOEMAIL,'||
'PARENTORDERID,PARENTSHIPID,PARENTORDERITEM,PARENTORDERLOT,WORKORDERSEQ,'||
'STAFFHRS,QTY2SORT,WEIGHT2SORT,CUBE2SORT,AMT2SORT,QTY2PACK,WEIGHT2PACK,'||
'CUBE2PACK,AMT2PACK,QTY2CHECK,WEIGHT2CHECK,CUBE2CHECK,AMT2CHECK,IMPORTFILEID,'||
'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,nvl(CONFIRMED,sysdate),rejectcode,'||
'rejecttext,dateshipped,zoe.orderdtl_line_count(orderid,shipid),'||
'packlistshipdate,edicancelpending,deliveryservice,saturdaydelivery'||
' from orderhdr'||
' where orderstatus = ''9'' and statusupdate >= to_date(''' || in_begdatestr ||
''', ''yyyymmddhh24miss'')' ||
' and statusupdate <  to_date(''' || in_enddatestr || ''', ''yyyymmddhh24miss'') ' ||
' and custid = ''' || rtrim(in_custid) || '''';

cmdSqlCompany := 'select distinct class_to_company_' || rtrim(in_custid) ||
  '.abbrev, class_to_warehouse_' || rtrim(in_custid) || '.abbrev from ' ||
  ' class_to_company_' || rtrim(in_custid) || ',class_to_warehouse_' ||
  rtrim(in_custid) ||
  ' where class_to_company_' || rtrim(in_custid) || '.code = class_to_warehouse_' ||
  rtrim(in_custid) || '.code';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblCompany,12);
  dbms_sql.define_column(curCompany,2,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  while(1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curCompany);
    if cntRows <= 0 then
      Exit;
    end if;
    dbms_sql.column_value(curCompany,1,tblCompany);
    dbms_sql.column_value(curCompany,2,tblWarehouse);
    cmdSql := cmdSql || ' union select 0, 0,''' ||
      rtrim(in_custid) || ''',''O'',sysdate,sysdate,sysdate,' ||
      'null,null,''9'',null,null,null,0,0,0,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,' ||
      '0,0,0,0,0,0,0,null,sysdate,null,sysdate,null,null,null,sysdate,null,null,' ||
      'null,''X'',null,0,null,0,0,0,0,null,null,null,null,null,null,null,null,' ||
      'null,null,null,null,null,null,null,null,null,null,null,null,null,' ||
      'null,0,0,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,null,null,null,null,''' ||
      rtrim(tblcompany) || ''',''' || rtrim(tblwarehouse) ||
      ''',null,null,null,null,null,null,null,null,null,null,null,' ||
      'null,null,null,0,0,0,0,0,0,0,0,0,0,sysdate,0,null,' ||
      'to_date(''' || in_begdatestr || ''', ''yyyymmddhh24miss''), 0, ' ||
      ' sysdate, null, null, null' ||
      ' from dual ';
    cmdSql := cmdSql || ' union select 0, 0,''' ||
      rtrim(in_custid) || ''',''O'',sysdate,sysdate,sysdate,' ||
      'null,null,''9'',null,null,null,0,0,0,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,' ||
      '0,0,0,0,0,0,0,null,sysdate,null,sysdate,null,null,null,sysdate,null,null,' ||
      'null,''H'',null,0,null,0,0,0,0,null,null,null,null,null,null,null,null,' ||
      'null,null,null,null,null,null,null,null,null,null,null,null,null,' ||
      'null,0,0,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,null,null,null,null,''' ||
      rtrim(tblcompany) || ''',''' || rtrim(tblwarehouse) ||
      ''',null,null,null,null,null,null,null,null,null,null,null,' ||
      'null,null,null,0,0,0,0,0,0,0,0,0,0,sysdate,0,null,' ||
      'to_date(''' || in_begdatestr || ''', ''yyyymmddhh24miss''), 0, ' ||
      ' sysdate, null, null, null' ||
      ' from dual ';
  end loop;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view ship_summary_hdr_' || strSuffix ||
  '(custid,company,warehouse) as select custid, hdrpassthruchar05,'||
  'hdrpassthruchar06 from orderconfirmview_' || strSuffix ||
  ' group by custid,hdrpassthruchar05,hdrpassthruchar06';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

tblCompany := 'RG';
cmdSqlCompany := 'select abbrev from class_to_company_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblCompany,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblCompany);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

tblWarehouse := 'RG';
cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblWarehouse);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

cmdSql := 'create view noship_summary_dtl_' || strSuffix ||
  ' (custid,company,warehouse,item,itemdescr,qty) as select ''' ||
  rtrim(in_custid) || ''',''' ||
  rtrim(tblCompany) || ''',''' || rtrim(tblWarehouse) || ''',custitem.item,' ||
  'substr(custitem.descr,1,32),0 ' ||
  'from custitem ' ||
  'where custid = ''' || rtrim(in_custid) || ''' and status = ''ACTV'' ' ||
  'and not exists (select * from orderhdr where statusupdate >= ' ||
  'to_date(''' || in_begdatestr || ''', ''yyyymmddhh24miss'')' ||
  ' and statusupdate <  to_date(''' || in_enddatestr || ''', ''yyyymmddhh24miss'')' ||
  ' and orderstatus = ''9'' ' ||
  ' and custid = ''' || rtrim(in_custid) || ''' ' ||
  ' and hdrpassthruchar05 = ''' || rtrim(tblCompany) || ''' ' ||
  ' and hdrpassthruchar06 = ''' || rtrim(tblWarehouse) || ''' ' ||
  ' and exists (select * from orderdtl ' ||
  ' where orderhdr.orderid = orderdtl.orderid ' ||
  ' and orderhdr.shipid = orderdtl.shipid ' ||
  ' and orderdtl.item = custitem.item))';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view ship_summary_dtl_' || strSuffix ||
  ' (custid,company,warehouse,item,itemdescr,qty) as select h.custid,' ||
  'h.hdrpassthruchar05,h.hdrpassthruchar06,d.item,' ||
  'substr(zit.item_descr(h.custid,d.item),1,255),sum(nvl(d.qtyship,0)) ' ||
  'from orderconfirmview_' || strSuffix || ' h, orderdtl d ' ||
  'where h.orderid = d.orderid and h.shipid = d.shipid ' ||
  ' and h.qtyship != 0 ' ||
  ' group by h.custid, h.hdrpassthruchar05,h.hdrpassthruchar06,d.item,' ||
  'substr(zit.item_descr(h.custid,d.item),1,255) ' ||
  'union select * from noship_summary_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view ship_summary_tot_' || strSuffix ||
  ' (custid,totalseq,company,warehouse,totaltype,ordercount) as select ' ||
  'custid,''A'',hdrpassthruchar05,hdrpassthruchar06,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS''), count(1) - 1' ||
  ' from orderconfirmview_' || strSuffix ||
  ' where substr(reference,1,1) = ''H'' ' ||
  'group by custid,''A'',hdrpassthruchar05,hdrpassthruchar06,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS'') ' ||
  'union select custid,''B'',hdrpassthruchar05,hdrpassthruchar06,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS''),' ||
  'count(1) - 1 from orderconfirmview_' || strSuffix ||
  ' where substr(reference,1,1) != ''H'' ' ||
  'group by custid,''B'',hdrpassthruchar05,hdrpassthruchar06,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS'') ' ||
  'union select custid, ''C'',hdrpassthruchar05,hdrpassthruchar06,'||
  '''TOTAL ORDERS'', count(1) - 2 from orderconfirmview_' || strSuffix ||
  ' group by custid,''C'',hdrpassthruchar05,hdrpassthruchar06,''TOTAL ORDERS''';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view ship_summary_grand_tot_' || strSuffix ||
  ' (custid,company,warehouse,itemcount) as select custid,company,warehouse,'||
  'count(1) from ship_summary_dtl_' || strSuffix ||
  ' group by custid,company,warehouse';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss ' || sqlerrm;
  out_errorno := sqlcode;
end begin_ship_sum;

procedure end_ship_sum
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop VIEW ship_summary_grand_tot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW ship_summary_tot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW ship_summary_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view ship_summary_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view noship_summary_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view orderconfirmview_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_ship_sum;

procedure begin_shipsum
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'SHIPSUM_ORD_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create view shipsum_ord_' || strSuffix ||
  ' (custid, ' ||
  'company,warehouse,orderid,shipid,reference,qty) as ' ||
  'select oh.custid,nvl(cc.abbrev,sp.inventoryclass), ' ||
  'nvl(cw.abbrev,sp.inventoryclass),oh.orderid,oh.shipid, ' ||
  'oh.reference,sum(sp.quantity) ' ||
  'from class_to_company_' || rtrim(in_custid) || ' cc, ' ||
  'class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  'shippingplate sp, orderhdr oh ' ||
  'where oh.orderid = sp.orderid and oh.shipid = sp.shipid ' ||
  'and oh.custid = ''' || rtrim(in_custid) || ''' and oh.orderstatus = ''9'' ' ||
  'and sp.type in (''F'',''P'') and sp.status = ''SH'' ' ||
  'and sp.inventoryclass = cc.code(+) ' ||
  'and sp.inventoryclass = cw.code(+) ' ||
  'and oh.statusupdate >= to_date(''' || in_begdatestr ||
  ''', ''yyyymmddhh24miss'')' ||
  ' and oh.statusupdate <  to_date(''' || in_enddatestr ||
  ''', ''yyyymmddhh24miss'') ' ||
  'group by oh.custid,nvl(cc.abbrev,sp.inventoryclass), ' ||
  'nvl(cw.abbrev,sp.inventoryclass),oh.orderid,oh.shipid,oh.reference ';

cmdSqlCompany := 'select distinct class_to_company_' || rtrim(in_custid) ||
  '.abbrev, class_to_warehouse_' || rtrim(in_custid) || '.abbrev from ' ||
  ' class_to_company_' || rtrim(in_custid) || ',class_to_warehouse_' ||
  rtrim(in_custid) ||
  ' where class_to_company_' || rtrim(in_custid) || '.code = class_to_warehouse_' ||
  rtrim(in_custid) || '.code';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblCompany,12);
  dbms_sql.define_column(curCompany,2,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  while(1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curCompany);
    if cntRows <= 0 then
      Exit;
    end if;
    dbms_sql.column_value(curCompany,1,tblCompany);
    dbms_sql.column_value(curCompany,2,tblWarehouse);
    cmdSql := cmdSql || ' union select ''' || rtrim(in_custid) || ''', ''' ||
      rtrim(tblCompany) || ''',''' || rtrim(tblWarehouse) || ''', 0, 0, ''H'', 0 ' ||
      ' from dual ';
    cmdSql := cmdSql || ' union select ''' || rtrim(in_custid) || ''', ''' ||
      rtrim(tblCompany) || ''',''' || rtrim(tblWarehouse) || ''', 0, 0, ''X'', 0 ' ||
      ' from dual ';
  end loop;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view shipsum_hdr_' || strSuffix ||
  '(custid,company,warehouse) as select custid, company,'||
  'warehouse from shipsum_ord_' || strSuffix ||
  ' group by custid,company,warehouse ';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view shipsum_dtl_' || strSuffix ||
  ' (custid,company,warehouse,item,itemdescr,qty) as ' ||
  'select oh.custid,nvl(cc.abbrev,sp.inventoryclass), ' ||
  'nvl(cw.abbrev,sp.inventoryclass),sp.item, ' ||
  'substr(zit.item_descr(oh.custid,sp.item),1,255), ' ||
  'sum(nvl(sp.quantity,0)) ' ||
  'from class_to_company_' || rtrim(in_custid) || ' cc, ' ||
  'class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  'shippingplate sp, shipsum_ord_' || strSuffix ||
  ' oh ' ||
  'where oh.orderid = sp.orderid and oh.shipid = sp.shipid ' ||
  'and oh.custid = ''' || rtrim(in_custid) || '''' ||
  'and sp.type in (''F'',''P'') and sp.status = ''SH'' ' ||
  'and sp.inventoryclass = cc.code ' ||
  'and sp.inventoryclass = cw.code ' ||
  'and oh.company = cc.abbrev ' ||
  'and oh.warehouse = cw.abbrev ' ||
  'group by oh.custid,nvl(cc.abbrev,sp.inventoryclass), ' ||
  'nvl(cw.abbrev,sp.inventoryclass),sp.item,' ||
  'substr(zit.item_descr(oh.custid,sp.item),1,255) ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view shipsum_tot_' || strSuffix ||
  ' (custid,totalseq,company,warehouse,totaltype,ordercount) as select ' ||
  'custid,''A'',company,warehouse,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS''), count(1) - 1' ||
  ' from shipsum_ord_' || strSuffix ||
  ' where substr(reference,1,1) = ''H'' ' ||
  'group by custid,''A'',company,warehouse,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS'') ' ||
  'union select custid,''B'',company,warehouse,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS''),' ||
  'count(1) - 1 from shipsum_ord_' || strSuffix ||
  ' where substr(reference,1,1) != ''H'' ' ||
  'group by custid,''B'',company,warehouse,' ||
  'decode(substr(reference,1,1),''H'',''WEBBV ORDERS'',''SYKES ORDERS'') ' ||
  'union select custid, ''C'',company,warehouse,'||
  '''TOTAL ORDERS'', count(1) - 2 from shipsum_ord_' || strSuffix ||
  ' group by custid,''C'',company,warehouse,''TOTAL ORDERS''';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view shipsum_grand_tot_' || strSuffix ||
  ' (custid,company,warehouse,itemcount) as select custid,company,warehouse,'||
  'count(1) from shipsum_dtl_' || strSuffix ||
  ' group by custid,company,warehouse';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss ' || sqlerrm;
  out_errorno := sqlcode;
end begin_shipsum;

procedure end_shipsum
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop VIEW shipsum_grand_tot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW shipsum_tot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW shipsum_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipsum_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view shipsum_ord_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_shipsum;

procedure begin_rcptnote
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'RCPTNOTE_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

cmdSql := 'create view rcptnote_hdr_' || strSuffix ||
  ' (custid,company,warehouse,orderid,shipid,receiptdate,' ||
  'vendor,vendordesc,billoflading,carrier,po,ordertype,qtyrcvd,' ||
  'qtyrcvdgood,qtyrcvddmgd) ' ||
  ' as select oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass),oh.orderid,oh.shipid, ' ||
  'oh.statusupdate,oh.shipper,sh.name,oh.billoflading,oh.carrier, ' ||
  'oh.po,oh.ordertype,sum(rc.qtyrcvd),sum(rc.qtyrcvdgood),sum(rc.qtyrcvddmgd) ' ||
  'from class_to_company_' || rtrim(in_custid) || ' cc, ' ||
  'class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  '   shipper sh, orderdtlrcpt rc, orderhdr oh ' ||
  'where oh.orderstatus = ''R'' and oh.orderid = rc.orderid ' ||
  'and oh.shipid = rc.shipid and oh.shipper = sh.shipper(+) ' ||
  'and oh.custid = ''' || rtrim(in_custid) || '''' ||
  'and rc.inventoryclass = cc.code(+) and rc.inventoryclass = cw.code(+) ' ||
  'and oh.statusupdate >= to_date(''' || in_begdatestr ||
  ''', ''yyyymmddhh24miss'')' ||
  ' and oh.statusupdate <  to_date(''' || in_enddatestr ||
  ''', ''yyyymmddhh24miss'') ' ||
  'group by oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass), ' ||
  'oh.orderid,oh.shipid,statusupdate, ' ||
  'oh.shipper,sh.name,oh.billoflading,oh.carrier,oh.po,oh.ordertype ';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view rcptnote_dtl_' || strSuffix ||
  ' (custid,company,warehouse,orderid,shipid,receiptdate,' ||
  'linenumber,linenumberstr,item,lotnumber,uom,qtyrcvd,' ||
  'cubercvd,qtyrcvdgood,cubercvdgood,qtyrcvddmgd,cubercvddmgd,qtyorder) as select oh.custid,' ||
  'nvl(cc.abbrev,rc.inventoryclass),nvl(cw.abbrev,rc.inventoryclass), ' ||
  'oh.orderid,oh.shipid,oh.receiptdate, ' ||
  'zoe.line_number(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot), ' ||
  'substr(zoe.line_number_str(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),1,6), ' ||
  'rc.item,rc.lotnumber,rc.uom,sum(rc.qtyrcvd), ' ||
  'sum(rc.qtyrcvd) * zci.item_cube(oh.custid,rc.item,rc.uom), ' ||
  'sum(rc.qtyrcvdgood), ' ||
  'sum(rc.qtyrcvdgood) * zci.item_cube(oh.custid,rc.item,rc.uom), ' ||
  'sum(rc.qtyrcvddmgd), ' ||
  'sum(rc.qtyrcvddmgd) * zci.item_cube(oh.custid,rc.item,rc.uom), ' ||
  'sum(rc.qtyrcvd) from class_to_company_' || rtrim(in_custid) ||
  ' cc, class_to_warehouse_' || rtrim(in_custid) || ' cw, ' ||
  'orderdtlrcpt rc, rcptnote_hdr_' || strSuffix || ' oh where oh.orderid = rc.orderid ' ||
  'and oh.shipid = rc.shipid ' ||
  'and rc.inventoryclass = cc.code(+) and rc.inventoryclass = cw.code(+) ' ||
  'group by oh.custid,nvl(cc.abbrev,rc.inventoryclass), ' ||
  'nvl(cw.abbrev,rc.inventoryclass),oh.orderid,oh.shipid,oh.receiptdate, ' ||
  'zoe.line_number(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot), ' ||
  'substr(zoe.line_number_str(oh.orderid,oh.shipid,rc.orderitem,rc.orderlot),1,6), ' ||
  'rc.item,rc.lotnumber,rc.uom ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
en loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbrn ' || sqlerrm;
  out_errorno := sqlcode;
end begin_rcptnote;

procedure end_rcptnote
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop view rcptnote_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW rcptnote_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimern ' || sqlerrm;
  out_errorno := sqlcode;
end end_rcptnote;

procedure begin_stockstat
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_alias_descr IN varchar2
,in_exclude_zero_bal_yn IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;

begin

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'STOCKSTAT_NOLIP_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

tblCompany := 'RG';
cmdSqlCompany := 'select abbrev from class_to_company_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblCompany,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblCompany);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

tblWarehouse := 'RG';
cmdSqlCompany := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''RG'' ';
begin
  curCompany := dbms_sql.open_cursor;
  dbms_sql.parse(curCompany, cmdSqlCompany, dbms_sql.native);
  dbms_sql.define_column(curCompany,1,tblWarehouse,12);
  cntRows := dbms_sql.execute(curCompany);
  cntRows := dbms_sql.fetch_rows(curCompany);
  if cntRows > 0 then
    dbms_sql.column_value(curCompany,1,tblWarehouse);
  end if;
  dbms_sql.close_cursor(curCompany);
exception when others then
  dbms_sql.close_cursor(curCompany);
end;

if upper(in_exclude_zero_bal_yn) = 'Y' then
  cmdSql := 'create view stockstat_nolip_' || strSuffix ||
   ' (custid,company,warehouse,item,inventoryclass,invstatus,status,' ||
   'lipcount,qty) as select distinct custitem.custid, ''' || tblCompany ||
   ''',''' || tblWarehouse || ''',custitem.item,''RG'',''AV'',''A'',0,0 ' ||
   'from custitem where custid = ''xoxo''';
else
  cmdSql := 'create view stockstat_nolip_' || strSuffix ||
   ' (custid,company,warehouse,item,inventoryclass,invstatus,status,' ||
   'lipcount,qty) as select distinct custitem.custid, ''' || tblCompany ||
   ''',''' || tblWarehouse || ''',custitem.item,''RG'',''AV'',''A'',0,0 ' ||
   'from custitem where custid = ''' || rtrim(in_custid) || '''' ||
   ' and custitem.status = ''ACTV'' ' ||
   ' and custitem.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
   ' and not exists (select * from custitemtot ' ||
   ' where custitem.custid = custitemtot.custid ' ||
   'and custitem.item = custitemtot.item ' ||
   'and custitem.inventoryclass = ''RG'' ' ||
   'and custitemtot.status not in (''D'',''P'')) ';
end if;

curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_nolot_' || strSuffix ||
 ' (custid,company,warehouse,item,inventoryclass,invstatus,status ' ||
 ',lipcount,qty) as select custid ' ||
 ',nvl(class_to_company_' || rtrim(in_custid) || '.abbrev,''' || tblCompany || ''') ' ||
 ',nvl(class_to_warehouse_' || rtrim(in_custid) || '.abbrev,''' || tblWarehouse || ''') ' ||
 ',item,inventoryclass,invstatus,status,sum(lipcount),sum(qty) ' ||
 ' from class_to_company_' || rtrim(in_custid) || ', class_to_warehouse_' ||
 rtrim(in_custid) || ', custitemtot ' ||
 ' where custid = ''' || rtrim(in_custid) || '''' ||
 ' and inventoryclass = class_to_company_' || rtrim(in_custid) || '.code(+) ' ||
 ' and inventoryclass = class_to_warehouse_' || rtrim(in_custid) || '.code(+) ' ||
 ' and custitemtot.item not in (''UNKNOWN'',''RETURNS'',''x'') ' ||
 ' and custitemtot.status not in (''D'',''P'') ' ||
 ' group by custid,nvl(class_to_company_' || rtrim(in_custid) ||'.abbrev,''' ||
 tblCompany || '''), ' ||
 'nvl(class_to_warehouse_' || rtrim(in_custid) || '.abbrev,''' ||
 tblWarehouse || '''),item, ' ||
 'inventoryclass,invstatus,status ' ||
 ' union select * from stockstat_nolip_' || strSuffix;
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_file_hdr_' || strSuffix ||
 ' (custid,company,warehouse,min_warehouse,max_warehouse) as ' ||
 ' select distinct ''' || rtrim(in_custid) || ''',cc.abbrev,cw.abbrev, ' ||
 'cw.abbrev,cw.abbrev from class_to_company_' || rtrim(in_custid) ||
 ' cc, class_to_warehouse_' || rtrim(in_custid) || ' cw where cc.code = cw.code ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_item_hdr_' || strSuffix ||
 ' (custid,company,warehouse) as select distinct custid, company, warehouse ' ||
 'from stockstat_file_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_class_' || strSuffix ||
  ' (custid,company,warehouse,item,inventoryclass,qtyonhand,qtyavail,qtynotavail) ' ||
  ' as select custid,company,warehouse,item,inventoryclass,sum(qty), ' ||
  'zit.alloc_qty_class(custid,item,null,inventoryclass), ' ||
  'zit.not_avail_qty(custid,item,null,inventoryclass) ' ||
  'from stockstat_nolot_' || strSuffix ||
  ' where zci.custitem_sign(status) > 0 and invstatus != ''SU'' ' ||
  'group by custid,company,warehouse,item,inventoryclass ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_item_' || strSuffix ||
 ' (custid,company,warehouse,item,inventoryclass,qtyonhand,' ||
 'qtyalloc,qtyavail,qtynotavail) as select custid,company,warehouse,'||
 'item,inventoryclass,sum(qtyonhand),sum(qtyonhand - qtyavail - qtynotavail),'||
 'sum(qtyavail),sum(qtynotavail) from stockstat_class_' || strSuffix ||
 ' group by custid,company,warehouse,item,inventoryclass ';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_item_dtl_' || strSuffix ||
 ' (custid,company,warehouse,item,itemalias,qtyonhand,qtyalloc,qtyavail,qtynotavail) ' ||
 ' as select custid,company,warehouse,item,' ||
 ' substr(zit.alias_by_descr(custid,item,''' ||
 'rtrim(upper(in_alias_descr)) || ''),1,20),' ||
 ' zit.no_neg(sum(qtyonhand)),'||
 ' zit.no_neg(sum(qtyalloc)),zit.no_neg(sum(qtyavail)),zit.no_neg(sum(qtynotavail)) ' ||
 'from stockstat_item_' || strSuffix ||
 ' group by custid,company,warehouse,item,' ||
 ' substr(zit.alias_by_descr(custid,item,''' ||
 'rtrim(upper(in_alias_descr)) || ''),1,20)';
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_item_trl_' || strSuffix ||
 ' (custid,company,warehouse,dtlcount) as select custid, company,'||
 'warehouse, 0 from stockstat_file_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'create view stockstat_file_trl_' || strSuffix ||
 ' (custid,company,warehouse,sumcount) as select custid,company,'||
 ' warehouse, 0 from stockstat_file_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
/*
cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;
*/
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss ' || sqlerrm;
  out_errorno := sqlcode;
end begin_stockstat;

procedure end_stockstat
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := rtrim(upper(in_custid)) || in_viewsuffix;

cmdSql := 'drop VIEW stockstat_file_trl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_item_trl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_item_dtl_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_item_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_class_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_item_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop VIEW stockstat_file_hdr_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view stockstat_nolot_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

cmdSql := 'drop view stockstat_nolip_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_stockstat;

procedure begin_order_attach_import
(in_custid IN varchar2
,in_short_filename IN varchar2
,in_filename IN varchar2
,in_order_attach_dir IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCU is
  select custid
    from customer_aux
   where custid = in_custid;
CU curCU%rowtype;

l_attach_filepath customer_aux.order_attach_default_directory%type;
l_order_count pls_integer;
l_pos pls_integer;
l_rowcount pls_integer;
l_msg appmsgs.msgtext%type;
l_reference orderhdr.reference%type;

strReference varchar(100);

begin

out_msg := '';
out_errorno := 0;

CU := null;
open curCU;
fetch curCU into CU;
close curCU;
if CU.custid is null then
   out_msg := 'Invalid Customer ID: ' || in_custid;
   out_errorno := -1;
   zms.log_autonomous_msg('ImpOrdAttch', null, null,
     out_msg || chr(13) || in_filename, 'E', 'ImpOrdAttch', l_msg);
   return;
end if;

l_attach_filepath := trim(in_order_attach_dir);
if substr(l_attach_filepath,length(l_attach_filepath),1) <> '\' then
  l_attach_filepath := l_attach_filepath || '\';
end if;
l_attach_filepath := l_attach_filepath || in_short_filename;
l_pos := instr(in_short_filename, '.');
if l_pos <> 0 then
  strReference := substr(in_short_filename,1,l_pos-1);
else
  strReference := in_short_filename;
end if;

l_pos := instr(strReference, '_');
if l_pos <> 0 then
  strReference := substr(strReference,1,l_pos-1);
end if;

if length(strReference) < 21 then
  l_reference := strReference;
else
  l_reference := substr(strReference,1,20);
end if;

l_order_count := 0;

for oh in (select orderid
             from orderhdr
            where custid = in_custid
              and reference = l_reference)
loop

  l_order_count := l_order_count + 1;

  l_rowcount := 0;
  select count(1)
    into l_rowcount
    from orderattach
   where orderid = oh.orderid
     and upper(filepath) = upper(l_attach_filepath);

  if l_rowcount = 0 then
    insert into orderattach
      (orderid,filepath,lastuser,lastupdate)
    values
      (oh.orderid,l_attach_filepath,'ImpOrdAttch',sysdate);
  else
    update orderattach
       set lastuser = 'ImpOrdAttch',
           lastupdate = sysdate
     where orderid = oh.orderid
       and upper(filepath) = upper(l_attach_filepath);
  end if;

end loop;

if l_order_count = 0 then
 out_msg := 'No customer orders found: ' || in_custid;
 out_errorno := -2;
 zms.log_autonomous_msg('ImpOrdAttch', null, in_custid,
   out_msg || chr(13) || in_filename, 'E', 'ImpOrdAttch', l_msg);
 return;
end if;

exception when others then
  out_msg := 'boai ' || sqlerrm;
  out_errorno := sqlcode;
end begin_order_attach_import;

procedure begin_stockstat_gt
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_exclude_zero IN VARCHAR2
,in_exclude_open_receipts IN VARCHAR2
,in_partner_edi_code IN varchar2
,in_sender_edi_code IN varchar2
,in_app_sender_code IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

mark varchar2(20);

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
cmdSqlPlate varchar2(20000);
TYPE cur_type is REF CURSOR;
cpl cur_type;

strSuffix varchar2(32);
viewcount integer;

strDate varchar2(8);
strTime varchar2(8);
strBatch varchar2(12);
strDebugYN char(1);
strName varchar2(40);
strDescr varchar2(25);
stritem varchar2(50);
strProductGroup varchar2(4);
strRateGroup varchar2(10);
strLineNumber varchar2(3);
iQty integer;
iCnt integer;
nWeight number(17,8);
lQty varchar2(11);
lQtyAvailable varchar2(11);
lHoldQty varchar2(11);
lHoldFlag char(1);
lStatAbbrev varchar2(12);
sSource char(1);
l_prevent_suspense_stock_stat customer_aux.prevent_suspense_stock_status%type;
cursor c_plate
is
  select p.*
    from plate p, orderhdr o
   where p.custid = in_custid
     and p.facility = in_facility
     and p.type = 'PA'
     and p.item not in ('6005','9988','9989','9990','9981','9982')
     and p.invstatus != 'SU'
     and p.orderid = o.orderid(+)
     and p.shipid = o.shipid(+)
     and nvl(o.orderstatus,'R') = 'R'
order by item, lpid;

PL c_plate%rowtype;

cursor c_odtl(in_orderid number, in_shipid number, in_item varchar2)
is
  select to_char(nvl(dtlpassthrunum10,0), 'FM099')
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item;
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin
if out_errorno = -12345 then
   strDebugYN := 'Y';
else
   strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'STSTATGT_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

begin
   select nvl(prevent_suspense_stock_status,'N')
  into l_prevent_suspense_stock_stat
     from customer_aux
    where custid = rtrim(in_custid);
exception when others then
  l_prevent_suspense_stock_stat := null;
end;
if l_prevent_suspense_stock_stat is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

if l_prevent_suspense_stock_stat = 'Y' then
  select count(1)
   into cntRows
   from custitemtot
   where custid = in_custid
    and invstatus = 'SU';

if cntRows != 0 then
  out_errorno := -132;
    zms.log_autonomous_msg('NOSUSTOCKEXP', null, rtrim(in_custid),
                           'Customer ' || rtrim(in_custid) ||
                           ' has items in SUSPENSE--the stock status export was not produced',
                     'W', 'IMPEXP', out_msg);
  out_msg := 'There are items on suspense for customer '  || in_custid;
  return;
  end if;
end if;
select to_char(sysdate,'YYYYMMDD') into strDate from dual;
select to_char(sysdate,'HHMMSS')||'00' into strTime from dual;
strBatch := strDate || substr(strTime,1,4);

cmdsql := 'create table ststatgt_hdr_' || strsuffix  ||
'(custid varchar2(10) not null, record_type varchar2(1), transaction_set varchar2(3), ' ||
' partner_edi_code varchar2(15), date_created varchar2(8), time_created varchar2(8), '||
' depositor_code varchar2(12), batch_reference varchar2(35), other_reference varchar2(35), '||
' sender_edi_code varchar2(15), app_sender_code varchar2(12), app_recvr_code varchar2(12))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
debugmsg('insert hdr');
cmdSql := 'insert into ststatgt_hdr_' || strSuffix ||
'(custid, record_type, transaction_set, partner_edi_code, date_created, time_created, '||
' depositor_code, batch_reference, other_reference, sender_edi_code, app_sender_code, '||
' app_recvr_code) ' ||
' values ( ''' || in_custid || ''', ''I'', ''846'', '''|| in_partner_edi_code || ''', ''' ||
          strDate || ''', ''' || strTime ||''', null, '''|| strBatch ||''', ' ||
         'null, ''' || in_sender_edi_code || ''' , ''' || in_app_sender_code || ''', null)';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

begin
  select name into strName
     from customer
     where custid = in_custid;
exception when others then
   strName := null;
end;

cmdsql := 'create table ststatgt_rpt_' || strsuffix  ||
'(custid varchar2(10) not null, record_type varchar2(1), '||
 'date_created varchar2(8), name varchar2(40))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
debugmsg('insert rpt');
cmdSql := 'insert into ststatgt_rpt_' || strSuffix ||
'(custid, record_type, date_created, name) '||
' values ( ''' || in_custid || ''', ''H'', ''' || strDate || ''', ''' || strName ||''')';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
debugmsg('create dtl');
cmdsql := 'create table ststatgt_dtl_' || strsuffix  ||
'(record_type char(1), custid varchar2(10) not null, '||
' item varchar2(50), descr varchar2(25), lotnumber varchar2(30), serialnumber varchar2(30), '||
' facility varchar2(3), location varchar2(10), quantity varchar2(11), unitofmeasure varchar2(4), '||
' qtyonholddetail varchar2(11), qtydamaged varchar2(11), qtyonholdlot varchar2(11), '||
' weight varchar2(11), productgroup varchar2(4), creationdate varchar2(8), '||
' source char(1), document varchar2(9), sequence varchar2(3), linenumber varchar2(3), manufacturedate varchar2(8), '||
' qtyavailable varchar2(11), lpid varchar2(15), rategroup varchar2(5), useritem2 varchar2(20), '||
' holdflag char(1), statabbrev varchar2(12), lpidlast6 varchar2(6), lpidlast7 varchar2(7), ' ||
' qty integer, numWeight number(17,8))';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);
debugmsg('start PL');
cmdSqlPlate := ' select p.* ' ||
                 ' from plate p, orderhdr o ' ||
                ' where p.custid = ''' || in_custid ||'''';
if nvl(in_facility,'ALL') <> 'ALL'  then
   cmdSqlPlate :=  cmdSqlPlate || ' and p.facility = ''' || in_facility ||'''';
end if;
cmdSqlPlate :=  cmdSqlPlate || ' and p.type = ''PA''' ||
                               ' and p.item not in (''6005'',''9988'',''9989'',''9990'',''9981'',''9982'') '||
                               ' and p.invstatus != ''SU''' ||
                               ' and p.orderid = o.orderid(+) ' ||
                               ' and p.shipid = o.shipid(+) ' ||
                               ' and nvl(o.orderstatus,''R'') = ''R''' ||
                               ' order by item, lpid ';
open cpl for cmdSqlPlate;
loop
   fetch cpl into PL;
   exit when cpl%notfound;
   begin
      select substr(descr,1,25), rategroup, productgroup
        into strDescr, strRateGroup, strProductGroup
        from custitem
        where custid = PL.custid
          and item = PL.item;
   exception when no_data_found then
      strDescr := null;
   end;
   nWeight := PL.weight;
   select count(1) into iCnt
     from shippingplate
     where fromlpid = PL.lpid
       and type = 'P'
       and facility = in_facility
       and status in ('L','S');
   if iCnt > 0 then
      select sum(quantity) into iQty
        from shippingplate
        where fromlpid = PL.lpid
          and type = 'P'
          and facility = in_facility
          and status in ('L','S');
      iQty := iQty + PL.quantity;
      nWeight := PL.weight/PL.quantity * iQty;
   else
      iQty := PL.quantity;
   end if;
   if PL.invstatus = 'AV' then
      lQty := '+' || to_char(iQty, 'FM0999999') || '.00';
      lHoldQty := '+0000000.00';
      lQtyAvailable := lQty;
      --lQtyAvailable := '+' || to_char(PL.quantity, 'FM0999999') || '.00';
      lHoldFlag := null;
      lStatAbbrev := null;
   else
      lHoldQty := '+' || to_char(iQty, 'FM0999999') || '.00';
      lQty := lHoldQty;
      lQtyAvailable := '+0000000.00';
      lHoldFlag := 'H';
      begin
          select abbrev into lStatAbbrev
             from inventorystatus
             where code = PL.invstatus;
      exception when no_data_found then
         lStatAbbrev := null;
      end;
   end if;
   if PL.orderid is not null then
      open c_odtl(PL.orderid, PL.shipid, PL.item);
      fetch c_odtl into strLineNumber;
      if c_odtl%notfound then
         strLineNumber := '000';
      end if;
      close c_odtl;
      sSource := 'R';
   else
      sSource := 'A';
      strLineNumber := '000';
   end if;
   cmdSql := 'insert into ststatgt_dtl_' || strSuffix ||
    '(record_type,custid,item,descr,lotnumber,serialnumber,facility,location,'||
    'quantity,unitofmeasure,qtyonholddetail,qtydamaged,qtyonholdlot,weight, '||
    'productgroup,creationdate,source,document, sequence, linenumber,manufacturedate, '||
    ' qtyavailable,lpid, rategroup, useritem2, holdflag, statabbrev, lpidlast6, lpidlast7, ' ||
    ' qty, numWeight) '||
    ' values (''L'',''' || in_custid || ''', ''' || PL.item ||''','''|| strDescr || ''',''' ||
             PL.lotnumber || ''',''' || PL.serialnumber || ''',''' || PL.facility || ''',''' ||
             PL.location || ''', ''' || lQty || ''',''' || PL.unitofmeasure || ''',''' ||
             lHoldQty || ''',''+0000000.00'',''+0000000.00'',''' ||
             to_char(nWeight, 'FM099999') || '.00' || ''',''' ||
             strProductGroup || ''',''' || to_char(PL.creationdate,'YYYYMMDD') || ''','''||
             sSource || ''',''' || to_char(PL.orderid,'FM099999') || ''',''' ||
             to_char(PL.shipid,'FM099') ||''','''  ||strLineNumber ||
             ''',''' || to_char(PL.manufacturedate,'YYYYMMDD') || ''',''' ||
             lQtyAvailable || ''',''' || PL.lpid || ''',''' || substr(strRateGroup,1,5) ||
             ''','''||PL.useritem2 || ''','''|| lHoldFlag || ''','''|| lStatAbbrev ||
             ''','''|| zim7.lpid_last6(PL.lpid) || ''',''' || zim7.lpid_last7(PL.lpid) || ''',' ||
             lQty || ',' ||nWeight || ')';
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
end loop;

debugmsg('facility ');
cmdSql := 'create or replace view ststatgt_fac_' || strSuffix ||
  ' (custid, facility) as ' ||
  ' select distinct custid, facility ' ||
  '  from ststatgt_dtl_' || strSuffix;
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('mbr');
cmdSql := 'create or replace view ststatgt_mbr_' || strSuffix ||
   '(custid, facility, lotnumber,lpid, item, weight, qty) as '||
    'select custid, facility, '||
           '''"'' || rtrim(lotnumber) || ''"'', '||
           '''"'' || lpid || ''"'', '||
           '''"'' || rtrim(item) ||''"'', numweight, qty '||
    'from ststatgt_dtl_' || strSuffix;
debugmsg(cmdSql);
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbss '||mark||':' || sqlerrm;
  out_errorno := sqlcode;
end begin_stockstat_gt;


procedure end_stockstat_gt
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

begin
   cmdSql := 'drop view ststatgt_fac_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop view ststatgt_mbr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table ststatgt_dtl_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table ststatgt_rpt_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

begin
   cmdSql := 'drop table ststatgt_hdr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_stockstat_gt;


procedure begin_stockstat_ks
(in_custid IN varchar2
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_facility IN varchar2
,in_freezer_id IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is


cntRows integer;
cmdSql varchar2(2000);
cmdSqlPlate varchar2(2000);
TYPE cur_type is REF CURSOR;
cpl cur_type;
curFunc integer;

strSuffix varchar2(32);
viewcount integer;

strDescr varchar2(60);
strDate varchar2(8);
strTime varchar2(4);
strDebugYN char(1);
strFreezerID varchar2(8);
nWeight number(17,8);
iCnt integer;
iQty integer;
lQty varchar2(11);
l_prevent_suspense_stock_stat customer_aux.prevent_suspense_stock_status%type;

cursor c_plate
is
  select p.*
    from plate p, orderhdr o
   where p.custid = in_custid
     and p.facility = in_facility
     and p.type = 'PA'
     and p.invstatus != 'SU'
     and p.orderid = o.orderid(+)
     and p.shipid = o.shipid(+)
     and nvl(o.orderstatus,'R') = 'R'
order by item, lpid;

PL c_plate%rowtype;

cursor c_odtl(in_orderid number, in_shipid number, in_item varchar2)
is
  select to_char(nvl(dtlpassthrunum10,0), 'FM099')
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item;
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin
if out_errorno = -12345 then
   strDebugYN := 'Y';
else
   strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

viewcount := 1;
while(1=1)
loop
  strSuffix := rtrim(upper(in_custid)) || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'STSTATKS_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

begin
   select nvl(prevent_suspense_stock_status,'N')
     into l_prevent_suspense_stock_stat
     from customer_aux
    where custid = rtrim(in_custid);
exception when others then
  l_prevent_suspense_stock_stat := null;
end;
if l_prevent_suspense_stock_stat is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

if l_prevent_suspense_stock_stat = 'Y' then
  select count(1)
   into cntRows
   from custitemtot
   where custid = in_custid
    and invstatus = 'SU';
  if cntRows != 0 then
    out_errorno := -132;
    zms.log_autonomous_msg('NOSUSTOCKEXP', null, rtrim(in_custid),
                           'Customer ' || rtrim(in_custid) ||
                           ' has items in SUSPENSE--the stock status export was not produced',
                     'W', 'IMPEXP', out_msg);
   out_msg := 'There are items on suspense for customer '  || in_custid;
   return;
  end if;
end if;

select to_char(sysdate,'MMDDYYYY') into strDate from dual;
select to_char(sysdate,'HHMM') into strTime from dual;

cmdsql := 'create table ststatks_hdr_' || strsuffix  ||
'(custid varchar2(10) not null, date_created varchar2(8), time_created varchar2(4), '||
' freezer_id varchar2(8), item varchar2(50), descr varchar2(40), lpid varchar2(15), '||
' quantity number(15), uom varchar2(3), facility varchar2(3))';
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('start PL');
cmdSqlPlate := ' select p.* ' ||
                 ' from plate p, orderhdr o ' ||
                ' where p.custid = ''' || in_custid ||'''';
if nvl(in_facility,'ALL') <> 'ALL'  then
   cmdSqlPlate :=  cmdSqlPlate || ' and p.facility = ''' || in_facility ||'''';
end if;
cmdSqlPlate :=  cmdSqlPlate || ' and p.type = ''PA''' ||
                               ' and p.invstatus != ''SU''' ||
                               ' and p.orderid = o.orderid(+) ' ||
                               ' and p.shipid = o.shipid(+) ' ||
                               ' and nvl(o.orderstatus,''R'') = ''R''' ||
                               ' order by item, lpid ';
debugmsg(cmdSqlPlate);
open cpl for cmdSqlPlate;
loop
   fetch cpl into PL;
   exit when cpl%notfound;
   begin
      select descr into strDescr
        from custitem
        where custid = PL.custid
          and item = PL.item;
   exception when no_data_found then
      strDescr := null;
   end;
   nWeight := PL.weight;
   select count(1) into iCnt
     from shippingplate
     where fromlpid = PL.lpid
       and type = 'P'
       and facility = in_facility
       and status in ('L','S');
   if iCnt > 0 then
      select sum(quantity) into iQty
        from shippingplate
        where fromlpid = PL.lpid
          and type = 'P'
          and facility = in_facility
          and status in ('L','S');
      iQty := iQty + PL.quantity;
      nWeight := PL.weight/PL.quantity * iQty;
   else
      iQty := PL.quantity;
   end if;
   cmdSql := 'insert into ststatks_hdr_' || strSuffix ||
             '(custid, date_created, time_created, '||
             ' freezer_id, item, descr, lpid, '||
             ' quantity, uom, facility )' ||
             ' values (''' || in_custid || ''', ''' || strDate || ''', ''' || strTime ||
                       ''', ''' || strFreezerId || ''', ''' || PL.item ||''','''|| strDescr ||
                       ''',''' || PL.lpid || ''',' || trunc(nvl(PL.weight,0)) || ', ''LBS'',''' ||
                       PL.facility || ''')';
   debugmsg(cmdSql);
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
end loop;

out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbssks' ||':' || sqlerrm;
  out_errorno := sqlcode;
end begin_stockstat_ks;


procedure end_stockstat_ks
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;


begin
   cmdSql := 'drop table ststatks_hdr_' || strSuffix;
   curFunc := dbms_sql.open_cursor;
   dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
   cntRows := dbms_sql.execute(curFunc);
   dbms_sql.close_cursor(curFunc);
exception when others then
   null;
end;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimess ' || sqlerrm;
  out_errorno := sqlcode;
end end_stockstat_ks;


procedure begin_ordstat870
(in_custid IN varchar2
,in_loadno IN number
,in_orderid IN number
,in_shipid IN number
,in_begdatestr IN varchar2
,in_enddatestr IN varchar2
,in_bol_tracking_yn IN varchar2
,in_shipment_column IN varchar2
,in_aux_shipment_column IN varchar2
,in_masterbol_column IN varchar2
,in_track_separator IN varchar2
,in_force_estdelivery_yn IN varchar2
,in_estdelivery_validation_tbl in varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn,
    sipconsigneematchfield
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strDebugYN char(1);
curCompany integer;
cmdSqlCompany varchar2(255);
tblCompany varchar2(12);
tblWarehouse varchar2(12);
strSuffix varchar2(32);
viewcount integer;
l_condition varchar2(255);
l_carton_uom varchar2(4);
procedure debugmsg(in_text varchar2) is

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid Customer Code';
  return;
end if;

viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_views
   where view_name = 'ORD_STAT_870_HDR_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

  l_condition := null;

  if in_orderid != 0 then
     l_condition := ' and oh.orderid = '||to_char(in_orderid)
                 || ' and oh.shipid = '||to_char(in_shipid)
                 || ' ';
  elsif in_loadno != 0 then
     l_condition := ' and oh.loadno = '||to_char(in_loadno)
                 || ' ';
  elsif in_begdatestr is not null then
     l_condition :=  ' and oh.statusupdate >= to_date(''' || in_begdatestr
                 || ''', ''yyyymmddhh24miss'')'
                 ||  ' and oh.statusupdate <  to_date(''' || in_enddatestr
                 || ''', ''yyyymmddhh24miss'') ';
  end if;

  if l_condition is null then
     out_errorno := -2;
     out_msg := 'Invalid Selection Criteria ';
     return;
  end if;

  l_condition := l_condition || ' and oh.custid = '''||in_custid||'''';

  debugmsg('Condition = '||l_condition);


  -- Create header view
cmdSql := 'create view ord_stat_870_hdr_' || strSuffix ||
  ' (custid,company,warehouse,loadno,orderid,shipid,reference,trackingno,'||
  'dateshipped,commitdate,shipviacode,lbs,kgs,gms,ozs,shipticket,height,'||
  'width,length,shiptoidcode,'||
  'shiptoname,shiptocontact,shiptoaddr1,shiptoaddr2,'||
  'shiptocity,shiptostate,shiptopostalcode,shiptocountrycode,shiptophone,'||
  'carrier,carrier_name,packlistshipdate,routing,shiptype,shipterms,reportingcode,'||
  'depositororder,po,deliverydate,estdelivery,billoflading,prono,masterbol,'||
  'splitshipno,invoicedate,effectivedate,totalunits,totalweight,uomweight,'||
  'totalvolume,uomvolume,ladingqty,uom,warehouse_name,warehouse_id,'||
  'depositor_name,depositor_id,'||
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
  'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
  'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
  'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
  'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,'||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,'||
  'trailer,seal,palletcount,freightcost,lateshipreason,carrier_del_serv, ' ||
  'shippingcost, prono_or_all_trackingnos, shipfrom_addr1, shipfrom_addr2,' ||
  'shipfrom_city, shipfrom_state, shipfrom_postalcode, invoicenumber810, '||
  'invoiceamount810, vicsbolnumber, scac, delivery_requested, authorizationnbr, link_shipment, ' ||
  'link_aux_shipment, orderstatus )'||
  'as select ' ||
  'oh.custid,'' '','' '',oh.loadno,oh.orderid,oh.shipid, oh.reference,';
if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid)))))),';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid)))),';
end if;
cmdSql := cmdSql ||
  'oh.statusupdate,oh.shipdate,nvl(deliveryservice,''OTHR''),'||
  'zim7.sum_shipping_weight(orderid,shipid),'||
  'zim7.sum_shipping_weight(orderid,shipid) / 2.2046,'||
  'zim7.sum_shipping_weight(orderid,shipid) / .0022046,'||
  'zim7.sum_shipping_weight(orderid,shipid) * 16,'||
  'substr(zoe.max_shipping_container(orderid,shipid),1,15),'||
  'zoe.cartontype_height(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_width(zoe.max_cartontype(orderid,shipid)),'||
  'zoe.cartontype_length(zoe.max_cartontype(orderid,shipid)),'||
  'oh.shipto,'||
  'decode(CN.consignee,null,shiptoname,CN.name),'||
  'decode(CN.consignee,null,shiptocontact,CN.contact),'||
  'decode(CN.consignee,null,shiptoaddr1,CN.addr1),'||
  'decode(CN.consignee,null,shiptoaddr2,CN.addr2),'||
  'decode(CN.consignee,null,shiptocity,CN.city),'||
  'decode(CN.consignee,null,shiptostate,CN.state),'||
  'decode(CN.consignee,null,shiptopostalcode,CN.postalcode),'||
  'decode(CN.consignee,null,shiptocountrycode,CN.countrycode),'||
  'decode(CN.consignee,null,shiptophone,CN.phone),'||
  'oh.carrier,ca.name,'||
  '''  '',oh.hdrpassthruchar06,oh.shiptype,oh.shipterms,''A'', oh.reference,';
cmdSql := cmdSql || ' oh.po,oh.hdrpassthruchar07,';

if nvl(in_estdelivery_validation_tbl,'(none)') != '(none)' then
   cmdSql := cmdSql || 'zim7.facility_arrival_date(oh.dateshipped,oh.hdrpassthruchar12,''' || in_estdelivery_validation_tbl || '''),';
else
   if nvl(in_force_estdelivery_yn,'N') = 'Y' then
      cmdSql := cmdSql || 'trunc(oh.dateshipped + 5),';
   else
      cmdSql := cmdSql || 'oh.arrivaldate,';
   end if;
end if;
cmdSql := cmdSql ||
  'decode(nvl(oh.loadno,0),0,to_char(oh.orderid)||''-''||to_char(oh.shipid),'||
  'nvl(oh.billoflading,nvl(L.billoflading,to_char(oh.orderid)||''-''||to_char(oh.shipid)))),'||
  'nvl(oh.prono,L.prono),';
  if nvl(in_masterbol_column,'(none)') <> '(none)' then
     cmdSql := cmdSql || 'nvl(' || in_masterbol_column ||', decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null)),';
  else
     cmdSql := cmdSql || 'decode(zim7.load_orders(L.loadno), ''Y'',L.loadno,null),'; --masterbol
  end if;
  cmdSql := cmdSql || 'decode(zim7.split_shipment(oh.custid, oh.reference),''Y'',oh.reference,null),'|| --splitshipno
  'oh.dateshipped,oh.dateshipped,oh.qtyship,'|| --invoicedate, effectivedate, totalunits
  'zim7.sum_shipping_weight(orderid,shipid),''LB'',oh.cubeship,''CF'',ordercheckview_cartons(oh.orderid, oh.shipid),''CT'','||--totalweight, uomweight, totalvolume,uomvolume,ladingqty, uom
  'F.name,F.facility,C.name,'' '','|| --warehousename, warehouseid, depositorname, depositorid
  'HDRPASSTHRUCHAR01,HDRPASSTHRUCHAR02,HDRPASSTHRUCHAR03,HDRPASSTHRUCHAR04,'||
  'HDRPASSTHRUCHAR05,HDRPASSTHRUCHAR06,HDRPASSTHRUCHAR07,HDRPASSTHRUCHAR08,'||
  'HDRPASSTHRUCHAR09,HDRPASSTHRUCHAR10,HDRPASSTHRUCHAR11,HDRPASSTHRUCHAR12,'||
  'HDRPASSTHRUCHAR13,HDRPASSTHRUCHAR14,HDRPASSTHRUCHAR15,HDRPASSTHRUCHAR16,'||
  'HDRPASSTHRUCHAR17,HDRPASSTHRUCHAR18,HDRPASSTHRUCHAR19,HDRPASSTHRUCHAR20,'||
  'HDRPASSTHRUCHAR21,HDRPASSTHRUCHAR22,HDRPASSTHRUCHAR23,HDRPASSTHRUCHAR24,'||
  'HDRPASSTHRUCHAR25,HDRPASSTHRUCHAR26,HDRPASSTHRUCHAR27,HDRPASSTHRUCHAR28,'||
  'HDRPASSTHRUCHAR29,HDRPASSTHRUCHAR30,HDRPASSTHRUCHAR31,HDRPASSTHRUCHAR32,'||
  'HDRPASSTHRUCHAR33,HDRPASSTHRUCHAR34,HDRPASSTHRUCHAR35,HDRPASSTHRUCHAR36,'||
  'HDRPASSTHRUCHAR37,HDRPASSTHRUCHAR38,HDRPASSTHRUCHAR39,HDRPASSTHRUCHAR40,'||
  'HDRPASSTHRUCHAR41,HDRPASSTHRUCHAR42,HDRPASSTHRUCHAR43,HDRPASSTHRUCHAR44,'||
  'HDRPASSTHRUCHAR45,HDRPASSTHRUCHAR46,HDRPASSTHRUCHAR47,HDRPASSTHRUCHAR48,'||
  'HDRPASSTHRUCHAR49,HDRPASSTHRUCHAR50,HDRPASSTHRUCHAR51,HDRPASSTHRUCHAR52,'||
  'HDRPASSTHRUCHAR53,HDRPASSTHRUCHAR54,HDRPASSTHRUCHAR55,HDRPASSTHRUCHAR56,'||
  'HDRPASSTHRUCHAR57,HDRPASSTHRUCHAR58,HDRPASSTHRUCHAR59,HDRPASSTHRUCHAR60,'||
  'HDRPASSTHRUNUM01,HDRPASSTHRUNUM02,HDRPASSTHRUNUM03,HDRPASSTHRUNUM04,'||
  'HDRPASSTHRUNUM05,HDRPASSTHRUNUM06,HDRPASSTHRUNUM07,HDRPASSTHRUNUM08,'||
  'HDRPASSTHRUNUM09,HDRPASSTHRUNUM10,'||
  'HDRPASSTHRUDATE01,HDRPASSTHRUDATE02,' ||
  'HDRPASSTHRUDATE03,HDRPASSTHRUDATE04,HDRPASSTHRUDOLL01,HDRPASSTHRUDOLL02,' ||
  'L.trailer,L.seal,'||
  'zim7.pallet_count(oh.loadno,oh.custid,oh.fromfacility,oh.orderid,oh.shipid), ';
cmdSql := cmdSql || 'zim14.freight_total(oh.orderid,oh.shipid,null,null) ';
cmdSql := cmdSql || ', L.lateshipreason, OH.carrier||OH.deliveryservice,'
 ||'OH.shippingcost, ';

if nvl(rtrim(in_bol_tracking_yn),'N') = 'Y' then
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid, ''' || in_track_separator || '''),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,nvl(oh.billoflading,nvl(L.billoflading,'||
  'to_char(orderid) || ''-'' || to_char(shipid))))))';
else
  cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'',' ||
  'substr(zoe.order_trackingnos(oh.orderid,oh.shipid, ''' || in_track_separator || '''),1,1000),'||
  ' nvl(oh.prono,nvl(l.prono,to_char(orderid) || ''-'' || to_char(shipid))))';
end if;

if in_track_separator is not null then
   cmdSql := cmdSql || ' || ''' || in_track_separator || '''';
end if;

cmdSql := cmdSql || ',F.addr1,F.addr2,F.city,F.state,F.postalcode, oh.invoicenumber810, '||
                    'oh.invoiceamount810,zim7.VICSbolNumber(oh.loadno,oh.orderid,oh.shipid,oh.custid),' ||
                    'ca.scac, oh.delivery_requested, L.ldpassthruchar01, ';
if in_shipment_column is null then
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdsql || '''' ||  to_char(in_orderid) || to_char(in_shipid)|| ''' ';
   else
      cmdSql := cmdsql || '''' ||  to_char(in_loadno) || ''' ';
   end if;
else
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'nvl(substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),''(none)''), ' ||
                              'nvl(oh.' || in_shipment_column ||',''' || to_char(in_orderid) || to_char(in_shipid)|| ''' )) ';
   else
      cmdSql := cmdSql || 'nvl(oh.' || in_shipment_column ||
                          ',''' ||  to_char(in_loadno)|| ''' )';
   end if;
end if;
cmdSql := cmdSql || ',';
if in_aux_shipment_column is null then
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdsql || '''' ||  to_char(in_orderid) || to_char(in_shipid)|| ''' ';
   else
      cmdSql := cmdsql || '''' ||  to_char(in_loadno) || ''' ';
   end if;
else
   if nvl(in_loadno,0) = 0 then
      cmdSql := cmdSql || 'decode(nvl(ca.multiship,''N''),''Y'', '||
                              'nvl(substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),''(none)''), ' ||
                              'nvl(oh.' || in_aux_shipment_column ||',''' || to_char(in_orderid) || to_char(in_shipid)|| ''' )) ';
   else
      cmdSql := cmdSql || 'nvl(oh.' || in_aux_shipment_column ||
                          ',''' ||  to_char(in_loadno)|| ''' )';
   end if;
end if;

cmdSql := cmdSql ||
  ' , oh.orderstatus ' ||
  ' from consignee CN, customer C, facility F, loads L, carrier ca, orderhdr oh ';
cmdSql := cmdSql ||
  ' where oh.carrier = ca.carrier(+) '||
  ' and oh.loadno = L.loadno(+) ' ||
  ' and oh.fromfacility = F.facility(+) '||
  ' and oh.custid = C.custid(+) ' ||
  ' and oh.shipto = CN.consignee(+) ' ||
  l_condition;

cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

debugmsg('create dtl');
-- Create Detail View
cmdSql := 'create or replace view ord_stat_870_dtl_' || strSuffix ||
 '(orderid,shipid,custid,assignedid,shipticket,trackingno,servicecode,'||
 'lbs,kgs,gms,ozs,item,lotnumber,link_lotnumber,inventoryclass,'||
 'statuscode,reference,linenumber,orderdate,po,qtyordered,qtyshipped,'||
 'qtydiff,uom,packlistshipdate,weight,weightquaifier,weightunit,' ||
 'description,upc'||
 ',DTLPASSTHRUCHAR01,DTLPASSTHRUCHAR02,DTLPASSTHRUCHAR03' ||
 ',DTLPASSTHRUCHAR04,DTLPASSTHRUCHAR05,DTLPASSTHRUCHAR06,DTLPASSTHRUCHAR07' ||
 ',DTLPASSTHRUCHAR08,DTLPASSTHRUCHAR09,DTLPASSTHRUCHAR10,DTLPASSTHRUCHAR11' ||
 ',DTLPASSTHRUCHAR12,DTLPASSTHRUCHAR13,DTLPASSTHRUCHAR14,DTLPASSTHRUCHAR15' ||
 ',DTLPASSTHRUCHAR16,DTLPASSTHRUCHAR17,DTLPASSTHRUCHAR18,DTLPASSTHRUCHAR19' ||
 ',DTLPASSTHRUCHAR20'||
 ',DTLPASSTHRUCHAR21,DTLPASSTHRUCHAR22,DTLPASSTHRUCHAR23' ||
 ',DTLPASSTHRUCHAR24,DTLPASSTHRUCHAR25,DTLPASSTHRUCHAR26,DTLPASSTHRUCHAR27' ||
 ',DTLPASSTHRUCHAR28,DTLPASSTHRUCHAR29,DTLPASSTHRUCHAR30,DTLPASSTHRUCHAR31' ||
 ',DTLPASSTHRUCHAR32,DTLPASSTHRUCHAR33,DTLPASSTHRUCHAR34,DTLPASSTHRUCHAR35' ||
 ',DTLPASSTHRUCHAR36,DTLPASSTHRUCHAR37,DTLPASSTHRUCHAR38,DTLPASSTHRUCHAR39' ||
 ',DTLPASSTHRUCHAR40'||
 ',DTLPASSTHRUNUM01,DTLPASSTHRUNUM02,DTLPASSTHRUNUM03' ||
 ',DTLPASSTHRUNUM04,DTLPASSTHRUNUM05,DTLPASSTHRUNUM06,DTLPASSTHRUNUM07' ||
 ',DTLPASSTHRUNUM08,DTLPASSTHRUNUM09, DTLPASSTHRUNUM10, ' ||
 'DTLPASSTHRUNUM11,DTLPASSTHRUNUM12,DTLPASSTHRUNUM13' ||
 ',DTLPASSTHRUNUM14,DTLPASSTHRUNUM15,DTLPASSTHRUNUM16,DTLPASSTHRUNUM17' ||
 ',DTLPASSTHRUNUM18,DTLPASSTHRUNUM19, DTLPASSTHRUNUM20, ' ||
'DTLPASSTHRUDATE01,DTLPASSTHRUDATE02,DTLPASSTHRUDATE03,' ||
' DTLPASSTHRUDATE04,DTLPASSTHRUDOLL01,DTLPASSTHRUDOLL02, FROMLPID, smallpackagelbs ,' ||
' deliveryservice, entereduom, qtyshippedeuom, qtytotcommit)' ||
 'as select '||
 'oh.orderid,oh.shipid,oh.custid,d.dtlpassthrunum10,'||
 'substr(zoe.max_shipping_container(oh.orderid,oh.shipid),1,15),'||
 'decode(nvl(ca.multiship,''N''),''Y'','||
 '  substr(zoe.max_trackingno(oh.orderid,oh.shipid),1,30),'||
 ' nvl(oh.prono,to_char(oh.orderid) || ''-'' || to_char(oh.shipid))),'||
 'nvl(oh.deliveryservice,''OTHR''),nvl(d.weightship,0)'||
 ',nvl(d.weightship,0) / 2.2046,nvl(d.weightship,0) / .0022046,' ||
 'nvl(d.weightship,0) * 16,'||
 'd.item,d.lotnumber,nvl(d.lotnumber,''(none)''),d.inventoryclass,'||
 'decode(D.linestatus, ''X'',''CU'','||
 'decode(nvl(d.qtyship,0), 0,''DS'','||
        'decode(zim7.split_item(oh.custid,oh.reference,d.item),'||
                '''Y'',''SS'','||
         'decode(zim7.changed_qty(oh.orderid,oh.shipid,'||
                                  'd.item,d.lotnumber),'||
            '''Y'',''PR'',''CC'')))),';
cmdSql := cmdSql || 'oh.reference,';
cmdSql := cmdSql || 'nvl(d.dtlpassthruchar13,''000000''),oh.entrydate,oh.po,d.qtyentered,'||
 'nvl(d.qtyship,0),'||
 'nvl(d.qtyship,0) - d.qtyentered,d.uom,oh.packlistshipdate,'||
 'nvl(d.weightship,0),''G'','||
 '''L'', i.descr, u.upc';
cmdSql := cmdSql ||
 ',D.DTLPASSTHRUCHAR01,D.DTLPASSTHRUCHAR02,D.DTLPASSTHRUCHAR03' ||
 ',D.DTLPASSTHRUCHAR04,D.DTLPASSTHRUCHAR05,D.DTLPASSTHRUCHAR06,D.DTLPASSTHRUCHAR07' ||
 ',D.DTLPASSTHRUCHAR08,D.DTLPASSTHRUCHAR09,D.DTLPASSTHRUCHAR10,D.DTLPASSTHRUCHAR11' ||
 ',D.DTLPASSTHRUCHAR12,D.DTLPASSTHRUCHAR13,D.DTLPASSTHRUCHAR14,D.DTLPASSTHRUCHAR15' ||
 ',D.DTLPASSTHRUCHAR16,D.DTLPASSTHRUCHAR17,D.DTLPASSTHRUCHAR18,D.DTLPASSTHRUCHAR19' ||
 ',D.DTLPASSTHRUCHAR20'||
 ',D.DTLPASSTHRUCHAR21,D.DTLPASSTHRUCHAR22,D.DTLPASSTHRUCHAR23' ||
 ',D.DTLPASSTHRUCHAR24,D.DTLPASSTHRUCHAR25,D.DTLPASSTHRUCHAR26,D.DTLPASSTHRUCHAR27' ||
 ',D.DTLPASSTHRUCHAR28,D.DTLPASSTHRUCHAR29,D.DTLPASSTHRUCHAR30,D.DTLPASSTHRUCHAR31' ||
 ',D.DTLPASSTHRUCHAR32,D.DTLPASSTHRUCHAR33,D.DTLPASSTHRUCHAR34,D.DTLPASSTHRUCHAR35' ||
 ',D.DTLPASSTHRUCHAR36,D.DTLPASSTHRUCHAR37,D.DTLPASSTHRUCHAR38,D.DTLPASSTHRUCHAR39' ||
 ',D.DTLPASSTHRUCHAR40'||
 ',D.DTLPASSTHRUNUM01,D.DTLPASSTHRUNUM02,D.DTLPASSTHRUNUM03' ||
 ',D.DTLPASSTHRUNUM04,D.DTLPASSTHRUNUM05,D.DTLPASSTHRUNUM06,D.DTLPASSTHRUNUM07' ||
 ',D.DTLPASSTHRUNUM08,D.DTLPASSTHRUNUM09,D.DTLPASSTHRUNUM10'||
 ',D.DTLPASSTHRUNUM11,D.DTLPASSTHRUNUM12,D.DTLPASSTHRUNUM13' ||
 ',D.DTLPASSTHRUNUM14,D.DTLPASSTHRUNUM15,D.DTLPASSTHRUNUM16,D.DTLPASSTHRUNUM17' ||
 ',D.DTLPASSTHRUNUM18,D.DTLPASSTHRUNUM19,D.DTLPASSTHRUNUM20, '||
 ' D.DTLPASSTHRUDATE01,D.DTLPASSTHRUDATE02,D.DTLPASSTHRUDATE03,D.DTLPASSTHRUDATE04,' ||
 ' D.DTLPASSTHRUDOLL01,D.DTLPASSTHRUDOLL02, ''000000000000000'',0,oh.deliveryservice, ' ||
 ' D.uomentered, zcu.equiv_uom_qty (D.custid,D.item,D.uom,D.qtyship,D.uomentered), D.qtytotcommit' ||
 ' from custitemupcview U, custitem i, carrier ca, orderdtl d, orderhdr oh ' ||
 ' where oh.orderid = d.orderid '||
 ' and oh.shipid = d.shipid '||
 ' and oh.carrier = ca.carrier(+) '||
 ' and d.custid = i.custid(+) '||
 ' and d.item = i.item(+) '||
 ' and d.custid = U.custid(+) '||
 ' and d.item = U.item(+) ';
cmdSql := cmdSql || l_condition;

cntRows := 1;
while (cntRows * 60) < (Length(cmdSql)+60)
loop
  debugmsg(substr(cmdSql,((cntRows-1)*60)+1,60));
  cntRows := cntRows + 1;
end loop;

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);


out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimbos870 ' || sqlerrm;
  out_errorno := sqlcode;
end begin_ordstat870;




procedure end_ordstat870
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is

cursor curCustomer is
  select custid,nvl(linenumbersyn,'N') as linenumbersyn
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);
strObject varchar2(32);
strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

for obj in (select object_name, object_type
              from user_objects
             where object_name like 'ORD_STAT_870_%_' || strSuffix
               and object_name != 'ORD_STAT_870_HDR_' || strSuffix )
loop

  cmdSql := 'drop ' || obj.object_type || ' ' || obj.object_name;

  execute immediate cmdSql;

end loop;

cmdsql := 'drop view ORD_STAT_870_HDR_' || strSuffix;
execute immediate cmdSql;
out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeos870 ' || sqlerrm;
  out_errorno := sqlcode;
end end_ordstat870;

end zimportproc2;
/
show error package body zimportproc2;
exit;

