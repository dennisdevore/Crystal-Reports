create or replace PROCEDURE facility_loc_inv_adj
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
,in_inventoryclass varchar2
,in_invstatus varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
,in_location varchar2
,in_expirationdate date
,in_qty number
,in_orig_custid varchar2
,in_orig_item varchar2
,in_orig_inventoryclass varchar2
,in_orig_invstatus varchar2
,in_orig_lotnumber varchar2
,in_orig_serialnumber varchar2
,in_orig_useritem1 varchar2
,in_orig_useritem2 varchar2
,in_orig_useritem3 varchar2
,in_orig_location varchar2
,in_orig_expirationdate date
,in_orig_qty number
,in_orig_facility varchar2
,in_adjreason varchar2
,in_userid varchar2
,in_tasktype varchar2
,in_weight number
,in_orig_weight number
,in_mfgdate date
,in_orig_mfgdate date
,in_anvdate date
,in_orig_anvdate date
,out_adjrowid1 IN OUT varchar2
,out_adjrowid2 IN OUT varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_custreference IN varchar2 default null
,in_tasks_ok IN varchar2 default null
,in_facility varchar2
) is

cursor curPlate is
  select custid,
         item,
         nvl(inventoryclass,'RG') as inventoryclass,
         invstatus,
         status,
         lotnumber,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         location,
         expirationdate,
         unitofmeasure,
         quantity as qty,
         qtyrcvd,
         facility,
         nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         orderid,
         shipid,
         type,
         parentlpid,
         weight,
         lastcountdate,
         itementered,
         uomentered,
         manufacturedate,
         anvdate
    from plate
   where lpid = in_lpid;
pl curPlate%rowtype;
new curPlate%rowtype;

cursor curOrderhdr(in_orderid number, in_shipid number) is
  select orderstatus, ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderdtl(in_orderid number, in_shipid number,
  in_item varchar2, in_lotnumber varchar2) is
  select *
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderdtl%rowtype;
od2 curOrderdtl%rowtype;

cursor curChildrenSum(in_parentlpid varchar2) is
  select custid,
         item,
         lotnumber,
         invstatus,
         inventoryclass,
         sum(quantity) as quantity
    from plate
   where parentlpid = in_parentlpid
     and status = pl.status
     and type = 'PA'
   group by custid,item,lotnumber,invstatus,inventoryclass
   order by custid,item,lotnumber,invstatus,inventoryclass;
cursor curSysDflt(in_id varchar2)
is
   select defaultvalue
      from systemdefaults
      where defaultid = in_id;
forceLotAdj varchar2(255);

curCustInvClass integer;
custclassokay integer;
cmdSql varchar2(2000);
cntRows integer;
out_msg_suffix varchar2(80);
ci custitem%rowtype;
lo location%rowtype;
parent plate%rowtype;
newlastcountdate plate.lastcountdate%type;
cntChildItems integer;
cntChildren integer;
cntItem integer;
cntLotNumber integer;
cntInvStatus integer;
cntInventoryClass integer;
maxqty1 custitem.maxqtyof1%type;
adjrowid rowid;
strMsg varchar2(255);
intErrorno integer;
strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
strReasonAbbrev adjustmentreasons.abbrev%type;
strUserSetting userdetail.setting%type;
nulldate date;
l_adj_date date;

CURSOR C_CUSTITEMVIEW(in_custid varchar2, in_item varchar2)
IS
  select serialrequired, user1required, user2required, user3required,
         serialasncapture, user1asncapture, user2asncapture, user3asncapture,
         'N' asnflag, iskit
    from custitemview
   where custid = in_custid
     and item = in_item;

CIV_old C_CUSTITEMVIEW%rowtype;
CIV_new C_CUSTITEMVIEW%rowtype;

cnt integer;

odr_cnt integer;
odr_qty plate.quantity%type;
odr_weight plate.weight%type;
cursor c_odr(p_orderid number, p_shipid number, p_lpid varchar2, p_item varchar2,
             p_lotnumber varchar2, p_custid varchar2, p_uom varchar2,
             p_inventoryclass varchar2, p_invstatus varchar2, p_serialnumber varchar2,
             p_useritem1 varchar2, p_useritem2 varchar2, p_useritem3 varchar2)
is
   select rowid, qtyrcvd, weight
      from orderdtlrcpt
      where orderid = p_orderid
        and shipid = p_shipid
        and lpid = p_lpid
        and item = p_item
        and nvl(lotnumber,'(none)') = nvl(p_lotnumber,'(none)')
        and custid = p_custid
        and uom = p_uom
        and inventoryclass = p_inventoryclass
        and invstatus = p_invstatus
        and nvl(serialnumber, '(none)') = nvl(p_serialnumber, '(none)')
        and nvl(useritem1, '(none)') = nvl(p_useritem1, '(none)')
        and nvl(useritem2, '(none)') = nvl(p_useritem2, '(none)')
        and nvl(useritem3, '(none)') = nvl(p_useritem3, '(none)');
l_use_catch_weights custitem.use_catch_weights%type;

l_cdat cdata;
l_adjqty number;
l_force_invadjactivity customer_aux.force_invadjactivity%type;

begin

out_msg := '';
out_errorno := 0;
out_msg_suffix := '';
out_adjrowid1 := null;
out_adjrowid2 := null;
nulldate := to_date('01012000','mmddyyyy');
l_adj_date := sysdate;

open curPlate;
fetch curPlate into pl;
if curPlate%notfound then
  close curPlate;
  out_msg := 'Plate record not found: ' || in_lpid;
  out_errorno := 1;
  return;
end if;
close curPlate;

if pl.type != 'PA' then
  out_msg := 'Invalid plate type: ' || pl.type;
  out_errorno := 14;
  return;
end if;

if (pl.status not in ('A','I','P') and zlbl.is_lp_unprocessed_autogen(in_lpid) = 'N') then
  out_msg := 'Invalid plate status: ' || pl.status;
  out_errorno := 19;
  return;
end if;

if pl.facility != in_orig_facility then
  out_msg := 'Plate not at your facility: ' || pl.facility;
  out_errorno := 2;
  return;
end if;

strUserSetting := substr(zus.user_form_setting(in_userid,'PLATEADJUST',in_orig_facility),1,12);

if strUserSetting <> 'SUPERVISOR' then

  if pl.invstatus in ('QA','IN')
  and in_tasktype != 'QA' then
    out_msg := 'This plate must be updated via the QA/Inspection process';
    out_errorno := 80;
    return;
  end if;

  if rtrim(in_invstatus) in ('QA','IN')
  and in_tasktype != 'QA' then
    out_msg := 'This status is reserved for use by the QA/Inspection process';
    out_errorno := 81;
    return;
  end if;

end if;

if rtrim(in_custid) is null then
  new.custid := pl.custid;
else
  new.custid := in_custid;
end if;
if rtrim(in_item) is null then
  new.item := pl.item;
else
  new.item := in_item;
end if;
if rtrim(in_inventoryclass) is null then
  new.inventoryclass := pl.inventoryclass;
else
  new.inventoryclass := in_inventoryclass;
end if;
if rtrim(in_invstatus) is null then
  new.invstatus := pl.invstatus;
else
  new.invstatus := in_invstatus;
end if;
if rtrim(in_lotnumber) is null then
  new.lotnumber := pl.lotnumber;
else
  new.lotnumber := in_lotnumber;
