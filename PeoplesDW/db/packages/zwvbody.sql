create or replace PACKAGE BODY alps.zwave
IS
--
-- $Id$
--

zwv_debug_on boolean := False;

PROCEDURE set_debug_mode(in_mode boolean)
IS
BEGIN

  zwv_debug_on := nvl(in_mode,False);

END set_debug_mode;

PROCEDURE debug_msg
(in_text varchar2
,in_userid varchar2
)
is

l_char_count integer;
l_log_msg varchar2(255);

begin


  if not zwv_debug_on then
    return;
  end if;

  l_char_count := 1;
  while (l_char_count * 250) < (length(in_text)+250)
  loop
    zms.log_autonomous_msg('ZWAVE',null,null,substr(in_text,((l_char_count-1)*250)+1,250),
                           'T',in_userid,l_log_msg);
    l_char_count := l_char_count + 1;
  end loop;

exception when others then
    null;
end debug_msg;

function pick_to_label_okay
(in_orderid IN number
,in_shipid IN number
) return varchar2 is

oh orderhdr%rowtype;
ca carrier%rowtype;
cu customer%rowtype;

begin

oh := null;
select nvl(l.carrier,o.carrier),
       nvl(l.shiptype,o.shiptype),
       o.custid
  into oh.carrier, oh.shiptype, oh.custid
  from loads l, orderhdr o
 where o.orderid = in_orderid
   and o.shipid = in_shipid
   and o.loadno = l.loadno(+);

if oh.carrier is null then
  return 'Y';
end if;

begin
  select nvl(pick_by_line_number_yn,'N')
    into cu.pick_by_line_number_yn
    from customer
   where custid = oh.custid;
exception when others then
  cu.pick_by_line_number_yn := 'N';
end;

if cu.pick_by_line_number_yn = 'Y' then
  return 'Y';
end if;

select multiship
  into ca.multiship
  from carrier
 where carrier = oh.carrier;

-- if a multiship carrier and the shipment is not
-- small package, then no pick-to-label is allowed
-- (pick to pallet is used instead to force shipping master pallets to
-- be created during the picking process)
if (ca.multiship = 'Y') and
   (oh.shiptype != 'S') then
  return 'N';
else
  return 'Y';
end if;

exception when others then
  return 'Y';
end pick_to_label_okay;

function single_shipping_units_only
(in_orderid IN number
,in_shipid IN number
) return varchar2 is

oh orderhdr%rowtype;
ca carrier%rowtype;
begin

oh := null;

if in_shipid = 0 then
  select carrier,
         shiptype
    into oh.carrier, oh.shiptype
    from waves
   where wave = in_orderid;
else
  select nvl(l.carrier,o.carrier),
         nvl(l.shiptype,o.shiptype)
    into oh.carrier, oh.shiptype
    from loads l, orderhdr o
   where o.orderid = in_orderid
     and o.shipid = in_shipid
     and o.loadno = l.loadno(+);
end if;

if oh.carrier is null then
  return 'N';
end if;

select multiship
  into ca.multiship
  from carrier
 where carrier = oh.carrier;

-- if a multiship carrier and the shipment is
-- small package, then single shipping units must be
-- created for individual scans at the multiship station
if (ca.multiship = 'Y') and
   (oh.shiptype = 'S') then
  return 'Y';
else
  return 'N';
end if;

exception when others then
  return 'N';
end single_shipping_units_only;


function cartontype_group
(in_cartontype varchar
) return varchar2 is

out_cartongroup varchar2(4);

begin

select cartongroup
  into out_cartongroup
  from cartongroups
 where cartongroup = in_cartontype
   and rownum < 2;

return out_cartongroup;

exception when others then
  return null;
end cartontype_group;

FUNCTION default_picktype
(in_facility varchar2
,in_locid varchar2
) return varchar2 is

out_picktype zone.picktype%type;
strPickingzone location.pickingzone%type;

begin

out_picktype := 'LINE';

select pickingzone
  into strPickingzone
  from location
 where facility = in_facility
   and locid = in_locid;

select nvl(picktype,'LINE')
  into out_picktype
  from zone
 where facility = in_facility
   and zoneid = strPickingzone;

return out_picktype;

exception when others then
  return out_picktype;
end default_picktype;

FUNCTION subtask_total
(in_facility varchar2
,in_locid varchar2
,in_item varchar2
) return number is

sumQty subtasks.qty%type;

begin

sumQty := 0;

select nvl(sum(qty),0)
  into sumQty
  from subtasks
 where facility = in_facility
   and fromloc = in_locid
   and item = in_item
   and tasktype in ('BP','OP','PK');

return sumQty;

exception when others then
  return 0;
end subtask_total;

FUNCTION subtask_total_by_lip
(in_lpid varchar2
,in_custid varchar2
,in_item varchar2
) return number is

sumQty subtasks.qty%type;

begin

sumQty := 0;

select nvl(sum(qty),0)
  into sumQty
  from subtasks
 where lpid = in_lpid
   and custid = in_custid
   and item = in_item
   and tasktype in ('BP','OP','PK');

return sumQty;

exception when others then
  return 0;
end subtask_total_by_lip;

FUNCTION location_lastupdate
(in_facility varchar2
,in_locid varchar2
) return date is

out_lastupdate date;

begin

out_lastupdate := sysdate;

select lastupdate
  into out_lastupdate
  from location
 where facility = in_facility
   and locid = in_locid;

return out_lastupdate;

exception when others then
  return sysdate;
end location_lastupdate;

function tasked_at_loc
(in_facility in varchar2
,in_locid    in varchar2
,in_custid   in varchar2
,in_item     in varchar2
,in_wave     in number
,in_lotnumber in varchar2)
return number is
   l_totqty number(9) := 0;
   l_qty number(9) := 0;
begin
   select nvl(sum(nvl(qty,0)),0) into l_totqty
      from subtasks
      where facility = in_facility
        and fromloc = in_locid
        and custid = in_custid
        and item = in_item
        and (in_lotnumber = '(none)'
         or  nvl(orderlot,'(none)') = '(none)'
         or  nvl(orderlot,'(none)') = in_lotnumber);

   select nvl(sum(nvl(qty,0)),0) into l_qty
      from batchtasks bt
      where facility = in_facility
        and fromloc = in_locid
        and custid = in_custid
        and item = in_item
        and (in_lotnumber = '(none)'
         or  nvl(orderlot,'(none)') = '(none)'
         or  nvl(orderlot,'(none)') = in_lotnumber)
         and not exists(
      select 1
        from subtasks
       where taskid=bt.taskid
         and facility = bt.facility
         and fromloc = bt.fromloc
         and custid = bt.custid
         and item = bt.item
         and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)'));
   l_totqty := l_totqty + l_qty;

-- if we are switching to a new dynamic pick front within a loop that
-- calls find a pick() the facility will be null
   if nvl(in_wave,0) != 0 then
      select nvl(sum(nvl(qty,0)),0) into l_qty
         from subtasks
         where facility is null
           and fromloc = in_locid
           and custid = in_custid
           and item = in_item
           and wave = in_wave
           and (in_lotnumber = '(none)'
            or  nvl(orderlot,'(none)') = '(none)'
            or  nvl(orderlot,'(none)') = in_lotnumber);
      l_totqty := l_totqty + l_qty;

      select nvl(sum(nvl(qty,0)),0) into l_qty
         from batchtasks bt
         where facility is null
           and fromloc = in_locid
           and custid = in_custid
           and item = in_item
           and wave = in_wave
           and (in_lotnumber = '(none)'
            or  nvl(orderlot,'(none)') = '(none)'
            or  nvl(orderlot,'(none)') = in_lotnumber)
         and not exists(
         select 1
           from subtasks
          where taskid=bt.taskid
            and facility = bt.facility
            and fromloc = bt.fromloc
            and custid = bt.custid
            and item = bt.item
            and nvl(orderlot,'(none)') = nvl(bt.orderlot,'(none)'));
      l_totqty := l_totqty + l_qty;
   end if;

   return l_totqty;
exception
   when OTHERS then
      return 0;
end tasked_at_loc;

function total_at_loc
(in_facility in varchar2
,in_locid    in varchar2
,in_custid   in varchar2
,in_item     in varchar2
,in_lotnumber in varchar2
,in_invstatus in varchar2
,in_inventoryclass in varchar2)
return number is
   l_qty number(9) := 0;
begin
   select nvl(sum(nvl(quantity,0)),0) into l_qty
      from plate
      where facility = in_facility
        and location = in_locid
        and custid = in_custid
        and item = in_item
        and (in_lotnumber = '(none)'
         or  lotnumber = in_lotnumber)
        and invstatus = nvl(in_invstatus,invstatus)
        and inventoryclass = nvl(in_inventoryclass,inventoryclass);
   return l_qty;
exception
   when OTHERS then
      return 0;
end total_at_loc;

PROCEDURE get_next_wave
(out_wave OUT number
,out_msg IN OUT varchar2
)
is

currcount integer;

begin

currcount := 1;
while (currcount = 1)
loop
  select waveseq.nextval
    into out_wave
    from dual;
  select count(1)
    into currcount
    from waves
   where wave = out_wave;
end loop;

out_msg := 'OKAY';

exception when others then
  out_msg := sqlerrm;
end get_next_wave;

procedure get_wave_totals
(in_facility varchar2
,in_wave number
,out_cntorder IN OUT number
,out_qtyorder IN OUT number
,out_weightorder IN OUT number
,out_cubeorder IN OUT number
,out_qtycommit IN OUT number
,out_weightcommit IN OUT number
,out_cubecommit IN OUT number
,out_staffhours IN OUT number
,out_msg IN OUT varchar2
) is

begin

out_msg := '';
out_cntorder := 0;
out_qtyorder := 0;
out_weightorder := 0;
out_cubeorder := 0;
out_qtycommit := 0;
out_weightcommit := 0;
out_cubecommit := 0;
out_staffhours := 0;

select nvl(cntorder,0),
       nvl(qtyorder,0),
       nvl(weightorder,0),
       nvl(cubeorder,0),
       nvl(qtycommit,0),
       nvl(weightcommit,0),
       nvl(cubecommit,0),
       nvl(staffhrs,0)
  into out_cntorder,
       out_qtyorder,
       out_weightorder,
       out_cubeorder,
       out_qtycommit,
       out_weightcommit,
       out_cubecommit,
       out_staffhours
  from waves
 where wave = in_wave;

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvgot ' || sqlerrm;
end get_wave_totals;

procedure compress_ai_wave				-- private procedure, not in spec
	(in_wave in number,
	 out_msg in out varchar2)
is
	cursor c_subtasks is
   	select ST.rowid as strowid,
      		 ST.taskid as taskid,
             ST.custid as custid,
             SP.item as item,
             nvl(SP.lotnumber, '(none)') as lotnumber,
             ST.fromloc as fromloc,
             ST.pickuom as pickuom,
             ST.qty as qty,
             ST.pickqty as pickqty,
             ST.weight as weight,
             ST.cube as cube,
             ST.staffhrs as staffhrs,
             ST.shippinglpid as shippinglpid,
             SP.qtyentered as qtyentered,
             PL.orderid as receipt,
             ST.orderid as orderid,
             ST.shipid as shipid,
             SP.fromlpid as fromlpid,
             ST.orderitem as orderitem,
             ST.orderlot as orderlot
      	from subtasks ST, shippingplate SP, plate PL
      	where ST.wave = in_wave
           and SP.lpid = ST.shippinglpid
           and PL.lpid (+) = SP.fromlpid
         order by ST.taskid, ST.custid, SP.item, SP.lotnumber, ST.fromloc, ST.pickuom,
                  ST.orderitem, ST.orderlot, PL.orderid;
	curst c_subtasks%rowtype;

	procedure update_ai_task is
	begin
      update subtasks
         set qty = curst.qty,
             pickqty = curst.pickqty,
             weight = curst.weight,
             cube = curst.cube,
             staffhrs = curst.staffhrs,
             shippingtype = 'P'
         where rowid = curst.strowid;

	   update shippingplate
         set quantity = curst.qty,
             type = 'P',
			    qtyentered = curst.qtyentered,
			    weight = curst.weight,
             pickqty = curst.pickqty
         where lpid = curst.shippinglpid;
	end;

   procedure add_agginvtask
      (p_lpid in varchar2,
       p_qty  in number) is
   begin
      insert into agginvtasks
         (shippinglpid, lpid, qty)
      values
         (curst.shippinglpid, p_lpid, p_qty);
   end;
begin
	out_msg := 'OKAY';

	for st in c_subtasks loop

		if c_subtasks%rowcount = 1 then			-- first row, save it
      	curst := st;
         add_agginvtask(st.fromlpid, st.qty);

      elsif curst.taskid = st.taskid
        and curst.custid = st.custid
        and curst.item = st.item
        and curst.lotnumber = st.lotnumber
        and curst.fromloc = st.fromloc
        and curst.pickuom = st.pickuom
        and curst.orderitem = st.orderitem
        and curst.orderlot = st.orderlot
        and curst.receipt = st.receipt then		-- dupe of previous, merge
			curst.qty := curst.qty + st.qty;
      	curst.pickqty := curst.pickqty + st.pickqty;
         curst.weight := curst.weight + st.weight;
         curst.cube := curst.cube + st.cube;
         curst.staffhrs := curst.staffhrs + st.staffhrs;
         curst.qtyentered := curst.qtyentered + st.qtyentered;
         add_agginvtask(st.fromlpid, st.qty);

         delete subtasks where rowid = st.strowid;
         delete shippingplate where lpid = st.shippinglpid;
      else  	-- new, update current and save
      	update_ai_task;
		   curst := st;
         add_agginvtask(st.fromlpid, st.qty);
		end if;
	end loop;

	update_ai_task;

exception when others then
	out_msg := 'wvcaw ' || sqlerrm;
end compress_ai_wave;

procedure release_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority IN OUT varchar2
,in_picktype IN OUT varchar2
,in_userid IN varchar2
,in_trace IN varchar2
,out_msg IN OUT varchar2
) is

cursor curOrders is
  select orderid,
         shipid,
         orderstatus,
         fromfacility,
         custid,
         priority,
         stageloc
    from orderhdr
   where wave = in_wave
     and orderstatus != 'X'
   order by nvl(original_wave_before_combine,0), orderid, shipid;

cursor curWave is
  select picktype,
         nvl(taskpriority,'9') as taskpriority,
         wavestatus,
         job,
         batchcartontype,
         sortloc,
         stageloc,
         nvl(consolidated, 'N') consolidated,
         shiptype,
         carrier,
         servicelevel,
         nvl(use_flex_pick_fronts_yn,'N') use_flex_pick_fronts_yn,
         fpf_begin_location,
         nvl(fpf_full_picks_to_fpf_yn,'N') fpf_full_picks_to_fpf_yn,
         nvl(sdi_sortation_yn,'N') sdi_sortation_yn,
         nvl(sdi_sorter_process,'(none)') sdi_sorter_process
    from waves
   where wave = in_wave;
wv curWave%rowtype;

cursor curOrderItems is
  select distinct oh.custid, od.item,
         lpad(nvl(trim(ci.stacking_factor),'ZZZZZZZZZZZZ'),12,' ') stacking_factor
    from orderhdr oh, orderdtl od, custitem ci
   where oh.wave = in_wave
     and od.orderid = oh.orderid
     and od.shipid = oh.shipid
     and ci.item = od.item
   order by lpad(nvl(trim(ci.stacking_factor),'ZZZZZZZZZZZZ'),12,' '), od.item;
oi curOrderItems%rowtype;

cursor curFPFLocations(in_begin_location varchar2) is
  select 1 firstsort, nvl(pickingseq,0) pickingseq, locid
    from location
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) = 0
     and status = 'E'
     and locid = in_begin_location
  union
  select 2 firstsort, nvl(pickingseq,0) pickingseq, locid
    from location
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) = 0
     and status = 'E'
     and locid > in_begin_location
  union
  select 3 firstsort, nvl(pickingseq,0) pickingseq, locid
    from location
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) = 0
     and status = 'E'
     and locid < in_begin_location
   order by 1, 2, 3;
loc curFPFLocations%rowtype;

cursor curFPFLocation(in_item varchar2) is
  select locid
    from location
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) = in_wave
     and flex_pick_front_item = in_item;
fpfloc curFPFLocation%rowtype;


cursor curCheckForReplenishments is
  select distinct
         custid,
         item
    from subtasks
   where wave = in_wave;

cursor curShortOrders is
  select orderid,
         shipid,
         fromfacility,
         custid
    from orderhdr
   where wave = in_wave
     and orderstatus != 'X'
     and nvl(shipshort,'N') = 'W'
   order by orderid, shipid;
cso curShortOrders%rowtype;

cursor curCSREmails is
  select distinct ca.csr_email
    from orderhdr oh, customer_aux ca
   where wave = in_wave
     and orderstatus != 'X'
     and nvl(shipshort,'N') = 'W'
     and ca.custid = oh.custid;
ccsr curCSREmails%rowtype;

cursor curCSROrders(in_csr_email varchar2) is
  select orderid, shipid
    from orderhdr oh, customer_aux ca
   where wave = in_wave
     and orderstatus != 'X'
     and nvl(shipshort,'N') = 'W'
     and ca.custid = oh.custid
     and ca.csr_email = in_csr_email
   order by orderid, shipid;
ccsro curCSROrders%rowtype;

cntError integer;
out_errorno integer;
strTaskPriority varchar2(1);
strMsg varchar2(255);
strUpgrade char(1);
cntRows integer;
l_sortloc location.locid%type;
numJob number(16);
fpfCount integer;
itemCount integer;
l_wave integer;
msg varchar2(1000);
msgCount integer;

begin

out_msg := '';
cntError := 0;
open curWave;
fetch curWave into wv;
if curWave%notfound then
  close curWave;
  out_msg := 'Invalid wave identifier ' || in_wave;
  return;
end if;
close curWave;

if wv.wavestatus > '2' then
  zms.log_autonomous_msg('WaveRelease', in_facility, '',
    'Wave ' || in_wave || '-invalid status for release: ' || wv.wavestatus,
    'W', in_userid, strMsg);
  out_msg := 'OKAY Wave ' || in_wave || '-invalid status for release: ' || wv.wavestatus;
  return;
end if;

if rtrim(in_taskpriority) is null then
  in_taskpriority := wv.taskpriority;
  if rtrim(in_taskpriority) is null then
    in_taskpriority := '3';
  end if;
end if;

if nvl(rtrim(in_picktype),'(none)') = '(none)' then
  in_picktype := wv.picktype;
end if;

if wv.use_flex_pick_fronts_yn = 'Y' then
  update location lo
     set flex_pick_front_wave = 0,
         flex_pick_front_item = null,
         lastuser = in_userid,
         lastupdate = sysdate
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) <> 0
     and status = 'E'
     and nvl(flex_pick_front_wave,0) <> in_wave
     and exists(
       select 1
         from waves
        where wave = lo.flex_pick_front_wave
          and wavestatus = '4')
     and not exists(
       select 1
         from plate
        where facility = lo.facility
          and location = lo.locid);
     
  select count(1)
    into fpfCount
    from location
   where facility = in_facility
     and loctype = 'FPF'
     and nvl(flex_pick_front_wave,0) = 0
     and status = 'E';
  
  select count(1)
    into itemCount
    from (
      select distinct oh.custid, od.item
        from orderhdr oh, orderdtl od
       where oh.wave = in_wave
         and od.orderid = oh.orderid
         and od.shipid = oh.shipid);
  
  if itemCount > fpfCount then
    zms.log_autonomous_msg('WaveRelease', in_facility, '',
      'Wave ' || in_wave || '-not enough empty FPF locations.',
      'W', in_userid, strMsg);
    out_msg := 'Wave ' || in_wave || '-not enough empty FPF locations.';
    return;
  end if;

  -- allocate FPF locations for all items in the wave
  for oi in curOrderItems
  loop
    loc := null;
    open curFPFLocations(wv.fpf_begin_location);
    fetch curFPFLocations into loc;
    close curFPFLocations;
  
    if loc.locid is null then
      zms.log_autonomous_msg('WaveRelease', in_facility, '',
        'Wave ' || in_wave || '-not enough empty FPF locations.',
        'W', in_userid, strMsg);
      out_msg := 'Wave ' || in_wave || '-not enough empty FPF locations.';
      rollback;
      return;
    end if;
    
    -- update FPF for wave/item
    update location
       set flex_pick_front_wave = in_wave,
           flex_pick_front_item = oi.item,
           lastuser = in_userid,
           lastupdate = sysdate
     where facility = in_facility
       and locid = loc.locid;
  end loop;
end if;

if in_reqtype = 'MASSMAN' then
  zms.log_msg('WaveRelease', in_facility, '',
    'Wave ' || in_wave || ' mass manifest',
    'T', in_userid, strMsg);
end if;

if wv.consolidated = 'Y' then
  in_picktype := 'BAT';
  update orderhdr
     set shiptype = wv.shiptype,
         carrier = wv.carrier,
         deliveryservice = wv.servicelevel,
         stageloc = wv.stageloc
   where wave = in_wave;
	l_sortloc := wv.stageloc;
else
	l_sortloc := wv.sortloc;
end if;

delete from batchtasks
 where wave = in_wave
   and taskid = 0;

for oh in curOrders
loop
--  zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
--    'Processing Order ' || oh.orderid || '-' || oh.shipid,
--    'W', in_userid, out_msg);
/* staging location restriction removed
  if (oh.stageloc is null) and
     (wv.stageloc is null) then
    cntRows := 0;
    begin
      select count(1)
        into cntRows
        from orderdtl
       where orderid = oh.orderid
         and shipid = oh.shipid
         and linestatus != 'X'
         and nvl(xdockorderid,0) != 0;
    exception when others then
      cntRows := 0;
    end;
    if cntRows <> 0 then
      out_msg := 'OKAY--Staging Location Required (crossdock items on order ' ||
         oh.orderid || '-' || oh.shipid || ')';
      zms.log_msg('WaveRelease', in_facility, oh.custid,
        'Staging Location Required (crossdock items on order ' ||
        oh.orderid || '-' || oh.shipid || ')',
        'E', in_userid, out_msg);
      zoh.add_orderhistory(oh.orderid, oh.shipid,'Error',out_msg,in_userid, strMsg);
      return;
    end if;
  end if;
*/
-- to reset null values
  update orderdtl
     set fromfacility = oh.fromfacility,
         custid = oh.custid,
         priority = oh.priority
   where orderid = oh.orderid
     and shipid = oh.shipid
     and ( (fromfacility is null) or
           (custid is null) or
           (priority is null) );

  if oh.priority = '0' then
    strTaskPriority := '2';
  else
    strTaskPriority := in_taskpriority;
  end if;

  release_order(
    oh.orderid,
    oh.shipid,
    in_reqtype,
    oh.fromfacility,
    strTaskPriority,
    in_picktype,
    in_userid,
    in_trace,
    out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
        out_msg, 'W', in_userid, strMsg);
    cntError := cntError + 1;
  end if;

end loop;

