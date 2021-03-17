create or replace PACKAGE BODY alps.zweight
IS
--
-- $Id$
--
custom_kg char(1);

FUNCTION system_lbs_to_kgs_factor

return number

is

cursor curSystemDefault is
  select qty
    from conversions
   where fromuom = 'LBS'
     and touom = 'KG';
sd curSystemDefault%rowtype;

out_factor customer.lbs_to_kgs_conversion_factor%type;

begin

sd := null;
open curSystemDefault;
fetch curSystemDefault into sd;
close curSystemDefault;
if nvl(sd.qty,0) = 0 then
  out_factor := DEFAULT_LBS_TO_KGS_FACTOR;
else
  out_factor := sd.qty;
end if;

return out_factor;

exception when others then
  return DEFAULT_LBS_TO_KGS_FACTOR;
end system_lbs_to_kgs_factor;

FUNCTION from_lbs_to_kgs
(in_custid varchar2
,in_lbs  number
) return number
is

cursor curCustomerFactor(in_custid varchar2) is
  select lbs_to_kgs_conversion_factor,
         lbs_to_kgs_round_up_down_none
    from customerview
   where custid = in_custid;
cf curCustomerFactor%rowtype;

out_kgs number(17,8);
num_kgs number(18,9);
l_decimal_str varchar2(20);
l_99_pos pls_integer;
l_00_pos pls_integer;

begin

out_kgs := 0;

if custom_kg != 'Y' then
   num_kgs := in_lbs/DEFAULT_LBS_TO_KGS_FACTOR;
else
   cf := null;
   open curCustomerFactor(in_custid);
   fetch curCustomerFactor into cf;
   close curCustomerFactor;
   if in_lbs is null then
     return null;
   end if;
   num_kgs := nvl(in_lbs,0) / cf.lbs_to_kgs_conversion_factor;
end if;

if cf.lbs_to_kgs_round_up_down_none = 'Y' then
  out_kgs := round(num_kgs, 8);
else
  out_kgs := trunc(num_kgs,8);
end if;

l_decimal_str := to_char(mod(out_kgs,1),'.99999999');
l_99_pos := instr(l_decimal_str,'99');

begin
  if cf.lbs_to_kgs_round_up_down_none = 'N' then
    if l_99_pos != 0 then
      out_kgs := trunc(out_kgs + ( 1 / power(10, l_99_pos - 1)),l_99_pos - 1);
    else
      l_00_pos := instr(l_decimal_str,'00');
      if l_00_pos != 0 then
        out_kgs := trunc(out_kgs,l_00_pos - 2);
      end if;
    end if;
  end if;
exception when others then
  null;
end;

return out_kgs;

exception when others then
  return -1;
end from_lbs_to_kgs;

FUNCTION from_kgs_to_lbs
(in_custid varchar2
,in_kgs  number
) return number
is

cursor curCustomerFactor(in_custid varchar2) is
  select nvl(lbs_to_kgs_conversion_factor,0) as lbs_to_kgs_conversion_factor,
         nvl(lbs_to_kgs_round_up_down_none,'N') as lbs_to_kgs_round_up_down_none
    from customerview
   where custid = in_custid;
cf curCustomerFactor%rowtype;

out_lbs number(17,8);
num_lbs number(18,9);
l_decimal_str varchar2(20);
l_99_pos pls_integer;
l_00_pos pls_integer;

begin

out_lbs := 0;

cf := null;
open curCustomerFactor(in_custid);
fetch curCustomerFactor into cf;
close curCustomerFactor;

if in_kgs is null then
  return null;
end if;

num_lbs := nvl(in_kgs,0) * cf.lbs_to_kgs_conversion_factor;

if cf.lbs_to_kgs_round_up_down_none = 'Y' then
  out_lbs := round(num_lbs, 8);
else
  out_lbs := trunc(num_lbs,8);
end if;

l_decimal_str := to_char(mod(out_lbs,1),'.99999999');
l_99_pos := instr(l_decimal_str,'99');
begin
  if cf.lbs_to_kgs_round_up_down_none = 'N' then
    if l_99_pos != 0 then
      out_lbs := trunc(out_lbs + ( 1 / power(10, l_99_pos - 1)),l_99_pos - 1);
    else
      l_00_pos := instr(l_decimal_str,'00');
      if l_00_pos != 0 then
        out_lbs := trunc(out_lbs,l_00_pos - 2);
      end if;
    end if;
  end if;	
exception when others then 
  null;
end;

return out_lbs;

exception when others then
  return -1;
end from_kgs_to_lbs;

FUNCTION is_ordered_by_weight
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return char
is

cursor curOrderdtl is
  select qtyorder,
         weight_entered_lbs,
         weight_entered_kgs
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x');
od curOrderdtl%rowtype;

