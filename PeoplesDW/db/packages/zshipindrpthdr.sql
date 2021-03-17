-- Individual Shipping Report - productivity

drop table zshipindrpt_hdr;

create table zshipindrpt_hdr (
   sessionid            number,
   userid               varchar2(12),
   hrs_loggedin         number(9,4),
   hrs_tasked           number(9,4),
   hrs_nontasked        number(9,4),
   orders_picked        number(9,4),
   hrs_picking          number(9,4),
   hrs_processing       number(9,4),
   orders_picked_per_hr number(8,4),
   lines_picked         number(9,4),
   lines_shipped        number(9,4),
   hrs_shipping         number(9,4),
   lines_picked_per_hr  number(8,4),
   lines_shipped_per_hr number(9,4),
   hrs_replenishment    number(9,4),
   units_replenished    number(8),
   lastupdate           date
);

create index zshipindrpt_hdr_sessionid_idx
   on zshipindrpt_hdr(sessionid);

create index zshipindrpt_hdr_lastupdate_idx
   on zshipindrpt_hdr(lastupdate);


drop table zshipindrpt_tmp;

create table zshipindrpt_tmp (
   sessionid  number,
   event      varchar2(4),
   custid     varchar2(10),
   units      number(7),
   orderid    number(9),
   shipid     number(2),
   item       varchar2(50),
   uom        varchar2(4),
   begtime    date,
   endtime    date,
   etc        varchar2(255),
   baseuom    varchar2(4),
   lastupdate date
);

create index zshipindrpt_tmp_sessionid_idx
   on zshipindrpt_tmp(sessionid);

create index zshipindrpt_tmp_lastupdate_idx
   on zshipindrpt_tmp(lastupdate);


drop table zshipindrpt_dtl;

create table zshipindrpt_dtl (
   sessionid          number,
   userid             varchar2(12),
   baseuom            varchar2(4),
   baseuom_descr      varchar2(32),
   baseuom_qty        number(12),
   baseuom_qty_per_hr number(12,4),
   uom1               varchar2(4),
   uom1_descr         varchar2(32),
   uom1_picks         number(12),
   uom1_picks_per_hr  number(12,4),
   uom2               varchar2(4),
   uom2_descr         varchar2(32),
   uom2_picks         number(12),
   uom2_picks_per_hr  number(12,4),
   uom3               varchar2(4),
   uom3_descr         varchar2(32),
   uom3_picks         number(12),
   uom3_picks_per_hr  number(12,4),
   uom4               varchar2(4),
   uom4_descr         varchar2(32),
   uom4_picks         number(12),
   uom4_picks_per_hr  number(12,4),
   uom5               varchar2(4),
   uom5_descr         varchar2(32),
   uom5_picks         number(12),
   uom5_picks_per_hr  number(12,4),
   lastupdate           date
);

create index zshipindrpt_dtl_sessionid_idx
   on zshipindrpt_dtl(sessionid);

create index zshipindrpt_dtl_lastupdate_idx
   on zshipindrpt_dtl(lastupdate);


create or replace package zshipindrpt_hdrpkg
   as type zshipindrpt_hdr_type is ref cursor return zshipindrpt_hdr%rowtype;
end zshipindrpt_hdrpkg;
/


