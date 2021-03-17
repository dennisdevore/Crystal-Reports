create or replace PACKAGE BODY      zorderentry
IS
--
-- $Id$
--

-- Private code

procedure process_cancelled_charges
   (in_orderid  in number,
    in_shipid   in number,
    in_user     in varchar2)
is
   cursor c_id is
      select rowid, invoice, custid, facility
         from invoicedtl
         where orderid = in_orderid
           and shipid = in_shipid;
   errno number;
   msg varchar2(255);
   logmsg varchar2(255);
   invnum invoicedtl.invoice%type := 0;
begin
   for id in c_id loop
      if nvl(id.invoice, 0) = 0 then
         if invnum = 0 then
            zba.locate_accessorial_invoice(id.custid, id.facility, in_user, invnum,
                  errno, msg);
            if (errno != 0) then
               zms.log_msg('OrdCanCharge', id.facility, id.custid,  'Locate error: ' || msg,
                     'E', in_user, logmsg);
               goto continue_loop;
            end if;
         end if;
         update invoicedtl
            set invoice = invnum
            where rowid = id.rowid;

         zba.calc_accessorial_invoice(invnum, errno, msg);
         if (errno != 0) then
            zms.log_msg('OrdCanCharge', id.facility, id.custid,  'Calc error: ' || msg,
                  'E', in_user, logmsg);
         end if;
      end if;
   <<continue_loop>>
      null;
   end loop;

exception
   when OTHERS then
      null;
end process_cancelled_charges;

procedure estimate_order_values
   (in_orderid  in number,
    in_shipid   in number,
    in_custid   in varchar2,
    in_userid   in varchar2,
    out_errorno out number,
    out_msg     out varchar2)
is
   cursor c_cax(p_custid varchar2) is
      select estimate_cartons
         from customer_aux
         where custid = p_custid;
   cax c_cax%rowtype := null;
   cursor c_cmin(p_cartongroup varchar2, p_weight number, p_cube number) is
      select code as cartontype,
             nvl(maxweight,0) as maxweight,
             (nvl(maxcube,0)+1) / 1728.0 as maxcube
         from cartongroupsview
         where cartongroup = p_cartongroup
           and maxweight >= p_weight
           and nvl(maxcube,0) / 1728.0 >= p_cube
         order by maxcube, maxweight;
   cmin c_cmin%rowtype;
   cursor c_cmax(p_cartongroup varchar2) is
      select code as cartontype,
             nvl(maxweight,0) as maxweight,
             (nvl(maxcube,0)+1) / 1728.0 as maxcube
         from cartongroupsview
         where cartongroup = p_cartongroup
         order by maxcube desc, maxweight;
   cmax c_cmax%rowtype;
   cursor c_ctn(p_cartontype varchar2) is
      select nvl(length*width*height,0) / 1728.0 as cube,
             nvl(container_weight,0) as container_weight,
             nvl(typeorgroup,'C') as typeorgroup,
             nvl(maxcube,0) / 1728.0 as maxcube,
             nvl(maxweight,0) as maxweight
         from cartontypes
         where code = p_cartontype;
   ctn c_ctn%rowtype;
   cursor curLocation(p_item varchar2, p_uom varchar2) is
      select lo.pickingseq pickseq, lo.locid location
        from orderhdr oh,
             itempickfronts ipf,
             location lo
       where oh.orderid = in_orderid
         and oh.shipid = in_shipid
         and ipf.custid = in_custid
         and ipf.item = p_item
         and ipf.facility = oh.fromfacility
         and ipf.pickuom = p_uom
         and lo.facility = ipf.facility
         and lo.locid = ipf.pickfront;
   cloc curLocation%rowtype;
   cursor curCartonTypes is
     select cartontype,
            sum(weight) as weight,
            sum(cube) as cube
       from cartonitems_temp
      where exists (select *
                      from cartongroups
                     where cartongroups.cartongroup = cartonitems_temp.cartontype)
      group by cartontype;
   ct curCartonTypes%rowtype;
   cursor curCartonItems(p_cartontype varchar2) is
     select cartonitems_temp.*, rowid
       from cartonitems_temp
      where cartontype = ct.cartontype
        and exists (select *
                      from cartongroups
                     where cartongroups.cartongroup = cartonitems_temp.cartontype)
      order by cartontype, pickseq, location, item;
   cit curCartonItems%rowtype;
   tempitem curCartonItems%rowtype;
   newitem curCartonItems%rowtype;
   cursor curCartonDetails is
     select cartonitems_temp.*, rowid
       from cartonitems_temp
      where cartonseq is null
      order by cartontype, pickseq, location, item;
   cdt curCartonDetails%rowtype;
   cursor curCartonSub(in_cartontype varchar2) is
     select cartonseq,
            sum(weight) as weight,
            sum(cube) as cube
       from cartonitems_temp
      where cartontype = in_cartontype
        and cartonseq is not null
      group by cartonseq
      order by cartonseq desc;
   cs curCartonSub%rowtype;
   cursor curCartonLimits(in_cartontype varchar2) is
     select maxweight,
            (nvl(maxcube,0)+1) / 1728.0 as maxcube
       from cartontypes
      where code = in_cartontype;
   cl curCartonLimits%rowtype;
   cursor curCartonChkSum is
     select cartongroup,
            cartontype,
            cartonseq,
            sum(weight) as weight,
            sum(cube) as cube
       from cartonitems_temp
      group by cartongroup,cartontype,cartonseq
      order by cartongroup,cartontype,cartonseq;
   cc curCartonChkSum%rowtype;
   cursor curNextSeq (in_cartontype varchar2) is
     select nvl(max(cartonseq),0)+1 as cartonseq
       from cartonitems_temp
      where cartontype = in_cartontype;


   l_pickuom tasks.pickuom%type;
   l_pickqty tasks.pickqty%type;
   l_picktotype subtasks.picktotype%type;
   l_cartontype subtasks.cartontype%type;
   l_baseqty subtasks.qty%type;
   l_errorno integer;
   l_msg varchar2(255);
   l_item_qty orderdtl.qtyorder%type;
   l_pickweight subtasks.weight%type;
   l_pickcube subtasks.cube%type;
   l_tot_cartons orderhdr.estimated_cartons%type := 0;
   l_tot_cube orderhdr.estimated_package_cube%type := 0;
   l_tot_pkg_weight orderhdr.estimated_package_weight_lbs%type := 0;
   l_tot_weight orderhdr.estimated_weight_lbs%type := 0;
   l_cartons orderhdr.estimated_cartons%type;
   l_cartonsbyweight orderhdr.estimated_cartons%type;
   l_cartonsbycube orderhdr.estimated_cartons%type;
   l_pkg_weight orderhdr.estimated_package_weight_lbs%type;
   l_weight orderhdr.estimated_weight_lbs%type;
   l_cube orderhdr.estimated_package_cube%type;
   l_cartonseq subtasks.cartonseq%type;
   l_cartoncount orderhdr.estimated_cartons%type;

   procedure add_detail
      (p_cartontype  in varchar2,
       p_item        in varchar2,
       p_qty         in number,
       p_uom         in varchar2,
       p_weight      in number,
       p_cube        in number,
       p_picktotype  in varchar2)
   is
      l_cartongroup cartongroups.cartongroup%type;
      cnt integer;
   begin
      select count(1)
        into cnt
        from cartonitems_temp
       where cartontype = p_cartontype
         and item = p_item
         and uom = p_uom;

      l_cartongroup := null;
      open c_ctn(l_cartontype);
      fetch c_ctn into ctn;
      close c_ctn;
      if(ctn.typeorgroup = 'G') then
         l_cartongroup := p_cartontype;
      end if;


      if cnt = 0 then
         cloc := null;
         open curLocation(p_item, p_uom);
         fetch curLocation into cloc;
         close curLocation;
         if(cloc.pickseq is null) then
            if(p_picktotype = 'PACK') then
               out_errorno := -200;
               out_msg := 'Pick front not set up for item '||p_item||', uom '||p_uom;
               return;
            else
               cloc.pickseq := 0;
            end if;
         end if;
         insert into cartonitems_temp(cartongroup, cartontype, item, qty, uom, weight, cube, cartonseq, pickseq, location)
            values (l_cartongroup, p_cartontype, p_item, p_qty, p_uom, p_weight, p_cube, null, cloc.pickseq, cloc.location);
      else
         update cartonitems_temp
            set qty = qty + p_qty,
                weight = weight + p_weight,
                cube = cube + p_cube
          where nvl(cartongroup,'xxx') = nvl(l_cartongroup,'xxx')
            and cartontype = p_cartontype
            and item = p_item
            and uom = p_uom;
      end if;
   end add_detail;

begin
   out_errorno := 0;
   out_msg := null;

   delete from cartonitems_temp;

   open c_cax(in_custid);
   fetch c_cax into cax;
   close c_cax;
   if nvl(cax.estimate_cartons,'N') != 'Y' then
      return;
   end if;

   for od in (select fromfacility, item, uom, qtyorder,
                     weightorder, cubeorder
               from orderdtl
               where orderid = in_orderid
                 and shipid = in_shipid
                 and linestatus != 'X'
               order by item) loop

      l_item_qty := od.qtyorder;
      loop
         exit when (l_item_qty <= 0);
         zgs.compute_largest_whole_pickuom(od.fromfacility, in_custid, od.item,
               od.uom, l_item_qty, l_pickuom, l_pickqty, l_picktotype, l_cartontype,
               l_baseqty, l_errorno, l_msg);
         l_pickweight := zci.item_weight(in_custid, od.item, l_pickuom) * l_pickqty;
         l_pickcube := zci.item_cube(in_custid, od.item, l_pickuom) * l_pickqty;

          add_detail(l_cartontype, od.item, l_pickqty, l_pickuom, l_pickweight, l_pickcube, l_picktotype);
          if out_errorno <> 0 then
             return;
          end if;

         l_item_qty := l_item_qty - l_baseqty;
      end loop;
   end loop;

   while ( 1 = 1 ) loop
      ct := null;
      open curCartonTypes;
      fetch curCartonTypes into ct;
      if ( curCartonTypes%notfound ) then
         close curCartonTypes;
         exit;
      end if;

      cmin := null;
      open c_cmin(ct.cartontype, ct.weight, ct.cube);
      fetch c_cmin into cmin;
      if ( c_cmin%notfound ) then
         close c_cmin;

         cmax := null;
         open c_cmax(ct.cartontype);
         fetch c_cmax into cmax;
         close c_cmax;

         l_weight := 0;
         l_cube := 0;
         for cit in curCartonItems(ct.cartontype) loop
            if ( (cit.weight + l_weight) > cmax.maxweight ) or
               ( (cit.cube + l_cube) > cmax.maxcube ) then
               tempitem := null;
               newitem := null;
               begin
                 if (cit.weight + l_weight) > cmax.maxweight then
                   tempitem.weight := cit.weight / cit.qty;
                   tempitem.qty := floor((cmax.maxweight - l_weight) / tempitem.weight);
                 else
                   tempitem.cube := cit.cube / cit.qty;
                   tempitem.qty := floor((cmax.maxcube - l_cube) / tempitem.cube);
                 end if;
               exception when others then
                 tempitem.qty := 0;
               end;

               if ( tempitem.qty > 0 ) then
                  newitem := cit;
                  newitem.qty := cit.qty - tempitem.qty;
                  newitem.weight := zci.item_weight(in_custid,cit.item,cit.uom) * newitem.qty;
                  newitem.cube := zci.item_cube(in_custid,cit.item,cit.uom) * newitem.qty;

                  cit.qty := tempitem.qty;
                  cit.weight := zci.item_weight(in_custid,cit.item,cit.uom) * cit.qty;
                  cit.cube := zci.item_cube(in_custid,cit.item,cit.uom) * cit.qty;

                  cloc := null;
                  open curLocation(newitem.item, newitem.uom);
                  fetch curLocation into cloc;
                  close curLocation;
                  if(cloc.pickseq is null) then
                     cloc.pickseq := 0;
                  end if;
                  insert into cartonitems_temp(cartongroup, cartontype, item, qty, uom, weight, cube, cartonseq, pickseq, location)
                     values(newitem.cartongroup, newitem.cartontype, newitem.item, newitem.qty, newitem.uom, newitem.weight, newitem.cube, null, cloc.pickseq, cloc.location);

                  cit.qty := tempitem.qty;
                  cit.weight := zci.item_weight(in_custid,cit.item,cit.uom) * cit.qty;
                  cit.cube := zci.item_cube(in_custid,cit.item,cit.uom) * cit.qty;

                  update cartonitems_temp
                     set cartontype = cmax.cartontype,
                         qty = cit.qty,
                         weight = cit.weight,
                         cube = cit.cube
                   where rowid = cit.rowid;
               else
                  if (cit.weight > cmax.maxweight) or
                     (cit.cube > cmax.maxcube) then
                     update cartonitems_temp
                        set cartontype = 'PAL'
                      where rowid = cit.rowid;
                  end if;
               end if;
               exit;
            else
               update cartonitems_temp
                  set cartontype = cmax.cartontype
                where rowid = cit.rowid;

                l_weight := l_weight + cit.weight;
                l_cube := l_cube + cit.cube;
            end if;
         end loop;
      else
         close c_cmin;
         update cartonitems_temp
            set cartontype = cmin.cartontype
          where cartontype = ct.cartontype;
      end if;
   close curCartonTypes;
   end loop;

   while ( 1 = 1 ) loop
      cdt := null;
      open curCartonDetails;
      fetch curCartonDetails into cdt;
      if ( curCartonDetails%notfound ) then
         close curCartonDetails;
         exit;
      end if;
      newitem.qty := 0;
      open curCartonSub(cdt.cartontype);
      fetch curCartonSub into cs;
      if curCartonSub%notfound then
        cs.cartonseq := 0;
        cs.weight := 0;
        cs.cube := 0;
      end if;
      close curCartonSub;
      open curCartonLimits(cdt.cartontype);
      fetch curCartonLimits into cl;
      if curCartonLimits%notfound then
        cl.maxweight := 100;
        cl.maxcube := 10;
      end if;
      close curCartonLimits;
      if ( (cdt.weight + cs.weight) > cl.maxweight ) or
         ( (cdt.cube + cs.cube) > cl.maxcube ) then
        begin
          if (cdt.weight + cs.weight) > cl.maxweight then
            tempitem.weight := cdt.weight / cdt.qty;
            tempitem.qty := floor((cl.maxweight - cs.weight) / tempitem.weight);
          else
            tempitem.cube := cdt.cube / cdt.qty;
            tempitem.qty := floor((cl.maxcube - cs.cube) / tempitem.cube);
          end if;
        exception when others then
          tempitem.qty := 0;
        end;
        if (tempitem.qty > 0) and
           (cdt.qty > tempitem.qty) then
          newitem := cdt;
          newitem.qty := cdt.qty - tempitem.qty;
          newitem.weight := zci.item_weight(in_custid,cdt.item,cdt.uom) * newitem.qty;
          newitem.cube := zci.item_cube(in_custid,cdt.item,cdt.uom) * newitem.qty;

          cdt.qty := tempitem.qty;
          cdt.weight := zci.item_weight(in_custid,cdt.item,cdt.uom) * cdt.qty;
          cdt.cube := zci.item_cube(in_custid,cdt.item,cdt.uom) * cdt.qty;
          if cs.cartonseq = 0 then
            cdt.cartonseq := 1;
          else
            cdt.cartonseq := cs.cartonseq;
          end if;
        else
          cdt.cartonseq := cs.cartonseq + 1;
          if ( cdt.weight > cl.maxweight ) or
             ( cdt.cube > cl.maxcube ) then
             begin
                if (cdt.weight) > cl.maxweight then
                  tempitem.weight := cdt.weight / cdt.qty;
                  tempitem.qty := floor(cl.maxweight / tempitem.weight);
                else
                  tempitem.cube := cdt.cube / cdt.qty;
                  tempitem.qty := floor(cl.maxcube / tempitem.cube);
                end if;
             exception when others then
                tempitem.qty := 0;
             end;

             if (tempitem.qty > 0) and
                (cdt.qty > tempitem.qty) then
                newitem := cdt;
                newitem.qty := cdt.qty - tempitem.qty;
                newitem.weight := zci.item_weight(in_custid,cdt.item,cdt.uom) * newitem.qty;
                newitem.cube := zci.item_cube(in_custid,cdt.item,cdt.uom) * newitem.qty;

                cdt.qty := tempitem.qty;
                cdt.weight := zci.item_weight(in_custid,cdt.item,cdt.uom) * cdt.qty;
                cdt.cube := zci.item_cube(in_custid,cdt.item,cdt.uom) * cdt.qty;
             end if;
          end if;
        end if;
      else
        if cs.cartonseq = 0 then
          cdt.cartonseq := 1;
        else
          cdt.cartonseq := cs.cartonseq;
        end if;
      end if;
      if ( newitem.qty != 0 ) then
         cloc := null;
         open curLocation(newitem.item, newitem.uom);
         fetch curLocation into cloc;
         close curLocation;
         if(cloc.pickseq is null) then
            cloc.pickseq := 0;
         end if;
         insert into cartonitems_temp(cartongroup, cartontype, item, qty, uom, weight, cube, cartonseq, pickseq, location)
            values(newitem.cartongroup, newitem.cartontype, newitem.item, newitem.qty, newitem.uom, newitem.weight, newitem.cube, null, cloc.pickseq, cloc.location);
      end if;

      update cartonitems_temp
         set cartonseq = cdt.cartonseq,
             qty = cdt.qty,
             weight = cdt.weight,
             cube = cdt.cube
       where rowid = cdt.rowid;
      close curCartonDetails;
   end loop;

   open curCartonChksum;
   while ( 1 = 1 )
   loop
     fetch curCartonChkSum into cc;
     if curCartonChkSum%notfound then
       close curCartonChkSum;
       exit;
     end if;
     open c_cmin(cc.cartongroup, cc.weight, cc.cube);
     cmin.cartontype := '';
     fetch c_cmin into cmin;
     if (c_cmin%notfound) or
        (cc.cartontype = cmin.cartontype) then
       close c_cmin;
       goto continue_cartonchk_loop;
     end if;
     close c_cmin;
     close curCartonChkSum;
     l_cartonseq := 1;
     open curNextSeq(cmin.cartontype);
     fetch curNextSeq into l_cartonseq;
     close curNextSeq;
     update cartonitems_temp
        set cartontype = cmin.cartontype,
            cartonseq = l_cartonseq
      where cartontype = cc.cartontype
        and cartonseq = cc.cartonseq;
     update cartonitems_temp
        set cartonseq = cartonseq - 1
      where cartontype = cc.cartontype
        and cartonseq > cc.cartonseq;
     open curCartonChkSum;
   <<continue_cartonchk_loop>>
     null;
   end loop;

   l_tot_cartons := 0;
   l_tot_cube := 0;
   l_tot_pkg_weight := 0;
   l_tot_weight := 0;
   l_pkg_weight := 0;
   l_weight := 0;

   for ctns in (select cartontype, count(distinct cartonseq) as cartons, sum(weight) as weight, sum(cube) as cube
                from cartonitems_temp
               group by cartontype
               order by cartontype) loop
      open c_ctn(ctns.cartontype);
      fetch c_ctn into ctn;
      close c_ctn;

      l_pkg_weight := ctns.cartons*ctn.container_weight;
      l_weight := ctns.weight + l_pkg_weight;
      zoh.add_orderhistory(in_orderid, in_shipid, 'Carton Estimate',
            'Estimated '||ctns.cartons||' '||ctns.cartontype||' cartons :'
            ||ctns.cube||' cuft. '||l_pkg_weight||' lbs.  Total: '
            ||l_weight||' lbs.', in_userid, l_msg);

      l_tot_cartons := l_tot_cartons + ctns.cartons;
      l_tot_cube := l_tot_cube + ctns.cube;
      l_tot_pkg_weight := l_tot_pkg_weight + l_pkg_weight;
      l_tot_weight := l_tot_weight + l_weight;
   end loop;

   if (l_tot_cartons = 0) then
      zoh.add_orderhistory(in_orderid, in_shipid, 'Carton Estimate',
            'Estimated 0 cartons', in_userid, l_msg);
   end if;

   update orderhdr
      set estimated_cartons = l_tot_cartons,
          estimated_package_cube = l_tot_cube,
          estimated_package_weight_lbs = l_tot_pkg_weight,
          estimated_weight_lbs = l_tot_weight
      where orderid = in_orderid
        and shipid = in_shipid;

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,255);
      out_errorno := sqlcode;
