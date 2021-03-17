create or replace package body alps.replenishment as
--
-- $Id$
--

procedure process_replenish_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cursor curItem is
  select V.iskit, nvl(C.paperbased,'N') as paperbased,
         pick_front_by_invclass
    from custitemview V, customer C
   where V.custid = in_custid
     and V.item = in_item
     and C.custid = V.custid;
it curItem%rowtype;
l_loc_inventoryclass itempickfronts.inventoryclass%type;

procedure log_msg(in_msg varchar2, in_msgtype varchar2) is
strMsg varchar2(255);
begin
  zms.log_msg('REPLENISH', in_facility, in_custid,
    in_item || '/' || in_locid || ' ' || in_msg,
    in_msgtype, in_userid, strMsg);
exception when others then
  null;
end;

begin

out_msg := '';
out_errorno := 0;

open curItem;
fetch curItem into it;
if curItem%notfound then
  close curItem;
  out_msg := 'Customer Item not found';
  out_errorno := 1;
  return;
end if;
close curItem;

if it.paperbased = 'Y' then
  out_msg := 'Aggregate inventory is not replenishable';
  out_errorno := 3;
  return;
end if;

if it.pick_front_by_invclass = 'Y' then
  begin
    select inventoryclass
      into l_loc_inventoryclass
      from itempickfronts
     where custid = in_custid
       and item = in_item
       and facility = in_facility
       and pickfront = in_locid;
  exception when others then
    l_loc_inventoryclass := null;
  end;
  if l_loc_inventoryclass is null then
    out_msg := 'This pick front requires an inventory class: ' || 
      in_facility || ' ' || in_locid;
    log_msg(out_msg, 'E');
    out_errorno := 4;
  end if;
end if;

if it.iskit in ('N', 'K') then
  process_loc_replenishment(in_reqtype, in_facility, in_custid,
    in_item, in_locid, in_userid, in_trace, out_errorno, out_msg);
  if it.iskit = 'K' then -- made to 'S'tock
    process_kit_replenishment(in_reqtype, in_facility, in_custid,
      in_item, in_locid, in_userid, in_trace, out_errorno, out_msg);
  end if;
  return;
end if;

out_msg := 'Item is not replenishable';
out_errorno := 2;

exception when others then
   out_msg := 'zrpprr ' || substr(sqlerrm, 1, 80);
   out_errorno := sqlcode;
end process_replenish_request;

procedure process_loc_replenishment
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cursor curItem is
  select baseuom,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass,
         pick_front_by_invclass
    from custitemview
   where custid = in_custid
     and item = in_item;
it curItem%rowtype;

cursor curLocBalance is
  select nvl(sum(quantity),0) as qty
    from plate
   where custid = in_custid
     and item = in_item
     and facility = in_facility
     and location = in_locid
     and type = 'PA'
     and status = 'A';
lb curLocBalance%rowtype;

cursor curTaskBalance is
  select nvl(sum(qty),0) as qty
    from subtasks
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and toloc = in_locid;
tb curTaskBalance%rowtype;

cursor curItemPickFront is
  select replenishqty,
         replenishuom,
         replenishwithuom,
         topoffqty,
         topoffuom,
         maxqty,
         maxuom,
         pickuom,
         nvl(dynamic,'N') dynamic,
         'N' flexpick,
         'C' allocrule,
		 inventoryclass
    from itempickfronts
   where facility = in_facility
     and item = in_item
     and custid = in_custid
     and pickfront = in_locid
  union
  select nvl(wv.fpf_minqty,0) replenishqty,
         wv.fpf_minuom replenishuom,
         null replenishwithuom,
         0 topoffqty,
         null topoffuom,
         nvl(wv.fpf_maxqty,0) maxqty,
         wv.fpf_maxuom maxuom,
         null pickuom,
         'N' dynamic,
         'Y' flexpick,
         nvl(fpf_allocrule,'C') allocrule,
	     null
    from location lo, waves wv
   where lo.facility = in_facility
     and lo.locid = in_locid
     and lo.flex_pick_front_item = in_item
     and wv.wave = lo.flex_pick_front_wave
     and nvl(wv.use_flex_pick_fronts_yn,'N') = 'Y';
pf curItemPickFront%rowtype;

cursor curReplenishFromPickFront (in_uom varchar2) is
  select pickfront,
         zwv.subtask_total(i1.facility,i1.pickfront,i1.item) as taskqty,
         zwv.location_lastupdate(i1.facility,i1.pickfront) as locupdate
    from itempickfrontsview i1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and pickuom = in_uom
     and locationstatus != 'O'
     and pickfront != in_locid
     and nvl(dynamic,'N') = 'N'
     and not exists
         (select *
            from itempickfronts i2
           where i1.facility = i2.facility
             and i1.pickfront = i2.pickfront
             and i2.pickuom != in_uom)
   order by 2 desc, 3;

cursor curReplFromPickFrontByClass (in_uom varchar2, in_inventoryclass varchar2) is
  select pickfront,
         zwv.subtask_total(i1.facility,i1.pickfront,i1.item) as taskqty,
         zwv.location_lastupdate(i1.facility,i1.pickfront) as locupdate
    from itempickfrontsview i1
   where facility = in_facility
     and custid = in_custid
     and item = in_item
     and pickuom = in_uom
     and locationstatus != 'O'
     and pickfront != in_locid
     and nvl(dynamic,'N') = 'N'
     and inventoryclass = in_inventoryclass
     and not exists
         (select *
            from itempickfronts i2
           where i1.facility = i2.facility
             and i1.pickfront = i2.pickfront
             and i2.pickuom != in_uom)
   order by 2 desc, 3;
