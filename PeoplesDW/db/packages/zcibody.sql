create or replace PACKAGE BODY alps.zcustitem IS
--
-- $Id$
--


-- Private functions


function uom_to_uom
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_from_uom in varchar2,
    in_to_uom   in varchar2,
    in_skips    in varchar2,
    in_level    in integer)
return number
is
   l_qty number := -1;
   l_level number;
   errmsg VARCHAR2(200);
begin

   l_level := in_level;
   
   zbut.from_uom_to_uom(in_custid, in_item, in_qty, in_to_uom, in_from_uom, in_skips, l_level,
      l_qty, errmsg);

   if (errmsg <> 'OKAY') then
      l_qty := -1;
   end if;

   return l_qty;

exception
   when OTHERS then
      return -1;
end uom_to_uom;


-- Public


FUNCTION item_code
(in_custid IN varchar2
,in_itemalias IN varchar2
) return varchar2 is

out custitem%rowtype;
item_count number;
l_alias custitemalias.itemalias%type;
l_minlength pls_integer;

function partial_match
   (p_custid in varchar2,
    p_alias in varchar2)
return varchar2 is
   l_item custitemalias.item%type := '';
begin
   select item
      into l_item
      from custitemalias
      where custid = p_custid
        and rtrim(translate(itemalias,'%',' ')) = p_alias
        and nvl(partial_match_yn,'N') = 'Y';
   return l_item;
exception when others then
  return 'Unknown';
end partial_match;

begin

  out.item := '';

  if length(in_itemalias) is null then
    return 'Unknown';
  end if;

  begin
    select item
      into out.item
      from custitem
     where custid = in_custid
       and item = in_itemalias;
  exception when no_data_found then
	begin
      select count(1)
        into item_count
        from custitemalias
       where custid = in_custid
         and itemalias = in_itemalias;
      if (item_count > 1) then
          return 'Multiple';
      end if;
      
      select item
        into out.item
        from custitemalias
       where custid = in_custid
         and itemalias = in_itemalias
         and nvl(partial_match_yn,'N') = 'N';
    exception when no_data_found then
      l_alias := in_itemalias;
      select min(length(rtrim(translate(itemalias,'%',' '))))
         into l_minlength
         from custitemalias
         where custid = in_custid
           and nvl(partial_match_yn,'N') = 'Y';
      if l_minlength is null then
         out.item := 'Unknown';
      else
         loop
            out.item := partial_match(in_custid, l_alias);
            exit when out.item != 'Unknown';
            l_alias := substr(l_alias, 1, length(l_alias)-1);
            exit when nvl(length(l_alias),0) < l_minlength;
         end loop;
      end if;
    end;
  end;

  return out.item;

exception when others then
  return 'Unknown';
end item_code;

PROCEDURE get_customer_item
(in_custid IN varchar2
,in_itemalias IN varchar2
,out_item IN OUT varchar2
,out_lotrequired IN OUT varchar2
,out_hazardous IN OUT varchar2
,out_iskit IN OUT varchar2
,out_msg  IN OUT varchar2
) is

begin   out_item := '';
  out_lotrequired := 'N';
  out_hazardous := 'N';
  out_iskit := 'N';
  out_msg := '';

  select item_code(in_custid,in_itemalias)
    into out_item
    from dual;

  if out_item = 'Unknown' then
    out_msg := 'Unknown item/alias for Customer ' || in_custid;
  elsif out_item = 'Multiple' then
    out_msg := 'Multiple items for Customer ' || in_custid;
  else
    select lotrequired,
           hazardous,
           iskit
      into out_lotrequired, out_hazardous, out_iskit
      from custitemview
     where custid = in_custid
       and item = out_item;
    out_msg := 'OKAY';
  end if;

exception when others then
  out_msg := substr(sqlerrm,1,80);
end get_customer_item;

FUNCTION custitem_status_abbrev
(in_status IN varchar2
) return varchar2 is

out itemlipstatus%rowtype;
begin
 out.abbrev := '';
 select abbrev
  into out.abbrev
  from itemlipstatus
 where code = in_status;

return out.abbrev;

exception when others then
  return 'Unknown';
end custitem_status_abbrev;

FUNCTION custitem_sign
(in_status IN varchar2
) return number is

begin
if in_status in ('CM','R') then
  return -1;
else
  return 1;
end if;

exception when others then
  return 1;
end custitem_sign;

FUNCTION custitem_projected
(in_status IN varchar2
) return number is

begin
if in_status not in ('I','PN','P','D','U') then
  return 1;
else
  return 0;
end if;

exception when others then
  return 1;
end custitem_projected;

FUNCTION hazardous_item
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

c custitem%rowtype;

begin

select nvl(hazardous,'N')
  into c.hazardous
  from custitem
 where custid = in_custid
   and item = in_item;

return c.hazardous;

exception when others then
  return 'N';
end hazardous_item;

FUNCTION hazardous_item_on_order
(in_orderid IN number
,in_shipid IN NUMBER
) return varchar2 is

hazcount integer;
begin
hazcount := 0;
select count(1)
  into hazcount
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and linestatus = 'A'
   and hazardous_item(custid, item) = 'Y';

if hazcount = 0 then
  return 'N';
else
  return 'Y';
end if;

exception when others then
  return 'N';
end hazardous_item_on_order;