begin

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderdtl;
if (nvl(od.weight_entered_lbs,0) != 0) or
   (nvl(od.weight_entered_kgs,0) != 0) then
  return 'Y';
else
  return 'N';
end if;

exception when others then
  return 'N';
end is_ordered_by_weight;

FUNCTION weight_to_display
(in_custid varchar2
,in_lbs  number
) return number
is
   cursor c_cus(p_custid varchar2) is
      select default_weight_uom
         from customer
         where custid = p_custid;
   cus c_cus%rowtype := null;
   l_weight number := in_lbs;
begin
   open c_cus(in_custid);
   fetch c_cus into cus;
   close c_cus;

   if nvl(cus.default_weight_uom,'LB') = 'KG' then
      l_weight := from_lbs_to_kgs(in_custid, in_lbs);
   end if;

   return l_weight;
exception
   when OTHERS then
      return -1;
end weight_to_display;

procedure check_pick_weight_range
   (in_qty       in number,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_lpid      in varchar2,       -- optional
    in_orderid   in number,
    in_shipid    in number,
    in_orderitem in varchar2,
    in_orderlot  in varchar2,
    in_weight    in number,
    out_lower    out number,
    out_upper    out number,
    out_message  out varchar2)
is
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotnumber varchar2) is
      select nvl(OD.weight_entered_lbs,0) as weight_entered_lbs,
             nvl(OD.weight_entered_kgs,0) as weight_entered_kgs,
             nvl(OD.weightpick,0) as weightpick,
             OD.custid,
             decode(nvl(OD.variancepct_use_default,'Y'),'N',
                    nvl(OD.variancepct,0),zci.variancepct(OD.custid,OD.item)) as variancepct,
             decode(nvl(OD.variancepct_use_default,'Y'),'N',
                    nvl(OD.variancepct_overage,0),zci.variancepct_overage(OD.custid,OD.item)) as variancepct_overage,
             OD.qtytype,
             nvl(CU.paperbased,'N') as paperbased
      from orderdtl OD, customer CU
      where OD.orderid = p_orderid
        and OD.shipid = p_shipid
        and OD.item = p_item
        and nvl(OD.lotnumber,'x') = nvl(p_lotnumber,'x')
        and CU.custid = OD.custid;
   od c_od%rowtype := null;
   l_weight number;
   l_picks_todo pls_integer;

begin

   out_message := 'Not in weight range';     -- assume the worst
   out_lower := 0;
   out_upper := 0;

   open c_od(in_orderid, in_shipid, in_orderitem, in_orderlot);
   fetch c_od into od;
   close c_od;

   select count(1) into l_picks_todo
      from shippingplate
      where orderid = in_orderid
        and shipid = in_shipid
        and orderitem = in_orderitem
        and nvl(orderlot,'x') = nvl(in_orderlot,'x')
        and status = 'U';

   -- assure we're in lbs
   if od.weight_entered_lbs = 0 then
      od.weight_entered_lbs := from_kgs_to_lbs(od.custid, od.weight_entered_kgs);
   end if;

   -- calculate weight for qty
   if l_picks_todo = 0 then
      l_weight := od.weightpick;
   elsif nvl(in_weight,0) != 0 then
      l_weight := in_weight;
   elsif in_lpid is not null then
      l_weight := in_qty * zcwt.lp_item_weight(in_lpid, od.custid, in_item, in_uom);
   else
      l_weight := in_qty * zci.item_weight(od.custid, in_item, in_uom);
   end if;

   if l_picks_todo != 0 then
     l_weight := l_weight + od.weightpick;
   end if;

   case od.qtytype
      when 'E' then                       -- exact
         out_lower := od.weight_entered_lbs;
         out_upper := od.weight_entered_lbs;
         if (l_picks_todo <= 1) or (od.paperbased = 'Y') then     -- last pick
            if l_weight = od.weight_entered_lbs then
               out_message := 'OKAY';
            end if;
         else                             -- not last, no overage
            if l_weight < od.weight_entered_lbs then
               out_message := 'OKAY';
            end if;
         end if;

      when 'A' then                       -- approximate
         out_lower := (od.variancepct/100) * od.weight_entered_lbs;
         out_upper := (od.variancepct_overage/100) * od.weight_entered_lbs;
         if (l_picks_todo <= 1) or (od.paperbased = 'Y') then     -- last pick
            if l_weight between out_lower and out_upper then
               out_message := 'OKAY';
            end if;
            if l_weight < od.weight_entered_lbs then
              out_message := 'MORE';
            end if;
         else                             -- not last, no overage
            if l_weight < out_upper then
               out_message := 'OKAY';
            end if;
         end if;

      else                       -- probably null
         if l_weight > 0 then
            out_message := 'OKAY';
         end if;
   end case;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end check_pick_weight_range;

