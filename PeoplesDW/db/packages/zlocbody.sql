create or replace package body alps.zlocation as
--
-- $Id$
--


-- Types


type loc_rectype is record (
	locid location.locid%type,
	equipprof location.equipprof%type,
   locpandd location.locid%type,
   zonepandd location.locid%type,
   section location.section%type,
   loctype location.loctype%type);


-- Private functions


function is_equip_in_prof
   (in_equipment in varchar2,
    in_profile   in varchar2)
return boolean
is
	l_cnt pls_integer;
begin
   select count(1) into l_cnt
      from equipprofequip
      where profid = in_profile
        and equipid = in_equipment;
	if l_cnt = 0 then
   	return false;
	end if;
   return true;

exception when others then
	return false;
end is_equip_in_prof;


function is_loc_accessible
   (in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2)
return boolean
is
	l_profile location.equipprof%type;
begin
	begin
	   select equipprof into l_profile
      	from location
      	where facility = in_facility
           and locid = in_location;
	exception
		when NO_DATA_FOUND then
			return false;
	end;

	return is_equip_in_prof(in_equipment, l_profile);

exception when others then
	return false;
end is_loc_accessible;


function is_xdock_loc_ok
   (in_facility in varchar2,
    in_location in varchar2,
    in_orderid  in number,
    in_shipid   in number)
return boolean
is
	cursor c_loc(p_facility varchar2, p_locid varchar2) is
   	select loctype
      	from location
         where facility = p_facility
           and locid = p_locid;
   loc c_loc%rowtype := null;
   l_msg varchar2(255);
   l_stageloc location.locid%type;
   l_loadloc location.locid%type;
begin
   for oh in (select orderid, shipid, loadno, stopno
               from orderhdr
               where xdockorderid = in_orderid
                 and xdockshipid = in_shipid
                 and ordertype = 'O'
                 and orderstatus != 'X') loop
      l_stageloc := null;
      get_stage_loc(in_facility, oh.loadno, oh.stopno, oh.orderid, oh.shipid,
            l_stageloc, l_loadloc, l_msg);
      if nvl(l_loadloc,'(??)') = in_location then
         return true;
      end if;
      if nvl(l_stageloc,'(??)') = in_location then
         return true;
      end if;
   end loop;

   open c_loc(in_facility, in_location);
   fetch c_loc into loc;
   close c_loc;
   if loc.loctype = 'STG' then
      return true;
   end if;

   return false;
exception when others then
	return false;
end is_xdock_loc_ok;


-- Public procedures


procedure get_drop_loc
	(in_facility  in varchar2,
    in_fromloc   in varchar2,
    in_destloc   in varchar2,
    in_equipment in varchar2,
    in_zone_col  in varchar2,
    out_droploc  out varchar2,
    out_message  out varchar2)
is
	origin loc_rectype := null;
	dest loc_rectype := null;
   l_cnt pls_integer;
   l_sql varchar2(1024);
   l_loc location.locid%type;
begin
	out_droploc := null;
   out_message := null;

	select count(1) into l_cnt
   	from user_tab_columns
      where table_name = 'LOCATION'
        and column_name = upper(in_zone_col);
	if l_cnt = 0 then
   	out_message := 'Invalid zone type';
      return;
	end if;

  	l_sql := 'select L.locid, L.equipprof, L.panddlocation, Z.panddlocation, ' ||
                   'L.section, L.loctype ' ||
      			'from location L, zone Z ' ||
		         'where L.facility = :p_facility ' ||
      		     'and L.locid = :p_location ' ||
		           'and Z.facility (+) = L.facility ' ||
      		     'and Z.zoneid (+) = L.' || in_zone_col;

   execute immediate l_sql into origin
      using in_facility, in_fromloc;
	if origin.locid is null then
   	out_message := 'From loc not found';
      return;
	end if;

   execute immediate l_sql into dest
      using in_facility, in_destloc;
	if dest.locid is null then
   	out_message := 'Dest loc not found';
      return;
	end if;

   if origin.loctype != 'XFR' then
	   begin
		   select instr(searchstr, '|'||rpad(dest.section,10)||'|') into l_cnt
      	   from sectionsearch
            where facility = in_facility
              and sectionid = origin.section;
	   exception
		   when NO_DATA_FOUND then
			   l_cnt := 0;
	   end;

	   if l_cnt = 0 then			-- find closest transfer location
   	   for l in (select L.locid
      	            from location L, sectionsearch S
                     where L.facility = in_facility
                       and L.loctype = 'XFR'
                       and L.status != 'O'
                       and S.facility = in_facility
                       and S.sectionid = origin.section
			              and instr(S.searchstr, '|'||rpad(L.section,10)||'|') > 0
			            order by instr(S.searchstr, '|'||rpad(L.section,10)||'|')) loop
            execute immediate l_sql into dest
               using in_facility, l.locid;
			   exit;
		   end loop;
	   end if;
	end if;

	if is_equip_in_prof(in_equipment, dest.equipprof) then
   	out_droploc := dest.locid;
	elsif is_loc_accessible(in_facility, dest.locpandd, in_equipment) then
   	out_droploc := dest.locpandd;
	elsif is_loc_accessible(in_facility, dest.zonepandd, in_equipment) then
   	out_droploc := dest.zonepandd;
   end if;

