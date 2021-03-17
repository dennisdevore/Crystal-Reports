create or replace package body alps.zputaway as
--
-- $Id$
--


-- constants


RBLDMP_ID               CONSTANT    varchar2(11) := 'FIX_PUTAWAY';
PUTAWAY_DEFAULT_QUEUE   CONSTANT    varchar2(7) := 'putaway';
USER_DEFAULT_QUEUE      CONSTANT    varchar2(5) := 'userq';

-- Types


type rbldmptbltype is table of plate.lpid%type index by binary_integer;


-- Global variables


rbldmp_tbl rbldmptbltype;


-- Private procedures


procedure update_rbldmp_tbl
   (in_lpid   in varchar2,
    out_found out boolean)
is
   i binary_integer;
begin
   out_found := true;
   for i in 1..rbldmp_tbl.count loop
      if (rbldmp_tbl(i) = in_lpid) then
         return;
      end if;
   end loop;
   rbldmp_tbl(rbldmp_tbl.count+1) := in_lpid;
   out_found := false;
end update_rbldmp_tbl;


-- Public functions


function is_putaway_loc_restricted
   (in_lpid  in varchar2,
    in_loc   in varchar2)
return varchar2
is
   cursor c_lp(p_lpid varchar2) is
      select LP.facility,
             FA.restrict_putaway
         from plate LP, facility FA
         where LP.lpid = p_lpid
           and FA.facility = LP.facility;
   lp c_lp%rowtype := null;
   cursor c_loc(p_facility varchar2, p_location varchar2) is
      select putawayzone
         from location
         where facility = p_facility
           and locid = p_location;
   loc c_loc%rowtype := null;
   cursor c_prf(p_facility varchar2, p_lpid varchar2) is
      select distinct profid
         from custitemfacilityview
         where facility = p_facility
           and (custid, item) in
               (select distinct custid, item
                  from plate
                  where custid is not null
                    and item is not null
                  start with lpid = p_lpid
                  connect by prior lpid = parentlpid);
   prf c_prf%rowtype;
   l_restrict varchar2(1) := 'N';
begin

   open c_lp(in_lpid);
   fetch c_lp into lp;
   close c_lp;
   if nvl(lp.restrict_putaway,'N') = 'N' then
      return 'N';                         -- data missing or unrestricted
   end if;

   open c_loc(lp.facility, in_loc);
   fetch c_loc into loc;
   close c_loc;
   if loc.putawayzone is null then
      return 'Y';                         -- location not found or no putaway zone
   end if;

   open c_prf(lp.facility, in_lpid);
   loop
      fetch c_prf into prf;
      exit when (c_prf%notfound) or (l_restrict = 'Y');

      select decode(count(1), 0, 'Y', 'N') into l_restrict
         from putawayprofline
         where facility = lp.facility
           and profid = prf.profid
           and (zoneid = 'ANY ZONE!' or zoneid = loc.putawayzone);
   end loop;
   close c_prf;

   return l_restrict;

exception
   when OTHERS then
      return 'N';
end is_putaway_loc_restricted;


-- Public procedures