FUNCTION order_by_weight_qty
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
) return number
is

cursor curOrderdtl is
  select custid,
         uom,
         qtyorder,
         weight_entered_lbs,
         weight_entered_kgs,
         qtytype
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x');
od curOrderdtl%rowtype;

begin

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderdtl;

if od.custid is null then
  return 0;
end if;

if (nvl(od.weight_entered_lbs,0) = 0) and
   (nvl(od.weight_entered_kgs,0) = 0) then
  return od.qtyorder;
end if;

return calc_order_by_weight_qty(od.custid,in_item,od.uom,
                                od.weight_entered_lbs,
                                od.weight_entered_kgs,
                                nvl(od.qtytype,'A'));

exception when others then
  return 1;
end order_by_weight_qty;

function calc_order_by_weight_qty
(in_custid varchar2
,in_item varchar2
,in_uom varchar2
,in_weight_entered_lbs number
,in_weight_entered_kgs number
,in_qtytype varchar2
) return number is

qtyCalculated number;
numItemWeight number;

begin

numItemWeight := nvl(zci.item_weight(in_custid,in_item,in_uom),0);
if nvl(numItemWeight,0) = 0 then
  return 1;
end if;

if nvl(in_weight_entered_lbs,0) != 0 then
  qtyCalculated := in_weight_entered_lbs / numItemWeight;
else
	qtyCalculated := zwt.from_kgs_to_lbs(in_custid, in_weight_entered_kgs) / numItemWeight;
end if;

if (mod(qtyCalculated,1) < .000001) then
  qtyCalculated := floor(qtyCalculated);
else
  qtyCalculated := ceil(qtyCalculated);
end if;

if qtyCalculated = 0 then
  qtyCalculated := 1;
end if;

return qtyCalculated;

exception when others then
  return 1;
end calc_order_by_weight_qty;


procedure get_lineitem_weight
   (in_orderid     in number,
    in_shipid      in number,
    in_item        in varchar2,
    in_lotnumber   in varchar2,
    out_weight     out number,
    out_tot_weight out number,
    out_confirmed  out varchar2,
    out_message    out varchar2)
is
   cursor c_itm(p_orderid number, p_shipid number, p_item varchar2) is
      select CI.use_catch_weights,
             CX.allow_lineitem_weights
         from orderhdr OH, custitemview CI, customer_aux CX
         where OH.orderid = p_orderid
           and OH.shipid = p_shipid
           and CI.custid (+) = OH.custid
           and CI.item (+) = p_item
           and CX.custid (+) = OH.custid;
   itm c_itm%rowtype := null;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lotno varchar2) is
      select nvl(receipt_weight_confirmed,'N') as confirmed,
             decode (nvl(weight_entered_lbs,0),
               0, nvl(zwt.from_kgs_to_lbs(custid, weight_entered_kgs),0),
                  weight_entered_lbs) as weight,
             qtyorder
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber, '(none)') = nvl(p_lotno, '(none)');
  od c_od%rowtype := null;
begin
   out_message := 'OKAY';
   out_weight := 0;
   out_tot_weight := 0;
   out_confirmed := 'Y';

   open c_itm(in_orderid, in_shipid, in_item);
   fetch c_itm into itm;
   close c_itm;
   if nvl(itm.use_catch_weights,'N') = 'Y'
   and nvl(itm.allow_lineitem_weights,'N') = 'Y' then
      open c_od(in_orderid, in_shipid, in_item, in_lotnumber);
      fetch c_od into od;
      close c_od;
      if nvl(od.weight,0) != 0 and nvl(od.qtyorder,0) != 0 then
         out_tot_weight := od.weight;
         out_weight := od.weight / od.qtyorder;
         out_confirmed := od.confirmed;
      end if;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end get_lineitem_weight;


procedure confirm_received_weight
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotnumber  in varchar2,
    in_weight     in number,
    out_message   out varchar2)
is
begin
   out_message := 'OKAY';
   update orderdtl
      set receipt_weight_confirmed = 'Y',
          weight_entered_lbs = decode(weight_entered_lbs, null, null, in_weight),
          weight_entered_kgs = decode(weight_entered_kgs, null, null, in_weight)
      where orderid = in_orderid
        and shipid = in_shipid
        and item = in_item
        and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)')
        and nvl(receipt_weight_confirmed,'N') = 'N';
   if sql%rowcount = 0 then
      out_message := 'NONE';
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end confirm_received_weight;


begin

begin
   select substr(defaultvalue,1,1)
      into custom_kg
      from systemdefaults
      where defaultid = 'CUSTOM_KG_CONVERSION';
exception
   when OTHERS then
      custom_kg := null;
end;

if custom_kg is null then
    custom_kg := 'N';
end if;

end zweight;
/
show error package zweight;
show error package body zweight;
exit;
