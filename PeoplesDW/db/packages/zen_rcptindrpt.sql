-- Individual Receiving Report - productivity

drop table zen_rcptindrpthdr;

create table zen_rcptindrpthdr (
   sessionid      number,
   userid         varchar2(12),
   hrs_loggedin   number(13,4),
   hrs_tasked     number(13,4),
   hrs_nontasked  number(13,4),
   orders_worked  number(13,4),
   hrs_receiving  number(13,4),
   orders_per_hr  number(12,4),
   lines_received number(13,4),
   lines_per_hr   number(12,4),
   lastupdate     date
);

create index zen_rcptindrpthdr_session_idx
   on zen_rcptindrpthdr(sessionid);

create index zen_rcptindrpthdr_update_idx
   on zen_rcptindrpthdr(lastupdate);


drop table zen_rcptindrpttmp;

create table zen_rcptindrpttmp (
   sessionid  number,
   custid     varchar2(10),
   units      number(11),
   orderid    number(9),
   shipid     number(2),
   lpid       varchar2(15),
   item       varchar2(50),
   uom        varchar2(4),
   pieces     number(7),
   cartons    number(7),
   cubed      number(9,2),
   lastupdate date
);

create index zen_rcptindrpttmp_session_idx
   on zen_rcptindrpttmp(sessionid);

create index zen_rcptindrpttmp_update_idx
   on zen_rcptindrpttmp(lastupdate);


drop table zen_rcptindrptdtl;

create table zen_rcptindrptdtl (
   sessionid  number,
   userid     varchar2(12),
   uom        varchar2(4),
   qty        number(13),
   lps_tot    number(13),
   uom_per_hr number(13,4),
   lps_per_hr number(12,4),
   pieces_qty number(12),
   pieces_qty_per_hour number(12,4),
   cartons_qty number(12),
   cartons_qty_per_hour number(12,4),
   cubed      number(12),
   cubed_per_hour number(12,4),
   lastupdate date
);

create index zen_rcptindrptdtl_session_idx
   on zen_rcptindrptdtl(sessionid);

create index zen_rcptindrptdtl_update_idx
   on zen_rcptindrptdtl(lastupdate);


create or replace package zen_rcptindrpthdrpkg
   as type zen_rcptindrpthdr_type is ref cursor return zen_rcptindrpthdr%rowtype;
      type zen_rcptindrptdtl_type is ref cursor return zen_rcptindrptdtl%rowtype;
end zen_rcptindrpthdrpkg;
/


create or replace procedure zen_rcptindrpthdrproc
   (zen_rcptindrpthdr_cursor in out zen_rcptindrpthdrpkg.zen_rcptindrpthdr_type,
    in_userid  in varchar2,
    in_begdate in date,
    in_enddate in date)
is
--
-- $Id: zen_rcptindrpt.sql 1904 2007-05-07 16:10:54Z eric $
--
   cursor c_uh(p_beg date, p_end date, p_userid varchar2) is
      select uh.*,
             nvl(zlbl.uom_qty_conv(uh.custid, uh.item, uh.units, uh.uom, 'PCS'),0) as pieces,
             nvl(zlbl.uom_qty_conv(uh.custid, uh.item, uh.units, uh.uom, 'CTN'),0) as cartons,
             nvl(zlbl.uom_qty_conv(uh.custid, uh.item, uh.units, uh.uom, ci.baseuom),0) * ci.cube as cubed
         from userhistory uh,
         	    custitem ci
         where uh.begtime between p_beg and p_end
          and upper(p_userid) in ('ALL', uh.nameid)
	        and uh.event in ('1LIP','1STP','ALIP','ASNR','LGIN','NTSK')
	        and uh.custid = ci.custid (+)
	        and uh.item = ci.item (+)
         order by uh.nameid;
   l_sessionid number;
   l_begdate date;
   l_enddate date;
   l_userid varchar2(12);
   l_curruser userhistory.nameid%type;
   l_sec_lgin number := 0;
   l_sec_ntsk number := 0;
   l_sec_recv number := 0;

   procedure do_dtl
   is
      l_cnt number;
   begin
      for dtl in (select uom, sum(units) as qty,
      	             sum(pieces) as pieces,
      	             sum(cartons) as cartons,
      	             sum(cubed) as cubed
                     from zen_rcptindrpttmp
                     group by uom) loop
         select count(distinct lpid) into l_cnt
            from zen_rcptindrpttmp
            where uom = dtl.uom;

         insert into zen_rcptindrptdtl
            (sessionid,
             userid,
             uom,
             qty,
             lps_tot,
             uom_per_hr,
             lps_per_hr,
             pieces_qty,
             pieces_qty_per_hour,
             cartons_qty,
             cartons_qty_per_hour,
             cubed,
             cubed_per_hour,
             lastupdate)
         values
            (l_sessionid,
             l_curruser,
             dtl.uom,
             dtl.qty,
             l_cnt,
             decode(l_sec_recv, 0, 0, dtl.qty / (l_sec_recv / 3600)),
             decode(l_sec_recv, 0, 0, l_cnt / (l_sec_recv / 3600)),
             dtl.pieces,
             decode(l_sec_recv, 0, 0, dtl.pieces / (l_sec_recv / 3600)),
             dtl.cartons,
             decode(l_sec_recv, 0, 0, dtl.cartons / (l_sec_recv / 3600)),
             dtl.cubed,
             decode(l_sec_recv, 0, 0, dtl.cubed / (l_sec_recv / 3600)),
             sysdate);
      end loop;
   end do_dtl;

   procedure do_user
   is
      l_orders number := 0;
      l_lines number := 0;
   begin
      select nvl(count(distinct orderid||shipid),0) into l_orders
         from zen_rcptindrpttmp;

      select nvl(sum(count(distinct item)),0) into l_lines
         from zen_rcptindrpttmp
         group by orderid||shipid;

      insert into zen_rcptindrpthdr
         (sessionid,
          userid,
          hrs_loggedin,
          hrs_tasked,
          hrs_nontasked,
          orders_worked,
          hrs_receiving,
          orders_per_hr,
          lines_received,
          lines_per_hr,
          lastupdate)
      values
         (l_sessionid,
          l_curruser,
          l_sec_lgin / 3600,
          (l_sec_lgin-l_sec_ntsk) / 3600,
          l_sec_ntsk / 3600,
          l_orders,
          l_sec_recv / 3600,
          decode(l_sec_recv, 0, 0, l_orders / (l_sec_recv / 3600)),
          l_lines,
          decode(l_sec_recv, 0, 0, l_lines / (l_sec_recv / 3600)),
          sysdate);

      do_dtl;

      delete from zen_rcptindrpttmp
         where sessionid = l_sessionid;
      commit;

      l_sec_lgin := 0;
      l_sec_ntsk := 0;
      l_sec_recv := 0;

   end do_user;

   function seconds
      (p_beg date,
       p_end date,
       p_max date)
   return number
   is
      l_secs number := 0;
      l_end date := p_end;
   begin
