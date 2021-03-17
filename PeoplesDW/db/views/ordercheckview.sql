create or replace function ordercheckview_lpid
   (shlpid   in varchar2,
    type     in varchar2,
    fromlpid in varchar2,
   parentlpid in varchar2)
return varchar2
is
--
-- $Id$
--
   cursor c_top (p_lpid varchar2) is
      select lpid
         from shippingplate
         where parentlpid is null
         start with lpid = p_lpid
         connect by prior parentlpid = lpid;
   top c_top%rowtype;
   cursor c_xp (p_lpid varchar2) is
      select lpid
         from plate
         where type = 'XP'
           and parentlpid = p_lpid;
   xp c_xp%rowtype;
   rowfound boolean;
begin

   if type = 'F' and parentlpid is null then
      return fromlpid;
   end if;

   open c_top(shlpid);
   fetch c_top into top;
   rowfound := c_top%found;
   close c_top;
   if rowfound then
      open c_xp(top.lpid);
      fetch c_xp into xp;
      rowfound := c_xp%found;
      close c_xp;
      if rowfound then
         return xp.lpid;
      end if;
   end if;

   return shlpid;

exception
   when OTHERS then
      return shlpid;
end ordercheckview_lpid;
/

create or replace function ordercheckview_cartons
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   out_cartons number;
   l_quantity number;
   l_shiptype varchar2(2);
begin
   select shiptype into l_shiptype from orderhdr where orderid = in_orderid and shipid = in_shipid;
   if l_shiptype = 'S' then
      select count(1) into out_cartons
        from shippingplate
       where orderid = in_orderid
         and shipid = in_shipid
         and parentlpid is null;
   else
      select count(1) into out_cartons
         from caselabels
         where orderid = in_orderid
           and shipid = in_shipid
           and labeltype in('CS','PL','PP','IP')
           and changeproc not like '%PALLET%';
      if out_cartons = 0 then
         for pp in (select lpid, type, quantity from shippingplate
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and parentlpid is null) loop
            if (pp.type = 'C') then
               out_cartons := out_cartons + 1;
            else
               for cp in (select custid, item, unitofmeasure, lotnumber,
                                 sum(quantity) as quantity
                           from shippingplate
                           where type in ('F','P')
                           start with lpid = pp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber) loop
                  l_quantity := 0;
                  select zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure,
                         nvl(zci.default_value('CARTONSUOM'),'CTN'))
                  into l_quantity
                  from dual;

                  out_cartons := out_cartons + nvl(l_quantity,0);
               end loop;
            end if;
         end loop;
         for cp in (select custid, item, unitofmeasure, lotnumber,
                           sum(quantity) as quantity
                     from shippingplate sp
                    where orderid = in_orderid
                      and shipid = in_shipid
                      and type in ('F','P')
                      and nvl(loadno,0) <> 0
                      and exists (
                         select 1
                           from shippingplate
                          where lpid = sp.parentlpid
                            and loadno = sp.loadno
                            and shipid = 0)
                     group by custid, item, unitofmeasure, lotnumber) loop
            l_quantity := 0;
            select zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure,
                   nvl((select defaultvalue from systemdefaults where defaultid = 'CARTONSUOM'),'CTN'))
            into l_quantity
            from dual;
            out_cartons := out_cartons + nvl(l_quantity,0);
         end loop;
      end if;
   end if;


   return out_cartons;

exception
   when OTHERS then
      return 0;
end ordercheckview_cartons;
/

create or replace function ordercheckview_cartons_nmfc
   (in_orderid  in number,
    in_shipid   in number,
    in_nmfc in varchar2)
return number
is
   out_cartons number;
   l_quantity number;
   l_shiptype varchar2(2);