procedure get_uoms_in_uos
   (in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_uos       in varchar2,
    io_howmany   in out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_uom is
      select unitofmeasure uom, uominuos
         from custitemuomuos
         where custid = in_custid
           and item = in_item
           and unitofstorage = in_uos
           and unitofmeasure != in_uom;
   factor number;
   err varchar2(1);
   msg varchar2(80);
begin
   io_howmany := 0;
   out_error := 'N';
   out_message := null;

   begin
      select uominuos
         into io_howmany
         from custitemuomuos
         where custid = in_custid
           and item = in_item
           and unitofmeasure = in_uom
           and unitofstorage = in_uos
           and rownum = 1;
      return;
   exception
      when NO_DATA_FOUND then
         null;
   end;

   for x in c_uom loop
      zrf.get_baseuom_factor(in_custid, in_item, in_uom, x.uom, factor, err, msg);
      if (err != 'N') then
         out_error := err;
         out_message := msg;
         exit;
      end if;
      if (msg is null) then
         io_howmany := factor * x.uominuos;
         exit;
      end if;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end get_uoms_in_uos;


procedure get_used_uos
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_uos       in varchar2,
    in_curlp     in varchar2,
    io_used      in out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_lp is
      select item, custid, unitofmeasure uom, nvl(sum(quantity), 0) qty
         from plate
         where facility = in_facility
           and location = in_location
           and type = 'PA'
           and lpid not in (select lpid from plate
                              start with lpid = in_curlp
                              connect by prior lpid = parentlpid)
         group by item, custid, unitofmeasure
    union all
      select item, custid, unitofmeasure uom, nvl(sum(quantity), 0) qty
         from plate
         where destfacility = in_facility
           and destlocation = in_location
           and type = 'PA'
           and lpid not in (select lpid from plate
                              start with lpid = in_curlp
                              connect by prior lpid = parentlpid)
         group by item, custid, unitofmeasure;
   howmany number;
   err varchar2(1);
   msg varchar2(80);
   l_used_uos number;
begin
   io_used := 0;
   out_error := 'N';
   out_message := null;

   begin
     select used_uos
       into l_used_uos
       from location
      where facility = in_facility
        and locid = in_location;
   exception when others then
      l_used_uos := null;
   end;
   if l_used_uos is not null then
     io_used := l_used_uos;
     return;     
   end if;
   for lp in c_lp loop
      get_uoms_in_uos(lp.custid, lp.item, lp.uom, in_uos, howmany, err, msg);
      if (err != 'N') then
         out_error := err;
         out_message := msg;
         exit;
      end if;
      if (howmany = 0) then
         out_message := 'No link for cust.item (' || lp.custid || '.' || lp.item
               || ') to uos (' || in_uos || ')';
         exit;
      end if;
      io_used := io_used + (lp.qty / howmany);
      update location
         set used_uos = io_used
       where facility = in_facility
         and locid = in_location;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end get_used_uos;


procedure putaway_lp
   (in_action       in varchar2,
    in_lpid         in varchar2,
    in_facility     in varchar2,
    in_location     in varchar2,
    in_sender       in varchar2,
    in_keeptogether in varchar2,
    in_equipment    in varchar2,
    out_message     out varchar2,
    out_facility    out varchar2,
    out_location    out varchar2)
is
   cursor c_Q is
      select abbrev
         from putawayqueues
         where code = in_facility;
   q c_Q%rowtype;
   cursor c_defQ is
      select abbrev
         from putawayqueues
         order by abbrev;
   correlation varchar2(32) := 'PUTAWAY';
   status number;
   logmsg varchar(255);
   fac varchar(255) := null;
   loc varchar(255) := null;
   msg varchar2(400);
   trans varchar2(20);
begin
   out_message := null;
   out_facility := null;
   out_location := null;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      correlation := correlation || q.abbrev;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         correlation := correlation || q.abbrev;
      end if;
      close c_defQ;
   end if;
   close c_Q;
   msg := in_action|| chr(9) ||
          in_keeptogether|| chr(9) ||
          in_lpid|| chr(9) ||
          in_facility|| chr(9) ||
          in_location|| chr(9) ||
          in_sender|| chr(9);
   if (in_equipment is not null) then
      msg := msg || in_equipment || chr(9);
   end if;
   status := zqm.send_commit(PUTAWAY_DEFAULT_QUEUE,'MSG',msg,1,correlation);
   if (status != 1) then
      out_message := 'Send error ' || status;
      return;
   end if;

   if (in_action in ('RESP', 'ATRS', 'NLRS', 'TARS')) then
      status := zqm.receive_commit(USER_DEFAULT_QUEUE,in_sender,null,zqm.DQ_REMOVE, trans, msg);
      if (status != 1) then
         out_message := 'Recv error ' || status;
         return;
      end if;
      fac := zqm.get_field(msg,1);
      loc := zqm.get_field(msg,2);
   end if;

   if ((nvl(length(fac), 0) > 3) or (nvl(length(loc), 0) > 10)) then
      rollback;
      zms.log_msg('PUTAWAY_LP', in_facility, null, 'fac=<'||fac||'>', 'T', in_sender, logmsg);
      zms.log_msg('PUTAWAY_LP', in_facility, null, 'loc=<'||loc||'>', 'T', in_sender, logmsg);
      commit;
   end if;

   out_facility := fac;
   out_location := loc;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end putaway_lp;

procedure putaway_lp_delay
   (in_action       in varchar2,
    in_lpid         in varchar2,
    in_facility     in varchar2,
    in_location     in varchar2,
    in_sender       in varchar2,
    in_keeptogether in varchar2,
    out_message     out varchar2)
is
   cursor c_Q is
      select abbrev
         from putawayqueues
         where code = in_facility;
   q c_Q%rowtype;
   cursor c_defQ is
      select abbrev
         from putawayqueues
         order by abbrev;
   correlation varchar2(32) := 'PUTAWAY';
   status number;
   logmsg varchar(255);
   msg varchar2(400);
   trans varchar2(20);
begin
   out_message := null;

   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      correlation := correlation || q.abbrev;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         correlation := correlation || q.abbrev;
      end if;
      close c_defQ;
   end if;
   close c_Q;
   msg := in_action|| chr(9) ||
          in_keeptogether|| chr(9) ||
          in_lpid|| chr(9) ||
          in_facility|| chr(9) ||
          in_location|| chr(9) ||
          in_sender|| chr(9);
   status := zqm.send(PUTAWAY_DEFAULT_QUEUE,'MSG',msg,1,correlation);
   if (status != 1) then
      out_message := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end putaway_lp_delay;

procedure rebuild_putaway_mps
   (in_facility in varchar2,
    in_user     in varchar2,
    out_message out varchar2)
is
   cursor c_lp is
      select lpid, parentlpid, custid, item, orderid, shipid, loadno, stopno,
             shipno, lotnumber, invstatus, inventoryclass, rowid
         from plate
         where facility = in_facility
           and location = in_user
           and status = 'U'
           and disposition is not null
           and parentlpid is not null;
   cursor c_mp (p_lp varchar2) is
      select type, status, location, disposition
         from plate
         where lpid = p_lp;
   mp c_mp%rowtype;
   cursor c_delmp (p_lp varchar2) is
      select type
         from deletedplate
         where lpid = p_lp;
   delmp c_delmp%rowtype;
   msg varchar2(80) := null;
   mpfound boolean;
   rtnmsg varchar2(255) := null;
begin
   rbldmp_tbl.delete;

   for lp in c_lp loop
      open c_mp(lp.parentlpid);
      fetch c_mp into mp;
      mpfound := c_mp%found;
      close c_mp;

--    parent does not exist
      if not mpfound then
         open c_delmp(lp.parentlpid);
         fetch c_delmp into delmp;
         mpfound := c_delmp%found;
         close c_delmp;

--       parent never existed
         if not mpfound then
            zplp.build_empty_parent(lp.parentlpid, in_facility, in_user, 'U', 'MP',
                  RBLDMP_ID, 'PUT', lp.custid, lp.item, lp.orderid, lp.shipid,
                  lp.loadno, lp.stopno, lp.shipno, lp.lotnumber, lp.invstatus,
                  lp.inventoryclass, msg);
            exit when (msg is not null);
     	      zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                  'adding new mp ' || lp.parentlpid,
                  'E', in_user, rtnmsg);

