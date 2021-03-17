create or replace package body bill_3linx as

function get_weight
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2 )
return number
is
rc number(10,1);
gItem shippingplate.item%type;
begin
   rc := 0;
   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   begin
      select actweight into rc
         from multishipdtl
         where cartonid = in_carton;
   exception when others then
      return rc;
   end;

   return rc;
end get_weight;

function get_cost
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2 )
return number
is
rc number(10,2);
gItem shippingplate.item%type;
begin
   rc := 0;
   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   begin
      select cost into rc
         from multishipdtl
         where cartonid = in_carton;
   exception when others then
      return rc;
   end;

   return rc;
end get_cost;

function get_insurance
(in_custid in varchar2,
 in_item in varchar2,
 in_qty in number )
return number
is
rc number(10,2);
pNum number(16,4);
strMsg appmsgs.msgtext%type;

begin

   begin
      select (trunc(nvl(itmpassthrunum01,0) * in_qty / 100) + 1) * 100 into rc -- value rounded up to neares multiple of 100
         from custitem
         where custid = in_custid
           and item = in_item;
   exception when others then
      rc := 100;
   end;

   return rc;
end get_insurance;

function get_insurance2
(in_custid in varchar2,
 in_item in varchar2,
 in_qty in number,
 in_lpid in varchar2 )
return number
is
rc number(10,2);
pNum number(16,4);
pAmt number(10,2);
strMsg appmsgs.msgtext%type;
gItem shippingplate.item%type;
begin
   rc := 0;
   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   for b in (select custid, orderid, shipid, item, quantity from bill_3linx_base where parentlpid = in_lpid) loop
      rc := rc + in_qty * zci.item_amt(b.custid, b.orderid, b.shipid, b.item, null);
   end loop;
   rc:= (trunc(rc / 100) + 1) * 100;
   return rc;
end get_insurance2;

function get_ordercharge
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2,
 in_orderid in number,
 in_shipid in number )
return number
is
tCharge varchar2(12);
oCharge number(10,2);
rc number(10,1);
gLpid shippingplate.lpid%type;
gItem shippingplate.item%type;
begin
   rc := 0;
   begin
      select min(lpid) into gLpid
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and type != 'P';
   exception when others then
      return rc;
   end;
   if gLpid != in_lpid then
      return rc;
   end if;

   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   begin
      select actweight into rc
         from multishipdtl
         where cartonid = in_carton;
   exception when others then
      return rc;
   end;
   begin
      select to_number(abbrev) into rc
         from bill3linxparm
         where rtrim(code) = 'ORDERCHG';
   exception when others then
      rc := 2.01;
   end;

   return rc;
end get_ordercharge;

function get_picks2
(in_custid in varchar2,
 in_item in varchar2,
 in_qty in number )
return integer
is
rc number(10,2);
pQty number;
nQty number;
pUom varchar2(20);
strMsg appmsgs.msgtext%type;
cursor c_uom is
   select cu.qty, cu.touom
   from custitemuom cu, custitem ci
   where cu.custid = in_custid
     and cu.item = in_item
     and cu.custid = ci.custid
     and cu.item = ci.item
     and cu.fromuom = ci.baseuom
     and touom != 'PT'
   order by sequence;

begin
   rc := 0;
   open c_uom;
   fetch c_uom into pQty, pUom;
   if c_uom%notfound then
      rc := in_qty;
   else
      if pQty != 0 then
         if in_qty < pQty then
            rc := in_qty;
         else
            nQty := in_qty;
            while nQty >= pQty loop
               rc := rc + 1;
               nQty := nQty - pqty;
            end loop;
            rc := rc + nQty;
         end if;
      else
         rc := in_qty;
      end if;
   end if;

   return rc;
end get_picks2;


function get_picks
(in_custid in varchar2,
 in_item in varchar2,
 in_qty in number )
return number
is
rc number(10,2);
pQty number;
strMsg appmsgs.msgtext%type;

begin

   begin
      select qty into pQty
         from custitemuom
         where custid = in_custid
           and item = in_item
           and touom = 'CS';
   exception when others then
      pQty := 1;
   end;
   rc := in_qty / pQty;

   return rc;
end get_picks;

function get_itemcharge
(in_custid in varchar2,
 in_item in varchar2,
 in_qty in number )
return number
is
rc number(10,2);
itemRate number(10,2);
pQty integer;
nQty integer;
pUom varchar2(20);
strMsg appmsgs.msgtext%type;
result integer;
cursor c_uom is
   select cu.qty, cu.touom
   from custitemuom cu, custitem ci
   where cu.custid = in_custid
     and cu.item = in_item
     and cu.custid = ci.custid
     and cu.item = ci.item
     and cu.fromuom = ci.baseuom
     and touom != 'PT'
   order by sequence;

