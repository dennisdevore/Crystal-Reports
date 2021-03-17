create or replace package body alps.zediproc as
--
-- $Id$
--

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

begin

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

zmi3.get_whse(adj.custid,adj.inventoryclass,strWhse,strRegWhse,strRetWhse);

if strWhse is null then
  out_errorno := 1;
  out_msg := 'No interface needed (not a relevant warehouse)';
  return;
end if;

zedi.get_cust_parm_value(adj.custid,'947INVADJFMT',prm.descr,prm.abbrev);
if prm.descr is null then
   zedi.get_cust_parm_value(adj.custid,'852PRDACTFMT',prm.descr,prm.abbrev);
end if;

if prm.descr is null then
  out_errorno := 2;
  out_msg := 'No interface needed (no format defined)';
  return;
end if;

if ( (adj.newcustid is null) and (adj.oldcustid is null) ) or
     ( (adj.custid != nvl(adj.newcustid,adj.custid)) or
       (adj.item != nvl(adj.newitem,adj.item)) ) or
     ( (adj.custid != nvl(adj.oldcustid,adj.custid)) or
       (adj.item != nvl(adj.olditem,adj.item)) ) and
    ( adj.adjqty != 0 ) then
  zedi.get_movement_code(adj.custid,strWhse,adj.inventoryclass,adj.invstatus,
   adj.inventoryclass,adj.invstatus,adj.adjreason,adj.adjqty,
   out_movement_code,out_errorno,out_msg);
elsif ( (adj.inventoryclass != nvl(adj.newinventoryclass,adj.inventoryclass)) or
      (adj.invstatus != nvl(adj.newinvstatus,adj.invstatus)) ) then
  zedi.get_movement_code(adj.custid,strWhse,adj.inventoryclass,adj.invstatus,
    adj.newinventoryclass,adj.newinvstatus,adj.adjreason,adj.adjqty,
    out_movement_code,out_errorno,out_msg);
else
  out_errorno := 3;
  out_msg := 'No interface needed (offset transaction)';
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
cmdSql := 'select substr(code,10,2) from EDI_Parms_for_' ||
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
cmdSql := 'select substr(code,7,2) from EDI_Parms_for_' ||
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

cmdSql := 'select descr, abbrev from EDI_Parameters_for_' ||
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

cmdSql := 'select descr, abbrev from EDI_Parms_for_' ||
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

cmdSql := 'select substr(abbrev,1,3) from EDI_ShipTo_Override_' ||
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

cmdSql := 'select upper(descr), upper(abbrev) from EDI_Parms_for_' ||
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
  out_errorno := 1;
  out_msg := 'No entry';
--  zut.prt(out_errorno || ' ' || out_msg);
  return;
end if;

if out_abbrev = 'REJECT' then
  out_errorno := -95;
  out_msg := 'Adjustment not allowed';
--  zut.prt('     Code:'||in_code||out_errorno || ' ' || out_msg);
  return;
end if;

out_movement_code := rtrim(out_abbrev); -- substr(out_abbrev,1,3);
out_errorno := 0;
out_msg := 'OKAY';

exception when others then
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

orig_mv_code mv.code%type;

begin

out_movement_code := null;
out_errorno := 0;
out_msg := '';

--
-- Priority of searhcing for matches
--    XX - Old status
--    YY - New Status
--    ZZ - reason given
--
--      SC-XX/YY:ZZ
--      SC-XX/YY:??   Can list not avail reasons
--      SC-XX/??:ZZ   Can list not avail to status
--      SC-??/YY:ZZ   Can list not avail from status
--      SC-XX/??:??
--      SC-??/YY:??
--


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
--zut.prt('exact: >' || mv.code || '<');
orig_mv_code := mv.code;

zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);
if (out_errorno = 0 and mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
elsif out_errorno <= 0 then
  return;
end if;

<< class_status_any_reason >>
mv.code := substr(orig_mv_code,1,9) || '??';
--zut.prt('any reason: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
--  zut.prt('check valid');
  if mv.abbrev = 'REJECT' then
    strMsg := null;
--    zut.prt('call valid');
    zedi.get_valid_status_class_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,in_from_invstatus,in_to_inventoryclass,
      in_to_invstatus,strMsg);
    if strMsg is not null then
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    return;
  end if;
end if;

-- NEW
<< class_any_fromstat >>
mv.code := in_change_type || '-' ||
           '??' || '/' ||
           in_to_invstatus || ':' ||
           in_reason_code;
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_from_invstatus) <> 0) then
    out_errorno := -93;
    out_msg := 'From status not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    out_errorno := 0;
    out_msg := 'OKAY';
    return;
  end if;
end if;