PROCEDURE reset_sub_sequence
(in_custid varchar2
,in_item varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curItemSubs is
  select custid, item, seq
    from custitemsubs
   where custid = in_custid
     and item = in_item
   order by seq desc;

newseq number(7);
begin
out_msg := '';
update custitemsubs
   set seq = seq * -1
 where custid = in_custid
   and item = in_item;

if sql%rowcount = 0 then
  out_msg := 'Item Sub not found: ' ||
             in_custid || ' ' || in_item;
  return;
end if;

newseq := 10; for p in curItemSubs
loop
  update custitemsubs
     set seq = newseq,
         lastuser = in_userid,
         lastupdate = sysdate
   where custid = p.custid
     and item = p.item
     and seq = p.seq;

  newseq := newseq + 10; end loop; out_msg := 'OKAY'; exception when others then
  out_msg := substr(sqlerrm,1,80);
end reset_sub_sequence;

FUNCTION product_group
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

c custitem%rowtype;
begin
select nvl(productgroup,'?')
  into c.productgroup
  from custitem
 where custid = in_custid
   and item = in_item;

return c.productgroup;

exception when others then
  return '?';
end product_group;

FUNCTION baseuom
(in_custid IN varchar2
,in_item IN varchar2
) return varchar2 is

c custitem%rowtype;
begin
select nvl(baseuom,'?')
  into c.baseuom
  from custitem
 where custid = in_custid
   and item = in_item;

return c.baseuom;

exception when others then
  return '?';
end baseuom;

FUNCTION item_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number is

cursor curCustItemUom is
  select nvl(weight,0) as weight
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(weight,0) as weight
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_weight number;
l_catch_weights custitem.use_catch_weights%type;
l_catch_weight_item_weight_yn customer_aux.catch_weight_item_weight_yn%type;
l_factor number;

begin

out_weight := 0;

begin
   select use_catch_weights, catch_weight_item_weight_yn
      into l_catch_weights, l_catch_weight_item_weight_yn
      from custitemview
      where custid = in_custid
        and item = in_item;
exception
   when NO_DATA_FOUND then
      l_catch_weights := 'N';
end;

if l_catch_weights = 'Y' and
   nvl(l_catch_weight_item_weight_yn,'N') = 'N' then
   out_weight := zcwt.item_avg_weight(in_custid, in_item, in_uom);
   if out_weight > 0 then
      return out_weight;
   end if;
end if;

iu.weight := 0;
open curCustItemUom;
fetch curCustItemUom into iu;
close curCustItemUom;
if (iu.weight = 0) then
  open curCustItem;
  fetch curCustItem into ci;
  if curCustItem%notfound then
    close curCustItem;
    return 1;
  end if;
  close curCustItem;
  if in_uom = ci.baseuom then
    out_weight := ci.weight;
  else
    l_factor := uom_to_uom(in_custid, in_item, 1, ci.baseuom, in_uom, '', 1);
    if l_factor in (0, -1) then
      return 1;
    end if;
    out_weight := ci.weight * l_factor;
  end if;
else
  out_weight := iu.weight;
end if;
if out_weight > 999999999.99999999 then
  out_weight := 1;
end if;
return out_weight;

exception when others then
  return 1;
end item_weight;

FUNCTION item_weight_use_entered_weight
(in_custid IN varchar2
,in_item IN varchar2
,in_orderid in number
,in_shipid in number
,in_uom IN varchar2
) return number is

cursor curCustItemUom is
  select nvl(weight,0) as weight
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(weight,0) as weight
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curOrderDtl is
   select nvl(weight_entered_lbs, 0) as weight_entered_lbs, nvl(weight_entered_kgs, 0) as weight_entered_kgs,
          qtyentered, uomentered
     from orderdtl
    where orderid = in_orderid
      and shipid = in_shipid
      and item = in_item;
od curOrderDtl%rowtype;

out_weight number;
l_catch_weights custitem.use_catch_weights%type;
l_catch_weight_item_weight_yn customer_aux.catch_weight_item_weight_yn%type;
l_use_entered_weight_yn customer_aux.use_entered_weight_yn%type;
l_factor number;
l_weight shippingplate.weight%type;
l_uom_entered_weight shippingplate.weight%type;
l_baseuom custitem.baseuom%type;


begin

out_weight := 0;

begin
   select use_catch_weights, catch_weight_item_weight_yn, use_entered_weight_yn, baseuom
      into l_catch_weights, l_catch_weight_item_weight_yn, l_use_entered_weight_yn, l_baseuom
      from custitemview
      where custid = in_custid
        and item = in_item;
exception
   when NO_DATA_FOUND then
      l_catch_weights := 'N';
end;

if l_catch_weights = 'Y' and
   l_use_entered_weight_yn = 'Y' then
   od := null;
   open curOrderDtl;
   fetch curOrderdtl into od;
   close curOrderdtl;
   if od.uomentered is not null and
      (od.weight_entered_lbs <> 0 or
       od.weight_entered_kgs <> 0) then
      if od.weight_entered_lbs <> 0 then
         l_weight := od.weight_entered_lbs;
      else
         l_weight := od.weight_entered_kgs;
      end if;
      l_uom_entered_weight := l_weight / od.qtyentered; -- weight of one of uom entered
      if in_uom = l_baseuom then
         out_weight := l_uom_entered_weight;
         return out_weight;
      else
         l_factor := uom_to_uom(in_custid, in_item, 1, od.uomentered, in_uom, '', 1);
         if l_factor not in (0, -1) then
            out_weight := l_uom_entered_weight * l_factor;
            return out_weight;
         end if;
      end if;
   end if;
end if;

if l_catch_weights = 'Y' and
   nvl(l_catch_weight_item_weight_yn,'N') = 'N' then
   out_weight := zcwt.item_avg_weight(in_custid, in_item, in_uom);
   if out_weight > 0 then
      return out_weight;
   end if;
end if;

iu.weight := 0;
open curCustItemUom;
fetch curCustItemUom into iu;
close curCustItemUom;
if (iu.weight = 0) then
  open curCustItem;
  fetch curCustItem into ci;
  if curCustItem%notfound then
    close curCustItem;
    return 1;
  end if;
  close curCustItem;
  if in_uom = ci.baseuom then
    out_weight := ci.weight;
  else
    l_factor := uom_to_uom(in_custid, in_item, 1, ci.baseuom, in_uom, '', 1);
    if l_factor in (0, -1) then
      return 1;
    end if;
    out_weight := ci.weight * l_factor;
  end if;
else
  out_weight := iu.weight;
end if;
if out_weight > 999999999.99999999 then
  out_weight := 1;
end if;
return out_weight;

exception when others then
  return 1;
end item_weight_use_entered_weight;

FUNCTION item_cube
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number is

cursor curCustItemUom is
  select nvl(cube,0) as cube
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(cube,0) as cube
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_cube number;
l_factor number;

begin

out_cube := 0;

iu.cube := 0;
open curCustItemUom;
fetch curCustItemUom into iu;
close curCustItemUom;
if (iu.cube = 0) then
  open curCustItem;
  fetch curCustItem into ci;
  if curCustItem%notfound then
    close curCustItem;
    return 1;
  end if;
  close curCustItem;
  if in_uom = ci.baseuom then
    out_cube := ci.cube;
  else
    l_factor := uom_to_uom(in_custid, in_item, 1, ci.baseuom, in_uom, '', 1);
    if l_factor in (0, -1) then
      return 1;
    end if;
    out_cube :=  ci.cube * l_factor;
  end if;
else
  out_cube := iu.cube;
end if;

out_cube := out_cube / 1728.0;

if out_cube > 999999.9999 then
  out_cube := 1;
end if;

return out_cube;

exception when others then
  return 1;
end item_cube;

FUNCTION picktotype
(in_custid IN varchar2
,in_item IN varchar2
,in_pickuom IN varchar2
) return varchar2 is

cursor curCustItem is
  select picktotype
    from custitem
   where custid = in_custid
     and item = in_item
     and baseuom = in_pickuom;

cursor curCustItemUom is
  select nvl(picktotype,'PAL')
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_pickuom
   order by sequence;
out_picktotype custitemuom.picktotype%type;

begin

out_picktotype := '';
open curCustItem;
fetch curCustItem into out_picktotype;
close curCustItem;

if out_picktotype is null then
  open curCustItemUom;
  fetch curCustItemUom into out_picktotype;
  close curCustItemUom;
end if;

return out_picktotype;

exception when others then
  return 'FULL';
end picktotype;

FUNCTION cartontype
(in_custid IN varchar2
,in_item IN varchar2
,in_pickuom IN varchar2
) return varchar2 is

cursor curCustItem is
  select cartontype
    from custitem
   where custid = in_custid
     and item = in_item
     and baseuom = in_pickuom;

out_cartontype custitemuom.cartontype%type;

begin

out_cartontype := '';
open curCustItem;
fetch curCustItem into out_cartontype;
close curCustItem;

if out_cartontype is null then
  select nvl(cartontype,'NONE')
    into out_cartontype
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_pickuom;
end if;

return out_cartontype;

exception when others then
  return 'NONE';
end cartontype;

FUNCTION item_amt
(in_custid IN varchar2
,in_orderid in number
,in_shipid in number
,in_item IN varchar2
,in_lot in varchar2)
return number is

amt custitem.useramt1%type;
  v_custid customer.custid%type;
  v_pct_sale_billing customer.pct_sale_billing%type;
  v_orderdtl_dollar_amt_pt customer.orderdtl_dollar_amt_pt%type;
  v_ordertype orderhdr.ordertype%type;
begin

  v_custid := in_custid;
  if (in_orderid is not null and in_shipid is not null)
  then
    select custid, ordertype
    into v_custid, v_ordertype
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  end if;
  
  if (v_custid is null or in_item is null)
  then
    return 0;
  end if;

  if (in_orderid is not null and in_shipid is not null and nvl(v_ordertype,'X') = 'O')
  then 
    select upper(nvl(pct_sale_billing,'N')), orderdtl_dollar_amt_pt
    into v_pct_sale_billing, v_orderdtl_dollar_amt_pt
    from customer
    where custid = v_custid;

    if (v_pct_sale_billing = 'Y')
    then
begin
        execute immediate 'select ' || v_orderdtl_dollar_amt_pt || '
                           from orderdtl
                           where orderid = :in_orderid and shipid = :in_shipid and item = :in_item and nvl(lotnumber,''(none)'') = nvl(:in_lot,''(none)'')' 
        into amt using in_orderid, in_shipid, in_item, in_lot;
      exception
        when others then
          amt := null;
      end;
      
      if amt is not null
      then
        return amt;
      end if;
    end if;
  end if;

select nvl(useramt1,0)
  into amt
  from custitem
   where custid = v_custid
   and item = in_item;

return amt;

exception when others then
  return 0;
end item_amt;

FUNCTION item_stackheight
(in_custid IN varchar2
,in_item IN varchar2
) return number is

l_stackheight custitem.stackheight%type;

begin

select nvl(stackheight,0)
  into l_stackheight
  from custitem
 where custid = in_custid
   and item = in_item;

return l_stackheight;

exception when others then
  return 0;
end item_stackheight;

FUNCTION item_base_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
,in_qty in number
) return number is

