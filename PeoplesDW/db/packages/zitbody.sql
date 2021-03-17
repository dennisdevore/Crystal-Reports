create or replace PACKAGE BODY alps.zitem
IS
--
-- $Id$
--

FUNCTION uom_abbrev
(in_uom IN varchar2
) return varchar2 is

out unitsofmeasure%rowtype;

begin

select abbrev
  into out.abbrev
  from unitsofmeasure
 where code = in_uom;

return out.abbrev;

exception when others then
  return in_uom;
end uom_abbrev;

FUNCTION status_abbrev
(in_status IN varchar2
) return varchar2 is

out itemstatus%rowtype;

begin

select abbrev
  into out.abbrev
  from itemstatus
 where code = in_status;

return out.abbrev;

exception when others then
  return in_status;
end status_abbrev;

FUNCTION item_abbrev
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

out custitem%rowtype;

begin

select abbrev
  into out.abbrev
  from custitem
 where custid = in_custid
   and item = in_item;

return out.abbrev;

exception when others then
  return in_item;
end item_abbrev;


FUNCTION item_productgroup
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

out custitem%rowtype;

begin

select productgroup
  into out.productgroup
  from custitem
 where custid = in_custid
   and item = in_item;

return out.productgroup;

exception when others then
  return null;
end item_productgroup;


FUNCTION item_descr
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

out_descr custitem.descr%type;

begin

select descr
  into out_descr
  from custitem
 where custid = in_custid
   and item = in_item;

return out_descr;

exception when others then
  return in_item;
end item_descr;

FUNCTION backorder_abbrev
(in_backorder IN varchar2
) return varchar2 is

out backorderpolicy%rowtype;

begin

select abbrev
  into out.abbrev
  from backorderpolicy
 where code = in_backorder;

return out.abbrev;

exception when others then
  return in_backorder;
end backorder_abbrev;

FUNCTION qtytype_abbrev
(in_qtytype IN varchar2
) return varchar2 is

out orderquantitytypes%rowtype;

begin

select abbrev
  into out.abbrev
  from orderquantitytypes
 where code = in_qtytype;

return out.abbrev;

exception when others then
  return in_qtytype;
end qtytype_abbrev;


PROCEDURE max_uom
(in_custid IN varchar2
,in_item IN varchar2
,out_maxuom IN OUT varchar2
) is

cursor curCustItem is
  select baseuom
    from custitemview
   where custid = in_custid
     and item = in_item;
it curCustItem%rowtype;

cursor curCustItemUom(in_uom varchar2) is
  select touom
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_uom;
iu curCustItemUom%rowtype;

cntLoop integer;

begin

out_maxuom := 'EA';

open curCustItem;
fetch curCustItem into it.baseuom;
if curCustItem%notfound then
  close curCustItem;
  return;
end if;
close curCustItem;

out_maxuom := it.baseuom;
cntLoop := 0;
while (1=1) loop
  open curCustItemUom(out_maxuom);
  fetch curCustItemUom into iu;
  if curCustItemUom%notfound then
    close curCustItemUom;
    exit;
  end if;
  close curCustItemUom;
  out_maxuom := iu.touom;
  cntLoop := cntLoop + 1;
  if cntLoop > 64 then
    exit;
  end if;
end loop;

return;

exception when others then
  return;
end max_uom;

FUNCTION alloc_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number is

out_alloc_qty custitemtot.qty%type;

begin

out_alloc_qty := 0;

if rtrim(in_facility) is null then
  select nvl(sum(qty),0)
    into out_alloc_qty
  from custitemtotsumavailview
  where custid = in_custid
    and item = in_item
    and invstatus in ('AV');
else
  select nvl(sum(qty),0)
    into out_alloc_qty
  from custitemtotsumavailview
  where custid = in_custid
    and item = in_item
    and facility = in_facility
    and invstatus in ('AV');
end if;

return nvl(out_alloc_qty,0);

exception when others then
  return 0;
end alloc_qty;

FUNCTION alloc_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number is

out_alloc_weight custitemtot.weight%type;

begin

out_alloc_weight := 0;

if rtrim(in_facility) is null then
  select nvl(sum(weight),0)
    into out_alloc_weight
  from custitemtotsumavailview
  where custid = in_custid
    and item = in_item
    and invstatus in ('AV');
else
  select nvl(sum(weight),0)
    into out_alloc_weight
  from custitemtotsumavailview
  where custid = in_custid
    and item = in_item
    and facility = in_facility
    and invstatus in ('AV');
end if;

