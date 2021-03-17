create or replace function carriersheet_building
   (in_orderid in number,
    in_shipid  in number)
return varchar2
is
   cursor c_oh is
      select *
        from orderhdr
       where orderid=in_orderid
		 and shipid=in_shipid;
   oh c_oh%rowtype;

   cursor c_od is
      select count(1) count
        from orderdtl od
       where orderid=in_orderid
		 and shipid=in_shipid
		 and linestatus<>'X'
		 and nvl(qtyorder,0) <>
		 nvl((select sum(quantity)
		       from shippingplate sp
			  where sp.orderid = in_orderid
			    and sp.shipid = in_shipid
				and sp.orderitem = od.item
				and nvl(sp.orderlot,'(none)') = nvl(od.lotnumber,'(none)')
				and sp.type in ('F','P')),0);
   od c_od%rowtype;

   cursor c_bd is
      select building from(
      select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,
1,2))),'?') building
        from shippingplate sp, location lo
       where sp.orderid=in_orderid
         and sp.shipid=in_shipid
         and sp.status<>'U'
         and sp.status<>'SH'
         and sp.type in ('F','P')
         and sp.facility='11'
         and sp.facility=lo.facility
         and sp.pickedfromloc=lo.locid
       union
      select nvl(substr(lo.pickingzone,1,(decode(length(lo.pickingzone),3,
1,2))),'?')
        from shippingplate sp, location lo
       where sp.orderid=in_orderid
         and sp.shipid=in_shipid
         and sp.status='U'
         and sp.type in ('F','P')
         and sp.facility='11'
         and sp.facility=lo.facility
         and sp.location=lo.locid)
	   order by decode(building,'8','9','89','9',building);
   bd c_bd%rowtype;

   building varchar2(20);
begin

   building := '';

   open c_oh;
   fetch c_oh into oh;
   close c_oh;

   if oh.fromfacility <> '11' then
     return '';
   end if;

   if oh.orderstatus in ('0','1','2','3','9','X') then
     return '?';
   end if;

   for bd in c_bd
   loop
     if(length(building)>0) then
	     building := building || ',';
	   end if;
	   if (bd.building = '8' or bd.building = '89') then
	     building := building || '9';
	   else
       building := building || bd.building;
	   end if;
   end loop;

   open c_od;
   fetch c_od into od;
   close c_od;

   if(od.count > 0) and (instr(building,'?') = 0) then
     if(length(building)>0) then
	     building := building || ',';
	   end if;
	   building := building || '?';
   end if;

   return building;

exception
   when OTHERS then
      return '?';
end carriersheet_building;
/
create or replace function carriersheet_pallets
   (in_orderid in number,
    in_shipid  in number)
return varchar2
is
   cursor c_od is
      select decode(nvl(ci.pallet_qty,0),0,0,
              ceil(nvl(zbut.translate_uom_function(od.custid,od.item,od.qtyentered,od.uomentered,ci.pallet_uom)/ci.pallet_qty,0))) pallets
        from orderdtl od, custitem ci
       where od.orderid=in_orderid
         and od.shipid=in_shipid
         and od.linestatus<>'X'
         and ci.custid=od.custid
         and ci.item=od.item;
   od c_od%rowtype;

   pallets number;
begin

   pallets := 0;

   for od in c_od
   loop
     if (od.pallets = 0) then
       return '';
     end if;
     pallets := pallets + od.pallets;
   end loop;

   if (pallets = 0) then
     return '';
   end if;

   return to_char(pallets);

exception
   when OTHERS then
      return '';
end carriersheet_pallets;
/

CREATE OR REPLACE VIEW carriersheetview
(
orderid,
shipid,
building,
pieces,
cases,
cartons,
pallets,
weight,
weight_lbs,
weight_kgs,
hazarous,
userid
)
as
  select
oh.orderid,
oh.shipid,
carriersheet_building(oh.orderid,oh.shipid),
(select sum(nvl(zbut.translate_uom_function(oh.custid,od.item,od.qtyentered,od.uomentered,'PCS'),0))
    from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
(select sum(nvl(zbut.translate_uom_function(oh.custid,od.item,od.qtyentered,od.uomentered,'CS'),0))
    from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
(select sum(nvl(zbut.translate_uom_function(oh.custid,od.item,od.qtyentered,od.uomentered,'CTN'),0))
    from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
carriersheet_pallets(oh.orderid,oh.shipid),
(select sum(nvl(weightorder,0))
   from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
(select sum(nvl(weight_entered_lbs,0))
   from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
(select sum(nvl(weight_entered_kgs,0))
   from orderdtl od
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'),
decode((select count(1)
   from orderdtl od, custitem ci
   where od.orderid=oh.orderid
     and od.shipid=oh.shipid
     and od.linestatus<>'X'
     and ci.custid=od.custid
     and ci.item=od.item
     and nvl(ci.hazardous,'N')='Y'),0,'','HZ'),
(select userid
   from orderhistory
  where orderid=oh.orderid
    and shipid=oh.shipid
    and action='ADD'
    and rownum=1)
from orderhdr oh;
exit;