end if;
if rtrim(in_serialnumber) is null then
  new.serialnumber := pl.serialnumber;
else
  new.serialnumber := in_serialnumber;
end if;
if rtrim(in_useritem1) is null then
  new.useritem1 := pl.useritem1;
else
  new.useritem1 := in_useritem1;
end if;
if rtrim(in_useritem2) is null then
  new.useritem2 := pl.useritem2;
else
  new.useritem2 := in_useritem2;
end if;
if rtrim(in_useritem3) is null then
  new.useritem3 := pl.useritem3;
else
  new.useritem3 := in_useritem3;
end if;
if rtrim(in_facility) is null then
  new.facility := pl.facility;
else
  new.facility := in_facility;
end if;
if rtrim(in_location) is null then
  new.location := pl.location;
else
  new.location := in_location;
end if;
if in_expirationdate is null then
  new.expirationdate := pl.expirationdate;
else
  new.expirationdate := in_expirationdate;
end if;
if in_qty is null then
  new.qty := pl.qty;
else
  new.qty := in_qty;
end if;
if in_weight is null then
  new.weight := pl.weight;
else
  new.weight := in_weight;
end if;
if in_mfgdate is null then
  new.manufacturedate := pl.manufacturedate;
else
  new.manufacturedate := in_mfgdate;
end if;

if in_anvdate is null then
  new.anvdate := pl.anvdate;
else
  new.anvdate := in_anvdate;
end if;

if new.qty = 0 then
  new.weight := 0;
end if;

if pl.custid = new.custid and
   pl.item = new.item and
   pl.inventoryclass = new.inventoryclass and
   pl.invstatus = new.invstatus and
   nvl(pl.lotnumber,'(none)') = nvl(new.lotnumber,'(none)') and
   nvl(pl.serialnumber,'(none)') = nvl(new.serialnumber,'(none)') and
   nvl(pl.useritem1,'(none)') = nvl(new.useritem1,'(none)') and
   nvl(pl.useritem2,'(none)') = nvl(new.useritem2,'(none)') and
   nvl(pl.useritem3,'(none)') = nvl(new.useritem3,'(none)') and
   pl.facility = new.facility and
   pl.location = new.location and
   nvl(pl.expirationdate,nulldate) = nvl(new.expirationdate,nulldate) and
   nvl(pl.manufacturedate,nulldate) = nvl(new.manufacturedate,nulldate) and
   nvl(pl.anvdate,nulldate) = nvl(new.anvdate,nulldate) and
   pl.qty = new.qty and
   pl.weight = new.weight then
  out_msg := 'No changes were entered';
  out_errorno := 3;
  return;
end if;

if pl.status = 'P' then
   if pl.custid != new.custid then
      out_msg := 'Cannot change Customer ID on a picked plate';
      out_errorno := 27;
      return;
   end if;

   if pl.item != new.item then
      out_msg := 'Cannot change Item on a picked plate';
      out_errorno := 28;
      return;
   end if;

   if pl.inventoryclass != new.inventoryclass then
      out_msg := 'Cannot change Inventory Class on a picked plate';
      out_errorno := 29;
      return;
   end if;

   if pl.invstatus != new.invstatus then
      out_msg := 'Cannot change Inventory Status on a picked plate';
      out_errorno := 30;
      return;
   end if;

   if pl.facility != new.facility or
      pl.location != new.location then
      out_msg := 'Cannot change Location on a picked plate';
      out_errorno := 32;
      return;
   end if;

   if nvl(pl.expirationdate,nulldate) != nvl(new.expirationdate,nulldate) then
      out_msg := 'Cannot change Expiration Date on a picked plate';
      out_errorno := 33;
      return;
   end if;

   if nvl(pl.manufacturedate,nulldate) != nvl(new.manufacturedate,nulldate) then
      out_msg := 'Cannot change Manufacture Date on a picked plate';
      out_errorno := 33;
      return;
   end if;

   if pl.qty != new.qty then
      out_msg := 'Cannot change Quantity on a picked plate';
      out_errorno := 34;
      return;
   end if;
else
  begin
    select count(1)
      into cntRows
      from tasks
     where lpid = in_lpid;
  exception when others then
    cntRows := 0;
  end;
  if cntRows = 0 then
    begin
      select count(1)
        into cntRows
        from subtasks
       where lpid = in_lpid;
    exception when others then
      cntRows := 0;
    end;
  end if;
  if (cntRows = 0) then
    if pl.parentlpid is not null then
      begin
        select count(1)
          into cntRows
          from tasks
         where lpid = pl.parentlpid;
      exception when others then
        cntRows := 0;
      end;
      if cntRows = 0 then
        begin
          select count(1)
            into cntRows
            from subtasks
           where lpid = pl.parentlpid;
        exception when others then
          cntRows := 0;
        end;
      end if;
    else
      begin
        select count(1)
          into cntRows
          from tasks
         where lpid in
           (select lpid
              from plate
             where parentlpid = in_lpid);
      exception when others then
        cntRows := 0;
      end;
      if cntRows = 0 then
        begin
          select count(1)
            into cntRows
            from subtasks
           where lpid in
             (select lpid
                from plate
               where parentlpid = in_lpid);
        exception when others then
          cntRows := 0;
        end;
      end if;
    end if;
  end if;
  if cntRows <> 0 and nvl(in_tasks_ok,'N') != 'Y' then
    out_msg := 'There are tasks assigned to this LiP';
    out_errorno := 40;
    return;
  end if;
end if;

if pl.custid != in_orig_custid then
  out_msg := 'The Customer ID on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.item != in_orig_item then
  out_msg := 'The Item on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.inventoryclass != in_orig_inventoryclass then
  out_msg := 'The Inventory Class on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.invstatus != in_orig_invstatus then
  out_msg := 'The Inventory Status on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if  nvl(pl.lotnumber,'(none)') != nvl(rtrim(in_orig_lotnumber),'(none)') then
  out_msg := 'The Lot Number on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.serialnumber,'(none)') != nvl(rtrim(in_orig_serialnumber),'(none)') then
  out_msg := 'The Serial Number on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.useritem1,'(none)') != nvl(rtrim(in_orig_useritem1),'(none)') then
  out_msg := 'The UserItem1 Value on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.useritem2,'(none)') != nvl(rtrim(in_orig_useritem2),'(none)') then
  out_msg := 'The UserItem2 Value on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.useritem3,'(none)') != nvl(rtrim(in_orig_useritem3),'(none)') then
  out_msg := 'The UserItem3 Value on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.facility != in_orig_facility then
  out_msg := 'The facility on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.location != in_orig_location then
  out_msg := 'The Location on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.expirationdate,nvl(in_orig_expirationdate,nulldate)) != nvl(in_orig_expirationdate,nulldate) then
  out_msg := 'The Expiration Date on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.manufacturedate,nvl(in_orig_mfgdate,nulldate)) != nvl(in_orig_mfgdate,nulldate) then
  out_msg := 'The Manufacture Date on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if nvl(pl.anvdate,nvl(in_orig_anvdate,nulldate)) != nvl(in_orig_anvdate,nulldate) then
  out_msg := 'The Anniversary Date on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if  pl.qty != in_orig_qty then
  out_msg := 'The Quantity on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if pl.weight != in_orig_weight then
  out_msg := 'The Weight on this plate record has changed--please review and retry';
  out_errorno := 4;
  return;
end if;