cursor curCustItem is
  select baseuom
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

cursor curFromUomSeq(in_fromuom varchar2) is
  select sequence
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom = in_fromuom;
fs curFromUomSeq%rowtype;

cursor curToUomSeq(in_touom varchar2) is
  select sequence
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_touom;
ts curToUomSeq%rowtype;

cursor curUomEquivUp(in_fromseq number,in_toseq number) is
  select qty
    from custitemuom
   where custid = in_custid
     and item = in_item
     and sequence >= in_fromseq
     and sequence <= in_toseq
   order by sequence;

out_baseqty custitem.cube%type;
qtyEquiv custitemuom.qty%type;

begin

out_baseqty := nvl(in_qty,0);

open curCustItem;
fetch curCustItem into ci;
if curCustItem%notfound then
  close curCustItem;
  return out_baseqty;
end if;
close curCustItem;
if in_uom != ci.baseuom then
  open curFromUomSeq(ci.baseuom);
  fetch curFromUomSeq into fs;
  if curFromUomSeq%notfound then
    close curFromUomSeq;
    return out_baseqty;
  end if;
  close curFromUomSeq;
  open curToUomSeq(in_uom);
  fetch curToUomSeq into ts;
  if curToUomSeq%notfound then
    close curToUomSeq;
    return out_baseqty;
  end if;
  close curToUomSeq;
  qtyEquiv := nvl(in_qty,0);
  for ue in curUomEquivUp(fs.sequence,ts.sequence)
  loop
    qtyEquiv := qtyEquiv * ue.qty;
  end loop;
  out_baseqty := qtyEquiv;