end estimate_order_values;


-- Public code

FUNCTION cartontype_length
(in_cartontype IN varchar2
) return number is

out_length cartontypes.length%type;

begin

out_length := 0;

select length
  into out_length
  from cartontypes
 where code = in_cartontype;

return out_length;

exception when others then
  return out_length;
end cartontype_length;

FUNCTION cartontype_width
(in_cartontype IN varchar2
) return number is

out_width cartontypes.width%type;

begin

out_width := 0;

select width
  into out_width
  from cartontypes
 where code = in_cartontype;

return out_width;

exception when others then
  return out_width;
end cartontype_width;

FUNCTION cartontype_height
(in_cartontype IN varchar2
) return number is

out_height cartontypes.height%type;

begin

out_height := 0;

select height
  into out_height
  from cartontypes
 where code = in_cartontype;

return out_height;

exception when others then
  return out_height;
end cartontype_height;

FUNCTION sum_shipping_weight
(in_orderid IN number
,in_shipid  IN number
) return number is

out_weight shippingplate.weight%type;

begin

out_weight := 0;

select sum(weight)
  into out_weight
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and parentlpid is null
   and trackingno is not null
   and type in ('M','C');

return out_weight;

exception when others then
  return out_weight;
end sum_shipping_weight;

FUNCTION sum_shipping_cost
(in_orderid IN number
,in_shipid  IN number
) return number is

out_cost multishipdtl.cost%type;

begin

out_cost := 0;

select sum(cost)
  into out_cost
  from multishipdtl
 where orderid = in_orderid
   and shipid = in_shipid;

return out_cost;

exception when others then
  return out_cost;
end sum_shipping_cost;

FUNCTION max_shipping_container
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_lpid shippingplate.lpid%type;
lCons char(1);
cursor c_cons is
   select consolidated
      from waves
      where wave in (select wave from orderhdr
                      where orderid = in_orderid
                      and shipid = in_shipid);

begin
lCons := null;
open c_cons;
fetch c_cons into lCons;
close c_cons;

out_lpid := '';

if nvl(lCons,'N') = 'Y' then
   select max(parentlpid)
     into out_lpid
     from shippingplate
    where orderid = in_orderid
      and shipid = in_shipid
      and type in ('F','P');
else
   select max(lpid)
     into out_lpid
     from shippingplate
    where orderid = in_orderid
      and shipid = in_shipid
      and parentlpid is null
      and type in ('M','C');
end if;

return out_lpid;

exception when others then
  return out_lpid;
end max_shipping_container;

FUNCTION min_nonserial_lpid
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_lpid shippingplate.lpid%type;

begin

out_lpid := '';

select min(lpid)
  into out_lpid
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and type in ('F','P')
   and serialnumber is null;

return out_lpid;

exception when others then
  return out_lpid;
end min_nonserial_lpid;

FUNCTION max_cartontype
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_cartontype shippingplate.cartontype%type;

begin

out_cartontype := '';

select max(cartontype)
  into out_cartontype
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and parentlpid is null
   and type in ('M','C');

return out_cartontype;

exception when others then
  return out_cartontype;
end max_cartontype;

FUNCTION max_trackingno
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2 default null
,in_orderlot IN varchar2 default null
) return varchar2 is

out_trackingno shippingplate.trackingno%type;

begin

out_trackingno := '';

if rtrim(in_orderitem) is null then
  select max(trackingno)
    into out_trackingno
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and parentlpid is null
     and trackingno is not null
     and type in ('M','C','F');
else
  select max(substr(zmp.shipplate_trackingno(nvl(parentlpid,lpid)),1,30))
    into out_trackingno
    from ShippingPlate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'SH';
end if;

return out_trackingno;

exception when others then
  return out_trackingno;
end max_trackingno;

FUNCTION max_carrierused
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_carrierused multishipdtl.carrierused%type;

begin

out_carrierused := '';

select carrierused
  into out_carrierused
  from multishipdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and zoe.max_trackingno(in_orderid,in_shipid) = trackid;

return out_carrierused;

exception when others then
  return out_carrierused;
end max_carrierused;

FUNCTION unknown_lip_count
(in_orderid IN number
,in_shipid  IN number
) return number is

out_count integer;

begin

out_count := 0;

select count(1)
  into out_count
  from plate
 where orderid = in_orderid
   and shipid = in_shipid
   and item = 'UNKNOWN';

return out_count;

exception when others then
  return 0;
end unknown_lip_count;

FUNCTION orderdtl_line_count
(in_orderid IN number
,in_shipid  IN number
) return number is

out_count integer;
strCustid customer.custid%type;
strPick_by_Line_Number_yn customer.pick_by_line_number_yn%type;

begin

out_count := 0;

begin
  select custid
    into strCustid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
exception when others then
  strCustID := null;
end;

begin
  select pick_by_line_number_yn
    into strpick_by_line_number_yn
    from customer
   where custid = strCustid;
exception when others then
  strpick_by_line_number_yn := 'N';
end;

if strPick_by_Line_number_yn = 'Y' then
  select count(1)
    into out_count
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.linestatus != 'X'
     and od.orderid = ol.orderid(+)
     and od.shipid = ol.shipid(+)
     and od.item = ol.item(+)
     and nvl(od.lotnumber,'x') = nvl(ol.lotnumber(+),'x')
     and nvl(ol.xdock,'N') = 'N';
--  select count(1)
--    into out_count
--    from orderdtlline ol
--   where orderid = in_orderid
--     and shipid = in_shipid
--     and not exists
--      (select * from orderdtl od
--        where od.orderid = ol.orderid
--          and od.shipid = ol.shipid
--          and od.item = ol.item
--          and nvl(od.lotnumber,'x') = nvl(ol.lotnumber,'x')
--          and od.linestatus = 'X');
else
  select count(1)
    into out_count
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';
end if;

return out_count;

exception when others then
  return 0;
end orderdtl_line_count;

FUNCTION orderdtlline_line_count
(in_orderid IN number
,in_shipid  IN number
) return number is

out_count integer;

begin

out_count := 0;

  select count(1)
    into out_count
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.linestatus != 'X'
     and od.orderid = ol.orderid(+)
     and od.shipid = ol.shipid(+)
     and od.item = ol.item(+)
     and nvl(od.lotnumber,'x') = nvl(ol.lotnumber(+),'x')
     and nvl(ol.xdock,'N') = 'N';

return out_count;

exception when others then
  return 0;
end orderdtlline_line_count;

PROCEDURE get_next_orderid
(out_orderid OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select orderseq.nextval
    into out_orderid
    from dual;
  select count(1)
    into currcount
    from orderhdr
   where orderid = out_orderid;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_orderid;

PROCEDURE get_base_uom_equivalent
(in_custid IN varchar2
,in_itemalias IN varchar2
,in_uom IN varchar2
,in_qty IN number
,out_item OUT varchar2
,out_uom  OUT varchar2
,out_qty  OUT number
,out_msg  OUT varchar2
) is

cursor baseuom is
  select baseuom, status
    from custitem
   where custid = in_custid
     and item = out_item;
b baseuom%rowtype;

cursor equivuom(in_uom varchar2) is
  select fromuom, qty
    from custitemuom
   where custid = in_custid
     and item = out_item
     and touom = in_uom;
e equivuom%rowtype;

loopcount integer;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;

begin

out_item := '';
out_qty := 0;
out_msg := '';

zci.get_customer_item(in_custid,in_itemalias,out_item,strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  return;
end if;

open baseuom;
fetch baseuom into b;
if baseuom%notfound then
  close baseuom;
  out_msg := 'Item row not found';
  return;
end if;
close baseuom;

loopcount := 0;
out_qty := in_qty;
out_uom := in_uom;
if in_qty != 0 then
  while out_uom != b.baseuom
  loop
    if loopcount > 255 then
      out_msg := 'Unable to calculate equivalent UOM (loop)';
      return;
    end if;
    open equivuom(out_uom);
    fetch equivuom into e;
    if equivuom%notfound then
      close equivuom;
      out_msg := 'Unable to calculate equivalent UOM';
      return;
    end if;
    close equivuom;
    out_uom := e.fromuom;
    out_qty := out_qty * e.qty;
    loopcount := loopcount + 1;
  end loop;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end get_base_uom_equivalent;

PROCEDURE get_base_uom_equivalent_up
(in_custid IN varchar2
,in_itemalias IN varchar2
,in_uom IN varchar2
,in_qty IN number
,out_item OUT varchar2
,out_uom  OUT varchar2
,out_qty  OUT number
,out_entered_uom out varchar2
,out_entered_qty out varchar2
,out_msg  OUT varchar2
) is
cursor baseuom is
  select baseuom, status
    from custitem
   where custid = in_custid
     and item = out_item;
b baseuom%rowtype;
cursor equivuom(in_uom varchar2) is
  select touom, fromuom, qty
    from custitemuom
   where custid = in_custid
     and item = out_item
     and (touom = in_uom or
          fromuom = in_uom);
e equivuom%rowtype;
loopcount integer;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
begin
out_item := '';
out_qty := 0;
out_msg := '';
out_entered_uom := in_uom;
out_entered_qty := in_qty;
zci.get_customer_item(in_custid,in_itemalias,out_item,strLotRequired,strHazardous,strIsKit,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  return;
end if;
open baseuom;
fetch baseuom into b;
if baseuom%notfound then
  close baseuom;
  out_msg := 'Item row not found';
  return;
end if;
close baseuom;
loopcount := 0;
out_qty := in_qty;
out_uom := in_uom;
if in_qty != 0 then
  while out_uom != b.baseuom
  loop
    if loopcount > 255 then
      out_msg := 'Unable to calculate equivalent UOM (loop)';
      return;
    end if;
    open equivuom(out_uom);
    fetch equivuom into e;
    if equivuom%notfound then
      close equivuom;
      out_msg := 'Unable to calculate equivalent UOM';
      return;
    end if;
    close equivuom;
    if e.touom=out_uom AND e.fromuom=b.baseuom then
        out_uom := e.fromuom;
        out_qty := out_qty * e.qty;
    end if;
    if e.fromuom=out_uom AND e.touom=b.baseuom then
        out_uom := e.touom;
        out_qty := out_qty / e.qty;
        out_entered_uom := e.touom;
        out_entered_qty := out_qty;
    end if;
    loopcount := loopcount + 1;
  end loop;
end if;
out_msg := 'OKAY';
exception when others then
  out_msg := substr(sqlerrm,1,80);
end get_base_uom_equivalent_up;
PROCEDURE cancel_item
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor Corderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         nvl(loadno,0) as loadno,
         nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility,
         nvl(fromfacility,' ') as fromfacility,
         nvl(qtyorder,0) as qtyorder,
         nvl(weightorder,0) as weightorder,
         nvl(cubeorder,0) as cubeorder,
         nvl(amtorder,0) as amtorder,
         nvl(qtyCommit,0) as qtyCommit,
         nvl(qtyShip,0) as qtyShip,
         nvl(qtyPick,0) as qtyPick,
         custid,
         priority,
         carrier,
       shiptype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

cursor Corderdtl is
  select nvl(linestatus,'?') as linestatus,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyship,0) as qtyship,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty,
         uom
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'x') = nvl(in_lotnumber,'x');
od Corderdtl%rowtype;

newOrderStatus orderhdr.orderstatus%type;
cntRows integer;
is_shipped varchar2(1);
cancelledqty integer;
errMsg varchar2(255);
errNo integer;
itemcnt integer;
toplpid shippingplate.lpid%type;
topfromlpid shippingplate.fromlpid%type;
strMultiShip carrier.multiship%type;
v_items2pick number;

begin

out_msg := '';

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;
if oh.orderstatus > '8' then
  out_msg := 'Invalid order status: ' || oh.orderstatus;
  return;
end if;

begin
  select nvl(multiship,'N')
    into strMultiShip
    from carrier
   where carrier = oh.carrier;
exception when others then
  strMultiShip := 'N';
end;
/****
if oh.loadno != 0 then
  out_msg := 'Order is assigned to load: ' || oh.loadno;
  return;
end if;
****/

if oh.ordertype in ('T','U') then  -- branch or ownership transfer
  if (oh.tofacility != in_facility) and
     (oh.fromfacility != in_facility) then
    out_msg := 'Order not associated with your facility' || oh.tofacility;
    return;
  end if;
elsif oh.ordertype in ('R','Q','P','A','C','I') then  -- inbound
  if oh.tofacility != in_facility then
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
else
  if oh.fromfacility != in_facility then -- outbound
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
end if;

open Corderdtl;
fetch Corderdtl into od;
if Corderdtl%notfound then
  close Corderdtl;
  out_msg := 'Order item not found: ' || in_orderid || '-' || in_shipid
      || ' ' || in_item || ' ' || in_lotnumber;
  return;
end if;
close Corderdtl;

if od.linestatus != 'A' then
  out_msg := 'Item is not active: ' || od.linestatus;
  return;
end if;

if od.qtyrcvd != 0 then
  out_msg := 'Cannot cancel--receipts have been processed';
  return;
end if;

if (ztk.active_tasks_for_orderdtl(in_orderid, in_shipid, in_item, in_lotnumber)) then
  out_msg := 'Cannot cancel--there are active tasks';
  return;
end if;

if (ztk.passed_tasks_for_order(in_orderid, in_shipid)) then
  out_msg := 'Cannot cancel--order has passed tasks';
  return;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
     and status = 'SH';
exception when others then
  null;
end;
if cntRows != 0 then
  out_msg := 'Cannot cancel--shipments have been processed';
  return;
end if;

for sp in (select parentlpid from shippingplate
            where orderid = in_orderid
            and shipid = in_shipid
            and orderitem = in_item
            and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
            and type in ('F', 'P')
            and parentlpid is not null) loop

   select lpid into toplpid
      from shippingplate
      where parentlpid is null
      start with lpid = sp.parentlpid
      connect by prior parentlpid = lpid;

   begin
      select count(distinct orderitem) into itemcnt
         from shippingplate
         start with lpid = toplpid
         connect by prior lpid = parentlpid;
   exception
      when OTHERS then
         itemcnt := 0;
   end;

   if (itemcnt > 1) then
      out_msg := 'Cannot cancel--Shipping Units have mixed items';
      if strMultiShip = 'Y' then
        out_msg := out_msg ||
           chr(10) || chr(13) ||
           '(Set the order''s priority to "E"xception to prevent' ||
           chr(10) || chr(13) ||
           'small package station processing)';
      end if;
      return;
   end if;

end loop;

if strMultiShip = 'Y' then
  for spm in (select parentlpid from shippingplate
              where orderid = in_orderid
              and shipid = in_shipid
              and orderitem = in_item
              and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
              and type in ('F', 'P')
              and parentlpid is not null)
  loop

     select lpid,fromlpid into toplpid, topfromlpid
        from shippingplate
        where parentlpid is null
        start with lpid = spm.parentlpid
        connect by prior parentlpid = lpid;

     delete from multishipdtl
      where cartonid = topfromlpid;

  end loop;
end if;

if (oh.orderstatus > '0') then
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and linestatus = 'A';
  exception when others then
    null;
  end;
  if cntRows = 1 then
    zoe.cancel_order(in_orderid,in_shipid,
      in_facility,null,in_userid,out_msg);
    return;
  end if;
end if;

zwv.unrelease_line
    (oh.fromfacility
    ,oh.custid
    ,in_orderid
    ,in_shipid
    ,in_item
    ,od.uom
    ,in_lotnumber
    ,od.invstatusind
    ,od.invstatus
    ,od.invclassind
    ,od.inventoryclass
    ,od.qty
    ,oh.priority
    ,'X'  -- request type of cancel
    ,in_userid
    ,'N'  -- trace flag off
    ,out_msg
    );
if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('LineCancel', in_facility, oh.custid,
      out_msg, 'E', in_userid, out_msg);
end if;

update orderdtl
   set linestatus = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');

/* Check for oh.shiptype = 'S' and rest of the items in orderdetail are in shipped status.
Then Call shipped_order_updates with Multiship parameter. This update will start IEQ from Sysnapse */
if (oh.shiptype = 'S' and
    zmn.order_is_shipped(in_orderid,in_shipid) = 'Y') then
       zmn.shipped_order_updates(in_orderid,in_shipid,'MULTISHIP',errno,errmsg);
       zoh.add_orderhistory(in_orderid, in_shipid,
           'Order Shipped',
           'Order is in shipped status because of a item was cancelled',
           in_userid, out_msg);
       zsmtp.notify_order_shipped(in_orderid, in_shipid);
end if;

if oh.loadno != 0 then
   for sp in (select lpid, parentlpid from shippingplate
               where orderid = in_orderid
               and shipid = in_shipid
               and orderitem = in_item
               and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
               and type in ('F', 'P')
               and status in ('P', 'S')) loop

      if (sp.parentlpid is null) then
         toplpid := sp.lpid;
      else
         select lpid into toplpid
            from shippingplate
            where parentlpid is null
            start with lpid = sp.parentlpid
            connect by prior parentlpid = lpid;
      end if;

      update shippingplate
         set loadno = 0,
             stopno = 0,
             shipno = 0
         where rowid in (select rowid from shippingplate
                           start with lpid = toplpid
                           connect by prior lpid = parentlpid);
      end loop;
end if;

if oh.ordertype in ('R','Q','P','A','C','I') then
  goto finish_cancel;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)');