zbp.generate_batch_tasks(in_wave,in_facility,in_taskpriority,
  wv.picktype,wv.batchcartontype,l_sortloc,in_userid,
  in_trace,wv.consolidated,out_errorno,out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('LineRelease', in_facility, null,
    out_msg, 'W', in_userid, strMsg);
  cntError := cntError + 1;
end if;

update waves
   set wavestatus = '3',
       actualrelease = sysdate,
       schedrelease = null,
       lastuser = in_userid,
       lastupdate = sysdate
 where wave = in_wave;

for oh in curOrders
loop
  zlb.compute_order_labor(oh.orderid,oh.shipid,oh.fromfacility,in_userid,
    out_errorno,out_msg);
  if out_errorno != 0 then
    zms.log_msg('LABORCALC', oh.fromfacility, oh.custid,
        out_msg, 'E', in_userid, strMsg);
    cntError := cntError + 1;
  end if;
end loop;

begin
  select upper(substr(zci.default_value('UPGRADEREPLONRELEASE'),1,1))
    into strUpgrade
    from dual;
exception when others then
  strUpgrade := 'N';
end;

if strUpgrade = 'Y' then
  for rp in curCheckForReplenishments
  loop
     update subtasks
       set priority = ztk.upgrade_priority(priority)
     where facility = in_facility
       and custid = rp.custid
       and item = rp.item
       and tasktype = 'RP'
       and priority in  ('2','3','4');
    update tasks
       set priority = ztk.upgrade_priority(priority)
     where facility = in_facility
       and custid = rp.custid
       and item = rp.item
       and tasktype = 'RP'
       and priority in  ('2','3','4');
  end loop;
end if;

if (in_reqtype = 'AggInven') then
  compress_ai_wave(in_wave, out_msg);
  if substr(out_msg, 1, 4) != 'OKAY' then
          zms.log_msg('WaveRelease', in_facility, null, out_msg, 'W', in_userid, strMsg);
          cntError := cntError + 1;
  end if;
end if;

if wv.consolidated = 'Y' then
  zbp.update_consolidated_tasks(in_wave,in_userid,in_trace,out_errorno,out_msg);
  if out_errorno <> 0 then
    zms.log_msg('Wave Release', in_facility, null,
      out_msg, 'W', in_userid, strMsg);
    cntError := cntError + 1;
  end if;
end if;

if wv.use_flex_pick_fronts_yn = 'Y' then
  for oi in curOrderItems
  loop
    fpfloc := null;
    open curFPFLocation(oi.item);
    fetch curFPFLocation into fpfloc;
    close curFPFLocation;
  
    if fpfloc.locid is null then
      zms.log_autonomous_msg('WaveRelease', in_facility, '',
        'Wave ' || in_wave || '-unable to find FPF location for ' || oi.item,
        'W', in_userid, strMsg);
      out_msg := 'Wave ' || in_wave || '-unable to find FPF location for ' || oi.item;
      rollback;
      return;
    end if;
    
    select count(1)
      into cntRows
      from subtasks
     where facility = in_facility
       and fromloc = fpfloc.locid;
    
    if (cntRows > 0) then
      -- create replenishment tasks
      zrp.send_replenish_msg_no_commit('REPLPP', in_facility, oi.custid, oi.item,
        fpfloc.locid, in_userid, in_trace, out_errorno, out_msg);
    
      if (out_msg != 'OKAY') then
         zms.log_msg('WaveRelease', in_facility, oi.custid, 'Replenishment error: ' ||
           out_msg, 'E', in_userid, strMsg);
         cntError := cntError + 1;
      end if;
    else
      -- clear unneeded FPF locations
      update location
         set flex_pick_front_wave = 0,
             flex_pick_front_item = null,
             lastuser = in_userid,
             lastupdate = sysdate
       where facility = in_facility
         and locid = fpfloc.locid;
    end if;
  end loop;
end if;

for cso in curShortOrders
loop
  l_wave := in_wave;
  unrelease_order(
    cso.orderid,
    cso.shipid,
    cso.fromfacility,
    in_userid,
    in_reqtype,
    in_trace,
    l_wave,
    out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', cso.fromfacility, cso.custid,
        out_msg, 'W', in_userid, strMsg);
    cntError := cntError + 1;
  end if;
end loop;

for ccsr in curCSREmails
loop
  msg := 'The following short orders at facility ' || in_facility || ' require action: ';
  msgCount := 0;
  for ccsro in curCSROrders(ccsr.csr_email)
  loop
    if (msgCount > 0) then
      msg := msg || ', ';
    end if;
    msg := msg || to_char(ccsro.orderid) || '-' || to_char(ccsro.shipid);
    msgCount := msgCount + 1;
  end loop;
  msg := msg || '.';
  begin
    zsmtp.mail(ccsr.csr_email, 'Synapse Alert: Short orders requiring action', msg);
  exception when others then
    zms.log_msg('WaveRelease', in_facility, null, 'CSR Email error: ' ||
      sqlerrm, 'E', in_userid, strMsg);
  end;      
end loop;

if wv.sdi_sortation_yn = 'Y' then
   msg := 'Wave ' || in_wave || ' SDI sorter process ' || wv.sdi_sorter_process;
   zms.log_autonomous_msg('WaveRelease',in_facility,null,msg,'I',in_userid,strMsg);

   msg := '';
   if wv.sdi_sorter_process = 'RETAIL' then
--      zsdi2.sdi_retail_distribution(in_wave, out_errorno, msg);
     null;
   elsif wv.sdi_sorter_process = 'WHOLESALE' then
--      zsdi2.sdi_wholesale_distribution(in_wave, out_errorno, msg);
     null;
   else
      out_errorno := 0;
   end if;
   if out_errorno != 0  then
      zms.log_autonomous_msg('WaveRelease',in_facility,null,msg,'E',in_userid,strMsg);
      cntError := cntError + 1;
   end if;
end if;

if (cntError > 0) then
  msg := 'Wave ' || in_wave || ' ' || cntError || ' warnings generated';
  zms.log_autonomous_msg('WaveRelease',in_facility,null,msg,'W',in_userid,strMsg);
end if;

out_msg := 'OKAY (' || cntError || ' warnings were generated)';

exception when others then
  out_msg := 'wvrw ' || sqlerrm;
end release_wave;

procedure release_order
(in_orderid varchar2
,in_shipid number
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_trace varchar2
,out_msg IN OUT varchar2
) is

cursor curOrderDtls is
  select item as orderitem,
         lotnumber,
         custid,
         fromfacility,
         invclassind,
         inventoryclass
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curOrderHdr is
  select nvl(loadno,0) as loadno,
         nvl(stopno,0) as stopno,
         nvl(shipno,0) as shipno,
         nvl(wave,0) as wave,
         custid,
         stageloc,
         carrier,
         shiptype,
         fromfacility,
         priority,
         FTZ216Authorization
    from orderhdrview
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curWaves(in_wave number) is
  select stageloc,
         sortloc,
         batchcartontype,
         nvl(consolidated, 'N') consolidated
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curCarrierStageLoc is
  select stageloc
    from carrierstageloc
   where carrier = oh.carrier
     and facility = oh.fromfacility
     and shiptype = oh.shiptype;
cs curCarrierStageLoc%rowtype;

cursor curShippingPlates is
  select lpid,
         fromlpid
    from shippingplate sp
   where orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P')
     and status = 'U'
     and not exists
       (select 1
          from subtasks st
         where st.shippinglpid = sp.lpid)
     and not exists
       (select 1
          from batchtasks bt
         where bt.orderid = sp.orderid
           and bt.shipid = sp.shipid);

cntError integer;
out_errorno integer;
strMsg varchar2(255);
cntRows integer;

cursor curSysDef(in_id varchar2) is
  select defaultvalue
    from systemdefaults
   where defaultid = in_id;

ftzClasses varchar2(255);
cntFTZ integer;
new_priority orderhdr.priority%type;
tsk_touserid tasks.touserid%type;
tsk_priority tasks.priority%type;
intErrorno integer;
l_prelim_packlist_rpt customer_aux.prelim_packlist_rpt%type;
l_prelim_packlist_printer customer_aux.prelim_packlist_printer%type;

begin

out_msg := '';
cntError := 0;

open curOrderhdr;
fetch curOrderhdr into oh;
if curOrderhdr%notfound then
  close curOrderHdr;
  out_msg := 'Order Header Not Found';
  return;
end if;
close curOrderhdr;

delete from batchtasks
 where wave = oh.wave
   and orderid = in_orderid
   and shipid = in_shipid
   and facility is null;

delete from subtasks
 where wave = oh.wave
   and orderid = in_orderid
   and shipid = in_shipid
   and (facility is null
    or  taskid = 0);

delete from tasks
 where wave = oh.wave
   and orderid = in_orderid
   and shipid = in_shipid
   and facility is null;

delete from batchtasks
 where orderid = in_orderid
   and shipid = in_shipid
   and not exists
       (select 1
          from subtasks
         where subtasks.taskid = batchtasks.taskid
           and rownum = 1);

for sp in curShippingPlates
loop
  update plate pl
     set qtytasked = nvl((select sum(st.qty-nvl(st.qtypicked,0))
                            from subtasks st
                           where st.lpid = pl.lpid
                             and st.tasktype in ('RP','PK','OP','BP','SO')),0),
         lastuser = in_userid,
         lastupdate = sysdate
   where lpid = sp.fromlpid;
   
  delete from shippingplate
   where lpid = sp.lpid;
end loop;

open curWaves(oh.wave);
fetch curWaves into wv;
if curWaves%notfound then
  close curWaves;
  out_msg := 'Wave Not Found';
  return;
end if;
close curWaves;

if oh.stageloc is null then
  if wv.stageloc is not null then
    oh.stageloc := wv.stageloc;
  else
    cs := null;
    open curCarrierStageloc;
    fetch curCarrierStageLoc into cs;
    close curCarrierStageLoc;
    if cs.stageloc is not null then
      oh.stageloc := cs.stageloc;
    end if;
  end if;
end if;

ftzClasses := null;
open curSysDef('FOREIGNTRADEZONECLASSES');
fetch CurSysDef into ftzClasses;
close curSysDef;
cntFTZ := 0;

--zut.prt('releasing lines');
for ol in curOrderDtls
loop
  if in_trace = 'Y' then
    zms.log_msg('WaveRelease', ol.fromfacility, ol.custid,
      'Processing Line ' || in_orderid || '-' || in_shipid  || ' ' ||
      ol.orderitem || ' ' || ol.lotnumber,
      'T', in_userid, strMsg);
  end if;

  if ol.invclassind = 'I' and nvl(FTZClasses,'(none)') <> '(none)' and
     instr( ','||FTZClasses||',',','||ol.inventoryclass||',') > 0 then
     cntFTZ := cntFTZ + 1;
  end if;

  zwv.release_line(
    in_orderid,
    in_shipid,
    ol.orderitem,
    ol.lotnumber,
    in_reqtype,
    in_facility,
    in_taskpriority,
    in_picktype,
    'N',
    oh.stageloc,
    wv.sortloc,
    wv.batchcartontype,
    'N',
    in_userid,
    in_trace,
    1, -- initialize recursion counter to 1
    out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', ol.fromfacility, ol.custid,
        out_msg, 'W', in_userid, strMsg);
    cntError := cntError + 1;
  end if;
end loop;

--zut.prt('complete from release order ' || in_orderid);
if (in_reqtype = 'AggInven') then
  tsk_touserid := '(AggInven)';
  tsk_priority := '9';
else
  tsk_touserid := null;
  tsk_priority := in_taskpriority;
end if;
complete_pick_tasks(oh.wave,in_facility,in_orderid,in_shipid,tsk_priority,
	in_taskpriority, in_picktype, in_userid, null, tsk_touserid, wv.consolidated,
	in_trace, out_errorno, out_msg);
if substr(out_msg,1,4) != 'OKAY' then
  zms.log_msg('WaveRelease', in_facility, oh.custid,
      out_msg, 'W', in_userid, strMsg);
  cntError := cntError + 1;
end if;

new_priority := oh.priority;
if cntFTZ > 0 and oh.FTZ216Authorization is null then
   new_priority := 'E';
end if;

update orderhdr
   set orderstatus = '4',
       commitstatus = '3',
       priority = new_priority,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid
   and orderstatus < '4';

if oh.loadno != 0 then
  zld.min_load_status(oh.loadno,in_facility,'3',in_userid);
  zld.min_loadstop_status(oh.loadno,oh.stopno,in_facility,'3',in_userid);
end if;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Released',
     'Order Released Wave: '||oh.wave,
     in_userid, out_msg);

zprono.check_for_prono_assignment
(in_orderid
,in_shipid
,'Wave Release'
,intErrorno
,strMsg
);

begin
  select prelim_packlist_rpt, prelim_packlist_printer
    into l_prelim_packlist_rpt, l_prelim_packlist_printer
    from customer_aux
   where custid = oh.custid;
exception when others then
  l_prelim_packlist_rpt := null;
  l_prelim_packlist_printer := null;
end;

if l_prelim_packlist_rpt is not null then
  if l_prelim_packlist_printer is null then
    begin
      select defaultprinter
        into l_prelim_packlist_printer
        from userheader
       where nameid = in_userid;
    exception when others then
      l_prelim_packlist_printer := null;
    end;
  end if;
  if l_prelim_packlist_printer is not null then
    zmnq.send_shipping_msg(in_orderid,
                          in_shipid,
                          l_prelim_packlist_printer,
                          l_prelim_packlist_rpt,
                          null,
			  null,
                          out_msg);
  end if;
end if;

if (in_reqtype = 'RELORD') and (oh.wave != 0) then
  select count(1)
    into cntRows
    from orderhdr
   where wave = oh.wave
     and orderstatus < '4';
  
  if cntRows = 0 then
    update waves
       set wavestatus = '3',
           actualrelease = sysdate,
           schedrelease = null,
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = oh.wave;
  end if;
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvro ' || sqlerrm;
end release_order;

procedure find_a_pick
(in_fromfacility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_invstatus varchar2
,in_inventoryclass varchar2
,in_qty number
,in_pickuom varchar2
,in_repl_req_yn varchar2
,in_storage_or_stage varchar2
,in_ordered_by_weight varchar2
,in_qtytype varchar2
,in_wave number
,in_bat_zone_only varchar2
,in_parallel_pick_zones varchar2
,in_expdaterequired varchar2
,in_enter_min_days_to_expire_yn varchar2
,in_min_days_to_expiration number
,in_allocrule varchar2
,in_pass_count number
,out_lpid_or_loc IN OUT varchar2
,out_baseuom IN OUT varchar2
,out_baseqty IN OUT number
,out_pickuom IN OUT varchar2
,out_pickqty IN OUT number
,out_pickfront IN OUT varchar2
,out_picktotype IN OUT varchar2
,out_cartontype IN OUT varchar2
,out_picktype IN OUT varchar2
,out_wholeunitsonly IN OUT varchar2
,out_weight IN OUT number
,in_trace IN varchar2
,out_msg IN OUT varchar2) is

cursor curAllocRule(in_allocrule varchar2) is
  select rowid,
         priority,
         uom,
         nvl(qtymin,1) as qtymin,
         nvl(qtymax,9999999) as qtymax,
         nvl(in_parallel_pick_zones,pickingzone) as pickingzone,
         nvl(usefwdpick,'N') as usefwdpick,
         nvl(lifofifo,'F') as lifofifo,
         nvl(datetype,'M') as datetype,
         nvl(picktoclean,'N') as picktoclean,
         nvl(wholeunitsonly,'N') as wholeunitsonly,
         nvl(wholelponly,'N') as wholelponly,
         nvl(bylot,'N') as bylot,
         nvl(pickfrontfifo,'N') as pickfrontfifo,
         nvl(strictfifo,'N') as strictfifo,
         nvl(storage_code_field,'x') as storage_code_field,
         nvl(code_date_field,'x') as code_date_field
    from allocrulesdtl
   where facility = in_fromfacility
     and allocrule = in_allocrule
     and ( (invstatus is null) or
           (invstatus = in_invstatus) )
     and ( (inventoryclass is null) or
            inventoryclass = nvl(in_inventoryclass,'RG') )
   order by priority;
ar curAllocRule%rowtype;

cursor curItem is
  select baseuom, lotrequired, fifowindowdays
    from custitemview
   where custid = in_custid
     and item = in_item;
it curItem%rowtype;

cursor curItemFacility is
  select allocrule,
         replallocrule
    from custitemfacilityview
   where custid = in_custid
     and item = in_item
     and facility = in_fromfacility;
itf curItemFacility%rowtype;

cursor c_pkzn(p_facility varchar2, p_location varchar2) is
   select ZN.deconsolidation
      from location LO, zone ZN
      where LO.facility = p_facility
        and LO.locid = p_location
        and ZN.facility (+) = LO.facility
        and ZN.zoneid (+) = LO.pickingzone;
pkzn c_pkzn%rowtype;

cursor c_lp(p_lpid varchar2) is
   select quantity
      from plate
      where lpid = p_lpid;

cursor curWave is
   select nvl(use_flex_pick_fronts_yn,'N') use_flex_pick_fronts_yn,
          nvl(fpf_full_picks_bypass_fpf,'N') fpf_full_picks_bypass_fpf,
          fpf_begin_location,
          allocrule,
          fpf_pick_allocrule
     from waves
    where wave = in_wave;
wv curWave%rowtype;

cursor curFPFLocation is
   select locid
     from location
    where facility = in_fromfacility
      and nvl(flex_pick_front_wave,0) = in_wave
      and flex_pick_front_item = in_item;
loc curFPFLocation%rowtype;
      
qtyRemain plate.quantity%type;
base curAllocRule%rowtype;
curPlate integer;
curPickfront integer;
cntRows integer;
lp plate%rowtype;
ignore_wholelp char(1);
pf itempickfronts%rowtype;
cmdSql varchar2(2000);
viewtouse varchar2(30);
lLotNumber plate.lotnumber%type;
strOutMsg appmsgs.msgtext%type;
palletuom unitsofmeasure.code%type;
palletqty number(9,2);
minpalletqty number(9,2);
find_smallest_lp char(1);
lAllocRuleCount number(1);
curFIFODate integer;
lFIFODate date;
curStorageCode integer;
lStorageCode varchar2(255);
curCodeDate integer;
lCodeDate varchar2(8);

procedure trace_msg(in_msg varchar2) is
numCols integer;

begin

  if nvl(in_trace,'x') != 'Y' then
    return;
  end if;

  numCols := 1;
  while (numCols * 254) < (Length(in_msg)+254)
  loop
    zms.log_msg('FINDPLATE', in_fromfacility, in_custid,
                substr(in_msg,((numCols-1)*254)+1,254),
                'T', 'FINDPLATE', strOutMsg);
    numCols := numCols + 1;
  end loop;

end;

begin

out_msg := '';
out_lpid_or_loc := '';
out_weight := 0;

trace_msg('Itm: ' || in_item || ' ' ||
          'Lot: ' || nvl(in_lotnumber,'(none)') || ' ' ||
          'Order ID: ' || in_orderid || ' ' ||
          'Ship ID: ' || in_shipid || ' ' ||
          'InvStat: ' || in_invstatus || ' ' ||
          'InvClass: ' || in_inventoryclass || ' ' ||
          'Qty: ' || in_qty || ' ' ||
          'PickUOM: ' || nvl(in_pickuom,'(none)') || ' ' ||
          'ReplYN: ' || in_repl_req_yn || ' ' ||
          'STOorSTG: ' || in_storage_or_stage || ' ' ||
          'ByWeightYN: ' || in_ordered_by_weight || ' ' ||
          'BATonly: ' || in_bat_zone_only || ' ' ||
          'QtyType: ' || in_qtytype || ' ' ||
          'PassCount: ' || nvl(in_pass_count,2));

open curItem;
fetch curItem into it;
if curItem%notfound then
  it.baseuom := 'EA';
  trace_msg('Item not found: base uom defaults to EA');
else
  trace_msg('Item baseuom is ' || it.baseuom);
end if;
close curItem;
out_baseuom := it.baseuom;

wv := null;
open curWave;
fetch curWave into wv;
close curWave;

ignore_wholelp := 'N';
if (nvl(in_repl_req_yn,'N') = 'Y') and
   (nvl(out_wholeunitsonly,'N') = 'Y') then
  ignore_wholelp := 'Y';
end if;
out_wholeunitsonly := 'N';

itf := null;
open curItemFacility;
fetch curItemFacility into itf;
close curItemFacility;
  
if (nvl(in_allocrule,'C') = 'C') then
  if wv.allocrule is not null then
    ar := null;
    open curAllocRule(wv.allocrule);
    fetch curAllocRule into ar;
    close curAllocRule;
    
    if ar.priority is not null then
      itf.allocrule := wv.allocrule;
    end if;
  end if;

  if (wv.use_flex_pick_fronts_yn = 'Y' and wv.fpf_pick_allocrule is not null) then
    ar := null;
    open curAllocRule(wv.fpf_pick_allocrule);
    fetch curAllocRule into ar;
    close curAllocRule;
    
    if ar.priority is not null then
      itf.allocrule := wv.fpf_pick_allocrule;
    end if;
  end if;

  if in_repl_req_yn = 'Y' then
    if itf.replallocrule is not null then
      itf.allocrule := itf.replallocrule;
    else
      trace_msg('Note: Replenishment allocation rule defaults to pick allocation rule: ' || itf.allocrule);
    end if;
  end if;
  
  if itf.allocrule is null then
    out_msg := 'Cannot allocate: No allocation rule defined for item';
    trace_msg(out_msg);
    return;
  end if;
else
  itf.allocrule := in_allocrule;
end if;