end if;

return out_baseqty;

exception when others then
  return out_baseqty;
end item_base_qty;

function default_value
(in_defaultid varchar2
) return varchar2

is

strDefaultValue systemdefaults.defaultvalue%type;

begin

select defaultvalue
  into strDefaultValue
  from systemdefaults
 where defaultid = in_defaultid;

return strDefaultValue;

exception when others then
  return null;
end default_value;

FUNCTION item_uom_length
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number
is

cursor curCustItemUom is
  select nvl(length,0) as length
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(length,0) as length
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_length custitem.length%type;

begin

out_length := 0;

ci := null;
open curCustItem;
fetch curCustItem into ci;
close curCustItem;
if in_uom = ci.baseuom then
  out_length := ci.length;
else
  iu := null;
  open curCustItemUom;
  fetch curCustItemUom into iu;
  close curCustItemUom;
  out_length := iu.length;
end if;

return out_length;

exception when others then
  return 0;
end item_uom_length;

FUNCTION item_uom_height
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number
is

cursor curCustItemUom is
  select nvl(height,0) as height
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(height,0) as height
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_height custitem.height%type;

begin

out_height := 0;

ci := null;
open curCustItem;
fetch curCustItem into ci;
close curCustItem;
if in_uom = ci.baseuom then
  out_height := ci.height;
else
  iu := null;
  open curCustItemUom;
  fetch curCustItemUom into iu;
  close curCustItemUom;
  out_height := iu.height;
end if;

return out_height;

exception when others then
  return 0;
end item_uom_height;

FUNCTION item_uom_width
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number
is

cursor curCustItemUom is
  select nvl(width,0) as width
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(width,0) as width
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_width custitem.width%type;

begin

out_width := 0;

ci := null;
open curCustItem;
fetch curCustItem into ci;
close curCustItem;
if in_uom = ci.baseuom then
  out_width := ci.width;
else
  iu := null;
  open curCustItemUom;
  fetch curCustItemUom into iu;
  close curCustItemUom;
  out_width := iu.width;
end if;

return out_width;

exception when others then
  return 0;
end item_uom_width;

PROCEDURE item_qty_descr
(in_custid IN varchar2
,in_item IN varchar2
,in_baseuom IN varchar2
,in_baseuom_qty IN number
,out_qty_descr IN OUT varchar2
)
is

cursor curCustItemUom is
  select touom
    from custitemuom
   where custid = in_custid
     and item = in_item
     and fromuom != 'CUIN'
   order by sequence desc;

out_descr varchar2(2000);
qtyremain integer;
out_pickqty number;
uom_qty number;
out_msg varchar2(255);

begin

out_qty_descr := null;
qtyremain := in_baseuom_qty;

for ciu in curCustItemUom
loop
  zbut.translate_uom(in_custid,in_item,qtyremain,
    in_baseuom,ciu.touom,out_pickqty,out_msg);
  if out_msg = 'OKAY' then
    uom_qty := floor(out_pickqty);
    if uom_qty <> 0 then
      if out_qty_descr is null then
        out_qty_descr := '(';
      else
        out_qty_descr := out_qty_descr || ', ';
      end if;
      out_qty_descr := out_qty_descr || trim(to_char(uom_qty)) ||
        ' ' || zit.uom_abbrev(ciu.touom);
      zbut.translate_uom(in_custid,in_item,uom_qty,
        ciu.touom,in_baseuom,out_pickqty,out_msg);
      qtyRemain := qtyRemain - out_pickqty;
    end if;
  end if;
end loop;

if qtyremain <> 0 then
  if out_qty_descr is null then
    out_qty_descr := '(';
  else
    out_qty_descr := out_qty_descr || ', ';
  end if;
  out_qty_descr := out_qty_descr || trim(to_char(qtyremain)) ||
    ' ' || zit.uom_abbrev(in_baseuom);
end if;
out_qty_descr := out_qty_descr || ')';

exception when others then
  out_qty_descr := null;
end item_qty_descr;

FUNCTION item_touom_qty
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number is

cursor curCustItemUom is
  select nvl(qty,0) as qty
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

out_qty custitemuom.qty%type;

begin

out_qty := 0;

open curCustItemUom;
fetch curCustItemUom into out_qty;
close curCustItemUom;
return out_qty;

exception when others then
  return 1;
end item_touom_qty;

FUNCTION item_tareweight
(in_custid IN varchar2
,in_item IN varchar2
,in_uom IN varchar2
) return number is

cursor curCustItemUom is
  select nvl(tareweight,0) as tareweight
    from custitemuom
   where custid = in_custid
     and item = in_item
     and touom = in_uom;
iu curCustItemUom%rowtype;

cursor curCustItem is
  select baseuom,
         nvl(tareweight,0) as tareweight
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

out_tareweight number := 0;
l_factor number;

begin

iu.tareweight := 0;
open curCustItemUom;
fetch curCustItemUom into iu;
close curCustItemUom;
if (iu.tareweight = 0) then
  open curCustItem;
  fetch curCustItem into ci;
  if curCustItem%notfound then
    close curCustItem;
    return 0;
  end if;
  close curCustItem;
  if in_uom = ci.baseuom then
    out_tareweight := ci.tareweight;
  else
    l_factor := uom_to_uom(in_custid, in_item, 1, ci.baseuom, in_uom, '', 1);
    if l_factor in (0, -1) then
      return 1;
    end if;
    out_tareweight :=  ci.tareweight * l_factor;
  end if;
else
  out_tareweight := iu.tareweight;
end if;

if out_tareweight > 999999999.99999999 then
  out_tareweight := 0;
end if;

return out_tareweight;

exception when others then
  return 0;
end item_tareweight;

FUNCTION variancepct
(in_custid IN varchar2
,in_item IN varchar2
) return number is

out_variancepct custitem.variancepct%type;