fp curReplenishFromPickFront%rowtype;

cursor curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq,
         nvl(flex_pick_front_wave,0) as flex_pick_front_wave,
         flex_pick_front_item
    from location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;

cursor curPlateRow(in_lpid varchar2) is
  select *
    from plate
   where lpid = in_lpid;
lpr curPlateRow%rowtype;

cursor curWave(in_wave number) is
  select nvl(fpf_full_picks_to_fpf_yn,'N') as fpf_full_picks_to_fpf_yn
    from waves
   where wave = in_wave;
wv curWave%rowtype;

cursor curTaskQty is
  select nvl(sum(nvl(qty,0) - nvl(qtypicked,0)),0) qty, min(uom) uom
    from subtasks
   where facility = in_facility
     and fromloc = in_locid
     and item = in_item;
tq curTaskQty%rowtype;

curPlate integer;
cntRows integer;
lp plate%rowtype;
cmdSql varchar2(2000);
baseMaxQty itempickfronts.MaxQty%type;
basetaskqty itempickfronts.MaxQty%type;
basereplenishqty itempickfronts.replenishqty%type;
taskpickqty number(9,2);
tk tasks%rowtype;
sb subtasks%rowtype;
findbaseqty plate.quantity%type;
findbaseuom tasks.pickuom%type;
findpickuom tasks.pickuom%type;
findpickqty plate.quantity%type;
findpicktotype custitem.picktotype%type;
findcartontype custitem.cartontype%type;
findpickfront char(1);
findpicktype waves.picktype%type;
findwholeunitsonly char(1);
findweight plate.weight%type;
platequantity plate.quantity%type;
usepickfront boolean;
uomtofind varchar2(12);
cntTasks integer;
numJob number(16);
fullplaterpl varchar2(255);
palletuom unitsofmeasure.code%type;
palletqty number(9,2);
passCount number;

procedure log_msg(in_msg varchar2, in_msgtype varchar2) is
strMsg varchar2(255);
begin
  zms.log_autonomous_msg('REPLENISH', in_facility, in_custid,
    in_item || '/' || in_locid || ' ' || in_msg,
    in_msgtype, in_userid, strMsg);
exception when others then
  null;
end;
begin

out_msg := '';
out_errorno := 0;
cntTasks := 0;

open curItem;
fetch curItem into it;
if curItem%notfound then
  close curItem;
  log_msg('Customer Item not found', 'E');
  out_errorno := 1;
  return;
end if;
close curItem;

lb.qty := 0;
open curLocBalance;
fetch curLocBalance into lb;
close curLocBalance;

tb.qty := 0;
open curTaskBalance;
fetch curTaskBalance into tb;
close curTaskBalance;

open curItemPickFront;
fetch curItemPickFront into pf;
if curItemPickFront%notfound then
  close curItemPickFront;
  log_msg('Pick Front info not found', 'E');
  out_errorno := 2;
  return;
end if;
close curItemPickFront;

if nvl(pf.dynamic,'N') != 'N' then
   return;
end if;

begin
   fullplaterpl := 'N';
   if (pf.flexpick <> 'Y') then
     select nvl(defaultvalue,'N') into fullplaterpl
        from systemdefaults
        where defaultid = 'FULLPLATEREPLENISHMENT';
   end if;
exception
   when OTHERS then
      fullplaterpl := 'N';
end;