exception when others then
  null;
end;

if cntRows = 0 then
  begin
    select count(1)
      into cntRows
      from batchtasks
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_item
       and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)');
  exception when others then
    null;
  end;
  if cntRows = 0 then
    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_item
       and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)');
    delete from orderlabor
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_item
       and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
    delete from itemdemand
     where orderid = in_orderid
       and shipid = in_shipid
       and orderitem = in_item
       and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)');
  end if;
end if;

oh := null;
open Corderhdr;
fetch Corderhdr into oh;
close Corderhdr;
if oh.orderstatus is null then
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;

newOrderStatus := oh.orderstatus;
if oh.orderstatus < '4' then
  goto finish_cancel;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_item
     and nvl(orderlot,'(none)') = nvl(in_lotnumber,'(none)')
     and status = 'L';
exception when others then
  null;
end;

if cntRows = 0 then
  is_shipped := zmn.order_is_shipped(in_orderid,in_shipid);
  if is_shipped = 'Y' then
    if oh.loadno = 0 then
      newOrderStatus := '9';
    else
      newOrderStatus := '8';
    end if;
  end if;
end if;

if oh.orderstatus = '5' then
  select count(1) into v_items2pick
	from orderdtl 
  where orderid = in_orderid 
  and shipid = in_shipid 
  and linestatus != 'X'
  and (qtypick is null or qtypick < qtyorder);
  
  if v_items2pick = 0 then
    newOrderStatus := '6';
  end if;
end if;

if oh.orderstatus != newOrderStatus then
  if newOrderStatus = '9' then
    UPDATE orderhdr
       SET orderstatus = newOrderStatus,
           dateshipped = sysdate,
           packlistshipdate = sysdate,
           lastuser = in_UserId,
           lastupdate = sysdate
     WHERE orderid = in_OrderId
       AND shipid = in_ShipId;
    zmn.shipped_order_updates(in_orderid,in_shipid,in_userid,errno,errmsg);
--    zld.check_for_interface(0,in_orderid,in_shipid,in_facility,
--                            'REGORDTYPES','REGI44SNFMT','RETORDTYPES',
--                            'RETI9GIFMT','MULTISHIP',errmsg);
  else
    UPDATE orderhdr
       SET orderstatus = newOrderStatus,
           lastuser = in_UserId,
           lastupdate = sysdate
     WHERE orderid = in_OrderId
       AND shipid = in_ShipId;
  end if;
end if;

<<finish_cancel>>

out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end cancel_item;

PROCEDURE uncancel_item
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is
  oh  orderhdr%rowtype;
  od  orderdtl%rowtype;
begin

  out_msg := '';
  
  begin
    select *
    into oh
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
      return;
  end;
  
  if oh.orderstatus not in ('0','1') then
    out_msg := 'Invalid order status: ' || oh.orderstatus;
    return;
  end if;
  
  if oh.ordertype in ('T','U') then  -- branch or ownership transfer
    if (oh.tofacility != in_facility) and
       (oh.fromfacility != in_facility) then
      out_msg := 'Order not associated with your facility' || oh.tofacility;
      return;
    end if;
  elsif oh.ordertype in ('R','Q','P','A','C','I') then  -- inbound
    if oh.tofacility != in_facility then
      out_msg := 'Order not at your facility' || oh.tofacility;
      return;
    end if;
  else
    if oh.fromfacility != in_facility then -- outbound
      out_msg := 'Order not at your facility' || oh.tofacility;
      return;
    end if;
  end if;
  
  begin
    select *
    into od
    from orderdtl
    where orderid = in_orderid and shipid = in_shipid and item = in_item and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
  exception
    when others then
      out_msg := 'Order item not found: ' || in_orderid || '-' || in_shipid || ' ' || in_item || ' ' || in_lotnumber;
      return;
  end;
  
  if od.linestatus <> 'X' then
    out_msg := 'Line is not cancelled';
    return;
  end if;
  
  update orderdtl
  set linestatus = 'A', cancelreason = null
  where orderid = in_orderid and shipid = in_shipid and item = in_item and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)');

  out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end uncancel_item;

PROCEDURE cancel_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor Corderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         nvl(loadno,0) as loadno,
         nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility,
         nvl(fromfacility,' ') as fromfacility,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyship,0) as qtyship,
         custid,
         confirmed,
         priority,
         rejectcode,
         rejecttext,
         edicancelpending,
         reference,
         nvl(wave,0) as wave,
         workorderseq,
         po
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curShippingPlate is
  select count(1) as count
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH';
sp curShippingPlate%rowtype;

cursor curCustomer(in_custid varchar2) is
  select nvl(resubmitorder,'N') as resubmitorder,
         include_ack_cancel_orders_yn
    from customer cu, customer_aux caux
   where cu.custid = caux.custid
    and  cu.custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and facility = in_facility
     and not exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and tasks.priority = '0');

cntRows integer;
out_errorno integer;
rc integer;
strMsg varchar2(255);

procedure log_ack(in_status varchar2, in_comment varchar2) is
 l_importfileid import_order_acknowledgment.importfileid%type;
 
begin
  if nvl(cu.include_ack_cancel_orders_yn,'N') = 'Y' and 
     in_source = 'EDI' then
    begin
        select cancel_importfileid
          into l_importfileid
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid
           and custid = oh.custid
           and nvl(po,'(none)') = nvl(oh.po,'(none)')
           and reference = oh.reference;
    exception when others then
        l_importfileid := null;
    end;
    zimportprocs.log_order_import_ack(l_importfileid, oh.custid, oh.po, oh.reference,
             in_orderid, in_shipid, in_status, in_comment, 'D');
 end if;
end;

begin

out_msg := '';

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  log_ack('E',out_msg);
  return;
end if;
close Corderhdr;

if (oh.orderstatus > '8') and
   (oh.orderstatus != 'X') then
  out_msg := 'Invalid order status for cancel: ' ||
    in_orderid || '-' || in_shipid || ' Status: ' || oh.orderstatus;
  log_ack('E',out_msg);
  return;
end if;

if (in_source = 'CRT') and
   (oh.orderstatus = 'X') then
  out_msg := 'Invalid order status for cancel: ' ||
    in_orderid || '-' || in_shipid || ' Status: ' || oh.orderstatus;
  return;
end if;

if in_source = 'EDI' and
   (oh.orderstatus = 'X') then
  out_msg := 'Invalid order status for cancel: ' ||
  in_orderid || '-' || in_shipid || ' Status: ' || oh.orderstatus;
  log_ack('E',out_msg);
  return;
end if;

open curCustomer(oh.custid);
fetch curCustomer into cu;
if curCustomer%notfound then
  cu.resubmitorder := 'N';
end if;
close curCustomer;

if oh.ordertype in ('T','U') then  -- branch or ownership transfer
  if (oh.tofacility != in_facility) and
     (oh.fromfacility != in_facility) then
    out_msg := 'Order not associated with your facility ' || oh.tofacility;
    log_ack('E',out_msg);
    return;
  end if;
elsif oh.ordertype in ('R','Q','P','A','C','I') then  -- inbound
  if oh.tofacility != in_facility then
    out_msg := 'Order not at your facility' || oh.tofacility;
    log_ack('E',out_msg);
    return;
  end if;
  if oh.qtyrcvd != 0 then
    out_msg := 'Cannot cancel--receipts have been processed';
    log_ack('E',out_msg);
    return;
  end if;
else
  if oh.fromfacility != in_facility then -- outbound
    out_msg := 'Order not at your facility' || oh.tofacility;
    log_ack('E',out_msg);
    return;
  end if;
end if;

if ztk.active_tasks_for_order(in_orderid,in_shipid) = true then
  out_msg := 'There are active tasks for this order';
  return;  
end if;

if (ztk.passed_tasks_for_order(in_orderid, in_shipid)) then
  out_msg := 'There are passed tasks for this order';
  return;
end if;

sp.count := 0;
open curShippingPlate;
fetch curShippingPlate into sp.count;
if curShippingPlate%notfound then
  sp.count := 0;
end if;
close curShippingPlate;
if sp.count != 0 then
  out_msg := 'Cannot cancel--order ' || in_orderid || '-' || in_shipid ||
   ' has ' ||  sp.count || ' shipped pallets';
   log_ack('E',out_msg);
  return;
end if;