begin

select variancepct
  into out_variancepct
  from custitemview
 where custid = in_custid
   and item = in_item;

return out_variancepct;

exception when others then
  return 0;
end variancepct;

FUNCTION variancepct_overage
(in_custid IN varchar2
,in_item IN varchar2
) return number is

out_variancepct_overage custitem.variancepct_overage%type;

begin

select variancepct_overage
  into out_variancepct_overage
  from custitemview
 where custid = in_custid
   and item = in_item;

return out_variancepct_overage;

exception when others then
  return 0;
end variancepct_overage;

FUNCTION item_qty_backorder
(in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
) return number is

out_qty_backorder orderdtl.qtyorder%type;

begin

SELECT NVL(SUM(zbillutility.translate_uom_function(in_custid, in_item, NVL(od.qtyorder, 0) - NVL(od.qtyship, 0), od.uom, ci.baseuom)), 0)
  into out_qty_backorder 
  FROM custitem ci, orderhdr oh, orderdtl od
 WHERE ci.custid = in_custid
       AND ci.item = in_item
       AND oh.recent_order_id LIKE 'Y%'
       AND oh.custid = ci.item
       AND oh.fromfacility = in_facility
       AND oh.orderstatus NOT IN ('X', '9')
       AND NVL (oh.backorderyn, 'N') = 'Y'
       AND od.orderid = oh.orderid
       AND od.shipid = oh.shipid
       AND od.custid = oh.custid
       AND od.item = ci.item;

return out_qty_backorder;

exception when others then
  return 0;
end item_qty_backorder;

PROCEDURE configure_seq_object
(in_custid IN varchar2
,in_type IN varchar2 -- 'LOT','SER','US1','US2','US3'
,out_seq_name IN OUT varchar2
,out_min_seq IN OUT number
,out_max_seq IN OUT number
)

is

cursor curSequence(in_sequence varchar2) is
  select sequence_name,min_value,max_value,last_number
    from user_sequences
   where sequence_name = upper(rtrim(in_sequence));
l_seq curSequence%rowtype;
l_str appmsgs.msgtext%type;
l_cmd varchar2(4000);
l_cnt pls_integer;
l_start_with pls_integer;

begin

l_seq := null;
if out_min_seq <= 0 then
  out_min_seq := 1;
end if;

if out_max_seq > 99999999999999999999 then
  out_max_seq := 99999999999999999999;
end if;

l_start_with := out_min_seq;

if rtrim(out_seq_name) is null then
  goto create_seq;
end if;

open curSequence(out_seq_name);
fetch curSequence into l_seq;
close curSequence;
if l_seq.sequence_name is null then
  goto create_seq;
end if;

if l_seq.min_value = out_min_seq and
   l_seq.max_value = out_max_seq then
  return;
end if;

if l_seq.last_number < out_min_seq then
  l_start_with := out_min_seq;
else
  l_start_with := l_seq.last_number;
end if;

l_cmd := 'drop sequence ' || l_seq.sequence_name;
execute immediate l_cmd;

<<create_seq>>

l_cnt := 1;
while (1=1)
loop
  l_seq := null;
  l_str := 'AUTO' || '_' || in_type || '_' || l_cnt;
  open curSequence(l_str);
  fetch curSequence into l_seq;
  close curSequence;
  if l_seq.sequence_name is null then
    exit;
  end if;
  l_cnt := l_cnt + 1;
end loop;

l_cmd := 'create sequence ' || l_str ||
         ' increment by 1 start with ' || l_start_with ||
         ' minvalue ' || out_min_seq  ||
         ' maxvalue ' || out_max_seq  ||
         ' nocache cycle';
execute immediate l_cmd;

out_seq_name := l_str;

exception when others then
  zms.log_autonomous_msg('AUTOSEQ', null, in_custid, sqlerrm || chr(13) || l_cmd, 'E', 'AUTOSEQ', l_str);
end configure_seq_object;

