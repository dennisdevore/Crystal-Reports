drop table zshipsumrpt;

create table zshipsumrpt (
   sessionid      number,
   facility       varchar2(3),
   orders_per_day number(9,4),
   pounds_per_day number(15,4),
   lines_per_day  number(9,4),
   cases_per_day  number(9,4),
   cases_accurate char(1),
   lastupdate     date
);


create index zshipsumrpt_sessionid_idx
   on zshipsumrpt(sessionid);

create index zshipsumrpt_lastupdate_idx
   on zshipsumrpt(lastupdate);


create or replace package zshipsumrptpkg
   as type ssr_type is ref cursor return zshipsumrpt%rowtype;
end zshipsumrptpkg;
/


create or replace procedure zshipsumrptproc
   (ssr_cursor in out zshipsumrptpkg.ssr_type,
    in_begdate in date,
    in_enddate in date)
is
--
-- $Id$
--
   cursor c_hdr(p_beg date, p_end date) is
      select fromfacility as fac,
             count(1)/(trunc(p_end)-trunc(p_beg)+1) as orders,
             nvl(sum(weightship),0)/(trunc(p_end)-trunc(p_beg)+1) as pounds
         from orderhdr
         where dateshipped between p_beg and p_end
           and ordertype = 'O'
         group by fromfacility;
   cursor c_dtl(p_beg date, p_end date) is
      select OH.fromfacility as fac,
             count(1)/(trunc(p_end)-trunc(p_beg)+1) as lines,
             nvl(sum(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyship, OD.uom, 'CS')),0)
                  /(trunc(p_end)-trunc(p_beg)+1) as cases
         from orderdtl OD, orderhdr OH
         where OH.dateshipped between p_beg and p_end
           and OH.ordertype = 'O'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
         group by OH.fromfacility;
   cursor c_no_cs(p_beg date, p_end date) is
      select OH.fromfacility as fac, count(1) as cnt
         from orderdtl OD, orderhdr OH
         where OH.dateshipped between p_beg and p_end
           and OH.ordertype = 'O'
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and nvl(zlbl.uom_qty_conv(OD.custid, OD.item, OD.qtyship, OD.uom, 'CS'),0) = 0
         group by OH.fromfacility;
   l_begdate date;
   l_enddate date;
   l_sessionid number;
   l_lastupdate date := trunc(sysdate);

   procedure update_data
      (p_facility varchar2,
       p_orders   number,
       p_pounds   number,
       p_lines    number,
       p_cases    number,
       p_accurate varchar2)
   is
   begin
      update zshipsumrpt
         set orders_per_day = orders_per_day + p_orders,
             pounds_per_day = pounds_per_day + p_pounds,
             lines_per_day = lines_per_day + p_lines,
             cases_per_day = cases_per_day + p_cases,
             cases_accurate = p_accurate
         where sessionid = l_sessionid
           and facility = p_facility
           and lastupdate = l_lastupdate;
      if sql%rowcount = 0 then
         insert into zshipsumrpt
            (sessionid, facility, orders_per_day, pounds_per_day,
             lines_per_day, cases_per_day, cases_accurate, lastupdate)
         values
            (l_sessionid, p_facility, p_orders, p_pounds,
             p_lines, p_cases, p_accurate, l_lastupdate);
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

   delete from zshipsumrpt
      where sessionid = l_sessionid;
   commit;

   delete from zshipsumrpt
      where lastupdate < l_lastupdate;
   commit;

   for f in c_hdr(l_begdate, l_enddate) loop
      update_data(f.fac, f.orders, f.pounds, 0, 0, 'Y');
   end loop;

   for f in c_dtl(l_begdate, l_enddate) loop
      update_data(f.fac, 0, 0, f.lines, f.cases, 'Y');
   end loop;

   for f in c_no_cs(l_begdate, l_enddate) loop
      update_data(f.fac, 0, 0, 0, 0, 'N');
   end loop;
   commit;

   open ssr_cursor for
      select *
         from zshipsumrpt
         where sessionid = l_sessionid
         order by facility;

end zshipsumrptproc;
/

show errors package zshipsumrptpkg;
show errors procedure zshipsumrptproc;
exit;