palletuom := null;
if pf.flexpick = 'Y' then
  toloc := null;
  open curLocation(in_facility,in_locid);
  fetch curLocation into toloc;
  close curLocation;

  if (toloc.flex_pick_front_item <> in_item) or
     (toloc.flex_pick_front_wave = 0) then
    log_msg('Unable to find flexible pick front for item ' || in_item, 'E');
    out_errorno := 7;
    return;
  end if;
  
  wv := null;
  open curWave(toloc.flex_pick_front_wave);
  fetch curWave into wv;
  close curWave;

  if (wv.fpf_full_picks_to_fpf_yn is null) then
    log_msg('Unable to find flexible pick front wave info ' || toloc.flex_pick_front_wave, 'E');
    out_errorno := 8;
    return;
  end if;
  
  tq := null;
  open curTaskQty;
  fetch curTaskQty into tq;
  close curTaskQty;

  if (tq.uom is null) then
    -- no replenishments needed
    out_msg := 'OKAY';
    out_errorno := 0;
    return;
  end if;

  if (pf.replenishqty = 0) or (pf.replenishuom is null) then
    pf.replenishqty := tq.qty;
    pf.replenishuom := tq.uom;
  else
    zbut.translate_uom(in_custid,in_item,pf.replenishqty,
      pf.replenishuom,it.baseuom,basereplenishqty,out_msg);
      
    if substr(out_msg,1,4) != 'OKAY' then
      log_msg('Unable to translate replenish uom ' || pf.replenishuom, 'E');
      out_errorno := 3;
      return;
    end if;
    
    if (basereplenishqty > tq.qty) then
      pf.replenishqty := tq.qty;
      pf.replenishuom := tq.uom;
    end if;
  end if;
  
  if (pf.maxqty = 0) or (pf.maxuom is null) then
    pf.maxqty := tq.qty;
    pf.maxuom := tq.uom;
  else
    zbut.translate_uom(in_custid,in_item,pf.maxqty,
      pf.maxuom,it.baseuom,basemaxqty,out_msg);
      
    if substr(out_msg,1,4) != 'OKAY' then
      log_msg('Unable to translate max uom ' || pf.maxuom, 'E');
      out_errorno := 4;
      return;
    end if;
    
    if (basemaxqty >= tq.qty) then
      pf.maxqty := tq.qty;
      pf.maxuom := tq.uom;
    else
      fullplaterpl := 'Y';
    end if;
  end if;
  
  if in_trace = 'Y' then
    log_msg('Flex pick: wave ' || toloc.flex_pick_front_wave || ' subtasks ' || tq.qty || ' ' || tq.uom ||
      ' min ' || pf.replenishqty || ' ' || pf.replenishuom || ' max ' || pf.maxqty || ' ' || pf.maxuom, 'T');
  end if;
  
  if (wv.fpf_full_picks_to_fpf_yn = 'Y') then
    palletuom := nvl(zci.default_value('PALLETSUOM'),'PLT');
    pf.replenishwithuom := palletuom;
    pf.pickuom := palletuom;
    
    if (pf.replenishuom != palletuom) then
      zbut.translate_uom(in_custid,in_item,pf.replenishqty,
        pf.replenishuom,palletuom,palletqty,out_msg);
        
      if substr(out_msg,1,4) != 'OKAY' then
        log_msg('Unable to translate pallet uom ' || palletuom, 'E');
        out_errorno := 10;
        return;
      end if;
      
      if (palletqty >= 1.0) then
        pf.replenishqty := ceil(palletqty);
        pf.replenishuom := palletuom;
      end if;
    end if;
    
    if (pf.maxuom != palletuom) then
      zbut.translate_uom(in_custid,in_item,pf.maxqty,
        pf.maxuom,palletuom,palletqty,out_msg);
        
      if substr(out_msg,1,4) != 'OKAY' then
        log_msg('Unable to translate pallet uom ' || palletuom, 'E');
        out_errorno := 10;
        return;
      end if;
      
      pf.maxqty := ceil(palletqty);
      pf.maxuom := palletuom;
    end if;
  
    if in_trace = 'Y' then
      log_msg('min ' || pf.replenishqty || ' ' || pf.replenishuom || ' max ' || pf.maxqty || ' ' || pf.maxuom, 'T');
    end if;
  else
    pf.replenishwithuom := tq.uom;
    pf.pickuom := tq.uom;
  end if;
end if;

if substr(in_reqtype,1,3) = 'TOP' then
  zbut.translate_uom(in_custid,in_item,pf.topoffqty,
    pf.topoffuom,it.baseuom,basereplenishqty,out_msg);
else
  zbut.translate_uom(in_custid,in_item,pf.replenishqty,
    pf.replenishuom,it.baseuom,basereplenishqty,out_msg);
end if;
if substr(out_msg,1,4) != 'OKAY' then
  log_msg('Unable to translate replenish uom ' || pf.replenishuom, 'E');
  out_errorno := 3;
  return;
end if;

if in_trace = 'Y' then
  log_msg(in_custid || ' ' || in_item || ' loc: ' || lb.qty || ' tsk: ' || tb.qty || ' min: ' ||
    basereplenishqty, 'T');
end if;