if (wv.use_flex_pick_fronts_yn = 'Y') and
   ((wv.fpf_pick_allocrule is null) or
    (wv.fpf_pick_allocrule != itf.allocrule)) then
  if (in_storage_or_stage = 'FPF') then
    trace_msg('Flexible pick item: ' || in_item);
    out_msg := '';
    
    loc := null;
    open curFPFLocation;
    fetch curFPFLocation into loc;
    close curFPFLocation;
    
    if (loc.locid is null) then
      out_msg := 'No inventory found';
      return;
    end if;
  
    out_lpid_or_loc := loc.locid;

    for ar in curAllocRule(itf.allocrule)
    loop
      trace_msg('Pri: ' || ar.priority || ' ' ||
            'UOM: ' || ar.uom || ' ' ||
            'Min: ' || ar.qtyMin || ' ' ||
            'Max: ' || ar.qtyMax || ' ' ||
            'Zone: ' || ar.pickingzone || ' ' ||
            'UseFwdPick: ' || ar.usefwdpick || ' ' ||
            'LifoFifo: ' || ar.lifofifo || ' ' ||
            'Date: ' || ar.datetype || ' ' ||
            'Clean: ' || ar.picktoclean || ' ' ||
            'WholeUOM: ' || ar.wholeunitsonly || ' ' ||
            'WholeLP: ' || ar.wholelponly);

      zbut.translate_uom(in_custid,in_item,ar.qtyMin,ar.uom,it.baseuom,base.qtyMin,out_msg);
      if substr(out_msg,1,4) != 'OKAY' then
        trace_msg('Skip rule: cannot translate min from ' || ar.uom || ' to ' || it.baseuom);
        goto continue_loop;
      end if;
      zbut.translate_uom(in_custid,in_item,ar.qtyMax,ar.uom,it.baseuom,base.qtyMax,out_msg);
      if substr(out_msg,1,4) != 'OKAY' then
        trace_msg('Skip rule: cannot translate max from ' || ar.uom || ' to ' || it.baseuom);
        goto continue_loop;
      end if;
    
      if (in_qty < base.qtyMin) or
         (in_qty > base.qtyMax) then
        trace_msg('Skip rule: quantity not eligible ' || ar.uom || ' ' || in_qty ||
          ' min ' || base.qtyMin || ' max ' || base.qtyMax);
        goto continue_loop;
      end if;
    
      zbut.translate_uom(in_custid,in_item,in_qty,it.baseuom,ar.uom,out_pickqty,out_msg);
      if substr(out_msg,1,4) != 'OKAY' then
        trace_msg('Skip rule: cannot translate max from ' || it.baseuom || ' to ' || ar.uom);
        goto continue_loop;
      end if;
      out_pickqty := floor(out_pickqty);
      if (out_pickqty = 0) then
        goto continue_loop;
      end if;
      
      zbut.translate_uom(in_custid,in_item,out_pickqty,ar.uom,it.baseuom,out_baseqty,out_msg);
      if substr(out_msg,1,4) != 'OKAY' then
        trace_msg('Skip rule: cannot translate max from ' || ar.uom || ' to ' || it.baseuom);
        goto continue_loop;
      end if;
      if (out_baseqty = 0) then
        goto continue_loop;
      end if;

      out_msg := 'OKAY';
      out_pickuom := ar.uom;
      out_weight := out_baseqty * zci.item_weight(in_custid,in_item,ar.uom);
      out_picktotype := zci.picktotype(in_custid,in_item,ar.uom);
      out_cartontype := zci.cartontype(in_custid,in_item,ar.uom);
      out_picktype := default_picktype(in_fromfacility,loc.locid);
      out_pickfront := 'Y';
    
      return;
    <<continue_loop>>
      null;
    end loop;

    out_msg := 'OKAY';
    out_baseqty := in_qty;   
    out_pickqty := in_qty;
    out_pickuom := it.baseuom;
    out_weight := out_baseqty * zci.item_weight(in_custid,in_item,it.baseuom);
    out_picktotype := zci.picktotype(in_custid,in_item,it.baseuom);
    out_cartontype := zci.cartontype(in_custid,in_item,it.baseuom);
    out_picktype := default_picktype(in_fromfacility,loc.locid);
    out_pickfront := 'Y';
    return;
  end if;
  
  palletuom := null;
  if (wv.fpf_full_picks_bypass_fpf = 'Y') then
    palletuom := nvl(zci.default_value('PALLETSUOM'),'PLT');
    zbut.translate_uom(in_custid,in_item,in_qty,
        it.baseuom,palletuom,palletqty,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_msg := 'Unable to translate pallet uom ' || palletuom;
      trace_msg(out_msg);
      return;
    end if;
    
    minpalletqty := floor(palletqty);
    if (minpalletqty < 1) then
      out_msg := 'No inventory found';
      return;
    end if;

    zbut.translate_uom(in_custid,in_item,1,
        palletuom,it.baseuom,palletqty,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      out_msg := 'Unable to translate pallet uom ' || palletuom;
      trace_msg(out_msg);
      return;
    end if;
  end if;
end if;

lFIFODate := null;
if (it.fifowindowdays is not null) and (nvl(in_pass_count,2) < 2) then
  trace_msg('FIFO Window Days ' || it.fifowindowdays);
  
  ar := null;
  open curAllocRule(itf.allocrule);
  fetch curAllocRule into ar;
  close curAllocRule;
  
  trace_msg('Date Type ' || ar.DateType);
  
  if (ar.DateType not in ('L','C')) then
    select count(1)
      into lAllocRuleCount
      from allocrulesdtl
     where facility = in_fromfacility
       and allocrule = itf.allocrule
       and ( (invstatus is null) or
             (invstatus = in_invstatus) )
       and ( (inventoryclass is null) or
              inventoryclass = nvl(in_inventoryclass,'RG') )
       and nvl(usefwdpick,'N') = 'N'
       and rownum = 1;
  
    if (lAllocRuleCount >= 1) then
      if (ar.LifoFifo = 'L') then
        cmdSql := 'select max(trunc(';
      else
        cmdSql := 'select min(trunc(';
      end if;
      
      if ar.DateType = 'M' then
        cmdSql := cmdSql || 'manufacturedate';
      elsif ar.DateType = 'E' then
        cmdSql := cmdSql || 'expirationdate';
      else
        cmdSql := cmdSql || 'least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate)))';
      end if;
      
      cmdSql := cmdSql || ')) fifodate from ';
      
      if (nvl(in_lotnumber,'(none)') <> '(none)') then
        cmdSql := cmdSql || 'availstatusclassview';
      else
        cmdSql := cmdSql || 'availstatusclassviewnolot';
      end if;
  
      cmdSql := cmdSql || ' where facility = ''' || in_fromfacility || '''' ||
          ' and custid = ''' || in_custid || '''' ||
          ' and item = ''' || in_item || '''';
    
      if nvl(in_lotnumber,'(none)') <> '(none)' then
        cmdSql := cmdSql || ' and lotnumber = ''' || in_lotnumber || '''';
      end if;
  
      if nvl(in_invstatus,'(none)') <> '(none)' then
        cmdSql := cmdSql || ' and invstatus = ''' || in_invstatus || '''';
      end if;

      if nvl(in_inventoryclass,'(none)') <> '(none)' then
        cmdSql := cmdSql || ' and inventoryclass = ''' || in_inventoryclass || '''';
      end if;

      begin
        lp := null;
        trace_msg(cmdSql);
        curFIFODate := dbms_sql.open_cursor;
        dbms_sql.parse(curFIFODate, cmdSql, dbms_sql.native);
        dbms_sql.define_column(curFIFODate,1,lp.manufacturedate);
        cntRows := dbms_sql.execute(curFIFODate);
        cntRows := dbms_sql.fetch_rows(curFIFODate);
        if cntRows > 0 then
          dbms_sql.column_value(curFIFODate,1,lp.manufacturedate);
        end if;
        dbms_sql.close_cursor(curFIFODate);
      exception when no_data_found then
        dbms_sql.close_cursor(curFIFODate);
      end;
      
      lFIFODate := lp.manufacturedate;
    end if;
    
    if (lFIFODate is not null) then
      if (ar.LifoFifo = 'L') then
        lFIFODate := lFIFODate - it.fifowindowdays;
      else
        lFIFODate := lFIFODate + it.fifowindowdays;
      end if;
      trace_msg('FIFO Date ' || to_char(lFIFODate,'MM/DD/YYYY'));
    end if;
  end if;
end if;

trace_msg('Using allocation rule: ' || itf.allocrule);

ar := null;
for ar in curAllocRule(itf.allocrule)
loop
  find_smallest_lp := 'N';
  if (ar.picktoclean <> 'Y') and (nvl(in_pass_count,2) = 1) then
    find_smallest_lp := 'Y';
  end if;
<< find_again >>
  trace_msg('Pri: ' || ar.priority || ' ' ||
            'UOM: ' || ar.uom || ' ' ||
            'Min: ' || ar.qtyMin || ' ' ||
            'Max: ' || ar.qtyMax || ' ' ||
            'Zone: ' || ar.pickingzone || ' ' ||
            'UseFwdPick: ' || ar.usefwdpick || ' ' ||
            'LifoFifo: ' || ar.lifofifo || ' ' ||
            'Date: ' || ar.datetype || ' ' ||
            'Clean: ' || ar.picktoclean || ' ' ||
            'WholeUOM: ' || ar.wholeunitsonly || ' ' ||
            'WholeLP: ' || ar.wholelponly || ' ' ||
            'PickFrontFIFO: ' || ar.pickfrontfifo || ' ' ||
            'Strict FIFO: ' || ar.strictfifo || ' ' ||
            'FindSmallestLP: ' || find_smallest_lp || ' ' ||
            'Storage Code: ' || ar.storage_code_field || ' ' ||
            'Code Date: ' || ar.code_date_field);

  lStorageCode := null;
  lCodeDate := null;
  
  if (ar.DateType = 'C') then
    if (instr(ar.storage_code_field,'ITMPASSTHRUCHAR') = 0) then
      trace_msg('Skip rule: Rule uses Code Date, Storage Code Field not set');
      goto continue_loop;
    end if;
    if (instr(ar.code_date_field,'DTLPASSTHRUDATE') = 0) then
      trace_msg('Skip rule: Rule uses Code Date, Code Date Field not set');
      goto continue_loop;
    end if;
    if ((nvl(in_orderid,0) = 0) or (nvl(in_shipid,0) = 0)) then
      trace_msg('Skip rule: Rule uses Code Date, OrderID/ShipID not passed');
      goto continue_loop;
    end if;
    
    cmdSql := 'select nvl('||ar.storage_code_field||',''x'') from custitem ' ||
              'where custid='''||in_custid||''' and item='''||in_item||'''';
    begin
      trace_msg(cmdSql);
      curStorageCode := dbms_sql.open_cursor;
      dbms_sql.parse(curStorageCode, cmdSql, dbms_sql.native);
      dbms_sql.define_column(curStorageCode,1,lStorageCode,255);
      cntRows := dbms_sql.execute(curStorageCode);
      cntRows := dbms_sql.fetch_rows(curStorageCode);
      if cntRows > 0 then
        dbms_sql.column_value(curStorageCode,1,lStorageCode);
      end if;
      dbms_sql.close_cursor(curStorageCode);
    exception when no_data_found then
      dbms_sql.close_cursor(curStorageCode);
    end;

    if (lStorageCode not in ('M','E')) then
      trace_msg('Skip rule: Storage Code not M or E');
      goto continue_loop;
    end if;
    
    cmdSql := 'select to_char(od.' || ar.code_date_field || ', ''YYYYMMDD'') ' ||
              'from commitments cm, orderdtl od ' ||
              'where cm.orderid = ' || in_orderid || ' and ' ||
              'cm.shipid = ' || in_shipid || ' and ' ||
              'cm.item = ''' || in_item || ''' and ' ||
              'nvl(cm.lotnumber,''(none)'') = nvl('''||in_lotnumber||''',''(none)'') and ' ||
              'cm.invstatus = ''' || in_invstatus || ''' and ' ||
              'cm.inventoryclass = ''' || in_inventoryclass || ''' and ' ||
              'od.orderid = cm.orderid and ' ||
              'od.shipid = cm.shipid and ' ||
              'od.item = cm.orderitem and ' ||
              'nvl(od.lotnumber,''(none)'') = nvl(cm.orderlot,''(none)'')';
    begin
      trace_msg(cmdSql);
      curCodeDate := dbms_sql.open_cursor;
      dbms_sql.parse(curCodeDate, cmdSql, dbms_sql.native);
      dbms_sql.define_column(curCodeDate,1,lCodeDate,8);
      cntRows := dbms_sql.execute(curCodeDate);
      cntRows := dbms_sql.fetch_rows(curCodeDate);
      if cntRows > 0 then
        dbms_sql.column_value(curCodeDate,1,lCodeDate);
      end if;
      dbms_sql.close_cursor(curCodeDate);
    exception when no_data_found then
      dbms_sql.close_cursor(curCodeDate);
    end;

    if (nvl(lCodeDate,'19800101') = '19800101') then
      trace_msg('Skip rule: Code Date not set');
      goto continue_loop;
    end if;

    if (ar.useFwdPick = 'Y') then
      ar.useFwdPick := 'N';
    end if;
    
    if (ar.lifofifo = 'L') then
      ar.lifofifo := 'F';
    end if;
    
    trace_msg('Storage Code: '||lStorageCode||'/Code Date:'||lCodeDate);
  end if;

  if (ar.useFwdPick = 'Y') and
     (ar.pickingzone is null) and
     (wv.use_flex_pick_fronts_yn = 'Y') and
     (wv.fpf_pick_allocrule = itf.allocrule) then
    trace_msg('Flexible pick item: ' || in_item);
    out_msg := '';
    
    loc := null;
    open curFPFLocation;
    fetch curFPFLocation into loc;
    close curFPFLocation;
    
    if (loc.locid is null) then
      out_msg := 'No inventory found';
      return;
    end if;
  
    out_msg := 'OKAY';
    out_lpid_or_loc := loc.locid;
    out_baseqty := in_qty;
    out_pickqty := in_qty;
    out_pickuom := it.baseuom;
    out_weight := out_baseqty * zci.item_weight(in_custid,in_item,it.baseuom);
    out_picktotype := zci.picktotype(in_custid,in_item,it.baseuom);
    out_cartontype := zci.cartontype(in_custid,in_item,it.baseuom);
    out_picktype := default_picktype(in_fromfacility,loc.locid);
    out_pickfront := 'Y';
    return;
  end if;

  zbut.translate_uom(in_custid,in_item,ar.qtyMin,ar.uom,it.baseuom,base.qtyMin,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    trace_msg('Skip rule: cannot translate min from ' || ar.uom || ' to ' || it.baseuom);
    goto continue_loop;
  end if;
  zbut.translate_uom(in_custid,in_item,ar.qtyMax,ar.uom,it.baseuom,base.qtyMax,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    trace_msg('Skip rule: cannot translate max from ' || ar.uom || ' to ' || it.baseuom);
    goto continue_loop;
  end if;
  out_msg := '';
  out_picktotype := zci.picktotype(in_custid,in_item,ar.uom);
  out_cartontype := zci.cartontype(in_custid,in_item,ar.uom);
  out_pickuom := ar.uom;
  out_pickfront := ar.UseFwdPick;
  if (rtrim(in_pickuom) is null) then -- standard order allocation (follow the quantity rules)
    if in_ordered_by_weight != 'Y' then
      if (in_qty < base.qtyMin) or
         (in_qty > base.qtyMax) then
        trace_msg('Skip rule: quantity not eligible ' || ar.uom || ' ' || in_qty ||
          ' min ' || base.qtyMin || ' max ' || base.qtyMax);
        goto continue_loop;
      end if;
    end if;
  else
    if (in_pickuom = 'NOPICKFRONT') then -- replenish uom is same as pick front uom
      if (ar.UseFwdPick = 'Y') then
        trace_msg('Skip rule: don''t replenish from another pick front');
        goto continue_loop;
      else
        trace_msg('Replenish request: pick to clean overrides to ''Y''');
        ar.picktoclean := 'Y'; -- pick replenishments to clean to use partial lips
      end if;
    else
      if in_pickuom != 'IGNORE' then
        if ar.uom != in_pickuom then  -- replenishment allocation
          trace_msg('Skip rule: requested pick UOM not same as rule''s UOM');
          goto continue_loop;
        end if;
      end if;
    end if;
  end if;

  if (nvl(trim(in_parallel_pick_zones),'(none)') <> '(none)') and (ar.useFwdPick <> 'Y') then
    trace_msg('Skip rule: Parallel Pick Zone selected, rule does not use PF');
    goto continue_loop;
  end if;

  if (in_enter_min_days_to_expire_yn = 'Y') and
     (in_expdaterequired = 'Y') and
     (in_min_days_to_expiration > 0) and
     (ar.UseFwdPick = 'Y') then
    ar.UseFwdPick := 'N';
  end if;
  if ar.useFwdPick = 'Y' then
    if (nvl(in_lotnumber,'(none)') <> '(none)') then
      lLotNumber := in_lotnumber;
    else
      lLotNumber := '(none)';
    end if;
    
    cmdSql := 'select apf.pickfront, apf.dynamic from availpickfrontfifoview apf' ||
      ' where apf.facility = ''' || in_fromfacility || '''' ||
      ' and apf.custid = ''' || in_custid || '''' ||
      ' and apf.item = ''' || in_item || '''' ||
      ' and apf.pickuom = ''' || ar.uom || '''';

    if zdpf.count_dynamicpfs(in_fromfacility, in_custid, in_item, ar.uom) > 0 then
      cmdSql := cmdSql || ' and apf.dynamic = ''Y''' ||
      ' and zwv.tasked_at_loc(apf.facility, apf.pickfront, apf.custid, apf.item, ' || in_wave || ', ''' || lLotNumber || ''')' ||
      ' <= (zwv.total_at_loc(apf.facility, apf.pickfront, apf.custid, apf.item, ''' || lLotNumber || ''', ''' || in_invstatus || ''', ''' || in_inventoryclass || ''')' ||
      ' - zlbl.uom_qty_conv(apf.custid, apf.item, 1, apf.pickuom, ''' || it.baseuom || '''))';
    else
      cmdSql := cmdSql || ' and apf.dynamic = ''N''';
    end if;

    if ar.pickingzone is not null then
      cmdSql := cmdSql || ' and apf.pickingzone = ''' || ar.pickingzone || '''';
    end if;

    if nvl(in_lotnumber,'(none)') <> '(none)' then
      cmdSql := cmdSql || ' and exists(select 1' ||
        ' from plate' ||
        ' where facility = apf.facility' ||
        ' and custid = apf.custid' ||
        ' and item = apf.item' ||
        ' and lotnumber = ''' || in_lotnumber || '''' ||
        ' and location = apf.pickfront)';
    end if;

    if ar.pickfrontfifo = 'N' then
      cmdSql := cmdSql || ' order by apf.subtask_total, apf.location_lastupdate';
    else
      cmdSql := cmdSql || ' order by';
      if ar.LifoFifo = 'L' then
        if ar.DateType = 'M' then
          cmdSql := cmdSql || ' apf.maxmfgdate';
        elsif ar.DateType = 'E' then
          cmdSql := cmdSql || ' apf.maxexpdate';
        else
          cmdSql := cmdSql || ' apf.maxcrtdate';
        end if;
        cmdSql := cmdSql || ' desc';
      else
        if ar.DateType = 'M' then
          cmdSql := cmdSql || ' apf.minmfgdate';
        elsif ar.DateType = 'E' then
          cmdSql := cmdSql || ' apf.minexpdate';
        else
          cmdSql := cmdSql || ' apf.mincrtdate';
        end if;
      end if;

      cmdSql := cmdSql || ', zwv.total_at_loc(apf.facility, apf.pickfront, apf.custid, apf.item, ''' || lLotNumber || ''', ''' || in_invstatus || ''', ''' || in_inventoryclass || ''')' ||
                          ' - zwv.tasked_at_loc(apf.facility, apf.pickfront, apf.custid, apf.item, ' || in_wave || ', ''' || lLotNumber || ''')';

      if (ar.picktoclean <> 'Y') then
        cmdSql := cmdSql || ' desc';
      end if;
    end if;

    begin
      trace_msg(cmdSql);
      curPickfront := dbms_sql.open_cursor;
      dbms_sql.parse(curPickfront, cmdSql, dbms_sql.native);
      dbms_sql.define_column(curPickfront,1,pf.pickfront,10);
      dbms_sql.define_column(curPickfront,2,pf.dynamic,1);
      cntRows := dbms_sql.execute(curPickfront);
      cntRows := dbms_sql.fetch_rows(curPickfront);
      if cntRows > 0 then
        dbms_sql.column_value(curPickfront,1,pf.pickfront);
        dbms_sql.column_value(curPickfront,2,pf.dynamic);
      end if;
      dbms_sql.close_cursor(curPickfront);
    exception when no_data_found then
      dbms_sql.close_cursor(curPickfront);
    end;

    if pf.pickfront is null then
      zdpf.build_dynamicpf(in_fromfacility, in_custid, in_item, ar.rowid,
          in_invstatus, in_inventoryclass, lLotNumber, in_wave, pf.pickfront);
      if pf.pickfront is not null then
        pf.dynamic := 'Y';
      end if;
    end if;

    trace_msg('pf.pickfront is ' || pf.pickfront || ' (dynamic ' || pf.dynamic);
    if pf.pickfront is not null then
      if in_ordered_by_weight = 'Y' then
        out_baseqty := zwt.calc_order_by_weight_qty(in_custid,in_item,it.baseuom,in_qty,0,in_qtytype);
      else
        out_baseqty := in_qty;
      end if;
      if pf.dynamic = 'Y' then
        out_baseqty := least(out_baseqty,
            (total_at_loc(in_fromfacility, pf.pickfront, in_custid, in_item, lLotNumber, in_invstatus, in_inventoryclass)
             - tasked_at_loc(in_fromfacility, pf.pickfront, in_custid, in_item, in_wave, lLotNumber)));
      end if;
      zbut.translate_uom(in_custid,in_item,out_baseqty,it.baseuom,ar.uom,out_pickqty,out_msg);
      if in_ordered_by_weight = 'Y' and
         substr(out_msg,1,4) != 'OKAY' then
         out_pickqty := 1;
         out_msg := 'OKAY';
      end if;
      if (substr(out_msg,1,4) = 'OKAY') then
        if (mod(out_pickqty,1) != 0) then
          out_pickqty := floor(out_pickqty+.000001);
          zbut.translate_uom(in_custid,in_item,out_pickqty,ar.uom,it.baseuom,out_baseqty,out_msg);
        end if;
        if out_pickqty <> 0 then
          out_picktype := default_picktype(in_fromfacility,pf.pickfront);
          out_weight := out_baseqty * zci.item_weight(in_custid,in_item,it.baseuom);
          out_lpid_or_loc := pf.pickfront;
          out_msg := 'FOUND';
          exit;
        end if;
      else
        trace_msg('Cannot translate pick front uom ' || ar.uom);
      end if;
    end if;
  else
    if in_storage_or_stage = 'STG' then
      if (nvl(in_lotnumber,'(none)') <> '(none)') or (ar.DateType = 'L') or (ar.bylot = 'Y') then
        viewtouse := 'availstagestatusclassview';
      else
        viewtouse := 'availstagestatusclassviewnolot';
      end if;
    elsif (ar.UseFwdPick = 'N' and out_pickfront = 'Y') then
      out_pickfront := 'N';
      if nvl(in_lotnumber,'(none)') <> '(none)' then
        viewtouse := 'availpfstatusclassview';
      else
        viewtouse := 'availpfstatusclassviewnolot';
      end if;
    else
      if (nvl(in_lotnumber,'(none)') <> '(none)') or (ar.DateType = 'L') or (ar.bylot = 'Y') then
        viewtouse := 'availstatusclassview';
      else
        viewtouse := 'availstatusclassviewnolot';
      end if;
    end if;
    cmdSql := 'select lpid, location, quantity, weight, lotnumber, expirationdate from ' || viewtouse ||
      ' where facility = ''' || nvl(in_fromfacility,'x') || '''' ||
      ' and custid = ''' || nvl(in_custid,'x') || '''' ||
      ' and item = ''' || nvl(in_item,'x') || '''' ||
      ' and invstatus = ''' || nvl(in_invstatus,'x') || '''' ||
      ' and inventoryclass = ''' || nvl(in_inventoryclass,'RG') || '''';
    if nvl(in_lotnumber,'(none)') <> '(none)' then
      cmdSql := cmdSql || ' and lotnumber = ''' || in_lotnumber || '''';
    end if;
    if ar.pickingzone is not null then
      cmdSql := cmdSql || ' and pickingzone = ''' || ar.pickingzone || '''';
    end if;
    if rtrim(in_pickuom) is null then
      cmdSql := cmdSql || ' and quantity >= ' || base.qtymin;
    end if;
    if (wv.use_flex_pick_fronts_yn = 'Y') and
       (wv.fpf_full_picks_bypass_fpf = 'Y') and
       ((wv.fpf_pick_allocrule is null) or
        (wv.fpf_pick_allocrule != itf.allocrule)) then
      cmdSql := cmdSql || ' and quantity = ' || palletqty;
    elsif (ar.wholelponly = 'Y') and (ignore_wholelp = 'N') and ((nvl(in_repl_req_yn,'N') = 'N') or (ar.strictfifo = 'N')) then
      cmdSql := cmdSql || ' and quantity <= ' || in_qty;
    end if;
    if (find_smallest_lp = 'Y') then
      cmdSql := cmdSql || ' and quantity >= ' || in_qty;
    end if;
    if (in_ordered_by_weight = 'Y') and
       (in_pickuom != 'IGNORE') then
      cmdSql := cmdSql || ' and trunc(weight) <= ' || in_qty;
    end if;
    if in_bat_zone_only = 'Y' then
       cmdSql := cmdSql || ' and exists (select 1 from zone where facility = ''' ||
                 nvl(in_fromfacility,'x') || ''' and zoneid = pickingzone ' ||
                 ' and picktype = ''BAT'')';
    end if;
    if (lFIFODate is not null) and (ar.DateType <> 'C') then
      if ar.DateType = 'M' then
        cmdSql := cmdSql || ' and trunc(manufacturedate)';
      elsif ar.DateType = 'E' then
        cmdSql := cmdSql || ' and trunc(expirationdate)';
      else
        cmdSql := cmdSql || ' and least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate)))';
      end if;
      if (ar.LifoFifo = 'L') then
        cmdSql := cmdSql || ' >= to_date(''' || to_char(lFIFODate,'YYYYMMDD') || ''',''YYYYMMDD'')';
      else
        cmdSql := cmdSql || ' <= to_date(''' || to_char(lFIFODate,'YYYYMMDD') || ''',''YYYYMMDD'')';
      end if;
    end if;
    if (ar.DateType = 'C') then
      if lStorageCode = 'M' then
        cmdSql := cmdSql || ' and trunc(manufacturedate)';
      else
        cmdSql := cmdSql || ' and trunc(expirationdate)';
      end if;
      cmdSql := cmdSql || ' >= to_date(''' || lCodeDate || ''',''YYYYMMDD'')';
    end if;
    cmdSql := cmdSql || ' order by ';
    if ar.DateType = 'M' then
      cmdSql := cmdSql || ' trunc(manufacturedate) ';
    elsif ar.DateType = 'E' then
      cmdSql := cmdSql || ' trunc(expirationdate) ';
    elsif ar.DateType = 'L' then
    	if it.lotrequired <> 'N' then
    	  if ar.LifoFifo = 'L' then
          cmdSql := cmdSql || ' maxlot';
        else
          cmdSql := cmdSql || ' minlot';
        end if;
      else
        cmdSql := cmdSql || ' least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) ';
        zms.log_msg('FINDPLATE', in_fromfacility, null,
            'Rule ' || to_char(ar.priority) || ' set for fifo by lotnumber, but item ' || in_item || ' not set up for lot capture', 'W',
            'FINDPLATE', strOutMsg);
      end if;
    elsif (ar.DateType = 'C') then
      if lStorageCode = 'M' then
        cmdSql := cmdSql || ' trunc(manufacturedate) ';
      else
        cmdSql := cmdSql || ' trunc(expirationdate) ';
      end if;
    else
      cmdSql := cmdSql || ' least(trunc(creationdate),nvl(trunc(anvdate),trunc(creationdate))) ';
    end if;
    if ar.LifoFifo = 'L' then
      cmdSql := cmdSql || ' desc ';
    end if;
    if (ar.bylot = 'Y') then
    	cmdSql := cmdSql || ', minlot';
    end if;
    if (ar.picktoclean = 'Y') or (find_smallest_lp = 'Y') then
      if in_ordered_by_weight = 'Y' then
        cmdSql := cmdSql || ', weight, location, lpid';
      else
        cmdSql := cmdSql || ', quantity, location, lpid';
      end if;
    else
      if in_ordered_by_weight = 'Y' then
        cmdSql := cmdSql || ', weight desc, location, lpid';
      else
        cmdSql := cmdSql || ', quantity desc, location, lpid';
      end if;
    end if;
    begin
      trace_msg(cmdSql);
      curPlate := dbms_sql.open_cursor;
      dbms_sql.parse(curPlate, cmdSql, dbms_sql.native);
      dbms_sql.define_column(curPlate,1,lp.lpid,15);
      dbms_sql.define_column(curPlate,2,lp.location,10);
      dbms_sql.define_column(curPlate,3,lp.quantity);
      dbms_sql.define_column(curPlate,4,lp.weight);
      dbms_sql.define_column(curPlate,5,lp.lotnumber,30);
      dbms_sql.define_column(curPlate,6,lp.expirationdate);
      cntRows := dbms_sql.execute(curPlate);
      while (1=1)
      loop
        cntRows := dbms_sql.fetch_rows(curPlate);
        if cntRows <= 0 then
          exit;
        end if;
        dbms_sql.column_value(curPlate,1,lp.lpid);
        dbms_sql.column_value(curPlate,2,lp.location);
        dbms_sql.column_value(curPlate,3,lp.quantity);
        dbms_sql.column_value(curPlate,4,lp.weight);
        dbms_sql.column_value(curPlate,5,lp.lotnumber);
        dbms_sql.column_value(curPlate,6,lp.expirationdate);
        if (in_enter_min_days_to_expire_yn = 'Y') and
           (in_expdaterequired = 'Y') and
           (in_min_days_to_expiration > 0) then
          if (lp.expirationdate is null) or
             (trunc(sysdate) + in_min_days_to_expiration > lp.expirationdate) then
            goto continue_plate_loop;
          end if;
        end if;
        if (ar.wholelponly = 'Y') and (ignore_wholelp = 'N') and (nvl(in_repl_req_yn,'N') = 'Y') and (ar.strictfifo = 'Y') and
           (lp.quantity > in_qty) then
          exit;
        end if;
        pkzn := null;
        open c_pkzn(in_fromfacility, lp.location);
        fetch c_pkzn into pkzn;
        close c_pkzn;
        pkzn.deconsolidation := nvl(pkzn.deconsolidation,'N');
        out_baseqty := lp.quantity;
        if   (pkzn.deconsolidation = 'N')
          or (nvl(out_picktype, default_picktype(in_fromfacility,lp.location)) != 'BAT')
          or (nvl(zrf.virtual_lpid(lp.lpid),'(none)') != lp.lpid) then
          if in_ordered_by_weight = 'Y' then
            if lp.weight > in_qty then
              out_baseqty := zwt.calc_order_by_weight_qty(in_custid,in_item,it.baseuom,in_qty,0,in_qtytype);
            end if;
			if out_baseqty > lp.quantity then
			  out_baseqty := lp.quantity;
			end if;
          else
            if lp.quantity > in_qty then
              out_baseqty := in_qty;
            end if;
          end if;
        elsif lp.lotnumber is not null then     -- handle vlp's with mixed lots
          open c_lp(lp.lpid);
          fetch c_lp into out_baseqty;
          close c_lp;
        end if;
        zbut.translate_uom(in_custid,in_item,out_baseqty,it.baseuom,ar.uom,out_pickqty,out_msg);
        if in_ordered_by_weight = 'Y' and
           substr(out_msg,1,4) != 'OKAY' then
          out_pickqty := out_baseqty;
          out_pickuom := out_baseuom;
          ar.wholeunitsonly := 'N';
          out_msg := 'OKAY';
        end if;
        if (substr(out_msg,1,4) = 'OKAY') then
          if ar.wholeunitsonly = 'Y' then
            out_pickqty := floor(out_pickqty);
            zbut.translate_uom(in_custid,in_item,out_pickqty,ar.uom,it.baseuom,out_baseqty,out_msg);
          end if;
          if mod(out_pickqty,1) != 0 then
            if mod(out_pickqty,1) < .000001 then
              out_pickqty := floor(out_pickqty);
            else
              out_pickqty := out_baseqty;
              out_pickuom := out_baseuom;
            end if;
          end if;
          if out_pickqty != 0 then
            out_wholeunitsonly := ar.wholeunitsonly;
            out_picktype := default_picktype(in_fromfacility,lp.location);
            out_msg := 'FOUND';
            out_lpid_or_loc := lp.lpid;
            if lp.quantity != out_baseqty then
              out_weight := zcwt.lp_item_weight(lp.lpid, in_custid, in_item, out_pickuom) * out_pickqty;
            else
              out_weight := lp.weight;
            end if;
            exit;
          end if;
        end if;
      << continue_plate_loop >>
        null;
      end loop;
      dbms_sql.close_cursor(curPlate);
    exception when no_data_found then
      dbms_sql.close_cursor(curPlate);
    end;
  end if;
  if out_msg = 'FOUND' then
    exit;
  end if;
  if (nvl(in_pass_count,2) = 1) and (find_smallest_lp = 'Y') then
    find_smallest_lp := 'N';
    goto find_again;
  end if;
<<continue_loop>>
  null;
end loop;

--zut.prt('fap out ' || out_msg);
if out_msg = 'FOUND' then
  trace_msg('LIPorLOC: ' || out_lpid_or_loc || ' ' ||
            'baseUOM: ' || out_baseuom || ' ' ||
            'baseQty: ' || out_baseqty || ' ' ||
            'pickuom: ' || out_pickuom || ' ' ||
            'pickQty: ' || out_pickqty || ' ' ||
            'pickfront: ' || out_pickfront || ' ' ||
            'picktotype: ' || out_picktotype || ' ' ||
            'cartontype: ' || out_cartontype || ' ' ||
            'picktype: ' || out_picktype || ' ' ||
            'wholeUOM: ' || out_wholeunitsonly || ' ' ||
            'weight: ' || substr(to_char(out_weight),1,20));
  out_msg := 'OKAY';
else
  out_msg := 'No inventory found';
end if;

exception when others then
  out_msg := 'wvfap ' || sqlerrm;
end find_a_pick;

procedure release_line
(in_orderid varchar2
,in_shipid varchar2
,in_orderitem varchar2
,in_orderlot varchar2
,in_reqtype varchar2
,in_facility varchar2
,in_taskpriority varchar2
,in_picktype varchar2
,in_complete varchar2
,in_stageloc varchar2
,in_sortloc varchar2
,in_batchcartontype varchar2
,in_regen varchar2
,in_userid varchar2
,in_trace varchar2
,in_recurse_count integer
,out_msg IN OUT varchar2
) is

cursor curOrderDtl is
  select orderid,
         shipid,
         custid,
         item,
         lotnumber,
         priority,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(qtypick,0) as qtypick,
         nvl(weightorder,0) as weightorder,
         nvl(weightcommit,0) as weightcommit,
         nvl(weightpick,0) as weightpick,
         uom,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtyentered,
         uomentered,
         qtytype,
         childorderid,
         childshipid,
         nvl(backorder,'N') as backorder,
         nvl(xdockorderid,0) as xdockorderid,
         nvl(xdockshipid,0) as xdockshipid,
         xdocklocid,
         nvl(weight_entered_lbs,0) as weight_entered_lbs,
         nvl(weight_entered_kgs,0) as weight_entered_kgs,
         decode(nvl(variancepct,0),0,zci.variancepct(custid,item),variancepct) as variancepct,
         nvl(min_days_to_expiration,0) as min_days_to_expiration
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
od curOrderDtl%rowtype;

cursor curChildLine(in_orderid number, in_shipid number) is
  select item,
         lotnumber,
         priority,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtycommit,0) as qtycommit,
         nvl(qtypick,0) as qtypick,
         nvl(weightorder,0) as weightorder,
         nvl(weightcommit,0) as weightcommit,
         nvl(weightpick,0) as weightpick,
         uom,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         qtyentered,
         uomentered,
         qtytype,
         childorderid,
         childshipid
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X';

cursor curItem (in_custid varchar2, in_item varchar2) is
  select decode(variancepct,0,1,variancepct) as variancepct,
         iskit,
         baseuom,
         useramt1,
         unkitted_class,
         expdaterequired,
         rcpt_qty_is_full_qty
    from custitemview
   where custid = in_custid
     and item = in_item;
ci curItem%rowtype;

cursor curPendPicksLine is
  select nvl(sum(quantity),0) as qty, nvl(sum(weight),0) as weight
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and type in ('F','P')
     and status = 'U';
pl curPendPicksLine%rowtype;

cursor curPendBatchLine is
  select nvl(sum(qty),0) as qty, nvl(sum(weight),0) as weight
    from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
bl curPendBatchLine%rowtype;

cursor curPendPicksItem(in_item varchar2,in_lotnumber varchar2,
  in_invstatus varchar2, in_inventoryclass varchar2) is
  select nvl(sum(quantity),0) as qty, nvl(sum(weight),0) as weight
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and item = in_item
     and invstatus = in_invstatus
     and inventoryclass = in_inventoryclass
     and type in ('F','P')
     and status = 'U';
pi curPendPicksItem%rowtype;

cursor curPendBatchItem(in_item varchar2,in_lotnumber varchar2,
  in_invstatus varchar2, in_inventoryclass varchar2) is
  select nvl(sum(qty),0) as qty, nvl(sum(weight),0) as weight
    from batchtasks
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
     and item = in_item
     and invstatus = in_invstatus
     and inventoryclass = in_inventoryclass;
bi curPendBatchLine%rowtype;

cursor curComm is
  select item as item,
         nvl(lotnumber,'(none)') as lotnumber,
         nvl(orderlot,'(none)') as orderlot,
         invstatus,
         inventoryclass,
         nvl(qty,0) as qty,
         uom,
         zci.item_weight(custid,item,uom) * qty as weight
    from commitments
   where orderid = in_orderid
     and shipid = in_shipid
     and orderitem = in_orderitem
     and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
   order by item, lotnumber, invstatus, inventoryclass;

cursor curPlate(in_lpid varchar2) is
  select lpid,
         location,
         quantity,
         holdreason,
         unitofmeasure,
         serialnumber,
         lotnumber,
         useritem1,
         useritem2,
         useritem3,
         manufacturedate,
         expirationdate,
         nvl(qtyrcvd,0) qtyrcvd
    from plate
   where lpid = in_lpid;
lp curPlate%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;

cursor curOrder(in_orderid number, in_shipid number) is
  select orderid,
         shipid,
         fromfacility,
         custid,
         wave,
         loadno,
         stopno,
         shipno,
         ordertype,
         xdockprocessing,
         componenttemplate,
         stageloc,
         priority,
         shipshort
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrder%rowtype;
co curOrder%rowtype;

cursor curWave(in_wave number) is
  select wave,
         nvl(use_flex_pick_fronts_yn,'N') use_flex_pick_fronts_yn,
         nvl(fpf_full_picks_bypass_fpf,'N') fpf_full_picks_bypass_fpf,
         fpf_pick_allocrule, parallel_pick_zones,
         nvl(sdi_sortation_yn,'N') sdi_sortation_yn
    from waves
   where wave = in_wave;
wv curWave%rowtype;

cursor curXDockLips(in_xdockorderid number, in_xdockshipid number) is
  select lpid,
         facility,
         custid,
         item,
         lotnumber,
         unitofmeasure,
         invstatus,
         inventoryclass,
         quantity,
         qtytasked,
         location,
         holdreason,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         manufacturedate,
         expirationdate
    from plate
   where orderid = in_xdockorderid
     and shipid = in_xdockshipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and type = 'PA'
     and status = 'A'
     and nvl(qtytasked,0) < quantity
     and exists
         (select 1
            from location
           where plate.facility = location.facility
             and plate.location = location.locid
             and location.loctype = 'CD');

cursor curCustomer(in_custid varchar2) is
  select nvl(cu.pick_by_line_number_yn,'N') pick_by_line_number_yn,
         nvl(ca.enter_min_days_to_expire_yn,'N') as enter_min_days_to_expire_yn,
         nvl(ca.no_full_shippingplates, 'N') no_full_shippingplates
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and ca.custid = cu.custid;
cu curCustomer%rowtype;

cursor curOrderDtlLine(in_baseuom varchar2) is
  select nvl(ol.uomentered,od.uomentered) as uomentered,
         nvl(ol.linenumber,nvl(od.dtlpassthrunum10,0)) as linenumber,
         nvl(OL.qty,nvl(OD.qtyorder,0)) as qty,
         nvl(ol.qtyentered,od.qtyentered) as qtyentered,
         nvl(ol.weight_entered_lbs,0) as weight_entered_lbs,
         nvl(ol.weight_entered_kgs,0) as weight_entered_kgs
    from orderdtlline ol, orderdtl od
   where od.orderid = in_orderid
     and od.shipid = in_shipid
     and od.item = in_orderitem
     and nvl(od.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and OD.orderid = OL.orderid(+)
     and OD.shipid = OL.shipid(+)
     and OD.item = OL.item(+)
     and nvl(OD.lotnumber,'(none)') = nvl(OL.lotnumber(+),'(none)')
     and nvl(ol.uomentered,'x') != in_baseuom
     and nvl(OL.xdock,'N') = 'N'
    union
  select uomentered as uomentered,
         max(linenumber) as linenumber,
         sum(qty) as qty,
         sum(qtyentered) as qtyentered,
         sum(nvl(ol.weight_entered_lbs,0)) as weight_entered_lbs,
         sum(nvl(ol.weight_entered_kgs,0)) as weight_entered_kgs
    from orderdtlline ol
   where ol.orderid = in_orderid
     and ol.shipid = in_shipid
     and ol.item = in_orderitem
     and nvl(ol.lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and ol.uomentered = in_baseuom
     and nvl(ol.xdock,'N') = 'N'
   group by uomentered;
ol curOrderDtlLine%rowtype;

cursor curParallelPickZones(in_wave number, in_parallel_pick_zones varchar2) is
  select 1 as sort1, zoneid, 1 as sort2
    from subtasks st,
         (select trim(regexp_substr(in_parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
         connect by trim(regexp_substr(in_parallel_pick_zones, '[^,]+', 1, level)) is not null) uz
   where st.wave = in_wave
     and st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.pickingzone = uz.zoneid
   union
  select 2 as sort1, zoneid,
   (select count(distinct orderid)
      from subtasks
     where wave = in_wave
       and pickingzone=uz.zoneid) as sort2
    from (select trim(regexp_substr(in_parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
         connect by trim(regexp_substr(in_parallel_pick_zones, '[^,]+', 1, level)) is not null) uz
   order by 1,3,2;
ppz curParallelPickZones%rowtype;

CURSOR C_SD(in_id varchar2)
IS
SELECT defaultvalue
  FROM systemdefaults
 WHERE defaultid = in_id;
csd C_SD%rowtype;

type picked_by_line_rcd is record
(lpid shippingplate.lpid%type
,quantity shippingplate.quantity%type
);

type picked_by_line_tbl is table of picked_by_line_rcd
  index by binary_integer;

pbl picked_by_line_tbl;
pblx integer;
pblfound boolean;
qtyBaseRemain shippingplate.quantity%type;
cmdSql varchar2(2000);

sp shippingplate%rowtype;
tk tasks%rowtype;
sb subtasks%rowtype;
qtyOrdered number(18,8);
qtyCommReleased orderdtl.qtyorder%type;
qtyLineReleased orderdtl.qtyorder%type;
qtyOrigCommit orderdtl.qtycommit%type;
qtyRemain number(18,8);
qtyToUse number(18,8);
findbaseqty plate.quantity%type;
findbaseuom tasks.pickuom%type;
findpickuom tasks.pickuom%type;
findpickqty plate.quantity%type;
findpicktotype custitem.picktotype%type;
findcartontype custitem.cartontype%type;
findpickfront char(1);
findpicktype waves.picktype%type;
findloctype location.loctype%type;
findwholeunitsonly char(1);
findlabeluom tasks.pickuom%type;
findorderedbyweight char(1);
findweight plate.weight%type;
shippingplatetype shippingplate.type%type;
cntTasks integer;
hrsLimit number(10,4);
out_errorno integer;
labelokay char(1);
singleonly char(1);
uomtofind varchar2(12);
stdAllocation boolean;
strMsg varchar2(255);
intErrorno integer;
qtyApply integer;
qtyXDocked integer;
qtyCommit integer;
passCount number;
tsk_curruserid tasks.curruserid%type;
tsk_priority tasks.priority%type;
tsk_touserid tasks.curruserid%type;
req_type varchar2(32);
l_consolidated waves.consolidated%type;
l_recommit BOOLEAN;
qtyAvailable number(16);
l_picktype waves.picktype%type;
l_taskpriority varchar2(1);

procedure trace_msg(in_msg varchar2) is
strMsg appmsgs.msgtext%type;
begin
  if in_trace = 'Y' then
    out_msg := 'Item ' || in_orderitem || '/' || in_orderlot || ' ' || in_msg;
    zms.log_msg('LINERELEASE', in_facility, oh.custid,
      substr(out_msg,1,254), 'T', 'LINERELEASE', strMsg);
  end if;
end;

procedure get_next_line_number_qty is
begin
  if not curOrderDtlLine%isopen then
    trace_msg('initialize line number qty');
    open curOrderDtlLine(ci.baseuom);
    qtyBaseRemain := 0;
    pbl.delete;
    begin
      select nvl(sum(quantity),0)
        into qtyBaseRemain
        from shippingplate sp1
       where orderid = in_orderid
         and shipid = in_shipid
         and orderitem = in_orderitem
         and nvl(orderlot,'x') = nvl(in_orderlot,'x')
         and pickuom = ci.baseuom
         and type in ('F','P')
         and (
               (parentlpid is null) or
               exists (select 1
                         from shippingplate sp2
                        where sp2.lpid = sp1.parentlpid
                          and sp2.pickuom = ci.baseuom)
             );
      trace_msg('Base uom qty is ' || qtyBaseRemain);
    exception when others then
      trace_msg(sqlerrm);
    end;
  end if;

  while(1=1)
  loop
    fetch curOrderDtlLine into ol;
    if not curOrderDtlLine%found then
      trace_msg('no more lines');
      ol := null;
      return;
    end if;
    trace_msg('Line ' || ol.linenumber || ' UOM ' || ol.uomentered || ' Quantity ' || ol.qty);
    if ol.uomentered = ci.baseuom then
      if ol.qty >= qtyBaseRemain then
        ol.qty := ol.qty - qtyBaseRemain;
        qtyBaseRemain := 0;
        return;
      else
        qtyBaseRemain := qtyBaseRemain - ol.qty;
        goto continue_line_loop;
      end if;
    end if;
    for sp in (select lpid,quantity
                 from shippingplate
                 where orderid = in_orderid
                   and shipid = in_shipid
                   and orderitem = in_orderitem
                   and nvl(orderlot,'x') = nvl(in_orderlot,'x')
                   and pickuom = ol.uomentered
                   and type = 'M')
    loop
      pblfound := False;
      for pblx in 1..pbl.count
      loop
        if sp.lpid = pbl(pblx).lpid then
          pblfound := True;
          sp.quantity := sp.quantity - pbl(pblx).quantity;
          exit;
        end if;
      end loop;
      if sp.quantity = 0 then
        goto continue_sp_loop;
      end if;
      if ol.qty >= sp.quantity then
        ol.qty := ol.qty - sp.quantity;
        if pblfound then
          pbl(pblx).quantity := pbl(pblx).quantity + sp.quantity;
        else
          pblx := pbl.count + 1;
          pbl(pblx).lpid := sp.lpid;
          pbl(pblx).quantity := sp.quantity;
        end if;
      else
        if pblfound then
          pbl(pblx).quantity := pbl(pblx).quantity + ol.qty;
        else
          pblx := pbl.count + 1;
          pbl(pblx).lpid := sp.lpid;
          pbl(pblx).quantity := ol.qty;
        end if;
        ol.qty := 0;
      end if;
      if ol.qty = 0 then
        exit;
      end if;
    << continue_sp_loop >>
      null;
    end loop;

    if ol.qty != 0 then
      return;
    end if;

  << continue_line_loop >>
    null;
  end loop;

exception when others then
  trace_msg(sqlerrm);
  ol := null;
end;

begin

out_msg := '';
findpicktotype := '';
l_picktype := in_picktype;
l_taskpriority := in_taskpriority;

trace_msg('release_line reqtype is ' || in_reqtype);

if in_recurse_count > 64 then
  out_msg := 'Work Order propogation limit reached (line)';
  return;
end if;

open curOrder(in_orderid, in_shipid);
fetch curOrder into oh;
if curOrder%notfound then
   close curOrder;
  out_msg := 'Order Header not found: ' || in_orderid || ' ' ||
    in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
  return;
end if;
close curOrder;

cu := null;
open curCustomer(oh.custid);
fetch curCustomer into cu;
close curCustomer;

if zcord.cons_orderid(in_orderid, in_shipid) = 0 then
   l_consolidated := 'N';
else
   l_consolidated := 'Y';
end if;

if in_trace = 'Y' then
  trace_msg('l_consolidated is ' || l_consolidated);
end if;

if nvl(oh.xdockprocessing,'S') = 'A' then
  goto create_itemdemand;
end if;

wv := null;
open curWave(oh.wave);
fetch curWave into wv;
close curWave;

l_picktype := in_picktype;
if (nvl(trim(wv.parallel_pick_zones),'(none)') <> '(none)') then
  l_picktype := 'ORDR';
end if;

open curOrderDtl;
fetch curOrderDtl into od;
if curOrderDtl%notfound then
  close curOrderDtl;
  out_msg := 'Order Line not found: ' || in_orderid || ' ' ||
    in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
  return;
end if;
close curOrderDtl;

findorderedbyweight := substr(zwt.is_ordered_by_weight(oh.orderid,oh.shipid,od.item,od.lotnumber),1,1);

if ((instr(od.invstatus,',') <> 0) or (instr(od.inventoryclass,',') <> 0)) then
    if in_trace = 'Y' then
      trace_msg('check commitments ' || od.item || '/' || od.lotnumber || ' ' ||
        od.uom || ' ' || od.invstatusind || '-' || od.invstatus || ' ' ||
        od.invclassind || '-' || od.inventoryclass || ' qty: ' || od.qtyorder);
    end if;
  l_recommit := FALSE;
  for cm in curComm
  loop
    qtyAvailable := 0;
    select nvl(sum(qty),0)
      into qtyAvailable
      from custitemtotview
     where facility = in_facility
       and custid = od.custid
       and item = od.item
       and nvl(lotnumber,'(none)') = decode(cm.orderlot,'(none)',nvl(lotnumber,'(none)'),nvl(cm.lotnumber,'(none)'))
       and invstatus = cm.invstatus
       and inventoryclass = cm.inventoryclass
       and status = 'A';
    if (qtyAvailable < cm.qty) then
      l_recommit := TRUE;
    end if;
  end loop;

  if (l_recommit) then
    if in_trace = 'Y' then
      trace_msg('call zcm.uncommit_line' || od.item || '/' || od.lotnumber || ' ' ||
        od.uom || ' ' || od.invstatusind || '-' || od.invstatus || ' ' ||
        od.invclassind || '-' || od.inventoryclass);
    end if;
    zcm.uncommit_line
        (in_facility
        ,od.custid
        ,in_orderid
        ,in_shipid
        ,od.item
        ,od.uom
        ,od.lotnumber
        ,od.invstatusind
        ,od.invstatus
        ,od.invclassind
        ,od.inventoryclass
        ,null
        ,od.priority
        ,req_type
        ,in_userid
        ,out_msg
        );
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('WaveRelease', in_facility, oh.custid,
          out_msg, 'W', in_userid, strMsg);
    end if;

    select nvl(zwt.order_by_weight_qty(orderid, shipid, item, lotnumber),0) - nvl(qtycommit,0) - nvl(qtypick,0)
      into qtyRemain
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid
       and item = in_orderitem
       and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');

    if in_trace = 'Y' then
      trace_msg('call zcm.commit_line' || od.item || '/' || od.lotnumber || ' ' ||
        od.uom || ' ' || od.invstatusind || '-' || od.invstatus || ' ' ||
        od.invclassind || '-' || od.inventoryclass || ' qty: ' || qtyRemain);
    end if;
    zcm.commit_line
        (in_facility
        ,od.custid
        ,in_orderid
        ,in_shipid
        ,od.item
        ,od.uom
        ,od.lotnumber
        ,od.invstatusind
        ,od.invstatus
        ,od.invclassind
        ,od.inventoryclass
        ,qtyRemain
        ,od.priority
        ,req_type
        ,cu.enter_min_days_to_expire_yn
        ,od.min_days_to_expiration
        ,in_userid
        ,out_msg
        );
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('WaveRelease', in_facility, oh.custid,
          out_msg, 'W', in_userid, strMsg);
    end if;
    qtyRemain := 0;
  end if;
  
  open curOrderDtl;
  fetch curOrderDtl into od;
  close curOrderDtl;
end if;

req_type := in_reqtype;
if (in_reqtype = 'MatIssue') then
  tsk_curruserid := in_userid;
  tsk_priority := '0';
  tsk_touserid := null;
elsif (in_reqtype = 'AggInven') then
  tsk_curruserid := null;
  tsk_priority := '9';
  tsk_touserid := '(AggInven)';
  req_type := '1';
else
  tsk_curruserid := null;
  tsk_priority := in_taskpriority;
  tsk_touserid := null;
end if;

qtyRemain := od.qtyorder;

if findorderedbyweight = 'Y' then
  trace_msg('weight order/Commit/Pick/Remain '
    || od.weightorder || ' '
    || od.weightcommit || ' '
    || od.weightpick || ' '
    || qtyRemain);
else
  trace_msg('qty order/Commit/Pick/Remain '
    || od.qtyorder || ' '
    || od.qtycommit || ' '
    || od.qtypick || ' '
    || qtyRemain);
end if;

if (oh.componenttemplate is not null) and
   (nvl(od.childorderid,0) <> 0) then
  if in_trace = 'Y' then
    trace_msg('component with child');
  end if;
  goto create_kit;
end if;

if (req_type != '1') or -- NOT initial release
   (od.xdockorderid = 0) then -- NOT xdock order
 if in_trace = 'Y' then
   trace_msg('not initial release ' || req_type);
 end if;
 goto continue_line_release;
end if;

if oh.ordertype not in ('W','K') then
  for pl in curXDockLips(od.xdockorderid,od.xdockshipid)
  loop
    if qtyRemain <= 0 then
      exit;
    end if;
    if zid.include_exclude(od.invclassind,od.inventoryclass,pl.inventoryclass) = False then
      goto continue_xdock_loop;
    end if;
    if zid.include_exclude(od.invstatusind,od.invstatus,pl.invstatus) = False then
      goto continue_xdock_loop;
    end if;
    qtyApply := pl.quantity - nvl(pl.qtytasked,0);
    if qtyApply > qtyRemain then
      qtyApply := qtyRemain;
    end if;
    if qtyApply <= 0 then
      goto continue_xdock_loop;
    end if;
    qtyRemain := qtyRemain - qtyApply;
    tk := null;
    sb := null;
    sp := null;
    singleonly := zwv.single_shipping_units_only(od.orderid,od.shipid);
    if singleonly = 'Y' then
      tk.picktotype := 'LBL';
    else
      tk.picktotype := 'PAL';
    end if;
    tk.priority := in_taskpriority;
    tk.tasktype := 'PK';
    tk.cartontype := 'NONE';
    tk.cartonseq := null;
    ztsk.get_next_taskid(tk.taskid,strMsg);
    zsp.get_next_shippinglpid(sp.lpid,strMsg);
    if (qtyApply = pl.quantity) and
       (cu.no_full_shippingplates <> 'Y') then
      sp.type := 'F';
    else
      sp.type := 'P';
    end if;
    if oh.stageloc is null then
      begin
        select loadstopstageloc
          into tk.toloc
          from loadsorderview
         where orderid = oh.orderid
           and shipid = oh.shipid;
      exception when others then
        tk.toloc := null;
      end;
    else
      tk.toloc := oh.stageloc;
    end if;
    tk.fromloc := pl.location;
    zgs.compute_largest_whole_pickuom(pl.facility,pl.custid,pl.item,
      pl.unitofmeasure, qtyApply,
      tk.pickuom, tk.pickqty, sb.picktotype, sb.cartontype, sb.qty,
      intErrorno, strMsg);
    if sb.qty != qtyApply then
      tk.pickuom := pl.unitofmeasure;
      tk.pickqty := qtyApply;
    end if;
    insert into shippingplate
      (lpid, item, custid, facility, location, status, holdreason,
      unitofmeasure, quantity, type, fromlpid, serialnumber,
      lotnumber, parentlpid, useritem1, useritem2, useritem3,
      lastuser, lastupdate, invstatus, qtyentered, orderitem,
      uomentered, inventoryclass, loadno, stopno, shipno,
      orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
      pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
      values
      (sp.lpid, pl.item, pl.custid, pl.facility, tk.fromloc,
       'U', pl.holdreason, pl.unitofmeasure, qtyApply,
       sp.type, pl.lpid, pl.serialnumber, pl.lotnumber, null,
       pl.useritem1, pl.useritem2, pl.useritem3,
       'ITEMDEMAND', sysdate, pl.invstatus, qtyApply,
       od.item, od.uomentered, pl.inventoryclass,
       oh.loadno, oh.stopno, oh.shipno, oh.orderid,
       oh.shipid, zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
       null, null, tk.taskid, od.lotnumber,
       tk.pickuom, tk.pickqty, tk.cartonseq, pl.manufacturedate, pl.expirationdate);
    fromloc := null;
    open curLocation(pl.facility,tk.fromloc);
    fetch curLocation into fromloc;
    close curLocation;
    toloc := null;
    open curLocation(pl.facility,tk.toloc);
    fetch curLocation into toloc;
    close curLocation;
    insert into tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs)
      values
      (tk.taskid, tk.tasktype, pl.facility, fromloc.section,tk.fromloc,
       fromloc.equipprof,toloc.section,tk.toloc,toloc.equipprof,tsk_touserid,
       pl.custid,pl.item,pl.lpid,pl.unitofmeasure,qtyApply,
       fromloc.pickingseq,oh.loadno,oh.stopno,oh.shipno,
       oh.orderid,oh.shipid,od.item,od.lotnumber,
       tsk_priority,tk.priority,tsk_curruserid,'ITEMDEMAND',sysdate,
       tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
       fromloc.pickingzone,tk.cartontype,
       zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
       zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
       zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
       fromloc.pickingzone,tk.pickuom,tk.pickqty));
    insert into subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup)
      values
      (tk.taskid,tk.tasktype,pl.facility,
       fromloc.section,tk.fromloc,fromloc.equipprof,toloc.section,
       tk.toloc,toloc.equipprof,null,pl.custid,pl.item,pl.lpid,
       pl.unitofmeasure,qtyApply,fromloc.pickingseq,oh.loadno,
       oh.stopno,oh.shipno,oh.orderid,oh.shipid,od.item,
       od.lotnumber,tk.priority,tk.priority,null,'ITEMDEMAND',
       sysdate,tk.pickuom,tk.pickqty,tk.picktotype,oh.wave,
       fromloc.pickingzone,tk.cartontype,
       zcwt.lp_item_weight(pl.lpid,pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
       zci.item_cube(pl.custid,pl.item,pl.unitofmeasure) * qtyApply,
       zlb.staff_hours(pl.facility,pl.custid,pl.item,tk.tasktype,
       fromloc.pickingzone,tk.pickuom,tk.pickqty),tk.cartonseq,
       sp.lpid, sp.type,zwv.cartontype_group(tk.cartontype));
    update plate
       set qtytasked = nvl(qtytasked,0) + qtyApply,
           lastuser = 'ITEMDEMAND',
           lastupdate = sysdate
     where lpid = pl.lpid
       and parentfacility is not null;
    begin
      insert into commitments
      (facility, custid, item, inventoryclass,
       invstatus, status, lotnumber, uom,
       qty, orderid, shipid, orderitem, orderlot,
       priority, lastuser, lastupdate)
      values
      (oh.fromfacility, oh.custid, pl.item, pl.inventoryclass,
       pl.invstatus, 'CM', in_orderlot, pl.unitofmeasure,
       qtyApply, in_orderid, in_shipid, in_orderitem, in_orderlot,
       oh.priority, 'WAVERELEASE', sysdate);
    exception when dup_val_on_index then
      update commitments
         set qty = qty + qtyApply,
             priority = oh.priority,
             lastuser = 'WAVERELEASE',
             lastupdate = sysdate
       where facility = oh.fromfacility
         and custid = oh.custid
         and item = pl.item
         and inventoryclass = pl.inventoryclass
         and invstatus = pl.invstatus
         and status = 'CM'
         and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
         and orderid = in_orderid
         and shipid = in_shipid
         and orderitem = pl.item
         and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)')
         and qty < qtyApply;
    end;
    if in_trace = 'Y' then
      trace_msg('Cross Dock Task Added ' || qtyApply);
    end if;
  <<continue_xdock_loop>>
    null;
  end loop;
end if;

open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;

<<continue_line_release>>

qtyRemain := od.qtyorder - od.qtycommit - od.qtypick;

if in_trace = 'Y' then
  trace_msg('continue_line_release Order/Commit/Pick/Remain '
    || od.qtyorder || ' '
    || od.qtycommit || ' '
    || od.qtypick || ' '
    || qtyRemain);
end if;

if qtyRemain < 0 then
  qtyRemain := 0;
end if;

if qtyRemain > 0 then
  if in_trace = 'Y' then
    trace_msg('call zcm.commit_line' || in_orderitem || '/' || in_orderlot || ' ' ||
      od.uom || ' ' || od.invstatusind || '-' || od.invstatus || ' ' ||
      od.invclassind || '-' || od.inventoryclass || ' qty: ' || qtyRemain);
  end if;
  zcm.commit_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,in_orderitem
      ,od.uom
      ,in_orderlot
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,qtyRemain
      ,od.priority
      ,req_type
      ,cu.enter_min_days_to_expire_yn
      ,od.min_days_to_expiration
      ,in_userid
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', in_facility, oh.custid,
        out_msg, 'W', in_userid, strMsg);
  end if;
  open curOrderDtl;
  fetch curOrderDtl into od;
  if curOrderDtl%notfound then
    close curOrderDtl;
    out_msg := 'Order Line not found: ' || in_orderid || ' ' ||
      in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
    return;
  end if;
  close curOrderDtl;
  qtyRemain := od.qtyorder - od.qtycommit - od.qtypick;
  if in_trace = 'Y' then
    trace_msg('qtycommitted ' || od.qtycommit);
  end if;
  if in_trace = 'Y' then
    trace_msg('qtyremain after commit ' || qtyRemain);
  end if;
  if qtyRemain < 0 then
    qtyRemain := 0;
  end if;
end if;

if (req_type = '1') and  -- wave release request: check back order policy
   (qtyRemain > 0) then    -- for item
  ci.iskit := 'Y';
  open curItem(oh.custid,in_orderitem);
  fetch curItem into ci;
  close curItem;
  if in_trace = 'Y' then
    trace_msg('Backorder/Kit ' ||
      od.backorder || ' ' ||
      ci.iskit);
  end if;
  if oh.componenttemplate is not null then
    goto continue_release;
  end if;
  if oh.ordertype in ('K','W') then -- ignore kit/work orders
    goto continue_release;
  end if;
  if od.backorder = 'N' then  -- 'N'o back order--short ship okay; continue release
    goto continue_release;
  end if;
  if od.backorder = 'P' then -- 'P'artial Back Order--short ship okay; continue release;
                             -- (backorder will be generated upon shipment)
    goto continue_release;
  end if;
  if od.backorder in ('A','X') then -- 'A'll or 'C'ancel
    if in_trace = 'Y' then
      trace_msg('Backorder Policy Cancel');
    end if;
    zoe.cancel_item(in_orderid,in_shipid,in_orderitem,in_orderlot,
      oh.fromfacility,in_userid,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
        'Cancel Item: ' || in_orderid || '-' || in_shipid || ' ' ||
        in_orderitem || ' ' || in_orderlot || ' ' ||
        out_msg, 'E', in_userid, strMsg);
    end if;
    if od.backorder = 'A' then -- back order 'A'll
      zbo.create_back_order_item(in_orderid,in_shipid,in_orderitem,
        in_orderlot,in_userid,intErrorno,out_msg);
      if intErrorno != 0 then
        zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
          'Back Order: ' || in_orderid || '-' || in_shipid || ' ' ||
          in_orderitem || ' ' || in_orderlot || ' ' ||
          out_msg, 'E', in_userid, strMsg);
      end if;
    end if;
    goto finish_line_release;
  end if;
  if od.backorder = 'W' then  -- 'W' e-mail CSR and await confirmation
    if(oh.shipshort <> 'Y') then
      update orderhdr
         set shipshort = 'W',
             lastuser = in_userid,
             lastupdate = sysdate
       where orderid = in_orderid
         and shipid = in_shipid;
      goto end_release;
    else
      goto continue_release;
    end if;
  end if;
end if;

<<continue_release>>

--reduce commitment by unpicked amount
pl.qty := 0;
pl.weight := 0;
open curPendPicksLine;
fetch curPendPicksLine into pl;
close curPendPicksLine;
bl.qty := 0;
open curPendBatchLine;
fetch curPendBatchLine into bl;
close curPendBatchLine;

if findorderedbyweight = 'Y' then
  if od.weight_entered_lbs = 0 then
    qtyOrdered := zwt.from_kgs_to_lbs(oh.custid,od.weight_entered_kgs);
  else
    qtyOrdered := od.weight_entered_lbs;
  end if;
  qtyRemain := qtyOrdered - od.weightpick - pl.weight - bl.weight;
else
  qtyOrdered := od.qtyOrder;
  qtyRemain := od.qtycommit - pl.qty - bl.qty;
end if;

if qtyRemain < 0 then
  qtyRemain := 0;
end if;

if findorderedbyweight = 'Y' then
  trace_msg('weight Order/Pick/PendPick/Batch/Remain ' ||
    qtyOrdered || ' ' ||
    od.weightpick || ' ' ||
    pl.weight || ' ' ||
    bl.weight || ' ' ||
    qtyRemain);
else
  trace_msg('qty Commit/PendPick/Batch/Remain ' ||
    od.qtycommit || ' ' ||
    pl.qty || ' ' ||
    bl.qty || ' ' ||
    qtyRemain);
end if;

if oh.componenttemplate is not null then
  goto create_kit;
end if;

open C_SD('REGENZONECONFIG');
fetch C_SD into csd;
close C_SD;

qtyLineReleased := 0;

if qtyRemain > 0 then
  for cm in curComm
  loop
    qtyOrigCommit := cm.qty;
    qtyCommReleased := 0;
    if in_trace = 'Y' then
      trace_msg('Commitment row: ' || cm.item || ' ' || cm.lotnumber || ' ' ||
                  cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty);
    end if;
    pi.qty := 0;
    pi.weight := 0;
    open curPendPicksItem(cm.item,cm.lotnumber,cm.invstatus,cm.inventoryclass);
    fetch curPendPicksItem into pi;
    close curPendPicksItem;
    bi.qty := 0;
    open curPendBatchItem(cm.item,cm.lotnumber,cm.invstatus,cm.inventoryclass);
    fetch curPendBatchItem into bi;
    close curPendBatchItem;

    if findorderedbyweight = 'Y' then
      cm.qty := cm.qty * zci.item_weight(oh.custid,od.item,od.uom) - pi.weight;
      if cm.qty > qtyOrdered then
        cm.qty := qtyOrdered;
      end if;
      trace_msg('weight to find ' || cm.qty || ' pending ' || pi.weight);
    else
      cm.qty := cm.qty - pi.qty - bi.qty;
      trace_msg('qty to find ' || cm.qty || ' pending ' || pi.qty || ' batch ' || bi.qty);
    end if;

    if cm.qty < 0 then
      if in_trace = 'Y' then
        trace_msg('Unpicked Item: ' || cm.item || ' ' || cm.lotnumber || ' ' ||
         cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty);
      end if;
      cm.qty := 0;
    end if;

    cntTasks := 0;
    open curItem(oh.custid,cm.item);
    fetch curItem into ci;
    close curItem;
    stdAllocation := True;

    if cu.pick_by_line_number_yn = 'Y' then
      ol := null;
      trace_msg('get initial line number');
      get_next_line_number_qty;
    end if;

    while cm.qty > 0
    loop
      if cu.pick_by_line_number_yn = 'Y' and ol.qty = 0 then
        get_next_line_number_qty;
        if ol.qty is null then
          trace_msg('No more lines');
          cm.qty := 0;
          exit;
         end if;
      end if;
      out_msg := '';
      if (l_picktype = 'BAT') and
         (oh.ordertype != 'K') and
         (nvl(cm.lotnumber,'(none)') = '(none)') then
        lp.lpid := '';
        findbaseuom := cm.uom;
        findbaseqty := cm.qty;
        findpickuom := cm.uom;
        findpickqty := cm.qty;
        findpickfront := 'Y';
        findpicktotype := 'PAL';
        findcartontype := 'PAL';
        findpicktype := 'BAT';
        findwholeunitsonly := 'N';
        out_msg := 'OKAY';
      else
        if stdAllocation = True then
          if cu.pick_by_line_number_yn = 'Y' and
             ol.uomentered != ci.baseuom then
            uomtofind := ol.uomentered;
          else
            uomtofind := ''; -- follow standard allocation qty rules
          end if;
        else
          uomtofind := 'IGNORE';  -- follow rules but disregard quantity
        end if;
        if (wv.use_flex_pick_fronts_yn = 'Y') then
          if (wv.fpf_full_picks_bypass_fpf = 'Y') and
             (wv.fpf_pick_allocrule is null) then
            uomtofind := nvl(zci.default_value('PALLETSUOM'),'PLT');
            findloctype := 'STO';
          else
            findloctype := 'FPF';
          end if;
        elsif (ci.iskit = 'K') and
           (oh.ordertype = 'O') then
          findloctype := 'STG';
        else
          findloctype := 'STO';
        end if;
        if cu.pick_by_line_number_yn = 'Y' then
          qtyToUse := ol.qty;
        else
          qtyToUse := cm.qty;
        end if;

        ppz := null;
        if (nvl(trim(wv.parallel_pick_zones),'(none)') <> '(none)') then
          open curParallelPickZones(oh.wave, wv.parallel_pick_zones);
          fetch curParallelPickZones into ppz;
          close curParallelPickZones;
        end if;

        passCount := 1;
<< find_again >>
        trace_msg('Find a pick for ' || qtyToUse);
        findpicktype := null;
        find_a_pick(oh.fromfacility,oh.custid,in_orderid,in_shipid,cm.item,cm.lotnumber,
          cm.invstatus, cm.inventoryclass, qtyToUse,
          uomtofind, 'N', -- NOT a replenish request
          findloctype, findorderedbyweight, od.qtytype, oh.wave, 'N', ppz.zoneid,
          ci.expdaterequired, cu.enter_min_days_to_expire_yn,
          od.min_days_to_expiration, null, passCount, lp.lpid, findbaseuom,
          findbaseqty, findpickuom, findpickqty, findpickfront, findpicktotype,
          findcartontype, findpicktype, findwholeunitsonly, findweight, in_trace, out_msg);
        if in_trace = 'Y' then
          zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
         'Find Plate1: ' || cm.item || ' ' || cm.lotnumber || ' ' ||
          cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty || ' ' ||
          lp.lpid || ' ' || findbaseqty || ' ' || findpickuom || ' ' || findpickqty
          || ' ' || findpickfront || ' ' || findpicktotype || ' ' || findpicktype || ' ' || out_msg,
          'T', in_userid, strMsg);
        end if;
-- if no stock is found in a staging area for made-to-order kit, then try storage areas
        if substr(out_msg,1,4) != 'OKAY' then
          if (ci.iskit = 'K') and
             (oh.ordertype = 'O') and
             (findloctype = 'STG') then
            findloctype := 'STO';
            goto find_again;
          elsif (wv.use_flex_pick_fronts_yn = 'Y') and
                (wv.fpf_full_picks_bypass_fpf = 'Y') and
                (wv.fpf_pick_allocrule is null) and
                (findloctype = 'STO') then
            findloctype := 'FPF';
            l_picktype := 'ORDR';
            l_taskpriority := '9';
            if cu.pick_by_line_number_yn = 'Y' and
               ol.uomentered != ci.baseuom then
              uomtofind := ol.uomentered;
            else
              uomtofind := '';
            end if;
            goto find_again;
          elsif (nvl(passCount,2) < 2) then
            passCount := nvl(passCount,2) + 1;
            goto find_again;
          end if;
        end if;
        if (findpicktype = 'BAT') and (out_msg = 'OKAY') and
           ((nvl(rtrim(l_picktype),'(none)') = '(none)') or
           	((nvl(in_regen,'N') = 'Y') and
		         (nvl(csd.defaultvalue,'N') = 'Y'))) then
          if findorderedbyweight = 'Y' then
            zms.log_msg('WaveRelease', in_facility, oh.custid,
            'Wave ' || oh.wave || ': Order ' || oh.orderid || '-' || oh.shipid || ' Item ' || od.item ||
            ' Batch picking is not supported for ordered-by-weight items',
            'E', in_userid, strMsg);
            out_msg := 'NOBATCH';
          else
            lp.lpid := '';
            findbaseuom := cm.uom;
            findbaseqty := cm.qty;
            findpickuom := cm.uom;
            findpickqty := cm.qty;
            findpickfront := 'Y';
            findpicktotype := 'PAL';
            findcartontype := 'PAL';
            findwholeunitsonly := 'N';
          end if;
        end if;
      end if;
      if substr(out_msg,1,4) = 'OKAY' then
        if cu.pick_by_line_number_yn = 'Y' then
          findlabeluom := ol.uomentered;
          findpicktotype := 'LBL';
        elsif findwholeunitsonly = 'Y' then
          findlabeluom := findpickuom;
        else
          findlabeluom := null;
        end if;
        if (req_type = 'MatIssue') then
          findpicktotype := 'FULL';
        elsif findpicktotype = 'LBL' then
          if pick_to_label_okay(in_orderid,in_shipid) = 'N' then
            findpicktotype := 'PAL';
          end if;
        else
          if findpicktotype in ('PAL','FULL') then
            singleonly := zwv.single_shipping_units_only(in_orderid,in_shipid);
            if singleonly = 'Y' then
              findpicktotype := 'LBL';
            end if;
          end if;
        end if;
        if in_trace = 'Y' then
          zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
         'Find Plate2: ' || cm.item || ' ' || cm.lotnumber || ' ' ||
          cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty || ' ' ||
          lp.lpid || ' ' || findbaseqty || ' ' || findpickuom || ' ' || findpickqty
          || ' ' || findpickfront || ' ' || findpicktotype || ' ' || findpicktype || ' ' || out_msg,
          'T', in_userid, strMsg);
        end if;
        if findpickfront = 'Y' then
          lp.location := lp.lpid;
          lp.lpid := null;
          lp.quantity := findbaseqty;
          lp.holdreason := null;
          lp.unitofmeasure := findbaseuom;
          lp.serialnumber := null;
          lp.lotnumber := null;
          lp.useritem1 := null;
          lp.useritem2 := null;
          lp.useritem3 := null;
          lp.manufacturedate := null;
          lp.expirationdate := null;
        elsif lp.lpid is not null then
          open curPlate(lp.lpid);
          fetch curPlate into lp;
          lp.unitofmeasure := findbaseuom;
          close curPlate;

          if (ci.rcpt_qty_is_full_qty = 'Y') then
            if (findbaseqty = lp.qtyrcvd) and (findbaseqty = lp.quantity) then
              findpicktotype := 'FULL';
            elsif (findpicktype = 'BAT') and (wv.sdi_sortation_yn = 'Y') then
              findpicktotype := 'TOTE';
            end if;
          end if;
        else
          lp.quantity := 0;
        end if;
        if findorderedbyweight = 'Y' then
          cm.qty := cm.qty - findweight;
          qtyCommReleased := qtyCommReleased + findbaseqty;
          trace_msg('Committed ' || cm.qty || ' FindWeight ' || findweight);
        else
          cm.qty := cm.qty - findbaseqty;
          trace_msg('Committed ' || cm.qty || ' FindBaseQty ' || findbaseqty);
        end if;
        if cu.pick_by_line_number_yn = 'Y' then
          ol.qty := ol.qty - findbaseqty;
        end if;
        if (findpickfront = 'N') and
           (findbaseqty = lp.quantity) and
           (cu.no_full_shippingplates <> 'Y') then
          shippingplatetype := 'F';
        else
          shippingplatetype := 'P';
        end if;
        tk.cartonseq := null;
        tk.tasktype := 'PK';

		    if (nvl(in_regen,'N') = 'Y') and
		       (nvl(csd.defaultvalue,'N') = 'Y') then
          tk.taskid := 0;
          if (findpicktype = 'BAT') and
		         (oh.ordertype != 'K') then
            tk.tasktype := 'BP';
		      elsif (findpicktype <> 'LINE') then
            tk.tasktype := 'OP';
          else
            ztsk.get_next_taskid(tk.taskid,out_msg);
          end if;
        elsif (nvl(l_picktype,findpicktype) = 'ORDR') or
              (nvl(l_picktype,findpicktype) = 'BAT') or
              (findpicktotype not in ('FULL','LBL')) then
          tk.taskid := 0;
          if nvl(l_picktype,findpicktype) = 'ORDR' then
            tk.tasktype := 'OP';
          elsif nvl(l_picktype,findpicktype) = 'BAT' then
            if oh.ordertype != 'K' then
              tk.tasktype := 'BP';
            end if;
          end if;
        else
          ztsk.get_next_taskid(tk.taskid,out_msg);
        end if;
        if tk.tasktype = 'BP' then
          fromloc := null;
          open curLocation(in_facility,lp.location);
          fetch curLocation into fromloc;
          close curLocation;
          toloc := null;
          open curLocation(in_facility,in_sortloc);
          fetch curLocation into toloc;
          close curLocation;
          trace_msg('insert bt ' || oh.custid || ' ' || in_orderitem ||
            ' ' || in_orderlot || ' ' || lp.lpid || ' ' || findbaseqty);
          insert into batchtasks
            (taskid, tasktype, facility, fromsection, fromloc,
             fromprofile,tosection,toloc,toprofile,touserid,
             custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
             orderid,shipid,orderitem,orderlot,priority,
             prevpriority,curruserid,lastuser,lastupdate,
             pickuom, pickqty, picktotype, wave,
             pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
             shippinglpid, shippingtype, invstatus, inventoryclass,
             qtytype, lotnumber)
          values
            (tk.taskid,tk.tasktype,null,
             fromloc.section,lp.location,fromloc.equipprof,toloc.section,
             in_sortloc,toloc.equipprof,null,oh.custid,cm.item,lp.lpid,
             lp.unitofmeasure,findbaseqty,fromloc.pickingseq,oh.loadno,
             oh.stopno,oh.shipno,in_orderid,in_shipid,in_orderitem,
             in_orderlot,l_taskpriority,l_taskpriority,null,in_userid,
             sysdate,findpickuom,findpickqty,findpicktotype,oh.wave,
             fromloc.pickingzone,findcartontype,
             zcwt.lp_item_weight(lp.lpid,oh.custid,cm.item,findpickuom) * findpickqty,
             zci.item_cube(oh.custid,cm.item,findpickuom) * findpickqty,
             zlb.staff_hours(in_facility,oh.custid,cm.item,tk.tasktype,
             fromloc.pickingzone,findpickuom,findpickqty),tk.cartonseq,
             null, shippingplatetype, cm.invstatus, cm.inventoryclass,
             od.qtytype, cm.lotnumber);
          update plate
             set qtytasked = nvl(qtytasked,0) + findbaseqty,
                 lastuser = in_userid,
                 lastupdate = sysdate
           where lpid = lp.lpid;
          cntTasks := cntTasks + 1;
        else
          zsp.get_next_shippinglpid(sp.lpid,out_msg);
          if in_trace = 'Y' then
            trace_msg('Insert shipping: ' || cm.item || ' ' || cm.lotnumber || ' ' ||
                       cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty || ' ' ||
                       lp.lpid || ' ' || findbaseqty || ' ' || findpickuom || ' ' || findpickqty);
          end if;
          insert into shippingplate
            (lpid, item, custid, facility, location, status, holdreason,
            unitofmeasure, quantity, type, fromlpid, serialnumber,
            lotnumber, parentlpid, useritem1, useritem2, useritem3,
            lastuser, lastupdate, invstatus, qtyentered, orderitem,
            uomentered, inventoryclass, loadno, stopno, shipno,
            orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
            pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
            values
            (sp.lpid, cm.item, oh.custid, in_facility, lp.location,
             'U', lp.holdreason, lp.unitofmeasure, findbaseqty,
             shippingplatetype, lp.lpid, lp.serialnumber, lp.lotnumber, null,
             lp.useritem1, lp.useritem2, lp.useritem3,
             in_userid, sysdate, cm.invstatus, od.qtyentered,
             in_orderitem, od.uomentered, cm.inventoryclass,
             oh.loadno, oh.stopno, oh.shipno, in_orderid,
             in_shipid, zcwt.lp_item_weight(lp.lpid,oh.custid,cm.item,findpickuom) * findpickqty,
             null, null, tk.taskid, in_orderlot,
             findpickuom, findpickqty, tk.cartonseq, lp.manufacturedate, lp.expirationdate);
          fromloc := null;
          open curLocation(in_facility,lp.location);
          fetch curLocation into fromloc;
          close curLocation;
          toloc := null;
          open curLocation(in_facility,in_stageloc);
          fetch curLocation into toloc;
          close curLocation;
          if tk.taskid != 0 then
            insert into tasks
              (taskid, tasktype, facility, fromsection, fromloc,
               fromprofile,tosection,toloc,toprofile,touserid,
               custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
               orderid,shipid,orderitem,orderlot,priority,
               prevpriority,curruserid,lastuser,lastupdate,
               pickuom, pickqty, picktotype, wave,
               pickingzone, cartontype, weight, cube, staffhrs)
              values
              (tk.taskid, tk.tasktype, null, fromloc.section,lp.location,
               fromloc.equipprof,toloc.section,in_stageloc,
               toloc.equipprof,tsk_touserid,oh.custid,cm.item,lp.lpid,
               lp.unitofmeasure,findbaseqty,fromloc.pickingseq,oh.loadno,oh.stopno,
               oh.shipno,in_orderid,in_shipid,in_orderitem,in_orderlot,
               tsk_priority,l_taskpriority,tsk_curruserid,in_userid,sysdate,
               findpickuom,findpickqty,findpicktotype,oh.wave,
               fromloc.pickingzone,findcartontype,
               zcwt.lp_item_weight(lp.lpid,oh.custid,cm.item,findpickuom) * findpickqty,
               zci.item_cube(oh.custid,cm.item,findpickuom) * findpickqty,
               zlb.staff_hours(in_facility,oh.custid,cm.item,tk.tasktype,
               fromloc.pickingzone,findpickuom,findpickqty));
          end if;

          insert into subtasks
            (taskid, tasktype, facility, fromsection, fromloc,
             fromprofile,tosection,toloc,toprofile,touserid,
             custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
             orderid,shipid,orderitem,orderlot,priority,
             prevpriority,curruserid,lastuser,lastupdate,
             pickuom, pickqty, picktotype, wave,
             pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
             shippinglpid, shippingtype, cartongroup, labeluom)
            values
            (tk.taskid,tk.tasktype,null,
             fromloc.section,lp.location,fromloc.equipprof,toloc.section,
             in_stageloc,toloc.equipprof,null,oh.custid,cm.item,lp.lpid,
             lp.unitofmeasure,findbaseqty,fromloc.pickingseq,oh.loadno,
             oh.stopno,oh.shipno,in_orderid,in_shipid,in_orderitem,
             in_orderlot,l_taskpriority,l_taskpriority,null,in_userid,
             sysdate,findpickuom,findpickqty,findpicktotype,oh.wave,
             fromloc.pickingzone,findcartontype,
             zcwt.lp_item_weight(lp.lpid,oh.custid,cm.item,findpickuom) * findpickqty,
             zci.item_cube(oh.custid,cm.item,findpickuom) * findpickqty,
             zlb.staff_hours(in_facility,oh.custid,cm.item,tk.tasktype,
             fromloc.pickingzone,findpickuom,findpickqty),tk.cartonseq,
             sp.lpid, shippingplatetype,
             zwv.cartontype_group(findcartontype), findlabeluom);
          if lp.lpid is not null then
            update plate
               set qtytasked = nvl(qtytasked,0) + findbaseqty,
                   lastuser = in_userid,
                   lastupdate = sysdate
             where lpid = lp.lpid
               and parentfacility is not null;
          end if;
          cntTasks := cntTasks + 1;
        end if;
      else
        if stdAllocation = True then
          if cu.pick_by_line_number_yn = 'Y' and
             ol.uomentered != ci.baseuom then
            trace_msg('No line-item pick for uom ' || ol.uomentered || ' ' || ol.qty);
            ol.qty := 0;
          else
            stdAllocation := False;
          end if;
        else
          if cu.pick_by_line_number_yn = 'Y' then
            ol.qty := 0;
            trace_msg('Line Pick Shortage ' || ol.uomentered || ' ' || ol.qty);
            stdAllocation := True;
          else
            if cntTasks = 0 then
              out_msg := out_msg || ' ' || in_orderid || '-' ||
                in_shipid || ' ' || in_orderitem || ' ' ||
                cm.item || ' ' || cm.lotnumber || ' ' ||
                cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty;
              zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
                out_msg, 'W', in_userid, strMsg);
            elsif out_msg = 'No inventory found' then
              out_msg := 'No more inventory found' || ' ' || in_orderid || '-' ||
                in_shipid || ' ' || in_orderitem || ' ' ||
                cm.item || ' ' || cm.lotnumber || ' ' ||
                cm.invstatus || ' ' || cm.inventoryclass || ' ' || cm.qty;
              zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
                out_msg, 'W', in_userid, strMsg);
            end if;
            cm.qty := 0;
          end if;
        end if;
      end if;
    << continue_task_create_loop >>
      null;
    end loop; -- task create loop
    if cu.pick_by_line_number_yn = 'Y' then
      if curOrderDtlLine%isopen then
        close curOrderDtlLine;
      end if;
    else
      if (cm.qty <= 0) and
         (findorderedbyweight = 'Y') and
         (cntTasks != 0) then
        trace_msg('obw--qtyCommReleased ' || qtyCommReleased || ' pi.qty ' || pi.qty);
        qtyCommReleased := qtyCommReleased + pi.qty;
        if qtyCommReleased != qtyOrigCommit then
          update commitments
             set qty = qtyCommReleased
           where facility = oh.fromfacility
             and custid = oh.custid
             and item = cm.item
             and inventoryclass = cm.inventoryclass
             and invstatus = cm.invstatus
             and status = 'CM'
             and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
             and orderid = in_orderid
             and shipid = in_shipid
             and orderitem = in_orderitem
             and nvl(orderlot,'(none)') = nvl(in_orderlot,'(none)');
        end if;
        qtyLineReleased := qtyLineReleased + qtyCommReleased;
        trace_msg('obw--newqtyOrder ' || qtyLineReleased || ' qtyOrder ' || od.qtyorder);
      end if;
    end if;
  end loop; -- commitment loop
  if findorderedbyweight = 'Y' then
    qtyLineReleased := qtyLineReleased + od.qtypick;
    if qtyLineReleased != od.qtyorder then
      update orderdtl
         set qtyorder = qtyLineReleased,
             weightorder = zci.item_weight(custid,item,uom) * qtyLineReleased,
             cubeorder = zci.item_cube(custid,item,uom) * qtyLineReleased,
             amtorder =  zci.item_amt(custid,orderid,shipid,item,lotnumber) * qtyLineReleased,
             lastuser = in_userid,
             lastupdate = sysdate
       where orderid = oh.orderid
         and shipid = oh.shipid
         and item = in_orderitem
         and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)');
    end if;
  end if;
end if;

<< create_kit >>

open curItem(oh.custid,in_orderitem);
fetch curItem into ci;
close curItem;

if zwo.work_order_update_needed(oh.ordertype,oh.componenttemplate,ci.iskit,
       od.childorderid,od.inventoryclass,ci.unkitted_class) = 'Y' then
  zwo.update_work_order(
    in_orderid,
    in_shipid,
    in_orderitem,
    in_orderlot,
    req_type,
    in_facility,
    in_taskpriority,
    l_picktype,
    in_complete,
    in_stageloc,
    in_userid,
    1,
    out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('LineRelease', in_facility, oh.custid,
      out_msg, 'W', in_userid, strMsg);
  end if;
  od := null;
  open curOrderDtl;
  fetch curOrderDtl into od;
  close curOrderDtl;
  if od.item is null then
    out_msg := 'Order Line not re-found: ' || in_orderid || ' ' ||
      in_shipid || ' ' || in_orderitem || ' ' || in_orderlot;
    return;
  end if;
  if nvl(od.childorderid,0) != 0 then
    co := null;
    open curOrder(od.childorderid,od.childshipid);
    fetch curOrder into co;
    close curOrder;
    if co.ordertype is null then
      out_msg := 'Child Order Header not found: ' || in_orderid || ' ' ||
        in_shipid || ' ' || od.childorderid || ' ' || od.childshipid;
      return;
    end if;
    if nvl(co.wave,0) = 0 then
      update orderhdr
         set wave = oh.wave,
             orderstatus = '4',
             commitstatus = '3',
             lastuser = in_userid,
             lastupdate = sysdate
       where orderid = od.childorderid
         and shipid = od.childshipid;
    end if;
    if (oh.ordertype = 'O' and oh.componenttemplate is not null) and
       (nvl(co.wave,0) != 0) then
      null; --release components only once
    else
      for cl in curChildLine(od.childorderid,od.childshipid)
      loop
        zwv.release_line(
          od.childorderid,
          od.childshipid,
          cl.item,
          cl.lotnumber,
          req_type,
          in_facility,
          in_taskpriority,
          l_picktype,
          'Y',
          in_stageloc,
          in_sortloc,
          in_batchcartontype,
          in_regen,
          in_userid,
          in_trace,
          in_recurse_count + 1,
          out_msg);
        if substr(out_msg,1,4) != 'OKAY' then
          zms.log_msg('WaveRelease', co.fromfacility, co.custid,
              out_msg, 'W', in_userid, strMsg);
        end if;
      end loop;
    end if;
  end if;
end if;

<<finish_line_release>>

if in_complete = 'Y' then -- generating picks for this line only
--  zut.prt('complete from release line');
  complete_pick_tasks(oh.wave,in_facility,in_orderid,in_shipid,tsk_priority,
    in_taskpriority, l_picktype, in_userid, tsk_curruserid, tsk_touserid, l_consolidated,
    in_trace, out_errorno, out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('LineRelease', in_facility, oh.custid,
      out_msg, 'W', in_userid, strMsg);
  end if;
  if oh.ordertype != 'K' then
    zbp.generate_batch_tasks(oh.wave,in_facility,in_taskpriority,
      l_picktype,in_batchcartontype,in_sortloc,in_userid,
      in_trace,l_consolidated,out_errorno,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('LineRelease', in_facility, oh.custid,
        out_msg, 'W', in_userid, strMsg);
    end if;
  end if;
  zlb.compute_line_labor(in_orderid,in_shipid,in_orderitem,
    in_orderlot,in_userid,l_picktype,in_facility,'Y',
    out_errorno, out_msg);
  if out_errorno != 0 then
    zms.log_msg('LABORCALC', in_facility, oh.custid,
      out_msg, 'E', in_userid, strMsg);
  end if;
end if;

<<create_itemdemand>>

zid.create_itemdemand_for_shortage(in_orderid,in_shipid,in_orderitem,in_orderlot,
  in_userid,intErrorno,out_msg);
if intErrorno != 0 then
  zms.log_msg('WaveRelease', oh.fromfacility, oh.custid,
    'Item Demand: ' || in_orderid || '-' || in_shipid || ' ' ||
    in_orderitem || ' ' || in_orderlot || ' ' ||
    out_msg, 'E', in_userid, strMsg);
end if;

<<end_release>>

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvrl ' || sqlerrm;
end release_line;

PROCEDURE unrelease_line
(in_facility varchar2
,in_custid varchar2
,in_orderid number
,in_shipid number
,in_orderitem varchar2
,in_uom varchar2
,in_lotnumber varchar2
,in_invstatusind varchar2
,in_invstatus varchar2
,in_invclassind varchar2
,in_inventoryclass varchar2
,in_qty number
,in_priority varchar2
,in_reqtype varchar2
,in_userid varchar2
,in_trace varchar2
,out_msg  IN OUT varchar2
) is

cursor curOrderDtl is
  select childorderid,
         childshipid
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
od curOrderDtl%rowtype;

begin

ztk.delete_subtasks_by_orderitem(
  in_orderid,
  in_shipid,
  in_orderitem,
  in_lotnumber,
  in_userid,
  in_reqtype,
  out_msg);

zbp.delete_batchtasks_by_orderitem(
  in_orderid,
  in_shipid,
  in_orderitem,
  in_lotnumber,
  in_userid,
  in_reqtype,
  out_msg);

open curOrderDtl;
fetch curOrderDtl into od;
close curOrderdtl;
if od.childorderid is not null then
  zoe.cancel_order(od.childorderid,od.childshipid,in_facility,
       null,in_userid,out_msg);
  update orderhdr
     set wave = 0
   where orderid = od.childorderid
     and shipid = od.childshipid;
  update orderdtl
     set childorderid = null,
         childshipid = null
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)');
end if;

out_msg := 'OKAY';

exception when others then
  out_msg := 'zwvul ' || sqlerrm;
end unrelease_line;

procedure unrelease_order
(in_orderid number
,in_shipid number
,in_facility varchar2
,in_userid varchar2
,in_reqtype varchar2 -- '1' wave release form
,in_trace varchar2
,out_wave IN OUT number
,out_msg IN OUT varchar2
) is

cursor curOrderhdr is
  select orderid,
         shipid,
         fromfacility,
         orderstatus,
         commitstatus,
         custid,
         priority,
         wave,
         nvl(loadno,0) as loadno,
         qtypick
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curWaves(in_wave number) is
  select wave,
         wavestatus,
         facility,
         nvl(sdi_sortation_yn, 'N') as sdi_sortation_yn,
         nvl(sdi_sorter_process, 'xxx') as sdi_sorter_process,
         nvl(sdi_retail_exported, 'N') as sdi_retail_exported
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cursor curOrderdtl is
  select item, uom, lotnumber,
         invstatusind, invstatus,
         invclassind, inventoryclass,
         nvl(qtyorder,0) - nvl(qtycommit,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
   order by item, lotnumber;

cursor curBatchTasks is
  select rowid,
         taskid,
         custid,
         facility,
         lpid
    from subtasks
   where orderid = 0
     and shipid = 0
     and facility = in_facility
     and wave = out_wave;
bt curBatchTasks%rowtype;

cntRows integer;
msg varchar2(255);
intErrorno integer;
l_skip_kit_check pls_integer;
l_simple_kit_count pls_integer;
l_wave waves.wave%type;

begin

out_msg := '';

oh := null;
open curOrderhdr;
fetch curOrderhdr into oh;
close curOrderHdr;
if oh.orderid is null then
  out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' not found';
  return;
end if;

if oh.orderstatus = 'X' then
  out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' is cancelled';
  return;
end if;

if oh.qtypick > 0 then
  out_msg := 'Order ' || in_orderid || '-' || in_shipid || ' has picks';
  return;
end if;

select count(1)
into l_skip_kit_check
from custitem
where custid in (select distinct custid 
                 from orderhdr 
                 where wave = oh.wave)
  and iskit = 'S';

if (l_skip_kit_check > 0) then
  select count(1)
    into l_simple_kit_count
    from orderdtl od
   where orderid = in_orderid
     and shipid = in_shipid
     and exists (select 1 from custitemview civ
                  where civ.custid = od.custid
                    and civ.item = od.item
                    and civ.iskit = 'S');
  if l_simple_kit_count != 0 then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
               ' has simplified kit items';
    return;
  end if;
                
  select count(1)
    into l_simple_kit_count
    from orderhdr ohd, orderdtl od
   where nvl(ohd.wave,0) = nvl(oh.wave,0)
     and nvl(ohd.wave,0) <> 0
     and od.orderid = ohd.orderid
     and od.shipid = ohd.shipid
     and exists (select 1 from custitemview civ
                  where civ.custid = od.custid
                    and civ.item = od.item
                    and civ.iskit = 'S');
  if l_simple_kit_count != 0 then
    out_msg := 'Wave ' || oh.wave ||
               ' has orders with simplified kit items';
    return;
  end if;
end if;
              
if in_reqtype = '1' then
  if oh.orderstatus > '4' then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
           ' Invalid order status: ' || oh.orderstatus;
    return;
  end if;
  if oh.commitstatus < '1' then
    out_msg := 'Order ' || in_orderid || '-' || in_shipid ||
           ' Invalid commitment status: ' || oh.commitstatus;
    return;
  end if;
end if;

wv := null;
if out_wave = 0 then
  l_wave := oh.wave;
else
  l_wave := out_wave;
end if;
open curWaves(l_wave);
fetch curWaves into wv;
close curWaves;
if wv.wave is null then
  out_msg := 'Wave not found: ' || l_wave;
  return;
end if;
if (wv.sdi_sortation_yn = 'Y') and
   (wv.sdi_sorter_process = 'RETAIL') and
   (wv.sdi_retail_exported = 'Y') then
  out_msg := 'Wave ' || l_wave || ' has already been exported to sorter';
  return;
end if;

if out_wave = 0 then -- single order unreleased
  select count(1)
    into cntRows
    from tasks
   where wave = oh.wave
     and tasktype in ('BP','SO');
  if cntRows <> 0 then
    out_msg := 'There are batch picks in this wave. (Only Unrelease All is acceptable)';
    return;
  end if;
  select count(1)
    into cntRows
    from subtasks ST, tasks TK
   where ST.orderid = in_orderid
     and ST.shipid = in_shipid
     and TK.taskid = ST.taskid
     and Tk.priority = '0';
  if cntRows <> 0 then
    out_msg := 'There are active tasks for this order: ' || in_orderid || '-' || in_shipid;
    return;
  end if;
  select count(1)
    into cntRows
    from orderhdr
   where wave = oh.wave;
  if cntRows = 1 then
    out_wave := oh.wave;
  else
    get_next_wave(wv.wave,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      return;
    end if;
    insert into waves
     (wave, descr, wavestatus, facility, lastuser, lastupdate)
     values
     (wv.wave, 'Unreleased', '1', in_facility, in_userid, sysdate);
    out_wave := wv.wave;
  end if;
else  -- whole wave being unreleased
  begin
    cntRows := 0;
    select count(1)
      into cntRows
      from tasks
     where wave = oh.wave
       and priority = '0';
  exception when others then
    cntRows := 1;
  end;
  if cntRows <> 0 then
    out_msg := 'Wave has active tasks';
    return;
  end if;
  select count(1)
    into cntRows
    from orderhdr
   where wave = out_wave
     and orderstatus > '4'
     and orderstatus < 'X';
  if cntRows != 0 then
    out_msg := 'Wave contains orders beyond Released status';
    return;
  end if;
  if wv.wavestatus > '3' then
    out_msg := 'Wave has invalid status for unrelease: ' || wv.wavestatus;
    return;
  end if;
  cntRows := 0;
  begin
    select count(1)
      into cntRows
      from orderhdr
     where wave = oh.wave
       and nvl(qtypick,0) != 0;
  exception when others then
    cntRows := 1;
  end;
  if cntRows != 0 then
    out_msg := 'Wave contains orders that have picks';
    return;
  end if;
  for bt in curBatchTasks
  loop
    ztk.subtask_no_pick(bt.rowid, bt.facility, bt.custid, bt.taskid, bt.lpid,
      in_userid, 'N', out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      zms.log_msg('DeleteTask', bt.facility, bt.custid,
         out_msg, 'E', in_userid, msg);
    end if;
  end loop;
end if;

for od in curOrderdtl
loop
  zwv.unrelease_line
      (oh.fromfacility
      ,oh.custid
      ,in_orderid
      ,in_shipid
      ,od.item
      ,od.uom
      ,od.lotnumber
      ,od.invstatusind
      ,od.invstatus
      ,od.invclassind
      ,od.inventoryclass
      ,od.qty
      ,oh.priority
      ,in_reqtype
      ,in_userid
      ,in_trace
      ,out_msg
      );
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', in_facility, oh.custid,
        out_msg, 'W', in_userid, msg);
  end if;
end loop;

update orderhdr
   set orderstatus = '2', -- committed
       commitstatus = '1', -- selected
       shipshort = decode(nvl(shipshort,'N'),'Y','N',shipshort),
       wave = out_wave,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

if out_wave != 0 then
  select count(1)
    into cntRows
    from orderhdr
   where wave = out_wave
     and orderstatus > '2'
     and orderstatus < 'X';
  if cntRows = 0 then
    update waves
       set wavestatus = '1',
           lastuser = in_userid,
           lastupdate = sysdate
     where wave = out_wave
       and wavestatus > '1';

    update location
       set flex_pick_front_wave = 0,
           flex_pick_front_item = null,
           lastuser = in_userid,
           lastupdate = sysdate
     where facility = in_facility
       and nvl(flex_pick_front_wave, 0) = out_wave
       and loctype = 'FPF';
  end if;
end if;

if oh.loadno != 0 then
  select count(1)
    into cntRows
    from orderhdr
   where loadno = oh.loadno
     and orderstatus > '2';
  if cntRows = 0 then
    update loads
       set loadstatus = '2',
           lastuser = in_userid,
           lastupdate = sysdate
     where loadno = oh.loadno
       and loadstatus > '2';
  end if;
end if;

if oh.wave != 0 then
  begin
   select min(orderstatus)
     into oh.orderstatus
     from orderhdr
    where wave = oh.wave
      and ordertype not in ('W','K');
   exception when no_data_found then
      oh.orderstatus := '9';
   end;

   if oh.orderstatus > '8' then
      update waves
         set wavestatus = '4',
             lastuser = in_userid,
             lastupdate = sysdate
       where wave = oh.wave
         and wavestatus < '4';
   end if;
end if;

zoh.add_orderhistory(in_orderid, in_shipid,
     'Order Unreleased',
     'Order Unreleased Wave:'|| oh.wave,
     in_userid, out_msg);

zprono.check_for_prono_assignment
(in_orderid
,in_shipid
,'Wave Unrelease'
,intErrorno
,msg
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'zwvuo ' || sqlerrm;
end unrelease_order;

procedure ready_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curWaves is
  select wavestatus
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cntError integer;

begin

out_msg := '';
cntError := 0;

open curWaves;
fetch curWaves into wv;
if curWaves%notfound then
  close curWaves;
  out_msg := 'Wave not found: ' || in_wave;
  return;
end if;
close curWaves;

if wv.wavestatus != '1' then
  out_msg := 'Invalid wave status: ' || wv.wavestatus;
  return;
end if;

update waves
   set wavestatus = '2',
       lastuser = in_userid,
       lastupdate = sysdate
 where wave = in_wave;

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvrw ' || sqlerrm;
end ready_wave;

procedure undo_ready_wave
(in_wave number
,in_reqtype varchar2
,in_facility varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
) is

cursor curWaves is
  select wavestatus
    from waves
   where wave = in_wave;
wv curWaves%rowtype;

cntError integer;

begin

out_msg := '';
cntError := 0;

open curWaves;
fetch curWaves into wv;
if curWaves%notfound then
  close curWaves;
  out_msg := 'Wave not found: ' || in_wave;
  return;
end if;
close curWaves;

if wv.wavestatus != '2' then
  out_msg := 'Invalid wave status: ' || wv.wavestatus;
  return;
end if;

update waves
   set wavestatus = '1',
       lastuser = in_userid,
       lastupdate = sysdate
 where wave = in_wave;

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvrw ' || sqlerrm;
end undo_ready_wave;

procedure complete_pick_tasks
(in_wave number
,in_facility varchar2
,in_orderid number
,in_shipid number
,in_taskpriority varchar2
,in_taskprevpriority varchar2
,in_picktype varchar2
,in_userid varchar2
,in_curruserid varchar2
,in_touserid varchar2
,in_consolidated varchar2
,in_trace varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

cursor curGroupSum is
  select tasktype,
         picktotype,
         cartontype,
         sum(weight) as weight,
         sum(cube) as cube
    from subtasks
   where wave = in_wave
     and taskid = 0
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and picktotype not in ('FULL','LBL')
     and exists (select 1
                   from cartongroups
                  where subtasks.cartontype = cartongroups.cartongroup)
   group by tasktype, picktotype, cartontype
   order by tasktype, picktotype, cartontype;
gs curGroupSum%rowtype;

cursor curGroupDtl(in_tasktype varchar2, in_picktotype varchar2,
  in_cartontype varchar2) is
  select st.*,
         st.rowid subtasksrowid,
         '' separate_batch_tasks_yn,
         0  batch_tasks_limit,
         w.pick_by_zone,
         nvl(ci.productgroup,'X') productgroup,
         w.pick_by_productgroup,
         w.batch_pick_by_item_yn,
         nvl(w.consolidated,'N') consolidated,
         nvl(w.master_wave,0) master_wave
    from waves w, subtasks st, custitem ci
   where w.wave = st.wave
     and st.custid = ci.custid(+)
     and st.item = ci.item(+)
     and st.wave = in_wave
     and st.taskid = 0
     and st.facility is null
     and st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.tasktype = in_tasktype
     and st.picktotype = in_picktotype
     and st.cartontype = in_cartontype
     and exists (select 1
                   from cartongroups
                  where st.cartontype = cartongroups.cartongroup)
   order by st.tasktype, st.picktotype, st.cartontype, st.locseq, st.fromloc, st.item;
gd curGroupDtl%rowtype;

cursor curCartonMin(in_cartongroup varchar2, in_weight number,
  in_cube number) is
  select code as cartontype,
         maxweight,
         (nvl(maxcube,0)+1) / 1728.0 as maxcube
    from cartongroupsview
   where cartongroup = in_cartongroup
     and maxweight >= in_weight
     and nvl(maxcube,0) / 1728.0 >= in_cube
   order by maxcube, maxweight;

cursor curCartonMax(in_cartongroup varchar2) is
  select code as cartontype,
         maxweight,
         (nvl(maxcube,0)+1) / 1728.0 as maxcube
    from cartongroupsview
   where cartongroup = in_cartongroup
   order by maxcube desc, maxweight;
cm curCartonMax%rowtype;

cursor curSubTasks is
  select st.*,
         st.rowid subtasksrowid,
         nvl(z.separate_batch_tasks_yn,'N') as separate_batch_tasks_yn,
         nvl(z.batch_tasks_limit,0) as batch_tasks_limit,
         w.pick_by_zone,
         nvl(ci.productgroup,'X') productgroup,
         nvl(w.pick_by_productgroup,'N') pick_by_productgroup,
         w.batch_pick_by_item_yn,
         nvl(w.consolidated,'N') consolidated,
         nvl(w.master_wave,0) master_wave
    from waves w, zone z, subtasks st, custitem ci
   where w.wave = st.wave
     and z.zoneid(+) = st.pickingzone
     and z.facility(+) = in_facility
     and st.custid = ci.custid(+)
     and st.item = ci.item(+)
     and st.wave = in_wave
     and st.taskid = 0
     and st.facility is null
     and st.orderid = in_orderid
     and st.shipid = in_shipid
     order by st.tasktype, 
              decode(st.tasktype,'OP','X','BP','X','SO','X',st.picktotype),
              decode(st.tasktype,'OP','X','BP','X','SO','X',st.cartontype),
              decode(st.tasktype,'BP',z.separate_batch_tasks_yn,'X'),
              decode(st.tasktype,'SO',decode(nvl(w.consolidated,'N'),'Y',decode(nvl(w.master_wave,0),0,'X',st.lpid),'X'),'X'),
              decode(nvl(w.pick_by_productgroup,'N'),'Y',decode(st.tasktype,'OP',nvl(ci.productgroup,'X'),'X'),'X'),
              st.pickingzone,
              st.locseq,
              st.fromloc, 
              st.item;
sb  curSubTasks%rowtype;
sb2 curSubTasks%rowtype;

cursor curDupTaskSum is
  select st.taskid,
         st.fromloc,
         nvl(st.lpid,'x') as lpid,
         st.item,
         st.orderitem,
		 nvl(sp.lotnumber, 'x') as lotnumber,
         nvl(st.orderlot, 'x') as orderlot,
         st.pickuom,
         st.picktotype,
         st.cartontype,
         st.cartonseq,
         count(1) as count
    from subtasks st, shippingplate sp
   where st.wave = in_wave
     and st.facility is null
     and st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.picktotype not in ('FULL','LBL')
	 and nvl(st.shippinglpid,'NA') = sp.lpid(+)
   group by st.taskid,st.fromloc,nvl(st.lpid,'x'),st.item,st.orderitem,nvl(sp.lotnumber, 'x'),nvl(st.orderlot,'x'),st.pickuom,st.picktotype,
            st.cartontype,st.cartonseq
   having count(1) > 1;

cursor curDupTaskDtl (in_taskid varchar2, in_fromloc varchar2,
  in_lpid varchar2, in_item varchar2, in_orderitem varchar2, in_orderlot varchar2,
  in_pickuom varchar2, in_picktotype varchar2, in_cartontype varchar2,
  in_cartonseq number, in_lotnumber varchar2) is
  select st.*,
         st.rowid subtasksrowid,
         '' separate_batch_tasks_yn,
         0  batch_task_limit,
         w.pick_by_zone,
         nvl(ci.productgroup,'X') productgroup,
         w.pick_by_productgroup,
         w.batch_pick_by_item_yn,
         nvl(w.consolidated,'N') consolidated,
         nvl(w.master_wave,0) master_wave
    from waves w, subtasks st, shippingplate sp, custitem ci
   where w.wave = st.wave
     and st.custid = ci.custid(+)
     and st.item = ci.item(+)
     and st.wave = in_wave
     and st.orderid = in_orderid
     and st.shipid = in_shipid
     and st.taskid = in_taskid
     and st.fromloc = in_fromloc
     and nvl(st.lpid,'x') = in_lpid
     and st.item = in_item
	 and nvl(sp.lotnumber,'x') = nvl(in_lotnumber,'x')
     and st.orderitem = in_orderitem
     and nvl(st.orderlot,'x') = nvl(in_orderlot,'x')
     and st.pickuom = in_pickuom
     and st.picktotype = in_picktotype
     and st.cartontype = in_cartontype
     and st.cartonseq = in_cartonseq
	 and nvl(st.shippinglpid,'NA') = sp.lpid(+);

cursor curCartonChkSum is
  select taskid,
         cartongroup,
         picktotype,
         cartontype,
         cartonseq,
         sum(weight) as weight,
         sum(cube) as cube
    from subtasks
   where wave = in_wave
     and facility is null
     and cartongroup is not null
     and orderid = in_orderid
     and shipid = in_shipid
     and picktotype not in ('FULL','LBL')
   group by taskid,cartongroup,picktotype,cartontype,cartonseq
   order by taskid,cartongroup,picktotype,cartontype,cartonseq;
cc curCartonChkSum%rowtype;

cursor curNextSeq (in_taskid varchar2, in_picktotype varchar2,
  in_cartontype varchar2) is
  select nvl(max(cartonseq),0)+1 as cartonseq
    from subtasks
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and taskid = in_taskid
     and picktotype = in_picktotype
     and cartontype = in_cartontype;

cursor curCartonSub(in_tasktype varchar2, in_picktotype varchar2, in_cartontype varchar2) is
  select cartonseq,
         sum(weight) as weight,
         sum(cube) as cube
    from subtasks
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and tasktype = in_tasktype
     and picktotype = in_picktotype
     and cartontype = in_cartontype
     and cartonseq is not null
   group by cartonseq
   order by cartonseq desc;
cs curCartonSub%rowtype;

cursor curCartonLimits(in_cartontype varchar2) is
  select decode(nvl(maxweight,0.0),0.0,100.0,maxweight) as maxweight,
         decode(nvl(maxcube,0.0)/1728.0,0.0,10.0,maxcube/1728.0) as maxcube
    from cartontypes
   where code = in_cartontype;
cl curCartonLimits%rowtype;

cursor curShippingPlate(in_lpid varchar2) is
  select *
    from shippingplate
   where lpid = in_lpid;
sp curShippingPlate%rowtype;

--hrsLimit tasks.staffhrs%type;
tk tasks%rowtype;
tk_separate_batch_tasks_yn zone.separate_batch_tasks_yn%type;
tk_batch_tasks_limit zone.batch_tasks_limit%type;
tk_pick_by_zone waves.pick_by_zone%type;
tk_pick_by_productgroup waves.pick_by_productgroup%type;
tk_productgroup custitem.productgroup%type;
tk_batch_pick_by_item_yn waves.batch_pick_by_item_yn%type;
st_item subtasks.item%type;
st_lpid subtasks.lpid%type;
st subtasks%rowtype;
carton_filled boolean;
newcartonseq subtasks.cartonseq%type;
strMsg varchar(255);
cntSubTasks integer;
v_allowpickpassing customer.allowpickpassing%type;
v_subtask subtasks%rowtype;

procedure trace_msg(in_msg varchar2) is
strOutMsg appmsgs.msgtext%type;
numCols integer;

begin

  if nvl(in_trace,'x') != 'Y' then
    return;
  end if;

  numCols := 1;
  while (numCols * 254) < (Length(in_msg)+254)
  loop
    zms.log_msg('CMPLTASK', in_facility, null,
                substr(in_msg,((numCols-1)*254)+1,254),
                'T', 'CMPLTASK', strOutMsg);
    numCols := numCols + 1;
  end loop;
end;

procedure insert_task_row is
begin
  if tk.taskid is null then
    return;
  end if;
  insert into tasks
    (taskid, tasktype,toloc,tosection,toprofile,
     custid,locseq,fromloc,fromsection,fromprofile,
     loadno,stopno,shipno,orderid,shipid,
     priority,prevpriority,lastuser,lastupdate,
     qty, pickqty, wave, pickingzone,
     weight, cube, staffhrs, picktotype, cartontype,
     cartonseq, curruserid, touserid)
    values
    (tk.taskid, tk.tasktype, tk.toloc, tk.tosection, tk.toprofile,
     tk.custid, tk.locseq, tk.fromloc, tk.fromsection, tk.fromprofile,
     tk.loadno, tk.stopno, tk.shipno, tk.orderid, tk.shipid,
     in_taskpriority, in_taskprevpriority, in_userid, sysdate,
     tk.qty, tk.pickqty, in_wave, tk.pickingzone,
     tk.weight, tk.cube, tk.staffhrs, tk.picktotype, tk.cartontype,
     tk.cartonseq, in_curruserid, in_touserid);
  tk.taskid := null;
  cntSubTasks := 0;
end;

begin

out_errorno := 0;
out_msg := '';

--zut.prt('group loop');
while (1=1) loop
  open curGroupSum;
  fetch curGroupSum into gs;
  if curGroupSum%notfound then
--    zut.prt('no more groups');
    close curGroupSum;
    exit;
  end if;
--zut.prt('processing ' || gs.picktotype || ' ' ||
--  gs.cartontype || ' ' || gs.weight || ' ' || gs.cube);
  open curCartonMin(gs.cartontype, gs.weight, gs.cube);
  fetch curCartonMin into cm;
  if curCartonMin%notfound then
--    zut.prt('no min');
    close curCartonMin;
    open curCartonMax(gs.cartontype);
    fetch curCartonMax into cm;
    close curCartonMax;
    tk.weight := 0;
    tk.cube := 0;
    for gd in curGroupDtl(gs.tasktype, gs.picktotype, gs.cartontype) loop
--    zut.prt('gd ' || gd.tasktype || ' ' || gs.cartontype || ' ' || gs.picktotype
--      || ' ' || gd.pickqty || ' ' || gd.item || ' ' || gd.weight ||
--      ' ' || gd.cube || ' ' || cm.maxweight || ' ' || cm.maxcube ||
--      ' ' || tk.weight || ' ' || tk.cube);
      if ( (gd.weight + tk.weight) > cm.maxweight ) or
         ( (gd.cube + tk.cube) > cm.maxcube ) then
        begin
          if (gd.weight + tk.weight) > cm.maxweight then
            if (gd.cube + tk.cube) > cm.maxcube then
              st.weight := gd.weight / gd.pickqty;
              st.cube := gd.cube / gd.pickqty;
              if floor((cm.maxweight - tk.weight) / st.weight) <= floor((cm.maxcube - tk.cube) / st.cube) then
                st.pickqty := floor((cm.maxweight - tk.weight) / st.weight);
              else
                st.pickqty := floor((cm.maxcube - tk.cube) / st.cube);
              end if;                
            else
              st.weight := gd.weight / gd.pickqty;
              st.pickqty := floor((cm.maxweight - tk.weight) / st.weight);
            end if;
          else
            st.cube := gd.cube / gd.pickqty;
            st.pickqty := floor((cm.maxcube - tk.cube) / st.cube);
          end if;
        exception when others then
          st.pickqty := 0;
        end;
--      zut.prt('st.pickqty ' || st.pickqty || ' '
--        || nvl(st.weight,-1) || ' ' || nvl(st.cube,-2));
        if (st.pickqty > 0) then
          sb2 := gd;
          sb2.pickqty := gd.pickqty - st.pickqty;
          sb2.weight := zcwt.lp_item_weight(gd.lpid,gd.custid,gd.item,gd.pickuom) * sb2.pickqty;
          sb2.cube := zci.item_cube(gd.custid,gd.item,gd.pickuom) * sb2.pickqty;
          zbut.translate_uom(gd.custid,gd.item,sb2.pickqty,
            sb2.pickuom,sb2.uom,sb2.qty,out_msg);
          sb2.staffhrs := zlb.staff_hours(in_facility,gd.custid,gd.item,'PICK',
             gd.pickingzone,sb2.pickuom,sb2.pickqty);
          gd.pickqty := st.pickqty;
          gd.weight := zcwt.lp_item_weight(gd.lpid,gd.custid,gd.item,gd.pickuom) * gd.pickqty;
          gd.cube := zci.item_cube(gd.custid,gd.item,gd.pickuom) * gd.pickqty;
          zbut.translate_uom(gd.custid,gd.item,gd.pickqty,
                 gd.pickuom,gd.uom,gd.qty,out_msg);
          gd.staffhrs := zlb.staff_hours(in_facility,gd.custid,gd.item,'PICK',
             gd.pickingzone,gd.pickuom,gd.pickqty);
          if gd.shippingtype = 'F' then
            gd.shippingtype := 'P';
          end if;
          if in_orderid != 0 then
            open curShippingPlate(sb2.shippinglpid);
            fetch curShippingPlate into sp;
            close curShippingPlate;
            zsp.get_next_shippinglpid(sp.lpid,out_msg);
          else
            sp.lpid := null;
          end if;
--        zut.prt('ins qty ' || sb2.qty || ' '
--          || sb2.weight || ' ' || sb2.cube || ' ' || sb2.cartontype);
          insert into subtasks
            (taskid, tasktype, facility, fromsection, fromloc,
             fromprofile,tosection,toloc,toprofile,touserid,
             custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
             orderid,shipid,orderitem,orderlot,priority,
             prevpriority,curruserid,lastuser,lastupdate,
             pickuom, pickqty, picktotype, wave,
             pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
             shippinglpid, shippingtype, cartongroup, labeluom)
            values
            (0, sb2.tasktype, sb2.facility, sb2.fromsection, sb2.fromloc,
             sb2.fromprofile,sb2.tosection,sb2.toloc,sb2.toprofile,sb2.touserid,
             sb2.custid,sb2.item,sb2.lpid,sb2.uom,sb2.qty,sb2.locseq,sb2.loadno,
             sb2.stopno,sb2.shipno,sb2.orderid,sb2.shipid,sb2.orderitem,
             sb2.orderlot,sb2.priority,sb2.prevpriority,sb2.curruserid,
             sb2.lastuser,sysdate,sb2.pickuom, sb2.pickqty, sb2.picktotype,
             sb2.wave,sb2.pickingzone, sb2.cartontype, sb2.weight, sb2.cube,
             sb2.staffhrs, sb2.cartonseq,sp.lpid, 'P', sb2.cartongroup,
             sb2.labeluom);
          if in_orderid != 0 then
            insert into shippingplate
              (lpid, item, custid, facility, location, status, holdreason,
              unitofmeasure, quantity, type, fromlpid, serialnumber,
              lotnumber, parentlpid, useritem1, useritem2, useritem3,
              lastuser, lastupdate, invstatus, qtyentered, orderitem,
              uomentered, inventoryclass, loadno, stopno, shipno,
              orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
              pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
              values
              (sp.lpid, sp.item, sp.custid, sp.facility, sp.location, sp.status, sp.holdreason,
              sp.unitofmeasure, sb2.qty, 'P', sp.fromlpid, sp.serialnumber,
              sp.lotnumber, sp.parentlpid, sp.useritem1, sp.useritem2, sp.useritem3,
              sp.lastuser, sp.lastupdate, sp.invstatus, sp.qtyentered, sp.orderitem,
              sp.uomentered, sp.inventoryclass, sp.loadno, sp.stopno, sp.shipno,
              sp.orderid, sp.shipid, sb2.weight, sp.ucc128, sp.labelformat, 0, sp.orderlot,
              sp.pickuom, sb2.pickqty, null, sp.manufacturedate, sp.expirationdate);
          end if;
--        zut.prt('upd qty ' || gd.qty || ' '
--          || gd.weight || ' ' || gd.cube  || ' ' || cm.cartontype);
          update subtasks
             set cartontype = cm.cartontype,
                 pickqty = gd.pickqty,
                 qty = gd.qty,
                 weight = gd.weight,
                 cube = gd.cube,
                 staffhrs = gd.staffhrs,
                 shippingtype = gd.shippingtype
           where rowid = gd.subtasksrowid;
          if in_orderid != 0 then
            update shippingplate
               set type = gd.shippingtype,
                   pickqty = gd.pickqty,
                   quantity = gd.qty,
                   weight = gd.weight
             where lpid = gd.shippinglpid;
          end if;
        else
          if (gd.weight > cm.maxweight) or
             (gd.cube > cm.maxcube) then
            update subtasks
               set cartontype = 'PAL'
             where rowid = gd.subtasksrowid;
          end if;
        end if;
        exit;
      else
--      zut.prt('accum ' || cm.cartontype);
        update subtasks
           set cartontype = cm.cartontype
         where rowid = gd.subtasksrowid;
        tk.weight := tk.weight + gd.weight;
        tk.cube := tk.cube + gd.cube;
      end if;
    end loop;
  else
--  zut.prt('fits min ' || gs.tasktype || ' ' || gs.picktotype
--    || ' ' || gs.cartontype || ' ' || cm.cartontype ||
--    ' ' || gs.cube);
    close curCartonMin;
    update subtasks
       set cartontype = cm.cartontype
     where wave = in_wave
       and taskid = 0
       and tasktype = gs.tasktype
       and picktotype = gs.picktotype
       and cartontype = gs.cartontype;
  end if;
  close curGroupSum;
end loop;

tk.taskid := null;
cntSubTasks := 0;

while (1=1) loop
  open curSubTasks;
  fetch curSubTasks into sb;
  if curSubTasks%notfound then
    close curSubTasks;
    exit;
  end if;
  sb2.pickqty := 0;
  if in_trace = 'Y' then
     trace_msg('Cmplt_tsk: tk.taskid ' || to_char(tk.taskid) || ' tk.tasktype ' || tk.tasktype);
  end if;

  if (tk.taskid is not null) then
    if (sb.tasktype != tk.tasktype) then
      insert_task_row;
    elsif (tk.tasktype not in ('OP','BP','SO')) and
        ( (tk.picktotype in ('FULL','LBL')) or
          (sb.picktotype != tk.picktotype) or
          (sb.cartontype != tk.cartontype) ) then
        insert_task_row;
    elsif (tk.tasktype = 'BP') and
          ( ((tk_separate_batch_tasks_yn = 'Y') and (tk.pickingzone != sb.pickingzone))  or
            ((tk_separate_batch_tasks_yn = 'Y') and
             (tk_batch_tasks_limit > 0 and cntSubTasks >= tk_batch_tasks_limit)) or
           (tk_separate_batch_tasks_yn != sb.separate_batch_tasks_yn) ) then
       insert_task_row;
    elsif (tk_pick_by_zone = 'Y') and (tk.pickingzone != sb.pickingzone) then
      insert_task_row;
    elsif (tk_pick_by_productgroup = 'Y') and (tk_productgroup != sb.productgroup) then
      insert_task_row;
    elsif (tk_batch_pick_by_item_yn = 'Y') and (st_item != sb.item) then
      insert_task_row;
    elsif (tk.tasktype = 'SO') and
          (sb.consolidated = 'Y') and
          (sb.master_wave != 0) and
          (st_lpid != sb.lpid) then
       insert_task_row;
    end if;
  end if;
  if sb.picktotype not in ('FULL','LBL') then
    open curCartonSub(sb.tasktype,sb.picktotype,sb.cartontype);
    fetch curCartonSub into cs;
    if curCartonSub%notfound then
      cs.cartonseq := 0;
      cs.weight := 0;
      cs.cube := 0;
    end if;
    close curCartonSub;
    open curCartonLimits(sb.cartontype);
    fetch curCartonLimits into cl;
    if curCartonLimits%notfound then
      cl.maxweight := 100;
      cl.maxcube := 10;
    end if;
    close curCartonLimits;
    if ( (sb.weight + cs.weight) > cl.maxweight ) or
       ( (sb.cube + cs.cube) > cl.maxcube ) then
--      zut.prt('item ' || sb.item  || ' ' || sb.pickqty);
--      zut.prt(sb.weight + cs.weight || ' ' || cl.maxweight);
--      zut.prt(sb.cube + cs.cube || ' ' || cl.maxcube);
      begin
        if (sb.weight + cs.weight) > cl.maxweight then
          if (sb.cube + cs.cube) > cl.maxcube then
            st.weight := sb.weight / sb.pickqty;
            st.cube := sb.cube / sb.pickqty;
            if floor((cl.maxweight - cs.weight) / st.weight) <= floor((cl.maxcube - cs.cube) / st.cube) then
              st.pickqty := floor((cl.maxweight - cs.weight) / st.weight);
            else
              st.pickqty := floor((cl.maxcube - cs.cube) / st.cube);
            end if;
          else
            st.weight := sb.weight / sb.pickqty;
            st.pickqty := floor((cl.maxweight - cs.weight) / st.weight);
          end if;
        else
          st.cube := sb.cube / sb.pickqty;
          st.pickqty := floor((cl.maxcube - cs.cube) / st.cube);
        end if;
      exception when others then
        st.pickqty := 0;
      end;
      if (st.pickqty > 0) and
         (sb.pickqty > st.pickqty) then
        sb2 := sb;
        sb2.pickqty := sb.pickqty - st.pickqty;
        sb2.weight := zcwt.lp_item_weight(sb.lpid,sb.custid,sb.item,sb.pickuom) * sb2.pickqty;
        sb2.cube := zci.item_cube(sb.custid,sb.item,sb.pickuom) * sb2.pickqty;
        zbut.translate_uom(sb.custid,sb.item,sb2.pickqty,
               sb2.pickuom,sb2.uom,sb2.qty,out_msg);
        sb2.staffhrs := zlb.staff_hours(in_facility,sb.custid,sb.item,sb.tasktype,
             sb.pickingzone,sb2.pickuom,sb2.pickqty);
        sb.pickqty := st.pickqty;
        sb.weight := zcwt.lp_item_weight(sb.lpid,sb.custid,sb.item,sb.pickuom) * sb.pickqty;
        sb.cube := zci.item_cube(sb.custid,sb.item,sb.pickuom) * sb.pickqty;
        zbut.translate_uom(sb.custid,sb.item,sb.pickqty,
               sb.pickuom,sb.uom,sb.qty,out_msg);
        sb.staffhrs := zlb.staff_hours(in_facility,sb.custid,sb.item,sb.tasktype,
             sb.pickingzone,sb.pickuom,sb.pickqty);
        if cs.cartonseq = 0 then
          sb.cartonseq := 1;
        else
          sb.cartonseq := cs.cartonseq;
        end if;
      else
        if (tk.tasktype not in ('OP','BP','SO')) and
           (tk.taskid is not null) then
          insert_task_row;
        end if;
        sb.cartonseq := cs.cartonseq + 1;
        if ( sb.weight > cl.maxweight ) or
           ( sb.cube > cl.maxcube ) then
--        zut.prt('item2 ' || sb.item  || ' ' || sb.pickqty);
--        zut.prt(sb.weight || ' ' || cl.maxweight);
--        zut.prt(sb.cube || ' ' || cl.maxcube);
          if (sb.weight) > cl.maxweight then
            if (sb.cube) > cl.maxcube then
              st.weight := sb.weight / sb.pickqty;
              st.cube := sb.cube / sb.pickqty;
              if floor(cl.maxweight / st.weight) <= floor(cl.maxcube / st.cube) then
                st.pickqty := floor(cl.maxweight / st.weight);
              else
                st.pickqty := floor(cl.maxcube / st.cube);
              end if;
            else
              st.weight := sb.weight / sb.pickqty;
              st.pickqty := floor(cl.maxweight / st.weight);
            end if;
          else
            st.cube := sb.cube / sb.pickqty;
            st.pickqty := floor(cl.maxcube / st.cube);
          end if;
          if (st.pickqty > 0) and
             (sb.pickqty > st.pickqty) then
            sb2 := sb;
            sb2.pickqty := sb.pickqty - st.pickqty;
            sb2.weight := zcwt.lp_item_weight(sb.lpid,sb.custid,sb.item,sb.pickuom) * sb2.pickqty;
            sb2.cube := zci.item_cube(sb.custid,sb.item,sb.pickuom) * sb2.pickqty;
            sb2.staffhrs := zlb.staff_hours(in_facility,sb.custid,sb.item,sb.tasktype,
                 sb.pickingzone,sb2.pickuom,sb2.pickqty);
            zbut.translate_uom(sb.custid,sb.item,sb2.pickqty,
                   sb2.pickuom,sb2.uom,sb2.qty,out_msg);
            sb.pickqty := st.pickqty;
            sb.weight := zcwt.lp_item_weight(sb.lpid,sb.custid,sb.item,sb.pickuom) * sb.pickqty;
            sb.cube := zci.item_cube(sb.custid,sb.item,sb.pickuom) * sb.pickqty;
            zbut.translate_uom(sb.custid,sb.item,sb.pickqty,
                   sb.pickuom,sb.uom,sb.qty,out_msg);
            sb.staffhrs := zlb.staff_hours(in_facility,sb.custid,sb.item,sb.tasktype,
               sb.pickingzone,sb.pickuom,sb.pickqty);
          end if;
        end if;
      end if;
    else
      if cs.cartonseq = 0 then
        sb.cartonseq := 1;
      else
        sb.cartonseq := cs.cartonseq;
      end if;
    end if;
  else
    sb.cartonseq := 1;
  end if;
  if tk.taskid is null then
    ztsk.get_next_taskid(tk.taskid,out_msg);
    tk.tasktype := sb.tasktype;
    tk.custid := sb.custid;
    tk.toloc := sb.toloc;
    tk.tosection := sb.tosection;
    tk.toprofile := sb.toprofile;
    tk.fromloc := sb.fromloc;
    tk.fromsection := sb.fromsection;
    tk.fromprofile := sb.fromprofile;
    tk.locseq := sb.locseq;
    tk.loadno := sb.loadno;
    tk.stopno := sb.stopno;
    tk.shipno := sb.shipno;
    tk.orderid := sb.orderid;
    tk.shipid := sb.shipid;
    tk.pickqty := sb.pickqty;
    tk.qty := sb.qty;
    tk.pickingzone := sb.pickingzone;
    tk_productgroup := sb.productgroup;
    tk.weight := sb.weight;
    tk.cube := sb.cube;
    tk.staffhrs := sb.staffhrs;
    if tk.tasktype not in ('OP','BP','SO') then
      tk.picktotype := sb.picktotype;
      tk.cartontype := sb.cartontype;
      tk.cartonseq := sb.cartonseq;
    else
      tk.picktotype := null;
      tk.cartontype := null;
      tk.cartonseq := null;
    end if;
    tk_separate_batch_tasks_yn := sb.separate_batch_tasks_yn;
    tk_batch_tasks_limit := sb.batch_tasks_limit;
    tk_pick_by_zone := sb.pick_by_zone;
    tk_pick_by_productgroup := sb.pick_by_productgroup;
    tk_batch_pick_by_item_yn := sb.batch_pick_by_item_yn;
    st_item := sb.item;
    st_lpid := sb.lpid;
  else
    tk.pickqty := tk.pickqty + sb.pickqty;
    tk.qty := tk.qty + sb.qty;
    tk.weight := tk.weight + sb.weight;
    tk.cube := tk.cube + sb.cube;
    tk.staffhrs := tk.staffhrs + sb.staffhrs;
  end if;
  cntSubTasks := cntSubTasks + 1;
  if sb2.pickqty != 0 then
    if sb.shippingtype = 'F' then
      sb.shippingtype := 'P';
    end if;
    if in_orderid != 0 then
      open curShippingPlate(sb2.shippinglpid);
      fetch curShippingPlate into sp;
      close curShippingPlate;
      zsp.get_next_shippinglpid(sp.lpid,out_msg);
    else
      sp.lpid := null;
    end if;
    insert into subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup,labeluom)
      values
      (0, sb2.tasktype, sb2.facility, sb2.fromsection, sb2.fromloc,
       sb2.fromprofile,sb2.tosection,sb2.toloc,sb2.toprofile,sb2.touserid,
       sb2.custid,sb2.item,sb2.lpid,sb2.uom,sb2.qty,sb2.locseq,sb2.loadno,sb2.stopno,sb2.shipno,
       sb2.orderid,sb2.shipid,sb2.orderitem,sb2.orderlot,sb2.priority,
       sb2.prevpriority,sb2.curruserid,sb2.lastuser,sysdate,
       sb2.pickuom, sb2.pickqty, sb2.picktotype, sb2.wave,
       sb2.pickingzone, sb2.cartontype, sb2.weight, sb2.cube, sb2.staffhrs, null,
       sp.lpid, 'P', sb2.cartongroup, sb2.labeluom);
    cntSubTasks := cntSubTasks + 1;
    if in_orderid != 0 then
      insert into shippingplate
        (lpid, item, custid, facility, location, status, holdreason,
        unitofmeasure, quantity, type, fromlpid, serialnumber,
        lotnumber, parentlpid, useritem1, useritem2, useritem3,
        lastuser, lastupdate, invstatus, qtyentered, orderitem,
        uomentered, inventoryclass, loadno, stopno, shipno,
        orderid, shipid, weight, ucc128, labelformat, taskid, orderlot,
        pickuom, pickqty, cartonseq, manufacturedate, expirationdate)
        values
        (sp.lpid, sp.item, sp.custid, sp.facility, sp.location, sp.status, sp.holdreason,
        sp.unitofmeasure, sb2.qty, 'P', sp.fromlpid, sp.serialnumber,
        sp.lotnumber, sp.parentlpid, sp.useritem1, sp.useritem2, sp.useritem3,
        sp.lastuser, sp.lastupdate, sp.invstatus, sp.qtyentered, sp.orderitem,
        sp.uomentered, sp.inventoryclass, sp.loadno, sp.stopno, sp.shipno,
        sp.orderid, sp.shipid, sb2.weight, sp.ucc128, sp.labelformat, 0, sp.orderlot,
        sp.pickuom, sb2.pickqty, null, sp.manufacturedate, sp.expirationdate);
    end if;
  end if;
  update subtasks
     set taskid = tk.taskid,
         cartonseq = sb.cartonseq,
         pickqty = sb.pickqty,
         qty = sb.qty,
         weight = sb.weight,
         cube = sb.cube,
         staffhrs = sb.staffhrs,
         shippingtype = sb.shippingtype
   where rowid = sb.subtasksrowid;
  if in_orderid != 0 then
    update shippingplate
       set taskid = tk.taskid,
           type = sb.shippingtype,
           cartonseq = sb.cartonseq,
           pickqty = sb.pickqty,
           quantity = sb.qty,
           weight = sb.weight
     where lpid = sb.shippinglpid;
  end if;
  close curSubTasks;
end loop;

if in_trace = 'Y' then
     trace_msg('Cmplt_tsk: insert_task_row ' || to_char(tk.taskid) || ' tk.tasktype ' || tk.tasktype);
end if;
insert_task_row;

--zut.prt('check for dups');
for ds in curDupTaskSum loop
  sb2.taskid := null;
  for dd in curDupTaskDtl(ds.taskid,ds.fromloc,ds.lpid,ds.item,ds.orderitem,
               ds.orderlot,ds.pickuom,ds.picktotype,ds.cartontype,ds.cartonseq,ds.lotnumber)
  loop
    if sb2.taskid is null then
      sb2 := dd;
    else
      sb2.qty := sb2.qty + dd.qty;
      sb2.pickqty := sb2.pickqty + dd.pickqty;
      sb2.weight := sb2.weight + dd.weight;
      sb2.cube := sb2.cube + dd.cube;
      sb2.staffhrs := sb2.staffhrs + dd.staffhrs;
      delete from subtasks
       where rowid = dd.subtasksrowid;
      if in_orderid != 0 then
        delete from shippingplate
         where lpid = dd.shippinglpid;
      end if;
    end if;
  end loop;
  if sb2.taskid is not null then
    update subtasks
       set qty = sb2.qty,
           pickqty = sb2.pickqty,
           weight = sb2.weight,
           cube = sb2.cube,
           staffhrs = sb2.staffhrs
     where rowid = sb2.subtasksrowid;
    if in_orderid != 0 then
      update shippingplate
         set pickqty = sb2.pickqty,
             quantity = sb2.qty,
             weight = sb2.weight
       where lpid = sb2.shippinglpid;
    end if;
  end if;
end loop;

-- downsize carton if leftover space allows
--zut.prt('downsize');
open curCartonChksum;
while (1=1)
loop
  fetch curCartonChkSum into cc;
  if curCartonChkSum%notfound then
    close curCartonChkSum;
    exit;
  end if;
--zut.prt(cc.cartongroup || ' ' || cc.weight || ' ' || cc.cube ||
--  ' ' || cc.picktotype || ' ' || cc.cartontype || ' ' ||
--  cc.cartonseq);
  open curCartonMin(cc.cartongroup, cc.weight, cc.cube);
  cm.cartontype := '';
  fetch curCartonMin into cm;
  if (curCartonMin%notfound) or
     (cc.cartontype = cm.cartontype) then
    close curCartonMin;
    goto continue_cartonchk_loop;
  end if;
  close curCartonMin;
--zut.prt('close cartonchksum');
  close curCartonChkSum;
  newcartonseq := 1;
  open curNextSeq(cc.taskid,cc.picktotype,cm.cartontype);
  fetch curNextSeq into newcartonseq;
  close curNextSeq;
--zut.prt('downsized ' || cc.cartongroup || ' ' ||
--  cc.picktotype || ' ' ||
--  cc.cartontype || ' ' || cm.cartontype || ' ' || cc.cartonseq ||
--    ' ' || newcartonseq);
  update subtasks
     set cartontype = cm.cartontype,
         cartonseq = newcartonseq
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and taskid = cc.taskid
     and cartongroup = cc.cartongroup
     and picktotype = cc.picktotype
     and cartontype = cc.cartontype
     and cartonseq = cc.cartonseq;
  update subtasks
     set cartonseq = cartonseq -1
   where wave = in_wave
     and facility is null
     and orderid = in_orderid
     and shipid = in_shipid
     and taskid = cc.taskid
     and cartongroup = cc.cartongroup
     and picktotype = cc.picktotype
     and cartontype = cc.cartontype
     and cartonseq > cc.cartonseq;
  open curCartonChkSum;
<<continue_cartonchk_loop>>
  null;
end loop;

if in_orderid = 0 then
  zbp.allocate_picks_to_orders(in_wave,in_facility,in_orderid,in_shipid,
    in_taskpriority,in_picktype,in_userid,in_consolidated,in_trace,
    out_errorno,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    zms.log_msg('WaveRelease', in_facility, null,
        out_msg, 'W', in_userid, strMsg);
  end if;
end if;

begin
  select nvl(b.allowpickpassing, 'N') into v_allowpickpassing
  from orderhdr a, customer b
  where a.orderid = in_orderid and a.shipid = in_shipid
    and a.custid = b.custid;
exception
  when others then
    v_allowpickpassing := 'N';
end;

if (v_allowpickpassing = 'F') then
  for rec in (select taskid
              from tasks
              where orderid = in_orderid
                and shipid = in_shipid
                and facility is null
                and tasktype in ('OP'))
  loop
    
    begin
      select * into v_subtask
      from subtasks
      where taskid = rec.taskid
        and locseq = (select min(locseq) from subtasks where taskid = rec.taskid)
        and rownum = 1;
      
      update tasks
      set fromsection = v_subtask.fromsection,
          fromprofile = v_subtask.fromprofile,
          fromloc = v_subtask.fromloc,
          locseq = v_subtask.locseq
      where taskid = rec.taskid;
      
    exception
      when others then 
        null;
    end;
  end loop;
end if;

if (in_curruserid is not null) and (in_wave is null) then   -- material issue
  update subtasks
     set facility = in_facility
   where taskid in
         (select taskid from tasks
            where curruserid = in_curruserid
              and orderid = in_orderid
              and shipid = in_shipid
              and facility is null);

  update tasks
     set facility = in_facility
   where curruserid = in_curruserid
     and orderid = in_orderid
     and shipid = in_shipid
     and facility is null;
else
  if in_orderid = 0 then
    update batchtasks
       set facility = in_facility
     where wave = in_wave
       and facility is null;
  end if;

  update subtasks
     set facility = in_facility
   where wave = in_wave
     and orderid = in_orderid
     and shipid = in_shipid
     and facility is null;

  update tasks
     set facility = in_facility
   where wave = in_wave
     and orderid = in_orderid
     and shipid = in_shipid
     and facility is null;
end if;

update subtasks st
   set picktotype = 'FULL'
 where st.wave = in_wave
   and nvl(picktotype,'xxx') != 'FULL'
   and exists(select 1
                from custitemview ci 
               where ci.custid = st.custid
                 and ci.item = st.item
                 and ci.rcpt_qty_is_full_qty = 'Y')
   and st.qty = (select lp.quantity
                   from plate lp
                  where lp.lpid = st.lpid)
   and st.qty = (select nvl(lp.qtyrcvd,0)
                   from plate lp
                  where lp.lpid = st.lpid);

update subtasks st
   set picktotype = 'TOTE'
 where st.wave = in_wave
   and st.tasktype = 'BP'
   and nvl(picktotype,'xxx') != 'TOTE'
   and exists(select 1
                from waves wv
               where wv.wave = in_wave
                 and nvl(wv.sdi_sortation_yn,'N') = 'Y')
   and exists(select 1
                from custitemview ci 
               where ci.custid = st.custid
                 and ci.item = st.item
                 and ci.rcpt_qty_is_full_qty = 'Y')
   and (st.qty <> (select lp.quantity
                     from plate lp
                    where lp.lpid = st.lpid)
    or  st.qty <> (select nvl(lp.qtyrcvd,0)
                     from plate lp
                    where lp.lpid = st.lpid));

out_msg := 'OKAY';

exception when others then
  out_msg := 'wvcpt ' || sqlerrm;
  out_errorno := sqlcode;
end complete_pick_tasks;

PROCEDURE submit_wave_request
(in_wave IN number
,in_trace IN varchar2
,in_userid IN varchar2
) is

cursor curWave is
  select facility,
         picktype,
         nvl(taskpriority,'9') as taskpriority,
         wavestatus,
         job,
         nvl(mass_manifest,'N') as mass_manifest
    from waves
   where wave = in_wave;
wv curWave%rowtype;

out_errorno integer;
out_msg varchar2(255);
nonaicnt integer := 0;
reqtype varchar2(10);

begin

open curWave;
fetch curWave into wv;
if curWave%notfound then
  close curWave;
  return;
end if;
close curWave;

select count(1) into nonaicnt
	from orderhdr OH, customer CU
	where OH.wave = in_wave
     and OH.orderstatus != 'X'
     and CU.custid = OH.custid
     and nvl(CU.paperbased, 'N') != 'Y';

if nonaicnt = 0 then
	reqtype := 'AIWREL';
elsif wv.mass_manifest = 'Y' then
   reqtype := 'MASSMAN';
else
	reqtype := 'RELWAV';
end if;

zgp.pick_request(reqtype,wv.facility,in_userid,in_wave,
  null,null,null,null,null,wv.taskpriority,wv.picktype,in_trace,
  out_errorno,out_msg);

end submit_wave_request;

PROCEDURE submit_order_request
(in_orderid IN number
,in_shipid IN number
,in_trace IN varchar2
,in_userid IN varchar2
) is

cursor curOrderHdr is
  select fromfacility,
         nvl(wave,0) wave,
         nvl(shipshort,'N') shipshort,
         orderstatus
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curWave(in_wave IN number) is
  select picktype,
         nvl(taskpriority,'9') as taskpriority,
         wavestatus,
         job,
         nvl(mass_manifest,'N') as mass_manifest
    from waves
   where wave = in_wave;
wv curWave%rowtype;

out_errorno integer;
out_msg varchar2(255);
nonaicnt integer := 0;
reqtype varchar2(10);

begin

open curOrderHdr;
fetch curOrderHdr into oh;
if curOrderHdr%notfound then
  close curOrderHdr;
  return;
end if;
close curOrderHdr;

if(oh.shipshort <> 'W' or oh.orderstatus > '3') then
  return;
end if;

update orderhdr
   set shipshort = 'Y',
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

open curWave(oh.wave);
fetch curWave into wv;
close curWave;

reqtype := 'RELORD';

zgp.pick_request(reqtype,oh.fromfacility,in_userid,oh.wave,
  in_orderid,in_shipid,null,null,null,wv.taskpriority,wv.picktype,in_trace,
  out_errorno,out_msg);

end submit_order_request;

PROCEDURE submit_autowave_request
(in_wave IN number
,in_trace IN varchar2
,in_userid IN varchar2
) is

cursor curWave is
  select facility,
         picktype,
         nvl(taskpriority,'9') as taskpriority,
         wavestatus,
         job,
         nvl(mass_manifest,'N') as mass_manifest
    from waves
   where wave = in_wave;
wv curWave%rowtype;

out_errorno integer;
out_msg varchar2(255);
nonaicnt integer := 0;
reqtype varchar2(10);
l_termid varchar2(4);

begin

open curWave;
fetch curWave into wv;
if curWave%notfound then
  close curWave;
  return;
end if;
close curWave;

select count(1) into nonaicnt
	from orderhdr OH, customer CU
	where OH.wave = in_wave
     and OH.orderstatus != 'X'
     and CU.custid = OH.custid
     and nvl(CU.paperbased, 'N') != 'Y';

if nonaicnt = 0 then
	reqtype := 'AIWREL';
elsif wv.mass_manifest = 'Y' then
   reqtype := 'MASSMAN';
else
	reqtype := 'RELWAV';
end if;

-- Verify mass manifest waves
if reqtype = 'MASSMAN' then
  out_msg := test_wave_mass_manifest(in_wave);
  if out_msg != 'OKAY' then
      zms.log_msg('WaveRelease', wv.facility, '',
        'Wave ' || in_wave || '-invalid for MassManifest: ' || out_msg,
        'E', in_userid, out_msg);
      return;
  end if;

-- Locate first multiship terminal for the facility
  l_termid := null;

  select min(termid)
    into l_termid
    from multishipterminal
   where facility = wv.facility;

  /*
  if l_termid is null then
     zms.log_msg('WaveRelease', wv.facility, '',
       'Wave ' || in_wave || '-invalid for MassManifest: No multiship terminal found for facility',
       'E', in_userid, out_msg);
     return;
  end if;
  */
end if;

zgp.pick_request(reqtype,wv.facility,in_userid,in_wave,
  null,null,null,null,null,wv.taskpriority,wv.picktype,in_trace,
  out_errorno,out_msg);

if reqtype = 'MASSMAN' then
-- Do the mass manifest release processing
  mass_man_lbls.mass_man_nolabels(in_wave);

  -- send_mass_man_triggers(in_wave, l_termid, in_userid);
end if;

end submit_autowave_request;

PROCEDURE send_mass_man_triggers
(in_wave IN number
,in_termid IN varchar2
,in_userid IN varchar2
)
IS
out_msg varchar2(255);
BEGIN
-- removed per changes 8/14/2008
return;

-- Export the information to Malvern system

for crec in (select M.ctnid, O.custid, O.fromfacility
               from orderhdr O, mass_manifest_ctn M
              where M.wave = in_wave
                and M.orderid = O.orderid
                and M.shipid = O.shipid
                order by M.ctnid)
loop
    zmn.send_staged_carton_trigger(crec.fromfacility, crec.custid,
        in_termid, crec.ctnid, in_userid, out_msg);
end loop;

END;


function cancelled_qty
(in_wave number
) return number
is

cursor curOrderHdr is
  select orderid,shipid,custid
    from orderhdr
   where wave = in_wave
     and orderstatus != 'X';

cursor curOrderDtl(in_orderid number, in_shipid number) is
  select qtyorder
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus = 'X';

cursor curCustomer(in_custid varchar2) is
  select decode(nvl(reduceorderqtybycancel,'D'),'D',nvl(zci.default_value('REDUCEORDERQTYBYCANCEL'),'N'),'Y','Y','N') reduceorderqtybycancel
    from customer cu, customer_aux ca
   where cu.custid = in_custid
     and ca.custid = cu.custid;
cu curCustomer%rowtype;

qtyCancelled number;

begin

qtyCancelled := 0;

for oh in curOrderHdr
loop
  cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  if cu.reduceorderqtybycancel <> 'Y' then
    for od in curOrderDtl(oh.orderid,oh.shipid)
    loop
      qtyCancelled := qtyCancelled + od.qtyorder;
    end loop;
  end if;
end loop;

return qtyCancelled;

exception when others then
  return 0;
end cancelled_qty;


function kitted_qty
(in_wave number
) return number
is

cursor curOrderHdr is
  select orderid,shipid
    from orderhdr
   where wave = in_wave
     and orderstatus != 'X';

cursor curOrderDtl(in_orderid number, in_shipid number) is
  select nvl(qtyorder,0) - nvl(qtypick,0) as qty
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and linestatus != 'X'
     and exists
         (select 1
            from custitem
           where custid = orderdtl.custid
             and item = orderdtl.item
             and nvl(iskit,'N') != 'N');

qtyKitted number;

begin

qtyKitted := 0;

for oh in curOrderHdr
loop
  for od in curOrderDtl(oh.orderid,oh.shipid)
  loop
    qtyKitted := qtyKitted + od.qty;
  end loop;
end loop;

return qtyKitted;

exception when others then
  return 0;
end kitted_qty;


function test_wave_aggregateness
	(in_wave in number)
return varchar2
is
	cursor c_wv is
  		select nvl(picktype, 'none') picktype
    		from waves
   		where wave = in_wave;
	wv c_wv%rowtype;
	ordcnt integer := 0;
begin
	open c_wv;
	fetch c_wv into wv;
	if c_wv%notfound then
  		close c_wv;
  		return 'Invalid wave identifier ' || in_wave;
	end if;
	close c_wv;

	select count(1) into ordcnt
      from orderhdr OH, customer CU
     where OH.wave = in_wave
       and OH.orderstatus != 'X'
       and CU.custid = OH.custid
       and nvl(CU.paperbased, 'N') = 'Y';

	if ordcnt = 0 then
   	return 'OKAY';			-- no AI customers
   end if;

	select count(1) into ordcnt
      from orderhdr OH, customer CU
     where OH.wave = in_wave
       and OH.orderstatus != 'X'
       and CU.custid = OH.custid
       and nvl(CU.paperbased, 'N') != 'Y';

	if ordcnt != 0 then
   	return 'Wave ' || in_wave || ' contains orders for both Aggregate and Non Aggregate Inventory customers.';
	end if;

	if wv.picktype != 'ORDR' then
   	return 'Wave ' || in_wave || ' is for Aggregate Inventory customers but does not specify Order Picking.';
	end if;

	return 'OKAYAI';		-- no errors, but wave is for AI customer

exception when others then
	return 'wvtwa ' || sqlerrm;
end test_wave_aggregateness;

function test_wave_consolidate
	(in_wave in number)
return varchar2
is
	cursor c_wv is
  		select nvl(cross_customer_yn, 'N') cross_customer_yn
    		from waves
   		where wave = in_wave;
	wv c_wv%rowtype;

	custcnt integer := 0;
	conscnt integer := 0;
	zipccnt integer := 0;
	loadcnt integer := 0;
	stopcnt integer := 0;
	shipcnt integer := 0;
   weightcnt integer := 0;
	ordcnt integer := 0;
begin

	select count(distinct custid), count(distinct shipto),
           count(distinct shiptopostalcode), count(distinct nvl(loadno,0)),
           count(distinct nvl(stopno,0)), count(distinct nvl(shipno,0))
      into custcnt, conscnt, zipccnt, loadcnt, stopcnt, shipcnt
      from orderhdr OH
     where OH.wave = in_wave
       and OH.orderstatus != 'X';

	if custcnt != 1 then
	      wv := null;
	      open c_wv;
	      fetch c_wv into wv;
	      close c_wv;
	      
	      if (wv.cross_customer_yn != 'Y') then
      	return 'Wave ' || in_wave
            || ' contains orders for multiple customers.';
    end if;
    end if;

	 if loadcnt > 1 then
      	return 'Wave ' || in_wave
            || ' contains orders for multiple loads.';
    end if;

	 if stopcnt > 1 then
      	return 'Wave ' || in_wave
            || ' contains orders for multiple stops within a load.';
    end if;

	 if shipcnt > 1 then
      	return 'Wave ' || in_wave
            || ' contains orders for multiple shipments within a load/stop.';
    end if;

    select count(1) into weightcnt
      from orderhdr H, orderdtl D
      where H.wave = in_wave
        and D.orderid = H.orderid
        and D.shipid = H.shipid
        and (nvl(D.weight_entered_lbs,0) != 0 or nvl(D.weight_entered_kgs,0) != 0);
    if weightcnt > 1 then
        return 'Wave ' || in_wave || ' contains ordered by weight line items.';
    end if;

    select count(1) into ordcnt
       from orderhdr OH, customer CU
      where OH.wave = in_wave
        and OH.orderstatus != 'X'
        and CU.custid = OH.custid
        and nvl(CU.paperbased, 'N') = 'Y';

	 if ordcnt != 0 then
        return 'Wave ' || in_wave || ' contains orders for Aggregate Inventory customers.';
    end if;

--  Place all caution messages here
    if conscnt > 0 and zipccnt > 0 then
        return 'Caution: Wave ' || in_wave
            || ' contains mix of shipto''s and onetime shipto''s.';
    end if;

    if conscnt > 1 then
        return('Caution: Wave '|| in_wave
            || ' contains multiple shipto''s.');
    end if;

    if zipccnt > 1 then
        return('Caution: Wave '|| in_wave
            || ' contains multiple shipto zipcodes.');
    end if;

    return 'OKAY';

exception when others then
	return 'wvtwc ' || sqlerrm;
end test_wave_consolidate;


function test_wave_mass_manifest
	(in_wave in number)
return varchar2
is
   l_factor number := 0;
   l_err varchar2(1);
   l_msg varchar2(80);
   l_carrier orderhdr.carrier%type := null;
   strOutMsg appmsgs.msgtext%type;
   function cpt_label
      (in_custid  in varchar2,
       in_field   in varchar2,
       in_default in varchar2)
   return varchar2
   is
      l_label custdict.labelvalue%type;
   begin
      select labelvalue
         into l_label
         from custdict
         where custid = in_custid
           and fieldname = in_field;
      return l_label;
   exception when others then
      return in_default;
   end cpt_label;
begin
   for oh in (select orderid, shipid, shiptype, carrier
               from orderhdr where wave = in_wave) loop

      if oh.shiptype != 'S' then
         return 'Order ' || oh.orderid ||'-' || oh.shipid || ' is not small package.';
      end if;

      if oh.carrier is null then
         return 'Order ' || oh.orderid ||'-' || oh.shipid || ' has no carrier.';
      end if;

      if l_carrier is null then
         l_carrier := oh.carrier;
      elsif oh.carrier != l_carrier then
         return 'Order ' || oh.orderid ||'-' || oh.shipid || ' not for carrier ' || l_carrier ||'.';
      end if;

      for od in (select O.qtyorder, O.custid, O.item, O.uom, C.labeluom, C.lotrequired,
                        C.serialrequired, C.user1required, C.user2required, C.user3required
                  from orderdtl O, custitemview C
                  where O.orderid = oh.orderid
                    and O.shipid = oh.shipid
                    and C.custid = O.custid
                    and C.item = O.item) loop

         if od.labeluom is null then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' does not have a label uom defined.';
         end if;

         if od.lotrequired = 'P' then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' requires ' || cpt_label(od.custid, 'LOTNUMBER', 'Lot')
                  || ' capture upon pick.';
         end if;

         if od.serialrequired = 'P' then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' requires ' || cpt_label(od.custid, 'SERIALNUMBER', 'Serial #')
                  || ' capture upon pick.';
         end if;

         if od.user1required = 'P' then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' requires ' || cpt_label(od.custid, 'USERITEM1', 'User Item 1')
                  || ' capture upon pick.';
         end if;

         if od.user2required = 'P' then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' requires ' || cpt_label(od.custid, 'USERITEM2', 'User Item 2')
                  || ' capture upon pick.';
         end if;

         if od.user3required = 'P' then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' requires ' || cpt_label(od.custid, 'USERITEM3', 'User Item 3')
                  || ' capture upon pick.';
         end if;

         zrf.get_baseuom_factor(od.custid, od.item, od.uom, od.labeluom, l_factor, l_err, l_msg);

         if l_msg is not null then
            if l_err = 'N' then
               return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                     || ' does not have a uom relationship between ' || od.uom
                     || ' and ' || od.labeluom || '.';
            end if;

            return 'Error: ' || l_msg || ' converting item ' || od.item || ' for order '
                  || oh.orderid ||'-' || oh.shipid || ' between uom ' || od.uom
                  || ' and ' || od.labeluom || '.';
         end if;

         if mod(od.qtyorder, l_factor) != 0 then
            return 'Item ' || od.item || ' for order ' || oh.orderid ||'-' || oh.shipid
                  || ' contains a partial ' || od.labeluom || '.';
         end if;
      end loop;
   end loop;

   zms.log_msg('WaveRelease', null, null,
               'Wave ' || in_wave || ' mass manifest OKAY',
               'T', 'WaveRelease', strOutMsg);

  	return 'OKAY';

exception when others then
	return 'wvtwmm ' || sqlerrm;
end test_wave_mass_manifest;

function test_wave_batchability
	(in_wave in number)
return varchar2
is
  cntRows integer := 0;
begin

  select count(1) into cntRows
    from orderhdr H, orderdtl D
    where H.wave = in_wave
      and D.orderid = H.orderid
      and D.shipid = H.shipid
      and (nvl(D.weight_entered_lbs,0) != 0 or nvl(D.weight_entered_kgs,0) != 0)
      and D.linestatus != 'X';
  if cntRows > 1 then
      	return 'Wave ' || in_wave
            || ' contains ordered by weight line items.';
  end if;

  select count(1) into cntRows
    from orderhdr H, orderdtl D
    where H.wave = in_wave
      and D.orderid = H.orderid
      and D.shipid = H.shipid
      and (nvl(D.weight_entered_lbs,0) != 0 or nvl(D.weight_entered_kgs,0) != 0)
      and D.linestatus != 'X';
  if cntRows > 1 then
      	return 'Wave ' || in_wave
            || ' contains items with inexact quantity types.';
  end if;

  return 'OKAY';

exception when others then
	return 'wvtba ' || sqlerrm;
end test_wave_batchability;

function test_wave_ppzone_validity
(in_wave in number)
return varchar2
is
    cursor c_wv is
      select facility, nvl(parallel_pick_zones,'(none)') parallel_pick_zones, nvl(picktype,'ORDR') picktype
        from waves
       where wave = in_wave;
    wv c_wv%rowtype;
    cntRows integer := 0;
begin

    open c_wv;
    fetch c_wv into wv;
    if c_wv%notfound then
       close c_wv;
       return 'Invalid wave identifier ' || in_wave;
    end if;
    close c_wv;

    if wv.parallel_pick_zones = '(none)' then
       return 'Parallel Pick Zones not set for wave ' || in_wave; 
    end if;

    if wv.picktype <> 'ORDR' then
       return 'Parallel Pick Zones incompatible with Pick Type ' || wv.picktype;
    end if;

    select count(1) into cntRows
      from (select trim(regexp_substr(wv.parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
        connect by trim(regexp_substr(wv.parallel_pick_zones, '[^,]+', 1, level)) is not null) uz
      where not exists(
     select 1
       from zone zo
      where zo.facility = wv.facility
        and zo.zoneid = uz.zoneid);

    if cntRows > 0 then
       return wv.parallel_pick_zones || ' contains invalid picking zones for facility ' ||
              wv.facility || '.';
    end if;

    select count(1) into cntRows
      from (select trim(regexp_substr(wv.parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
        connect by trim(regexp_substr(wv.parallel_pick_zones, '[^,]+', 1, level)) is not null) uz
     where not exists(
     select 1
       from zone zo, location lo
      where zo.facility = wv.facility
        and zo.zoneid = uz.zoneid
        and lo.facility = zo.facility
        and lo.pickingzone = zo.zoneid);

    if cntRows > 0 then
       return wv.parallel_pick_zones || ' contains picking zones with no locations for facility ' ||
              wv.facility || '.';
    end if;

    select count(1) into cntRows
      from (select trim(regexp_substr(wv.parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
         connect by trim(regexp_substr(wv.parallel_pick_zones, '[^,]+', 1, level)) is not null) uz
    where not exists(
      select 1
        from zone zo, location lo, itempickfronts ipf
       where zo.facility = wv.facility
         and zo.zoneid = uz.zoneid
         and lo.facility = zo.facility
         and lo.pickingzone = zo.zoneid
         and ipf.facility = lo.facility
         and ipf.pickfront = lo.locid);

    if cntRows > 0 then
       return wv.parallel_pick_zones || ' contains picking zones with no pick fronts for facility ' ||
              wv.facility || '.';
    end if;

    select count(1) into cntRows
      from (select trim(regexp_substr(wv.parallel_pick_zones,'[^,]+', 1, level)) as zoneid from dual
         connect by trim(regexp_substr(wv.parallel_pick_zones, '[^,]+', 1, level)) is not null) uz,
         (select distinct custid, item
            from orderdtl
           where (orderid,shipid) in(
             select orderid,shipid
               from orderhdr
              where wave = in_wave)
                and linestatus <> 'X') it
    where not exists(
      select 1
        from location lo, itempickfronts ipf
       where lo.facility = wv.facility
         and lo.pickingzone = uz.zoneid
         and ipf.custid = it.custid
         and ipf.item = it.item
         and ipf.facility = lo.facility
         and ipf.pickfront = lo.locid);

    if cntRows > 0 then
       return 'Wave ' || in_wave
           || ' contains items without pick fronts in specified parallel picking zones.';
    end if;

  return 'OKAY';

exception when others then
   return 'wvtba ' || sqlerrm;
end test_wave_ppzone_validity;

procedure wave_pre_validate
(in_included_rowids IN clob
,in_userid IN varchar2
,in_picktype IN varchar2
,in_release_for_tms IN varchar2
,in_sdi_max_units IN number
,out_tms_format IN OUT varchar2
,out_tms_status IN OUT varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)

is

type cur_type is ref cursor;
l_cur cur_type;
l_sql varchar2(4000);
l_custid customer.custid%type;
l_paperbased customer.paperbased%type;
l_tms_format customer.tms_orders_to_plan_format%type := null;
l_tms_format_save customer.tms_orders_to_plan_format%type := null;
l_tms_status orderhdr.tms_status%type := null;
l_tms_status_save orderhdr.tms_status%type := null;
l_xdockorderid orderhdr.xdockorderid%type;
l_ai_count pls_integer := 0;
l_non_ai_count pls_integer := 0;
l_mark varchar2(255);
l_loop_count pls_integer;
l_rowid_length pls_integer := 18;
i pls_integer;
l_log_msg appmsgs.msgtext%type;
l_qtyorder orderhdr.qtyorder%type;
l_tot_qtyorder orderhdr.qtyorder%type := 0;

begin

l_loop_count := length(in_included_rowids) - length(replace(in_included_rowids, ',', ''));

i := 1;
while (i <= l_loop_count)
loop 

  l_sql := 'select oh.custid, nvl(cu.paperbased,''N''), cu.tms_orders_to_plan_format,' ||
           'oh.tms_status, oh.xdockorderid, nvl(oh.qtyorder,0) ' ||
           'from customer cu, orderhdr oh ' ||
           'where oh.custid = cu.custid(+) and oh.rowid in (';

  while length(l_sql) < 3950 -- 4000 character limit for open cursor command
  loop
    l_sql := l_sql || '''' || substr(in_included_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_sql) < 3950) then
      l_sql := l_sql || ',';
    else
      exit;
    end if;
  end loop;
  
  l_sql := l_sql || ') order by orderid, shipid';
  
  open l_cur for l_sql;
  loop
    fetch l_cur into l_custid, l_paperbased, l_tms_format, l_tms_status, l_xdockorderid, l_qtyorder;
    exit when l_cur%notfound;
    if nvl(l_xdockorderid,0) != 0 then
      out_errorno := -100;
      out_msg := 'Wave may not contain outbound Transload orders.';
      return;
    end if;
    
    if l_paperbased = 'Y' then
      l_ai_count := l_ai_count + 1;
    else
      l_non_ai_count := l_non_ai_count + 1;
    end if;    

    if l_tms_format_save is null then
      l_tms_format_save :=  l_tms_format;
      l_tms_status_save := l_tms_status;
    end if;
    
    if (nvl(l_tms_format_save,'x') != nvl(l_tms_format,'x') ) and
       (in_release_for_tms = 'Y') then
      out_errorno := -300;
      out_msg  := 'TMS formats mismatch. Customer ' || l_custid || ' Format: ' ||
                  l_tms_format || chr(13) ||
                  'does not match ' || l_tms_format_save;
      return;
    end if;
      
    l_tot_qtyorder := l_tot_qtyorder + l_qtyorder;

  end loop;

  close l_cur;

end loop;

l_mark := 'end loop';

if (l_ai_count != 0) and (l_non_ai_count != 0) then
  out_errorno := -200;
  out_msg := 'Orders for both Aggregate Inventory customers and' || chr(13) ||
             'Non Aggregate Inventory customer may not be' || chr(13) ||
             'combined on the save wave.';
  return;
end if;

l_mark := 'picktype check';

if (l_ai_count != 0) and (in_picktype != 'ORDR') then
  out_errorno := -201;
  out_msg := 'Order Picking must be selected for' || chr(13) ||
             'Aggregate Inventory customers.';
  return;
end if;

if (nvl(in_sdi_max_units,0) > 0) and
   (l_ai_count + l_non_ai_count > 1) and
   (l_tot_qtyorder > nvl(in_sdi_max_units,0)) then
  out_errorno := -400;
  out_msg := 'Total quantity ordered (' || l_tot_qtyorder ||
             ') greater than Max Units (' || in_sdi_max_units || ').';
  return;
end if;

out_tms_format := l_tms_format_save;
out_tms_status := l_tms_status_save;
out_errorno := 0;
out_msg := 'OKAY' || l_loop_count;

exception when others then
  out_errorno := sqlcode;
  out_msg := 'wpv ' || sqlerrm || '/' || l_mark;
end wave_pre_validate;

procedure wave_commit
(in_wave IN number
,in_included_rowids IN clob
,in_reqtype IN varchar2
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
,out_error_count IN OUT number
)
is

type cur_type is ref cursor;
l_cur cur_type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_custid orderhdr.custid%type;
l_sql varchar2(4000);
l_errorno pls_integer;
l_msg varchar2(255);
l_userid userheader.nameid%type;
l_wave waves.wave%type;
i pls_integer;
l_loop_count pls_integer;
l_rowid_length pls_integer := 18;
l_log_msg appmsgs.msgtext%type;

begin

l_userid := in_userid;
l_wave := in_wave;
out_error_count := 0;

out_msg := 'OKAY';
         
l_loop_count := length(in_included_rowids) - length(replace(in_included_rowids, ',', ''));

i := 1;
while (i <= l_loop_count)
loop 

  l_sql := 'select orderid, shipid, custid ' ||
           'from orderhdr ' ||
           'where rowid in (';

  while length(l_sql) < 3975 -- 4000 character limit for open cursor command
  loop
    l_sql := l_sql || '''' || substr(in_included_rowids,((i-1)*l_rowid_length)+i+1,l_rowid_length) || '''';
    i := i + 1;
    if (i <= l_loop_count) and (length(l_sql) < 3975) then
      l_sql := l_sql || ',';
    else
      exit;
    end if;
  end loop;
  
  l_sql := l_sql || ')';
  
  open l_cur for l_sql;
  loop
  
    fetch l_cur into l_orderid, l_shipid, l_custid;
    exit when l_cur%notfound;

    zcm.commit_order(l_orderid, l_shipid, in_facility, l_userid, in_reqtype,
                     l_wave, l_errorno, l_msg);
    if substr(l_msg, 1,4) != 'OKAY' then
      rollback;
      zms.log_autonomous_msg('WAVECOMMIT',in_facility,l_custid,
                         l_msg,'E',in_userid,l_log_msg);
      out_error_count := out_error_count + 1;
    else
      commit;
    end if;  
    if l_msg = 'OKAYMULTI' then
      out_msg := 'OKAYMULTI';
    end if;
      
  end loop;

  close l_cur;

end loop;

out_errorno := 0;

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end wave_commit;

procedure request_pack_lists
(in_wave number
,in_printer varchar2
,in_userid varchar2
,out_msg IN OUT varchar2
)
is

l_order_count pls_integer;
l_errmsg varchar(255);
l_packlistrptfile customer.packlistrptfile%type;
l_packlist customer.packlist%type;

begin

out_msg := 'OKAY';
l_order_count := 0;

for oh in(select orderid, shipid, custid
           from orderhdr
          where wave = in_wave
            and orderstatus >= '4'
            and orderstatus != 'X')
loop

  zcu.pack_list_format(oh.orderid,oh.shipid,l_packlist,l_packlistrptfile);

  if l_packlistrptfile is not null then
    zmnq.send_shipping_msg(oh.orderid,
                          oh.shipid,
                          in_printer,
                          l_packlistrptfile,
                          null,
			  null,
                          l_errmsg);
    l_order_count := l_order_count + 1;
  end if;

end loop;

out_msg := 'OKAY--Pack List Request Count: ' || l_order_count;

exception when others then
  out_msg := 'wvtba ' || sqlerrm;
end request_pack_lists;

end zwave;
/
show error package body zwave;
exit;