create or replace procedure zshipindrpt_hdrproc
   (zshipindrpt_hdr_cursor in out zshipindrpt_hdrpkg.zshipindrpt_hdr_type,
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
	        and event in ('LGIN',
                         'NTSK',
                         'AUDT','COMP','DKUL','DPIK','LPUL','OCHK','REST','SPMP',
                         'PICK',
                         'STGP',
                         'DKLD',
                         'RPPK',
                         'LPLD','BADT')
         order by nameid;
   uh c_uh%rowtype;
   l_sessionid number;
   l_begdate date;
   l_enddate date;
   l_userid varchar(12);
   l_curruser userhistory.nameid%type;
   l_sec_lgin number := 0;
   l_sec_ntsk number := 0;
   l_sec_proc number := 0;
   l_sec_pick number := 0;
   l_sec_ship number := 0;
   l_sec_repl number := 0;
   l_units_repl number := 0;

   procedure do_tmp
   is
      cursor c_itm(p_custid varchar2, p_item varchar2) is
         select baseuom
            from custitem
            where custid = p_custid
              and item = p_item;
      itm c_itm%rowtype;
      l_load loads.loadno%type;
   begin
      if uh.event = 'LPLD' then
         l_load := substr(uh.etc, instr(uh.etc, '=')+1, instr(uh.etc, ' ')-instr(uh.etc, '=')-1);
         for od in (select orderid, shipid, custid, item, qtyship, uom
                     from orderdtl
                     where (orderid, shipid) in
                        (select orderid, shipid from orderhdr where loadno = l_load)) loop
            itm := null;
            open c_itm(od.custid, od.item);
            fetch c_itm into itm;
            close c_itm;
            insert into zshipindrpt_tmp
               (sessionid,
                event,
                custid,
                units,
                orderid,
                shipid,
                item,
                uom,
                begtime,
                endtime,
                etc,
                baseuom,
                lastupdate)
            values
               (l_sessionid,
                uh.event,
                od.custid,
                od.qtyship,
                od.orderid,
                od.shipid,
                od.item,
                od.uom,
                uh.begtime,
                uh.endtime,
                uh.etc,
                itm.baseuom,
                sysdate);
         end loop;
      else
         itm := null;
         open c_itm(uh.custid, uh.item);
         fetch c_itm into itm;
         close c_itm;
         insert into zshipindrpt_tmp
            (sessionid,
             event,
             custid,
             units,
             orderid,
             shipid,
             item,
             uom,
             begtime,
             endtime,
             etc,
             baseuom,
             lastupdate)
         values
            (l_sessionid,
             uh.event,
             uh.custid,
             uh.units,
             uh.orderid,
             uh.shipid,
             uh.item,
             uh.uom,
             uh.begtime,
             uh.endtime,
             uh.etc,
             itm.baseuom,
             sysdate);
      end if;
   end do_tmp;

   function uom_descr
      (in_uom in varchar2)
   return varchar2
   is
      l_descr unitsofmeasure.descr%type := null;
   begin
      select descr
         into l_descr
         from unitsofmeasure
         where code = in_uom;
      return l_descr;
   exception
      when OTHERS then
         return in_uom;
   end uom_descr;

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

   procedure do_dtl
   is
      type uom_rectype is record (
         uom custitem.baseuom%type,
         uom_descr unitsofmeasure.descr%type,
         picks number,
         per_hr number);
      type uom_tbltype is table of uom_rectype index by binary_integer;
      uom_tbl uom_tbltype;
      cursor c_tmp is
         select * from zshipindrpt_tmp
            where event in ('PICK','BADT')
              and (etc is null or etc != 'batch')
            order by baseuom, uom;
      tmp c_tmp%rowtype;
      l_uom custitem.baseuom%type := null;
      l_uom_descr unitsofmeasure.descr%type;
      l_qty number := 0;
      i binary_integer;
      uom_found boolean;

      function picks_per_hr
         (in_uom varchar2,
          in_qty number)
      return number
      is
         l_hrs number := 0;
         l_secs number := 0;
      begin
         if (in_uom is not null) and (in_qty > 0) then
            for ztmp in (select begtime, endtime
                           from zshipindrpt_tmp
                           where uom = in_uom
                             and event = 'PICK') loop
               l_secs := l_secs + seconds(ztmp.begtime, ztmp.endtime, l_enddate);
            end loop;
            if l_secs > 0 then
               l_hrs := in_qty / (l_secs / 3600);
            end if;
         end if;
         return l_secs;
      end picks_per_hr;

      procedure ins_dtl
      is
         i binary_integer;
      begin
         while (uom_tbl.count < 5)
         loop
            i := uom_tbl.count+1;
            uom_tbl(i).uom := null;
            uom_tbl(i).uom_descr := null;
            uom_tbl(i).picks := 0;
         end loop;
         for i in 1..uom_tbl.count loop
            uom_tbl(i).per_hr := picks_per_hr(uom_tbl(i).uom, uom_tbl(i).picks);
         end loop;
         insert into zshipindrpt_dtl
            (sessionid,
             userid,
             baseuom,
             baseuom_descr,
             baseuom_qty,
             baseuom_qty_per_hr,
             uom1,
             uom1_descr,
             uom1_picks,
             uom1_picks_per_hr,
             uom2,
             uom2_descr,
             uom2_picks,
             uom2_picks_per_hr,
             uom3,
             uom3_descr,
             uom3_picks,
             uom3_picks_per_hr,
             uom4,
             uom4_descr,
             uom4_picks,
             uom4_picks_per_hr,
             uom5,
             uom5_descr,
             uom5_picks,
             uom5_picks_per_hr,
             lastupdate)
         values
            (l_sessionid,
             l_curruser,
             l_uom,
             l_uom_descr,
             l_qty,
             decode(l_sec_pick, 0, 0, l_qty / (l_sec_pick / 3600)),
             uom_tbl(1).uom,
             uom_tbl(1).uom_descr,
             uom_tbl(1).picks,
             uom_tbl(1).per_hr,
             uom_tbl(2).uom,
             uom_tbl(2).uom_descr,
             uom_tbl(2).picks,
             uom_tbl(2).per_hr,
             uom_tbl(3).uom,
             uom_tbl(3).uom_descr,
             uom_tbl(3).picks,
             uom_tbl(3).per_hr,
             uom_tbl(4).uom,
             uom_tbl(4).uom_descr,
             uom_tbl(4).picks,
             uom_tbl(4).per_hr,
             uom_tbl(5).uom,
             uom_tbl(5).uom_descr,
             uom_tbl(5).picks,
             uom_tbl(5).per_hr,
             sysdate);
         l_uom := tmp.baseuom;
         l_uom_descr := uom_descr(l_uom);
         l_qty := 0;
         uom_tbl.delete;
      end ins_dtl;
   begin
      uom_tbl.delete;
      open c_tmp;
      loop
         fetch c_tmp into tmp;
         exit when c_tmp%notfound;

         if c_tmp%rowcount = 1 then
            l_uom := tmp.baseuom;
            l_uom_descr := uom_descr(l_uom);
         end if;
         if l_uom != tmp.baseuom then
            ins_dtl;
         end if;

         l_qty := l_qty + zlbl.uom_qty_conv(tmp.custid, tmp.item, tmp.units, tmp.uom, tmp.baseuom);

         uom_found := false;
         for i in 1..uom_tbl.count loop
            if uom_tbl(i).uom = tmp.uom then
               uom_found := true;
               exit;
            end if;
         end loop;
         if not uom_found then
            i := uom_tbl.count+1;
            uom_tbl(i).uom := tmp.uom;
            uom_tbl(i).uom_descr := uom_descr(tmp.uom);
            uom_tbl(i).picks := 0;
         end if;

         uom_tbl(i).picks := uom_tbl(i).picks + tmp.units;

      end loop;
      ins_dtl;

   end do_dtl;

   procedure do_user
   is
      l_orders_pick number := 0;
      l_lines_pick number := 0;
      l_lines_ship number := 0;
   begin
      select nvl(count(distinct orderid||shipid),0) into l_orders_pick
         from zshipindrpt_tmp
         where event in ('PICK','BADT')
           and (etc is null or etc != 'batch');

      select nvl(sum(count(distinct item)),0) into l_lines_pick
         from zshipindrpt_tmp
         where event in ('PICK','BADT')
           and (etc is null or etc != 'batch')
         group by orderid||shipid;

      select nvl(sum(count(distinct item)),0) into l_lines_ship
         from zshipindrpt_tmp
         where event = 'LPLD'
         group by orderid||shipid;

      insert into zshipindrpt_hdr
         (sessionid,
          userid,
          hrs_loggedin,
          hrs_tasked,
          hrs_nontasked,
          orders_picked,
          hrs_picking,
          hrs_processing,
          orders_picked_per_hr,
          lines_picked,
          lines_shipped,
          hrs_shipping,
          lines_picked_per_hr,
          lines_shipped_per_hr,
          hrs_replenishment,
          units_replenished,
          lastupdate)
      values
         (l_sessionid,
          l_curruser,
          l_sec_lgin / 3600,
          (l_sec_lgin-l_sec_ntsk) / 3600,
          l_sec_ntsk / 3600,
          l_orders_pick,
          l_sec_pick / 3600,
          l_sec_proc / 3600,
          decode(l_sec_pick, 0, 0, l_orders_pick / (l_sec_pick / 3600)),
          l_lines_pick,
          l_lines_ship,
          l_sec_ship / 3600,
          decode(l_sec_pick, 0, 0, l_lines_pick / (l_sec_pick / 3600)),
          decode(l_sec_ship, 0, 0, l_lines_ship / (l_sec_ship / 3600)),
          l_sec_repl / 3600,
          l_units_repl,
          sysdate);

      do_dtl;

      delete from zshipindrpt_tmp
         where sessionid = l_sessionid;
      commit;

      l_sec_lgin := 0;
      l_sec_ntsk := 0;
      l_sec_proc := 0;
      l_sec_pick := 0;
      l_sec_ship := 0;
      l_sec_repl := 0;
      l_units_repl := 0;

   end do_user;

begin

   select sys_context('USERENV','SESSIONID')
      into l_sessionid
      from dual;

   l_begdate := to_date(to_char(trunc(in_begdate), 'mm/dd/yyyy')||' 00:00:00',
         'mm/dd/yy hh24:mi:ss');

   l_enddate := to_date(to_char(trunc(in_enddate), 'mm/dd/yyyy')||' 23:59:59',
         'mm/dd/yy hh24:mi:ss');

   l_userid := nvl(in_userid,'ALL');
   
   delete from zshipindrpt_hdr
      where sessionid = l_sessionid;
   commit;

   delete from zshipindrpt_hdr
      where lastupdate < trunc(sysdate);
   commit;

   delete from zshipindrpt_tmp
      where sessionid = l_sessionid;
   commit;

   delete from zshipindrpt_tmp
      where lastupdate < trunc(sysdate);
   commit;

   delete from zshipindrpt_dtl
      where sessionid = l_sessionid;
   commit;

   delete from zshipindrpt_dtl
      where lastupdate < trunc(sysdate);
   commit;

   open c_uh(l_begdate, l_enddate, l_userid);
   loop
      fetch c_uh into uh;
      exit when c_uh%notfound;

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

      elsif uh.event in ('AUDT','COMP','DKUL','DPIK','LPUL','OCHK','REST','SPMP') then
         l_sec_proc := l_sec_proc + seconds(uh.begtime, uh.endtime, l_enddate);

      elsif uh.event = 'PICK' then
         l_sec_pick := l_sec_pick + seconds(uh.begtime, uh.endtime, l_enddate);
         do_tmp;

      elsif uh.event = 'STGP' then
         if (uh.etc is not null) or (uh.etc = 'wix=11') then
            l_sec_repl := l_sec_repl + seconds(uh.begtime, uh.endtime, l_enddate);
         else
            l_sec_pick := l_sec_pick + seconds(uh.begtime, uh.endtime, l_enddate);
         end if;

      elsif uh.event = 'DKLD' then
         l_sec_ship := l_sec_ship + seconds(uh.begtime, uh.endtime, l_enddate);

      elsif uh.event = 'RPPK' then
         l_sec_repl := l_sec_repl + seconds(uh.begtime, uh.endtime, l_enddate);
         l_units_repl := l_units_repl + uh.units;

      else
         do_tmp;

      end if;
   end loop;
   do_user;

   open zshipindrpt_hdr_cursor for
      select *
         from zshipindrpt_hdr
         where sessionid = l_sessionid
         order by userid;

end zshipindrpt_hdrproc;
/


show errors package zshipindrpt_hdrpkg;
show errors procedure zshipindrpt_hdrproc;
exit;