PROCEDURE validate_auto_seq
(in_custid IN varchar2
,in_productgroup IN varchar2
,in_item IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor curCustomer is
  select lotrequired, lot_seq_name, lot_seq_min, lot_seq_max,
         serialrequired, serial_seq_name, serial_seq_min, serial_seq_max,
         user1required, useritem1_seq_name, useritem1_seq_min, useritem1_seq_max,
         user2required, useritem2_seq_name, useritem2_seq_min, useritem2_seq_max,
         user3required, useritem3_seq_name, useritem3_seq_min, useritem3_seq_max
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and cu.custid = ca.custid(+);

cursor curCustProductGroup is
  select lotrequired, lot_seq_name, lot_seq_min, lot_seq_max,
         serialrequired, serial_seq_name, serial_seq_min, serial_seq_max,
         user1required, useritem1_seq_name, useritem1_seq_min, useritem1_seq_max,
         user2required, useritem2_seq_name, useritem2_seq_min, useritem2_seq_max,
         user3required, useritem3_seq_name, useritem3_seq_min, useritem3_seq_max
    from custitem
   where custid = in_custid
     and item = in_item;

cursor curCustItem is
  select lotrequired, lot_seq_name, lot_seq_min, lot_seq_max,
         serialrequired, serial_seq_name, serial_seq_min, serial_seq_max,
         user1required, useritem1_seq_name, useritem1_seq_min, useritem1_seq_max,
         user2required, useritem2_seq_name, useritem2_seq_min, useritem2_seq_max,
         user3required, useritem3_seq_name, useritem3_seq_min, useritem3_seq_max
    from custitem
   where custid = in_custid
     and item = in_item;

l curCustItem%rowtype;
l_sequence_name user_sequences.sequence_name%type;
l_cmd varchar2(4000);

begin

out_msg := 'OKAY';

l := null;

if rtrim(in_item) is not null then
  open curCustItem;
  fetch curCustItem into l;
  close curCustItem;
elsif rtrim(in_productgroup) is not null then
  open curCustProductGroup;
  fetch curCustProductGroup into l;
  close curCustProductGroup;
else
  open curCustomer;
  fetch curCustomer into l;
  close curCustomer;
end if;

if l.lotrequired = 'A' then
  configure_seq_object(in_custid,'LOT',l.lot_seq_name,l.lot_seq_min,l.lot_seq_max);
  if rtrim(in_item) is not null then
    update custitem
       set lot_seq_name = l.lot_seq_name,
           lot_seq_min = l.lot_seq_min,
           lot_seq_max = l.lot_seq_max
     where custid = in_custid
       and item = in_item
       and (nvl(lot_seq_name,'x') != nvl(l.lot_seq_name,'x') or
            nvl(lot_seq_min,0) != nvl(l.lot_seq_min,0) or
            nvl(lot_seq_max,0) != nvl(l.lot_seq_max,0));
  elsif rtrim(in_productgroup) is not null then
    update custproductgroup
       set lot_seq_name = l.lot_seq_name,
           lot_seq_min = l.lot_seq_min,
           lot_seq_max = l.lot_seq_max
     where custid = in_custid
       and productgroup = in_productgroup
       and (nvl(lot_seq_name,'x') != nvl(l.lot_seq_name,'x') or
            nvl(lot_seq_min,0) != nvl(l.lot_seq_min,0) or
            nvl(lot_seq_max,0) != nvl(l.lot_seq_max,0));
  else
    update customer_aux
       set lot_seq_name = l.lot_seq_name,
           lot_seq_min = l.lot_seq_min,
           lot_seq_max = l.lot_seq_max
     where custid = in_custid
       and (nvl(lot_seq_name,'x') != nvl(l.lot_seq_name,'x') or
            nvl(lot_seq_min,0) != nvl(l.lot_seq_min,0) or
            nvl(lot_seq_max,0) != nvl(l.lot_seq_max,0));
  end if;
elsif l.lot_seq_name is not null then
  l_cmd := 'drop sequence ' || l.lot_seq_name;
  execute immediate l_cmd;
  if rtrim(in_item) is not null then
     update custitem
        set lot_seq_name = null,
            lot_seq_min = null,
            lot_seq_max = null
      where custid = in_custid
        and item = in_item;
  elsif rtrim(in_productgroup) is not null then
     update custproductgroup
        set lot_seq_name = null,
            lot_seq_min = null,
            lot_seq_max = null
      where custid = in_custid
        and productgroup = in_productgroup;
  else
     update customer_aux
        set lot_seq_name = null,
            lot_seq_min = null,
            lot_seq_max = null
      where custid = in_custid;
   end if;
end if;

if l.serialrequired = 'A' then
  configure_seq_object(in_custid,'SER',l.serial_seq_name,l.serial_seq_min,l.serial_seq_max);
  if rtrim(in_item) is not null then
    update custitem
       set serial_seq_name = l.serial_seq_name,
           serial_seq_min = l.serial_seq_min,
           serial_seq_max = l.serial_seq_max
     where custid = in_custid
       and item = in_item
       and (nvl(serial_seq_name,'x') != nvl(l.serial_seq_name,'x') or
            nvl(serial_seq_min,0) != nvl(l.serial_seq_min,0) or
            nvl(serial_seq_max,0) != nvl(l.serial_seq_max,0));
  elsif rtrim(in_productgroup) is not null then
    update custproductgroup
       set serial_seq_name = l.serial_seq_name,
           serial_seq_min = l.serial_seq_min,
           serial_seq_max = l.serial_seq_max
     where custid = in_custid
       and productgroup = in_productgroup
       and (nvl(serial_seq_name,'x') != nvl(l.serial_seq_name,'x') or
            nvl(serial_seq_min,0) != nvl(l.serial_seq_min,0) or
            nvl(serial_seq_max,0) != nvl(l.serial_seq_max,0));
  else
    update customer_aux
       set serial_seq_name = l.serial_seq_name,
           serial_seq_min = l.serial_seq_min,
           serial_seq_max = l.serial_seq_max
     where custid = in_custid
       and (nvl(serial_seq_name,'x') != nvl(l.serial_seq_name,'x') or
            nvl(serial_seq_min,0) != nvl(l.serial_seq_min,0) or
            nvl(serial_seq_max,0) != nvl(l.serial_seq_max,0));
  end if;
elsif l.serial_seq_name is not null then
  l_cmd := 'drop sequence ' || l.serial_seq_name;
  execute immediate l_cmd;
  if rtrim(in_item) is not null then
     update custitem
        set serial_seq_name = null,
            serial_seq_min = null,
            serial_seq_max = null
      where custid = in_custid
        and item = in_item;
  elsif rtrim(in_productgroup) is not null then
     update custproductgroup
        set serial_seq_name = null,
            serial_seq_min = null,
            serial_seq_max = null
      where custid = in_custid
        and productgroup = in_productgroup;
  else
     update customer_aux
        set serial_seq_name = null,
            serial_seq_min = null,
            serial_seq_max = null
      where custid = in_custid;
   end if;
end if;

if l.user1required = 'A' then
  configure_seq_object(in_custid,'US1',l.useritem1_seq_name,l.useritem1_seq_min,l.useritem1_seq_max);
  if rtrim(in_item) is not null then
    update custitem
       set useritem1_seq_name = l.useritem1_seq_name,
           useritem1_seq_min = l.useritem1_seq_min,
           useritem1_seq_max = l.useritem1_seq_max
     where custid = in_custid
       and item = in_item
       and (nvl(useritem1_seq_name,'x') != nvl(l.useritem1_seq_name,'x') or
            nvl(useritem1_seq_min,0) != nvl(l.useritem1_seq_min,0) or
            nvl(useritem1_seq_max,0) != nvl(l.useritem1_seq_max,0));
  elsif rtrim(in_productgroup) is not null then
    update custproductgroup
       set useritem1_seq_name = l.useritem1_seq_name,
           useritem1_seq_min = l.useritem1_seq_min,
           useritem1_seq_max = l.useritem1_seq_max
     where custid = in_custid
       and productgroup = in_productgroup
       and (nvl(useritem1_seq_name,'x') != nvl(l.useritem1_seq_name,'x') or
            nvl(useritem1_seq_min,0) != nvl(l.useritem1_seq_min,0) or
            nvl(useritem1_seq_max,0) != nvl(l.useritem1_seq_max,0));
  else
    update customer_aux
       set useritem1_seq_name = l.useritem1_seq_name,
           useritem1_seq_min = l.useritem1_seq_min,
           useritem1_seq_max = l.useritem1_seq_max
     where custid = in_custid
       and (nvl(useritem1_seq_name,'x') != nvl(l.useritem1_seq_name,'x') or
            nvl(useritem1_seq_min,0) != nvl(l.useritem1_seq_min,0) or
            nvl(useritem1_seq_max,0) != nvl(l.useritem1_seq_max,0));
  end if;
elsif l.useritem1_seq_name is not null then
  l_cmd := 'drop sequence ' || l.useritem1_seq_name;
  execute immediate l_cmd;
  if rtrim(in_item) is not null then
     update custitem
        set useritem1_seq_name = null,
            useritem1_seq_min = null,
            useritem1_seq_max = null
      where custid = in_custid
        and item = in_item;
  elsif rtrim(in_productgroup) is not null then
     update custproductgroup
        set useritem1_seq_name = null,
            useritem1_seq_min = null,
            useritem1_seq_max = null
      where custid = in_custid
        and productgroup = in_productgroup;
  else
     update customer_aux
        set useritem1_seq_name = null,
            useritem1_seq_min = null,
            useritem1_seq_max = null
      where custid = in_custid;
   end if;
end if;

if l.user2required = 'A' then
  configure_seq_object(in_custid,'US2',l.useritem2_seq_name,l.useritem2_seq_min,l.useritem2_seq_max);
  if rtrim(in_item) is not null then
    update custitem
       set useritem2_seq_name = l.useritem2_seq_name,
           useritem2_seq_min = l.useritem2_seq_min,
           useritem2_seq_max = l.useritem2_seq_max
     where custid = in_custid
       and item = in_item
       and (nvl(useritem2_seq_name,'x') != nvl(l.useritem2_seq_name,'x') or
            nvl(useritem2_seq_min,0) != nvl(l.useritem2_seq_min,0) or
            nvl(useritem2_seq_max,0) != nvl(l.useritem2_seq_max,0));
  elsif rtrim(in_productgroup) is not null then
    update custproductgroup
       set useritem2_seq_name = l.useritem2_seq_name,
           useritem2_seq_min = l.useritem2_seq_min,
           useritem2_seq_max = l.useritem2_seq_max
     where custid = in_custid
       and productgroup = in_productgroup
       and (nvl(useritem2_seq_name,'x') != nvl(l.useritem2_seq_name,'x') or
            nvl(useritem2_seq_min,0) != nvl(l.useritem2_seq_min,0) or
            nvl(useritem2_seq_max,0) != nvl(l.useritem2_seq_max,0));
  else
    update customer_aux
       set useritem2_seq_name = l.useritem2_seq_name,
           useritem2_seq_min = l.useritem2_seq_min,
           useritem2_seq_max = l.useritem2_seq_max
     where custid = in_custid
       and (nvl(useritem2_seq_name,'x') != nvl(l.useritem2_seq_name,'x') or
            nvl(useritem2_seq_min,0) != nvl(l.useritem2_seq_min,0) or
            nvl(useritem2_seq_max,0) != nvl(l.useritem2_seq_max,0));
  end if;
elsif l.useritem2_seq_name is not null then
  l_cmd := 'drop sequence ' || l.useritem2_seq_name;
  execute immediate l_cmd;
  if rtrim(in_item) is not null then
     update custitem
        set useritem2_seq_name = null,
            useritem2_seq_min = null,
            useritem2_seq_max = null
      where custid = in_custid
        and item = in_item;
  elsif rtrim(in_productgroup) is not null then
     update custproductgroup
        set useritem2_seq_name = null,
            useritem2_seq_min = null,
            useritem2_seq_max = null
      where custid = in_custid
        and productgroup = in_productgroup;
  else
     update customer_aux
        set useritem2_seq_name = null,
            useritem2_seq_min = null,
            useritem2_seq_max = null
      where custid = in_custid;
   end if;
end if;

if l.user3required = 'A' then
  configure_seq_object(in_custid,'US3',l.useritem3_seq_name,l.useritem3_seq_min,l.useritem3_seq_max);
  if rtrim(in_item) is not null then
    update custitem
       set useritem3_seq_name = l.useritem3_seq_name,
           useritem3_seq_min = l.useritem3_seq_min,
           useritem3_seq_max = l.useritem3_seq_max
     where custid = in_custid
       and item = in_item
       and (nvl(useritem3_seq_name,'x') != nvl(l.useritem3_seq_name,'x') or
            nvl(useritem3_seq_min,0) != nvl(l.useritem3_seq_min,0) or
            nvl(useritem3_seq_max,0) != nvl(l.useritem3_seq_max,0));
  elsif rtrim(in_productgroup) is not null then
    update custproductgroup
       set useritem3_seq_name = l.useritem3_seq_name,
           useritem3_seq_min = l.useritem3_seq_min,
           useritem3_seq_max = l.useritem3_seq_max
     where custid = in_custid
       and productgroup = in_productgroup
       and (nvl(useritem3_seq_name,'x') != nvl(l.useritem3_seq_name,'x') or
            nvl(useritem3_seq_min,0) != nvl(l.useritem3_seq_min,0) or
            nvl(useritem3_seq_max,0) != nvl(l.useritem3_seq_max,0));
  else
    update customer_aux
       set useritem3_seq_name = l.useritem3_seq_name,
           useritem3_seq_min = l.useritem3_seq_min,
           useritem3_seq_max = l.useritem3_seq_max
     where custid = in_custid
       and (nvl(useritem3_seq_name,'x') != nvl(l.useritem3_seq_name,'x') or
            nvl(useritem3_seq_min,0) != nvl(l.useritem3_seq_min,0) or
            nvl(useritem3_seq_max,0) != nvl(l.useritem3_seq_max,0));
  end if;
elsif l.useritem3_seq_name is not null then
  l_cmd := 'drop sequence ' || l.useritem3_seq_name;
  execute immediate l_cmd;
  if rtrim(in_item) is not null then
     update custitem
        set useritem3_seq_name = null,
            useritem3_seq_min = null,
            useritem3_seq_max = null
      where custid = in_custid
        and item = in_item;
  elsif rtrim(in_productgroup) is not null then
     update custproductgroup
        set useritem3_seq_name = null,
            useritem3_seq_min = null,
            useritem3_seq_max = null
      where custid = in_custid
        and productgroup = in_productgroup;
  else
     update customer_aux
        set useritem3_seq_name = null,
            useritem3_seq_min = null,
            useritem3_seq_max = null
      where custid = in_custid;
   end if;
end if;

exception when others then
  out_msg := substr(sqlerrm,1,80);
end validate_auto_seq;

PROCEDURE get_auto_seq
(in_custid IN varchar2
,in_item IN varchar2
,in_type IN varchar2 -- 'LOT','SER','US1','US2','US3'
,out_seq  IN OUT varchar2
)
is

l_str appmsgs.msgtext%type;
l_cmd varchar2(255);
l_sequence_name user_sequences.sequence_name%type;
l_sequence_column user_tab_columns.column_name%type;
l_length pls_integer;
l_max_value user_sequences.max_value%type;

begin

  out_seq := '';

  if in_type = 'LOT' then
    l_sequence_column := 'LOT_SEQ_NAME';
  elsif in_type = 'SER' then
    l_sequence_column := 'SERIAL_SEQ_NAME';
  elsif in_type = 'US1' then
    l_sequence_column := 'USERITEM1_SEQ_NAME';
  elsif in_type = 'US2' then
    l_sequence_column := 'USERITEM2_SEQ_NAME';
  elsif in_type = 'US3' then
    l_sequence_column := 'USERITEM3_SEQ_NAME';
  else
    zms.log_autonomous_msg('AUTOSEQ', null, in_custid, 'Invalid auto-sequence type: ' ||
        in_type, 'E', 'AUTOSEQ', l_str);
    return;
  end if;

  l_sequence_name := null;
  l_cmd := 'select ' || l_sequence_column || ' from custitemview where custid = ''' ||
           in_custid || ''' and item = ''' || in_item || '''';
  execute immediate l_cmd into l_sequence_name;
  if l_sequence_name is null then
    zms.log_autonomous_msg('AUTOSEQ', null, in_custid, 'No auto-sequence configured for item ' ||
        in_item, 'E', 'AUTOSEQ', l_str);
    return;
  end if;

  select max_value
    into l_max_value
    from user_sequences
   where sequence_name = l_sequence_name;

  l_str := l_max_value;
  l_length := length(rtrim(l_str));

  l_cmd :=  'select lpad(' || l_sequence_name || '.nextval,' || l_length ||
             ', ''0'') from dual';
  execute immediate l_cmd into out_seq;

exception when others then
  zms.log_autonomous_msg('AUTOSEQ', null, in_custid, 'Item ' || in_item || ': ' ||sqlerrm,
                         'E', 'AUTOSEQ', l_str);
end get_auto_seq;

FUNCTION total_cases
(in_orderid IN number
,in_shipid IN number
) return varchar2 is

total_cartons number;
tmp_qty number;
tmp_item custitemalias.item%type;
l_cases_uom orderdtl.uom%type;
out_msg varchar2(255);
out_translate_qty number;
  
begin
  
total_cartons := 0;  
  
begin
  select upper(substr(zci.default_value('CARTONSUOM'),1,4))
    into l_cases_uom
    from dual;
exception when others then
  l_cases_uom := 'CS';
end;

for od in (select custid, item,
                  uom, qtyorder,
                  uomentered, qtyentered
             from orderdtl
             where orderid = in_orderid
               and shipid = in_shipid
               and linestatus != 'X') 
loop

  if l_cases_uom = od.uomentered then
    total_cartons := total_cartons + nvl(od.qtyentered,0);
  elsif l_cases_uom = od.uom then
    total_cartons := total_cartons + nvl(od.qtyorder,0);
  else
    zbut.translate_uom(od.custid,od.item,od.qtyorder,od.uom,l_cases_uom,out_translate_qty,out_msg);
    if substr(out_msg,1,4) = 'OKAY' then
      total_cartons := total_cartons + nvl(out_translate_qty,0);
    else
      begin
        select qty
          into tmp_qty
          from custitemuom
        where custid = od.custid and item = od.item and sequence = 10;
      exception when no_data_found then
        tmp_qty := -1;
      end;
      if tmp_qty < 0 then
        return 'ERROR:' + tmp_item;
      else
        total_cartons := total_cartons + nvl(od.qtyorder,0) * tmp_qty;
      end if;    
    end if;
  end if;  
end loop;

return total_cartons;  

exception when others then
  return 'ERROR';
end total_cases;

PROCEDURE validate_cas_threshold
(in_casnumber IN varchar2
,out_msg  IN OUT varchar2
)
is

l_count pls_integer;

begin

  out_msg := 'NOT FOUND';

  select count(1)
    into l_count
    from casthreshold
   where in_casnumber like casnumber || '%';

  if (l_count >= 1) then
    out_msg := 'FOUND';
  end if;

exception when others then
  out_msg := 'ERROR';
end validate_cas_threshold;

FUNCTION is_valid_cas_threshold
(in_casnumber IN varchar2
) return varchar2
is

l_msg varchar2(12);

begin

  l_msg := '';

  validate_cas_threshold(in_casnumber,l_msg);
  
  if(l_msg = 'FOUND') then
    return 'Y';
  end if;
  
  return 'N';

exception when others then
  return 'N';
end is_valid_cas_threshold;

end zcustitem;
/
show error package body zcustitem;
exit;