exception when others then
	out_message := sqlerrm;

end get_drop_loc;


procedure drop_plate_at_loc
	(in_lpid         in varchar2,
    in_destloc      in varchar2,
    in_droploc      in varchar2,
    in_lpstatus     in varchar2,
    in_user         in varchar2,
    in_taskid       in number,
    in_tasktype     in varchar2,
    out_error       out varchar2,
    out_msgno       out number,
    out_message     out varchar2,
	 out_loaded_load out varchar2)   -- non-zero if load switched to status '8'; else 0
is
   cursor c_tsk(p_taskid number) is
   	select taskid, prevpriority
      	from tasks
         where taskid = p_taskid;
	tsk c_tsk%rowtype;
	cursor c_lp(p_lpid varchar2) is
   	select PL.parentlpid as parentlpid,
             PL.custid as custid,
             PL.item as item,
             PL.unitofmeasure as unitofmeasure,
             PL.quantity as quantity,
             PL.loadno as loadno,
             PL.stopno as stopno,
             PL.shipno as shipno,
             PL.orderid as orderid,
             PL.shipid as shipid,
             PL.itementered as itementered,
             PL.lotnumber as lotnumber,
             PL.facility as facility,
             PL.qtyentered as qtyentered,
             PL.uomentered as uomentered,
             PL.status as status,
             PL.prevlocation as prevlocation,
             PL.type as lptype,
             nvl(pl.virtuallp,'N') as virtuallp,
             nvl(OH.ordertype,'?') as ordertype,
             SP.lpid as splpid,
             nvl(SP.type,'?') as sptype,
             SP.loadno as spload
      	from plate PL, orderhdr OH, shippingplate SP
         where PL.lpid = p_lpid
           and OH.orderid (+) = PL.orderid
           and OH.shipid (+) = PL.shipid
           and SP.fromlpid (+) = PL.lpid;
	lp c_lp%rowtype;
	cursor c_loc(p_facility varchar2, p_locid varchar2) is
   	select loctype, section, equipprof, putawayseq, pickingseq
      	from location
         where facility = p_facility
           and locid = p_locid;
	drp c_loc%rowtype;
	dest c_loc%rowtype;
   l_found boolean;
   l_msg varchar2(80);
	l_errno number;
   l_auxmsg varchar2(80);
   l_cnt pls_integer;
   l_destloc location.locid%type;
   l_qty subtasks.qty%type;
	l_cdat cdata;
   l_status plate.status%type;
   l_is_loaded varchar2(1);
   l_spload_door loads.doorloc%type;
