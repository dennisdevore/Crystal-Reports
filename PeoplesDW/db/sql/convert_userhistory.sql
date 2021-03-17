--
-- $Id$
--
declare
   type ordtype is record (
      orderid orderhdr.orderid%type,
      shipid orderhdr.shipid%type);
   type ordtbltype is table of ordtype index by binary_integer;
   ordtbl ordtbltype;

   type lptbltype is table of varchar2(1) index by varchar2(15);
   lptbl lptbltype;

   l_begtime date := null;
   l_pickparentevent userhistory.etc%type;
   nuh userhistory_new%rowtype;
   pnuh userhistory_new%rowtype := null;

   function shlp_cube(in_lpid varchar2)
   return userhistory_new.cube%type
   is
      l_cube userhistory_new.cube%type := 0;
   begin
      select least(sum(pickqty*zci.item_cube(custid, item, pickuom)), 999999.9999)
         into l_cube
         from shippingplate
         where type in ('F','P')
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
      return l_cube;
   end shlp_cube;

   function shlp_pickqty(in_lpid varchar2)
   return userhistory_new.units%type
   is
      l_pickqty userhistory_new.units%type := 0;
   begin
      select sum(nvl(pickqty,0))
         into l_pickqty
         from shippingplate
         where type in ('F','P')
         start with lpid = in_lpid
         connect by prior lpid = parentlpid;
      return l_pickqty;
   end shlp_pickqty;

   function shlp_pickuom(in_lpid varchar2)
   return userhistory_new.uom%type
   is
      l_cnt pls_integer := 0;
      l_pickuom userhistory_new.uom%type := null;
   begin
      for sp in (select distinct pickuom from(
                 select pickuom
                  from shippingplate
                  where type in ('F','P')
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid)) loop
         l_pickuom := sp.pickuom;
         l_cnt := l_cnt + 1;
         if l_cnt > 1 then
            l_pickuom := null;
            exit;
         end if;
      end loop;
      return l_pickuom;
   end shlp_pickuom;

   function shlp_uom(in_lpid varchar2)
   return userhistory_new.baseuom%type
   is
      l_cnt pls_integer := 0;
      l_uom userhistory_new.baseuom%type := null;
   begin
      for sp in (select distinct unitofmeasure from(
                 select unitofmeasure
                  from shippingplate
                  where type in ('F','P')
                  start with lpid = in_lpid
                  connect by prior lpid = parentlpid)) loop
         l_uom := sp.unitofmeasure;
         l_cnt := l_cnt + 1;
         if l_cnt > 1 then
            l_uom := null;
            exit;
         end if;
      end loop;
      return l_uom;
   end shlp_uom;

   function lp_timed_qty(in_lpid varchar2, in_date date)
   return plate.quantity%type
   is
      cursor c_lp(p_lpid varchar2, p_date date) is
         select whenoccurred, quantity, lastupdate
            from platehistory
            where lpid = p_lpid
              and whenoccurred >= p_date
         union
         select sysdate as whenoccurred, quantity, lastupdate
            from plate
            where lpid = p_lpid
         order by whenoccurred;
      l_qty plate.quantity%type := 0;
   begin
      for lp in c_lp(in_lpid, in_date) loop
         if lp.lastupdate >= in_date then
            l_qty := lp.quantity;
            exit;
         end if;
      end loop;
      return l_qty;
   end lp_timed_qty;

   procedure get_lpid_history
      (in_status in varchar2)
   is
   begin
      for ph in (select * from platehistory
                  where lpid = nuh.lpid
                  order by whenoccurred) loop
         if ph.status = in_status then
            nuh.baseuom := ph.unitofmeasure;
            nuh.baseunits := ph.quantity;
            nuh.cube := least(zci.item_cube(ph.custid, ph.item, ph.unitofmeasure) * ph.quantity,
                  999999.9999);
            nuh.weight := ph.weight;
            exit;
         end if;
      end loop;
   end get_lpid_history;

   procedure get_lpid_data
   is
      cursor c_lp(p_lpid varchar2) is
         select custid, item
            from plate
            where lpid = p_lpid
         union
         select custid, item
            from deletedplate
            where lpid = p_lpid;
      lp c_lp%rowtype := null;
   begin
      if nuh.custid is null or nuh.item is null then
         open c_lp(nuh.lpid);
         fetch c_lp into lp;
         close c_lp;
         if lp.custid is null then
            return;
         end if;
         nuh.custid := lp.custid;
         nuh.item := lp.item;
      end if;

      nuh.baseuom := zci.baseuom(nuh.custid, nuh.item);
      if nuh.uom is null then
         nuh.uom := nuh.baseuom;
      end if;
      nuh.baseunits := zlbl.uom_qty_conv(nuh.custid, nuh.item, nuh.units, nuh.uom,
            nuh.baseuom);
      nuh.cube := least(zci.item_cube(nuh.custid, nuh.item, nuh.uom) * nuh.units, 999999.9999);
      nuh.weight := least(zcwt.lp_item_weight(nuh.lpid, nuh.custid, nuh.item, nuh.uom)*nuh.units,
            999999999.99999999);
   end get_lpid_data;

   procedure get_pick_history
   is
      cursor c_sp(p_orderid number, p_shipid number, p_fromlpid varchar2) is
         select pickqty,
                pickedfromloc,
                pickuom,
                unitofmeasure,
                quantity,
                zci.item_cube(custid, item, pickuom)*pickqty as cube,
                weight
            from shippingplate
            where fromlpid = p_fromlpid
              and orderid = p_orderid
              and shipid = p_shipid;
      sp c_sp%rowtype := null;
      i binary_integer;
      l_matched boolean := false;
   begin
      open c_sp(nuh.orderid, nuh.shipid, nuh.lpid);
      fetch c_sp into sp;
      close c_sp;
      if sp.pickqty is not null then
         nuh.units := sp.pickqty;
         nuh.location := sp.pickedfromloc;
         nuh.uom := sp.pickuom;
         nuh.baseuom := sp.unitofmeasure;
         nuh.baseunits := sp.quantity;
         nuh.cube := least(sp.cube, 999999.9999);
         nuh.weight := sp.weight;
      else
         nuh.baseuom := zci.baseuom(nuh.custid, nuh.item);
         nuh.baseunits := zlbl.uom_qty_conv(nuh.custid, nuh.item, nuh.units,
               nuh.uom, nuh.baseuom);
         nuh.cube := least(zci.item_cube(nuh.custid, nuh.item, nuh.uom)*nuh.units, 999999.9999);
         nuh.weight := least(zci.item_weight(nuh.custid, nuh.item, nuh.uom)*nuh.units,
               999999999.99999999);
      end if;