--    ignore null dates
      if p_beg is not null and p_end is not null then
--       Don't allow end date of event to be beyond end date of report
         if trunc(p_end) > trunc(p_max) then
            l_end := to_date(to_char(trunc(p_max), 'mm/dd/yyyy')||' 23:59:59',
                  'mm/dd/yy hh24:mi:ss');
         end if;
         l_secs := (l_end-p_beg)*86400;
      end if;
      return l_secs;

   exception
      when OTHERS then
         return 0;
   end seconds;
begin

   select sys_context('USERENV','SESSIONID')
      into l_sessionid
      from dual;

   l_begdate := to_date(to_char(trunc(in_begdate), 'mm/dd/yyyy')||' 00:00:00',
         'mm/dd/yy hh24:mi:ss');

   l_enddate := to_date(to_char(trunc(in_enddate), 'mm/dd/yyyy')||' 23:59:59',
         'mm/dd/yy hh24:mi:ss');

   l_userid := nvl(in_userid,'ALL');
   
   delete from zen_rcptindrpthdr
      where sessionid = l_sessionid;
   commit;

   delete from zen_rcptindrpthdr
      where lastupdate < trunc(sysdate);
   commit;

   delete from zen_rcptindrpttmp
      where sessionid = l_sessionid;
   commit;

   delete from zen_rcptindrpttmp
      where lastupdate < trunc(sysdate);
   commit;

   delete from zen_rcptindrptdtl
      where sessionid = l_sessionid;
   commit;

   delete from zen_rcptindrptdtl
      where lastupdate < trunc(sysdate);
   commit;

   for uh in c_uh(l_begdate, l_enddate, l_userid) loop
      if c_uh%rowcount = 1 then
         l_curruser := uh.nameid;
      end if;
      if l_curruser != uh.nameid then
         do_user;
         l_curruser := uh.nameid;
      end if;

      if uh.event = 'LGIN' then
         l_sec_lgin := l_sec_lgin + seconds(uh.begtime, uh.endtime, l_enddate);
      elsif uh.event = 'NTSK' then
         l_sec_ntsk := l_sec_ntsk + seconds(uh.begtime, uh.endtime, l_enddate);
      elsif uh.event in ('1STP','ASNR') then
         l_sec_recv := l_sec_recv + seconds(uh.begtime, uh.endtime, l_enddate);
      else
         insert into zen_rcptindrpttmp
            (sessionid,
             custid,
             units,
             orderid,
             shipid,
             lpid,
             item,
             uom,
             pieces,
             cartons,
             cubed,
             lastupdate)
         values
            (l_sessionid,
             uh.custid,
             uh.units,
             uh.orderid,
             uh.shipid,
             uh.lpid,
             uh.item,
             uh.uom,
             uh.pieces,
             uh.cartons,
             uh.cubed,
             sysdate);
      end if;
   end loop;
   do_user;

   open zen_rcptindrpthdr_cursor for
      select *
         from zen_rcptindrpthdr
         where sessionid = l_sessionid
         order by userid;

end zen_rcptindrpthdrproc;
/


create or replace procedure zen_rcptindrptdtlproc
   (zen_rcptindrptdtl_cursor in out zen_rcptindrpthdrpkg.zen_rcptindrptdtl_type,
    in_sessionid in number,
    in_begdate   in date,
    in_enddate   in date)
is
begin

   open zen_rcptindrptdtl_cursor for
      select *
         from zen_rcptindrptdtl
         where sessionid = in_sessionid
         order by userid, uom;

end zen_rcptindrptdtlproc;
/


show errors package zen_rcptindrpthdrpkg;
show errors procedure zen_rcptindrpthdrproc;
show errors procedure zen_rcptindrptdtlproc;
exit;