--       parent was deleted
         elsif (delmp.type = 'XP') then         -- very strange....
            update plate                        -- mark as "not a child"
               set parentlpid = null,
                   lastoperator = RBLDMP_ID,
                   lastuser = RBLDMP_ID,
                   lastupdate = sysdate
               where rowid = lp.rowid;
     	      zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                  'ignoring deleted xp ' || lp.parentlpid,
                  'E', in_user, rtnmsg);
            lp.parentlpid := null;              -- don't try to attach

         else
            insert into plate                   -- move it into the plate table
               select * from deletedplate
               where lpid = lp.parentlpid;
            delete deletedplate
               where lpid = lp.parentlpid;

            update plate
               set status = 'U',                -- in case we have to morph
                   location = in_user,
                   disposition = 'PUT',
                   parentlpid = null
               where lpid = lp.parentlpid;

            if (delmp.type = 'PA') then         -- getting squirrelly
			      zplp.morph_lp_to_multi(lp.parentlpid, RBLDMP_ID, msg);
               exit when (msg is not null);
     	         zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                     'restoring and morphing deleted pa ' || lp.parentlpid,
                     'E', in_user, rtnmsg);
            else
     	         zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                     'restoring deleted ' || delmp.type || ' ' || lp.parentlpid,
                     'E', in_user, rtnmsg);
            end if;

            update plate
               set status = 'A'                 -- forces attach to clear/set fields
               where lpid = lp.parentlpid;
         end if;

         if (lp.parentlpid is not null) then
            zplp.attach_child_plate(lp.parentlpid, lp.lpid, in_user, 'U', RBLDMP_ID, msg);
            exit when (msg is not null);
            update_rbldmp_tbl(lp.parentlpid, mpfound);
         end if;