<< class_any_tostat >>
mv.code := substr(orig_mv_code,1,6) ||
           '??' || ':' ||
           in_reason_code;
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_to_invstatus) <> 0) then
    out_errorno := -94;
    out_msg := 'To status not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    out_errorno := 0;
    out_msg := 'OKAY';
    return;
  end if;
end if;


-- END NEW

<< class_any_tostatus_any_reason >>
mv.code := substr(orig_mv_code,1,6)
           || '??:??';
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  if mv.abbrev = 'REJECT' then -- NEW TEST
    strMsg := null;
--    zut.prt('call valid');
    zedi.get_valid_status_class_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,in_from_invstatus,in_to_inventoryclass,
      '??',strMsg);
    if strMsg is not null then
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
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

<< class_any_fromstat_any_reason >>
mv.code := in_change_type || '-' ||
           '??' || '/' ||
           in_to_invstatus || ':' ||
           '??';
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  if mv.abbrev = 'REJECT' then -- NEW TEST
    strMsg := null;
--    zut.prt('call valid');
    zedi.get_valid_status_class_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,'??','??',
      in_to_invstatus,strMsg);
    if strMsg is not null then
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
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

begin

out_movement_code := null;
out_errorno := 0;
out_msg := '';

<< exact_status_reason >>
mv := null;
mv.code := in_change_type || '-' ||
           in_to_invstatus || ':' ||
           in_reason_code;