begin
	out_error := 'N';
   out_msgno := 0;
   out_message := null;
   out_loaded_load := 0;

	if nvl(in_taskid,0) = 0 then		-- this should only be true from lppway()
   	tsk := null;
	else
	   open c_tsk(in_taskid);
   	fetch c_tsk into tsk;
	   l_found := c_tsk%found;
   	close c_tsk;
	   if not l_found then
   		out_message := 'Task not found';
      	return;
		end if;
	end if;

	open c_lp(in_lpid);
   fetch c_lp into lp;
   l_found := c_lp%found;
   close c_lp;
   if not l_found then
   	out_message := 'LP not found';
      return;
	end if;

   open c_loc(lp.facility, in_droploc);
   fetch c_loc into drp;
   l_found := c_loc%found;
   close c_loc;
   if not l_found then
   	out_message := 'Drop loc not found';
      return;
	end if;

   if (drp.loctype = 'DEL') and (in_tasktype != 'SP') then
   	out_message := 'DEL invalid for ' || in_tasktype;
      return;
	end if;

   if (lp.ordertype = 'C') and (lp.splpid is not null) then
      if drp.loctype not in ('DOR','STG') then
         out_message := 'No xdock at ' || drp.loctype;
         return;
      end if;

      if not is_xdock_loc_ok(lp.facility, in_droploc, lp.orderid, lp.shipid) then
         out_message := 'Invalid xdock loc';
         return;
      end if;

      if (lp.spload is not null and drp.loctype = 'DOR') then
        select nvl(doorloc, in_droploc) into l_spload_door
        from loads
        where loadno = lp.spload;
        
        if (l_spload_door <> in_droploc) then
          out_message := 'Wrong door location';
          return;
        end if;
      end if;

      zrfpk.stage_a_plate(lp.splpid, in_droploc, in_user, in_tasktype, 'N',
            in_droploc, 'N', 'N', out_error, out_message, l_is_loaded);
      if out_message is not null then
         return;
      end if;

      if l_is_loaded = 'Y' then
         out_loaded_load := lp.spload;
      end if;
   else
      if drp.loctype not in ('PND','XFR') then
  	   	l_destloc := in_droploc;
   	else
      	l_destloc := in_destloc;
   	end if;

      select count(1) into l_cnt
         from shippingplate
         where fromlpid = in_lpid
           and type = 'F'
           and status in ('S','P');
   	if (lp.status = 'P') or (l_cnt > 0) then
         l_status := 'P';
      else
         l_status := in_lpstatus;
     	end if;

      if lp.parentlpid is not null then
   		zplp.detach_child_plate(lp.parentlpid, in_lpid, in_droploc, lp.facility,
         		l_destloc, l_status, in_user, in_tasktype, l_msg);
		   if l_msg is not null then
      	   out_error := 'Y';
         	out_message := l_msg;
            return;
		   end if;
   	else
         update plate
   	      set destfacility = lp.facility,
                destlocation = l_destloc,
		   	    location = in_droploc,
                status = l_status,
      		    lastoperator = in_user,
   	      	 lasttask = in_tasktype,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid in (select lpid from plate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid);
   	end if;

	   if l_status = 'P' then
         update shippingplate
            set location = in_droploc,
                prevlocation = location,
                lastuser = in_user,
                lastupdate = sysdate
            where lpid in (select lpid from shippingplate
             			start with fromlpid = in_lpid
                     connect by prior parentlpid = lpid)
		   	  and status in ('P', 'S')
              and location = lp.prevlocation;
	   end if;

      if (lp.lptype = 'MP') and (lp.virtuallp = 'Y') and (lp.sptype = 'F') then
         zrfpk.stage_full_virtual(lp.splpid, in_user, in_tasktype, l_msg);
		   if l_msg is not null then
      	   out_error := 'Y';
         	out_message := l_msg;
            return;
		   end if;
      end if;
   end if;

   if drp.loctype = 'CD' then
	   for l in (select lpid, custid from plate
					   where type = 'PA'
         		   start with lpid = in_lpid
         		   connect by prior lpid = parentlpid) loop
		   zid.lip_placed_at_xdock(l.lpid, null, in_user, l_errno, l_msg);
		   if l_errno != 0 then
   		   zms.log_msg('ZLOC', lp.facility, l.custid, l_msg, 'W', in_user, l_auxmsg);
		   end if;
	   end loop;
	end if;

--	There is an entered qty and uom, and the converted entered qty is the
-- same as the actual - use the entered values
--	otherwise, use the actual values
	if (lp.qtyentered is not null) and (lp.uomentered is not null) then
  		zbut.translate_uom(lp.custid, lp.item, lp.qtyentered, lp.uomentered,
      		lp.unitofmeasure, l_qty, l_msg);
    	if (substr(l_msg, 1, 4) = 'OKAY') and (l_qty = lp.quantity) then
      	lp.quantity := lp.qtyentered;
         lp.unitofmeasure := lp.uomentered;
		end if;
   end if;

	if drp.loctype not in ('PND','XFR') then