if (lb.qty + tb.qty) < basereplenishqty then
  zbut.translate_uom(in_custid,in_item,pf.maxQty,
    pf.maxuom,it.baseuom,basemaxqty,out_msg);
  if substr(out_msg,1,4) != 'OKAY' then
    log_msg('Unable to translate max uom ' || pf.maxuom, 'E');
    out_errorno := 4;
    return;
  end if;
  basetaskqty := basemaxqty - lb.qty - tb.qty;
  if in_trace = 'Y' then
    log_msg('basetaskqty is ' || basetaskqty,'T');
  end if;
  if basetaskqty > 0 then
    zbut.translate_uom(in_custid,in_item,basetaskqty,
      it.baseuom,pf.replenishwithuom,taskpickqty,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      log_msg('Unable to translate replenish with uom ' ||
        pf.replenishwithuom, 'E');
      out_errorno := 5;
      return;
    end if;
    taskpickqty := floor(taskpickqty);
    if taskpickqty = 0 then
      taskpickqty := 1;
    end if;
    zbut.translate_uom(in_custid,in_item,taskpickqty,
      pf.replenishwithuom,it.baseuom,basetaskqty,out_msg);
    if substr(out_msg,1,4) != 'OKAY' then
      log_msg('Unable to translate back to base uom ' || it.baseuom, 'E');
      out_errorno := 6;
      return;
    end if;
    if in_trace = 'Y' then
      log_msg('taskpickqty is ' || basetaskqty,'T');
    end if;
    if basetaskqty > 0 then
      usepickfront := False;
      if (pf.pickuom != pf.replenishwithuom) and (pf.flexpick != 'Y') and (pf.allocrule = 'C') then
        fp := null;
        if it.pick_front_by_invclass = 'Y' then
          log_msg('pfbyclass ' ||
              pf.pickuom || ' with ' || pf.replenishwithuom, 'T');
          open curReplFromPickFrontByClass(pf.replenishwithuom, pf.inventoryclass);
          fetch curReplFromPickFrontByClass into fp;
          close curReplFromPickFrontByclass;
        else
          log_msg('pfNOTbyclass ' ||
              pf.pickuom || ' with ' || pf.replenishwithuom, 'T');
        open curReplenishFromPickFront(pf.replenishwithuom);
        fetch curReplenishFromPickFront into fp;
          close curReplenishFromPickFront;
        end if;
        if fp.pickfront is not null then
          usepickfront := True;
          if in_trace = 'Y' then
            log_msg('Using pickfront for replenishment of ' ||
              pf.pickuom || ' with ' || pf.replenishwithuom, 'T');
          end if;
        end if;
      end if;
      if usepickfront then
        ztsk.get_next_taskid(tk.taskid,out_msg);
        open curLocation(in_facility,fp.pickfront);
        fetch curLocation into fromloc;
        close curLocation;
        open curLocation(in_facility,in_locid);
        fetch curLocation into toloc;
        close curLocation;
        insert into tasks
          (taskid, tasktype, facility, fromsection, fromloc,
           fromprofile,tosection,toloc,toprofile,
           custid,item,lpid,uom,qty,locseq,priority,
           prevpriority,lastuser,lastupdate,
           pickuom, pickqty, picktotype,
           pickingzone, cartontype, weight, cube, staffhrs)
          values
          (tk.taskid, 'RP', in_facility, fromloc.section,fp.pickfront,
           fromloc.equipprof,toloc.section,in_locid,
           toloc.equipprof,in_custid,in_item,null,
           it.baseuom,basetaskqty,fromloc.pickingseq,
           '3','3',in_userid,sysdate,
           pf.replenishwithuom,taskpickqty,'PAL',
           fromloc.pickingzone,'NONE',
           zci.item_weight(in_custid,in_item,pf.replenishwithuom) * taskpickqty,
           zci.item_cube(in_custid,in_item,pf.replenishwithuom) * taskpickqty,
           zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
           fromloc.pickingzone,pf.replenishwithuom,taskpickqty));
        insert into subtasks
          (taskid, tasktype, facility, fromsection, fromloc,
           fromprofile,tosection,toloc,toprofile,
           custid,item,lpid,uom,qty,locseq,priority,
           prevpriority,lastuser,lastupdate,
           pickuom, pickqty, picktotype,
           pickingzone, cartontype, weight, cube,
           staffhrs, shippingtype)
          values
          (tk.taskid, 'RP', in_facility, fromloc.section,fp.pickfront,
           fromloc.equipprof,toloc.section,in_locid,
           toloc.equipprof,in_custid,in_item,null,
           it.baseuom,basetaskqty,fromloc.pickingseq,
           '3','3',in_userid,sysdate,
           pf.replenishwithuom,taskpickqty,'PAL',
           fromloc.pickingzone,'PAL',
           zci.item_weight(in_custid,in_item,pf.replenishwithuom) * taskpickqty,
           zci.item_cube(in_custid,in_item,pf.replenishwithuom) * taskpickqty,
           zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
           fromloc.pickingzone,pf.replenishwithuom,taskpickqty),
           'P');
        cntTasks := cntTasks + 1;
      else
        cmdSql := 'select distinct invstatus, inventoryclass from availstatusclassview ' ||
          'where facility = ''' || nvl(in_facility,'x') || '''' ||
          ' and custid = ''' || nvl(in_custid,'x') || '''' ||
          ' and item = ''' || nvl(in_item,'x') || '''';
        if rtrim(it.invstatus) is not null then
          cmdsql := cmdsql || ' and invstatus ' ||
            zcm.in_str_clause(it.invstatusind,it.invstatus);
        end if;
        if it.pick_front_by_invclass = 'Y' then
          cmdsql := cmdsql || ' and inventoryclass ' ||
            zcm.in_str_clause('I', pf.inventoryclass);
        elsif rtrim(it.inventoryclass) is not null then
          cmdsql := cmdsql || ' and inventoryclass ' ||
            zcm.in_str_clause(it.invclassind, it.inventoryclass);
        end if;
        if (pf.flexpick = 'Y') and (palletuom is not null) then
          uomtofind := palletuom;
        elsif (pf.flexpick = 'Y') and (pf.allocrule <> 'C') then
          uomtofind := 'IGNORE';
        elsif pf.pickuom = pf.replenishwithuom then
          uomtofind := 'NOPICKFRONT';
        else
          uomtofind := pf.replenishwithuom;
        end if;
        if in_trace = 'Y' then
          cntRows := 1;
          while (cntRows * 60) < (Length(cmdSql)+60)
          loop
            log_msg(substr(cmdSql,((cntRows-1)*60)+1,60), 'T');
            cntRows := cntRows + 1;
          end loop;
        end if;
        begin
          curPlate := dbms_sql.open_cursor;
          dbms_sql.parse(curPlate, cmdSql, dbms_sql.native);
          dbms_sql.define_column(curPlate,1,lp.invstatus,2);
          dbms_sql.define_column(curPlate,2,lp.inventoryclass,2);
          cntRows := dbms_sql.execute(curPlate);
          while basetaskqty > 0
          loop
            cntRows := dbms_sql.fetch_rows(curPlate);
            if (cntRows <= 0) and (pf.flexpick != 'Y') then
              exit;
            end if;
            dbms_sql.column_value(curPlate,1,lp.invstatus);
            dbms_sql.column_value(curPlate,2,lp.inventoryclass);
            while basetaskqty > 0
            loop
              if in_trace = 'Y' then
                log_msg('find: ' || uomtofind || ' stat: ' || lp.invstatus || ' class: ' ||
                    lp.inventoryclass, 'T');
              end if;
              findpicktype := null;
              if (substr(in_reqtype,6,1) != 'P') then
                findwholeunitsonly := 'Y';
              end if;
              passCount := 1;
<< find_again >>
              zwv.find_a_pick(in_facility,in_custid,null,null,in_item,null,
                lp.invstatus, lp.inventoryclass, basetaskqty,
                uomtofind, 'Y', -- IS replenish request
                'STO', 'N', 'E', 0, 'N', null, 'N', 'N', 0, pf.allocrule, passCount, lp.lpid, 
                findbaseuom, findbaseqty, findpickuom,
                findpickqty, findpickfront, findpicktotype, findcartontype,
                findpicktype, findwholeunitsonly, findweight, in_trace, out_msg);
              if substr(out_msg,1,4) = 'OKAY' then
                if (fullplaterpl = 'Y' and
                    ((lb.qty + tb.qty) > basereplenishqty) and
                    ((lb.qty + tb.qty + findbaseqty) > basereplenishqty)) then
                	platequantity := 0;
                	select quantity
                	  into platequantity
                	  from plate
                	 where lpid = lp.lpid;
                	 
                	if (findbaseqty < platequantity) then
                		basetaskqty := 0;
                		exit;
                	end if;
                end if;
                tb.qty := tb.qty + findbaseqty;
                if (findpickfront != 'Y') and
                   (lp.lpid is not null) then
                  open curPlateRow(lp.lpid);
                  fetch curPlateRow into lpr;
                  close curPlateRow;
                  if (findbaseqty = lpr.quantity) then
                    sb.shippingtype := 'F';
                  else
                    sb.shippingtype := 'P';
                  end if;
                  basetaskqty := basetaskqty - findbaseqty;
                  ztsk.get_next_taskid(tk.taskid,out_msg);
                  open curLocation(in_facility,lpr.location);
                  fetch curLocation into fromloc;
                  close curLocation;
                  open curLocation(in_facility,in_locid);
                  fetch curLocation into toloc;
                  close curLocation;
                  insert into tasks
                    (taskid, tasktype, facility, fromsection, fromloc,
                     fromprofile,tosection,toloc,toprofile,
                     custid,item,lpid,uom,qty,locseq,priority,
                     prevpriority,lastuser,lastupdate,
                     pickuom, pickqty, picktotype,
                     pickingzone, cartontype, weight, cube, staffhrs)
                    values
                    (tk.taskid, 'RP', in_facility, fromloc.section,lpr.location,
                     fromloc.equipprof,toloc.section,in_locid,
                     toloc.equipprof,in_custid,in_item,lp.lpid,
                     it.baseuom,findbaseqty,fromloc.pickingseq,
                     '3','3',in_userid,sysdate,
                     findpickuom,findpickqty,'FULL',
                     fromloc.pickingzone,'NONE',
                     zci.item_weight(in_custid,in_item,findpickuom) * findpickqty,
                     zci.item_cube(in_custid,in_item,findpickuom) * findpickqty,
                     zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
                     fromloc.pickingzone,findpickuom,findpickqty));
                  insert into subtasks
                    (taskid, tasktype, facility, fromsection, fromloc,
                     fromprofile,tosection,toloc,toprofile,
                     custid,item,lpid,uom,qty,locseq,priority,
                     prevpriority,lastuser,lastupdate,
                     pickuom, pickqty, picktotype,
                     pickingzone, cartontype, weight, cube, staffhrs,
                     shippingtype)
                    values
                    (tk.taskid, 'RP', in_facility, fromloc.section,lpr.location,
                     fromloc.equipprof,toloc.section,in_locid,
                     toloc.equipprof,in_custid,in_item,lp.lpid,
                     it.baseuom,findbaseqty,fromloc.pickingseq,
                     '3','3',in_userid,sysdate,
                     findpickuom,findpickqty,'FULL',
                     fromloc.pickingzone,'NONE',
                     zci.item_weight(in_custid,in_item,findpickuom) * findpickqty,
                     zci.item_cube(in_custid,in_item,findpickuom) * findpickqty,
                     zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
                     fromloc.pickingzone,findpickuom,findpickqty),
                     sb.shippingtype);
                  update plate
                     set qtytasked = nvl(qtytasked,0) + findbaseqty
                   where lpid = lp.lpid
                     and parentfacility is not null;
                  cntTasks := cntTasks + 1;
                elsif (findpickfront = 'Y') and (lp.lpid is not null) and
                  (pf.flexpick = 'Y') and (pf.allocrule is not null) then
                  basetaskqty := basetaskqty - findbaseqty;
                  ztsk.get_next_taskid(tk.taskid,out_msg);
                  open curLocation(in_facility,lp.lpid);
                  fetch curLocation into fromloc;
                  close curLocation;
                  open curLocation(in_facility,in_locid);
                  fetch curLocation into toloc;
                  close curLocation;
                  insert into tasks
                    (taskid, tasktype, facility, fromsection, fromloc,
                     fromprofile,tosection,toloc,toprofile,
                     custid,item,lpid,uom,qty,locseq,priority,
                     prevpriority,lastuser,lastupdate,
                     pickuom, pickqty, picktotype,
                     pickingzone, cartontype, weight, cube, staffhrs)
                    values
                    (tk.taskid, 'RP', in_facility, fromloc.section,lp.lpid,
                     fromloc.equipprof,toloc.section,in_locid,
                     toloc.equipprof,in_custid,in_item,null,
                     it.baseuom,findbaseqty,fromloc.pickingseq,
                     '3','3',in_userid,sysdate,
                     findpickuom,findpickqty,'PAL',
                     fromloc.pickingzone,'NONE',
                     zci.item_weight(in_custid,in_item,pf.replenishwithuom) * findpickqty,
                     zci.item_cube(in_custid,in_item,pf.replenishwithuom) * findpickqty,
                     zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
                     fromloc.pickingzone,findpickuom,findpickqty));
                  insert into subtasks
                    (taskid, tasktype, facility, fromsection, fromloc,
                     fromprofile,tosection,toloc,toprofile,
                     custid,item,lpid,uom,qty,locseq,priority,
                     prevpriority,lastuser,lastupdate,
                     pickuom, pickqty, picktotype,
                     pickingzone, cartontype, weight, cube,
                     staffhrs, shippingtype)
                    values
                    (tk.taskid, 'RP', in_facility, fromloc.section,lp.lpid,
                     fromloc.equipprof,toloc.section,in_locid,
                     toloc.equipprof,in_custid,in_item,null,
                     it.baseuom,findbaseqty,fromloc.pickingseq,
                     '3','3',in_userid,sysdate,
                     findpickuom,findpickqty,'PAL',
                     fromloc.pickingzone,'PAL',
                     zci.item_weight(in_custid,in_item,pf.replenishwithuom) * findpickqty,
                     zci.item_cube(in_custid,in_item,pf.replenishwithuom) * findpickqty,
                     zlb.staff_hours(in_facility,in_custid,in_item,'REPL',
                     fromloc.pickingzone,findpickuom,findpickqty),
                     'P');
                  cntTasks := cntTasks + 1;
                else
                  exit;
                end if;
              elsif (substr(in_reqtype,6,1) != 'P') and
                    (passCount = 1) then
                passCount := 2;
                findwholeunitsonly := 'Y';
                goto find_again;
              elsif (nvl(passCount,2) < 2) then
                passCount := nvl(passCount,2) + 1;
                goto find_again;
              else
                if (in_trace = 'Y') or
                   (out_msg <> 'No inventory found') then
                  log_msg(out_msg, 'T');
                end if;
                exit;
              end if;
            end loop;
          end loop;
          dbms_sql.close_cursor(curPlate);
        exception when others then
          dbms_sql.close_cursor(curPlate);
        end;
      end if;
    end if;
  end if;
  if (cntTasks = 0) and
     (substr(in_reqtype,6,1) != 'P') then
    dbms_job.submit(numJob,'zrpl.submit_replenish_request(''' ||
      substr(in_reqtype,1,5) || 'P'',''' ||
      in_facility || ''',''' || in_custid || ''',''' || in_item ||
      ''',''' || in_locid || ''',''' || in_userid ||
      ''', ''N'');',
      sysdate + .00005887, null, null);
  end if;
else
  if (tb.qty != 0) and
     (lb.qty < basereplenishqty) then
     update subtasks
       set priority = ztk.upgrade_priority(priority)
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and toloc = in_locid
       and priority not in  ('0','9');
    update tasks
       set priority = ztk.upgrade_priority(priority)
     where facility = in_facility
       and custid = in_custid
       and item = in_item
       and toloc = in_locid
       and priority not in  ('0','9');
  end if;
end if;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
   out_msg := 'zrpplr ' || substr(sqlerrm, 1, 80);
   out_errorno := sqlcode;
end process_loc_replenishment;

procedure process_kit_replenishment
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cursor curItem is
  select baseuom,
         invstatusind,
         invstatus,
         invclassind,
         inventoryclass
    from custitemview
   where custid = in_custid
     and item = in_item;
it curItem%rowtype;

cursor curItemBalance is
  select nvl(sum(quantity),0) as qty
    from plate
   where custid = in_custid
     and item = in_item
     and facility = in_facility
     and type = 'PA'
     and status = 'A';
ib curItemBalance%rowtype;

cursor curKitBalance is
  select nvl(sum(od.qtyorder),0) - nvl(sum(od.qtypick),0) as qty
    from orderdtl od, orderhdr oh
   where oh.orderid = od.orderid
     and oh.shipid = od.shipid
     and oh.ordertype = 'W'
     and oh.orderstatus < '6'
     and od.item = in_item
     and od.linestatus != 'X';
kb curKitBalance%rowtype;

cursor curMinMax is
  select nvl(qtyMin,0) as qtyMin,
         nvl(qtyMax,0) as qtyMax,
         nvl(qtyWorkOrderMin,0) as qtyWorkOrderMin
    from custitemminmax
   where custid = in_custid
     and item = in_item
     and facility = in_facility;
mm curMinMax%rowtype;
strMsg varchar2(255);
oh OrderHdr%rowtype;
od OrderDtl%rowtype;

procedure log_msg(in_msg varchar2, in_msgtype varchar2) is
begin
  zms.log_msg('REPLENISH', in_facility, in_custid,
    in_item || '/' || 'STOCK ORDER' || ' ' || in_msg,
    in_msgtype, in_userid, strMsg);
exception when others then
  null;
end;

begin

out_msg := '';
out_errorno := 0;

open curItem;
fetch curItem into it;
if curItem%notfound then
  close curItem;
  log_msg('Customer Item not found', 'E');
  out_errorno := 1;
  return;
end if;
close curItem;

mm := null;
open curMinMax;
fetch curMinMax into mm;
close curMinMax;
if mm.qtyMin is null then
  out_errorno := 0;
  out_msg := 'OKAY';
  return;
end if;

ib.qty := 0;
open curItemBalance;
fetch curItemBalance into ib;
close curItemBalance;

if in_trace = 'Y' then
  zms.log_msg('REPLENISH', in_facility, in_custid,
    in_item || '/' || 'STOCK ORDER' || ' ' ||
    'Max Qty ' || mm.qtyMax || ' ' ||
    'Item Qty ' || ib.qty || ' ' ||
    'Kit Qty ' || kb.qty,
    'T', in_userid, strMsg);
end if;

od.qtyorder := mm.qtyMax - ib.qty;
if (od.qtyorder <= 0) or
   (od.qtyorder < mm.qtyWorkOrderMin) then
  out_errorno := 0;
  out_msg := 'OKAY';
  return;
end if;

kb.qty := 0;
open curKitBalance;
fetch curKitBalance into kb;
close curKitBalance;
od.qtyorder := od.qtyorder - kb.qty;
if (od.qtyorder <= 0) or
   (od.qtyorder < mm.qtyWorkOrderMin) then
  out_errorno := 0;
  out_msg := 'OKAY';
  return;
end if;

if in_trace = 'Y' then
  zms.log_msg('REPLENISH', in_facility, in_custid,
    in_item || '/' || 'STOCK ORDER' || ' ' ||
    'Max Qty ' || mm.qtyMax || ' ' ||
    'Item Qty ' || ib.qty || ' ' ||
    'Kit Qty ' || kb.qty,
    'T', in_userid, strMsg);
end if;

zoe.get_next_orderid(oh.orderid,out_msg);
oh.shipid := 1;
insert into orderhdr
(orderid,shipid,custid,ordertype,apptdate,shipdate,po,rma,
 fromfacility,tofacility,shipto,billoflading,priority,shipper,
 consignee,shiptype,carrier,reference,shipterms,lastuser,lastupdate,
 orderstatus,commitstatus,statususer,entrydate, parentorderid,
 parentshipid, parentorderitem, parentorderlot, workorderseq)
values
(oh.orderid,oh.shipid,in_custid,'W',null,sysdate,null,null,
 in_facility,null,null,null,'A',null,
 null,null,null,null,null,in_userid,sysdate,
 '0','0',in_userid,sysdate,null,
 null,null,null,null);

insert into orderdtl
(orderid,shipid,item,lotnumber,uom,linestatus,
qtyentered,itementered,uomentered,
qtyorder,weightorder,cubeorder,amtorder,lastuser,lastupdate,
backorder,allowsub,qtytype,invstatusind,invstatus,invclassind,
inventoryclass,consigneesku,statususer
)
values
(oh.orderid,oh.shipid,in_item,null,it.baseuom,'A',
od.qtyorder,in_item,it.baseuom,
od.qtyorder,zci.item_weight(oh.custid,in_item,it.baseuom) * od.qtyorder,
zci.item_cube(oh.custid,in_item,it.baseuom) * od.qtyorder,
zci.item_amt(oh.custid,oh.orderid,oh.shipid,in_item,null) * od.qtyorder, in_userid, sysdate, --prn 25133
'N','N','E','I',null,'I',null,null,in_userid
);

zms.log_msg('STOCKREPL', in_facility, in_custid,
  'Replenishment work Order ' || oh.orderid || '-' || oh.shipid ||
  ' created for customer/item ' || oh.custid || '/' || in_item,
  'I', in_userid, strMsg);

exception when others then
   out_msg := 'zrppkr ' || substr(sqlerrm, 1, 80);
   out_errorno := sqlcode;
end process_kit_replenishment;

procedure submit_replenish_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
) is
out_errorno integer;
out_msg varchar2(255);
begin

zrp.send_replenish_msg(in_reqtype,in_facility,in_custid,
 in_item, in_locid, in_userid, in_trace, out_errorno,
 out_msg);

exception when others then
  null;
end submit_replenish_request;

function loc_balance
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
) return number is

out_balance plate.quantity%type;

begin

out_balance := 0;

select nvl(sum(quantity),0)
  into out_balance
  from plate
 where custid = in_custid
   and item = in_item
   and facility = in_facility
   and location = in_locid
   and type = 'PA'
   and status = 'A';

return out_balance;

exception when others then
  return 0;
end loc_balance;

function task_balance
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
) return number is

out_balance plate.quantity%type;

begin

out_balance := 0;

select nvl(sum(qty),0)
  into out_balance
  from subtasks
 where facility = in_facility
   and custid = in_custid
   and item = in_item
   and toloc = in_locid;

return out_balance;

exception when others then
  return 0;
end task_balance;




procedure assigned_item_replenish
(in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,out_newitem          out varchar2
,out_newcustid        out varchar2
,out_errorno          out number
,out_msg              out varchar2
) is


lipcount number(15);

cursor cNewItem is
	select distinct pendingitem,pendingcustid
		from itempickfronts
			where pendingitem is not null and
				custid       = in_custid and
				facility     = in_facility and
				oldpickfront = in_locid and
				item         = in_item;

begin

	for theItem in cNewItem loop
		out_newitem   := theItem.pendingitem;
		out_newcustid := theItem.pendingcustid;
	end loop;



	out_errorno := 1;
	out_msg   := 'IGNORE';

	if out_newitem is not null then


		select count(1) into lipcount
			from plate
				where facility   = in_facility and
					custid   = in_custid and
					item     = in_item and
					location = in_locid and
					status   = 'A';


		if lipcount = 0 then

			update itempickfronts
				set pickfront = in_locid,
				    lastuser = 'UPDTIPF',
				    lastupdate = sysdate
				where  facility = in_facility and
					custid  = out_newcustid and
					item   = out_newitem and
					pickfront is null;

			update itempickfronts
				set pendingitem = null,
				    pendingcustid = null,
				    olditem = null,
				    oldpickfront = null,
				    lastuser = 'UPDTIPF',
				    lastupdate = sysdate
				where  facility = in_facility and
					custid = in_custid and
					item   = in_item;

			out_errorno := 0;
			out_msg   := 'OKAY';
		end if;



	end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,255);
end assigned_item_replenish;

procedure validate_pick_front_drop
(in_lpid              in varchar2
,in_facility          in varchar2
,in_drop_loc          in varchar2
,out_pf_loc           in out varchar2
,out_errorno          in out number
)
is
lp plate%rowtype;
lp_rowid rowid;
l_pick_front_by_invclass custitem.pick_front_by_invclass%type;
l_pf_count pls_integer;

begin

out_errorno := 0;
out_pf_loc := '';

lp := null;
begin
  select custid, item, inventoryclass, rowid
    into lp.custid, lp.item, lp.inventoryclass, lp_rowid
    from plate
   where lpid = in_lpid;
exception when others then
  out_errorno := -1;
  out_pf_loc := 'LIPNOTFND';
  return;
end;

if (lp.custid is not null) and -- not a multi or a multi with all same custid/item/inventoryclass
   (lp.item is not null) and
   (lp.inventoryclass is not null) then
  begin
    select nvl(pick_front_by_invclass,'N')
      into l_pick_front_by_invclass
      from custitem
     where custid = lp.custid
       and item = lp.item;
  exception when others then
    l_pick_front_by_invclass := 'N';
  end;
  
  if l_pick_front_by_invclass = 'Y' then
    select count(1)
      into l_pf_count
      from itempickfronts
     where facility = in_facility
       and custid = lp.custid
       and item = lp.item
       and pickfront = in_drop_loc
       and inventoryclass = lp.inventoryclass;
  else
    select count(1)
      into l_pf_count
      from itempickfronts
     where facility = in_facility
       and custid = lp.custid
       and item = lp.item
       and pickfront = in_drop_loc;
  end if;
  if l_pf_count = 0 then
    out_errorno := -4;
    if l_pick_front_by_invclass = 'Y' then
      begin
        select pickfront
          into out_pf_loc
          from itempickfronts
         where facility = in_facility
           and custid = lp.custid
           and item = lp.item
           and inventoryclass = lp.inventoryclass
           and rownum = 1;
        return;
      exception when others then
        out_errorno := -2;
        out_pf_loc := '(no-class)';
        return;
      end;
    else
      begin
        select pickfront
          into out_pf_loc
          from itempickfronts
         where facility = in_facility
           and custid = lp.custid
           and item = lp.item
           and rownum = 1;
        return;
      exception when others then
        out_errorno := -3;
        out_pf_loc := '(none)';
        return;
      end;
    end if;
  else
    out_pf_loc := in_drop_loc;
    return;
  end if;
end if;

--process mixed multi
for lpitms in (select distinct custid, item, inventoryclass
               from plate
              where type = 'PA'
              start with rowid = lp_rowid
            connect by prior lpid = parentlpid)
loop
  begin
    select nvl(pick_front_by_invclass,'N')
      into l_pick_front_by_invclass
      from custitem
     where custid = lpitms.custid
       and item = lpitms.item;
  exception when others then
    l_pick_front_by_invclass := 'N';
  end;

  if l_pick_front_by_invclass = 'Y' then
    select count(1)
      into l_pf_count
      from itempickfronts
     where facility = in_facility
       and custid = lpitms.custid
       and item = lpitms.item
       and pickfront = in_drop_loc
       and inventoryclass = lpitms.inventoryclass;
  else
    select count(1)
      into l_pf_count
      from itempickfronts
     where facility = in_facility
       and custid = lpitms.custid
       and item = lpitms.item
       and pickfront = in_drop_loc;
  end if;
  if l_pf_count = 0 then
    if l_pick_front_by_invclass = 'Y' then
      begin
        select pickfront
          into out_pf_loc
          from itempickfronts
         where facility = in_facility
           and custid = lpitms.custid
           and item = lpitms.item
           and pickfront = in_drop_loc
           and inventoryclass = lpitms.inventoryclass
           and rownum = 1;
      exception when others then
        out_errorno := -2;
        out_pf_loc := '(no-class)';
        return;
      end;
    else
      begin
        select pickfront
          into out_pf_loc
          from itempickfronts
         where facility = in_facility
           and custid = lpitms.custid
           and item = lpitms.item
           and pickfront = in_drop_loc
           and rownum = 1;
      exception when others then
        out_errorno := -3;
        out_pf_loc := '(none)';
        return;
      end;
    end if;
  else
    out_pf_loc := in_drop_loc;
    return;
  end if;
end loop;

exception when others then
  out_errorno := sqlcode;
  out_pf_loc := to_char(sqlcode);
end;  

end replenishment;
/
show error package body replenishment;
exit;