--    parent exists
      else
         update_rbldmp_tbl(lp.parentlpid, mpfound);   -- see if we messed with it

--       it's one we "updated", so just attach to it
         if mpfound then
            zplp.attach_child_plate(lp.parentlpid, lp.lpid, in_user, 'U', RBLDMP_ID, msg);
            exit when (msg is not null);

         elsif (mp.type = 'XP') then            -- also very strange....
            update plate                        -- mark as "not a child"
               set parentlpid = null,
                   lastoperator = RBLDMP_ID,
                   lastuser = RBLDMP_ID,
                   lastupdate = sysdate
               where rowid = lp.rowid;
     	      zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                  'ignoring existing xp ' || lp.parentlpid,
                  'E', in_user, rtnmsg);

         elsif (mp.type = 'PA') then
            update plate
               set status = 'U',                -- for morphing
                   location = in_user,
                   disposition = 'PUT',
                   parentlpid = null
               where lpid = lp.parentlpid;
            zplp.morph_lp_to_multi(lp.parentlpid, RBLDMP_ID, msg);
            exit when (msg is not null);
            update plate
               set status = 'A'                 -- forces attach to clear/set fields
               where lpid = lp.parentlpid;
            zplp.attach_child_plate(lp.parentlpid, lp.lpid, in_user, 'U', RBLDMP_ID, msg);
            exit when (msg is not null);
  	         zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                  'morphing existing pa ' || lp.parentlpid,
                  'E', in_user, rtnmsg);
            update_rbldmp_tbl(lp.parentlpid, mpfound);

         elsif ((mp.location = in_user) and ((mp.disposition is null) or (mp.status != 'U'))) then
            update plate
               set status = 'U',
                   disposition = 'PUT',
                   lastoperator = RBLDMP_ID,
                   lastuser = RBLDMP_ID,
                   lastupdate = sysdate
               where lpid = lp.parentlpid;
  	         zms.log_msg(RBLDMP_ID, in_facility, lp.custid,
                  'updating existing mp ' || lp.parentlpid,
                  'E', in_user, rtnmsg);
         end if;
      end if;
   end loop;

   out_message := msg;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end rebuild_putaway_mps;

procedure assign_item
   (in_facility  in varchar2,
    in_custid    in varchar2,
    in_location  in varchar2,
    in_item	     in varchar2,
    in_newitem   in varchar2,
    in_newcustid in varchar2,
    out_message  out varchar2)