--	end of movement, cleanup
	   delete subtasks
   		where taskid = in_taskid
      	  and lpid = in_lpid;
		delete tasks
   		where taskid = in_taskid
      	  and not exists (select * from subtasks where taskid = in_taskid);
		if drp.loctype = 'DEL' then
			l_cdat := zcus.init_cdata;
			l_cdat.lpid := in_lpid;
			l_cdat.userid := in_user;
         l_cdat.out_no := 0;
         l_cdat.out_char := null;
    		zcus.execute('STPR',l_cdat);
         if l_cdat.out_no != 0 then
            out_error := 'I';
            out_msgno := l_cdat.out_no;
            out_message := l_cdat.out_char;
         end if;
		end if;
	else
      open c_loc(lp.facility, in_destloc);
      fetch c_loc into dest;
      l_found := c_loc%found;
      close c_loc;
      if not l_found then
   	   dest := null;
	   end if;
		if in_tasktype not in ('PA','MV') then
      	dest.putawayseq := dest.pickingseq;
		end if;

	   if nvl(in_taskid,0) = 0 then
-- 	no input task create everything
 			ztsk.get_next_taskid(tsk.taskid, l_msg);

         insert into tasks
            (taskid, tasktype, facility, fromsection,
             fromloc, fromprofile, tosection, toloc,
             toprofile, custid, item, lpid,
             uom, qty, locseq, loadno,
             stopno, shipno, orderid, shipid,
             orderitem, orderlot,
             priority, prevpriority,
             lastuser, lastupdate, step1_complete)
		   values
        	   (tsk.taskid, in_tasktype, lp.facility, drp.section,
             in_droploc, drp.equipprof, dest.section, in_destloc,
             dest.equipprof, lp.custid, lp.item, in_lpid,
             lp.unitofmeasure, lp.quantity, nvl(dest.putawayseq,0), lp.loadno,
             lp.stopno, lp.shipno, lp.orderid, lp.shipid,
             lp.itementered, lp.lotnumber,
             decode(drp.loctype, 'PND', '3', '5'), decode(drp.loctype, 'PND', '3', '5'),
             in_user, sysdate, 'Y');

    	   insert into subtasks
     		   (taskid, tasktype, facility, fromsection,
             fromloc, fromprofile, tosection, toloc,
             toprofile, custid, item, lpid,
             uom, qty, locseq, loadno,
             stopno, shipno, orderid, shipid,
             orderitem, orderlot,
             priority, lastuser, lastupdate, step1_complete)
		   values
			   (tsk.taskid, in_tasktype, lp.facility, drp.section,
             in_droploc, drp.equipprof, dest.section, in_destloc,
             dest.equipprof, lp.custid, lp.item, in_lpid,
             lp.unitofmeasure, lp.quantity, nvl(dest.putawayseq,0), lp.loadno,
             lp.stopno, lp.shipno, lp.orderid, lp.shipid,
             lp.itementered, lp.lotnumber,
             decode(drp.loctype, 'PND', '3', '5'), in_user, sysdate, 'Y');
		else
			select count(1) into l_cnt
      		from subtasks
         	where taskid = in_taskid;
			if l_cnt = 1 then
--			only 1 subtask, update both
	      	update subtasks
   	      	set tasktype = in_tasktype,
      	          priority = decode(drp.loctype, 'PND', prevpriority, '5'),
         	       curruserid = null,
            	    touserid = null,
               	 fromsection = drp.section,
	                fromloc = in_droploc,
   	             fromprofile = drp.equipprof,
                   tosection = dest.section,
                   toloc = in_destloc,
                   toprofile = dest.equipprof,
                   locseq = nvl(dest.putawayseq,0),
                   lastuser = in_user,
                   lastupdate = sysdate,
                   step1_complete = 'Y'
					where taskid = in_taskid;
      		update tasks
         		set tasktype = in_tasktype,
                	 priority = decode(drp.loctype, 'PND', prevpriority, '5'),
                   curruserid = null,
                   touserid = null,
                   fromsection = drp.section,
                   fromloc = in_droploc,
                   fromprofile = drp.equipprof,
                   tosection = dest.section,
                   toloc = in_destloc,
                   toprofile = dest.equipprof,
                   locseq = nvl(dest.putawayseq,0),
                   lastuser = in_user,
                   lastupdate = sysdate,
                   step1_complete = 'Y'
					where taskid = in_taskid;
			else
