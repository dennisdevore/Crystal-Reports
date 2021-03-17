create or replace package body alps.zmi3proc as
--
-- $Id$
--

-- Check for default mapping to override the SAP setup
function check_inv_adj_format
(in_custid  varchar2)
return varchar2
is
cursor curCustAux(in_custid varchar2)
is
select inv_adj_export_format
  from customer_aux
 where custid = in_custid;

CA curCustAux%rowtype;

begin

    CA := null;
    OPEN curCustAux(in_custid);
    FETCH curCustAux into CA;
    CLOSE curCustAux;

    return trim(CA.inv_adj_export_format);

exception when others then
    return null;
end check_inv_adj_format; 

-- add an invadjactivity row for SAP I9 interface if customer is so configured
procedure insert_damaged_info
(in_lpid IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_uom IN varchar2
,in_adjqty IN number
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_adjuser IN varchar2
,out_rowid IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
intErrorNo integer;
strMsg varchar2(255);
strFromInvStatus varchar2(4);
strToInvStatus varchar2(4);

begin

out_errorno := 0;
out_msg := '';

zmi3.get_whse(in_custid,in_inventoryclass,strWhse,strRegWhse,strRetWhse);
if strWhse is not null then
  insert into invadjactivity
   (whenoccurred, lpid, facility, custid, item, lotnumber,
    inventoryclass, invstatus, uom, adjqty, adjreason,
    tasktype, adjuser, lastuser, lastupdate,
    newcustid, newitem, newlotnumber,
    newinventoryclass, newinvstatus)
    values
   (sysdate, in_lpid, in_facility, in_custid, in_item, in_lotnumber,
    in_inventoryclass, in_invstatus, in_uom, in_adjqty, in_adjreason,
    in_tasktype, in_adjuser, in_adjuser, sysdate,
    in_custid, in_item, in_lotnumber,
    in_inventoryclass, 'DM')
      returning rowid into out_rowid;
  zmi3.validate_interface(out_rowid,strMovementCode,intErrorNo,strMsg);
  if intErrorNo != 0 then
    out_rowid := null;
    out_errorno := 1;
    out_msg := 'No interface needed';
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end insert_damaged_info;

procedure insert_interface_info
(in_lpid IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_inventoryclass IN varchar2
,in_invstatus IN varchar2
,in_uom IN varchar2
,in_adjqty IN number
,in_adjreason IN varchar2
,in_tasktype IN varchar2
,in_adjuser IN varchar2
,out_rowid IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
strMovementCode orderstatus.abbrev%type;
intErrorNo integer;
strMsg varchar2(255);
strFromInvStatus varchar2(4);
strToInvStatus varchar2(4);

begin

out_errorno := 0;
out_msg := '';

zmi3.get_whse(in_custid,in_inventoryclass,strWhse,strRegWhse,strRetWhse);
if strWhse is not null then
  if (in_adjreason = 'SG') then -- system-generated cycle count adjustments
    if in_adjqty > 0 then
      strFromInvStatus := in_invstatus;
      strToInvStatus := 'SU';
    else
      strFromInvStatus := 'SU';
      strToInvStatus := in_invstatus;
    end if;
    insert into invadjactivity
     (whenoccurred, lpid, facility, custid, item, lotnumber,
      inventoryclass, invstatus, uom, adjqty, adjreason,
      tasktype, adjuser, lastuser, lastupdate,
      newcustid, newitem, newlotnumber,
      newinventoryclass, newinvstatus)
      values
     (sysdate, in_lpid, in_facility, in_custid, in_item, in_lotnumber,
      in_inventoryclass, strFromInvStatus, in_uom, in_adjqty, in_adjreason,
      in_tasktype, in_adjuser, in_adjuser, sysdate,
      in_custid, in_item, in_lotnumber,
      in_inventoryclass, strToInvStatus)
        returning rowid into out_rowid;
  else
    insert into invadjactivity
     (whenoccurred, lpid, facility, custid, item, lotnumber,
      inventoryclass, invstatus, uom, adjqty, adjreason,
      tasktype, adjuser, lastuser, lastupdate)
      values
     (sysdate, in_lpid, in_facility, in_custid, in_item, in_lotnumber,
      in_inventoryclass, in_invstatus, in_uom, in_adjqty, in_adjreason,
      in_tasktype, in_adjuser, in_adjuser, sysdate)
      returning rowid into out_rowid;
  end if;
  zmi3.validate_interface(out_rowid,strMovementCode,intErrorNo,strMsg);
  if intErrorNo != 0 then
    out_rowid := null;
    out_errorno := 1;
    out_msg := 'No interface needed';
    return;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end insert_interface_info;

procedure validate_interface
(in_adjrowid IN rowid
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curInvAdjActivity is
  select *
    from invadjactivity
   where rowid = in_adjrowid;
adj curInvAdjActivity%rowtype;

strWhse orderstatus.abbrev%type;
strRegWhse orderstatus.abbrev%type;
strRetWhse orderstatus.abbrev%type;
prm orderstatus%rowtype;
strMsg varchar2(255);
strDebugYN char(1);
l_prm_descr varchar2(255);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  zut.prt('debug--' || sqlerrm);
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;
out_movement_code := '';
out_errorno := 0;
out_msg := '';

adj := null;
open curInvAdjActivity;
fetch curInvAdjActivity into adj;
close curInvAdjActivity;

if adj.custid is null then
  out_errorno := -1;
  out_msg := 'Adjustment row not found: ' || in_adjrowid;
  return;
end if;

debugmsg('get_whse cust: ' || adj.custid ||
         ' class: ' || adj.inventoryclass);
zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,strRegWhse,strRetWhse);
debugmsg('whse is >' || strWhse || '<');
if strWhse is null then
  out_errorno := 1;
  out_msg := 'No interface needed (not a relevant warehouse)';
  return;
end if;

l_prm_descr := check_inv_adj_format(adj.custid);

debugmsg('get_cust_parm_value ' || adj.custid);
if l_prm_descr is null then
    zmi3.get_cust_parm_value(adj.custid,'I9INVADJFMT',l_prm_descr,prm.abbrev);
end if;
debugmsg('parm value is >' || l_prm_descr || '<');
if l_prm_descr is null then
  out_errorno := 2;
  out_msg := 'No interface needed (no format defined)';
  return;
end if;

debugmsg('newcustid ' || adj.newcustid);
debugmsg('oldcustid ' || adj.oldcustid);
debugmsg('adjcustid ' || adj.custid);
debugmsg('newitem ' || adj.newitem);
debugmsg('olditem ' || adj.olditem);
debugmsg('adjitem ' || adj.item);
debugmsg('newinvstatus ' || adj.newinvstatus);
debugmsg('oldinvstatus ' || adj.oldinvstatus);
debugmsg('adjinvstatus ' || adj.invstatus);
debugmsg('newinventoryclass ' || adj.newinventoryclass);
debugmsg('oldinventoryclass ' || adj.oldinventoryclass);
debugmsg('adjinventoryclass ' || adj.inventoryclass);
debugmsg('adjreason ' || adj.adjreason);
debugmsg('adjqty ' || adj.adjqty);

if strDebugYN = 'Y' then
  out_errorno := -12345;
end if;

if ( (adj.newcustid is null) and (adj.oldcustid is null) ) or
     ( (adj.custid != nvl(adj.newcustid,adj.custid)) or
       (adj.item != nvl(adj.newitem,adj.item)) ) or
     ( (adj.custid != nvl(adj.oldcustid,adj.custid)) or
       (adj.item != nvl(adj.olditem,adj.item)) ) and
    ( adj.adjqty != 0 ) then
  debugmsg('get_movement_code adj ');
  zmi3.get_movement_code(adj.custid,strWhse,adj.inventoryclass,adj.invstatus,
   adj.inventoryclass,adj.invstatus,adj.adjreason,adj.adjqty,
   out_movement_code,out_errorno,out_msg);
elsif ( (adj.inventoryclass != nvl(adj.newinventoryclass,adj.inventoryclass)) or
      (adj.invstatus != nvl(adj.newinvstatus,adj.invstatus)) ) then
  debugmsg('get_movement_code new ');
  zmi3.get_movement_code(adj.custid,strWhse,adj.inventoryclass,adj.invstatus,
    adj.newinventoryclass,adj.newinvstatus,adj.adjreason,adj.adjqty,
    out_movement_code,out_errorno,out_msg);
else
  out_errorno := 3;
  out_msg := 'No interface needed (offset transaction)';
  return;
end if;

debugmsg('movement is ' || out_movement_code);
if upper(out_movement_code) = 'SKIP' then
  out_errorno := 1;
  out_msg := 'No interface needed (skipped)';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end validate_interface;

procedure get_valid_status_class_reasons
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,out_msg IN out varchar2
) is

mv orderstatus%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(1000);
strMsg varchar2(255);

begin

out_msg := null;
strMsg := null;
mv := null;
mv.code := in_change_type;
if in_change_type = 'CC' then
  mv.code := mv.code || '-' ||
             in_to_inventoryclass || '/' ||
             in_to_invstatus || ':';
else
  mv.code := mv.code || '-' ||
             in_from_invstatus || '/' ||
             in_to_invstatus || ':';
end if;
--zut.prt('mv.code is ' || mv.code);
cmdSql := 'select substr(code,10,2) from SAP_Parms_for_' ||
  rtrim(in_custid) || '_' || rtrim(in_whse) ||
  ' where code like ''' || mv.code || '%''' ||
  ' and substr(code,10,2) != ''??'' order by code ';
--zut.prt(cmdSql);
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,mv.code,2);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,mv.code);
--    zut.prt(mv.code);
    if strMsg is null then
      strMsg := 'Only valid reasons are: ';
    else
      strMsg := strMsg || ',';
    end if;
    strMsg := strMsg || mv.code;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