return out_alloc_weight;

exception when others then
  return 0;
end alloc_weight;

FUNCTION alloc_qty_class
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
,in_inventoryclass IN varchar2
) return number is

out_alloc_qty custitemtot.qty%type;

begin

out_alloc_qty := 0;

if rtrim(in_facility) is null then
  select sum(nvl(qty,0) * zci.custitem_sign(status))
    into out_alloc_qty
  from custitemtot
  where custid = in_custid
    and item = in_item
    and invstatus in ('AV')
    and inventoryclass = in_inventoryclass
    and zci.custitem_projected(status) = 1;
else
  select sum(nvl(qty,0) * zci.custitem_sign(status))
    into out_alloc_qty
  from custitemtot
  where custid = in_custid
    and facility = in_facility
    and item = in_item
    and invstatus in ('AV')
    and inventoryclass = in_inventoryclass
    and zci.custitem_projected(status) = 1;
end if;
return nvl(out_alloc_qty,0);

exception when others then
  return 0;
end alloc_qty_class;

FUNCTION not_avail_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
,in_inventoryclass IN varchar2
) return number is

out_not_avail_qty custitemtot.qty%type;

begin

out_not_avail_qty := 0;

if rtrim(in_facility) is null then
  if rtrim(in_inventoryclass) is null then
    select nvl(sum(qty),0)
      into out_not_avail_qty
    from custitemtot
    where custid = in_custid
      and item = in_item
      and invstatus not in ('AV','SU')
      and zci.custitem_projected(status) = 1
      and zci.custitem_sign(status) > 0;
  else
    select nvl(sum(qty),0)
      into out_not_avail_qty
    from custitemtot
    where custid = in_custid
      and item = in_item
      and invstatus not in ('AV','SU')
      and inventoryclass = in_inventoryclass
      and zci.custitem_projected(status) = 1
      and zci.custitem_sign(status) > 0;
  end if;
else
  if rtrim(in_inventoryclass) is null then
    select nvl(sum(qty),0)
      into out_not_avail_qty
    from custitemtot
    where custid = in_custid
      and facility = in_facility
      and item = in_item
      and invstatus not in ('AV','SU')
      and zci.custitem_projected(status) = 1
      and zci.custitem_sign(status) > 0;
  else
    select nvl(sum(qty),0)
      into out_not_avail_qty
    from custitemtot
    where custid = in_custid
      and facility = in_facility
      and item = in_item
      and invstatus not in ('AV','SU')
      and inventoryclass = in_inventoryclass
      and zci.custitem_projected(status) = 1
      and zci.custitem_sign(status) > 0;
  end if;
end if;

return nvl(out_not_avail_qty,0);

exception when others then
  return 0;
end not_avail_qty;

FUNCTION no_neg
(in_number IN number
) return number is
begin

if nvl(in_number,0) < 0 then
  return 0;
else
  return in_number;
end if;

exception when others then
  return 0;
end no_neg;

FUNCTION alias_by_descr
(in_custid IN varchar2
,in_item IN varchar2
,in_aliasdesc IN varchar2
) return varchar2 is

cursor curAliasByDescr is
  select itemalias
    from custitemalias
   where custid = in_custid
     and item = in_item
     and upper(aliasdesc) = upper(in_aliasdesc);

cursor curDefaultAlias is
  select itemalias
    from custitemalias
   where custid = in_custid
     and item = in_item
   order by itemalias;

out_itemalias custitemalias.itemalias%type;

begin

out_itemalias := null;

open curAliasByDescr;
fetch curAliasByDescr into out_itemalias;
close curAliasByDescr;

if out_itemalias is null then
  open curDefaultAlias;
  fetch curDefaultAlias into out_itemalias;
  close curDefaultAlias;
end if;

return out_itemalias;

exception when others then
  return in_item;
end alias_by_descr;

FUNCTION committed_picknotship_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_facility IN varchar2
) return number is

out_tot_qty custitemtot.qty%type;

begin

out_tot_qty := 0;

if rtrim(in_facility) is null then
  select nvl(sum(qty),0)
    into out_tot_qty
    from custitemtot
   where custid = in_custid
     and item = in_item
     and status in ('PN','CM');
else
  select nvl(sum(qty),0)
    into out_tot_qty
    from custitemtot
   where custid = in_custid
     and item = in_item
     and facility = in_facility
     and status in ('PN','CM');
end if;

return nvl(out_tot_qty,0);

exception when others then
  return 0;
end committed_picknotship_qty;

end zitem;

/
show error package body zitem;
exit;