--			more than 1 subtask, create new task, redirect subtask and update original task
    			ztsk.get_next_taskid(tsk.taskid, l_msg);

	         insert into tasks
   	         (taskid, tasktype, facility, fromsection,
      	       fromloc, fromprofile, tosection, toloc,
         	    toprofile, custid, item, lpid,
            	 uom, qty, locseq, loadno,
	             stopno, shipno, orderid, shipid,
   	          orderitem, orderlot,
      	       priority,
         	    prevpriority, lastuser, lastupdate, step1_complete)
				values
   	      	(tsk.taskid, in_tasktype, lp.facility, drp.section,
      	       in_droploc, drp.equipprof, dest.section, in_destloc,
             	 dest.equipprof, lp.custid, lp.item, in_lpid,
             	 lp.unitofmeasure, lp.quantity, nvl(dest.putawayseq,0), lp.loadno,
	             lp.stopno, lp.shipno, lp.orderid, lp.shipid,
   	          lp.itementered, lp.lotnumber,
      	       decode(drp.loctype, 'PND', tsk.prevpriority, '5'),
         	    tsk.prevpriority, in_user, sysdate, 'Y');

				update subtasks
   	      	set taskid = tsk.taskid,
      	      	 tasktype = in_tasktype,
         		    priority = decode(drp.loctype, 'PND', prevpriority, '5'),
            	    curruserid = null,
               	 touserid = null,
	                fromsection = drp.section,
   	             fromloc = in_droploc,
      	          fromprofile = drp.equipprof,
                   tosection = dest.section,
                   toloc = in_destloc,
                   toprofile = dest.equipprof,
                   locseq = nvl(dest.putawayseq,0),
                   lastuser = in_user,
                   lastupdate = sysdate,
                   step1_complete = 'Y'
	   			where taskid = in_taskid
   	   	  	  and lpid = in_lpid
      	  		returning qty into l_qty;

				update tasks
   	      	set qty = qty - l_qty,
                   lastuser = in_user,
                   lastupdate = sysdate,
                   step1_complete = null
      	      where taskid = in_taskid;

			end if;
		end if;
	end if;

	if (nvl(in_taskid,0) != 0) and (in_tasktype = 'PA') then
	   if drp.loctype not in ('PND','XFR','DOR') then
         update location
            set lastputawayto = sysdate
            where facility = lp.facility
              and locid = in_droploc;
      end if;

      if nvl(lp.loadno,0) != 0 then
         delete subtasks
            where taskid in
                  (select taskid from tasks
                     where tasktype = 'CC'
                       and loadno = lp.loadno
                       and lpid in
                           (select lpid from plate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid));

         delete tasks
            where tasktype = 'CC'
              and loadno = lp.loadno
              and lpid in
                  (select lpid from plate
                     start with lpid = in_lpid
                     connect by prior lpid = parentlpid);
      end if;
   end if;

exception when others then
	out_error := 'Y';
	out_message := sqlerrm;

end drop_plate_at_loc;


procedure get_stage_loc
	(in_facility  in varchar2,
    in_loadno    in number,
    in_stopno    in number,
    in_orderid   in number,
    in_shipid    in number,
    io_stageloc  in out varchar2,
    out_loadloc  out varchar2,
    out_message  out varchar2)