if strMsg is not null then
  out_msg := strMsg;
end if;

exception when others then
  null;
end get_valid_status_class_reasons;

procedure get_valid_quantity_reasons
(in_change_type IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,out_msg IN out varchar2
) is

mv orderstatus%rowtype;

curSql integer;
cntRows integer;
cmdSql varchar2(1000);
strMsg varchar2(255);

begin

out_msg := null;
strMsg := null;
mv := null;
mv.code := in_change_type || '-' ||
           in_to_invstatus || ':';
--zut.prt('mv.code is ' || mv.code);
cmdSql := 'select substr(code,7,2) from SAP_Parms_for_' ||
  rtrim(in_custid) || '_' || rtrim(in_whse) ||
  ' where code like ''' || mv.code || '%''' ||
  ' and substr(code,7,2) != ''??'' order by code ';
--zut.prt(cmdSql);
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,mv.code,2);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,mv.code);
--    zut.prt(mv.code);
    if strMsg is null then
      strMsg := 'Only valid reasons are: ';
    else
      strMsg := strMsg || ',';
    end if;
    strMsg := strMsg || mv.code;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

if strMsg is not null then
  out_msg := strMsg;
end if;

exception when others then
  null;
end get_valid_quantity_reasons;

procedure get_cust_parm_value
(in_custid IN varchar2
,in_parm IN varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);

