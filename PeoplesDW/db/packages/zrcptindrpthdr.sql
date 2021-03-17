-- Individual Receiving Report - productivity

drop table zrcptindrpt_hdr;

create table zrcptindrpt_hdr (
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

create index zrcptindrpt_hdr_sessionid_idx
   on zrcptindrpt_hdr(sessionid);

create index zrcptindrpt_hdr_lastupdate_idx
   on zrcptindrpt_hdr(lastupdate);


drop table zrcptindrpt_tmp;

create table zrcptindrpt_tmp (
   sessionid  number,
   custid     varchar2(10),
   units      number(11),
   orderid    number(9),
   shipid     number(2),
   lpid       varchar2(15),
   item       varchar2(50),
   uom        varchar2(4),
   lastupdate date
);

create index zrcptindrpt_tmp_sessionid_idx
   on zrcptindrpt_tmp(sessionid);

create index zrcptindrpt_tmp_lastupdate_idx
   on zrcptindrpt_tmp(lastupdate);


drop table zrcptindrpt_dtl;

create table zrcptindrpt_dtl (
   sessionid  number,
   userid     varchar2(12),
   uom        varchar2(4),
   qty        number(13),
   lps_tot    number(13),
   uom_per_hr number(13,4),
   lps_per_hr number(12,4),
   lastupdate date
);

create index zrcptindrpt_dtl_sessionid_idx
   on zrcptindrpt_dtl(sessionid);

create index zrcptindrpt_dtl_lastupdate_idx
   on zrcptindrpt_dtl(lastupdate);


create or replace package zrcptindrpt_hdrpkg
   as type zrcptindrpt_hdr_type is ref cursor return zrcptindrpt_hdr%rowtype;
end zrcptindrpt_hdrpkg;
/


create or replace procedure zrcptindrpt_hdrproc
   (zrcptindrpt_hdr_cursor in out zrcptindrpt_hdrpkg.zrcptindrpt_hdr_type,
    in_userid  in varchar2,
    in_begdate in date,
    in_enddate in date)
is
--
-- $Id$
--
   cursor c_uh(p_beg date, p_end date, p_userid varchar2) is
      select *
         from userhistory
         where begtime between p_beg and p_end
          and upper(p_userid) in ('ALL', nameid)
	        and event in ('1LIP','1STP','ALIP','ASNR','LGIN','NTSK')
         order by nameid;
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
      for dtl in (select uom, sum(units) as qty
                     from zrcptindrpt_tmp
                     group by uom) loop
         select count(distinct lpid) into l_cnt
            from zrcptindrpt_tmp
            where uom = dtl.uom;

         insert into zrcptindrpt_dtl
            (sessionid,
             userid,
             uom,
             qty,
             lps_tot,
             uom_per_hr,
             lps_per_hr,
             lastupdate)
         values
            (l_sessionid,
             l_curruser,
             dtl.uom,
             dtl.qty,
             l_cnt,
             decode(l_sec_recv, 0, 0, dtl.qty / (l_sec_recv / 3600)),
             decode(l_sec_recv, 0, 0, l_cnt / (l_sec_recv / 3600)),
             sysdate);
      end loop;
   end do_dtl;

   procedure do_user
   is
      l_orders number := 0;
      l_lines number := 0;
   begin
      select nvl(count(distinct orderid||shipid),0) into l_orders
         from zrcptindrpt_tmp;

      select nvl(sum(count(distinct item)),0) into l_lines
         from zrcptindrpt_tmp
         group by orderid||shipid;

      insert into zrcptindrpt_hdr
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

      delete from zrcptindrpt_tmp
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
   
   delete from zrcptindrpt_hdr
      where sessionid = l_sessionid;
   commit;

   delete from zrcptindrpt_hdr
      where lastupdate < trunc(sysdate);
   commit;

   delete from zrcptindrpt_tmp
      where sessionid = l_sessionid;
   commit;

   delete from zrcptindrpt_tmp
      where lastupdate < trunc(sysdate);
   commit;

   delete from zrcptindrpt_dtl
      where sessionid = l_sessionid;
   commit;

   delete from zrcptindrpt_dtl
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
         insert into zrcptindrpt_tmp
            (sessionid,
             custid,
             units,
             orderid,
             shipid,
             lpid,
             item,
             uom,
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
             sysdate);
      end if;
   end loop;
   do_user;

   open zrcptindrpt_hdr_cursor for
      select *
         from zrcptindrpt_hdr
         where sessionid = l_sessionid
         order by userid;

end zrcptindrpt_hdrproc;
/


show errors package zrcptindrpt_hdrpkg;
show errors procedure zrcptindrpt_hdrproc;
exit;