if (pl.parentlpid is not null) and
   (pl.custid != new.custid) then
  out_msg := 'Cannot change customer--LiP has a parent (' ||
    pl.parentlpid || ')';
  out_errorno := 17;
  return;
end if;

if (pl.parentlpid is not null) and
   (pl.facility != new.facility or pl.location != new.location) then
  out_msg := 'Cannot change location--LiP has a parent (' ||
    pl.parentlpid || ')';
  out_errorno := 18;
  return;
end if;

if pl.custid != new.custid or
   pl.item != new.item or
   pl.lotnumber != new.lotnumber then
  select count(1)
    into cntRows
    from customer
   where custid = new.custid;
  if cntRows = 0 then
    out_msg := 'Invalid Customer ID: ' || new.custid;
    out_errorno := 5;
    return;
  end if;
  begin
    select lotrequired
      into ci.lotrequired
      from custitemview
     where custid = new.custid
       and item = new.item;
  exception when no_data_found then
    out_msg := 'Invalid Customer/Item: ' || new.custid || ' ' || new.item;
    out_errorno := 6;
    return;
  end;
  if ci.lotrequired not in ('Y','O','S') then
    if rtrim(in_lotnumber) is null then
      new.lotnumber := null;
    else
      out_msg := 'A lot number cannot be entered for this item';
      out_errorno := 7;
      return;
    end if;
  else
    if (new.lotnumber is null) then
      out_msg := 'A lot number entry is required';
      out_errorno := 8;
      return;
    end if;
  end if;
end if;

CIV_old := null;
CIV_new := null;
OPEN C_CUSTITEMVIEW(pl.custid, pl.item);
FETCH C_CUSTITEMVIEW into CIV_old;
CLOSE C_CUSTITEMVIEW;

OPEN C_CUSTITEMVIEW(new.custid, new.item);
FETCH C_CUSTITEMVIEW into CIV_new;
CLOSE C_CUSTITEMVIEW;

