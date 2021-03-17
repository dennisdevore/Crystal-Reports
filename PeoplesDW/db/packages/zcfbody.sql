create or replace package body alps.zcreatefuncs
is
--
-- $Id$
--

procedure create_func
(in_custid in varchar2
,in_funcname in varchar2
,out_errorno in out number
,out_msg in out varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(2000);

begin

select count(1)
  into cntRows
  from customer
 where custid = rtrim(in_custid);

if cntRows = 0 then
  out_errorno := -1;
  out_msg := 'Invalid Table Suffix';
  return;
end if;

if rtrim(in_funcname) is null then
  out_errorno := -2;
  out_msg := 'Function Name is Required';
  return;
end if;


cmdSql := 'create or replace function f' || rtrim(in_funcname) ||
 '_' || rtrim(in_custid) || ' (in_invclass varchar2) return varchar2 ' ||
 'is out_value varchar2(32); begin out_value := in_invclass; ' ||
 'begin select abbrev into out_value from ' || rtrim(in_funcname) ||
 '_' || rtrim(in_custid) ||
 ' where code = rtrim(in_invclass); exception when no_data_found then ' ||
 'select abbrev into out_value from ' || rtrim(in_funcname) ||
 '_' || rtrim(in_custid) || ' where code = ''RG''; end; return out_value; ' ||
 ' exception when others then return in_invclass; end;';

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end create_func;

procedure drop_func
(in_custid in varchar2
,in_funcname in varchar2
,out_errorno in out number
,out_msg in out varchar2
) is

curFunc integer;
cntRows integer;
cmdSql varchar2(2000);

begin
cmdSql := 'drop function f' || rtrim(in_funcname) ||
  '_' || rtrim(in_custid);

curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := sqlerrm;
  out_errorno := sqlcode;
end drop_func;

function profid
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2
is

out_profid custitemfacility.profid%type;

begin

out_profid := null;

begin
  select profid
    into out_profid
    from custitemfacility
   where custid = in_custid
     and facility = in_facility
     and item = in_item;
exception when others then
  null;
end;

if nvl(out_profid,'C') = 'C' then
  begin
    select profid
      into out_profid
      from custproductgroupfacility
     where custid = in_custid
       and facility = in_facility
       and productgroup = zci.product_group(in_custid,in_item);
  exception when others then
    null;
  end;
  if nvl(out_profid,'C') = 'C' then
    out_profid := null;
    begin
      select profid
        into out_profid
        from custfacility
       where custid = in_custid
         and facility = in_facility;
    exception when others then
      null;
    end;
  end if;
end if;

return out_profid;

exception when others then
  return null;
end profid;

function allocrule
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2
is

out_allocrule custitemfacility.allocrule%type;

begin

out_allocrule := null;

begin
  select allocrule
    into out_allocrule
    from custitemfacility
   where custid = in_custid
     and facility = in_facility
     and item = in_item;
exception when others then
  null;
end;

if nvl(out_allocrule,'C') = 'C' then
  begin
    select allocrule
      into out_allocrule
      from custproductgroupfacility
     where custid = in_custid
       and facility = in_facility
       and productgroup = zci.product_group(in_custid,in_item);
  exception when others then
    null;
  end;
  if nvl(out_allocrule,'C') = 'C' then
    out_allocrule := null;
    begin
      select allocrule
        into out_allocrule
        from custfacility
       where custid = in_custid
         and facility = in_facility;
    exception when others then
      null;
    end;
  end if;
end if;

return out_allocrule;

exception when others then
  return null;
end allocrule;

function replallocrule
(in_facility varchar2
,in_custid varchar2
,in_item varchar2
) return varchar2
is

out_replallocrule custitemfacility.replallocrule%type;

begin

out_replallocrule := null;

begin
  select replallocrule
    into out_replallocrule
    from custitemfacility
   where custid = in_custid
     and facility = in_facility
     and item = in_item;
exception when others then
  null;
end;

if nvl(out_replallocrule,'C') = 'C' then
  begin
    select replallocrule
      into out_replallocrule
      from custproductgroupfacility
     where custid = in_custid
       and facility = in_facility
       and productgroup = zci.product_group(in_custid,in_item);
  exception when others then
    null;
  end;
  if nvl(out_replallocrule,'C') = 'C' then
    out_replallocrule := null;
    begin
      select replallocrule
        into out_replallocrule
        from custfacility
       where custid = in_custid
         and facility = in_facility;
    exception when others then
      null;
    end;
  end if;
end if;

return out_replallocrule;

exception when others then
  return null;
end replallocrule;

function group_profid
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2
is

out_profid custitemfacility.profid%type;

begin

out_profid := null;

begin
  select profid
    into out_profid
    from custproductgroupfacility
   where custid = in_custid
     and facility = in_facility
     and productgroup = in_productgroup;
exception when others then
  null;
end;

if nvl(out_profid,'C') = 'C' then
  out_profid := null;
  begin
    select profid
      into out_profid
      from custfacility
     where custid = in_custid
       and facility = in_facility;
  exception when others then
    null;
  end;
end if;

return out_profid;

exception when others then
  return null;
end group_profid;

function group_allocrule
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2
is

out_allocrule custitemfacility.allocrule%type;

begin

out_allocrule := null;

begin
  select allocrule
    into out_allocrule
    from custproductgroupfacility
   where custid = in_custid
     and facility = in_facility
     and productgroup = in_productgroup;
exception when others then
  null;
end;

if nvl(out_allocrule,'C') = 'C' then
  out_allocrule := null;
  begin
    select allocrule
      into out_allocrule
      from custfacility
     where custid = in_custid
       and facility = in_facility;
  exception when others then
    null;
  end;
end if;

return out_allocrule;

exception when others then
  return null;
end group_allocrule;

function group_replallocrule
(in_facility varchar2
,in_custid varchar2
,in_productgroup varchar2
) return varchar2
is

out_replallocrule custitemfacility.replallocrule%type;

begin

out_replallocrule := null;

begin
  select replallocrule
    into out_replallocrule
    from custproductgroupfacility
   where custid = in_custid
     and facility = in_facility
     and productgroup = in_productgroup;
exception when others then
  null;
end;

if nvl(out_replallocrule,'C') = 'C' then
  out_replallocrule := null;
  begin
    select replallocrule
      into out_replallocrule
      from custfacility
     where custid = in_custid
       and facility = in_facility;
  exception when others then
    null;
  end;
end if;

return out_replallocrule;

exception when others then
  return null;
end group_replallocrule;

end zcreatefuncs;

/
show error package body zcreatefuncs;
--exit;