is
	cursor c_dr(p_facility varchar2, p_doorloc varchar2) is
  		select nvl(loadno,0) as loadno
    		from door
   		where facility = p_facility
     		  and doorloc = p_doorloc;
	dr c_dr%rowtype;
   cursor c_maxstop(p_loadno number) is
   	select max(L.stopno) as stopno
      	from loadstop L
         where L.loadno = p_loadno
           and L.loadstopstatus < zrf.LOD_LOADED
           and exists (select * from orderhdr O
           					where O.loadno = L.loadno
                          and O.stopno = L.stopno
                          and O.orderstatus != 'X');
	mst c_maxstop%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
   	select stageloc, wave, carrier, shiptype
      	from orderhdrview
         where orderid = p_orderid
           and shipid = p_shipid;
   cursor c_consoh(p_wave number) is
   	select stageloc, wave, carrier, shiptype
      	from orderhdrview
         where wave = p_wave
         order by orderid, shipid;
	oh c_oh%rowtype;
   cursor c_wv(p_wave number) is
   	select stageloc
      	from waves
         where wave = p_wave;
	wv c_wv%rowtype;
   cursor c_ld(p_loadno number, p_stopno number) is
   	select nvl(LS.stageloc,L.stageloc) as stageloc, L.carrier, L.shiptype,
             L.doorloc
      	from loads L, loadstop LS
         where L.loadno = p_loadno
           and LS.loadno = L.loadno
           and LS.stopno = p_stopno;
	ld c_ld%rowtype;
	cursor c_cs(p_carrier varchar2, p_facility varchar2, p_shiptype varchar2) is
  		select stageloc
    		from carrierstageloc
   		where carrier = p_carrier
     		  and facility = p_facility
     		  and shiptype = p_shiptype;
	cs c_cs%rowtype;
   l_found boolean;
   l_loadfound boolean := false;
   l_loadno loads.loadno%type := nvl(in_loadno,0);
   l_stopno loadstop.stopno%type := nvl(in_stopno,0);
   l_orderid orderhdr.orderid%type := nvl(in_orderid,0);
   l_shipid orderhdr.shipid%type := nvl(in_shipid,0);
begin
	out_loadloc := null;
   out_message := null;

	if nvl(l_loadno,0) != 0 then
		open c_ld(l_loadno, l_stopno);
		fetch c_ld into ld;
   	l_loadfound := c_ld%found;
		close c_ld;
	end if;

	if l_loadfound and (ld.doorloc is not null) then	-- door assigned
		open c_dr(in_facility, ld.doorloc);
	   fetch c_dr into dr;
   	l_found := c_dr%found;
	   close c_dr;
   	if l_found and (dr.loadno = l_loadno) then		-- load arrived
      	open c_maxstop(l_loadno);
         fetch c_maxstop into mst;
         l_found := c_maxstop%found;
         close c_maxstop;
         if l_found and (mst.stopno = l_stopno) then	-- live loading OK
         	out_loadloc := ld.doorloc;
			end if;
		end if;
	end if;

	if io_stageloc is null then
 		if l_orderid != 0 then
      	if l_shipid != 0 then
		      open c_oh(l_orderid, l_shipid);
	         fetch c_oh into oh;
   	      l_found := c_oh%found;
	         close c_oh;
			else
				open c_consoh(l_orderid);						-- consolidated order
	         fetch c_consoh into oh;
   	      l_found := c_consoh%found;
	         close c_consoh;
         end if;
   	   if not l_found then
         	oh := null;
			end if;
     	   io_stageloc := oh.stageloc;

			if (io_stageloc is null) and (oh.wave is not null) then
		      open c_wv(oh.wave);
	         fetch c_wv into wv;
   	      l_found := c_wv%found;
	         close c_wv;
   	      if l_found then
     	      	io_stageloc := wv.stageloc;
				end if;
			end if;

			if io_stageloc is null then
		      open c_cs(oh.carrier, in_facility, oh.shiptype);
	         fetch c_cs into cs;
   	      l_found := c_cs%found;
	         close c_cs;
   	      if l_found then
     	      	io_stageloc := cs.stageloc;
				end if;
			end if;
		elsif l_loadfound then
			if io_stageloc is not null then
     	   	io_stageloc := ld.stageloc;
        	else
		      open c_cs(ld.carrier, in_facility, ld.shiptype);
	         fetch c_cs into cs;
   	      l_found := c_cs%found;
	         close c_cs;
   	      if l_found then
     	      	io_stageloc := cs.stageloc;
				end if;
			end if;
	   end if;
	end if;

exception when others then
	out_message := sqlerrm;

end get_stage_loc;

procedure rank_locations
	(in_facility  in varchar2)