--    save unique orderid/shipid for staging guess
      if nvl(nuh.orderid,0) != 0 then
         for i in 1..ordtbl.count loop
            if ordtbl(i).orderid = nuh.orderid
            and ordtbl(i).shipid = nuh.shipid then
               l_matched := true;
               exit;
            end if;
         end loop;
         if not l_matched then
            i := ordtbl.count + 1;
            ordtbl(i).orderid := nuh.orderid;
            ordtbl(i).shipid := nuh.shipid;
         end if;
      end if;
   end get_pick_history;

   procedure was_shlp_updated
      (in_lpid     in varchar2,
       in_status   in varchar2,
       in_begtime  in date,
       in_endtime  in date,
       out_updated out boolean,
       out_loc     out varchar2)
   is
      cursor c_sh(p_lpid varchar2, p_status varchar2) is
         select whenoccurred, status, lastupdate, location
            from shippingplatehistory
            where lpid = p_lpid
              and status = p_status
         union
         select sysdate as whenoccurred, status, lastupdate, location
            from shippingplate
            where lpid = p_lpid
              and status = p_status
         order by whenoccurred;
   begin
      out_updated := false;
      out_loc := null;
      if not lptbl.exists(in_lpid) then      -- not already updated
         for sh in c_sh(in_lpid, in_status) loop
            if sh.lastupdate between in_begtime and in_endtime then
               out_loc := sh.location;
               out_updated := true;
               exit;
            end if;
         end loop;
      end if;
   end was_shlp_updated;

   procedure do_stage_history
   is
      i binary_integer;
      l_staged boolean;
      l_begtime date := nuh.begtime;
      l_endtime date := nuh.endtime;
      l_rem userhistory_new.units%type := nvl(nuh.units,0);
      l_timeincr number;
   begin
      if l_rem = 0 then
         insert into userhistory_new values nuh;
         return;
      end if;

      l_timeincr := (l_endtime - l_begtime) / l_rem;
      for i in 1..ordtbl.count loop
         for sp in (select * from shippingplate
                     where orderid = ordtbl(i).orderid
                       and shipid = ordtbl(i).shipid
                       and parentlpid is null) loop
            was_shlp_updated(sp.lpid, 'S', l_begtime, l_endtime, l_staged, nuh.location);
            if l_staged then
               nuh.endtime := nuh.begtime + l_timeincr;
               nuh.custid := sp.custid;
               nuh.units := shlp_pickqty(sp.lpid);
               nuh.etc := l_pickparentevent;
               nuh.orderid := ordtbl(i).orderid;
               nuh.shipid := ordtbl(i).shipid;
               nuh.lpid := sp.lpid;
               nuh.item := sp.item;
               nuh.uom := shlp_pickuom(sp.lpid);
               nuh.baseuom := shlp_uom(sp.lpid);
               nuh.baseunits := sp.quantity;
               nuh.cube := shlp_cube(sp.lpid);
               nuh.weight := sp.weight;
               insert into userhistory_new values nuh;
               lptbl(sp.lpid) := 'Y';
               l_rem := l_rem - 1;
               if l_rem = 0 then
                  return;
               end if;
               nuh.begtime := nuh.endtime;
            end if;
         end loop;
      end loop;
   end do_stage_history;

   procedure do_load_history
   is
      l_loaded boolean;
      l_begtime date := nuh.begtime;
      l_endtime date := nuh.endtime;
      l_rem userhistory_new.units%type := nvl(nuh.units,0);
      l_timeincr number;
      l_loadno shippingplate.loadno%type;
      l_stopno shippingplate.stopno%type;
      l_dummy nuh.location%type;
   begin
      if pnuh.event is not null then
         pnuh.endtime := nuh.begtime;
         insert into userhistory_new values pnuh;
         pnuh := null;
      end if;

      if l_rem = 0 then
         insert into userhistory_new values nuh;
         return;
      end if;

      l_timeincr := (l_endtime - l_begtime) / l_rem;
      l_loadno := substr(nuh.etc, instr(nuh.etc, '=')+1,
            instr(nuh.etc, ' ')-(instr(nuh.etc, '=')+1));
      l_stopno := substr(nuh.etc, instr(nuh.etc, '=', 1, 2)+1,
            instr(nuh.etc, ' ', 1, 2) - (instr(nuh.etc, '=', 1, 2)+1));

      for sp in (select * from shippingplate
                  where loadno = l_loadno
                    and stopno = l_stopno
                    and parentlpid is null) loop
         was_shlp_updated(sp.lpid, 'L', l_begtime, l_endtime, l_loaded, l_dummy);
         if l_loaded then
            nuh.endtime := nuh.begtime + l_timeincr;
            nuh.custid := sp.custid;
            nuh.units := shlp_pickqty(sp.lpid);
            nuh.orderid := sp.orderid;
            nuh.shipid := sp.shipid;
            nuh.lpid := sp.lpid;
            nuh.item := sp.item;
            nuh.uom := shlp_pickuom(sp.lpid);
            nuh.baseuom := shlp_uom(sp.lpid);
            nuh.baseunits := sp.quantity;
            nuh.cube := shlp_cube(sp.lpid);
            nuh.weight := sp.weight;
            insert into userhistory_new values nuh;
            lptbl(sp.lpid) := 'Y';
            l_rem := l_rem - 1;
            if l_rem = 0 then
               return;
            end if;
            nuh.begtime := nuh.endtime;
         end if;
      end loop;
   end do_load_history;

   procedure do_unload_history
   is
      l_unloaded boolean;
      l_begtime date := nuh.begtime;
      l_endtime date := nuh.endtime;
      l_rem userhistory_new.units%type := nvl(nuh.units,0);
      l_timeincr number;
      l_loadno shippingplate.loadno%type;
      l_dummy nuh.location%type;
   begin
      if pnuh.event is not null then
         pnuh.endtime := nuh.begtime;
         insert into userhistory_new values pnuh;
         pnuh := null;
      end if;

      if l_rem = 0 then
         insert into userhistory_new values nuh;
         return;
      end if;

      l_timeincr := (l_endtime - l_begtime) / l_rem;
      l_loadno := substr(nuh.etc, instr(nuh.etc, '=', 1, 2)+1);

      for sp in (select * from shippingplate
                  where loadno = l_loadno
                    and parentlpid is null) loop
         was_shlp_updated(sp.lpid, 'S', l_begtime, l_endtime, l_unloaded, l_dummy);
         if l_unloaded then
            nuh.endtime := nuh.begtime + l_timeincr;
            nuh.custid := sp.custid;
            nuh.units := shlp_pickqty(sp.lpid);
            nuh.orderid := sp.orderid;
            nuh.shipid := sp.shipid;
            nuh.lpid := sp.lpid;
            nuh.item := sp.item;
            nuh.uom := shlp_pickuom(sp.lpid);
            nuh.baseuom := shlp_uom(sp.lpid);
            nuh.baseunits := sp.quantity;
            nuh.cube := shlp_cube(sp.lpid);
            nuh.weight := sp.weight;
            insert into userhistory_new values nuh;
            lptbl(sp.lpid) := 'Y';
            l_rem := l_rem - 1;
            if l_rem = 0 then
               return;
            end if;
            nuh.begtime := nuh.endtime;
         end if;
      end loop;
   end do_unload_history;