is
 cursor lipList is
 	select lpid from plate
 		where	facility = in_facility
        and custid   = in_custid
        and location = in_location
        and	item 	   = in_item
        and	status   = 'A';
  dummy1 varchar2(1);
  dummy2 varchar2(2);
  tskCount integer;
begin
	/*select count(1) into tskCount
		from tasks
			where
			    lpid in
			          (select lpid from plate
 				      where	facility = in_facility and
 					        location = in_location and
 					        item 	 = in_item and
 					        custid   = in_custid);*/

 	select count(1) into tskCount
		from subtasks
			where (facility = in_facility and
 			       fromloc  = in_location and
 			       custid   = in_custid) and
 			      (item     = in_item or
 			       tasktype = 'CC');

	if tskCount = 0 then

		for lp in lipList loop

			zput.putaway_lp('TANR', lp.lpid, in_facility, in_location, 'UPDTIPF', 'Y',
               null, out_message, dummy1, dummy2);
			if out_message is not null then
				exit;
			end if;
		end loop;

		if out_message is null  then
			out_message := 'OKAY';
			update itempickfronts
				set pendingitem = in_newitem,
				    pendingcustid = in_newcustid,
				    olditem = item,
				    oldpickfront = pickfront,
				    pickfront = null,
				    lastuser = 'UPDTPF',
				    lastupdate = sysdate
			where facility = in_facility
           and	pickfront = in_location
           and	item = in_item
           and	custid = in_custid;

			update custitem
			   set unitsofstorage =
				      (select unitsofstorage from custitem
					      where custid = in_newcustid
                       and item = in_newitem)
			   where custid = in_custid
              and item = in_item
              and unitsofstorage is null;
		end if;
	else
		out_message := 'Item not assigned. Pending tasks exist.';
	end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end assign_item;


procedure unassign_item
   (in_facility in varchar2,
    in_custid   in varchar2,
    in_location in varchar2,
    in_item	    in varchar2,
    out_message out varchar2)
is
 cursor taskList is
 	select taskid
      from tasks
      where curruserid is null
      and lpid in (select lpid from plate
 			   where	facility = in_facility
              and	location = in_location
              and	item 	 = in_item
              and	custid   = in_custid);
begin
	out_message := 'OKAY';

	for tid in taskList loop
		ztk.task_delete(in_facility,tid.taskid,'UPDTIPF',out_message);
		if out_message <> 'OKAY' then
			exit;
		end if;
	end loop;

	if out_message = 'OKAY' then
		update itempickfronts
			set pendingitem = null,
			    pendingcustid = null,
			    pickfront = oldpickfront,
			    olditem =  null,
			    oldpickfront = null,
			    lastuser = 'UPDTPF',
			    lastupdate = sysdate
		   where facility = in_facility
           and	oldpickfront = in_location
           and	item = in_item
           and	custid = in_custid;
	end if;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end unassign_item;


procedure get_remaining_uoms
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_uom       in varchar2,
    in_curlp     in varchar2,
    in_maxqty    in number,
    in_maxuom    in varchar2,
    io_remaining in out number,
    out_error    out varchar2,
    out_message  out varchar2)
is
   cursor c_lp is
      select unitofmeasure uom, nvl(sum(quantity), 0) qty
         from plate
         where facility = in_facility
           and location = in_location
           and custid = in_custid
           and item = in_item
           and type = 'PA'
           and lpid not in (select lpid from plate
                              start with lpid = in_curlp
                              connect by prior lpid = parentlpid)
         group by unitofmeasure
    union all
      select unitofmeasure uom, nvl(sum(quantity), 0) qty
         from plate
         where destfacility = in_facility
           and destlocation = in_location
           and custid = in_custid
           and item = in_item
           and type = 'PA'
           and lpid not in (select lpid from plate
                              start with lpid = in_curlp
                              connect by prior lpid = parentlpid)
         group by unitofmeasure;
   qty number;
   msg varchar2(255);