is
   cursor c_fac(p_facility varchar2) is
      select pickingheavy,
             pickingmoderate,
             pickinglight,
             putawayheavy,
             putawaymoderate,
             putawaylight
         from facility
         where facility = p_facility;
   fac c_fac%rowtype := null;
   l_totlocs pls_integer;
   l_cnt pls_integer;
   l_msg varchar2(255);
   l_heavy pls_integer;
   l_moderate pls_integer;
   l_rank varchar2(1);
   l_ranktime date;
begin

   l_ranktime := sysdate;

   open c_fac(in_facility);
   fetch c_fac into fac;
   close c_fac;

   select count(1) into l_totlocs
      from location
      where facility = in_facility
        and loctype in ('STO','PF');

   if fac.pickingheavy is not null
   and fac.pickingmoderate is not null
   and fac.pickinglight is not null then

      l_heavy := l_totlocs * fac.pickingheavy / 100;
      l_moderate := l_heavy + (l_totlocs * fac.pickingmoderate / 100);
      l_cnt := 0;

      for loc in (select rowid from location
                     where facility = in_facility
                       and loctype in ('STO','PF')
                     order by nvl(pickcount,0) desc) loop

         l_cnt := l_cnt + 1;
         if l_cnt <= l_heavy then
            l_rank := 'H';
         elsif l_cnt <= l_moderate then
            l_rank := 'M';
         else
            l_rank := 'L';
         end if;

         update location
            set lastranked = l_ranktime,
                pickrank = l_rank
            where rowid = loc.rowid;
      end loop;
   end if;
   commit;

   if fac.putawayheavy is not null
   and fac.putawaymoderate is not null
   and fac.putawaylight is not null then

      l_heavy := l_totlocs * fac.putawayheavy / 100;
      l_moderate := l_heavy + (l_totlocs * fac.putawaymoderate / 100);
      l_cnt := 0;

      for loc in (select rowid from location
                     where facility = in_facility
                       and loctype in ('STO','PF')
                     order by nvl(dropcount,0) desc) loop

         l_cnt := l_cnt + 1;
         if l_cnt <= l_heavy then
            l_rank := 'H';
         elsif l_cnt <= l_moderate then
            l_rank := 'M';
         else
            l_rank := 'L';
         end if;

         update location
            set lastranked = l_ranktime,
                putawayrank = l_rank
            where rowid = loc.rowid;
      end loop;
   end if;
   commit;

exception when others then
   zms.log_autonomous_msg('RANKING', in_facility, null, sqlerrm, 'E', 'SYNAPSE', l_msg);
end rank_locations;

procedure reset_location_status
  (in_facility  in varchar2,
   in_locid     in varchar2,
   out_error    out varchar2,
   out_message  out varchar2)
is 
  cursor c_loc(v_facility varchar2, v_locid varchar2) is
  select locid, status, nvl(lpcount, 0) lpcount, loctype, rowid
  from location
  where facility = v_facility and locid = v_locid;
  loc c_loc%rowtype := null;  
  here integer;
  coming integer;
begin
  out_error := 0;
  out_message := null;
  open c_loc(in_facility, in_locid);
  fetch c_loc into loc;
  close c_loc;
  if loc.locid is null then
    out_error := 1;
    out_message := 'Location does not exist';
    return;
  end if;
  if loc.status = 'O' then
    out_message := 'Location out of service';
    return;
  end if;
  select count(1) into here
  from plate
  where facility = in_facility
    and location = in_locid
    and type = 'PA';
  select count(1) into coming
  from plate
  where destfacility = in_facility
    and destlocation = in_locid
    and type = 'PA';   
  if (loc.lpcount != (here + coming)) then
    update location
    set lpcount = (here + coming), status = decode((here + coming), 0, 'E', 'I')
    where rowid = loc.rowid;
  elsif ((loc.status = 'E') and (loc.lpcount != 0 or (here + coming) != 0)) then
    update location
    set lpcount = (here + coming), status = decode((here + coming), 0, 'E', 'I')
    where rowid = loc.rowid;
  elsif ((loc.status = 'I') and (loc.lpcount = 0 or (here + coming) = 0)) then
    update location
    set lpcount = (here + coming), status = decode((here + coming), 0, 'E', 'I')
    where rowid = loc.rowid;
  end if;
end reset_location_status;
end zlocation;
/

show errors package body zlocation;
exit;