begin
   for uh in (select * from userhistory
               order by nameid, begtime) loop
      nuh := null;
      nuh.nameid := uh.nameid;
      nuh.begtime := uh.begtime;
      nuh.event := uh.event;
      nuh.endtime := uh.endtime;
      nuh.facility := uh.facility;
      nuh.custid := uh.custid;
      nuh.equipment := uh.equipment;
      nuh.units := uh.units;
      nuh.etc := uh.etc;
      nuh.orderid := uh.orderid;
      nuh.shipid := uh.shipid;
      nuh.location := uh.location;
      nuh.lpid := uh.lpid;
      nuh.item := uh.item;
      nuh.uom := uh.uom;

      if uh.event in ('1STP', 'ASNR') then
         l_begtime := uh.begtime;
         insert into userhistory_new values nuh;

      elsif uh.event in ('1LIP', 'ALIP') then
         get_lpid_history('U');
         nuh.begtime := l_begtime;
         l_begtime := uh.endtime;
         insert into userhistory_new values nuh;

      elsif uh.event in
            ('BAPK', 'CLIP', 'CLPK', 'CSPK', 'MIPK', 'RPPK', 'SOPK', 'STPK', 'SYPK') then
         ordtbl.delete;
         lptbl.delete;
         l_pickparentevent := uh.event;
         insert into userhistory_new values nuh;

      elsif uh.event = 'PICK' then
         get_pick_history;
         nuh.etc := l_pickparentevent;
         insert into userhistory_new values nuh;

      elsif uh.event = 'STGP' then
         do_stage_history;

      elsif uh.event = 'DKLD' then
         lptbl.delete;
         if nvl(nuh.units,0) = 0 then
            insert into userhistory_new values nuh;
         else
            pnuh := nuh;      -- save for 1st LPLD
            pnuh.units := 1;
         end if;

      elsif uh.event = 'LPLD' then
         do_load_history;

      elsif uh.event = 'DKUL' then
         lptbl.delete;
         if nvl(nuh.units,0) = 0 then
            insert into userhistory_new values nuh;
         else
            pnuh := nuh;      -- save for 1st LPUL
            pnuh.units := 1;
         end if;

      elsif uh.event = 'LPUL' then
         do_unload_history;

      elsif uh.event in ('BADT', 'DMGD', 'LLOD') then
         get_lpid_data;
         insert into userhistory_new values nuh;

      elsif uh.event = 'LPMV' then
         nuh.units := lp_timed_qty(nuh.lpid, nuh.begtime);
         get_lpid_data;
         insert into userhistory_new values nuh;

---  add some more here

      else
         insert into userhistory_new values nuh;
      end if;
   end loop;
end;
/
commit;

rename userhistory to userhistory_old;
rename userhistory_new to userhistory;

drop index userhistory_begin_event;
drop index userhistory_name_event_begin;
drop index userhistory_idx;
drop index userhistory_name_end;
drop index userhistory_name_event_end;

create index userhistory_begin_event on
   userhistory(begtime, event);

create index userhistory_name_event_begin on
   userhistory(nameid, event, begtime);

create index userhistory_idx on
   userhistory(nameid, begtime);

create index userhistory_name_end on
   userhistory(nameid, endtime);

create index userhistory_name_event_end on
   userhistory(nameid, event, endtime);

exit;
