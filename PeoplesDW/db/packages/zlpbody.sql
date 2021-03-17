create or replace PACKAGE BODY alps.zplate
IS
--
-- $Id$
--

FUNCTION platestatus_abbrev
(in_platestatus IN varchar2
) return varchar2 is

out licenseplatestatus%rowtype;

begin

select abbrev
  into out.abbrev
  from licenseplatestatus
 where code = in_platestatus;

return out.abbrev;

exception when others then
  return in_platestatus;
end platestatus_abbrev;

FUNCTION invstatus_abbrev
(in_invstatus IN varchar2
) return varchar2 is

out inventorystatus%rowtype;

begin

select abbrev
  into out.abbrev
  from inventorystatus
 where code = in_invstatus;

return out.abbrev;

exception when others then
  return in_invstatus;
end invstatus_abbrev;

FUNCTION handlingtype_abbrev
(in_handlingtype IN varchar2
) return varchar2 is

out handlingtypes%rowtype;

begin

select abbrev
  into out.abbrev
  from handlingtypes
 where code = in_handlingtype;

return out.abbrev;

exception when others then
  return in_handlingtype;
end handlingtype_abbrev;

FUNCTION inventoryclass_abbrev
(in_inventoryclass IN varchar2
) return varchar2 is

out inventoryclass%rowtype;

begin

select abbrev
  into out.abbrev
  from inventoryclass
 where code = in_inventoryclass;

return out.abbrev;

exception when others then
  return in_inventoryclass;
end inventoryclass_abbrev;

FUNCTION platetype_abbrev
(in_platetype IN varchar2
) return varchar2 is

out licenseplatetypes%rowtype;

begin

select abbrev
  into out.abbrev
  from licenseplatetypes
 where code = in_platetype;

return out.abbrev;

exception when others then
  return in_platetype;
end platetype_abbrev;

FUNCTION condition_abbrev
(in_condition IN varchar2
) return varchar2 is

out receiptcondition%rowtype;

begin

select abbrev
  into out.abbrev
  from receiptcondition
 where code = in_condition;

return out.abbrev;

exception when others then
  return in_condition;
end condition_abbrev;


FUNCTION holdreason_abbrev
(in_holdreason IN varchar2
) return varchar2 is

out holdreasons%rowtype;

begin

select abbrev
  into out.abbrev
  from holdreasons
 where code = in_holdreason;

return out.abbrev;

exception when others then
  return in_holdreason;
end holdreason_abbrev;

FUNCTION adjreason_abbrev
(in_adjreason IN varchar2
) return varchar2 is

out adjustmentreasons%rowtype;

begin

select abbrev
  into out.abbrev
  from adjustmentreasons
 where code = in_adjreason;

return out.abbrev;

exception when others then
  return in_adjreason;
end adjreason_abbrev;

FUNCTION tasktype_abbrev
(in_tasktype IN varchar2
) return varchar2 is

out tasktypes%rowtype;

begin

select abbrev
  into out.abbrev
  from tasktypes
 where code = in_tasktype;

return out.abbrev;

exception when others then
  return in_tasktype;
end tasktype_abbrev;

FUNCTION expiryaction_abbrev
(in_expiryaction IN varchar2
) return varchar2 is

out expirationactions%rowtype;

begin

select abbrev
  into out.abbrev
  from expirationactions
 where code = in_expiryaction;

return out.abbrev;

exception when others then
  return in_expiryaction;
end expiryaction_abbrev;

PROCEDURE plate_to_deletedplate
(in_lpid IN varchar2
,in_userid IN varchar2
,in_tasktype IN varchar2
,out_msg IN OUT varchar2
) is
qtyPlate plate.quantity%type;

begin

begin
  select quantity
    into qtyPlate
    from plate
  where lpid = in_lpid;
exception when no_data_found then
  out_msg := 'Plate row not found';
  return;
end;

out_msg := null;

if qtyPlate <> 0 then
  update plate
     set quantity = 0,
         lasttask = nvl(in_tasktype,'DE'),
         lastuser = in_userid,
         lastupdate = sysdate
   where lpid = in_lpid;
end if;

delete from deletedplate
 where lpid = in_lpid;

insert into deletedplate
  select *
    from plate
   where lpid = in_lpid;

delete from plate
 where lpid = in_lpid;

exception when others then
  out_msg := 'lpptd ' || sqlerrm;
end;

FUNCTION shippingplatestatus_abbrev
(in_shippingplatestatus IN varchar2
) return varchar2 is

out shippingplatestatus%rowtype;

begin

select abbrev
  into out.abbrev
  from shippingplatestatus
 where code = in_shippingplatestatus;

return out.abbrev;

exception when others then
  return in_shippingplatestatus;
end shippingplatestatus_abbrev;

FUNCTION shippingplatetype_abbrev
(in_shippingplatetype IN varchar2
) return varchar2 is

out shippingplatetypes%rowtype;

begin

select abbrev
  into out.abbrev
  from shippingplatetypes
 where code = in_shippingplatetype;

return out.abbrev;

exception when others then
  return in_shippingplatetype;
end shippingplatetype_abbrev;

FUNCTION phyinv_difference
(in_status IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_location IN varchar2
,in_systemcount IN number
,in_countcustid IN varchar2
,in_countitem IN varchar2
,in_countlot IN varchar2
,in_countlocation IN varchar2
,in_usercount IN number
) return varchar2
is

strDifference varchar2(255);

function append_comma(in_text IN varchar2)
return varchar2
is
strOut varchar(255);
begin
strOut := rtrim(in_text);
if Length(strOut) <> 0 then
  strOut := strOut || ',';
end if;
return strOut;
exception when others then
  return in_text;
end;

begin

if in_status not in ('CT','NC','PR') then
  return null;
end if;

strDifference := '';

if nvl(rtrim(in_custid),'x') <> nvl(rtrim(in_countcustid),'x') then
  strDifference := append_comma(strDifference) || 'Customer';
end if;

if nvl(rtrim(in_item),'x') <> nvl(rtrim(in_countitem),'x') then
  strDifference := append_comma(strDifference) || 'Item';
end if;

if nvl(rtrim(in_lotnumber),'x') <> nvl(rtrim(in_countlot),'x') then
  strDifference := append_comma(strDifference) || 'Lot';
end if;

if nvl(in_systemcount,0) <> nvl(in_usercount,0) then
  strDifference := append_comma(strDifference) || 'Quantity';
end if;

if nvl(in_location,'x') <> nvl(in_countlocation,'x') then
  strDifference := append_comma(strDifference) || 'Location';
end if;

if (strDifference is null) and
   (in_status = 'NC') then
  strDifference := 'Inventory Found';
end if;

return strDifference;

exception when others then
  return null;
end phyinv_difference;


FUNCTION is_lpid
(in_lpid IN varchar2
) return boolean
is
   l_search_set varchar2(64);
   l_replace_set varchar2(64);
begin

   if nvl(zci.default_value('ALPHANUMERICLIPS'),'N') = 'Y' then
      l_search_set := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXZY';
   else
      l_search_set := '0123456789';
   end if;
   l_replace_set := lpad('n',length(l_search_set),'n');

   if (translate(in_lpid, l_search_set, l_replace_set) = 'nnnnnnnnnnnnnnn') then
      return true;
   else
      return false;
   end if;

exception when others then
  return false;
end is_lpid;


end zplate;
/
show error package body zplate;
exit;
