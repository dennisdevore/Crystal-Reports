create or replace package body alps.zconsorder as
--
-- $Id$
--


-- Types


type anylptype is record (
   lpid plate.lpid%type,
   quantity plate.quantity%type,
   invstatus plate.invstatus%type,
   inventoryclass plate.inventoryclass%type,
   serialnumber plate.serialnumber%type,
   useritem1 plate.useritem1%type,
   useritem2 plate.useritem2%type,
   useritem3 plate.useritem3%type,
   parentlpid plate.parentlpid%type,
   holdreason plate.holdreason%type,
   weight plate.weight%type,
   lotnumber plate.lotnumber%type);
type anylpcur is ref cursor return anylptype;


-- Private procedures


procedure cons_pick_build_parent
   (io_plpid           in out varchar2,
    in_picktotype      in varchar2,
    in_facility        in varchar2,
    in_user            in varchar2,
    in_taskid          in number,
    in_tasktype        in varchar2,
    in_dropseq         in number,
    in_orderid         in number,
    in_shipid          in number,
    in_subtask_rowid   in varchar2,
    in_custid          in varchar2,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_pp is
      select type, status, location
         from plate
         where lpid = io_plpid;
   pp c_pp%rowtype;
   cursor c_anytote is
      select lpid
         from plate
         where facility = in_facility
           and location = in_user
           and type = 'TO'
           and status = 'M';
   cursor c_anypash(p_type varchar2) is
      select lpid
         from shippingplate
         where facility = in_facility
           and location = in_user
           and type = p_type
           and status = 'P';
   cursor c_ctn is
      select cartontype
         from subtasks
         where rowid = chartorowid(in_subtask_rowid);
   ctn c_ctn%rowtype;
   cursor c_cartons(p_mlip varchar2) is
      select lpid
         from shippingplate
         where type = 'C'
         start with lpid = p_mlip
         connect by prior lpid = parentlpid;
   l_found boolean;
   l_lptype plate.type%type;
   l_xrefid plate.lpid%type;
   l_xreftype plate.type%type;
   l_parentid plate.lpid%type;
   l_parenttype plate.type%type;
   l_topid plate.lpid%type;
   l_toptype plate.type%type;
   l_msg varchar2(80);
   l_addplp boolean := true;
   l_xlip plate.lpid%type := null;
   l_in_plpid plate.lpid%type := io_plpid;
begin
   out_error := 'N';
   out_message := null;

   if in_picktotype = 'TOTE' then
      if io_plpid is null then                           -- no tote specified?
         open c_anytote;                                 -- try to find one in use by user
         fetch c_anytote into io_plpid;
         l_found := c_anytote%found;
         close c_anytote;
         if l_found then                                 -- reuse it!
            return;
         end if;
         zrf.get_next_lpid(io_plpid, l_msg);             -- get new id
         if l_msg is not null then
            out_error := 'Y';
            out_message := l_msg;
            return;
         end if;
      else
         open c_pp;
         fetch c_pp into pp;
         l_found := c_pp%found;
         close c_pp;
      end if;

      if not l_found then                                -- build new tote
         insert into plate
            (lpid, facility, location, status, quantity, type,
             creationdate, lastoperator, lasttask, lastuser, lastupdate, weight,
             taskid, dropseq, orderid, shipid, custid)
         values
            (io_plpid, in_facility, in_user, 'A', 0, 'TO',
             sysdate, in_user, in_tasktype, in_user, sysdate, 0,
             in_taskid, in_dropseq, in_orderid, in_shipid, in_custid);
      elsif pp.type != 'TO' then                         -- existing tote
         out_message := 'LP not a Tote';
      elsif pp.status = 'A' then                         -- reuse existing tote
         update plate
            set quantity = 0,
                lasttask = 'OP',
                weight = 0,
                taskid = in_taskid,
                dropseq = in_dropseq,
                orderid = in_orderid,
                shipid = in_shipid,
                location = in_user,
                custid = in_custid
            where lpid = io_plpid;
      elsif (pp.status != 'M') or (pp.location != in_user) then
         out_message := 'Not available';
      end if;
      return;
   end if;

   if io_plpid is null then                              -- no parent shippingplate specified
      if in_picktotype = 'PACK' then                     -- try to find one in use by user
         open c_anypash('C');
      else
         open c_anypash('M');
      end if;
      fetch c_anypash into io_plpid;
      l_found := c_anypash%found;
      close c_anypash;
      -- prn 35170 - don't combine full picks onto same arbitrary master
      l_found := false;
      if l_found then                                    -- reuse it!
         return;
      end if;
      zsp.get_next_shippinglpid(io_plpid, l_msg);        -- get new id
      if l_msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;
   end if;

   zrf.identify_lp(io_plpid, l_lptype, l_xrefid, l_xreftype, l_parentid,
         l_parenttype, l_topid, l_toptype, l_msg);
   if l_msg is not null then
      out_error := 'Y';
      out_message := l_msg;
      return;
   end if;

   if in_picktotype = 'PACK' then
      open c_ctn;
      fetch c_ctn into ctn;
      if not c_ctn%found then
         ctn.cartontype := null;
      end if;
      close c_ctn;

      if l_lptype = 'C' then                             -- input was a carton
         l_addplp := false;
      elsif nvl(l_xreftype, '?') = 'C' then
         io_plpid := l_xrefid;                           -- input was xref to a carton
         l_addplp := false;
      elsif nvl(l_parenttype, '?') = 'C' then
         io_plpid := l_parentid;
         l_addplp := false;                              -- input has a carton
      elsif l_lptype = '?' then
         if substr(io_plpid, -1, 1) != 'S' then          -- kludge !!!
            zsp.get_next_shippinglpid(io_plpid, l_msg);  -- get new id
            if l_msg is not null then
               out_error := 'Y';
               out_message := l_msg;
               return;
            end if;
            l_xlip := l_in_plpid;
         end if;
      else
         if nvl(l_toptype, '?') = 'M' then               -- input has a master, any carton?
            open c_cartons(l_topid);
            fetch c_cartons into io_plpid;
            if c_cartons%notfound then
               io_plpid := null;
            end if;
            close c_cartons;
         end if;
         if io_plpid is not null then
            l_addplp := false;                           -- master had carton, use it
         else
            zsp.get_next_shippinglpid(io_plpid, l_msg);  -- get new id
            if l_msg is not null then
               out_error := 'Y';
               out_message := l_msg;
               return;
            end if;
            l_xlip := l_in_plpid;
         end if;
      end if;

      if l_addplp then
         insert into shippingplate
            (lpid, facility, location, status, quantity, type,
             lastuser, lastupdate, weight, taskid, dropseq, loadno,
             stopno, shipno,
             orderid, shipid, fromlpid, cartontype, custid)
         values
            (io_plpid, in_facility, in_user, 'P', 0, 'C',
             in_user, sysdate, 0, in_taskid, in_dropseq, cons_loadno(in_orderid, in_shipid),
             cons_stopno(in_orderid, in_shipid), cons_shipno(in_orderid, in_shipid),
             in_orderid, in_shipid, l_xlip, ctn.cartontype, in_custid);

         if l_xlip is not null then
            insert into plate
               (lpid, type, parentlpid, lastuser, lastupdate, lasttask,
                lastoperator, facility, custid)
            values
               (l_xlip, 'XP', io_plpid, in_user, sysdate, in_tasktype,
                in_user, in_facility, in_custid);
         end if;
      end if;
      return;
   end if;

   if l_lptype = 'M' then                                -- input was a master
      l_addplp := false;
   elsif nvl(l_xreftype, '?') = 'M' then
      io_plpid := l_xrefid;                              -- input was an xref to a master
      l_addplp := false;
   elsif nvl(l_toptype, '?') = 'M' then
      io_plpid := l_topid;
      l_addplp := false;                                 -- input has a master
   elsif l_lptype = '?' then
      if substr(io_plpid, -1, 1) != 'S' then             -- kludge !!!
         zsp.get_next_shippinglpid(io_plpid, l_msg);     -- get new id
         if l_msg is not null then
            out_error := 'Y';
            out_message := l_msg;
            return;
         end if;
         l_xlip := l_in_plpid;
      end if;
   else
      zsp.get_next_shippinglpid(io_plpid, l_msg);        -- get new id
      if l_msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;
   end if;


   if l_addplp then
      insert into shippingplate
         (lpid, facility, location, status, quantity, type,
          lastuser, lastupdate, weight, taskid, dropseq, loadno,
          stopno, shipno,
          orderid, shipid, fromlpid, custid)
      values
         (io_plpid, in_facility, in_user, 'P', 0, 'M',
          in_user, sysdate, 0, in_taskid, in_dropseq, cons_loadno(in_orderid, in_shipid),
          cons_stopno(in_orderid, in_shipid), cons_shipno(in_orderid, in_shipid),
          in_orderid, in_shipid, l_xlip, in_custid);

      if l_xlip is not null then
         insert into plate
            (lpid, type, parentlpid, lastuser, lastupdate, lasttask,
             lastoperator, facility, custid)
         values
            (l_xlip, 'XP', io_plpid, in_user, sysdate, in_tasktype,
             in_user, in_facility, in_custid);
      end if;
   end if;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end cons_pick_build_parent;


procedure cons_pick_update_parent
   (in_plpid    in varchar2,
    in_custid   in varchar2,
    in_item     in varchar2,
    in_lotno    in varchar2,
    in_qty      in number,
    in_weight   in number,
    out_message out varchar2)
is
   cursor c_pp is
      select custid, item, lotnumber, rowid
         from shippingplate
         where lpid = in_plpid;
   pp c_pp%rowtype;
begin
   out_message := null;

   open c_pp;
   fetch c_pp into pp;
   close c_pp;

   if nvl(in_custid, '(none)') != nvl(pp.custid, '(none)') then
      pp.custid := null;
      pp.item := null;
      pp.lotnumber := null;
   elsif nvl(in_item, '(none)') != nvl(pp.item, '(none)') then
      pp.item := null;
      pp.lotnumber := null;
   elsif nvl(in_lotno, '(none)') != nvl(pp.lotnumber, '(none)') then
      pp.lotnumber := null;
   end if;

   update shippingplate
      set item = pp.item,
          lotnumber = pp.lotnumber,
          custid = pp.custid,
          quantity = nvl(quantity, 0) + in_qty,
          weight = nvl(weight, 0) + in_weight,
          lastupdate = sysdate
      where rowid = pp.rowid;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end cons_pick_update_parent;


-- Public functions


function cons_orderid
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   l_wave waves.wave%type := null;
   l_cons waves.consolidated%type;
begin
   if nvl(in_shipid, 0) != 0 then
      begin
         select nvl(wave, 0)
            into l_wave
            from orderhdr
            where orderid = in_orderid
              and shipid = in_shipid;
      exception
         when NO_DATA_FOUND then
            return 0;
      end;
   else
      l_wave := in_orderid;
   end if;

   if l_wave != 0 then
      begin
         select upper(nvl(consolidated, 'N'))
            into l_cons
            from waves
            where wave = l_wave;
      exception
         when NO_DATA_FOUND then
            return 0;
      end;
      if l_cons != 'Y' then
         l_wave := 0;
      end if;
   end if;

   return l_wave;

exception
   when OTHERS then
      return 0;
end cons_orderid;


function cons_shiptype
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   l_shiptype waves.shiptype%type := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      select shiptype
         into l_shiptype
         from waves
         where wave = in_orderid;
   else
      select shiptype
         into l_shiptype
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return l_shiptype;

exception
   when OTHERS then
      return null;
end cons_shiptype;


function cons_carrier
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   l_carrier waves.carrier%type := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      select carrier
         into l_carrier
         from waves
         where wave = in_orderid;
   else
      select carrier
         into l_carrier
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return l_carrier;

exception
   when OTHERS then
      return null;
end cons_carrier;


function cons_ordertype
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select ordertype
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select ordertype
         into oh.ordertype
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.ordertype;

exception
   when OTHERS then
      return null;
end cons_ordertype;


function cons_componenttemplate
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select componenttemplate
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select componenttemplate
         into oh.componenttemplate
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.componenttemplate;

exception
   when OTHERS then
      return null;
end cons_componenttemplate;


function cons_multiship
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select carrier, loadno
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
   l_multiship carrier.multiship%type := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
      if oh.loadno is null then
         select nvl(C.multiship, 'N')
            into l_multiship
            from waves W, carrier C
            where W.wave = in_orderid
              and C.carrier = nvl(W.carrier, oh.carrier);
      else
         select nvl(C.multiship, 'N')
            into l_multiship
            from waves W, loads L, carrier C
            where W.wave = in_orderid
              and L.loadno (+) = oh.loadno
              and C.carrier = nvl(L.carrier, nvl(W.carrier, oh.carrier));
      end if;
   else
      select nvl(C.multiship, 'N')
         into l_multiship
         from orderhdr O, loads L, carrier C
         where O.orderid = in_orderid
           and O.shipid = in_shipid
           and L.loadno (+) = O.loadno
           and C.carrier = nvl(L.carrier, O.carrier);
   end if;
   return l_multiship;

exception
   when OTHERS then
      return null;
end cons_multiship;


function cons_orderstatus
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select orderstatus
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      if c_oh%notfound then
         oh.orderstatus := 'X';
      end if;
      close c_oh;
   else
      select orderstatus
         into oh.orderstatus
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.orderstatus;

exception
   when OTHERS then
      return null;
end cons_orderstatus;


function cons_workorderseq
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   cursor c_oh is
      select workorderseq
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select workorderseq
         into oh.workorderseq
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.workorderseq;

exception
   when OTHERS then
      return null;
end cons_workorderseq;


function cons_loadno
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   cursor c_oh is
      select loadno
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   cursor c_oh_orig is
      select loadno
         from orderhdr
         where original_wave_before_combine = in_orderid
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      if c_oh%notfound then
         close c_oh;
         open c_oh_orig;
         fetch c_oh_orig into oh;
         close c_oh_orig;
      else
      close c_oh;
      end if;
   else
      select loadno
         into oh.loadno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.loadno;

exception
   when OTHERS then
      return null;
end cons_loadno;


function cons_stopno
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   cursor c_oh is
      select stopno
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   cursor c_oh_orig is
      select stopno
         from orderhdr
         where original_wave_before_combine = in_orderid
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      if c_oh%notfound then
         close c_oh;
         open c_oh_orig;
         fetch c_oh_orig into oh;
         close c_oh_orig;
      else
      close c_oh;
      end if;
   else
      select stopno
         into oh.stopno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.stopno;

exception
   when OTHERS then
      return null;
end cons_stopno;


function cons_shipno
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   cursor c_oh is
      select shipno
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   cursor c_oh_orig is
      select shipno
         from orderhdr
         where original_wave_before_combine = in_orderid
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      if c_oh%notfound then
         close c_oh;
         open c_oh_orig;
         fetch c_oh_orig into oh;
         close c_oh_orig;
      else
      close c_oh;
      end if;
   else
      select shipno
         into oh.shipno
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.shipno;

exception
   when OTHERS then
      return null;
end cons_shipno;


function cons_invstatus
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2
is
   cursor c_od is
      select OD.invstatus
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_lotno is
      select OD.invstatus
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_item is
      select OD.invstatus
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   od c_od%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      if in_item = '(ignore)' then
         open c_od_ignore_item;
         fetch c_od_ignore_item into od;
         close c_od_ignore_item;
      elsif in_lotno = '(ignore)' then
         open c_od_ignore_lotno;
         fetch c_od_ignore_lotno into od;
         close c_od_ignore_lotno;
      else
         open c_od;
         fetch c_od into od;
         close c_od;
      end if;
   else
      if in_item = '(ignore)' then
         select invstatus
            into od.invstatus
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and rownum = 1;
      elsif in_lotno = '(ignore)' then
         select invstatus
            into od.invstatus
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and rownum = 1;
      else
         select invstatus
            into od.invstatus
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      end if;
   end if;
   return od.invstatus;

exception
   when OTHERS then
      return null;
end cons_invstatus;


function cons_invstatusind
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2
is
   cursor c_od is
      select nvl(OD.invstatusind,'x') as invstatusind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_lotno is
      select nvl(OD.invstatusind,'x') as invstatusind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_item is
      select nvl(OD.invstatusind,'x') as invstatusind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   od c_od%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      if in_item = '(ignore)' then
         open c_od_ignore_item;
         fetch c_od_ignore_item into od;
         close c_od_ignore_item;
      elsif in_lotno = '(ignore)' then
         open c_od_ignore_lotno;
         fetch c_od_ignore_lotno into od;
         close c_od_ignore_lotno;
      else
         open c_od;
         fetch c_od into od;
         close c_od;
      end if;
   else
      if in_item = '(ignore)' then
         select nvl(invstatusind,'x') as invstatusind
            into od.invstatusind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and rownum = 1;
      elsif in_lotno = '(ignore)' then
         select nvl(invstatusind,'x') as invstatusind
            into od.invstatusind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and rownum = 1;
      else
         select nvl(invstatusind,'x') as invstatusind
            into od.invstatusind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      end if;
   end if;
   return nvl(od.invstatusind,'x');

exception
   when OTHERS then
      return null;
end cons_invstatusind;


function cons_inventoryclass
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2
is
   cursor c_od is
      select OD.inventoryclass
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_lotno is
      select OD.inventoryclass
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_item is
      select OD.inventoryclass
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   od c_od%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      if in_item = '(ignore)' then
         open c_od_ignore_item;
         fetch c_od_ignore_item into od;
         close c_od_ignore_item;
      elsif in_lotno = '(ignore)' then
         open c_od_ignore_lotno;
         fetch c_od_ignore_lotno into od;
         close c_od_ignore_lotno;
      else
         open c_od;
         fetch c_od into od;
         close c_od;
      end if;
   else
      if in_item = '(ignore)' then
         select inventoryclass
            into od.inventoryclass
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and rownum = 1;
      elsif in_lotno = '(ignore)' then
         select inventoryclass
            into od.inventoryclass
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and rownum = 1;
      else
         select inventoryclass
            into od.inventoryclass
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      end if;
   end if;
   return od.inventoryclass;

exception
   when OTHERS then
      return null;
end cons_inventoryclass;


function cons_invclassind
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2
is
   cursor c_od is
      select OD.invclassind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_lotno is
      select OD.invclassind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   cursor c_od_ignore_item is
      select OD.invclassind
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OH.orderstatus != 'X'
         order by OH.orderid, OH.shipid;
   od c_od%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      if in_item = '(ignore)' then
         open c_od_ignore_item;
         fetch c_od_ignore_item into od;
         close c_od_ignore_item;
      elsif in_lotno = '(ignore)' then
         open c_od_ignore_lotno;
         fetch c_od_ignore_lotno into od;
         close c_od_ignore_lotno;
      else
         open c_od;
         fetch c_od into od;
         close c_od;
      end if;
   else
      if in_item = '(ignore)' then
         select invclassind
            into od.invclassind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and rownum = 1;
      elsif in_lotno = '(ignore)' then
         select invclassind
            into od.invclassind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and rownum = 1;
      else
         select invclassind
            into od.invclassind
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      end if;
   end if;
   return od.invclassind;

exception
   when OTHERS then
      return null;
end cons_invclassind;


function cons_custid
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select custid
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select custid
         into oh.custid
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.custid;

exception
   when OTHERS then
      return null;
end cons_custid;


function cons_fromfacility
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select fromfacility
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select fromfacility
         into oh.fromfacility
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.fromfacility;

exception
   when OTHERS then
      return null;
end cons_fromfacility;


function cons_qtycommit
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   l_qtycommit orderhdr.qtycommit%type := 0;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      select sum(qtycommit)
         into l_qtycommit
         from orderhdr
         where wave = in_orderid
            or original_wave_before_combine = in_orderid;
   else
      select qtycommit
         into l_qtycommit
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return l_qtycommit;

exception
   when OTHERS then
      return null;
end cons_qtycommit;


function cons_qty2check
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   l_qty2check orderhdr.qty2check%type := 0;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      select sum(qty2check)
         into l_qty2check
         from orderhdr
         where wave = in_orderid
            or original_wave_before_combine = in_orderid;
   else
      select qty2check
         into l_qty2check
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return l_qty2check;

exception
   when OTHERS then
      return null;
end cons_qty2check;


function cons_shipto
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select shipto
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select shipto
         into oh.shipto
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.shipto;

exception
   when OTHERS then
      return null;
end cons_shipto;


function cons_consignee
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select nvl(shipto, consignee) as consignee
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and orderstatus != 'X'
         order by orderid, shipid;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      close c_oh;
   else
      select nvl(shipto, consignee)
         into oh.consignee
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return oh.consignee;

exception
   when OTHERS then
      return null;
end cons_consignee;


function cons_any_hdr_rfautodisplay
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   cursor c_oh is
      select rfautodisplay
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and nvl(rfautodisplay, 'N') = 'Y'
           and comment1 is not null;
   oh c_oh%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_oh;
      fetch c_oh into oh;
      if c_oh%notfound then
         oh.rfautodisplay := 'N';
      end if;
      close c_oh;
   else
      begin
         select nvl(rfautodisplay, 'N')
            into oh.rfautodisplay
            from orderhdr
            where orderid = in_orderid
              and shipid = in_shipid
              and comment1 is not null;
      exception
         when NO_DATA_FOUND then
            oh.rfautodisplay := 'N';
      end;
   end if;
   return oh.rfautodisplay;

exception
   when OTHERS then
      return 'N';
end cons_any_hdr_rfautodisplay;


function cons_any_dtl_rfautodisplay
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return varchar2
is
   cursor c_od is
      select OD.rfautodisplay
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and nvl(OD.rfautodisplay, 'N') = 'Y'
           and OD.comment1 is not null;
   od c_od%rowtype := null;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      open c_od;
      fetch c_od into od;
      if c_od%notfound then
         od.rfautodisplay := 'N';
      end if;
      close c_od;
   else
      begin
         select nvl(rfautodisplay, 'N')
            into od.rfautodisplay
            from orderdtl
            where orderid = in_orderid
              and shipid = in_shipid
              and item = in_item
              and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
              and comment1 is not null;
      exception
         when NO_DATA_FOUND then
            od.rfautodisplay := 'N';
      end;
   end if;
   return od.rfautodisplay;

exception
   when OTHERS then
      return 'N';
end cons_any_dtl_rfautodisplay;


function cons_hdr_comments_len
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   cursor c_oh is
      select comment1
         from orderhdr
         where (wave = in_orderid
            or original_wave_before_combine = in_orderid)
           and comment1 is not null;
   l_comment long;
   l_len number := 0;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      for s in c_oh loop
         l_len := l_len + nvl(length(s.comment1), 0)
               + 20 - mod(nvl(length(s.comment1), 0), 20);
      end loop;
      return l_len;
   else
      select comment1
         into l_comment
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
      return nvl(length(l_comment), 0);
   end if;

exception
   when OTHERS then
      return 0;
end cons_hdr_comments_len;


function cons_dtl_comments_len
   (in_orderid  in number,
    in_shipid   in number,
    in_item     in varchar2,
    in_lotno    in varchar2)
return number
is
   cursor c_od is
      select OD.comment1
         from orderdtl OD, orderhdr OH
         where (OH.wave = in_orderid
            or OH.original_wave_before_combine = in_orderid)
           and OD.orderid = OH.orderid
           and OD.shipid = OH.shipid
           and OD.item = in_item
           and nvl(OD.lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and OD.comment1 is not null;
   l_comment long;
   l_len number := 0;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      for s in c_od loop
         l_len := l_len + nvl(length(s.comment1), 0)
               + 20 - mod(nvl(length(s.comment1), 0), 20);
      end loop;
      return l_len;
   else
      select comment1
         into l_comment
         from orderdtl
         where orderid = in_orderid
           and shipid = in_shipid
           and item = in_item
           and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)');
      return nvl(length(l_comment), 0);
   end if;

exception
   when OTHERS then
      return 0;
end cons_dtl_comments_len;


-- Public procedures


procedure cons_plate_pick
   (in_taskid          in number,
    in_user            in varchar2,
    in_plannedlp       in varchar2,
    in_pickedlp        in varchar2,
    in_custid          in varchar2,
    in_item            in varchar2,
    in_orderitem       in varchar2,
    in_lotno           in varchar2,
    in_orderid         in number,
    in_shipid          in number,
    in_qty             in number,
    in_dropseq         in number,
    in_pickfac         in varchar2,
    in_pickloc         in varchar2,
    in_lplotno         in varchar2,
    in_mlip            in varchar2,
    in_tasktype        in varchar2,
    in_picktotype      in varchar2,
    in_fromloc         in varchar2,
    in_subtask_rowid   in varchar2,
    in_extra_process   in varchar2,
    in_picked_child    in varchar2,
    in_pkd_lotno       in varchar2,
    in_pkd_serialno    in varchar2,
    in_pkd_user1       in varchar2,
    in_pkd_user2       in varchar2,
    in_pkd_user3       in varchar2,
    out_lpcount        out number,
    out_error          out varchar2,
    out_message        out varchar2)
is
   cursor c_bt is
      select BT.qty, BT.pickuom, BT.uom, BT.pickqty, BT.orderid, BT.shipid,
             BT.orderitem, BT.item, BT.inventoryclass, BT.invstatus, BT.custid,
             BT.orderlot, BT.loadno, BT.stopno, BT.shipno, BT.rowid,
             OH.ordertype, nvl(CIV.ordercheckrequired, 'N') checkreqd,
             CIV.serialrequired, CIV.user1required, CIV.user2required,
             CIV.user3required, CIV.serialasncapture, CIV.user1asncapture,
             CIV.user2asncapture, CIV.user3asncapture, BT.cartonseq, BT.cartontype,
             CIV.track_picked_pf_lps
         from batchtasks BT, orderhdr OH, custitemview CIV
         where BT.taskid = in_taskid
           and BT.custid = in_custid
           and BT.orderitem = in_orderitem
           and nvl(BT.orderlot,'(none)') = nvl(in_lotno,'(none)')
           and BT.item = in_item
           and nvl(BT.lpid,'(none)') = nvl(in_plannedlp,'(none)')
           and nvl(BT.fromloc,'(none)') = nvl(in_fromloc,'(none)')
           and OH.orderid = BT.orderid
           and OH.shipid = BT.shipid
           and CIV.custid = in_custid
           and CIV.item = in_item
         order by BT.orderid, BT.shipid;
   cursor c_lp(p_lpid varchar2) is
      select quantity, parentlpid, lotnumber, useritem1, useritem2, useritem3,
             serialnumber, inventoryclass, invstatus, holdreason, weight,
             manufacturedate, expirationdate, qtyrcvd
         from plate
         where lpid = p_lpid;
   pik c_lp%rowtype;
   od orderdtl%rowtype;
   l_remaining subtasks.qty%type;
   l_commitqty commitments.qty%type;
   l_rowid rowid;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_packqty orderdtl.qty2pack%type;
   l_packamtqty orderdtl.qty2pack%type;
   l_checkqty orderdtl.qty2check%type;
   l_checkamtqty orderdtl.qty2check%type;
   l_errmsg varchar2(200);
   l_parentlpid shippingplate.lpid%type;
   l_pickedlp plate.lpid%type;
   l_pickedlot plate.lotnumber%type;
   l_itemlot plate.lotnumber%type;
   c_any_lp anylpcur;
   l anylptype;
   l_qty subtasks.qty%type;
   l_type shippingplate.type%type;
   l_shlpid shippingplate.lpid%type;
   l_fromlpid plate.lpid%type;
   l_cloneid plate.lpid%type;
   l_weightpick orderdtl.weightpick%type;
   l_pickqty subtasks.pickqty%type;
   l_pickuom subtasks.pickuom%type;
   l_qty_pickuom subtasks.pickqty%type;
   l_qtypicked shippingplate.quantity%type;
   l_weight orderdtl.weightpick%type;
begin
   out_error := 'N';
   out_message := null;

   l_parentlpid := in_mlip;
   cons_pick_build_parent(l_parentlpid, in_picktotype, in_pickfac, in_user,
         in_taskid, in_tasktype, in_dropseq, in_orderid, in_shipid, in_subtask_rowid,
         in_custid, l_err, l_msg);
   if l_msg is not null then
      out_error := l_err;
      out_message := l_msg;
      return;
   end if;

   if nvl(in_extra_process, '?') in ('1', '2') then
      l_pickedlp := in_picked_child;
   else
      l_pickedlp := in_pickedlp;
   end if;
   l_pickedlot := in_lplotno;
   if l_pickedlp is not null then
      open c_lp(l_pickedlp);
      fetch c_lp into pik;
      close c_lp;
      if (in_lplotno is null) and (pik.lotnumber is not null) then
         l_pickedlot := pik.lotnumber;
      end if;
   end if;
   l_itemlot := nvl(l_pickedlot, in_lotno);

   l_remaining := in_qty;

   for bt in c_bt loop
      l_qty := least(bt.qty, l_remaining);

      if bt.qty = l_qty then
         delete from batchtasks
            where rowid = bt.rowid;
      else
         update batchtasks
            set qty = bt.qty - l_qty,
                pickuom = bt.uom,
                pickqty = bt.qty - l_qty
            where rowid = bt.rowid;
         bt.pickuom := bt.uom;
         bt.pickqty := l_qty;
         bt.qty := l_qty;
      end if;

      update orderhdr
         set orderstatus = zrf.ORD_PICKING,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = bt.orderid
           and shipid = bt.shipid
           and orderstatus < zrf.ORD_PICKING;

      if bt.loadno is not null then
         update loads
            set loadstatus = zrf.LOD_PICKING,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = bt.loadno
              and loadstatus < zrf.LOD_PICKING;
         update loadstop
            set loadstopstatus = zrf.LOD_PICKING,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = bt.loadno
              and stopno = bt.stopno
              and loadstopstatus < zrf.LOD_PICKING;
      end if;

      if (in_picktotype = 'TOTE') and (bt.ordertype != 'K') then
         l_packqty := bt.pickqty;
         l_packamtqty := bt.qty;
         l_checkqty := 0;
         l_checkamtqty := 0;
      elsif (bt.checkreqd = 'Y') and (bt.ordertype != 'K') then
         l_packqty := 0;
         l_packamtqty := 0;
         l_checkqty := bt.pickqty;
         l_checkamtqty := bt.qty;
      end if;

      update commitments
         set qty = qty - bt.qty,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = bt.orderid
           and shipid = bt.shipid
           and orderitem = bt.orderitem
           and nvl(orderlot, '(none)') = nvl(in_lotno, '(none)')
           and item = bt.item
           and nvl(lotnumber, '(none)') = nvl(in_lotno, '(none)')
           and inventoryclass = bt.inventoryclass
           and invstatus = bt.invstatus
           and status = 'CM'
         returning qty, rowid into l_commitqty, l_rowid;
      if (sql%rowcount != 0) and (l_commitqty <= 0) then
         delete commitments
            where rowid = l_rowid;
         if l_commitqty < 0 then
            l_msg := null;
            zms.log_msg('PICK_CORD', in_pickfac, bt.custid,
                  'orderid=' || bt.orderid || ' shipid=' || bt.shipid
                  || ' orderitem=' || bt.orderitem || ' item=' || bt.item
                  || ' lot=' || in_lotno || ' class=' || bt.inventoryclass
                  || ' status=' || bt.invstatus || ' remqty=' || l_commitqty, 'W',
                  in_user, l_msg);
         end if;
      end if;

      l_weightpick := bt.pickqty * zci.item_weight(bt.custid, bt.item, bt.pickuom);
      if in_tasktype = 'SO' then
         update orderdtl
            set qty2sort = nvl(qty2sort, 0) - bt.qty,
                weight2sort = nvl(weight2sort, 0) - l_weightpick,
                cube2sort = nvl(cube2sort, 0) - (bt.pickqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                qty2pack = nvl(qty2pack, 0) + l_packamtqty,
                weight2pack = nvl(weight2pack, 0)
                     + l_packqty * zci.item_weight(bt.custid, bt.item, bt.pickuom),
                cube2pack = nvl(cube2pack, 0)
                     + (l_packqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                amt2pack = nvl(amt2pack, 0)
                     + (l_packamtqty * zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot)),
                qty2check = nvl(qty2check, 0) + l_checkamtqty,
                weight2check = nvl(weight2check, 0)
                     + l_checkqty * zci.item_weight(bt.custid, bt.item, bt.pickuom),
                cube2check = nvl(cube2check, 0)
                     + (l_checkqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                amt2check = nvl(amt2check, 0)
                     + (l_checkamtqty * zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot)),
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = bt.orderid
              and shipid = bt.shipid
              and item = bt.orderitem
              and nvl(lotnumber, '(none)') = nvl(bt.orderlot, '(none)')
            returning invstatusind, invstatus, invclassind, inventoryclass,
                      qtyentered, uomentered
            into od.invstatusind, od.invstatus, od.invclassind, od.inventoryclass,
                 od.qtyentered, od.uomentered;
      else
         update orderdtl
            set qtypick = nvl(qtypick, 0) + bt.qty,
                weightpick = nvl(weightpick, 0) + l_weightpick,
                cubepick = nvl(cubepick, 0)
                     + (bt.pickqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                amtpick = nvl(amtpick, 0)
                     + (bt.qty * zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot)), --prn 25133
                qty2pack = nvl(qty2pack, 0) + l_packamtqty,
                weight2pack = nvl(weight2pack, 0)
                     + l_packqty * zci.item_weight(bt.custid, bt.item, bt.pickuom),
                cube2pack = nvl(cube2pack, 0)
                     + (l_packqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                amt2pack = nvl(amt2pack, 0)
                     + (l_packamtqty * zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot)), --prn 25133
                qty2check = nvl(qty2check, 0) + l_checkamtqty,
                weight2check = nvl(weight2check, 0)
                     + l_checkqty * zci.item_weight(bt.custid, bt.item, bt.pickuom),
                cube2check = nvl(cube2check, 0)
                     + (l_checkqty * zci.item_cube(bt.custid, bt.item, bt.pickuom)),
                amt2check = nvl(amt2check, 0)
                     + (l_checkamtqty * zci.item_amt(bt.custid, bt.orderid, bt.shipid, bt.item, bt.orderlot)), --prn 25133
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = bt.orderid
              and shipid = bt.shipid
              and item = bt.orderitem
              and nvl(lotnumber, '(none)') = nvl(bt.orderlot, '(none)')
            returning invstatusind, invstatus, invclassind, inventoryclass,
                      qtyentered, uomentered
            into od.invstatusind, od.invstatus, od.invclassind, od.inventoryclass,
                 od.qtyentered, od.uomentered;
      end if;

      zsp.get_next_shippinglpid(l_shlpid, l_msg);
      if l_msg is not null then
         out_error := 'Y';
         out_message := l_msg;
         return;
      end if;

      l_type := 'P';
      if l_pickedlp is not null then         -- update picked plate
         l_fromlpid := l_pickedlp;
         if bt.qty > pik.quantity then
            out_message := 'Qty not avail';
            return;
         end if;

         if bt.qty = pik.quantity then    -- full pick of remaining
            l_type := 'F';
            if nvl(in_extra_process, '?') != '2' then
               update plate
                  set status = 'P',
                      location = in_user,
                      lasttask = in_tasktype,
                      taskid = in_taskid,
                      lastoperator = in_user,
                      lastuser = in_user,
                      lastupdate = sysdate,
                      fromshippinglpid = decode(in_picktotype, 'TOTE', l_shlpid, null)
                  where lpid in (select lpid from plate
                                    start with lpid = l_pickedlp
                                    connect by prior lpid = parentlpid);
               if pik.parentlpid is not null then
                  zplp.detach_child_plate(pik.parentlpid, l_pickedlp, in_user, null,
                        null, 'P', in_user, in_tasktype, l_msg);
                  if l_msg is not null then
                     out_error := 'Y';
                     out_message := l_msg;
                     return;
                  end if;
               end if;
            end if;
         else
            zrf.decrease_lp(l_pickedlp, bt.custid, bt.item, bt.qty, l_itemlot,
                  bt.uom, in_user, in_tasktype, bt.invstatus, bt.inventoryclass, l_err, l_msg);
            if l_msg is not null then
               out_error := l_err;
               out_message := l_msg;
               return;
            end if;
         end if;
         pik.quantity := pik.quantity - bt.qty;
         l_cloneid := l_pickedlp;
      else                                -- find plate(s) to pick
         l_fromlpid := null;
         if l_itemlot is null then
            open c_any_lp for
               select lpid, quantity, invstatus, inventoryclass, serialnumber,
                      useritem1, useritem2, useritem3, parentlpid, holdreason, weight,
                      lotnumber
                  from plate
                  where facility = in_pickfac
                    and location = in_pickloc
                    and custid = bt.custid
                    and item = bt.item
                    and unitofmeasure = bt.uom
                    and type = 'PA'
                    and status = 'A'
                  order by manufacturedate, creationdate;
         else
            open c_any_lp for
               select lpid, quantity, invstatus, inventoryclass, serialnumber,
                      useritem1, useritem2, useritem3, parentlpid, holdreason, weight,
                      lotnumber
                  from plate
                  where facility = in_pickfac
                    and location = in_pickloc
                    and custid = bt.custid
                    and item = bt.item
                    and lotnumber = l_itemlot
                    and unitofmeasure = bt.uom
                    and type = 'PA'
                    and status = 'A'
                  order by manufacturedate, creationdate;
         end if;

         l_qty := bt.qty;
         loop
            fetch c_any_lp into l;
            exit when c_any_lp%notfound;

            if ((l.serialnumber is not null
                  and bt.serialrequired != 'Y' and bt.serialasncapture = 'Y')
            or  (l.useritem1 is not null
                  and bt.user1required != 'Y' and bt.user1asncapture = 'Y')
            or  (l.useritem2 is not null
                  and bt.user2required != 'Y' and bt.user2asncapture = 'Y')
            or  (l.useritem3 is not null
                  and bt.user3required != 'Y' and bt.user3asncapture = 'Y')
            or  (zrf.any_tasks_for_lp(l.lpid, l.parentlpid))) then
               goto continue_loop;
            end if;

            if (zrfpk.is_attrib_ok(od.invstatusind, od.invstatus, l.invstatus)
            and zrfpk.is_attrib_ok(od.invclassind, od.inventoryclass, l.inventoryclass)) then

               l_qtypicked := least(l.quantity, l_qty);
               l_qty := l_qty - l_qtypicked;

               if nvl(bt.track_picked_pf_lps,'N') = 'Y' then
                  if in_picktotype = 'TOTE' then
                     l_msg := null;
                     if l.quantity > l_qtypicked then
--                      only need part of plate
                        l_weight := l_qtypicked * (l.weight / l.quantity);
                        zplp.clone_lp(l.lpid, in_user, 'M', l_qtypicked, l_weight, in_user,
                              in_tasktype, null, in_taskid, l_shlpid, in_dropseq, l_cloneid,
                              l_msg);
                        if l_msg is null then
                           zrf.decrease_lp(l.lpid, bt.custid, bt.item, l_qtypicked,
                                 l_itemlot, bt.uom, in_user, in_tasktype, l.invstatus,
                                 l.inventoryclass, l_err, l_msg);
                        end if;
                     else
                        l_cloneid := l.lpid;
                     end if;

                     if l_msg is null then
                        zplp.attach_child_plate(l_parentlpid, l_cloneid, in_user, 'M', in_user,
                              l_msg);
                     end if;
                     if l_msg is not null then
                        out_error := 'Y';
                        out_message := l_msg;
                        close c_any_lp;
                        return;
                     end if;
                     update subtasks
                        set shippinglpid = l_parentlpid
                        where rowid = chartorowid(in_subtask_rowid)
                          and shippinglpid is null;               -- only save 1st for staging
                  else
                     zrf.decrease_lp(l.lpid, bt.custid, bt.item, l_qtypicked,
                           l_itemlot, bt.uom, in_user, in_tasktype, l.invstatus,
                           l.inventoryclass, l_err, l_msg);
                     if l_msg is not null then
                        out_error := l_err;
                        out_message := l_msg;
                        close c_any_lp;
                        return;
                     end if;

                     update subtasks
                        set shippinglpid = l_shlpid
                        where rowid = chartorowid(in_subtask_rowid)
                          and shippinglpid is null;               -- only save 1st for staging

                  end if;

--                convert baseuom qty into pickuom qty
                  l_qty_pickuom := zlbl.uom_qty_conv(bt.custid, bt.item, l_qtypicked,
                        bt.uom, bt.pickuom);
--                if exact conversion use pickuom else baseuom
                  if l_qtypicked = zlbl.uom_qty_conv(bt.custid, bt.item, l_qty_pickuom,
                        bt.pickuom, bt.uom) then
                     l_pickqty := l_qty_pickuom;
                     l_pickuom := bt.pickuom;
                  else
                     l_pickqty := l_qtypicked;
                     l_pickuom := bt.uom;
                  end if;
                  l_weight := l_pickqty * zci.item_weight(bt.custid, bt.item, l_pickuom);

                  insert into shippingplate
                     (lpid, item, custid, facility, location,
                      status, holdreason, unitofmeasure, quantity, type,
                      fromlpid, serialnumber,
                      lotnumber,
                      parentlpid,
                      useritem1, useritem2,
                      useritem3, lastuser, lastupdate, invstatus,
                      qtyentered, orderitem, uomentered, inventoryclass, loadno,
                      stopno, shipno, orderid, shipid, weight,
                      ucc128, labelformat, taskid, dropseq, orderlot,
                      pickuom, pickqty, trackingno, cartonseq, checked,
                      totelpid, cartontype,
                      pickedfromloc, shippingcost, carriercodeused,
                      satdeliveryused, openfacility, audited, prevlocation, fromlpidparent,
                      rmatrackingno, actualcarrier, manufacturedate, expirationdate,
                      origfromlpqty)
                  values
                     (l_shlpid, bt.item, bt.custid, in_pickfac, in_user,
                      'P', pik.holdreason, bt.uom, l_qtypicked, l_type,
                      l.lpid, nvl(in_pkd_serialno, l.serialnumber),
                      nvl(in_pkd_lotno, l.lotnumber),
                      decode(in_picktotype, 'TOTE', null, l_parentlpid),
                      nvl(in_pkd_user1, l.useritem1), nvl(in_pkd_user2, l.useritem2),
                      nvl(in_pkd_user3, l.useritem3), in_user, sysdate, l.invstatus,
                      l_qtypicked, bt.orderitem, bt.uom, l.inventoryclass, bt.loadno,
                      bt.stopno, bt.shipno, bt.orderid, bt.shipid, l_weight,
                      null, null, in_taskid, in_dropseq, bt.orderlot,
                      l_pickuom, l_pickqty, null, bt.cartonseq, null,
                      decode(in_picktotype, 'TOTE', l_parentlpid, null), bt.cartontype,
                      in_pickloc, null, null,
                      null, null, null, null, l.parentlpid,
                      null, null, pik.manufacturedate, pik.expirationdate,
                      decode(in_tasktype,'OP',pik.qtyrcvd,'PK',pik.qtyrcvd,null));

                  cons_pick_update_parent(l_parentlpid, bt.custid, bt.item, nvl(in_pkd_lotno,
                        l.lotnumber), l_qtypicked, l_weight, l_msg);
                  if l_msg is not null then
                     out_error := 'Y';
                     out_message := l_msg;
                     close c_any_lp;
                     return;
                  end if;
                  if l_qty != 0 then
                     zsp.get_next_shippinglpid(l_shlpid, l_msg);
                     if l_msg is not null then
                        out_error := 'Y';
                        out_message := l_msg;
                        close c_any_lp;
                        return;
                     end if;
                  end if;
               else
                  if l_fromlpid is null then
                     l_fromlpid := l.lpid;
                     pik.serialnumber := l.serialnumber;
                     pik.useritem1 := l.useritem1;
                     pik.useritem2 := l.useritem2;
                     pik.useritem3 := l.useritem3;
                     pik.invstatus := l.invstatus;
                     pik.inventoryclass := l.inventoryclass;
                     pik.parentlpid := l.parentlpid;
                     pik.holdreason := l.holdreason;
                     /*
                     -- not sure why you would have the below unless you turned the pick into a full pick, put the below plates in picked
                     --   status, and let them delete automatically upon ship
                     zplp.clone_lp(l.lpid, in_user, 'M', bt.qty, l_weightpick, in_user,
                        in_tasktype, null, in_taskid, l_shlpid, in_dropseq, l_cloneid, l_msg);
                     if l_msg is not null then
                        out_error := 'Y';
                        out_message := l_msg;
                        close c_any_lp;
                        return;
                     end if;
                     */
                  end if;
                  zrf.decrease_lp(l.lpid, bt.custid, bt.item, l_qtypicked,
                        l_itemlot, bt.uom, in_user, in_tasktype, l.invstatus,
                        l.inventoryclass, l_err, l_msg);
                  if l_msg is not null then
                     out_error := l_err;
                     out_message := l_msg;
                     close c_any_lp;
                     return;
                  end if;
               end if;
               exit when (l_qty = 0);
            end if;
         <<continue_loop>>
            null;
         end loop;
         close c_any_lp;
         if l_qty != 0 then
            out_message := 'Qty not avail';
            return;
         end if;
      end if;

      if (nvl(bt.track_picked_pf_lps,'N') != 'Y')
      or (l_pickedlp is not null) then
         insert into shippingplate
            (lpid, item, custid, facility, location,
             status, holdreason, unitofmeasure, quantity, type,
             fromlpid, serialnumber, lotnumber,
             parentlpid, useritem1,
             useritem2, useritem3, lastuser,
             lastupdate, invstatus, qtyentered, orderitem, uomentered,
             inventoryclass, loadno, stopno, shipno, orderid, shipid,
             weight, ucc128, labelformat,
             taskid, dropseq, orderlot, pickuom, pickqty,
             trackingno, cartonseq, checked,
             totelpid, cartontype,
             pickedfromloc, shippingcost, carriercodeused, satdeliveryused, openfacility,
             audited, prevlocation, fromlpidparent, rmatrackingno, actualcarrier,
             origfromlpqty)
         values
            (l_shlpid, bt.item, bt.custid, in_pickfac, in_user,
             'P', pik.holdreason, bt.uom, bt.qty, l_type,
             l_fromlpid, nvl(in_pkd_serialno, pik.serialnumber), nvl(in_pkd_lotno, l_pickedlot),
             decode(in_picktotype, 'TOTE', null, l_parentlpid), nvl(in_pkd_user1, pik.useritem1),
             nvl(in_pkd_user2, pik.useritem2), nvl(in_pkd_user3, pik.useritem3), in_user,
             sysdate, pik.invstatus, od.qtyentered, bt.orderitem, od.uomentered,
             pik.inventoryclass, bt.loadno, bt.stopno, bt.shipno, bt.orderid, bt.shipid,
             l_weightpick, null, null,
             in_taskid, in_dropseq, bt.orderlot, bt.pickuom, bt.pickqty,
             null, bt.cartonseq, null,
             decode(in_picktotype, 'TOTE', l_parentlpid, null), bt.cartontype,
             in_pickloc, null, null, null, null,
			 null, null, pik.parentlpid, null, null,
			 decode(in_tasktype,'OP',pik.qtyrcvd,'PK',pik.qtyrcvd,null));

         if in_picktotype = 'TOTE' then
            zplp.attach_child_plate(l_parentlpid, l_cloneid, in_user, 'M', in_user, l_msg);
         else
            cons_pick_update_parent(l_parentlpid, bt.custid, bt.item, nvl(in_pkd_lotno,
                  l_pickedlot), bt.qty, l_weightpick, l_msg);
         end if;
         if l_msg is not null then
            out_error := 'Y';
            out_message := l_msg;
            return;
         end if;
         update subtasks
            set shippinglpid = l_shlpid
            where rowid = chartorowid(in_subtask_rowid)
              and shippinglpid is null;               -- only save 1st for staging
      end if;

      zoh.add_orderhistory_item(bt.orderid, bt.shipid,
            l_shlpid, bt.item, in_lotno,
            'Pick Cord',
            'Pick Qty:'||bt.qty||' from LP:'||in_pickedlp,
            in_user, l_errmsg);

--    update pick counts
      update location
         set pickcount = nvl(pickcount, 0) + 1,
             lastpickedfrom = sysdate
         where facility = in_pickfac
           and locid = in_pickloc;

      update itempickfronts
         set lastpickeddate = sysdate
         where facility = in_pickfac
           and pickfront = in_pickloc;

      select count(1) into out_lpcount
         from plate
         where facility = in_pickfac
           and location = in_pickloc
           and type = 'PA'
           and status != 'P';

      update subtasks
         set qtypicked = nvl(qtypicked, 0) + bt.qty
            where rowid = chartorowid(in_subtask_rowid);

      zrfpk.bump_custitemcount(bt.custid, bt.item, 'PICK', bt.uom, bt.qty, in_user,
            l_err, l_msg);
      if l_msg is not null then
         out_error := l_err;
         out_message := l_msg;
         return;
      end if;

      l_remaining := l_remaining - bt.qty;
      exit when l_remaining = 0;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end cons_plate_pick;

function cons_shipped
   (in_orderid  in number,       -- orderid or wave
    in_shipid   in number)       -- shipid or 0 wave
return number                    -- 0 Not Cons Shipped, 1 Cons All Shipped
is
  cord orderhdr.orderid%type;
  cnt integer;
begin

  cord := zcord.cons_orderid(in_orderid, in_shipid);

  if nvl(cord,0) > 0 then
    cnt := 0;
    select count(1)
      into cnt
      from orderhdr
     where (wave = cord
        or original_wave_before_combine = cord)
       and orderstatus not in ('9','X');

    if nvl(cnt,0) = 0 then
        return 1;
    end if;

  end if;

  return 0;

end cons_shipped;


procedure cons_dec_batchtasks
   (in_taskid    in number,
    in_custid    in varchar2,
    in_orderitem in varchar2,
    in_lotno     in varchar2,
    in_item      in varchar2,
    in_plannedlp in varchar2,
    in_fromloc   in varchar2,
    in_qty       in number,
    out_message  out varchar2)
is
   cursor c_bt is
      select qty, uom, rowid
         from batchtasks
         where taskid = in_taskid
           and custid = in_custid
           and orderitem = in_orderitem
           and nvl(orderlot,'(none)') = nvl(in_lotno,'(none)')
           and item = in_item
           and nvl(lpid,'(none)') = nvl(in_plannedlp,'(none)')
           and nvl(fromloc,'(none)') = nvl(in_fromloc,'(none)')
         order by orderid, shipid desc;
   l_remaining subtasks.qty%type := in_qty;
   l_qty subtasks.qty%type;
begin
   out_message := null;

   for bt in c_bt loop
      l_qty := least(bt.qty, l_remaining);

      if bt.qty = l_qty then
         delete from batchtasks
            where rowid = bt.rowid;
      else
         update batchtasks
            set qty = bt.qty - l_qty,
                pickuom = bt.uom,
                pickqty = bt.qty - l_qty
            where rowid = bt.rowid;
      end if;

      l_remaining := l_remaining - bt.qty;
      exit when l_remaining = 0;
   end loop;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end cons_dec_batchtasks;


function cons_manual_picks
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
   l_manual_picks orderhdr.manual_picks_yn%type;
begin
   if (in_orderid = cons_orderid(in_orderid, in_shipid)) and (in_orderid != 0) then
      l_manual_picks := 'N';
   else
      select nvl(manual_picks_yn,'N')
         into l_manual_picks
         from orderhdr
         where orderid = in_orderid
           and shipid = in_shipid;
   end if;
   return l_manual_picks;

exception
   when OTHERS then
      return null;
end cons_manual_picks;

end zconsorder;
/

show errors package body zconsorder;
exit;