begin
   select shiptype into l_shiptype from orderhdr where orderid = in_orderid and shipid = in_shipid;
   if l_shiptype = 'S' then
      select count(1) into out_cartons
        from shippingplate
       where orderid = in_orderid
         and shipid = in_shipid
         and parentlpid is null;
   else
      select count(1) into out_cartons
      from(
       select lpid
         from caselabels cl, custitem ci
        where cl.orderid = in_orderid
          and cl.shipid = in_shipid
          and cl.labeltype in('CS','PL','PP','IP')
          and cl.changeproc not like '%PALLET%'
          and ci.custid = cl.custid
          and ci.item = cl.item
          and nvl(ci.nmfc,'(none)') = nvl(in_nmfc,'(none)')
       union all
       select lpid
         from caselabels cl
        where cl.orderid = in_orderid
          and cl.shipid = in_shipid
          and cl.labeltype in('CS','PL','PP','IP')
          and cl.changeproc not like '%PALLET%'
          and cl.item is null
          and exists(
            select 1
              from shippingplate sp, custitem ci
             where sp.orderid = cl.orderid
               and sp.shipid = cl.shipid
               and ci.custid = sp.custid
               and ci.item = sp.item
               and nvl(ci.nmfc,'(none)') = nvl(in_nmfc,'(none)')
             start with parentlpid = cl.lpid
           connect by prior parentlpid = lpid)
       union all
       select lpid
         from caselabels cl
        where cl.orderid = in_orderid
          and cl.shipid = in_shipid
          and cl.labeltype in('CS','PL','PP','IP')
          and cl.changeproc not like '%PALLET%'
          and cl.item is null
          and exists(
            select 1
              from shippingplate sp, custitem ci
             where sp.orderid = cl.orderid
               and sp.shipid = cl.shipid
               and sp.lpid = cl.lpid
               and sp.parentlpid is null
               and sp.type = 'F'
               and ci.custid = sp.custid
               and ci.item = sp.item
               and nvl(ci.nmfc,'(none)') = nvl(in_nmfc,'(none)')));
      if out_cartons = 0 then
         for pp in (select lpid, type, quantity from shippingplate sp
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and parentlpid is null
                       and exists(
                         select 1
                           from shippingplate sp1
                          where type in ('F','P')
                            and exists(
                              select 1
                                from custitem
                               where custid = sp1.custid
                                 and item = sp1.item
                                 and nvl(nmfc,'(none)') = nvl(in_nmfc,'(none)'))
                           start with lpid = sp.lpid
                           connect by prior lpid = parentlpid)) loop
            if (pp.type = 'C') then
               out_cartons := out_cartons + 1;
            else
               for cp in (select custid, item, unitofmeasure, lotnumber,
                                 sum(quantity) as quantity
                           from shippingplate sp
                           where type in ('F','P')
                             and exists(
                               select 1
                                 from custitem
                                where custid = sp.custid
                                  and item = sp.item
                                  and nvl(nmfc,'(none)') = nvl(in_nmfc,'(none)'))
                           start with lpid = pp.lpid
                           connect by prior lpid = parentlpid
                           group by custid, item, unitofmeasure, lotnumber) loop
                  l_quantity := 0;
                  select zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure,
                         nvl(zci.default_value('CARTONSUOM'),'CTN'))
                  into l_quantity
                  from dual;

                  out_cartons := out_cartons + nvl(l_quantity,0);
               end loop;
            end if;
         end loop;
         for cp in (select custid, item, unitofmeasure, lotnumber,
                           sum(quantity) as quantity
                     from shippingplate sp
                    where orderid = in_orderid
                      and shipid = in_shipid
                      and type in ('F','P')
                      and nvl(loadno,0) <> 0
                      and exists (
                         select 1
                           from shippingplate
                          where lpid = sp.parentlpid
                            and loadno = sp.loadno
                            and shipid = 0)
                      and exists(
                        select 1
                          from custitem
                         where custid = sp.custid
                           and item = sp.item
                           and nvl(nmfc,'(none)') = nvl(in_nmfc,'(none)'))
                     group by custid, item, unitofmeasure, lotnumber) loop
            l_quantity := 0;
            select zlbl.uom_qty_conv(cp.custid, cp.item, cp.quantity, cp.unitofmeasure,
                   nvl((select defaultvalue from systemdefaults where defaultid = 'CARTONSUOM'),'CTN'))
            into l_quantity
            from dual;
            out_cartons := out_cartons + nvl(l_quantity,0);
         end loop;
      end if;
   end if;


   return out_cartons;

exception
   when OTHERS then
      return 0;
end ordercheckview_cartons_nmfc;
/

create or replace view ordercheckview
(
   orderid,
   shipid,
   lpid,
   custid,
   item,
   itemdesc,
   lotnumber,
   quantity,
   unitofmeasure,
   location,
   qtyentered,
   order_cartons
)
as
select S.orderid,
       S.shipid,
       ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
       S.custid,
       S.item,
       CI.descr,
       S.lotnumber,
       sum(S.quantity),
       S.unitofmeasure,
       S.location,
       S.qtyentered,
       ordercheckview_cartons(S.orderid, S.shipid)
   from shippingplate S, custitem CI
   where S.type in ('F', 'P')
     and CI.custid = S.custid
     and CI.item = S.item
   group by S.orderid,
            S.shipid,
            ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
            S.custid,
            S.item,
            CI.descr,
            S.lotnumber,
            S.unitofmeasure,
            S.location,
            S.qtyentered,
            ordercheckview_cartons(S.orderid, S.shipid);


comment on table ordercheckview is '$Id$';

create or replace view pho_ordercheckview
(
   orderid,
   shipid,
   lpid,
   custid,
   item,
   itemdesc,
   lotnumber,
   quantity,
   unitofmeasure,
   location,
   qtyentered,
   loadno,
   order_cartons
)
as
select S.orderid,
       S.shipid,
       ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
       S.custid,
       S.item,
       CI.descr,
       S.lotnumber,
       sum(S.quantity),
       S.unitofmeasure,
       S.location,
       S.qtyentered,
        OH.loadno,
       ordercheckview_cartons(S.orderid, S.shipid)
   from orderhdr OH, shippingplate S, custitem CI
   where S.type in ('F', 'P')
     and CI.custid = S.custid
     and CI.item = S.item
     and OH.orderid = S.orderid
     and OH.shipid = S.shipid
   group by S.orderid,
            S.shipid,
            ordercheckview_lpid(lpid, type, fromlpid, parentlpid),
            S.custid,
            S.item,
            CI.descr,
            S.lotnumber,
            S.unitofmeasure,
            S.location,
            S.qtyentered,
            OH.loadno,
            ordercheckview_cartons(S.orderid, S.shipid);


comment on table pho_ordercheckview is '$Id$';

exit;