--zut.prt('exact: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);
if (out_errorno = 0 and mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
elsif out_errorno <= 0 then
--  zut.prt(out_errorno);
  return;
end if;

<< exact_status_any_reason >>
mv.code := substr(mv.code,1,6) || '??';
--zut.prt('any reason: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
--  zut.prt('check valid');
  if mv.abbrev = 'REJECT' then
    strMsg := null;
--    zut.prt('call valid');
    zedi.get_valid_quantity_reasons(in_change_type,in_custid,in_whse,
      in_from_inventoryclass,in_from_invstatus,in_to_inventoryclass,
      in_to_invstatus,strMsg);
    if strMsg is not null then
      out_msg := strMsg;
    end if;
  end if;
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
     (instr(mv.descr,in_reason_code) <> 0) then
    out_errorno := -92;
    out_msg := 'Reason Code not allowed (Disallowed codes: ' ||
      mv.descr || ')';
    return;
  else
    return;
  end if;
end if;

<< class_any_tostatus_any_reason >>
mv.code := substr(mv.code,1,3) || '??:??';
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
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

<< class_any_fromstat_any_reason >>
mv.code := in_change_type || '-' ||
           '??' || '/' ||
           in_to_invstatus || ':' ||
           '??';
--zut.prt('any tostatus: >' || mv.code || '<');
zedi.get_movement_config_value(mv.code,in_custid,
  in_whse,out_movement_code,mv.descr,mv.abbrev,out_errorno,out_msg);

if out_errorno < 0 then
  return;
end if;

if out_errorno = 0 then
  if (mv.abbrev = 'SKIP') then
    out_errorno := 4;
    out_msg := 'No interface needed (skip)';
    return;
  elsif (mv.descr <> 'OPTIONAL') and
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

begin

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
  out_movement_code := 'N/A';
  out_errorno := 2;
  return;
end if;

--zut.prt('strprefix: >' || strPrefix || '<');
if strPrefix in ('CC','SC') then
  zedi.get_status_or_class_movement(strPrefix,in_custid,in_whse,in_from_inventoryclass,
    in_from_invstatus,in_to_inventoryclass,in_to_invstatus,in_reason_code,
    in_adjqty,out_movement_code,out_errorno,out_msg);
else
--  zut.prt('get quantity');
  zedi.get_quantity_movement(strPrefix,in_custid,in_whse,in_from_inventoryclass,
    in_from_invstatus,in_to_inventoryclass,in_to_invstatus,in_reason_code,
    in_adjqty,out_movement_code,out_errorno,out_msg);
end if;

exception when others then
  null;
end get_movement_code;


function get_sscc18_code
(
    in_custid   IN  varchar2,
    in_type     IN  varchar2,
    in_lpid     IN  varchar2
)
return varchar2
is
   sscc varchar2(20);

   cursor C_CUST(in_custid varchar2)
   IS
     SELECT manufacturerucc
       FROM customer
      WHERE custid = in_custid;


   cursor C_SP(in_lpid varchar2)
   IS
    SELECT type, quantity
      FROM shippingplate
     WHERE lpid = in_lpid;

   SP C_SP%rowtype;


   manucc varchar2(7);

   ix integer;

   cc integer;
   cnt integer;

   l_type varchar2(1);
begin

    SP := null;
    OPEN C_SP(in_lpid);
    FETCH C_SP into SP;
    CLOSE C_SP;

    l_type := in_type;

    if l_type = '?' then
        if nvl(SP.type,'M') = 'M'
         and nvl(SP.quantity,1) > 1 then
            l_type := '1';
        else
            l_type := '0';
        end if;
    end if;

    manucc := null;

    OPEN C_CUST(in_custid);
    FETCH C_CUST into manucc;
    CLOSE C_CUST;

    if manucc is null then
       manucc := '0000000';
    end if;

    if length(manucc) < 7 then
       manucc := lpad(manucc,7,'0');
    end if;

    sscc := '00'|| lpad(substr(l_type,1,1),1,'1')
                   || manucc || substr(rtrim(in_lpid,'S'), -9);

    cc := 0;

    for cnt in 1..19 loop
      ix := substr(sscc,cnt,1);

      if mod(cnt,2) = 0 then
        cc := cc + ix;
      else
        cc := cc + (3 * ix);
      end if;

    end loop;


    cc := mod(10 - mod(cc,10),10);

    sscc := sscc || to_char(cc);


    return sscc;

exception when others then
   return '00000000000000000000';
end get_sscc18_code;

function get_sscc14_code
(
    in_type     IN  varchar2,
    in_upc      IN  varchar2
)
return varchar2
is
   sscc varchar2(14);

   manucc varchar2(7);

   ix integer;

   cc integer;
   cnt integer;
begin

    if rtrim(in_upc,' ') is null then
       return '              ';
    end if;

    sscc := in_type || '0'
            ||  substr(in_upc,1,11);

    cc := 0;

    for cnt in 1..13 loop
      ix := substr(sscc,cnt,1);

      if mod(cnt,2) = 0 then
        cc := cc + ix;
      else
        cc := cc + (3 * ix);
      end if;

    end loop;


    cc := mod(10 - mod(cc,10),10);

    sscc := sscc || to_char(cc);


    return sscc;

exception when others then
   return '              ';
end get_sscc14_code;


function check_ancestor
(
    in_plpid    IN  varchar2,
    in_clpid    IN  varchar2
)
return varchar2
is
  CURSOR C_PLT(in_lpid varchar2)
  IS
    SELECT parentlpid
      FROM shippingplate
     WHERE lpid = in_lpid;

  PLT C_PLT%rowtype;

  rc varchar2(1);
begin
    rc := 'N';

    if in_plpid = in_clpid then
       return 'N';
    end if;

    PLT := null;

    PLT.parentlpid := in_clpid;

    while PLT.parentlpid is not null
    loop
        OPEN C_PLT(PLT.parentlpid);
        FETCH C_PLT into PLT;
        CLOSE C_PLT;

        if PLT.parentlpid = in_plpid then
           return 'Y';
        end if;
    end loop;

    return rc;

exception when others then
   return 'N';
end check_ancestor;


function get_ucc128_code
   (in_custid in varchar2,
    in_type   in varchar2,
    in_lpid   in varchar2,
    in_seq    in number)
return varchar2
is
   cursor c_cust is
     select manufacturerucc
       from customer
      where custid = in_custid;
   manucc customer.manufacturerucc%type := null;
   ucc128 varchar2(20);
   ix integer;
   cc integer;
   cnt integer;
begin
   open c_cust;
   fetch c_cust into manucc;
   close c_cust;

   if manucc is null then
      manucc := '0000000';
   elsif length(manucc) < 7 then
      manucc := lpad(manucc, 7, '0');
   end if;

   ucc128 := '00'|| lpad(substr(in_type, 1, 1), 1, '1')
                 || manucc || substr(rtrim(in_lpid, 'S'), -5)
                 || lpad(in_seq, 4, '0');

   cc := 0;
   for cnt in 1..19 loop
      ix := substr(ucc128, cnt, 1);

      if mod(cnt, 2) = 0 then
         cc := cc + ix;
      else
         cc := cc + (3 * ix);
      end if;
   end loop;

   cc := mod(10 - mod(cc, 10), 10);
   ucc128 := ucc128 || to_char(cc);
   return ucc128;

exception
   when others then
      return '00000000000000000000';
end get_ucc128_code;


function get_load_stop_seq
   (in_orderid in number,
    in_shipid  in number)
return number
is

cursor C_ORD(in_orderid number, in_shipid number)
IS

SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;

ORD orderhdr%rowtype;

cursor C_CUST(in_custid varchar2)
IS
SELECT assign_stop_by_passthru_yn,
       assign_stop_load_passthru,
       assign_stop_stop_passthru
  FROM customer
 WHERE custid = in_custid;

CUST C_CUST%rowtype;

seq integer;

sqlcode varchar2(3000);

l_load number;
l_stop number;

begin
    seq := 0;

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    CUST := null;
    OPEN C_CUST(ORD.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if nvl(CUST.assign_stop_by_passthru_yn,'N') <> 'Y' then
        return -1;
    end if;


    sqlcode := 'select '||
            CUST.assign_stop_load_passthru ||','||
            CUST.assign_stop_stop_passthru ||
            ' from orderhdr where orderid = '||in_orderid ||
            ' and shipid = '||in_shipid;

    zut.prt(sqlcode);


    begin
        execute immediate sqlcode
            INTO l_load, l_stop;

    exception when others then
        zut.prt('Error:'||sqlerrm);

        return -2;
    end;

    return l_stop;

    sqlcode := 'select distinct '||
            CUST.assign_stop_load_passthru ||' load,'||
            CUST.assign_stop_stop_passthru ||' stop '||
            ' from orderhdr where fromfacility = '''||ORD.fromfacility||''''||
            ' and custid = '''||ORD.custid||''''||
            ' and ordertype = ''O'''||
            ' and orderstatus < 8 '||
            ' orderby '||CUST.assign_stop_stop_passthru;





    return seq;
exception
   when others then
      return -3;
end;


function get_custom_bol
    (in_orderid number,
     in_shipid  number)
return varchar2
is
    cmd varchar2(1000);

    cbol varchar2(100);



CURSOR C_ORDER
IS
    select O.custid,
           C.customBOL,
           nvl(L.billoflading,nvl(O.billoflading,O.orderid||'-'||O.shipid)) bol
      from loads L, customer C, orderhdr O
     where O.orderid = in_orderid
       and O.shipid = in_shipid
       and C.custid = O.custid
       and O.loadno = L.loadno(+);

ORD C_ORDER%rowtype;

begin
    cbol := in_orderid||'-'||in_shipid;

    ORD := null;
    OPEN C_ORDER;
    FETCH C_ORDER into ORD;
    CLOSE C_ORDER;

    if ORD.custid is not null then
        cbol := ORD.bol;
    end if;

    if ORD.customBOL is null then
        return cbol;
    end if;

    cmd := 'select '||ord.customBOL||' from loads L, customer C, orderhdr O '||
    ' where O.orderid = '||in_orderid ||' and O.shipid = '||in_shipid ||
    ' and C.custid = O.custid and O.loadno = L.loadno(+)';

    execute immediate cmd into cbol;

    return cbol;
exception when others then
    return cbol;
end get_custom_bol;

function check_custom_bol
    (in_orderid number,
     in_shipid  number,
     in_cbol    varchar2)
return varchar2
is
    cmd varchar2(1000);

    cbol varchar2(100);

    errmsg varchar2(200);
begin
    errmsg := 'Invalid SQL';

    cmd := 'select '||in_cBOL||' from loads L, customer C, orderhdr O '||
    ' where O.orderid = '||nvl(in_orderid,0)
    ||' and O.shipid = '||nvl(in_shipid,0) ||
    ' and C.custid = O.custid and O.loadno = L.loadno(+)';

    begin
      cbol := null;
      execute immediate cmd into cbol;
    exception when no_data_found then
        null;
    end;

    if cbol is not null then
        return 'OKAY The BOL is :'||cbol;
    end if;

    return 'OKAY ';
exception when others then
    return substr(sqlerrm,1,200);

end check_custom_bol;


function import_po
    (in_custid  varchar2,
     in_po      varchar2,
     in_ord_po  varchar2)
return varchar2
is

CURSOR C_CA(in_custid varchar2)
IS
SELECT unique_order_identifier
  FROM customer_aux
 WHERE custid = in_custid;

CA C_CA%rowtype;

ans varchar2(1);
begin
    ans := 'Y';

    CA := null;
    OPEN C_CA(in_custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

    if CA.unique_order_identifier = 'P' then
        if nvl(in_po,'(no po!)') != nvl(in_ord_po,'(no po!)') then
            return 'N';
        end if;
    end if;

    return ans;
exception when others then
    return 'Y';
end import_po;

PROCEDURE edi_import_log
   (in_transaction   in varchar2,
    in_importfileid in varchar2,
    in_custid   in varchar2,
    in_msgtext  in varchar2,
    out_msg     in out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   l_start pls_integer := 1;
   l_remain pls_integer := nvl(length(in_msgtext),0);
   l_len pls_integer;
begin
   out_msg := '';

   l_len := least(l_remain, 255); --only allow first 255
   insert into ediimportlog
      (created,
       transaction,
       importfileid,
       custid,
       msgtext)
    values
      (systimestamp,
       in_transaction,
       in_importfileid,
       in_custid,
       substr(in_msgtext, l_start, l_len));

   commit;
   out_msg := 'OKAY';

exception when others then
  out_msg := 'zedil ' || substr(sqlerrm,1,80);
  rollback;
end edi_import_log;


end zediproc;
/
show error package body zediproc;
exit;