begin

   result := 0;
   open c_uom;
   fetch c_uom into pQty, pUom;
   if c_uom%notfound then
      result := in_qty;
   else
      if pQty != 0 then
         if in_qty < pQty then
            result := in_qty;
         else
            nQty := in_qty;
            while nQty >= pQty loop
               result := result + 1;
               nQty := nQty - pqty;
            end loop;
            result := result + nQty;
         end if;
      else
         result := in_qty;
      end if;
   end if;


   begin
      select to_number(nvl(abbrev,'0')) into itemRate
         from bill3linxparm
         where rtrim(code) = 'ITEMRATE';
   exception when others then
      itemRate := 0;
   end;
   rc := result * itemRate;

   return rc;
end get_itemcharge;

function get_surcharge
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2,
 in_orderid in number,
 in_shipid in number,
 in_carrier in varchar2)
return number
is
rc number(10,1);
gItem shippingplate.item%type;
pCnt number;
cWeight number;
pWeight number;
cCube number;
pCube number;
gLpid shippingplate.lpid%type;

begin
   rc := 0;
   begin
      select min(lpid) into gLpid
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and type != 'P';
   exception when others then
      return rc;
   end;
   if gLpid != in_lpid then
      return rc;
   end if;

   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   select count(1) into pCnt
      from bill3linxparm
      where rtrim(code) = 'LTL'
        and abbrev = in_carrier;
   if pCnt > 0 then
      begin
          select to_number(nvl(abbrev,'0')) into rc
            from bill3linxparm
            where rtrim(code) = 'SURLTL';
      exception when others then
         rc := 0;
      end;
      return rc;
   end if;

   begin
      select actweight into cWeight
         from multishipdtl
         where cartonid = in_carton;
   exception when others then
      return rc;
   end;
   begin
      select to_number(nvl(abbrev,'0')) into pWeight
        from bill3linxparm
        where rtrim(code) = 'SURWEIGHT';
   exception when others then
        pWeight := 9999;
   end;
   if cWeight > pWeight then
      begin
         select to_number(nvl(abbrev,'0')) into rc
           from bill3linxparm
           where rtrim(code) = 'SURWEIGHTAMT';
      exception when others then
           rc := 0;
      end;
      return rc;
   end if;

   begin
      select to_number(nvl(abbrev,'0')) into pCube
        from bill3linxparm
        where rtrim(code) = 'SURCUBE';
   exception when others then
        rc := 0;
        return rc;
   end;

   begin
      select sum(sp.quantity * ci.cube) into cCube
         from shippingplate sp, custitem ci
         where parentlpid = in_lpid
           and type in ('F', 'P')
           and ci.custid = sp.custid
           and ci.item = sp.item;
   exception when others then
      rc := 0;
      return rc;
   end;

   if cCube > pCube then
      begin
         select to_number(nvl(abbrev,'0')) into rc
           from bill3linxparm
           where rtrim(code) = 'SURCUBEAMT';
      exception when others then
         rc := 0;
      end;
   end if;
   return rc;
end get_surcharge;

function get_customdoc
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2,
 in_countrycode in varchar2,
 in_orderid in number,
 in_shipid in number
 )
return number
is
rc number(10,1);
gItem shippingplate.item%type;
gLpid shippingplate.lpid%type;
pCnt number;
begin
   rc := 0;
   begin
      select min(lpid) into gLpid
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and type != 'P';
   exception when others then
      return rc;
   end;
   if gLpid != in_lpid then
      return rc;
   end if;

   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   if in_countrycode is not null then
      if in_countrycode != 'US' and
         in_countrycode != 'USA' then
         begin
            select to_number(nvl(abbrev,'0')) into rc
              from bill3linxparm
              where rtrim(code) = 'CUSTOMDOC';
          exception when others then
              rc := 0;
          end;
      end if;
   end if;


   return rc;
end get_customdoc;


function get_print
(in_lpid in varchar2,
 in_carton in varchar2,
 in_item in varchar2,
 in_carrier in varchar2,
 in_orderid in number,
 in_shipid in number
 )
return number
is
rc number(10,1);
gItem shippingplate.item%type;
gLpid shippingplate.lpid%type;
pCnt number;

begin
   rc := 0;

   begin
      select min(lpid) into gLpid
         from shippingplate
         where orderid = in_orderid
           and shipid = in_shipid
           and type != 'P';
   exception when others then
      return rc;
   end;
   if gLpid != in_lpid then
      return rc;
   end if;


   begin
      select min(item) into gItem
         from shippingplate
         where parentlpid = in_lpid
           and type in ('F', 'P');
   exception when others then
      return rc;
   end;

   if gItem != in_item then
      return rc;
   end if;

   select count(1) into pCnt
      from bill3linxparm
      where rtrim(code) = 'LTL'
        and abbrev = in_carrier;
   if pCnt > 0 then
      begin
          select to_number(nvl(abbrev,'0')) into rc
            from bill3linxparm
            where rtrim(code) = 'PRTLTL';
      exception when others then
         rc := 0;
      end;
      return rc;
   end if;
   begin
       select to_number(nvl(abbrev,'0')) into rc
         from bill3linxparm
         where rtrim(code) = 'PRTORD';
   exception when others then
      rc := 0;
   end;

   return rc;
end get_print;



end bill_3linx;

/
show errors package body bill_3linx;
exit;