if pl.inventoryclass != new.inventoryclass then
  select count(1)
    into cntRows
    from inventoryclass
   where code = new.inventoryclass;
  if cntRows = 0 then
    out_msg := 'Invalid inventory class: ' || new.inventoryclass;
    out_errorno := 9;
    return;
  end if;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'CLASS_TO_COMPANY_' || rtrim(new.CustId);
  custclassokay := 0;
  if cntRows = 1 then
    cmdSql := 'select count(1) from class_to_company_' ||
       rtrim(new.custid) || ' where code = ''' || new.inventoryclass ||
       '''';
    begin
      curCustInvClass := dbms_sql.open_cursor;
      dbms_sql.parse(curCustInvClass, cmdSql, dbms_sql.native);
      dbms_sql.define_column(curCustInvClass,1,custclassokay);
      cntRows := dbms_sql.execute(curCustInvClass);
      cntRows := dbms_sql.fetch_rows(curCustInvClass);
      if cntRows > 0 then
        dbms_sql.column_value(curCustInvClass,1,custclassokay);
      end if;
      dbms_sql.close_cursor(curCustInvClass);
    exception when others then
      dbms_sql.close_cursor(curCustInvClass);
    end;
    if custclassokay = 0 then
      out_msg := 'Invalid inventory class for this customer: ' || new.inventoryclass;
      out_errorno := 91;
      return;
    end if;
  end if;
  if (strUserSetting <> 'SUPERVISOR') and
     (CIV_old.iskit = 'I' or CIV_new.iskit = 'I') then
    out_msg := 'Supervisor status is required for kit-by-class changes';
    out_errorno := 92;
    return;
  end if;
end if;

if pl.invstatus != new.invstatus then
  select count(1)
    into cntRows
    from inventorystatus
   where code = new.invstatus;
  if cntRows = 0 then
    out_msg := 'Invalid inventory status: ' || new.invstatus;
    out_errorno := 10;
    return;
  end if;
end if;

if pl.facility != new.facility or 
   pl.location != new.location then
  begin
    select loctype
      into lo.loctype
      from location
     where facility = new.facility
       and locid = new.location;
  exception when no_data_found then
    out_msg := 'Location not found: ' || new.facility || '\' || new.location;
    out_errorno := 31;
    return;
  end;
  if lo.loctype in ('DOR') then
    out_msg := 'Cannot adjust to a door location';
    out_errorno := 11;
    return;
  end if;
  begin
    select loctype
      into lo.loctype
      from location
     where facility = pl.facility
       and locid = pl.location;
  exception when no_data_found then
    out_msg := 'Location not found: ' || pl.facility || '\' || pl.location;
    out_errorno := 31;
    return;
  end;
  if lo.loctype in ('DOR') then
    out_msg := 'Cannot adjust from a door location';
    out_errorno := 11;
    return;
  end if;
end if;

if pl.qty != new.qty then
  if (new.qty < 0) and
     (new.invstatus != 'SU') then
    out_msg := 'Adjusted quantity must be >= zero';
    out_errorno := 12;
    return;
  end if;
  if new.qty > 1 then
    begin
      select decode(nvl(I.maxqtyof1, 'C'), 'C', nvl(C.maxqtyof1, 'N'), I.maxqtyof1)
        into maxqty1
        from customer C, custitem I
       where I.custid = new.custid
         and I.item = new.item
         and C.custid = I.custid;
    exception when no_data_found then
      maxqty1 := 'N';
    end;
    if maxqty1 = 'Y' then
      out_msg := 'Adjusted quantity cannot be > 1';
      out_errorno := 20;
      return;
    end if;
  end if;
end if;

begin
  select abbrev
    into strReasonAbbrev
    from adjustmentreasons
   where code = in_adjreason;
exception when others then
   if (in_adjreason != 'QC') then
     out_msg := 'Invalid adjustment reason: ' || in_adjreason;
     out_errorno := 13;
     return;
   end if;
   strReasonAbbrev := in_adjreason;
end;

begin
  select baseuom
    into new.unitofmeasure
    from custitem
   where custid = new.custid
     and item = new.item;
exception when others then
  new.unitofmeasure := 'EA';
end;

begin
  select use_catch_weights
    into ci.use_catch_weights
    from custitemview
   where custid = new.custid
     and item = new.item;
exception when no_data_found then
  out_msg := 'Invalid Customer/Item: ' || new.custid || ' ' || new.item;
  out_errorno := 6;
  return;
end;
if ci.use_catch_weights = 'Y' then
  if new.qty > 0 then
    if new.weight <= 0 then
      out_msg := 'Adjusted weight must be > zero';
      out_errorno := 35;
      return;
    end if;
  elsif new.weight != 0 then
    out_msg := 'Adjusted weight must be = zero';
    out_errorno := 36;
    return;
  end if;
else
  if pl.weight = new.weight then
    new.weight := zcwt.lp_item_weight(in_lpid, new.custid, new.item,
        new.unitofmeasure) * new.qty;
  end if;
end if;

if in_tasktype in ('CC','PI') then
  newlastcountdate := sysdate;
else
  newlastcountdate := pl.lastcountdate;
end if;

open curOrderhdr(pl.orderid,pl.shipid);
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  oh.orderstatus := 'X';
  oh.ordertype := null;
end if;
close curOrderhdr;

open curSysDflt('INVADJLOT');
fetch curSysDflt into forceLotAdj;
if  curSysDflt%notfound then
   forceLotAdj := 'N';
end if;
close curSysDflt;

--
-- If receipt order is open do special checks for ASN Capture
--

if (oh.orderstatus = 'A') or
   (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R') then

   cnt := 0;

   if (CIV_old.serialrequired != 'Y' and CIV_old.serialasncapture = 'Y')
   or (CIV_old.user1required != 'Y' and CIV_old.user1asncapture = 'Y')
   or (CIV_old.user2required != 'Y' and CIV_old.user2asncapture = 'Y')
   or (CIV_old.user3required != 'Y' and CIV_old.user3asncapture = 'Y')
   then
      CIV_old.asnflag := 'Y';
      if (pl.custid = new.custid) and
         (pl.item = new.item) then
        CIV_new.asnflag := 'Y';
      end if;
   end if;

   if pl.custid != new.custid
   or pl.item != new.item then

     if (CIV_new.serialrequired != 'Y' and CIV_new.serialasncapture = 'Y')
     or (CIV_new.user1required != 'Y' and CIV_new.user1asncapture = 'Y')
     or (CIV_new.user2required != 'Y' and CIV_new.user2asncapture = 'Y')
     or (CIV_new.user3required != 'Y' and CIV_new.user3asncapture = 'Y')
     then
        CIV_new.asnflag := 'Y';
     end if;

     if CIV_old.asnflag = 'Y' then
        out_msg := 'Cannot change Customer Item for ASN capture Data.';
        out_errorno := 101;
        return;
     end if;


     if CIV_new.asnflag != CIV_old.asnflag then
        out_msg := 'ASN Capture not defined the same for old and new item';
        out_errorno := 102;
        return;
     end if;

     if CIV_old.serialrequired != CIV_new.serialrequired
     or CIV_old.serialasncapture != CIV_new.serialasncapture then
        out_msg := 'ASN Capture for serial number not defined the same for old and new item';
        out_errorno := 103;
        return;
     end if;
     if CIV_old.user1required != CIV_new.user1required
     or CIV_old.user1asncapture != CIV_new.user1asncapture then
        out_msg := 'ASN Capture for user item 1 not defined the same for old and new item';
        out_errorno := 104;
        return;
     end if;
     if CIV_old.user2required != CIV_new.user2required
     or CIV_old.user2asncapture != CIV_new.user2asncapture then
        out_msg := 'ASN Capture for user item 2 not defined the same for old and new item';
        out_errorno := 105;
        return;
     end if;

     if CIV_old.user3required != CIV_new.user3required
     or CIV_old.user3asncapture != CIV_new.user3asncapture then
        out_msg := 'ASN Capture for user item 3 not defined the same for old and new item';
        out_errorno := 106;
        return;
     end if;
   end if;

   if CIV_new.asnflag = 'Y' then

     if new.qty > pl.qty then
        out_msg := 'ASN Capture item cannot have quantity increased';
        out_errorno := 107;
        return;
     end if;

     if new.qty < pl.qty then
        select nvl(sum(qtyrcvd),0)
          into cnt
         from orderdtlrcpt
        where orderid = pl.orderid
          and shipid = pl.shipid
          and lpid = in_lpid
          and deleteflag = 'Y';

        if cnt != pl.qty - new.qty then
          out_msg := 'ASN Capture items flagged for deletion('||cnt||
           ') does not match decrease amount('||(pl.qty-new.qty)||').';
          out_errorno := 120;
          return;
        end if;
     end if;

   end if;
else
  if CIV_new.serialrequired = 'Y' then
   if new.serialnumber is null then
     out_msg := 'Serial number required.';
     out_errorno := 108;
     return;
   end if;
  elsif CIV_new.SerialASNCapture = 'N' then
     new.serialnumber := null;
  end if;

  if CIV_new.user1required = 'Y' then
   if new.useritem1 is null then
     out_msg := 'User item 1 required.';
     out_errorno := 109;
     return;
   end if;
  elsif CIV_new.User1ASNCapture = 'N' then
     new.useritem1 := null;
  end if;

  if CIV_new.user2required = 'Y' then
   if new.useritem2 is null then
     out_msg := 'User item 2 required.';
     out_errorno := 110;
     return;
   end if;
  elsif CIV_new.User2ASNCapture = 'N' then
     new.useritem2 := null;
  end if;

  if CIV_new.user3required = 'Y' then
   if new.useritem3 is null then
     out_msg := 'User item 3 required.';
     out_errorno := 111;
     return;
   end if;
  elsif CIV_new.user3required <> 'N' and
  	CIV_new.User3ASNCapture = 'N' then
    new.useritem3 := null;
  end if;

end if;

-- check for receipt adjustment on Arrived Receipts
if (oh.orderstatus = 'A') or
   (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R') then
  if pl.custid != new.custid then
    if oh.ordertype != 'Q' then
      out_msg := 'Cannot change Customer ID--receipt is open';
    else
      out_msg := 'Cannot change Customer ID--return is open';
    end if;
    out_errorno := 16;
    return;
  end if;
-- no receipt adjustment necessary
  if pl.item != new.item or
     nvl(pl.lotnumber,'(none)') != nvl(new.lotnumber,'(none)') or
     pl.invstatus != new.invstatus or
     pl.qty != new.qty then
    open curOrderdtl(pl.orderid,pl.shipid,pl.item,pl.lotnumber);
    fetch curOrderdtl into od;
    if curOrderdtl%notfound then
      close curOrderdtl;
      if oh.ordertype != 'Q' then
        out_msg := 'Receipt order-line not found: ' ||
          pl.orderid || ' ' || pl.shipid || ' ' ||
          pl.item || ' ' || pl.lotnumber;
      else
        out_msg := 'Return order-line not found: ' ||
          pl.orderid || ' ' || pl.shipid || ' ' ||
          pl.item || ' ' || pl.lotnumber;
      end if;
      out_errorno := 15;
      return;
    end if;
    close curOrderdtl;
  end if;
end if;

begin
  select nvl(force_invadjactivity,'N')
    into l_force_invadjactivity
	from customer_aux
   where custid = new.custid;
exception when others then
  l_force_invadjactivity := 'N';
end;

-- generate an adjustment activity row, unless the LiP is associated
-- with a an 'A'rrived order or an open return or the force flag is set
if not ( (oh.orderstatus = 'A') or
         (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R')
	   ) 
	    or
	  ( (l_force_invadjactivity = 'Y') and
	    (pl.invstatus != new.invstatus)
	  ) then
  if pl.custid = new.custid and
     pl.item = new.item and
     pl.invstatus = new.invstatus and
     pl.inventoryclass = new.inventoryclass and 
     pl.facility = new.facility then
    if (pl.qty != new.qty) or (pl.weight != new.weight) then
      insert into invadjactivity
       (whenoccurred, lpid, facility, custid, item, lotnumber,
        inventoryclass, invstatus, uom, adjqty, adjreason,
        tasktype, adjuser, lastuser, lastupdate, adjweight, custreference)
        values
       (l_adj_date, in_lpid, pl.facility, pl.custid, pl.item, pl.lotnumber,
        pl.inventoryclass, pl.invstatus, pl.unitofmeasure, new.qty - pl.qty, in_adjreason,
        in_tasktype, in_userid, in_userid, sysdate, new.weight - pl.weight, in_custreference)
        returning rowid into adjrowid;
      zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
      if strWhse is not null then
        zmi3.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
        if intErrorNo < 0 then
          out_errorno := intErrorNo;
          out_msg := strMsg;
          if in_tasktype != 'PI' then
            goto undo_adjustment;
          else
            out_errorno := 0;
            out_msg := '';
          end if;
        end if;
        if intErrorNo = 0 then
          out_adjrowid1 := adjrowid;
        else
          zedi.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
          if intErrorNo < 0 then
            out_errorno := intErrorNo;
            out_msg := strMsg;
            if in_tasktype != 'PI' then
              goto undo_adjustment;
            else
              out_errorno := 0;
              out_msg := '';
            end if;
          end if;
        end if;
      end if;
    else
      if nvl(pl.lotnumber,'(none)') != nvl(new.lotnumber,'(none)') then
         if forceLotAdj = 'Y' then
            insert into invadjactivity
             (whenoccurred, lpid, facility, custid, item, lotnumber,
              inventoryclass, invstatus, uom, adjqty, adjreason,
              tasktype, adjuser, lastuser, lastupdate,
              newcustid, newitem, newlotnumber,
              newinventoryclass, newinvstatus, adjweight, custreference)
              values
             (l_adj_date, in_lpid, pl.facility, pl.custid, pl.item, pl.lotnumber,
              pl.inventoryclass, pl.invstatus, pl.unitofmeasure, - pl.qty, in_adjreason,
              in_tasktype, in_userid, in_userid, sysdate,
              new.custid, new.item, new.lotnumber,
              new.inventoryclass, new.invstatus, - pl.weight, in_custreference)
                returning rowid into adjrowid;
            out_adjrowid1 := adjrowid;
            insert into invadjactivity
             (whenoccurred, lpid, facility, custid, item, lotnumber,
              inventoryclass, invstatus, uom, adjqty, adjreason,
              tasktype, adjuser, lastuser, lastupdate,
              oldcustid, olditem, oldlotnumber,
              oldinventoryclass, oldinvstatus, adjweight, custreference)
              values
             (l_adj_date, in_lpid, new.facility, new.custid, new.item, new.lotnumber,
              new.inventoryclass, new.invstatus, new.unitofmeasure, new.qty, in_adjreason,
              in_tasktype, in_userid, in_userid, sysdate,
              pl.custid, pl.item, pl.lotnumber,
              pl.inventoryclass, pl.invstatus, new.weight, in_custreference)
                returning   rowid into adjrowid;
            out_adjrowid2 := adjrowid;
         else
            zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
            if strWhse is null then
              insert into invadjactivity
               (whenoccurred, lpid, facility, custid, item, lotnumber,
                inventoryclass, invstatus, uom, adjqty, adjreason,
                tasktype, adjuser, lastuser, lastupdate,
                oldcustid, olditem, oldlotnumber,
                oldinventoryclass, oldinvstatus, adjweight, custreference)
                values
               (l_adj_date, in_lpid, new.facility, new.custid, new.item, new.lotnumber,
                new.inventoryclass, new.invstatus, new.unitofmeasure, 0, in_adjreason,
                in_tasktype, in_userid, in_userid, sysdate,
                pl.custid, pl.item, pl.lotnumber,
                pl.inventoryclass, pl.invstatus, 0, in_custreference)
                  returning rowid into adjrowid;
              out_adjrowid1 := adjrowid;
            end if;
         end if;
      end if;
    end if;
  elsif pl.custid != new.custid or
        pl.item != new.item or
        nvl(pl.lotnumber,'(none)') != nvl(new.lotnumber,'(none)') or
        pl.invstatus != new.invstatus or
        pl.inventoryclass != new.inventoryclass or
        pl.facility != new.facility then
    if in_tasktype != 'PI' then
      if pl.qty != new.qty then
        zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          out_msg := 'Quantity changes must be performed independently of other adjustments';
          out_errorno := 21;
          goto undo_adjustment;
        end if;
        zmi3.get_whse(new.custid,new.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          out_msg := 'Quantity changes must be performed independently of other adjustments';
          out_errorno := 22;
          goto undo_adjustment;
        end if;
      end if;
      if pl.invstatus != new.invstatus and
         pl.inventoryclass != new.inventoryclass then
        zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          out_msg := 'Class or Status changes must be performed independently of other adjustments';
          out_errorno := 23;
          goto undo_adjustment;
        end if;
        zmi3.get_whse(new.custid,new.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          out_msg := 'Class or Status changes must be performed independently of other adjustments';
          out_errorno := 24;
          goto undo_adjustment;
        end if;
      end if;
      if pl.custid != new.custid or
         pl.item != new.item then
        zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          if pl.invstatus != new.invstatus or
             pl.inventoryclass != new.inventoryclass then
            out_msg := 'Item changes must be performed independently of other changes';
            out_errorno := 25;
            goto undo_adjustment;
          end if;
        end if;
        zmi3.get_whse(new.custid,new.inventoryclass,strWhse,strRegWhse,strRetWhse);
        if strWhse is not null then
          if pl.invstatus != new.invstatus or
             pl.inventoryclass != new.inventoryclass then
            out_msg := 'Item changes must be performed independently of other changes';
            out_errorno := 26;
            goto undo_adjustment;
          end if;
        end if;
      end if;
    end if;
    insert into invadjactivity
     (whenoccurred, lpid, facility, custid, item, lotnumber,
      inventoryclass, invstatus, uom, adjqty, adjreason,
      tasktype, adjuser, lastuser, lastupdate,
      newcustid, newitem, newlotnumber,
      newinventoryclass, newinvstatus, adjweight, custreference)
      values
     (l_adj_date, in_lpid, pl.facility, pl.custid, pl.item, pl.lotnumber,
      pl.inventoryclass, pl.invstatus, pl.unitofmeasure, - pl.qty, in_adjreason,
      in_tasktype, in_userid, in_userid, sysdate,
      new.custid, new.item, new.lotnumber,
      new.inventoryclass, new.invstatus, - pl.weight, in_custreference)
        returning rowid into adjrowid;
    zmi3.get_whse(pl.custid,pl.inventoryclass,strWhse,strRegWhse,strRetWhse);
    if strWhse is not null then
      zmi3.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
      if intErrorNo < 0 then
        out_errorno := intErrorNo;
        out_msg := strMsg;
        if in_tasktype != 'PI' then
          goto undo_adjustment;
        else
          out_errorno := 0;
          out_msg := '';
        end if;
      end if;
      if intErrorNo = 0 then
        out_adjrowid1 := adjrowid;
      else
        zedi.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
        if intErrorNo < 0 then
          out_errorno := intErrorNo;
          out_msg := strMsg;
          if in_tasktype != 'PI' then
            goto undo_adjustment;
          else
            out_errorno := 0;
            out_msg := '';
          end if;
        end if;
      end if;
    end if;
    insert into invadjactivity
     (whenoccurred, lpid, facility, custid, item, lotnumber,
      inventoryclass, invstatus, uom, adjqty, adjreason,
      tasktype, adjuser, lastuser, lastupdate,
      oldcustid, olditem, oldlotnumber,
      oldinventoryclass, oldinvstatus, adjweight, custreference)
      values
     (l_adj_date, in_lpid, new.facility, new.custid, new.item, new.lotnumber,
      new.inventoryclass, new.invstatus, new.unitofmeasure, new.qty, in_adjreason,
      in_tasktype, in_userid, in_userid, sysdate,
      pl.custid, pl.item, pl.lotnumber,
      pl.inventoryclass, pl.invstatus, new.weight, in_custreference)
        returning   rowid into adjrowid;
    zmi3.get_whse(new.custid,new.inventoryclass,strWhse,strRegWhse,strRetWhse);
    if strWhse is not null then
      zmi3.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
      if intErrorNo < 0 then
        out_errorno := intErrorNo;
        out_msg := strMsg;
        if in_tasktype != 'PI' then
          goto undo_adjustment;
        else
          out_errorno := 0;
          out_msg := '';
        end if;
      end if;
      if intErrorNo = 0 then
        if out_adjrowid1 is null then
          out_adjrowid1 := adjrowid;
        else
          out_adjrowid2 := adjrowid;
        end if;
      else
        zedi.validate_interface(adjrowid,strMovementCode,intErrorNo,strMsg);
        if intErrorNo < 0 then
          out_errorno := intErrorNo;
          out_msg := strMsg;
          if in_tasktype != 'PI' then
            goto undo_adjustment;
          else
            out_errorno := 0;
            out_msg := '';
          end if;
        end if;
      end if;
    end if;
  end if;
end if;

<<undo_adjustment>>

if (out_errorno != 0) then
   if out_adjrowid1 is not null then
      delete invadjactivity where rowid = out_adjrowid1;
   end if;
   if out_adjrowid2 is not null then
      delete invadjactivity where rowid = out_adjrowid2;
   end if;
   return;
end if;

-- no more setting of out_errorno
-- If cust/item changing remove inventory
l_cdat := zcus.init_cdata;
l_cdat.lpid := in_lpid;
l_cdat.reason := in_adjreason;
if pl.custid != new.custid
or pl.item != new.item then
    l_cdat.quantity := -pl.qty;
    zcus.execute('IAJ',l_cdat);
end if;

update plate
   set custid = new.custid,
       item = new.item,
       unitofmeasure = new.unitofmeasure,
       inventoryclass = new.inventoryclass,
       invstatus = new.invstatus,
       lotnumber = new.lotnumber,
       serialnumber = new.serialnumber,
       useritem1 = new.useritem1,
       useritem2 = new.useritem2,
       useritem3 = new.useritem3,
       facility = new.facility,
       location = new.location,
       expirationdate = new.expirationdate,
       manufacturedate = new.manufacturedate,
       anvdate = trunc(new.anvdate),
       quantity = new.qty,
       weight = new.weight,
       lasttask = in_tasktype,
       adjreason = in_adjreason,
       lastuser = in_userid,
       lastupdate = sysdate,
       lastcountdate = newlastcountdate
 where lpid = in_lpid;

if pl.custid != new.custid
or pl.item != new.item then
    l_cdat.quantity := new.qty;
    zcus.execute('IAJ',l_cdat);
elsif pl.qty != new.qty then
    l_cdat.quantity := new.qty - pl.qty;
    zcus.execute('IAJ',l_cdat);

end if;

if (pl.parentlpid is not null) then
  if (pl.qty != new.qty) or (pl.weight != new.weight) then
    update plate
       set quantity = quantity - pl.qty + new.qty,
           weight = weight - pl.weight + new.weight,
           lasttask = in_tasktype,
           adjreason = in_adjreason,
           lastuser = in_userid,
           lastupdate = sysdate
     where lpid = pl.parentlpid
     returning quantity
          into parent.quantity;
  else
    begin
      select quantity
        into parent.quantity
        from plate
       where lpid = pl.parentlpid;
    exception when others then
      parent.quantity := 0;
    end;
  end if;
  begin
    select count(1)
      into cntChildren
      from plate
     where parentlpid = pl.parentlpid
       and status in ('A','M')
       and type = 'PA'
       and quantity != 0;
  exception when others then
    cntChildren := 0;
  end;
  if (parent.quantity = 0) and (cntChildren = 0) then
    zlp.plate_to_deletedplate(pl.parentlpid,in_userid,'IA',strMsg);
  elsif (parent.quantity != 0) or (cntChildren != 0) then
    if (pl.custid != new.custid or
        pl.item != new.item or
        pl.lotnumber != new.lotnumber or
        pl.invstatus != new.invstatus or
        pl.inventoryclass != new.inventoryclass) then
      cntChildItems := 0;
      parent.item := null;
      parent.lotnumber := null;
      parent.invstatus := null;
      parent.inventoryclass := null;
      cntItem := 0;
      cntLotNumber := 0;
      cntInvStatus := 0;
      cntInventoryClass := 0;
      for cs in curChildrenSum(pl.parentlpid)
      loop
        cntChildItems := cntChildItems + 1;
        parent.custid := cs.custid;
        if nvl(parent.item,'x') <> cs.item then
          cntItem := cntItem + 1;
        end if;
        parent.item := cs.item;
        if nvl(parent.lotnumber,'x') <> nvl(cs.lotnumber,'x') then
          cntlotnumber := cntlotnumber + 1;
        end if;
        parent.lotnumber := cs.lotnumber;
        if nvl(parent.invstatus,'x') <> cs.invstatus then
          cntinvstatus := cntinvstatus + 1;
        end if;
        parent.invstatus := cs.invstatus;
        if nvl(parent.inventoryclass,'x') <> cs.inventoryclass then
          cntinventoryclass := cntinventoryclass + 1;
        end if;
        parent.inventoryclass := cs.inventoryclass;
      end loop;
      if cntChildItems = 1 then -- "single-item" multi
        update plate
           set parentfacility = facility,
               parentitem = parent.item,
               childfacility = null,
               childitem = null,
               custid = parent.custid,
               item = parent.item,
               lotnumber = parent.lotnumber,
               invstatus = parent.invstatus,
               inventoryclass = parent.inventoryclass,
               lasttask = in_tasktype,
               lastuser = in_userid,
               lastupdate = sysdate
         where lpid = pl.parentlpid
           and (nvl(parentfacility,'x') != facility or
                nvl(parentitem,'x') != parent.item or
                childfacility is not null or
                childitem is not null or
                nvl(custid,'x') != parent.custid or
                nvl(item,'x') != parent.item or
                nvl(lotnumber,'x') != nvl(parent.lotnumber,'x') or
                nvl(invstatus,'x') != nvl(parent.invstatus,'x') or
                nvl(inventoryclass,'x') != nvl(parent.inventoryclass,'x')
               );
        update plate
           set parentfacility = null,
               parentitem = null,
               childfacility = null,
               childitem = null
         where parentlpid = pl.parentlpid
           and (parentfacility is not null or
                parentitem is not null or
                childfacility is not null or
                childitem is not null
               );
      else                      -- "multiple-item" multi
        if cntItem > 1 then
          parent.item := null;
        end if;
        if cntLotNumber > 1 then
          parent.lotnumber := null;
        end if;
        if cntInvStatus > 1 then
          parent.invstatus := null;
        end if;
        if cntInventoryClass > 1 then
          parent.inventoryclass := null;
        end if;
        update plate
           set parentfacility = null,
               parentitem = null,
               item = parent.item,
               lotnumber = parent.lotnumber,
               invstatus = parent.invstatus,
               inventoryclass = parent.inventoryclass,
               lasttask = in_tasktype,
               lastuser = in_userid,
               lastupdate = sysdate
         where lpid = pl.parentlpid
           and (parentfacility is not null or
                parentitem is not null or
                nvl(item,'x') <> nvl(parent.item,'x') or
                nvl(lotnumber,'x') <> nvl(parent.lotnumber,'x') or
                nvl(invstatus,'x') <> nvl(parent.invstatus,'x') or
                nvl(inventoryclass,'x') <> nvl(parent.inventoryclass,'x'));
        update plate
           set parentfacility = null,
               parentitem = null,
               childfacility = facility,
               childitem = item
         where parentlpid = pl.parentlpid
           and (parentfacility is not null or
                parentitem is not null or
                nvl(childfacility,'x') != facility or
                nvl(childitem,'x') != item
               );
      end if;
    end if;
  end if;
else
  update plate
     set parentfacility = facility,
         parentitem = item,
         childfacility = null,
         childitem = null
   where lpid = in_lpid
     and (nvl(parentfacility,'x') != facility or
          nvl(parentitem,'x') != item or
          childfacility is not null or
          childitem is not null
         );
end if;

-- The LiP is associated with an 'A'rrived order or an open return, update the
-- orderdtlrcpt table
if (oh.orderstatus = 'A') or
   (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R') then

  if (pl.custid = new.custid) and (pl.item = new.item) then
    if ci.use_catch_weights = 'Y' then
      zcwt.set_item_catch_weight(new.custid, new.item, pl.orderid, pl.shipid,
          new.qty - pl.qty, new.unitofmeasure, new.weight - pl.weight, in_userid, out_msg);
      if substr(out_msg, 1, 4) != 'OKAY' then
        zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg, 'W', in_userid, out_msg);
      end if;
    end if;
  else
    if ci.use_catch_weights = 'Y' then
      zcwt.set_item_catch_weight(new.custid, new.item, pl.orderid, pl.shipid,
          new.qty, new.unitofmeasure, new.weight, in_userid, out_msg);
      if substr(out_msg, 1, 4) != 'OKAY' then
        zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg, 'W', in_userid, out_msg);
      end if;
    end if;

    begin
      select use_catch_weights
        into l_use_catch_weights
        from custitemview
       where custid = pl.custid
         and item = pl.item;
    exception when no_data_found then
      l_use_catch_weights := 'N';
    end;

    if l_use_catch_weights = 'Y' then
      zcwt.set_item_catch_weight(pl.custid, pl.item, pl.orderid, pl.shipid,
          -pl.qty, pl.unitofmeasure, -pl.weight, in_userid, out_msg);
      if substr(out_msg, 1, 4) != 'OKAY' then
        zms.log_msg('PlateAdj', in_orig_facility, pl.custid, out_msg, 'W', in_userid, out_msg);
      end if;
    end if;
  end if;

  if nvl(CIV_old.asnflag,'N') = 'Y' then
  --
  -- If changing items etc need to do big complicated update here!!!
  --    check with Brian
  --
    delete from orderdtlrcpt
     where orderid = pl.orderid
       and shipid = pl.shipid
       and item = pl.item
       and nvl(lotnumber,'(none)') = nvl(pl.lotnumber,'(none)')
       and lpid = in_lpid
       and deleteflag = 'Y';

    update plate
       set qtyrcvd = pl.qtyrcvd + new.qty - pl.qty,
           lastuser = in_userid,
           lastupdate = sysdate
     where lpid = in_lpid;
  else

    odr_qty := pl.qty;
    odr_weight := pl.weight;
    for odr in c_odr(pl.orderid, pl.shipid, in_lpid, pl.item, pl.lotnumber,
        pl.custid, pl.unitofmeasure, pl.inventoryclass, pl.invstatus,
        pl.serialnumber, pl.useritem1, pl.useritem2, pl.useritem3) loop

      if odr.qtyrcvd <= odr_qty then
        delete orderdtlrcpt where rowid = odr.rowid;
      else
        update orderdtlrcpt
           set qtyrcvd = qtyrcvd - odr_qty,
               qtyrcvdgood = decode(pl.invstatus, 'DM', 0, qtyrcvdgood-odr_qty),
               qtyrcvddmgd = decode(pl.invstatus, 'DM', qtyrcvddmgd-odr_qty, 0),
               lastuser = in_userid,
               lastupdate = sysdate,
               weight = weight - odr_weight
         where rowid = odr.rowid;
      end if;
      odr_qty := odr_qty - least(odr.qtyrcvd, odr_qty);
      odr_weight := odr_weight - least(odr.weight, odr_weight);
      exit when (odr_qty = 0);
    end loop;
    if new.qty > 0 then
      odr_cnt := 0;
      for odr in c_odr(pl.orderid, pl.shipid, in_lpid, new.item, new.lotnumber,
          new.custid, new.unitofmeasure, new.inventoryclass, new.invstatus,
          new.serialnumber, new.useritem1, new.useritem2, new.useritem3) loop

        update orderdtlrcpt
           set qtyrcvd = qtyrcvd + new.qty,
               qtyrcvdgood = decode(new.invstatus, 'DM', 0, qtyrcvdgood+new.qty),
               qtyrcvddmgd = decode(new.invstatus, 'DM', qtyrcvddmgd+new.qty, 0),
               lastuser = in_userid,
               lastupdate = sysdate,
               weight = weight + new.weight
         where rowid = odr.rowid;
        odr_cnt := odr_cnt + 1;
        exit;

      end loop;

      if odr_cnt = 0 then
        insert into orderdtlrcpt
         (orderid,shipid,orderitem,orderlot,facility,custid,item,lotnumber,
          uom,inventoryclass,invstatus,lpid,qtyrcvd,qtyrcvdgood,
          qtyrcvddmgd,lastuser,lastupdate,
          serialnumber,useritem1,useritem2,useritem3,weight, parentlpid)
        values
         (pl.orderid,pl.shipid,new.item,new.lotnumber,in_orig_facility,new.custid,
          new.item,new.lotnumber,new.unitofmeasure,
          new.inventoryclass,new.invstatus,
          in_lpid,new.qty,
          decode(new.invstatus,'DM',null,new.qty),
          decode(new.invstatus,'DM',new.qty,null),
          in_userid,sysdate,
          new.serialnumber,new.useritem1,new.useritem2,new.useritem3,new.weight,
          pl.parentlpid);
      end if;
    end if;
    update plate
       set qtyrcvd = pl.qtyrcvd + new.qty - pl.qty,
           lastuser = in_userid,
           lastupdate = sysdate
     where lpid = in_lpid;
  end if;
end if;

-- The LiP is not associated with an 'A'rrived order or an open return, update
-- the asof
if not ((oh.orderstatus = 'A') or
     (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R')) then
  if pl.facility = new.facility and
     pl.custid = new.custid and
     pl.item = new.item and
     pl.invstatus = new.invstatus and
     pl.inventoryclass = new.inventoryclass and
     nvl(pl.lotnumber,'(none)') = nvl(new.lotnumber,'(none)') then
    if (pl.qty != new.qty) or (pl.weight != new.weight) then
      zbill.add_asof_inventory(
         pl.facility,
         pl.custid,
         pl.item,
         pl.lotnumber,
         pl.unitofmeasure,
         trunc(sysdate),
         new.qty - pl.qty,
         new.weight - pl.weight,
         strReasonAbbrev,
         'AD',
         pl.inventoryclass,
         pl.invstatus,
         pl.orderid,
         pl.shipid,
         in_lpid,
         in_userid,
         out_msg);
    end if;
    if substr(out_msg,1,4) != 'OKAY' then
        zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg,
        'W', in_userid, out_msg);
    end if;
  elsif pl.facility != new.facility or
        pl.custid != new.custid or
        pl.item != new.item or
        pl.invstatus != new.invstatus or
        pl.inventoryclass != new.inventoryclass or
        nvl(pl.lotnumber,'(none)') != nvl(new.lotnumber,'(none)') then
    zbill.add_asof_inventory(
       pl.facility,
       pl.custid,
       pl.item,
       pl.lotnumber,
       pl.unitofmeasure,
       trunc(sysdate),
       - pl.qty,
       - pl.weight,
       strReasonAbbrev,
       'AD',
       pl.inventoryclass,
       pl.invstatus,
       pl.orderid,
       pl.shipid,
       in_lpid,
       in_userid,
       out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
        zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg,
        'W', in_userid, out_msg);
    end if;
    if new.qty != 0 then
      zbill.add_asof_inventory(
         new.facility,
         new.custid,
         new.item,
         new.lotnumber,
         new.unitofmeasure,
         trunc(sysdate),
         new.qty,
         new.weight,
         strReasonAbbrev,
         'AD',
         new.inventoryclass,
         new.invstatus,
         pl.orderid,
         pl.shipid,
         in_lpid,
         in_userid,
         out_msg);
      if substr(out_msg,1,4) != 'OKAY' then
          zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg,
          'W', in_userid, out_msg);
      end if;
    end if;
  end if;
end if;

if new.qty = 0 then
  zlp.plate_to_deletedplate(in_lpid,in_userid,'IA',strMsg);
end if;

-- check for receipt adjustment on Arrived Receipts or open returns
if (oh.orderstatus = 'A') or
   (oh.ordertype = 'Q' and oh.orderstatus != 'X' and oh.orderstatus != 'R') then
-- no receipt adjustment necessary
  if pl.item = new.item and
     nvl(pl.lotnumber,'(none)') = nvl(new.lotnumber,'(none)') and
     pl.invstatus = new.invstatus and
     pl.qty = new.qty and
     pl.weight = new.weight then
    goto finish_it;
  end if;
  begin
    select useramt1
      into ci.useramt1
      from custitem
     where custid = pl.custid
       and item = pl.item;
  exception when no_data_found then
    ci.useramt1 := 0;
  end;
  if pl.invstatus = 'DM' then
    zrec.update_receipt_dtl(pl.orderid, pl.shipid, pl.item, pl.lotnumber,
      pl.unitofmeasure, pl.itementered, pl.uomentered,
      -pl.qty, 0, -pl.qty,
      -pl.weight, 0, -pl.weight,
      -(zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * pl.qty),
      0,
      -(zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * pl.qty),
      -(pl.qty * zci.item_amt(pl.custid, pl.orderid, pl.shipid, pl.item, pl.lotnumber)),
      0,
      -(pl.qty * zci.item_amt(pl.custid, pl.orderid, pl.shipid, pl.item, pl.lotnumber)),
      in_userid, 'Automatically created by inventory adjustment', out_msg);
  else
    zrec.update_receipt_dtl(pl.orderid, pl.shipid, pl.item, pl.lotnumber,
      pl.unitofmeasure, pl.itementered, pl.uomentered,
      -pl.qty, -pl.qty, 0,
      -pl.weight, -pl.weight, 0,
      -(zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * pl.qty),
      -(zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * pl.qty),
      0,
      -(pl.qty * zci.item_amt(pl.custid, pl.orderid, pl.shipid, pl.item, pl.lotnumber)),
      -(pl.qty * zci.item_amt(pl.custid, pl.orderid, pl.shipid, pl.item, pl.lotnumber)),
      0,
      in_userid, 'Automatically created by inventory adjustment', out_msg);
  end if;
  if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg,
      'W', in_userid, out_msg);
  end if;

  update loadstopship
     set qtyrcvd = nvl(qtyrcvd,0) - pl.qty,
         weightrcvd = nvl(weightrcvd ,0) - pl.weight,
         weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                        - nvl(zwt.from_lbs_to_kgs(pl.custid,pl.weight),0),
         cubercvd = nvl(cubercvd,0) - (zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * pl.qty),
         amtrcvd = nvl(amtrcvd,0) - (pl.qty * zci.item_amt(pl.custid, pl.orderid, pl.shipid, pl.item, pl.lotnumber)),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = pl.loadno
     and stopno = pl.stopno
     and shipno = pl.shipno;
  open curOrderdtl(pl.orderid,pl.shipid,new.item,new.lotnumber);
  fetch curOrderdtl into od2;
  if curOrderdtl%notfound then
    od2.orderid := 0;
  end if;
  close curOrderdtl;
  begin
    select useramt1
      into ci.useramt1
      from custitem
     where custid = new.custid
       and item = new.item;
  exception when no_data_found then
    ci.useramt1 := 0;
  end;
  if new.invstatus = 'DM' then
    zrec.update_receipt_dtl(pl.orderid, pl.shipid, new.item, new.lotnumber,
        new.unitofmeasure, new.item, new.unitofmeasure,
        new.qty, 0, new.qty,
        new.weight, 0, new.weight,
        zci.item_cube(new.custid,new.item,new.unitofmeasure) * new.qty,
        0,
        zci.item_cube(new.custid,new.item,new.unitofmeasure) * new.qty,
        new.qty * zci.item_amt(new.custid, pl.orderid, pl.shipid, new.item, new.lotnumber),
        0,
        new.qty * zci.item_amt(new.custid, pl.orderid, pl.shipid, new.item, new.lotnumber),
        in_userid, 'Automatically created by inventory adjustment', out_msg);
  else
    zrec.update_receipt_dtl(pl.orderid, pl.shipid, new.item, new.lotnumber,
        new.unitofmeasure, new.item, new.unitofmeasure,
        new.qty, new.qty, 0,
        new.weight, new.weight, 0,
        zci.item_cube(new.custid,new.item,new.unitofmeasure) * new.qty,
        zci.item_cube(new.custid,new.item,new.unitofmeasure) * new.qty,
        0,
        new.qty * zci.item_amt(new.custid, pl.orderid, pl.shipid, new.item, new.lotnumber),
        new.qty * zci.item_amt(new.custid, pl.orderid, pl.shipid, new.item, new.lotnumber),
        0,
        in_userid, 'Automatically created by inventory adjustment', out_msg);
  end if;
  if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('PlateAdj', in_orig_facility, new.custid, out_msg,
      'W', in_userid, out_msg);
  end if;
  update loadstopship
     set qtyrcvd = nvl(qtyrcvd,0) + new.qty,
         weightrcvd = nvl(weightrcvd,0) + new.weight,
         weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                        + nvl(zwt.from_lbs_to_kgs(new.custid,new.weight),0),
         cubercvd = nvl(cubercvd,0) + (zci.item_cube(new.custid,new.item,new.unitofmeasure) * new.qty),
         amtrcvd = nvl(amtrcvd,0) + (new.qty * zci.item_amt(new.custid, pl.orderid, pl.shipid, new.item, new.lotnumber)),
         lastuser = in_userid,
         lastupdate = sysdate
   where loadno = pl.loadno
     and stopno = pl.stopno
     and shipno = pl.shipno;
  out_msg_suffix := '(Receipt ' || pl.orderid || '/' ||
    pl.shipid || 'was also adjusted)';
end if;

<<finish_it>>

out_msg := 'OKAY ' || out_msg_suffix;

exception when others then
  out_errorno := sqlcode;
  out_msg := 'ziaia ' || substr(sqlerrm,1,80);
end facility_loc_inv_adj;
/
show error procedure facility_loc_inv_adj;
exit;