begin
   out_error := 'N';
   out_message := null;

   zbut.translate_uom(in_custid, in_item, in_maxqty, in_maxuom, in_uom, io_remaining, msg);
   if (substr(msg, 1, 4) != 'OKAY') then
      out_message := msg;
      return;
   end if;

   for lp in c_lp loop
      zbut.translate_uom(in_custid, in_item, lp.qty, lp.uom, in_uom, qty, msg);
      if (substr(msg, 1, 4) != 'OKAY') then
         out_message := msg;
         exit;
      end if;
      io_remaining := io_remaining - qty;
   end loop;

exception
   when OTHERS then
      out_error := 'Y';
      out_message := substr(sqlerrm, 1, 80);
end get_remaining_uoms;


procedure highest_whole_uom
   (in_custid   in varchar2,
    in_item     in varchar2,
    in_qty      in number,
    in_uom      in varchar2,
    out_qty     out number,
    out_uom     out varchar2,
    out_message out varchar2)
is
   cursor c_ciu(p_custid varchar2, p_item varchar2) is
      select touom
         from custitemuom
         where custid = p_custid
           and item = p_item
         order by sequence desc;
   l_toqty number(9);
   l_minqty number(9) := in_qty;
   l_minuom custitem.baseuom%type := in_uom;
begin
   out_message := null;

   for ciu in c_ciu(in_custid, in_item) loop
      l_toqty := zlbl.uom_qty_conv(in_custid, in_item, in_qty, in_uom, ciu.touom);

--    highest whole uom will produce the smallest qty
      if (l_toqty > 0) and (l_toqty < l_minqty) then

--       make sure it's exact
         if in_qty = zlbl.uom_qty_conv(in_custid, in_item, l_toqty, ciu.touom, in_uom) then
            l_minqty := l_toqty;
            l_minuom := ciu.touom;
         end if;
      end if;
   end loop;

   out_qty := l_minqty;
   out_uom := l_minuom;

exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end highest_whole_uom;


procedure putaway_decon_orphans
is
   cursor c_fa is
      select facility
         from facility;
   fa c_fa%rowtype := null;
   cursor c_loc (p_facility varchar2) is
      select locid
         from location
         where facility = p_facility
           and loctype = 'SRT';
   loc c_loc%rowtype := null;
   cursor c_lp(p_facility varchar2, p_location varchar2) is
      select lpid, custid
         from plate
         where facility = p_facility
           and location = p_location
           and status = 'P'
           and nvl(virtuallp,'N') = 'Y';
   lp c_lp%rowtype := null;
   l_msg varchar2(255);
   l_auxmsg varchar2(255);
   l_fac plate.facility%type;
   l_loc plate.location%type;
begin

   open c_fa;
   loop
      fetch c_fa into fa;
      exit when c_fa%notfound;

      open c_loc(fa.facility);
      loop
         fetch c_loc into loc;
         exit when c_loc%notfound;

         open c_lp(fa.facility, loc.locid);
         loop
            fetch c_lp into lp;
            exit when c_lp%notfound;

            if not zrf.any_tasks_for_lp(lp.lpid, null) then  -- no tasks remaining
               if not zrfpk.any_vlp_batch_work(lp.lpid) then   -- no sorts pending
                  zput.putaway_lp('TANR', lp.lpid, fa.facility, loc.locid, 'DeconPut', 'Y',
                        null, l_msg, l_fac, l_loc);
                  if l_msg is not null then
                     zms.log_autonomous_msg('DeconPut', fa.facility, lp.custid,
                           l_msg || ' LP = ' || lp.lpid, 'E', null, l_auxmsg);
                  end if;
               end if;
            end if;
         end loop;
         close c_lp;

      end loop;
      close c_loc;

   end loop;
   close c_fa;

exception
   when OTHERS then
      zms.log_autonomous_msg('DeconPut', fa.facility, lp.custid,
      sqlerrm || ' LP = ' || lp.lpid, 'E', null, l_msg);
end putaway_decon_orphans;


end zputaway;
/

show errors package body zputaway;
exit;