begin

out_descr := null;
out_abbrev := null;

cmdSql := 'select descr, abbrev from SAP_Parameters_for_' ||
  rtrim(in_custid) || ' where code = ''' || rtrim(in_parm) || ''' ';
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,out_descr,32);
  dbms_sql.define_column(curSql,2,out_abbrev,12);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows > 0 then
    dbms_sql.column_value(curSql,1,out_descr);
    dbms_sql.column_value(curSql,2,out_abbrev);
  end if;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

exception when others then
  out_descr := null;
  out_abbrev := null;
end get_cust_parm_value;

procedure get_whse
(in_custid IN varchar2
,in_inventoryclass IN varchar2
,out_whse IN OUT varchar2
,out_regular_whse IN OUT varchar2
,out_returns_whse IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);
prm orderstatus%rowtype;
begin

out_whse := null;
out_regular_whse := null;
out_returns_whse := null;

cmdSql := 'select abbrev from class_to_warehouse_' ||
  rtrim(in_custid) || ' where code = ''' || rtrim(in_inventoryclass) || ''' ';
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,out_whse,12);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows > 0 then
    dbms_sql.column_value(curSql,1,out_whse);
  end if;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

zmi3.get_cust_parm_value(in_custid,'REGWHSE',prm.descr,out_regular_whse);
zmi3.get_cust_parm_value(in_custid,'RETWHSE',prm.descr,out_returns_whse);

if (out_whse is null) 
and check_inv_adj_format(in_custid) is not null then
    out_whse := rtrim(in_inventoryclass);
end if;

exception when others then
  null;
end get_whse;

procedure get_whse_parm_value
(in_custid IN varchar2
,in_whse IN varchar2
,in_parm IN varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);

begin

out_descr := null;
out_abbrev := null;

cmdSql := 'select descr, abbrev from SAP_Parms_for_' ||
  rtrim(in_custid) || '_' || rtrim(in_whse) ||
  ' where code = ''' || rtrim(in_parm) || ''' ';
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,out_descr,32);
  dbms_sql.define_column(curSql,2,out_abbrev,12);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows > 0 then
    dbms_sql.column_value(curSql,1,out_descr);
    dbms_sql.column_value(curSql,2,out_abbrev);
  end if;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

exception when others then
  out_descr := null;
  out_abbrev := null;
end get_whse_parm_value;

procedure check_for_shipto_override
(in_custid IN varchar2
,in_shipto IN varchar2
,out_movement_code IN OUT varchar2
)
is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);

begin

out_movement_code := null;

cmdSql := 'select substr(abbrev,1,3) from SAP_ShipTo_Override_' ||
  rtrim(in_custid) || ' where code = ''' || rtrim(in_shipto) || ''' ';
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,out_movement_code,3);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows > 0 then
    dbms_sql.column_value(curSql,1,out_movement_code);
  end if;
  dbms_sql.close_cursor(curSql);
exception when others then
  dbms_sql.close_cursor(curSql);
end;

exception when others then
  null;
end check_for_shipto_override;

procedure get_movement_config_value
(in_code IN varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,out_movement_code IN OUT varchar2
,out_descr IN OUT varchar2
,out_abbrev IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);

begin

out_descr := null;
out_abbrev := null;
out_errorno := 0;
out_msg := null;

cmdSql := 'select upper(descr), upper(abbrev) from SAP_Parms_for_' ||
  rtrim(in_custid) || '_' || rtrim(in_whse) ||
  ' where code = ''' || in_code || ''' ';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
dbms_sql.define_column(curSql,1,out_descr,32);
dbms_sql.define_column(curSql,2,out_abbrev,12);
cntRows := dbms_sql.execute(curSql);
cntRows := dbms_sql.fetch_rows(curSql);
if cntRows > 0 then
  dbms_sql.column_value(curSql,1,out_descr);
  dbms_sql.column_value(curSql,2,out_abbrev);
end if;
dbms_sql.close_cursor(curSql);

if out_descr is null then
  -- zut.prt(cmdsql);
  out_errorno := 1;
  out_msg := 'No entry';
--  zut.prt(out_errorno || ' ' || out_msg);
  return;
end if;

if out_abbrev = 'REJECT' then
  out_errorno := -91;
  out_msg := 'Movement not allowed';
--  zut.prt(out_errorno || ' ' || out_msg);
  return;
end if;

out_movement_code := substr(out_abbrev,1,3);
out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  if (dbms_sql.is_open(curSql)) then
    dbms_sql.close_cursor(curSql);
  end if;
  
  out_errorno := 1;
  out_msg := 'No entry';
--  zut.prt(out_errorno || ' ' || out_msg || 'exception');
end get_movement_config_value;

procedure get_status_or_class_movement
(in_change_type in varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is

mv orderstatus%rowtype;
strMsg varchar2(255);

strDebugYN char(1);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  zut.prt('debug--' || sqlerrm);
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_movement_code := null;
out_errorno := 0;
out_msg := '';

<< exact_class_status_reason >>
mv := null;
mv.code := in_change_type;
if in_change_type = 'CC' then
  mv.code := mv.code || '-' ||
             in_to_inventoryclass || '/' ||
             in_to_invstatus || ':' ||
             in_reason_code;
else
  mv.code := mv.code || '-' ||
             in_from_invstatus || '/' ||
             in_to_invstatus || ':' ||
             in_reason_code;
end if;
debugmsg('exact: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);
if out_errorno <= 0 then
  return;
end if;

<< class_status_any_reason >>
mv.code := substr(mv.code,1,9) || '??';
debugmsg('any reason: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  debugmsg('check valid '  || out_errorno);
  if mv.abbrev = 'REJECT' then
    strMsg := null;
--    zut.prt('call valid');
    zmi3.get_valid_status_class_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,in_from_invstatus,in_to_inventoryclass,
      in_to_invstatus,strMsg);
    if strMsg is not null then
      debugmsg(strMsg);
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    debugmsg(out_msg);
    return;
  else
    debugmsg('optional return ' || out_errorno);
    return;
  end if;
end if;

if in_change_type = 'SC' then
    << class_any_tostatus >>
    mv.code := in_change_type || '-' ||
                 in_from_invstatus || '/' ||
                 '??' || ':' ||
                 in_reason_code;
    debugmsg('any tostatus: >' || mv.code || '<');
    zmi3.get_movement_config_value(mv.code,in_custid,
      in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

    if out_errorno < 0 then
      return;
    end if;

    if out_errorno = 0 then
      if (mv.descr <> 'OPTIONAL') and
         (instr(mv.descr,in_reason_code) <> 0) then
        out_errorno := -92;
        out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
          mv.descr || ')';
        debugmsg(out_msg);
        return;
      else
        debugmsg('optional return ' || out_errorno);
        return;
      end if;
    end if;

    << class_any_fromstatus >>
    mv.code := in_change_type || '-' ||
                 '??' || '/' ||
                 in_to_invstatus || ':' ||
                 in_reason_code;
    debugmsg('any fromstatus: >' || mv.code || '<');
    zmi3.get_movement_config_value(mv.code,in_custid,
      in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

    if out_errorno < 0 then
      return;
    end if;

    if out_errorno = 0 then
      if (mv.descr <> 'OPTIONAL') and
         (instr(mv.descr,in_reason_code) <> 0) then
        out_errorno := -92;
        out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
          mv.descr || ')';
        debugmsg(out_msg);
        return;
      else
        debugmsg('optional return ' || out_errorno);
        return;
      end if;
    end if;

  mv.code := in_change_type || '-' ||
             in_from_invstatus || '/' ||
             in_to_invstatus || ':' ||
             in_reason_code;

end if; -- in_change_type = 'SC'

<< class_any_tostatus_any_reason >>
mv.code := substr(mv.code,1,6) || '??:??';
debugmsg('any tostatusrsn: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    debugmsg(out_msg);
    return;
  else
    debugmsg('optional return ' || out_errorno);
    return;
  end if;
end if;

if out_errorno = 1 then
  if in_change_type = 'CC' then
    return;
  end if;
end if;

<< class_any_fromstat_any_reason >>
mv.code := in_change_type || '-' ||
           '??' || '/' ||
           in_to_invstatus || ':' ||
           '??';
debugmsg('any tostatus: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    out_errorno := 0;
    out_msg := 'OKAY';
    return;
  end if;
end if;

out_errorno := 1;
out_msg := 'No movement mapping exists for this adjustment';

exception when others then
  null;
end get_status_or_class_movement;

procedure get_quantity_movement
(in_change_type in varchar2
,in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is

strMsg varchar2(255);
mv orderstatus%rowtype;
strDebugYN char(1);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  zut.prt('debug--' || sqlerrm);
end;


begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_movement_code := null;
out_errorno := 0;
out_msg := '';

<< exact_status_reason >>
mv := null;
mv.code := in_change_type || '-' ||
           in_to_invstatus || ':' ||
           in_reason_code;
debugmsg('exact: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);
if out_errorno <= 0 then
  return;
end if;

<< exact_status_any_reason >>
mv.code := in_change_type || '-' ||
           in_to_invstatus || ':' ||
           '??';
debugmsg('any reason: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  debugmsg('check valid');
  if mv.abbrev = 'REJECT' then
    strMsg := null;
    debugmsg('call valid');
    zmi3.get_valid_quantity_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,in_from_invstatus,in_to_inventoryclass,
      in_to_invstatus,strMsg);
    if strMsg is not null then
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    return;
  end if;
end if;

<< class_any_stat_exact_reason >>
mv.code := in_change_type || '-' ||
           '??:'||
           in_reason_code;
debugmsg('any fromstatus exact reason: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    out_errorno := 0;
    out_msg := 'OKAY';
    return;
  end if;
end if;

<< class_any_tostatus_any_reason >>
mv.code := substr(mv.code,1,3) || '??:??';
debugmsg('any tostatus: >' || mv.code || '<');
zmi3.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    return;
  end if;
end if;

if out_errorno = 1 then
  if in_change_type = 'CC' then
    return;
  end if;
end if;

out_errorno := 1;
out_msg := 'No movement mapping exists for this adjustment';

exception when others then
  null;
end get_quantity_movement;

procedure get_movement_code
(in_custid IN varchar2
,in_whse IN varchar2
,in_from_inventoryclass IN varchar2
,in_from_invstatus IN varchar2
,in_to_inventoryclass IN varchar2
,in_to_invstatus IN varchar2
,in_reason_code IN varchar2
,in_adjqty IN number
,out_movement_code IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);
mv orderstatus%rowtype;
strPrefix char(2);
strDebugYN char(1);

procedure debugmsg(in_text varchar2) is
begin

  if strDebugYN = 'Y' then
    zut.prt(in_text);
  end if;

exception when others then
  zut.prt('debug--' || sqlerrm);
end;

begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
else
  strDebugYN := 'N';
end if;

out_movement_code := null;
out_errorno := 0;
out_msg := '';

if rtrim(in_custid) is null then
  out_errorno := -100;
  out_msg := 'A Customer ID value is required';
  return;
end if;

if rtrim(in_whse) is null then
  out_errorno := -101;
  out_msg := 'A Warehouse value is required';
  return;
end if;

if rtrim(in_from_inventoryclass) is null then
  out_errorno := -102;
  out_msg := 'A From Inventory Class value is required';
  return;
end if;

if rtrim(in_from_invstatus) is null then
  out_errorno := -103;
  out_msg := 'A From Inventory Status value is required';
  return;
end if;

if rtrim(in_to_inventoryclass) is null then
  out_errorno := -104;
  out_msg := 'A To Inventory Class value is required';
  return;
end if;

if rtrim(in_to_invstatus) is null then
  out_errorno := -105;
  out_msg := 'A To Inventory Status value is required';
  return;
end if;

if rtrim(in_reason_code) is null then
  out_errorno := -106;
  out_msg := 'A Reason Code value is required';
  return;
end if;

if (in_from_inventoryclass != in_to_inventoryclass) and
   (in_from_invstatus != in_to_invstatus) then
  out_errorno := -1;
  out_movement_code := 'Reject';
  out_msg := 'Status and Class must be changed independently';
  return;
end if;

if in_from_inventoryclass != in_to_inventoryclass then
  strPrefix := 'CC';  -- Class Change
elsif in_from_invstatus != in_to_invstatus then
  strPrefix := 'SC';  -- Status Change
elsif in_adjqty > 0 then
  strPrefix := 'QI';  -- Quantity Increase
elsif in_adjqty < 0 then
  strPrefix := 'QD';  -- Quantity Decrease
else
  out_msg := 'Unable to obtain movement code. (zmi3.gmc: -2)';
  out_movement_code := 'N/A';
  out_errorno := -2;
  return;
end if;

debugmsg('strprefix: >' || strPrefix || '<');
if strDebugYN = 'Y' then
  out_errorno := -12345;
end if;

if strPrefix in ('CC','SC') then
  debugmsg('get class status movement');
  zmi3.get_status_or_class_movement(strPrefix,in_custid,in_whse,in_from_inventoryclass,
    in_from_invstatus,in_to_inventoryclass,in_to_invstatus,in_reason_code,
    in_adjqty,out_movement_code,out_errorno,out_msg);
  debugmsg('class status movement is ' || out_movement_code);
else
  debugmsg('get qty movement');
  zmi3.get_quantity_movement(strPrefix,in_custid,in_whse,in_from_inventoryclass,
    in_from_invstatus,in_to_inventoryclass,in_to_invstatus,in_reason_code,
    in_adjqty,out_movement_code,out_errorno,out_msg);
  debugmsg('qty movement is ' || out_movement_code);
end if;

if out_errorno != 0 then
    if check_inv_adj_format(in_custid) is not null then
        out_errorno := 0;
        out_msg := '';
        out_movement_code := strPrefix;
    end if;
end if;

exception when others then
  null;
end get_movement_code;

/*
  CTO - configured-to-order
  STO - ship-to-order
*/
procedure get_cto_sto_prefix
(in_custid IN varchar2
,in_item IN varchar2
,out_prefix IN OUT number
) is

curSql integer;
cntRows integer;
cmdSql varchar2(1000);
pf orderstatus%rowtype;

begin

out_prefix := 20000000;
cmdSql := 'select descr from SAP_CTO_Prefix_' ||
  rtrim(in_custid) || ' order by code ';

--zut.prt('open cursor');
begin
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,pf.descr,32);
  cntRows := dbms_sql.execute(curSql);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curSql);
    if cntRows <= 0 then
      exit;
    end if;
    dbms_sql.column_value(curSql,1,pf.descr);
--    zut.prt('descr is ' || pf.descr);
    if substr(upper(in_item),1,length(pf.descr)) = upper(pf.descr) then
      out_prefix := 10000000;
      exit;
    end if;
  end loop;
  dbms_sql.close_cursor(curSql);
exception when others then
  out_prefix := null;
  dbms_sql.close_cursor(curSql);
end;

exception when others then
  out_prefix := 20000000;
end get_cto_sto_prefix;

procedure reset_cto_sto_prefix
(in_custid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curCustItem is
  select rowid,
         item,
         ctostoprefix
    from custitem
   where custid = in_custid;

intCtoStoPrefix integer;

begin

out_errorno := 0;
out_msg := '';

for ci in curCustitem
loop
  zmi3.get_cto_sto_prefix(in_custid,ci.item,intCtoStoPrefix);
  if nvl(ci.CtoStoPrefix,0) <> nvl(intCtoStoPrefix,0) then
    update custitem
       set CtoStoPrefix = intCtoStoPrefix
     where rowid = ci.rowid;
  end if;
end loop;

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end reset_cto_sto_prefix;

procedure check_for_customer_return
(in_lpid IN varchar2
,in_inventoryclass IN varchar2
,out_is_customer_return IN OUT varchar2
) is

cursor curTransferIn is
  select count(1)
    from invadjactivity
   where lpid = in_lpid
     and inventoryclass = in_inventoryclass
     and inventoryclass != oldinventoryclass
     and adjqty > 0;

cntRows integer;
begin

out_is_customer_return := 'Y';

open curTransferIn;
fetch curTransferIn  into cntRows;
close curTransferIn;
if cntRows <> 0 then
  out_is_customer_return := 'N';
end if;

exception when others then
  out_is_customer_return := 'Y';
end check_for_customer_return;

end zmi3proc;
/
show error package body zmi3proc;
exit;
