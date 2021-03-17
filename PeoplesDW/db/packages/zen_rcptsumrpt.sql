drop table zen_rcptsumrpt;

create table zen_rcptsumrpt (
   sessionid        number,
   facility         varchar2(3),
   cases_per_day    number(9,4),
   cases_accurate   char(1),
   pallets_per_day  number(9,4),
   pallets_accurate char(1),
   lps_per_day      number(9,4),
   orders_per_day   number(9,4),
   lines_per_day    number(9,4),
   cubed_per_day    number(9,4),
   pieces_per_day   number(9,4),
   cartons_per_day  number(9,4),
   lastupdate       date
);


create index zen_rcptsumrpt_sessionid_idx
   on zen_rcptsumrpt(sessionid);

create index zen_rcptsumrpt_lastupdate_idx
   on zen_rcptsumrpt(lastupdate);


create or replace package zen_rcptsumrptpkg
   as type rsr_type is ref cursor return zen_rcptsumrpt%rowtype;
end zen_rcptsumrptpkg;
/


create or replace procedure zen_rcptsumrptproc
   (rsr_cursor in out zen_rcptsumrptpkg.rsr_type,
    in_begdate in date,
    in_enddate in date)
is
--
-- $Id: zen_rcptsumrptobjects.sql 284 2005-10-28 17:35:10Z ed $
--
   cursor c_hdr(p_beg date, p_end date) is
      select tofacility as fac,
             count(1)/(trunc(p_end)-trunc(p_beg)+1) as orders
         from orderhdr
         where statusupdate between p_beg and p_end
           and ordertype in ('R','C')
           and orderstatus = 'R'
         group by tofacility;
   cursor c_dtl(p_beg date, p_end date) is
      select OH.tofacility as fac,
             count(1)/(trunc(p_end)-trunc(p_beg)+1) as lines,
             nvl(sum(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyrcvd, OD.uom, 'CS')),0)
                  /(trunc(p_end)-trunc(p_beg)+1) as cases,
             nvl(sum(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyrcvd, OD.uom, 'PT')),0)
                  /(trunc(p_end)-trunc(p_beg)+1) as pallets,
             sum(nvl(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyrcvd, OD.uom, 'PCS'),0))
                  /(trunc(p_end)-trunc(p_beg)+1) as pieces,
             sum(nvl(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyrcvd, OD.uom, 'CTN'),0))
                  /(trunc(p_end)-trunc(p_beg)+1) as cartons,
             sum(nvl(OD.cubercvd,0))/(trunc(p_end)-trunc(p_beg)+1) as cubed
         from orderdtl OD, orderhdr OH
         where OH.statusupdate between p_beg and p_end
           and OH.ordertype in ('R','C')
           and OH.orderstatus = 'R'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
         group by OH.tofacility;
   cursor c_no_uom(p_beg date, p_end date, p_uom varchar2) is
      select OH.tofacility as fac, count(1) as cnt
         from orderdtl OD, orderhdr OH
         where OH.statusupdate between p_beg and p_end
           and OH.ordertype in ('R','C')
           and OH.orderstatus = 'R'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and nvl(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyrcvd, OD.uom, p_uom),0) = 0
         group by OH.tofacility;
   cursor c_plate(p_beg date, p_end date) is
      select facility as fac, count(1)/(trunc(p_end)-trunc(p_beg)+1) as lps
         from plate
         where type = 'PA'
           and creationdate between p_beg and p_end
           and nvl(orderid,0) != 0
         group by facility;
   cursor c_delplate(p_beg date, p_end date) is
      select facility as fac, count(1)/(trunc(p_end)-trunc(p_beg)+1) as lps
         from deletedplate
         where type = 'PA'
           and nvl(orderid,0) != 0
           and creationdate between p_beg and p_end
         group by facility;
   l_begdate date;
   l_enddate date;
   l_sessionid number;
   l_lastupdate date := trunc(sysdate);

   procedure update_data
      (p_facility varchar2,
       p_cases    number,
       p_cs_acc   varchar2,
       p_pallets  number,
       p_pl_acc   varchar2,
       p_lps      number,
       p_orders   number,
       p_lines    number,
       p_cubed    number,
       p_pieces   number,
       p_cartons  number)
   is
   begin
      update zen_rcptsumrpt
         set cases_per_day = cases_per_day + p_cases,
             cases_accurate = nvl(p_cs_acc, cases_accurate),
             pallets_per_day = pallets_per_day + p_pallets,
             pallets_accurate = nvl(p_pl_acc, pallets_accurate),
             lps_per_day = lps_per_day + p_lps,
             orders_per_day = orders_per_day + p_orders,
             lines_per_day = lines_per_day + p_lines,
             cubed_per_day = cubed_per_day + p_cubed,
             pieces_per_day = pieces_per_day + p_pieces,
             cartons_per_day = cartons_per_day + p_cartons
         where sessionid = l_sessionid
           and facility = p_facility
           and lastupdate = l_lastupdate;
      if sql%rowcount = 0 then
         insert into zen_rcptsumrpt
            (sessionid, facility, cases_per_day, cases_accurate,
             pallets_per_day, pallets_accurate, lps_per_day, orders_per_day,
             lines_per_day, cubed_per_day, pieces_per_day, cartons_per_day,
             lastupdate)
         values
            (l_sessionid, p_facility, p_cases, p_cs_acc,
             p_pallets, p_pl_acc, p_lps, p_orders,
             p_lines, p_cubed, p_pieces, p_cartons,
             l_lastupdate);
      end if;
   end update_data;
begin

   l_begdate := to_date(to_char(trunc(in_begdate), 'mm/dd/yyyy')||' 00:00:00',
         'mm/dd/yy hh24:mi:ss');

   l_enddate := to_date(to_char(trunc(in_enddate), 'mm/dd/yyyy')||' 23:59:59',
         'mm/dd/yy hh24:mi:ss');

   select sys_context('USERENV','SESSIONID')
      into l_sessionid
      from dual;

   delete from zen_rcptsumrpt
      where sessionid = l_sessionid;
   commit;

   delete from zen_rcptsumrpt
      where lastupdate < l_lastupdate;
   commit;

   for f in c_hdr(l_begdate, l_enddate) loop
      update_data(f.fac, 0, 'Y', 0, 'Y', 0, f.orders, 0, 0, 0, 0);
   end loop;

   for f in c_dtl(l_begdate, l_enddate) loop
      update_data(f.fac, f.cases, 'Y', f.pallets, 'Y', 0, 0, f.lines, f.cubed, f.pieces, f.cartons);
   end loop;

   for f in c_plate(l_begdate, l_enddate) loop
      update_data(f.fac, 0, 'Y', 0, 'Y', f.lps, 0, 0, 0, 0, 0);
   end loop;

   for f in c_delplate(l_begdate, l_enddate) loop
      update_data(f.fac, 0, 'Y', 0, 'Y', f.lps, 0, 0, 0, 0, 0);
   end loop;

   for f in c_no_uom(l_begdate, l_enddate, 'CS') loop
      update_data(f.fac, 0, 'N', 0, null, 0, 0, 0, 0, 0, 0);
   end loop;

   for f in c_no_uom(l_begdate, l_enddate, 'PT') loop
      update_data(f.fac, 0, null, 0, 'N', 0, 0, 0, 0, 0, 0);
   end loop;

   commit;

   open rsr_cursor for
      select *
         from zen_rcptsumrpt
         where sessionid = l_sessionid
         order by facility;

end zen_rcptsumrptproc;
/

show errors package zen_rcptsumrptpkg;
show errors procedure zen_rcptsumrptproc;
exit;