for od in curOrderdtl
loop
  zwv.unrelease_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,od.qty
      ,oh.priority
      ,'X'  -- request type of cancel
      ,in_userid
      ,'N'  -- trace flag off
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('OrderCancel', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
  end if;
end loop;

if oh.rejectcode is null then
  oh.rejectcode := 400;
  begin
    select descr
      into oh.rejecttext
      from ordervalidationerrors
     where code = '400';
  exception when others then
    oh.rejecttext := 'Manual Cancellation';
  end;
  if (oh.ordertype in ('O')) and
     (oh.reference is not null) then
    oh.edicancelpending := 'Y';
  end if;
  oh.confirmed := null;
end if;

update orderdtl
   set linestatus = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

update orderhdr
   set orderstatus = 'X',
       commitstatus = '0',
       rejectcode = oh.rejectcode,
       rejecttext = oh.rejecttext,
       edicancelpending = oh.edicancelpending,
       confirmed = oh.confirmed,
       lastuser = in_userid,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

if oh.wave != 0 then
  begin
    select min(orderstatus)
      into oh.orderstatus
      from orderhdr
     where wave = oh.wave
       and ordertype not in ('W','K');
  exception when no_data_found then
    oh.orderstatus := '9';
  end;
  if oh.orderstatus > '8' then
    update waves
       set wavestatus = '4',
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and wavestatus < '4';
  end if;
end if;

zmn.change_order(in_orderid,in_shipid,out_msg);

if oh.loadno != 0 then
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from shippingplate
     where orderid = in_orderid
       and shipid = in_shipid
       and status = 'L';
  exception when others then
    null;
  end;
  if cntRows = 0 then
    zld.deassign_order_from_load(in_orderid,in_shipid,in_facility,
      in_userid,'N',out_errorno,out_msg);
  end if;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid;
exception when others then
  null;
end;

if (cntRows <> 0) and
   (oh.ordertype in ('V','T','U')) then
  for st in curOrderTasks
  loop
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'Y', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('DeleteTask', st.facility, st.custid,
         out_msg, 'E', in_userid, strMsg);
    end if;
  end loop;
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from subtasks
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    null;
  end;
end if;

if cntRows = 0 then
  begin
    select count(1)
      into cntRows
      from batchtasks
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    null;
  end;
  if cntRows = 0 then
    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid;
    delete from orderlabor
     where orderid = in_orderid
       and shipid = in_shipid;
    delete from itemdemand
     where orderid = in_orderid
       and shipid = in_shipid;
  end if;
end if;

if in_source = 'CRT' then
   rc := zba.calc_accessorial_charges('ODCC',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanCRT', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
elsif in_source = 'EDI' then
   rc := zba.calc_accessorial_charges('ODCE',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanEDI', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
elsif in_source = 'WEB' then
   rc := zba.calc_accessorial_charges('ODCW',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanWEB', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
else
    zms.log_msg('OrderCancel', in_facility, oh.custid,
        'Bad Source: '||in_source, 'W', in_userid, out_msg);
end if;

if oh.workorderseq is not null then
   update plate
      set status = 'A',
          lasttask = 'CN',
          lastoperator = in_userid,
          lastuser = in_userid,
          lastupdate = sysdate
      where workorderseq = oh.workorderseq
        and status = 'K';
end if;
log_ack('A','Order Cancelled');
out_msg := 'OKAY';

exception when others then
  out_msg := substr(sqlerrm,1,80);
end cancel_order;

PROCEDURE remove_order_from_hold
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,in_manual_removal IN varchar2 DEFAULT 'N'
) is

cursor curOrderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         ordertype,
         custid,
         shipto,
         comment1,
         source,
         carrier,
         shiptype,
         nvl(parentorderid,0) as parentorderid,
         reference,
         prono,
         po,
         importfileid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
     
cursor curCust is
  select include_ack_release_errors_yn
   from  customer_aux
  where custid = (select custid 
                   from orderhdr 
                  where orderid = in_orderid
                    and shipid = in_shipid);
oh curOrderhdr%rowtype;
strMsg varchar2(255);
rc integer;
thecarrier varchar2(4);
theShipType orderhdr.shiptype%type;
currShipType orderhdr.shiptype%type;
theDelivServ orderhdr.deliveryservice%type;
cntRows integer;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
str_dup_reference_ynw customer.dup_reference_ynw%type;
cntDups integer;
cu curCust%rowtype;

cursor C_CA(in_custid varchar2)
IS
select auto_assign_inbound_load
  from customer_aux
 where custid = in_custid;

CA C_CA%rowtype;
l_loadno loads.loadno%type;
l_stopno loadstop.stopno%type;
l_shipno loadstopship.shipno%type;

errmsg varchar2(255);

procedure log_ack(in_status varchar2, in_comment varchar2) is
strmsg varchar2(255);
begin
  if nvl(cu.include_ack_release_errors_yn,'N') = 'Y' and 
     oh.source = 'EDI' then
      zimportprocs.log_order_import_ack(oh.importfileid, oh.custid, oh.po, oh.reference,
             in_orderid, in_shipid, in_status, strmsg, null);
 end if;
end;

begin
out_msg := '';
out_errorno := 0;
out_warning := 0;

open curCust;
fetch curCust into cu;
close curCust;
open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  out_errorno := 1;
  log_ack('E',out_msg);
  return;
else
  currShipType := oh.shiptype;
end if;

close curOrderhdr;

if oh.orderstatus != '0' then
  out_msg := 'Invalid order status: ' || oh.orderstatus;
  out_errorno := 2;
  log_ack('E',out_msg);
  return;
end if;

if (oh.ordertype not in ('R','Q','W','K','P','A','C','I')) and
   (oh.carrier is null) then
    thecarrier := zoe.get_pref_carrier(in_orderid,in_shipid,theShipType,theDelivServ);
    if currShipType is not null then
      update orderhdr
         set carrier = thecarrier,
             lastuser = in_userid,
             lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid;
    else
      update orderhdr
        set carrier = thecarrier,
            shiptype = theShipType,
            deliveryservice = theDelivServ,
            lastuser = in_userid,
            lastupdate = sysdate
      where orderid = in_orderid
        and shipid = in_shipid;
    end if;
end if;

zoe.validate_order(in_orderid,in_shipid,in_userid,out_warning,
  out_errorno,out_msg);
if out_errorno != 0 then
  log_ack('E',out_msg);
  return;
end if;

if (oh.ordertype not in ('R','Q','W','K','P','A','C','I')) then
  begin
    select count(1)
      into cntRows
      from orderdtl od
     where od.orderid = in_orderid
       and od.shipid = in_shipid
       and nvl(qtyOrder,0) >= 0;
  exception when others then
    cntRows := 1;
  end;
  if cntRows = 0 then
    begin
      select count(1)
        into cntRows
        from orderdtl od
       where od.orderid = in_orderid
         and od.shipid = in_shipid
         and nvl(qtyOrder,0) < 0;
    exception when others then
      cntRows := 0;
    end;
    if cntRows <> 0 then
      zoe.cancel_order_request(in_orderid,in_shipid,
        in_facility,'EDI',in_userid,out_msg);
      out_errorno := 199;
      out_msg := 'OKAY--outbound order cancelled (all negative line item qtys)';
      return;
    end if;
  end if;
end if;

begin
  select nvl(dup_reference_ynw,'N') into str_dup_reference_ynw
     from customer
     where custid = oh.custid;
exception when others then
   str_dup_reference_ynw := 'N';
end;

if in_manual_removal = 'Y' then
   if str_dup_reference_ynw = 'H' then
      select count(1) into cntDups
         from orderhdr
         where reference = oh.reference
                and custid = oh.custid
                and orderstatus <> 'X';
      if cntDups > 1 then
         out_errorno := -3;
         out_msg := 'Dup Reference--order not released from hold';
         commit;
         return;
      end if;
   end if;
end if;

update orderhdr
   set orderstatus = '1',
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

zlb.compute_order_labor(in_orderid,in_shipid,in_facility,in_userid,
  out_errorno,out_msg);
if out_errorno != 0 then
  zms.log_msg('LABORCALC', in_facility, oh.custid,
    out_msg, 'W', in_userid, strMsg);
  out_errorno := 0;
end if;

rc := 0;
if (oh.source = 'CRT') and (not check_for_billing_charges(in_orderid, in_shipid, in_facility, zbill.IT_MISC, 'ODAC')) then
   rc := zba.calc_accessorial_charges('ODAC',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdRelCRT', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
elsif (oh.source = 'EDI') and (not check_for_billing_charges(in_orderid, in_shipid, in_facility, zbill.IT_MISC, 'ODAE')) then
   rc := zba.calc_accessorial_charges('ODAE',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdRelEDI', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
elsif (oh.source = 'WEB') and (not check_for_billing_charges(in_orderid, in_shipid, in_facility, zbill.IT_MISC, 'ODAW')) then
   rc := zba.calc_accessorial_charges('ODAW',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdRelWeb', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
else
    zms.log_msg('OrderRelease', in_facility, oh.custid,
        'Bad SourceL'||oh.source, 'W', in_userid, out_msg);
end if;

if (oh.ordertype = 'C') and (oh.source = 'CRT') and (oh.parentorderid = 0) then
   zxdk.build_xdock_outbound(in_orderid, in_shipid, null, in_userid, l_orderid,
         l_shipid, out_msg);
   if out_msg != 'OKAY' then
      zms.log_msg('CROSSDOCK', in_facility, oh.custid, out_msg, 'E',
            in_userid, strMsg);
      out_errorno := 132;
      return;
   end if;
end if;

if oh.ordertype = 'O' then
   estimate_order_values(in_orderid, in_shipid, oh.custid, in_userid,
         out_errorno, out_msg);
   if out_errorno != 0 then
      zms.log_msg('VALIDORDER', in_facility, oh.custid, out_msg, 'E', in_userid, strMsg);
      log_ack('E',out_msg);
      return;
   end if;
end if;

if oh.ordertype = 'R' and oh.source = 'EDI' then
    CA := null;
    OPEN C_CA(oh.custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

    if nvl(CA.auto_assign_inbound_load, 'N') = 'Y' then
        l_loadno := 0;
        l_stopno := 0;
        l_shipno := 0;
        zld.assign_inbound_order_to_load(in_orderid, in_shipid, oh.carrier,
            null, null, null, null, null, in_facility, in_userid,
            l_loadno, l_stopno, l_shipno, errmsg);
        update loads
           set prono = oh.prono
         where loadno = l_loadno;

    end if;
end if;

out_msg := 'OKAY--order released from hold';

exception when others then
  out_msg := substr(sqlerrm,1,255);
  out_errorno := sqlcode;
end remove_order_from_hold;

PROCEDURE place_order_on_hold
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) is

  ORD orderhdr%rowtype;
begin

  out_msg := '';
  out_errorno := 0;
  
  begin
    select *
    into ORD
    from orderhdr
    where orderid = in_orderid and shipid = in_shipid;
  exception
    when others then
      out_errorno := 1;
      out_msg := 'Order could not be found';
      return;
  end;
  
  if ORD.orderstatus <> '1' then
    out_errorno := 1;
    out_msg := 'Order is not in entered status';
    return;
  end if;
  
  if ORD.ordertype = 'C' then
    out_errorno := 1;
    out_msg := 'Order does not have a valid ordertype to put back on hold';
    return;
  end if;
  
  update orderhdr
  set orderstatus = '0'
  where orderid = in_orderid and shipid = in_shipid;

  out_msg := 'OKAY--order placed on hold';
  
exception when others then
  out_msg := substr(sqlerrm,1,255);
  out_errorno := sqlcode;
end place_order_on_hold;

PROCEDURE validate_line
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) is

cursor curOrderHDr is
  select ordertype,
         custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select rowid,orderdtl.*
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

cursor curCustItemView(in_custid varchar2, in_item varchar2) is
  select variancepct,
         variancepct_overage,
         use_min_units_qty,
         min_units_qty,
         use_multiple_units_qty,
         multiple_units_qty,
         iskit,
         unkitted_class,
         use_catch_weights,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtytype,
         allowsub,
         backorder,
         useramt1,
         baseuom,
		 pct_sale_billing,
		 min_pct_im_value,
		 orderdtl_dollar_amt_pt
    from custitemview
   where custid = in_custid
     and item = in_item;
civ curCustItemView%rowtype;

cntRows integer;
cntError integer;
cntWarning integer;
cntEntered integer;
strItem orderdtl.item%type;
strLotRequired custitem.lotrequired%type;
strHazardous custitem.hazardous%type;
strIsKit custitem.IsKit%type;
strUOMBase orderdtl.uom%type;
qtyBase orderdtl.qtyorder%type;
Order_by_weight boolean;
strPick_by_Line_Number_yn customer.pick_by_line_number_yn%type;

numErrorno integer;
strMsg varchar2(255);
l_allow_overpicking customer_aux.allow_overpicking%type;
l_allow_lineitem_weights customer_aux.allow_lineitem_weights%type;
l_nmfc_count pls_integer;
l_upd_orderdtl_when_validating customer_aux.upd_orderdtl_when_validating%type;
l_orderdtl_sales_value orderdtl.dtlpassthrunum01%type;

procedure item_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' ' ||
    in_item || '/' || nvl(rtrim(in_lotnumber),'(no lot)') || ': ' ||
    out_msg;
  zms.log_msg('VALIDORDER', in_facility, od.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin

out_msg := '';
out_errorno := 0;
out_warning := 0;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  close curOrderDtl;
  out_msg := 'Line not found';
  out_errorno := 1;
  item_msg('E');
  out_msg := 'Line not found';
  return;
end if;
close curOrderDtl;

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  out_msg := 'Header not found';
  out_errorno := 1;
  item_msg('E');
  return;
end if;
close curOrderHdr;

if oh.ordertype = 'F' then
  strLotRequired := 'Y';
  strHazardous := 'N';
  strIsKit := 'N';
  select count(1)
    into l_nmfc_count
    from nmfclasscodes
   where nmfc = od.itementered;
  if l_nmfc_count = 0 then
    out_msg := 'Invalid NMFC code';
    out_errorno := 105;
    item_msg('E');
    return;
  end if;
else
  zci.get_customer_item(oh.custid,od.itementered,strItem,
    strLotRequired,strHazardous,strIsKit,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    out_msg := 'Invalid item code';
    out_errorno := 105;
    item_msg('E');
    return;
  end if;
end if;

begin
  select CU.pick_by_line_number_yn, nvl(CX.allow_overpicking,'N'),
         nvl(CX.allow_lineitem_weights,'N')
    into strpick_by_line_number_yn, l_allow_overpicking,
         l_allow_lineitem_weights
    from customer CU, customer_aux CX
   where CU.custid = oh.Custid
     and CX.custid = CU.custid;
exception when others then
  strpick_by_line_number_yn := 'N';
  l_allow_overpicking := 'N';
  l_allow_lineitem_weights := 'N';
end;

if ( ((oh.ordertype in ('R','Q','P','A','C','I','F')) and (strLotRequired in ('Y','O','S'))) or
     (strLotRequired = 'O') ) then
  if rtrim(od.lotnumber) is null then
    out_errorno := 106;
    out_msg := 'A Lot Number is required';
    item_msg('E');
    out_msg := 'A Lot Number is required';
    return;
  end if;
else
  if (rtrim(od.lotnumber) is not null) and
     (strLotRequired <> 'S') then
    out_errorno := 107;
    out_msg := 'No Lot Number can be specified';
    item_msg('E');
    return;
  end if;
end if;

cntEntered := 0;

if nvl(od.qtyentered,0) != 0 then
  cntEntered := cntEntered + 1;
end if;
if nvl(od.weight_entered_lbs,0) != 0 then
  cntEntered := cntEntered + 1;
end if;
if nvl(od.weight_entered_kgs,0) != 0 then
  cntEntered := cntEntered + 1;
end if;

if nvl(substr(zci.default_value('ACCEPTZEROQTYORDER'),1,1),'N') = 'N' then
  if cntEntered = 0 then
    out_errorno := 141;
    out_msg := 'A Quantity, Lbs. or Kgs. value must be entered';
    item_msg('E');
    return;
  end if;
end if;

civ := null;
open curCustItemView(oh.custid,strItem);
fetch curCustItemView into civ;
close curCustItemView;
begin 
  select nvl(upd_orderdtl_when_validating,'N')
    into l_upd_orderdtl_when_validating
    from customer_aux
   where custid = oh.custid;
exception when others then 
 l_upd_orderdtl_when_validating := 'N';
end;
if l_upd_orderdtl_when_validating = 'Y' then
  if nvl(rtrim(od.uomentered),civ.baseuom) != civ.baseuom then
    zoe.get_base_uom_equivalent(oh.custid,od.itementered,od.uomentered,
      od.qtyentered,strItem,strUOMBase,qtyBase,out_msg);
  else
    qtyBase := od.qtyentered;
  end if;    

  if not oh.ordertype in ('R','Q','W','K','P','A','C','I','F') then
  UPDATE orderdtl 
     SET uomentered     = nvl(rtrim(uomentered),civ.baseuom),
         uom            = civ.baseuom,
         qtyorder       = qtyBase,
         weightorder    = zci.item_weight(oh.custid,od.item,civ.baseuom) * qtyBase,
         cubeorder      = zci.item_cube(oh.custid,od.item,civ.baseuom) * qtyBase,
         amtorder       = qtyBase * civ.useramt1,
         backorder      = nvl(rtrim(backorder),civ.backorder),
         allowsub       = nvl(rtrim(allowsub),civ.allowsub),
         qtytype        = nvl(rtrim(qtytype),civ.qtytype),
         invstatusind   = nvl(rtrim(invstatusind),civ.invstatusind),
         invstatus      = nvl(rtrim(invstatus),civ.invstatus),
         invclassind    = nvl(rtrim(invclassind),civ.invclassind),
         inventoryclass = nvl(rtrim(inventoryclass),civ.inventoryclass)
   where rowid = od.rowid;
  else
    UPDATE orderdtl 
       SET uomentered     = nvl(rtrim(uomentered),civ.baseuom),
           uom            = civ.baseuom,
           qtyorder       = qtyBase,
           weightorder    = zci.item_weight(oh.custid,od.item,civ.baseuom) * qtyBase,
           cubeorder      = zci.item_cube(oh.custid,od.item,civ.baseuom) * qtyBase,
           amtorder       = qtyBase * civ.useramt1
     where rowid = od.rowid;
  end if;
  
  open curOrderDtl;
  fetch curOrderDtl into od;
  close curOrderDtl;
end if;
if oh.ordertype = 'R' and nvl(civ.use_catch_weights,'N') = 'Y'
and l_allow_lineitem_weights = 'Y' then
  if nvl(od.qtyentered,0) = 0 and nvl(substr(zci.default_value('ACCEPTZEROQTYORDER'),1,1),'N') = 'N' then
    out_errorno := 205;
    out_msg := 'A Quantity must be entered';
    item_msg('E');
    return;
  end if;

  if cntEntered = 3 then
    out_errorno := 206;
    out_msg := 'Only one received weight may be entered (Lbs. or Kgs.)';
    item_msg('E');
    return;
  end if;

  Order_by_Weight := False;
else
  if (cntEntered > 1) and
     (oh.ordertype != 'F') then
    out_errorno := 140;
    out_msg := 'Only one ordered value may be entered (Quantity, Lbs. or Kgs.)';
    item_msg('E');
    return;
  end if;

  if nvl(od.qtyentered,0) = 0 and nvl(substr(zci.default_value('ACCEPTZEROQTYORDER'),1,1),'N') = 'N' then
    Order_by_Weight := True;
  else
    Order_by_Weight := False;
  end if;
end if;

if (Order_by_Weight) and
   (oh.ordertype != 'O') then
  out_errorno := 145;
  out_msg := 'Ordering by weight is not supported for this order type';
  item_msg('E');
  return;
end if;

if (Order_by_Weight) and
   (strIsKit <> 'N') then
  out_errorno := 146;
  out_msg := 'Ordering by weight is not supported for kit items';
  item_msg('E');
  return;
end if;

if (Order_by_Weight) and
   (strpick_by_line_number_yn <> 'N') then
  out_errorno := 147;
  out_msg := 'Ordering by weight is not supported for picking by line number';
  item_msg('E');
  return;
end if;

if (oh.ordertype != 'F') then
  zoe.get_base_uom_equivalent(oh.custid,od.itementered,od.uomentered,
    od.qtyentered,strItem,strUOMBase,qtyBase,out_msg);
  if not (Order_by_Weight) then
    if substr(out_msg,1,4) != 'OKAY' then
      if out_msg = 'This customer item is not active' then
        out_errorno := 116;
      else
        out_errorno := 108;
        out_msg := 'Cannot translate uom';
      end if;
      item_msg('E');
      return;
    end if;
  end if;

  if od.item != strItem then
    out_errorno := 109;
    out_msg := 'Item/Alias mismatch';
    item_msg('E');
    return;
  end if;

  if strUOMBase != od.UOM then
    out_errorno := 110;
    out_msg := 'UOM equivalent mismatch';
    item_msg('E');
    return;
  end if;

  if qtyBase != od.qtyorder then
    out_errorno := 111;
    out_msg := 'Quantity equivalent mismatch';
    item_msg('E');
    return;
  end if;
else
  strItem := od.itementered;
  strUOMBase := od.uomentered;
  qtyBase := od.qtyorder;
end if;

if od.qtytype = 'A' then
  if od.variancepct_use_default = 'N' then
    civ.variancepct := nvl(od.variancepct,0);
    civ.variancepct_overage := nvl(od.variancepct_overage,0);
  else
    civ := null;
    open curCustItemView(oh.custid,strItem);
    fetch curCustItemView into civ;
    close curCustItemView;
  end if;
  if civ.variancepct < 0 then
    out_errorno := 140;
    out_msg := 'The minimum range percentage value must be zero or greater';
    return;
  end if;
  if civ.variancepct > 100 then
    out_errorno := 141;
    out_msg := 'The minimum range percentage value cannot exceed 100';
    return;
  end if;
  if civ.variancepct_overage < 100 then
    out_errorno := 142;
    out_msg := 'The maximum range percentage value must be 100 or greater';
    return;
  end if;
  if civ.variancepct_overage > 1000 then
    out_errorno := 143;
    out_msg := 'The maximum range percentage value must be less than 1000';
    return;
  end if;
end if;

if not oh.ordertype in ('R','Q','W','K','P','A','C','I','F') then
  select count(1)
    into cntrows
    from orderquantitytypes
   where code = od.qtytype;
  if cntrows = 0 then
    out_errorno := 112;
    out_msg := 'Invalid Order Quantity Type';
    item_msg('E');
    return;
  end if;
  select count(1)
    into cntrows
    from backorderpolicy
   where code = od.backorder;
  if cntrows = 0 then
    out_errorno := 113;
    out_msg := 'Invalid Back Order Policy';
    item_msg('E');
    return;
  end if;
  if (nvl(od.invstatusind,'x') not in ('I','E')) or
     (rtrim(od.invstatus) is null) then
    out_errorno := 114;
    out_msg := 'Invalid inventory status indicator';
    item_msg('E');
    return;
  end if;
  if (nvl(od.invclassind,'x') not in ('I','E')) or
     (rtrim(od.inventoryclass) is null) then
    out_errorno := 115;
    out_msg := 'Invalid inventory class indicator';
    item_msg('E');
    return;
  end if;
  if (Order_By_Weight) and
     (od.qtytype not in ('A')) then
    out_errorno := 145;
    out_msg := 'Invalid quantity type for order by weight item';
    item_msg('E');
    return;
  end if;
  if (not Order_By_Weight) and (l_allow_overpicking = 'N')
  and (od.qtytype not in ('E')) then
    out_errorno := 145;
    out_msg := 'Invalid quantity type for order by units item';
    item_msg('E');
    return;
  end if;
end if;

if oh.ordertype = 'O' then
  civ := null;
  open curCustItemView(oh.custid,strItem);
  fetch curCustItemView into civ;
  close curCustItemView;
  if (civ.Use_Multiple_Units_Qty = 'Y') and
     (not Order_By_Weight) and
     (mod(od.qtyorder, civ.Multiple_Units_Qty) != 0) then
    out_errorno := 195;
    out_msg := 'Order quantity must be a multiple of ' || civ.Multiple_Units_Qty ||
               ' base units';
    item_msg('E');
    return;
  end if;
  if (civ.Use_Min_Units_Qty = 'Y') and
     (not Order_By_Weight) and
     (od.qtyorder < civ.Min_Units_Qty) then
    out_errorno := 196;
    out_msg := 'A minimum of ' || civ.Min_Units_Qty || ' must be ordered';
    item_msg('E');
    return;
  end if;
end if;

if (strIsKit = 'I') and
   (nvl(od.inventoryclass,'x') <> civ.unkitted_class) then -- kit-by-class item
  zwo.validate_ordered_kit_by_class(in_orderid,in_shipid,od.item,od.lotnumber,
    oh.custid,od.invclassind,od.inventoryclass,numErrorno,strMsg);
  if numErrorno <> 0 then
    out_errorno := 197;
    out_msg := strMsg;
    item_msg('E');
    return;
  end if;
  zwo.validate_kit(oh.custid,od.item,od.inventoryclass,numErrorNo,strMsg);
  if numErrorNo <> 0 then
    out_errorno := 198;
    out_msg := 'Kit-by-Class for ' || od.item || '/' || od.inventoryclass ||
               ' has validation errors';
    item_msg('E');
    return;
  end if;
end if;


  
if (nvl(civ.pct_sale_billing,'N') = 'Y' and oh.ordertype = 'O')
then

  begin
    execute immediate 'select ' || civ.orderdtl_dollar_amt_pt || '
                       from orderdtl
                       where orderid = :in_orderid and shipid = :in_shipid and item = :in_item and nvl(lotnumber,''(none)'') = nvl(:in_lotnumber,''(none)'')' 
    into l_orderdtl_sales_value using in_orderid, in_shipid, in_item, in_lotnumber;
  exception
    when others then
      out_errorno := sqlcode * -1;
      out_msg := sqlerrm;
      item_msg('E');
      return;
  end;

	if (l_orderdtl_sales_value is null)
	then
		out_errorno := 2000;
		out_msg := 'Customer using % of sales billing, but sales value in not populated for ' || od.item;
		item_msg('E');
		return;
	end if;
	
	if (nvl(civ.useramt1,0) = 0)
	then
		out_errorno := 2001;
		out_msg := 'Customer using % of sales billing, but item value not populated in item master for ' || od.item;
		item_msg('E');
		return;
	end if;
	
	if (nvl(l_orderdtl_sales_value,0) < nvl(civ.useramt1,0) * (nvl(civ.min_pct_im_value,0)/100))
	then
		--out_errorno := 2002;
    out_warning := out_warning + 1;
		out_msg := 'Customer using % of sales billing, but value on orderdtl is below threshold for ' || od.item;
		item_msg('W');
		--return;
	end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zoevl ' || substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end validate_line;

PROCEDURE validate_order
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_warning IN OUT number
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
) is

cursor curOrderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         ordertype,
         custid,
         shipto,
         consignee,
         carrier,
         fromfacility,
         tofacility,
         shipterms,
         shiptype,
         shiptoname,
         shiptoaddr1,
         shiptocity,
         shiptostate,
         shiptopostalcode,
         billtoname,
         billtoaddr1,
         billtocity,
         billtostate,
         billtopostalcode,
         deliveryservice,
         saturdaydelivery,
         cod,
         amtcod,
         specialservice1,
         specialservice2,
         specialservice3,
         specialservice4,
         source,
         nvl(parentorderid,0) as parentorderid,
         reference,
         po,
         importfileid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderDtl is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item,lotnumber;

cursor curCustomer(in_custid varchar2) is
  select status,
         credithold,
         resubmitorder,
         pick_by_line_number_yn,
         nvl(bbb_routing_yn, 'N') as bbb_routing_yn,
         outconfirmbatchmap
    from customer C, customer_aux A
   where C.custid = rtrim(in_custid)
     and C.custid = A.custid(+);
cu curCustomer%rowtype;

cursor curConsignee(in_consignee varchar2) is
  select consigneestatus,
         shipto,
         billto
    from consignee
   where consignee = in_consignee;
co curConsignee%rowtype;

cursor curCarrier(in_carrier varchar2) is
  select carrierstatus,
         carriertype,
         multiship
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;

cursor curCarrierServiceCodes(in_carrier varchar2,
  in_deliveryservice varchar2) is
  select servicecode
    from carrierservicecodes
   where carrier = in_carrier
     and servicecode = in_deliveryservice;
csc curCarrierServiceCodes%rowtype;

cursor curCarrierSpecialService(in_carrier varchar2,
  in_deliveryservice varchar2, in_specialservice varchar2) is
  select specialservice
    from carrierspecialservice
   where carrier = in_carrier
     and servicecode = in_deliveryservice
     and specialservice = in_specialservice;
css curCarrierSpecialService%rowtype;

cntRows integer;
cntError integer;
cntWarning integer;
strFacility orderhdr.fromfacility%type;
cntOrderDtl integer;
cust_errorno number(4);
cust_errormsg varchar2(36);
errorcode number(4);
strURSACheck varchar2(10);
thecarrier varchar(4);
theshiptype orderhdr.shiptype%type;
theDelivServ orderhdr.deliveryservice%type;
errmsg varchar2(200);
l_cnt pls_integer;
l_qty orderdtlline.qty%type;

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
strStatus char(1);
begin
  if (errorcode != 0) then
    zimp.translate_cust_errorcode
    (oh.custid, errorcode, out_msg, cust_errorno, cust_errormsg);
    update orderhdr
       set rejectcode = cust_errorno,
           rejecttext = cust_errormsg,
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;
    if cu.resubmitorder = 'Y' then
      update orderhdr
         set orderstatus = 'X',
             lastuser = in_userid,
             lastupdate = sysdate
       where orderid = in_orderid
         and shipid = in_shipid
         and orderstatus != 'X';
    end if;
    errorcode := 0;
  end if;
  out_msg := 'Order ' || in_orderid || '-' || in_shipid || ': ' || out_msg;
  zms.log_msg('VALIDORDER', nvl(oh.fromfacility,oh.tofacility), oh.custid,
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin

out_msg := '';
out_errorno := 0;
out_warning := 0;
errorcode := 0;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderhdr;
  out_msg := 'Order Not found';
  out_errorno := 1;
  order_msg('E');
  return;
end if;
close curOrderhdr;

select count(1)
  into cntRows
  from ordertypes
 where code = oh.ordertype;
if cntRows = 0 then
  errorcode := 100;
  out_errorno := 2;
  out_msg := 'Invalid Order Type: ' || oh.ordertype;
  order_msg('E');
  return;
end if;

open curCustomer(oh.custid);
fetch curCustomer into cu;
if curCustomer%notfound then
  close curCustomer;
  out_errorno := 2;
  out_msg := 'Invalid Customer Number';
  order_msg('E');
  return;
end if;
close curCustomer;

if cu.status != 'ACTV' then
  cntWarning := cntWarning + 1;
  out_msg := 'Customer status is not active';
  order_msg('W');
end if;

if cu.credithold in ('W','Y') then
  cntWarning := cntWarning + 1;
  out_msg := 'Customer is on credit hold';
  order_msg('W');
end if;

if oh.ordertype not in ('R','Q','W','K','P','A','C','I') then -- outbound validation
  if oh.shipto is null then
    if (cu.bbb_routing_yn != 'N') and
       (zbbb.is_a_bbb_order(oh.custid,in_orderid,in_shipid) = 'Y') then
      errorcode := 290;
      out_errorno := out_errorno + 1;
      out_msg := 'A Ship To Consignee is required (BBB Routing)';
      order_msg('E');
      return;
    end if;
    if oh.shiptoname is null then
      errorcode := 200;
      out_errorno := out_errorno + 1;
      out_msg := 'Ship To Name is required';
      order_msg('E');
    end if;
    if oh.shiptoaddr1 is null then
      errorcode := 201;
      out_errorno := out_errorno + 1;
      out_msg := 'Ship To Address is required';
      order_msg('E');
    end if;
    if oh.shiptocity is null then
      errorcode := 202;
      out_errorno := out_errorno + 1;
      out_msg := 'Ship To City is required';
      order_msg('E');
    end if;
    if oh.shiptostate is null then
      errorcode := 203;
      out_errorno := out_errorno + 1;
      out_msg := 'Ship To State is required';
      order_msg('E');
    end if;
    if oh.shiptopostalcode is null then
      errorcode := 204;
      out_errorno := out_errorno + 1;
      out_msg := 'Ship To Postal Code is required';
      order_msg('E');
    end if;
  else
    open curConsignee(oh.shipto);
    fetch curConsignee into co;
    if curConsignee%notfound then
      out_errorno := out_errorno + 1;
      out_msg := 'Invalid Ship To Consignee';
      order_msg('E');
    else
      if co.consigneestatus != 'A' then
        if (cu.bbb_routing_yn != 'N') and
           (zbbb.is_a_bbb_order(oh.custid,in_orderid,in_shipid) = 'Y') then
          errorcode := 291;
          out_errorno := out_errorno + 1;
          out_msg := 'Ship To Consignee is not active (BBB routing)';
          order_msg('E');
          return;
        else
          out_warning := out_warning + 1;
          out_msg := 'Ship To Consignee is not active';
          order_msg('W');
        end if;
      end if;
      if co.shipto <> 'Y' then
        out_warning := out_warning + 1;
        out_msg := 'Ship To Consignee is not classified as a ship to location';
        order_msg('W');
      end if;
      select count(1)
        into cntRows
        from custconsignee
       where custid = oh.custid
         and consignee = oh.shipto;
      if cntRows = 0 then
        out_warning := out_warning + 1;
        out_msg := 'Ship To Consignee is not associated with customer';
        order_msg('W');
      end if;
    end if;
    close curConsignee;
  end if;
  select count(1)
    into cntRows
    from shipmentterms
   where code = oh.shipterms;
  if cntRows = 0 then
    errorcode := 101;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid shipment terms';
    order_msg('E');
    return;
  end if;
  select count(1)
    into cntRows
    from shipmenttypes
   where code = oh.shiptype;
  if cntRows = 0 then
    errorcode := 121;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid shipment type';
    order_msg('E');
    return;
  end if;
  if oh.shipterms = '3RD' then
    if oh.consignee is null then
      if oh.billtoname is null then
        errorcode := 300;
        out_errorno := out_errorno + 1;
        out_msg := 'Bill To Name is required';
        order_msg('E');
      end if;
      if oh.billtoaddr1 is null then
        errorcode := 301;
        out_errorno := out_errorno + 1;
        out_msg := 'Bill To Address is required';
        order_msg('E');
      end if;
      if oh.billtocity is null then
        errorcode := 302;
        out_errorno := out_errorno + 1;
        out_msg := 'Bill To City is required';
        order_msg('E');
      end if;
      if oh.billtostate is null then
        errorcode := 303;
        out_errorno := out_errorno + 1;
        out_msg := 'Bill To State is required';
        order_msg('E');
      end if;
      if oh.billtopostalcode is null then
        errorcode := 304;
        out_errorno := out_errorno + 1;
        out_msg := 'Bill To Postal Code is required';
        order_msg('E');
      end if;
    else
      open curConsignee(oh.consignee);
      fetch curConsignee into co;
      if curConsignee%notfound then
        out_errorno := out_errorno + 1;
        out_msg := 'Invalid Bill To Consignee';
        order_msg('E');
      else
        if co.consigneestatus != 'A' then
          out_warning := out_warning + 1;
          out_msg := 'Bill To Consignee is not active';
          order_msg('W');
        end if;
        if co.billto <> 'Y' then
          out_warning := out_warning + 1;
          out_msg := 'Bill To Consignee is not classified as a freight billing location';
          order_msg('W');
        end if;
        select count(1)
          into cntRows
          from custconsignee
         where custid = oh.custid
           and consignee = oh.consignee;
        if cntRows = 0 then
          out_warning := out_warning + 1;
          out_msg := 'Bill To Consignee is not associated with customer';
          order_msg('W');
        end if;
      end if;
      close curConsignee;
    end if;
  end if;

  thecarrier := zoe.get_pref_carrier(in_orderid,in_shipid,theShipType,theDelivServ);
  if (thecarrier is not null) and
     (oh.carrier <> thecarrier) then
   out_warning := out_warning + 1;
        out_msg := 'Preferred carrier not selected. Use ' || thecarrier || '.';
        order_msg('W');
  end if;

  if ( (oh.shiptype in ('S','L','T')) and
       (theShipType <> '*') ) then
    if oh.shiptype <> theShiptype then
      out_warning := out_warning + 1;
      out_msg := 'Shipment Type not in weight range. Use ' || theshiptype || '.';
      order_msg('W');
    end if;
  end if;

end if;

if (oh.shiptype <> 'P') and
   (oh.ordertype in ('O','V','T','U') ) then
  ca := null;
  open curCarrier(oh.carrier);
  fetch curCarrier into ca;
  close curCarrier;
  if ca.carrierstatus is null then
    errorcode := 102;
    out_errorno := out_errorno + 1;
    if oh.carrier is null then
      out_msg := 'Carrier entry is required';
    else
      out_msg := 'Invalid carrier: ' || oh.carrier;
    end if;
    order_msg('E');
  else
    if ca.carrierstatus <> 'A' then
      out_warning := out_warning + 1;
      out_msg := 'Carrier is not active: '  || oh.carrier;
      order_msg('W');
    end if;
    if oh.deliveryservice is not null then
      csc := null;
      open curCarrierServiceCodes(oh.carrier,oh.deliveryservice);
      fetch curCarrierServiceCodes into csc;
      close curCarrierServiceCodes;
      if csc.servicecode is null then
        errorcode := 117;
        out_errorno := out_errorno + 1;
        out_msg := 'Invalid delivery service: ' || oh.deliveryservice;
        order_msg('E');
      end if;
    else
      if (ca.carriertype = 'S') or
         (ca.multiship = 'Y') then
        errorcode := 120;
        out_errorno := out_errorno + 1;
        out_msg := 'A delivery service is required';
        order_msg('E');
      end if;
    end if;
    if (ca.multiship = 'Y') then
      begin
        select substr(zci.default_value('URSAVALIDATION'),1,10)
          into strURSACheck
          from dual;
      exception when others then
        strURSACheck := 'N';
      end;
      if (strURSACheck = 'ON') and
         (oh.Shipto is null) then


         zur.check_order_address(in_orderid, in_shipid, in_userid, errmsg );
         if errmsg != 'OKAY' then
           errorcode := 119;
           out_errorno := out_errorno + 1;
           out_msg := 'URSA Error:'|| errmsg;
           order_msg('E');
         end if;

/*
        cntRows := 0;
        select count(1)
          into cntRows
          from ursa
         where zipcode = substr(oh.shiptopostalcode,1,5)
           and state = oh.shiptostate
           and instr(upper(cityprefixes), substr(upper(oh.shiptocity),1,1)) <> 0;
        if cntRows = 0 then
          errorcode := 119;
          out_errorno := out_errorno + 1;
          out_msg := 'URSA Validation Error: ' || oh.shiptostate ||
           ' ' || oh.shiptopostalcode || ' ' || oh.shiptocity;
          order_msg('E');
        end if;
*/
      end if;
    end if;
  end if;
end if;

if nvl(oh.saturdaydelivery,'N') not in ('Y','N') then
  errorcode := 118;
  out_errorno := out_errorno + 1;
  out_msg := 'Invalid Saturday Delivery Indicator: ' || oh.saturdaydelivery;
  order_msg('E');
end if;

if nvl(oh.cod,'N') not in ('Y','N') then
  errorcode := 130;
  out_errorno := out_errorno + 1;
  out_msg := 'Invalid COD Indicator: ' || oh.cod;
  order_msg('E');
end if;

if (oh.cod = 'Y') and (oh.amtcod = 0) then
  errorcode := 139;
  out_errorno := out_errorno + 1;
  out_msg := 'COD Amount is Missing ';
  order_msg('E');
end if;

if oh.specialservice1 is not null then
  css := null;
  open curCarrierSpecialService(oh.carrier,oh.deliveryservice,
    oh.specialservice1);
  fetch curCarrierSpecialService into css;
  close curCarrierSpecialService;
  if css.specialservice is null then
    errorcode := 131;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid Special Service (1): ' || oh.specialservice1;
    order_msg('E');
  end if;
end if;

if oh.specialservice2 is not null then
  css := null;
  open curCarrierSpecialService(oh.carrier,oh.deliveryservice,
    oh.specialservice2);
  fetch curCarrierSpecialService into css;
  close curCarrierSpecialService;
  if css.specialservice is null then
    errorcode := 131;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid Special Service (2): ' || oh.specialservice2;
    order_msg('E');
  end if;
end if;

if oh.specialservice3 is not null then
  css := null;
  open curCarrierSpecialService(oh.carrier,oh.deliveryservice,
    oh.specialservice3);
  fetch curCarrierSpecialService into css;
  close curCarrierSpecialService;
  if css.specialservice is null then
    errorcode := 131;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid Special Service (3): ' || oh.specialservice3;
    order_msg('E');
  end if;
end if;

if oh.specialservice4 is not null then
  css := null;
  open curCarrierSpecialService(oh.carrier,oh.deliveryservice,
    oh.specialservice4);
  fetch curCarrierSpecialService into css;
  close curCarrierSpecialService;
  if css.specialservice is null then
    errorcode := 131;
    out_errorno := out_errorno + 1;
    out_msg := 'Invalid Special Service (4): ' || oh.specialservice4;
    order_msg('E');
  end if;
end if;

cntOrderDtl := 0;
for od in curOrderDtl
loop
  cntOrderDtl := cntOrderDtl + 1;
  if oh.ordertype in ('R','Q','P','A','C','I') then
    strFacility := oh.tofacility;
  else
    strFacility := oh.fromfacility;
  end if;
  zoe.validate_line(in_orderid,in_shipid,od.item,od.lotnumber,strFacility,
    in_userid,cntWarning,cntError,out_msg);
  if cntError > 0 then
    out_msg := od.item || '/' || nvl(od.lotnumber,'(no lot)') || out_msg;
    errorcode := cntError;
    out_errorno := out_errorno + 1;
    order_msg('E');
  else
    out_warning := out_warning + cntWarning;
  end if;
end loop;

if (cntOrderDtl = 0) and
   (oh.ordertype not in ('R','Q','P','A','C','I')) then
  errorcode := 103;
  out_errorno := out_errorno + 1;
  out_msg := 'No detail lines';
  order_msg('E');
end if;

if (oh.ordertype = 'C') and (oh.source = 'CRT') and (oh.parentorderid = 0) then
   select count(1) into l_cnt
      from orderdtlline
      where orderid = in_orderid
        and shipid = in_shipid
        and nvl(xdock,'N') != 'N';
   if l_cnt = 0 then
      if (oh.shipto is null) and (oh.shiptoname is null) then
         errorcode := 132;
         out_errorno := out_errorno + 1;
         out_msg := 'Order has no Crossdock Ship To and no Crossdock Detail';
         order_msg('E');
      end if;
   else
      if (oh.shipto is not null) or (oh.shiptoname is not null) then
         errorcode := 132;
         out_errorno := out_errorno + 1;
         out_msg := 'Order has both Crossdock Ship To and Crossdock Detail';
         order_msg('E');
      else
         for odl in (select item, lotnumber, qtyorder
                     from orderdtl
                     where orderid = in_orderid
                       and shipid = in_shipid) loop

            select nvl(sum(qty),0) into l_qty
               from orderdtlline
               where orderid = in_orderid
                 and shipid = in_shipid
                 and item = odl.item
                 and nvl(lotnumber, '(none)') = nvl(odl.lotnumber, '(none)')
                 and nvl(xdock,'N') != 'N';

            if odl.qtyorder != l_qty then
               errorcode := 132;
               out_errorno := out_errorno + 1;
               out_msg := 'Item ' || odl.item || ' quantity mismatch.  Item quantity is '
                     || odl.qtyorder || ' Crossdock total is ' || l_qty;
               order_msg('E');
            end if;
         end loop;
      end if;
   end if;
end if;

if cu.pick_by_line_number_yn = 'Y' then
  cntOrderDtl := 0;
  select count(1)
    into cntOrderDtl
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and zwt.is_ordered_by_weight(orderid,shipid,item,lotnumber) = 'Y';
  if cntOrderDtl <> 0 then
    errorcode := 133;
    out_errorno := out_errorno + 1;
    out_msg := 'Pick by Line Number Customers cannot order by weight';
    order_msg('E');
  end if;
end if;

if out_errorno = 0 then
  out_msg := 'OKAY';
else
  out_msg := 'Not released--Errors found: ' || out_errorno;
end if;

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end validate_order;

FUNCTION orderstatus_abbrev
(in_orderstatus IN varchar2
) return varchar2 is

out orderstatus%rowtype;

begin

select abbrev
  into out.abbrev
  from orderstatus
 where code = in_orderstatus;

return out.abbrev;

exception when others then
  return in_orderstatus;
end orderstatus_abbrev;

FUNCTION commitstatus_abbrev
(in_commitstatus IN varchar2
) return varchar2 is

out commitstatus%rowtype;

begin

select abbrev
  into out.abbrev
  from commitstatus
 where code = in_commitstatus;

return out.abbrev;

exception when others then
  return in_commitstatus;
end commitstatus_abbrev;

FUNCTION shiptype_abbrev
(in_shiptype IN varchar2
) return varchar2 is

out shipmenttypes%rowtype;

begin

select abbrev
  into out.abbrev
  from shipmenttypes
 where code = in_shiptype;

return out.abbrev;

exception when others then
  return in_shiptype;
end shiptype_abbrev;

FUNCTION shipterms_abbrev
(in_shipterms IN varchar2
) return varchar2 is

out shipmentterms%rowtype;

begin

select abbrev
  into out.abbrev
  from shipmentterms
 where code = in_shipterms;

return out.abbrev;

exception when others then
  return in_shipterms;
end shipterms_abbrev;

FUNCTION line_count
(in_orderid IN number
,in_shipid IN number
) return number is

cntRows integer;
begin

select count(1)
  into cntRows
  from orderdtl
 where orderid = in_orderid
   and shipid = in_shipid
   and linestatus != 'X';

return cntRows;

exception when others then
  return 0;
end line_count;

procedure check_for_export_procs
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curCust(in_custid varchar2) is
  select outRejectBatchMap,
         outConfirmBatchMap,
         outStatusBatchMap,
         outShipSumBatchMap
    from customer
   where custid = in_custid;
cs curCust%rowtype;

cursor curCustAux(in_custid varchar2) is
  select overwrite_importfileid_yn
    from customer_aux
   where custid = in_custid;
csaux curCustAux%rowtype;

curCompany integer;
cntRows integer;
cmdSql varchar2(2000);
tblCompany varchar2(12);
tblWarehouse varchar2(12);

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg('EXPCHK', 'ALL', rtrim(in_custid),
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';

open curCust(in_custid);
fetch curCust into cs;
if curCust%notfound then
  close curCust;
  out_msg := 'Invalid customer code: ' || in_custid;
  out_errorno := -1;
  return;
end if;
close curCust;

open curCustAux(in_custid);
fetch curCustAux into csaux;
if curCustAux%notfound then
  close curCustAux;
  out_msg := 'Invalid customer code: ' || in_custid;
  out_errorno := -1;
  return;
end if;
close curCustAux;

if cs.outConfirmBatchMap is not null then
  cntRows := 0;
  begin
    if nvl(csaux.overwrite_importfileid_yn,'N') = 'N' then
      select count(1)
        into cntRows
        from orderhdr
       where importfileid = upper(in_importfileid)
         and ordertype in ('O','V', 'R');
     else -- overwrite import file
    select 1
      into cntRows
      from dual;
    end if;
  exception when others then
    cntRows := 0;
  end;
  if cntRows <> 0 then
    ziem.impexp_request('E',null,in_custid,
      cs.OutConfirmBatchMap,upper(in_importfileid),'NOW',
      0,0,0,in_userid,null,null,'importfileid',null,null,
      null,null,out_errorno,out_msg);
    if out_errorno != 0 then
      order_msg('E');
    end if;
  end if;
end if;

/*
if cs.outRejectBatchMap is not null then
  ziem.impexp_request('E',null,in_custid,
    cs.OutRejectBatchMap,upper(in_importfileid),'NOW',
    0,0,0,in_userid,null,null,'importfileid',null,null,
    null,null,out_errorno,out_msg);
  if out_errorno != 0 then
    order_msg('E');
  end if;
end if;
*/

if cs.OutStatusBatchMap is not null then
  cmdSql := 'select distinct class_to_company_' || rtrim(in_custid) ||
    '.abbrev, class_to_warehouse_' || rtrim(in_custid) || '.abbrev from ' ||
    ' class_to_company_' || rtrim(in_custid) || ',class_to_warehouse_' ||
    rtrim(in_custid) ||
    ' where class_to_company_' || rtrim(in_custid) || '.code = class_to_warehouse_' ||
    rtrim(in_custid) || '.code and class_to_company_' || rtrim(in_custid) ||
    '.code = ''RG''';
  begin
    curCompany := dbms_sql.open_cursor;
    dbms_sql.parse(curCompany, cmdSql, dbms_sql.native);
    dbms_sql.define_column(curCompany,1,tblCompany,12);
    dbms_sql.define_column(curCompany,2,tblWarehouse,12);
    cntRows := dbms_sql.execute(curCompany);
    while(1=1)
    loop
      cntRows := dbms_sql.fetch_rows(curCompany);
      if cntRows <= 0 then
        Exit;
      end if;
      dbms_sql.column_value(curCompany,1,tblCompany);
      dbms_sql.column_value(curCompany,2,tblWarehouse);
      ziem.impexp_request('E',null,in_custid,
        cs.OutStatusBatchMap,null,'NOW',
        0,0,0,in_userid,null,null,null,
        tblCompany,tblWarehouse,
        null,null,out_errorno,out_msg);
      if out_errorno != 0 then
        order_msg('E');
      end if;
    end loop;
    dbms_sql.close_cursor(curCompany);
  exception when others then
    dbms_sql.close_cursor(curCompany);
  end;
end if;

/* no longer produced at end-of-import; just once a day
if cs.OutShipSumBatchMap is not null then
  ziem.impexp_request('E',null,in_custid,
    cs.OutShipSumBatchMap,null,'NOW',
    0,0,0,in_userid,'customer','lastshipsum',
    'dateshipped',null,null,null,out_errorno,out_msg);
  if out_errorno != 0 then
    order_msg('E');
  end if;
end if;
*/

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zoecfep ' || sqlerrm;
  out_errorno := sqlcode;
end check_for_export_procs;

FUNCTION line_number
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number is

cursor curOrderHdr is
  select ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select dtlpassthrunum10
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

cursor curOrderLines is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

out_line_number integer;

begin

out_line_number := 0;

open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.ordertype in ('R','Q','P','A','C','I') then
  for ol in curOrderLines
  loop
    out_line_number := out_line_number + 1;
    if (in_orderitem = ol.item) and
       (nvl(rtrim(in_orderlot),'(none)') = nvl(ol.lotnumber,'(none)')) then
      exit;
    end if;
  end loop;
else
  open curOrderDtl;
  fetch curOrderDtl into out_line_number;
  close curOrderDtl;
end if;

return out_line_number;

exception when others then
  return out_line_number;
end line_number;

FUNCTION commit_date
(dateshipped IN date
,satokay     IN varchar2
,plusdays    IN number
) return date
is

out_date date;

begin

out_date := dateshipped+plusdays;

if (upper(to_char(out_date,'dy')) = 'SUN') or
   ( (upper(to_char(out_date,'dy')) = 'SAT') and
     (upper(satokay) != 'Y') ) then
  out_date := next_day(out_date, 'Monday');
end if;

return out_date;

exception when others then
  return null;
end;

PROCEDURE cancel_order_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is
cursor curCustomer is
  select include_ack_cancel_orders_yn
    from customer_aux
   where custid = (select custid from orderhdr 
                       where orderid = in_orderid
                         and shipid = in_shipid);
cu curCustomer%rowtype;

cursor Corderhdr is
  select custid,
         reference,
         po
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

out_errorno integer;
l_type varchar2(6);

procedure log_ack(in_status varchar2, in_comment varchar2) is
 l_importfileid import_order_acknowledgment.importfileid%type;
 
begin
  if nvl(cu.include_ack_cancel_orders_yn,'N') = 'Y' and 
     in_source = 'EDI' then
    begin
        select cancel_importfileid
          into l_importfileid
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid
           and custid = oh.custid
           and nvl(po,'(none)') = nvl(oh.po,'(none)')
           and reference = oh.reference;
    exception when others then
        l_importfileid := null;
    end;
    zimportprocs.log_order_import_ack(l_importfileid, oh.custid, oh.po, oh.reference,
             in_orderid, in_shipid, in_status, in_comment, 'D');
 end if;
end;

begin

out_msg := '';

open curCustomer;
fetch curCustomer into cu;
close curCustomer;

open Corderhdr;
fetch Corderhdr into oh;
close Corderhdr;

l_type := 'CANORD';
if in_source = 'WEB' then
  l_type := 'CANORW';
elsif in_source = 'EDI' then
  l_type := 'CANORE';
end if;

if ztk.active_tasks_for_order(in_orderid,in_shipid) = true then
  out_msg := 'There are active tasks for this order';
  log_ack('E',out_msg);
  return;
end if;

zgp.pick_request(l_type,
  in_facility,in_userid,0,in_orderid,in_shipid,
  null,null,0,null,null,'N',
  out_errorno,out_msg);

  if out_msg != 'OKAY' then
    log_ack('E',out_msg);
  end if;
  
exception when others then
  out_msg := substr(sqlerrm,1,80);
end cancel_order_request;

FUNCTION line_number_str
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return varchar2 is

cursor curOrderHdr is
  select ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select dtlpassthrunum10
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

cursor curOrderLines is
  select item,
         lotnumber
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

out_line_number integer;
out_line_number_str varchar2(6);
cntChars integer;
begin

out_line_number := 0;
out_line_number_str := '000000';

open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.ordertype in ('R','Q','P','A','C','I') then
  for ol in curOrderLines
  loop
    out_line_number := out_line_number + 1;
    if (in_orderitem = ol.item) and
       (nvl(rtrim(in_orderlot),'(none)') = nvl(ol.lotnumber,'(none)')) then
      exit;
    end if;
  end loop;
else
  open curOrderDtl;
  fetch curOrderDtl into out_line_number;
  close curOrderDtl;
end if;

out_line_number_str := out_line_number;
out_line_number_str := rtrim(out_line_number_str);

while length(out_line_number_str) < 6
loop
  out_line_number_str := '0' || out_line_number_str;
end loop;

return out_line_number_str;

exception when others then
  return out_line_number_str;
end line_number_str;

PROCEDURE regenerate_picks
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
) is

out_errorno integer;

begin

zgp.pick_request('REGEN',in_facility,in_userid,0,in_orderid,in_shipid,
  in_item,in_lotnumber,0,null,null,'N',
  out_errorno,out_msg);
out_msg := nvl(out_msg,'OKAY');

exception when others then
  out_msg := substr(sqlerrm,1,80);
end regenerate_picks;

FUNCTION last_pick_label
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

cursor curMultiShipDtl is
  select cartonid
    from multishipdtl
   where orderid = in_orderid
     and shipid = in_shipid
   order by shipdatetime desc;

out_cartonid multishipdtl.cartonid%type;

begin

out_cartonid := '';

open curMultiShipDtl;
fetch curMultiShipDtl into out_cartonid;
close curMultiShipDtl;

return out_cartonid;

exception when others then
  return out_cartonid;
end last_pick_label;

FUNCTION order_reference
(in_orderid IN number
,in_shipid IN number
) return varchar2
is

outreference orderhdr.reference%type;

begin

outreference := '';

select reference
  into outreference
  from orderhdr
 where orderid = in_orderid
   and shipid = in_shipid;

return outreference;

exception when others then
  return null;
end order_reference;

FUNCTION outbound_trackingno
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
) return varchar2
is

outtrackingno shippingplate.trackingno%type;

begin

outtrackingno := '';

select max(trackingno)
  into outtrackingno
  from shippingplate
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x');

return outtrackingno;

exception when others then
  return null;
end outbound_trackingno;

FUNCTION inbound_condition
(in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_serialnumber varchar2
,in_useritem1 varchar2
,in_useritem2 varchar2
,in_useritem3 varchar2
) return varchar2
is

outcondition plate.condition%type;
outcondition2 plate.condition%type;

begin

outcondition := '';

select max(condition)
  into outcondition
  from plate
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x')
   and type = 'PA';

select max(condition)
  into outcondition2
  from deletedplate
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'x') = nvl(in_lotnumber,'x')
   and nvl(serialnumber,'x') = nvl(in_serialnumber,'x')
   and nvl(useritem1,'x') = nvl(in_useritem1,'x')
   and nvl(useritem2,'x') = nvl(in_useritem2,'x')
   and nvl(useritem3,'x') = nvl(in_useritem3,'x')
   and type = 'PA';

if nvl(outcondition2,' ') > nvl(outcondition,' ') then
  outcondition := outcondition2;
end if;

return outcondition;

exception when others then
  return null;
end inbound_condition;

procedure check_cancel_interface
(in_orderid IN NUMBER
,in_shipid IN NUMBER
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderHdr is
  select orderid,
         shipid,
         fromfacility,
         custid,
         orderstatus,
         importfileid,
         ordertype,
         tofacility
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCust(in_custid varchar2) is
  select outRejectBatchMap,
         PoMapFile,
         rcptnote_include_cancelled_yn,
         outAckBatchMap,
         shipnote_include_cancelled_yn
    from customer
   where custid = in_custid;
cs curCust%rowtype;

curCompany integer;
cntRows integer;
cmdSql varchar2(2000);
tblCompany varchar2(12);
tblWarehouse varchar2(12);

procedure order_msg(in_msgtype varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_msg('EXPCHK', 'ALL', rtrim(oh.custid),
    out_msg, nvl(in_msgtype,'E'), in_userid, strMsg);
end;

begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderstatus is null then
  out_msg := 'Invalid Order ID ' || in_orderid || '-' || in_shipid;
  out_errorno := -11;
  return;
end if;

if oh.orderstatus != 'X' then
  out_msg := 'Order not cancelled--no interface needed';
  out_errorno := 1;
  return;
end if;

open curCust(oh.custid);
fetch curCust into cs;
if curCust%notfound then
  close curCust;
  out_msg := 'Invalid customer code: ' || oh.custid;
  out_errorno := -1;
  return;
end if;
close curCust;

if cs.outRejectBatchMap is not null then
  ziem.impexp_request('E',null,oh.custid,
    cs.OutRejectBatchMap,null,'NOW',
    0,in_orderid,in_shipid,in_userid,null,null,'importfileid',null,null,
    null,null,out_errorno,out_msg);
  if out_errorno != 0 then
    order_msg('E');
  end if;
end if;

if (cs.shipnote_include_cancelled_yn = 'Y') and
   (oh.ordertype in ('O','V')) then
    zld.check_for_interface(0,
                        oh.orderid,
                        oh.shipid,
                        oh.fromfacility,
                        'REGORDTYPES',
                        'REGI44SNFMT',
                        'RETORDTYPES',
                        'RETI9GIFMT',
                        in_userid,
                        out_msg);
end if;

if (cs.PoMapFile is not null) and
   (cs.rcptnote_include_cancelled_yn = 'Y') and
   (oh.ordertype in ('R','Q','P','A','C','I')) then
    zld.check_for_interface(0,
                        oh.orderid,
                        oh.shipid,
                        oh.tofacility,
                        'REGORDTYPES',
                        'REGI44RNFMT',
                        'RETORDTYPES',
                        'RETI9GRFMT',
                        in_userid,
                        out_msg);
end if;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zoecfep ' || sqlerrm;
  out_errorno := sqlcode;
end check_cancel_interface;



FUNCTION get_pref_carrier
(in_orderid IN number
,in_shipid  IN number
,out_shiptype OUT varchar2
,out_delivcode OUT varchar2
) return varchar2
is

cursor orderinfo(in_orderid number, in_shipid number) is
   select OH.shiptype, OH.shipto, OH.custid,
          decode(OH.shiptoname, null, CN.postalcode, OH.shiptopostalcode)
      from orderhdr OH, consignee CN
      where OH.orderid = in_orderid
        and OH.shipid = in_shipid
        and OH.shipto = CN.consignee(+);

cursor orderweight(in_orderid number,in_shipid number) is
   select sum(weightorder) from orderdtl where linestatus='A' and
      orderid = in_orderid and
      shipid   = in_shipid
     group by orderid,shipid;


cursor conscarrier(in_consignee varchar2, in_type varchar2, in_weight real, in_zip varchar2) is
   select carrier
      from consigneecarriers
      where consignee = in_consignee
        and shiptype = in_type
        and in_weight between fromweight and toweight
        and substr(in_zip, 1, 5) between nvl(begzip, '00000') and nvl(endzip, '99999');


cursor custcarrier(in_custid varchar2, in_type varchar2, in_weight real, in_zip varchar2) is
   select carrier
      from customercarriers
      where custid = in_custid
        and shiptype = in_type
        and in_weight between fromweight and toweight
        and substr(in_zip, 1, 5) between nvl(begzip, '00000') and nvl(endzip, '99999');

cursor custcarrier2(in_custid varchar2, in_weight real, in_zip varchar2) is
  select carrier, assigned_ship_type, servicecode
      from customercarriers
    where custid = in_custid
        and in_weight between fromweight and toweight
        and substr(in_zip, 1, 5) between nvl(begzip, '00000') and nvl(endzip, '99999');


theshiptype    varchar2(1);
thecustid      varchar2(10);
theconsignee   varchar2(10);
theweight   real;
thecarrier  varchar(4);
thezip varchar2(12);
intLtlPoundsHigh integer;
intLtlPoundsLow integer;

begin

-- get the weight

theweight := null;
open orderweight(in_orderid,in_shipid);
fetch orderweight into theweight;
close orderweight;

if theweight is null then
  theweight := 0;
end if;

-- get the ship type, consignee, custid and postalcode

open orderinfo(in_orderid,in_shipid);
fetch orderinfo into theshiptype,theconsignee,thecustid,thezip;
close orderinfo;

begin
  intLtlPoundsHigh :=
    nvl(to_number(substr(zci.default_value('LTLPOUNDSHIGH'),1,36)),0);
  intLtlPoundsLow :=
    nvl(to_number(substr(zci.default_value('LTLPOUNDSLOW'),1,36)),0);
  if (intLtlPoundsHigh = 0) or
     (intLtlPoundsLow = 0) then
    out_ShipType := '*' ;
  elsif theweight < intLtlPoundsLow then
    out_ShipType := 'S'; -- small package
  elsif theweight > intLtlPoundsHigh then
    out_Shiptype := 'T'; -- truckload
  else
    out_Shiptype := 'L'; -- LTL
  end if;
exception when others then
  out_ShipType := '?';
end;

-- look up the carrier based on conisingee

thecarrier := null;

open conscarrier(theconsignee,theshiptype,theweight,thezip);
fetch conscarrier into thecarrier;
close conscarrier;

-- if not found look up carrier based on custid
 if thecarrier is null then
   open custcarrier(thecustid,theshiptype,theweight,thezip);
   fetch custcarrier into thecarrier;
   close custcarrier;
 end if;

-- if not found look up carrier based on custid and assigned_ship_type
if thecarrier is null then
  open custcarrier2(thecustid,theweight,thezip);
  fetch custcarrier2 into thecarrier, out_Shiptype, out_delivcode;
  close custcarrier2;
end if;

-- return the preferred carrier
return thecarrier;

exception when others then
  return null;
end get_pref_carrier;

procedure usp_cancel_order
(
in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
, out_cancel_id out number
,out_msg   OUT varchar2
)is

cursor Corderhdr is
  select nvl(orderstatus,'?') as orderstatus,
         nvl(loadno,0) as loadno,
         nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility,
         nvl(fromfacility,' ') as fromfacility,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyrcvd,0) as qtyrcvd,
         nvl(qtyship,0) as qtyship,
         custid,
         confirmed,
         priority,
         rejectcode,
         rejecttext,
         edicancelpending,
         reference,
         nvl(wave,0) as wave,
         workorderseq
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curShippingPlate is
  select count(1) as count
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and status = 'SH';
sp curShippingPlate%rowtype;

cursor curCustomer(in_custid varchar2) is
  select nvl(resubmitorder,'N') as resubmitorder
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and facility = in_facility
     and not exists
       (select * from tasks
         where subtasks.taskid = tasks.taskid
           and tasks.priority = '0');

cntRows integer;
out_errorno integer;
rc integer;
strMsg varchar2(255);
maxCancelId NUMBER;

begin
out_cancel_id := 0;
out_msg := '';

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  return;
end if;
close Corderhdr;

if (oh.orderstatus > '8') and
   (oh.orderstatus != 'X') then
  out_msg := 'Invalid order status for cancel: ' ||
    in_orderid || '-' || in_shipid || ' Status: ' || oh.orderstatus;
  return;
end if;

open curCustomer(oh.custid);
fetch curCustomer into cu;
if curCustomer%notfound then
  cu.resubmitorder := 'N';
end if;
close curCustomer;

if oh.ordertype in ('T','U') then  -- branch or ownership transfer
  if (oh.tofacility != in_facility) and
     (oh.fromfacility != in_facility) then
    out_msg := 'Order not associated with your facility ' || oh.tofacility;
    return;
  end if;
elsif oh.ordertype in ('R','Q','P','A','C','I') then  -- inbound
  if oh.tofacility != in_facility then
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
  if oh.qtyrcvd != 0 then
    out_msg := 'Cannot cancel--receipts have been processed';
    return;
  end if;
else
  if oh.fromfacility != in_facility then -- outbound
    out_msg := 'Order not at your facility' || oh.tofacility;
    return;
  end if;
end if;

if ztk.active_tasks_for_order(in_orderid,in_shipid) = true then
  out_msg := 'There are active tasks for this order';
  return;
end if;

sp.count := 0;
open curShippingPlate;
fetch curShippingPlate into sp.count;
if curShippingPlate%notfound then
  sp.count := 0;
end if;
close curShippingPlate;
if sp.count != 0 then
  out_msg := 'Cannot cancel--order ' || in_orderid || '-' || in_shipid ||
   ' has ' ||  sp.count || ' shipped pallets';
  return;
end if;

for od in curOrderdtl
loop
  zwv.unrelease_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,od.qty
      ,oh.priority
      ,'X'  -- request type of cancel
      ,in_userid
      ,'N'  -- trace flag off
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('OrderCancel', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
  end if;
end loop;

if oh.rejectcode is null then
  oh.rejectcode := 400;
  begin
    select descr
      into oh.rejecttext
      from ordervalidationerrors
     where code = '400';
  exception when others then
    oh.rejecttext := 'Manual Cancellation';
  end;
  if (oh.ordertype in ('O')) and
     (oh.reference is not null) then
    oh.edicancelpending := 'Y';
  end if;
  oh.confirmed := null;
end if;

----------------------------------------------------
begin
  select max(nvl(cancel_id,0)) + 1 into maxCancelId
      from orderhdr ;
  exception when others then
    null;
end;

-----------------------------------------------------

update orderhdr
   set orderstatus = 'X',
       commitstatus = '0',
       rejectcode = oh.rejectcode,
       rejecttext = oh.rejecttext,
       edicancelpending = oh.edicancelpending,
       confirmed = oh.confirmed,
       lastuser = in_userid,
       cancel_id  = maxCancelId,
       cancel_user_id = in_userid,
       cancelled_date = sysdate,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

update orderdtl
   set linestatus = 'X',
       lastuser = in_userid,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

if oh.wave != 0 then
  begin
    select min(orderstatus)
      into oh.orderstatus
      from orderhdr
     where wave = oh.wave;
  exception when no_data_found then
    oh.orderstatus := '9';
  end;
  if oh.orderstatus > '8' then
    update waves
       set wavestatus = '4',
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave
       and wavestatus < '4';
  end if;
end if;

zmn.change_order(in_orderid,in_shipid,out_msg);

if oh.loadno != 0 then
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from shippingplate
     where orderid = in_orderid
       and shipid = in_shipid
       and status = 'L';
  exception when others then
    null;
  end;
  if cntRows = 0 then
    zld.deassign_order_from_load(in_orderid,in_shipid,in_facility,
      in_userid,'N',out_errorno,out_msg);
  end if;
end if;

cntRows := 0;
begin
  select count(1)
    into cntRows
    from subtasks
   where orderid = in_orderid
     and shipid = in_shipid;
exception when others then
  null;
end;

if (cntRows <> 0) and
   (oh.ordertype in ('V','T','U')) then
  for st in curOrderTasks
  loop
    ztk.subtask_no_pick(st.rowid, st.facility, st.custid, st.taskid, st.lpid,
      in_userid, 'Y', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('DeleteTask', st.facility, st.custid,
         out_msg, 'E', in_userid, strMsg);
    end if;
  end loop;
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from subtasks
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    null;
  end;
end if;

if cntRows = 0 then
  begin
    select count(1)
      into cntRows
      from batchtasks
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when others then
    null;
  end;
  if cntRows = 0 then
    delete from commitments
     where orderid = in_orderid
       and shipid = in_shipid;
    delete from orderlabor
     where orderid = in_orderid
       and shipid = in_shipid;
    delete from itemdemand
     where orderid = in_orderid
       and shipid = in_shipid;
  end if;
end if;

if in_source = 'CRT' then
   rc := zba.calc_accessorial_charges('ODCC',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanCRT', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
elsif in_source = 'EDI' then
   rc := zba.calc_accessorial_charges('ODCE',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanEDI', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
elsif in_source = 'WEB' then
   rc := zba.calc_accessorial_charges('ODCW',in_facility,null,
          in_orderid, in_shipid, in_userid, out_msg);
   if rc != zbill.GOOD then
    zms.log_msg('OrdCanWEB', in_facility, oh.custid,
        out_msg, 'W', in_userid, out_msg);
   end if;
   process_cancelled_charges(in_orderid, in_shipid, in_userid);
else
    zms.log_msg('OrderCancel', in_facility, oh.custid,
        'Bad SourceL'||in_source, 'W', in_userid, out_msg);
end if;

if oh.workorderseq is not null then
   update plate
      set status = 'A',
          lasttask = 'CN',
          lastoperator = in_userid,
          lastuser = in_userid,
          lastupdate = sysdate
      where workorderseq = oh.workorderseq
        and status = 'K';
end if;

out_cancel_id := maxCancelId;
out_msg := 'OKAY';

exception when others then
  out_cancel_id := 0;
  out_msg := substr(sqlerrm,1,80);

end usp_cancel_order;

PROCEDURE usp_cancel_order_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_source IN varchar2
,in_userid IN varchar2
,out_cancel_id out varchar2
,out_msg  OUT varchar2
) is

maxCancelId varchar2(15);
out_errorno integer;
l_type varchar2(6);

begin

maxCancelId :=0;
out_msg := '';

l_type := 'CANORD';
if in_source = 'WEB' then
  l_type := 'CANORW';
elsif in_source = 'EDI' then
  l_type := 'CANORE';
end if;

if ztk.active_tasks_for_order(in_orderid,in_shipid) = true then
  out_msg := 'There are active tasks for this order';
  return;
end if;

zgp.pick_request(l_type,
  in_facility,in_userid,0,in_orderid,in_shipid,
  null,null,0,null,null,'N',
  out_errorno,out_msg);

if out_msg = 'OKAY' then
  begin
   select to_char(sysdate,'MMDDYYYY')||alps.cancelledid.nextval into maxCancelId
         from dual ;
    exception when others then
      null;
  end;
  update orderhdr
   set lastuser = in_userid,
       cancel_id  = maxCancelId,
       cancel_user_id = in_userid,
       cancelled_date = sysdate,
       lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;

end if;

out_cancel_id := maxCancelId;

exception when others then
  out_cancel_id := 0;
  out_msg := substr(sqlerrm,1,80);

end usp_cancel_order_request;


FUNCTION line_qtyorder
(in_orderid IN number
,in_shipid  IN number
,in_orderitem IN varchar2
,in_orderlot IN varchar2
) return number is

cursor curOrderDtl is
  select qtyorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

out_qtyorder orderdtl.qtyorder%type;

begin

out_qtyorder := 0;

open curOrderDtl;
fetch curOrderdtl
 into out_qtyorder;
close curOrderDtl;

return out_qtyorder;

exception when others then
  return 0;
end line_qtyorder;


FUNCTION order_trackingnos
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

out_trackingnos varchar2(2000);

begin

out_trackingnos := '';

for cord in (select distinct trackingno
               from shippingplate
              where orderid = in_orderid
                and shipid = in_shipid
                and trackingno is not null)
loop

    exit when length(out_trackingnos) + length(cord.trackingno)> 1999;

    out_trackingnos := out_trackingnos ||','||cord.trackingno;
end loop;

return substr(out_trackingnos,2);

exception when others then
  return out_trackingnos;
end order_trackingnos;

FUNCTION order_trackingnos -- overload
(in_orderid IN number
,in_shipid  IN number
,in_seperator IN varchar2
) return varchar2 is

out_trackingnos varchar2(2000);

begin

out_trackingnos := '';

for cord in (select distinct trackingno
               from shippingplate
              where orderid = in_orderid
                and shipid = in_shipid
                and trackingno is not null)
loop

    exit when length(out_trackingnos) + length(cord.trackingno)> 1999;

    out_trackingnos := out_trackingnos ||nvl(in_seperator,',')||cord.trackingno;
end loop;

return substr(out_trackingnos,2);

exception when others then
  return out_trackingnos;
end order_trackingnos;


FUNCTION dtl_trackingnos
(in_orderid IN number
,in_shipid  IN number
,in_item    IN varchar2
) return varchar2 is

out_trackingnos varchar2(2000);

begin

out_trackingnos := '';

for cord in (select distinct trackingno
               from shippingplate
              where orderid = in_orderid
                and shipid = in_shipid
           and item = in_item
                and trackingno is not null)
loop

    exit when length(out_trackingnos) + length(cord.trackingno)> 1999;

    out_trackingnos := out_trackingnos ||','||cord.trackingno;
end loop;

return substr(out_trackingnos,2);

exception when others then
  return out_trackingnos;
end dtl_trackingnos;


PROCEDURE regenerate_order
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is
   cursor c_od(p_orderid number, p_shipid number) is
      select item, lotnumber, qtyorderdiff
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and nvl(qtyorderdiff,0) != 0;
   cursor c_shp (p_orderid number, p_shipid number) is
      select nvl(C.multiship, 'N') multiship, O.shiptype
         from orderhdr O, loads L, carrier C
         where O.orderid = p_orderid
           and O.shipid = p_shipid
           and L.loadno (+) = O.loadno
           and C.carrier = nvl(L.carrier, O.carrier);
   cursor c_oh (p_orderid number, p_shipid number) is
      select custid, loadno
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   shp c_shp%rowtype;
   oh c_oh%rowtype;
   l_any_negs boolean := false;
   rc integer;
   errmsg varchar2(255);
begin

   oh := null;
   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;


   for od in c_od(in_orderid, in_shipid) loop
      update tasks
         set priority = '9',
             prevpriority = priority
         where taskid in (select taskid from subtasks
                           where orderid = in_orderid
                             and shipid = in_shipid
                             and orderitem = od.item
                             and nvl(orderlot,'(none)') = nvl(od.lotnumber,'(none)'))
           and priority in ('1','2','3','4');

      if od.qtyorderdiff < 0 then
         l_any_negs := true;
      end if;

      rc := zba.calc_accessorial_charges('EDAP',in_facility,oh.loadno,
          in_orderid, in_shipid, in_userid, errmsg);
      if rc != zbill.GOOD then
         zms.log_msg('RegenOrd', in_facility, oh.custid,
            out_msg, 'W', in_userid, errmsg);
      end if;

   end loop;

   if l_any_negs then
      open c_shp(in_orderid, in_shipid);
      fetch c_shp into shp;
      close c_shp;

      if (shp.multiship = 'Y') and (shp.shiptype = 'S') then
         delete multishipdtl
            where orderid = in_orderid
              and shipid = in_shipid;

         update orderhdr
            set ignore_multiship = 'Y'
            where orderid = in_orderid
              and shipid = in_shipid;
      end if;
   end if;

   commit;

   for od in c_od(in_orderid, in_shipid) loop
      regenerate_picks(in_orderid, in_shipid, od.item, od.lotnumber, in_facility,
            in_userid, out_msg);
      if substr(out_msg, 1, 4) != 'OKAY' then
         return;
      end if;
   end loop;

   out_msg := 'OKAY';

exception when others then
   out_msg := substr(sqlerrm,1,80);
end regenerate_order;

FUNCTION expected_seal_value
(in_orderid IN number
,in_shipid  IN number
) return varchar2 is

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select seal_passthrufield
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cmdSql varchar2(1000);
out_ExpectedSealValue varchar2(255);

begin

out_ExpectedSealValue := null;

oh := null;
open curOrderHdr(in_orderid, in_shipid);
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  return null;
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;
if trim(cu.seal_passthrufield) is null then
  return null;
end if;

execute immediate
  'select to_char(' || cu.seal_passthrufield || ') ' ||
    ' from orderhdr where orderid = ' ||
    in_orderid || ' and shipid = ' || in_shipid
    into out_ExpectedSealValue;

return out_ExpectedSealValue;

exception when others then
  return out_ExpectedSealValue;
end expected_seal_value;

PROCEDURE seal_override_request
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_msg  IN OUT varchar2
)
is

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select custid,nvl(seal_verified,'N') as seal_verified
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select seal_passthrufield
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

strExpectedSealValue varchar2(255);
strMsg varchar2(255);

begin

out_msg := 'NONE';

oh := null;
open curOrderHdr(in_orderid,in_shipid);
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_msg := 'Invalid order number ' || in_orderid || '-' || in_shipid;
  return;
end if;

if oh.seal_verified = 'Y' then
  out_msg := 'The seal value has already been verified.';
  return;
end if;

strExpectedSealValue := substr(rtrim(zoe.expected_seal_value(in_orderid, in_shipid)),1,255);
if rtrim(strExpectedSealValue) is null then
  cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;
  out_msg := 'Seal number verification is required for this receipt.' || CHR(13) ||
             'An expected seal value has not been entered in the ' || CHR(13) ||
             cu.seal_passthrufield || ' field.';
  return;
end if;

update orderhdr
   set seal_verification_attempts = 0,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

strMsg := 'Seal verification override--attempt count reset to zero.';

zoh.add_orderhistory(in_orderid, in_shipid, 'Seal Override',
                     strMsg, in_userid, out_msg);

exception when others then
  out_msg := substr(sqlerrm,1,80);
end seal_override_request;

PROCEDURE seal_verification_attempt
(in_orderid IN number
,in_shipid IN number
,in_seal IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
)
is

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select custid,
         ordertype,
         nvl(seal_verified,'N') as seal_verified,
         nvl(seal_verification_attempts,0) as seal_verification_attempts
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

strExpectedSealValue varchar2(255);
strMsg varchar2(255);

begin

out_errorno := 0;
out_msg := 'NONE';

oh := null;
open curOrderHdr(in_orderid,in_shipid);
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  out_errorno := -1;
  out_msg := 'Invalid order';
  return;
end if;

if oh.ordertype != 'R' then
  out_errorno := -2;
  out_msg := 'Not a receipt order';
end if;

if oh.seal_verified = 'Y' then
  out_errorno := -3;
  out_msg := 'Already verified';
  return;
end if;

if oh.seal_verification_attempts >= 3 then
  out_errorno := -4;
  out_msg := 'Seal Override Needed';
  return;
end if;

strExpectedSealValue := substr(rtrim(zoe.expected_seal_value(in_orderid, in_shipid)),1,255);
if rtrim(strExpectedSealValue) is null then
  out_errorno := -5;
  out_msg := 'No seal on order';
  return;
end if;

if rtrim(in_seal) is null then
  out_errorno := -6;
  out_msg := 'Seal value required';
  return;
end if;

if rtrim(strExpectedSealValue) = rtrim(in_seal) then
  strMsg := 'PASS ';
  update orderhdr
     set seal_verification_attempts = nvl(seal_verification_attempts,0) + 1,
         seal_verified = 'Y',
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
else
  strMsg := 'FAIL ';
  update orderhdr
     set seal_verification_attempts = nvl(seal_verification_attempts,0) + 1,
         lastuser = in_userid,
         lastupdate = sysdate
   where orderid = in_orderid
     and shipid = in_shipid;
end if;

strMsg := strMsg || 'Expected: ' || rtrim(strExpectedSealValue) ||
          ' Scanned: ' || rtrim(in_seal);

zoh.add_orderhistory(in_orderid, in_shipid, 'Seal Verification',
                     strMsg, in_userid, out_msg);

if rtrim(strExpectedSealValue) = rtrim(in_seal) then
  out_errorno := 1;
  out_msg := 'Seal verify PASSED';
else
  if oh.seal_verification_attempts >= 2 then
    out_errorno := 3;
  else
    out_errorno := 2;
  end if;
  out_msg := 'Seal verify FAILED';
end if;

exception when others then
  out_msg := substr(sqlerrm,1,80);
end seal_verification_attempt;

function is_seal_verified
(in_orderid IN number
,in_shipid IN number
) return varchar2

is

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select custid,nvl(seal_verified,'N') as seal_verified,
         ordertype
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select require_seal_verification
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

begin

oh := null;
open curOrderHdr(in_orderid,in_shipid);
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.custid is null then
  return 'Y';
end if;

if oh.ordertype != 'R' then
  return 'Y';
end if;

if oh.seal_verified = 'Y' then
  return 'Y';
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;
if cu.require_seal_verification = 'Y' then
  return 'N';
else
  return 'Y';
end if;

exception when others then
  return 'N';
end is_seal_verified;

function get_min_days_to_expiration
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
) return number

is

cursor curOrderHdr is
  select custid, shipto
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid varchar2) is
  select nvl(enter_min_days_to_expire_yn,'N') enter_min_days_to_expire_yn
    from customer_aux
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curCustItemConsignee(in_custid varchar2, in_shipto varchar2) is
  select nvl(min_days_to_expiration,0) min_days_to_expiration
    from custitemconsignee
   where custid = in_custid
     and item = in_item
     and consignee = in_shipto;
cic curCustItemConsignee%rowtype;

cursor curCustItem(in_custid varchar2) is
  select nvl(shelflife,0) shelflife
    from custitem
   where custid = in_custid
     and item = in_item;
ci curCustItem%rowtype;

begin

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.shipto is null then
  return 0;
end if;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;
if cu.enter_min_days_to_expire_yn != 'Y' then
  return 0;
end if;

cic := null;
open curCustItemConsignee(oh.custid,oh.shipto);
fetch curCustItemConsignee into cic;
close curCustItemConsignee;

if nvl(cic.min_days_to_expiration,0) != 0 then
  return cic.min_days_to_expiration;
end if;

ci := null;
open curCustItem(oh.custid);
fetch curCustItem into ci;
close curCustItem;

-- return nvl(ci.shelflife,0);
return 0;

exception when others then
  return 0;
end get_min_days_to_expiration;

function consumable_entry_required
(in_custid IN varchar2
,in_ordertype IN varchar2
) return varchar2
is
cursor curCustomer(in_custid varchar2) is
  select custid,consumable_required
    from customer_aux
   where custid = in_custid;
cu curCustomer%rowtype;
begin
cu := null;
open curCustomer(in_custid);
fetch curCustomer into cu;
close curCustomer;
if cu.custid is null then
  return 'N';
end if;
if cu.consumable_required = 'N' then
  return 'N';
end if;
if in_ordertype = 'O' and
   cu.consumable_required in ('O','B') then
  return 'Y';
end if;
if in_ordertype = 'R' and
   cu.consumable_required in ('I','B') then
  return 'Y';
end if;
return 'N';
exception when others then
  return 'N';
end consumable_entry_required;
procedure release_orders_from_hold
(in_included_rowids IN clob
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
,out_warning_count IN OUT number
,out_error_count IN OUT number
,out_release_count IN OUT number
)
is

type cur_type is ref cursor;
l_cur cur_type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_custid customer.custid%type;
l_sql varchar2(4000);
l_errorno pls_integer;
l_warning pls_integer;
l_msg varchar2(255);
l_userid userheader.nameid%type;
l_ordertype orderhdr.ordertype%type;
i pls_integer;
l_loop_count pls_integer;
l_rowid_length pls_integer := 18;
l_log_msg appmsgs.msgtext%type;
l_wavetemplate customer.wavetemplate%type;

begin

out_errorno := 0;
out_msg := 'OKAY';
out_warning_count := 0;
out_error_count := 0;
out_release_count := 0;

l_loop_count := length(in_included_rowids) - length(replace(in_included_rowids, ',', ''));

i := 1;
while (i <= l_loop_count)
loop

  l_sql := 'select orderid, shipid, custid, ordertype ' ||
           'from orderhdr ' ||
           'where rowid in (';

  while length(l_sql) < 3975 -- 4000 character limit for open cursor command
  loop
    l_sql := l_sql || '''' || substr(in_included_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_sql) < 3975) then
      l_sql := l_sql || ',';
    else
      exit;
    end if;
  end loop;

  l_sql := l_sql || ')';

  open l_cur for l_sql;
  loop

    fetch l_cur into l_orderid, l_shipid, l_custid, l_ordertype;
    exit when l_cur%notfound;

    zoe.remove_order_from_hold(
      l_orderid,
      l_shipid,
      in_facility,
      in_userid,
      l_warning,
      l_errorno,
      l_msg,
      'Y');
    if l_errorno >= 0 then
      commit;
      if l_errorno > 0 then
        out_error_count := out_error_count + 1;
      end if;
      if l_warning != 0 then
        out_warning_count := out_warning_count + 1;
      end if;
      if l_errorno = 0 then
        out_release_count := out_release_count + 1;
        if l_ordertype = 'O' then
          begin
            select wavetemplate
              into l_wavetemplate
              from customer
             where custid = l_custid;
          exception when others then
            l_wavetemplate := null;
          end;
          if l_wavetemplate is not null then
            zgp.pick_request('COMORD','',in_userid,0,l_orderid,l_shipid,
              '','',0,'','','N',l_errorno,l_msg);
          end if;
        end if;
      end if;
    else
      rollback;
      out_error_count := out_error_count + 1;
    end if;

  end loop;

  close l_cur;

end loop;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end release_orders_from_hold;

function check_for_billing_charges
(in_orderid IN number
,in_shipid IN number
,in_facility IN varchar2
,in_invtype IN varchar2
,in_event IN varchar2
) return boolean
is
  v_custid customer.custid%type;
  v_rategroup customer.rategroup%type;
  v_count number;
begin

  select a.custid, rategroup
  into v_custid, v_rategroup
  from orderhdr a, customer b
  where a.custid = b.custid
    and a.orderid = in_orderid and a.shipid = in_shipid;
    
  select count(1)
  into v_count
  from invoicedtl
  where orderid = in_orderid and shipid = in_shipid
    and invtype = in_invtype
    and activity in (select w.activity
                      FROM custrategroup G, custactvfacilities F, custratewhen W
                      WHERE W.custid = zbut.rategroup(v_custid, v_rategroup).custid
                        AND W.rategroup = zbut.rategroup(v_custid, v_rategroup).rategroup
                        AND W.businessevent  = in_event
                        AND W.automatic in ('A','C')
                        AND G.custid = W.custid
                        AND G.rategroup = W.rategroup
                        AND G.status = 'ACTV'
                        AND W.custid = F.custid(+)
                        AND W.activity = F.activity(+)
                        AND 0 < instr(','||nvl(F.facilities,in_facility)||',', ','||in_facility||','));
                        
  if (v_count > 0) then
    return true;
  end if;
  
  return false;
    
exception
  when others then
    return false;
end check_for_billing_charges;

procedure update_ordered_values
(in_wave_plan_sql IN clob
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

type cur_type is ref cursor;
l_cur cur_type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_od orderdtl%rowtype;
l_sql varchar2(4000);

begin

out_errorno := 0;
out_msg := 'OKAY';

l_sql := 'select orderid,shipid ' ||
         substr(in_wave_plan_sql,instr(in_wave_plan_sql, 'from waveselectview'), 32767) ||
         ' and recompute_order_upon_wave_plan = ''Y''';

open l_cur for l_sql;
loop

  fetch l_cur into l_orderid, l_shipid;
  exit when l_cur%notfound;
  
  for od in (select rowid,custid,item,uom,lotnumber,
                    qtyorder,cubeorder,weightorder,amtorder,
                    nvl(qtycommit,0) qtycommit, nvl(cubecommit,0) cubecommit,nvl(weightcommit,0) weightcommit ,nvl(amtcommit,0) amtcommit,
                    nvl(qtytotcommit,0) qtytotcommit, nvl(cubetotcommit,0) cubetotcommit,nvl(weighttotcommit,0) weighttotcommit ,nvl(amttotcommit,0) amttotcommit
               from orderdtl
              where orderid = l_orderid
                and shipid = l_shipid)
  loop

    l_od.weightorder := zci.item_weight(od.custid,od.item,od.uom) * od.qtyorder;
    l_od.cubeorder := zci.item_cube(od.custid,od.item,od.uom) * od.qtyorder;
    l_od.amtorder := zci.item_amt(od.custid,l_orderid,l_shipid,od.item,od.lotnumber) * od.qtyorder;
    l_od.weightcommit := zci.item_weight(od.custid,od.item,od.uom) * od.qtycommit;
    l_od.cubecommit := zci.item_cube(od.custid,od.item,od.uom) * od.qtycommit;
    l_od.amtcommit := zci.item_amt(od.custid,l_orderid,l_shipid,od.item,od.lotnumber) * od.qtycommit;
    l_od.weighttotcommit := zci.item_weight(od.custid,od.item,od.uom) * od.qtytotcommit;
    l_od.cubetotcommit := zci.item_cube(od.custid,od.item,od.uom) * od.qtytotcommit;
    l_od.amttotcommit := zci.item_amt(od.custid,l_orderid,l_shipid,od.item,od.lotnumber) * od.qtytotcommit;

    if (l_od.weightorder != od.weightorder) or
       (l_od.cubeorder != od.cubeorder) or
       (l_od.amtorder != od.amtorder) or
       (l_od.weightcommit != od.weightcommit) or
       (l_od.cubecommit != od.cubecommit) or
       (l_od.amtcommit != od.amtcommit) or
       (l_od.weighttotcommit != od.weighttotcommit) or
       (l_od.cubetotcommit != od.cubetotcommit) or
       (l_od.amttotcommit != od.amttotcommit) then
      update orderdtl
         set weightorder = l_od.weightorder,
             cubeorder = l_od.cubeorder,
             amtorder = l_od.amtorder,
             weightcommit = l_od.weightcommit,
             cubecommit = l_od.cubecommit,
             amtcommit = l_od.amtcommit,
             weighttotcommit = l_od.weighttotcommit,
             cubetotcommit = l_od.cubetotcommit,
             amttotcommit = l_od.amttotcommit,
             lastuser = in_userid,
             lastupdate = sysdate
       where rowid = od.rowid;
    end if;
    
  end loop;

  commit;
  
end loop;

close l_cur;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
  if l_cur%isopen then
    close l_cur;
  end if;
end update_ordered_values;

FUNCTION total_cases
(in_orderid IN number
,in_shipid  IN number
) return number is

out_total_cases orderhdr.qtyorder%type;
l_cases_uom orderdtl.uom%type;
out_msg varchar2(255);
out_translate_qty number;

begin

out_total_cases := 0;

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
    out_total_cases := out_total_cases + nvl(od.qtyentered,0);
  elsif l_cases_uom = od.uom then
    out_total_cases := out_total_cases + nvl(od.qtyorder,0);
  else
    zbut.translate_uom(od.custid,od.item,od.qtyorder,od.uom,l_cases_uom,out_translate_qty,out_msg);
    if substr(out_msg,1,4) = 'OKAY' then
      out_total_cases := out_total_cases + nvl(out_translate_qty,0);
    end if;
  end if;  
end loop;

return out_total_cases;

exception when others then
  return out_total_cases;
end total_cases;

procedure check870
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,out_msg IN OUT varchar2
,out_map out varchar2
)
is
cmdSql varchar2(2000);
cursor curCustomer(in_custid varchar2) is
  select nvl(out870_generate,'N') out870_generate,
         nvl(out870_map, '(NONE)') as out870_map,
         nvl(out870_passthrufield, 'hdrpassthruchar01') as out870_passthrufield,
         nvl(out870_passthruvalue, '(none)') as out870_passthruvalue
    from customer_aux
   where custid = in_custid;
cu curCustomer%rowtype;
ohvalue varchar2(255);
begin
  out_msg := 'NOWAY';
  out_map := '(none)';
  cu := null;
  open curCustomer(in_custid);
  fetch curCustomer into cu;
  close curCustomer;
  if cu.out870_generate <> 'Y' then
     return;
  end if;
  cmdsql := 'select ' || cu.out870_passthruvalue || ' from orderhdr ' ||
             ' where orderid = ' || in_orderid || ' and shipid = ' || in_shipid;
  execute immediate cmdSql into ohvalue;
  if ohvalue <>  cu.out870_passthruvalue then
     return;
  end if;
  out_msg := 'OKAY';
  out_map := cu.out870_map;
exception when others then
   return;
end check870;
procedure request870
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_msg IN OUT varchar2
)
is
pMap varchar2(255);
errorno integer;
begin
  out_msg := 'NOWAY';
  zoe.check870(in_custid, in_orderid, in_shipid, out_msg, pMap);
  if out_msg <> 'OKAY' then
     return;
  end if;
  ziem.impexp_request('E',null,in_custid,pMap,null,'NOW',
    0,in_orderid,in_shipid,in_userid,null,null,null,null,null,
    null,null,errorno,out_msg);
  if errorno != 0 then
    out_msg := 'NOWAY';
  end if;
exception when others then
   return;
end request870;

procedure update_order_attach
(
  in_type in varchar2,
  in_data in varchar2,
  in_user in varchar2,
  in_filename in varchar2,
  out_msg in out varchar2
)
is
  v_count number;
begin
  out_msg := 'OKAY';
  
  if (upper(in_type) not in ('LOAD','ORDER')) then
    out_msg := 'Invalid data type';
    return;
  end if;
  
  if (in_data is null) then
    out_msg := 'Data is missing';
    return;
  end if;
  
  if (in_user is null) then
    out_msg := 'User is missing';
    return;
  end if;
  
  if (in_filename is null) then
    out_msg := 'Filename is missing';
    return;
  end if;
  
  if (upper(in_type) = 'LOAD') then
    select count(1) into v_count
    from orderhdr
    where loadno = in_data;
    
    if (v_count = 0) then 
      out_msg := 'No orders for load ' || in_data;
      return;
    end if;
  elsif (upper(in_type) = 'ORDER') then
    select count(1) into v_count
    from orderhdr
    where orderid = in_data;
    
    if (v_count = 0) then
      out_msg := 'Order ' || in_data || ' does not exist';
      return;
    end if;
  end if;
  
  insert into orderattach(orderid, filepath, lastuser, lastupdate)
  select orderid, in_filename, in_user, sysdate
  from orderhdr
  where (upper(in_type) = 'LOAD' and loadno = in_data)
    or (upper(in_type) = 'ORDER' and orderid = in_data);
  
exception
  when others then
    out_msg := 'Error attaching';
end update_order_attach;

end zorderentry;
/
show error package zorderentry;
show error package body zorderentry;
exit;
