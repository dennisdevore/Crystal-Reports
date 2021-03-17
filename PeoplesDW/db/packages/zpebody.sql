create or replace package body alps.zpickentry as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
CURSOR C_TASK(in_taskid number)
RETURN tasks%rowtype
IS
    SELECT *
      FROM tasks
     WHERE taskid = in_taskid;

----------------------------------------------------------------------
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_SUBTASK(in_taskid number, in_shippingplate varchar2)
IS
    SELECT subtasks.rowid, subtasks.*
      FROM subtasks
     WHERE taskid = in_taskid
       AND shippinglpid = in_shippingplate;

----------------------------------------------------------------------
CURSOR C_SHIPPLATE(in_taskid number, in_shiplpid varchar2)
RETURN shippingplate%rowtype
IS
    SELECT *
      FROM shippingplate
     WHERE taskid = in_taskid
       AND lpid = in_shiplpid;

----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
CURSOR C_PKF(in_facility varchar2, in_locid varchar2,
       in_custid varchar2, in_item varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE facility = in_facility
       AND location = in_locid
       AND custid = in_custid
       AND item = in_item;

----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_LOCATION(in_facility varchar2, in_location varchar2)
RETURN location%rowtype
IS
    SELECT *
      FROM location
     WHERE facility = in_facility
       AND locid = in_location;

----------------------------------------------------------------------

CURSOR C_CUSTITEM(in_custid varchar2,in_item varchar2)
RETURN custitemview%rowtype
IS
    SELECT *
      FROM custitemview
     WHERE custid = in_custid and
     	   item   = in_item;

----------------------------------------------------------------------

-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- pick_subtask
--
----------------------------------------------------------------------
PROCEDURE pick_subtask
(
    in_taskid       IN      number,
    in_shippinglpid IN      varchar2,
    in_picklpid     IN      varchar2,
    in_pickloc      IN      varchar2,
    in_pickqty      IN      number,
    in_reason       IN      varchar2,
    in_label        IN      varchar2,
    in_serialno     IN      varchar2,
    in_lotno	    IN      varchar2,
    in_user1	    IN	    varchar2,
    in_user2        IN      varchar2,
    in_user3        IN      varchar2,
    in_user         IN      varchar2,
    in_weight       IN      number,
    out_errmsg      OUT     varchar2
)IS
  TASK tasks%rowtype;
  ST C_SUBTASK%rowtype;
  SP shippingplate%rowtype;
  CUST customer%rowtype;
  CUSTITEM custitemview%rowtype;
  PLT plate%rowtype;
  LOC location%rowtype;
  OH orderhdr%rowtype;

  lpid plate.lpid%type;

  chk_error  varchar2(10);
  lp_count   integer;
  errmsg     varchar2(100);

   theQty number;

   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;


BEGIN
    out_errmsg := 'OKAY';
    theQty := in_pickqty;

-- Verify taskid
    TASK := null;
    OPEN C_TASK(in_taskid);
    FETCH C_TASK into TASK;
    CLOSE C_TASK;

    if TASK.taskid is null then
       out_errmsg := 'Invalid taskid. Does not exist.';
       return;
    end if;

-- Get Order Info
    OH := null;
    OPEN C_ORDHDR(TASK.orderid, TASK.shipid);
    FETCH C_ORDHDR into OH;
    CLOSE C_ORDHDR;

    if (TASK.tasktype not in ('OP','SO')) and
       not (TASK.tasktype = 'PK' and OH.ordertype in ('U','T')) then
       out_errmsg := 'Invalid taskid. Only valid for order and sort picks.';
       return;
    end if;

-- Get customer info for this pick task
    CUST := null;
    OPEN C_CUST(TASK.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
        out_errmsg := 'Customer '||TASK.custid||' does not exist';
        return;
    end if;

-- Read sub-task and shipping plat
    ST := null;
    OPEN C_SUBTASK(in_taskid, in_shippinglpid);
    FETCH C_SUBTASK into ST;
    CLOSE C_SUBTASK;

    if ST.taskid is null then
       out_errmsg := 'Invalid sub-task. Does not exist.';
       return;
    end if;

    SP := null;
    OPEN C_SHIPPLATE(in_taskid, in_shippinglpid);
    FETCH C_SHIPPLATE into SP;
    CLOSE C_SHIPPLATE;

    if SP.taskid is null then
       out_errmsg := 'Invalid shippingplate. Does not exist.';
       return;
    end if;


-- Verify required fields
    CUSTITEM := null;
    OPEN C_CUSTITEM(TASK.custid,ST.item);
    FETCH C_CUSTITEM into CUSTITEM;
    CLOSE C_CUSTITEM;

    if ( (CUSTITEM.LOTREQUIRED in ('P','O')) or
         (CUSTITEM.LOTREQUIRED = 'S' and rtrim(sp.orderlot) is not null) ) then
    	if in_lotno is null then
    		out_errmsg := 'Lot Number Required.';
       		return;
       	end if;

    end if;

    if CUSTITEM.SERIALREQUIRED = 'P' then
    	if in_serialno is null then
    		out_errmsg := 'Serial Number Required.';
       		return;
       	end if;

    end if;

    if CUSTITEM.USER1REQUIRED = 'P' then
    	if in_user1 is null then
    		out_errmsg := 'User 1 Required.';
       		return;
       	end if;

    end if;

    if CUSTITEM.USER2REQUIRED = 'P' then
    	if in_user2 is null then
    		out_errmsg := 'User 2 Required.';
       		return;
       	end if;

    end if;

    if CUSTITEM.USER3REQUIRED = 'P' then
    	if in_user3 is null then
    		out_errmsg := 'User 3 Required.';
       		return;
       	end if;

    end if;



-- If we have a plate get it
    PLT := null;
    if in_picklpid is not null then
	 -- theQty := null;
        lpid := lpad(in_picklpid, 15,'0');
        OPEN C_PLATE(lpid);
        FETCH C_PLATE into PLT;
        CLOSE C_PLATE;

        if PLT.lpid is null then
           out_errmsg := 'Invalid plate. Does not exist.';
           return;
        end if;
        if PLT.custid != CUST.custid then
           out_errmsg := 'Invalid plate. Does not belong to customer.';
           return;
        end if;
        if PLT.item != ST.item then
           out_errmsg := 'Invalid plate. Not same item.';
           return;
        end if;

        if ST.orderlot is not null then
          if ST.orderlot != NVL(PLT.lotnumber,'(none)') then
           out_errmsg := 'Invalid plate. Not same item.';
           return;
          end if;
        end if;
    elsif ST.lpid is not null then
        OPEN C_PLATE(ST.lpid);
        FETCH C_PLATE into PLT;
        CLOSE C_PLATE;
    end if;

-- verify picked qty
   if theQty  is not null then
      if theQty != ST.pickqty then
         if in_reason is null then
            out_errmsg := 'If override qty must provide reason.';
            return;
         end if;
      end if;
   end if;

-- get qty in terms of the base uom
-- There's no way to change the picked uom here, so we assume the user picks the uom
-- as instructed, but the qty we send to pick a plate must be in terms of the base
-- uom. (I think.) - Brad

zbut.translate_uom(CUST.custid,ST.item,in_pickqty,ST.pickuom,CUSTITEM.baseuom,theQty,out_errmsg);

-- check we have label if picktotype is correct
   if ST.picktotype in ('PACK','TOTE') then
      if in_label is null then
         out_errmsg := 'Must provide label id for pick to type:'
                    || ST.picktotype;
         return;
      end if;
-- Determine plate type and if it exists
     zrf.identify_lp(in_label, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, errmsg);
--     if (errmsg is null) then
--          zut.prt('LP Type  : '||lptype);
--          zut.prt('Top Plate: '||topid||'/'||toptype);
--          zut.prt('Parent   : '||parentid||'/'||parenttype);
--          zut.prt('Xref     : '||xrefid||'/'||xreftype);
--     end if;
     if lptype <> '?' then
       if ST.picktotype = 'TOTE' and lptype <> 'TO' then
          out_errmsg := 'TOTE requires an existing plate.';
          return;
       end if;
       if ST.picktotype = 'PACK' and xreftype <> 'C' then
          out_errmsg := 'PACK requires an existing carton.';
          return;
       end if;
       if ST.picktotype = 'PAL' and ST.shippingtype = 'P' and xreftype <> 'M' then
          out_errmsg := 'Partial pick to PAL requires an existing master pallet.';
          return;
       end if;
     end if;
   end if;

-- Check pick loc is a picking loc for same item???
   LOC := null;
   if in_pickloc is not null then
      OPEN C_LOCATION(TASK.facility, in_pickloc);
      FETCH C_LOCATION into LOC;
      CLOSE C_LOCATION;

      if LOC.locid is null then
         out_errmsg := 'Invalid location. Does not exist.';
         return;
      end if;
--    if LOC.loctype != 'PF' then
--       out_errmsg := 'Invalid location. Must pick from pick front.';
--       return;
--    end if;
      -- verify contains our item
      if LOC.loctype = 'PF' then
         PLT := null;
         OPEN C_PKF(TASK.facility, in_pickloc, TASK.custid, ST.item);
         FETCH C_PKF into PLT;
         CLOSE C_PKF;

         if PLT.lpid is null then
            out_errmsg := 'Invalid location. Pick front does not contain item.';
            return;
         end if;
      end if;
   end if;

-- Everything looks OK so call actual picking routine

/*

zrfpk.pick_a_plate(:taskid, :spid, :Guser, :plannedlp, :pickedlp, :custid,
                  :item, :orderitem, :lotno, :orderid, :shipid, :qty, :dropseq, :Gfacility,
                  :pickloc, :uom, :lplotno, :**mlip, :picktype=shippingtype?, :ttype, :picktotype,
                  :fromloc, :rid??, null, null, :cptlot???, :cptsn, :cptui1, :cptui2, :cptui3,
                  :lpcount:ilpcount, :err:ierr, :msg:imsg);


*/


   zrfpk.pick_a_plate(TASK.taskid,
                       ST.shippinglpid,
                       in_user,
                       ST.lpid,
                       nvl(in_picklpid, ST.lpid),
                       TASK.custid,
                       ST.item,
                       ST.orderitem,
                       ST.orderlot,
                       nvl(theQty,ST.qty),
                       SP.dropseq,
                       ST.facility,
                       nvl(in_pickloc,ST.fromloc),
							  CUSTITEM.baseuom,
                       --ST.uom,
                       nvl(in_lotno,PLT.lotnumber),
                       in_label,
                       ST.shippingtype,
                       TASK.tasktype,
                       ST.picktotype,
                       ST.fromloc,
							  rowidtochar(ST.rowid),
                       null,
                       null,
                       null,
                       in_serialno,
                       in_user1,
                       in_user2,
                       in_user3,
                       ST.pickuom,
                       in_pickqty,
                       in_weight,
                       ST.lpid,
                       lp_count,
                       chk_error,
                       errmsg);


	if errmsg is null then
      out_errmsg := 'OKAY';
	else
		out_errmsg := errmsg;
	end if;


END pick_subtask;


----------------------------------------------------------------------
--
-- stage_plate
--
----------------------------------------------------------------------
PROCEDURE stage_plate
(
    in_taskid       IN      number,
    in_lpid         IN      varchar2,
    in_loc          IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
) IS
  TASK tasks%rowtype;
  ST subtasks%rowtype;
  CUST customer%rowtype;
  PLT plate%rowtype;
  LOC location%rowtype;
  OH orderhdr%rowtype;

  chk_error  varchar2(10);
  errmsg     varchar2(100);

   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   l_is_loaded varchar2(1);
BEGIN
    out_errmsg := 'OKAY';

-- Verify taskid
    TASK := null;
    OPEN C_TASK(in_taskid);
    FETCH C_TASK into TASK;
    CLOSE C_TASK;

    if TASK.taskid is null then
       out_errmsg := 'Invalid taskid. Does not exist.';
       return;
    end if;

-- Get Order Info
    OH := null;
    OPEN C_ORDHDR(TASK.orderid, TASK.shipid);
    FETCH C_ORDHDR into OH;
    CLOSE C_ORDHDR;

    if (TASK.tasktype not in ('OP','SO')) and
       not (TASK.tasktype = 'PK' and OH.ordertype in ('U','T')) then
       out_errmsg := 'Invalid taskid. Only valid for order and sort picks.';
       return;
    end if;

-- Get customer info for this pick task
    CUST := null;
    OPEN C_CUST(TASK.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    if CUST.custid is null then
        out_errmsg := 'Customer '||TASK.custid||' does not exist';
        return;
    end if;


-- Check pick loc is a picking loc for same item???
   LOC := null;
   if in_loc is null then
      out_errmsg := 'Require a location to stage picks to.';
      return;
   end if;

   OPEN C_LOCATION(TASK.facility, in_loc);
   FETCH C_LOCATION into LOC;
   CLOSE C_LOCATION;

   if LOC.locid is null then
      out_errmsg := 'Invalid location. Does not exist.';
      return;
   end if;

--   if LOC.loctype != 'PF' then
--      out_errmsg := 'Invalid location. Must pick from pick front.';
--      return;
--   end if;

-- Determine plate type and if it exists
   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, errmsg);
   if (errmsg is not null) then
      out_errmsg := errmsg;
      return;
   end if;

--   zut.prt('Top Plate: '||topid||'/'||toptype);
--   zut.prt('Parent   : '||parentid||'/'||parenttype);
--   zut.prt('Xref     : '||xrefid||'/'||xreftype);

	zrfpk.stage_a_plate(in_lpid,
                       in_loc,
                       in_user,
                       TASK.tasktype,
							  'N',
                       in_loc,
                       'N',
                       'N',
                       chk_error,
                       errmsg,
                       l_is_loaded);

--   zut.prt('CHK:'||chk_error||' MSG:'||errmsg);

	if errmsg is not null then
   	out_errmsg := errmsg;
	else
   	out_errmsg := 'OKAY';
   end if;

END stage_plate;

procedure confirm_picks_for_load
(in_loadno IN number
,in_stageloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is
l_msg varchar2(255);
l_rfpk_msg varchar2(255);
l_label plate.lpid%type;
begin
out_errorno := 0;
out_msg := 'OKAY';
for stsk in (select wave, taskid, custid, orderid, shipid, fromloc, lpid, 
                    item, pickqty, pickuomabbrev, orderlot, weight, shippinglpid,
                    shippingtype, facility
               from subtasksview
              where loadno = in_loadno)
loop
  if stsk.shippingtype = 'P' then
    zrf.get_next_lpid(l_label, l_msg);
  else
    l_label := null;
  end if;
  zpe.pick_subtask(stsk.taskid, stsk.shippinglpid, stsk.lpid, stsk.fromloc,
     stsk.pickqty, null, l_label, null, stsk.orderlot, null, null, null, in_userid,
     stsk.weight, l_rfpk_msg);
  if l_rfpk_msg <> 'OKAY' then
    zms.log_autonomous_msg('CONFPICK',
          stsk.facility,
          stsk.custid,
          l_label || ' ' || stsk.orderid || '-' || stsk.shipid || ' ' ||
                          stsk.item || ' ' || stsk.lpid || ' ' || l_rfpk_msg,
          'E',
          in_userid,
          l_msg);
    rollback;
    goto continue_stsk_loop;
  end if;
  zpe.stage_plate(stsk.taskid, stsk.shippinglpid, in_stageloc, in_userid, l_rfpk_msg);
  if substr(l_rfpk_msg,1,4) <> 'OKAY' then
    zms.log_autonomous_msg('STGPICK',
          stsk.facility,
          stsk.custid,
          l_label || ' ' || stsk.orderid || '-' || stsk.shipid || ' ' ||
                          stsk.item || ' ' || stsk.lpid || ' ' || l_rfpk_msg,
          'E',
          in_userid,
          l_msg);
    rollback;
    goto continue_stsk_loop;
  end if;
  commit;
  << continue_stsk_loop >>
    null;
end loop;
exception when others then
  out_errorno := sqlcode;
  out_msg := 'cpfl ' || sqlerrm;
end confirm_picks_for_load;
procedure load_plates_for_load
(in_facility IN varchar2
,in_loadno IN number
,in_doorloc IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
)
is
l_msg varchar2(255);
l_rfld_msg varchar2(255);
l_overage varchar2(1);
begin
out_errorno := 0;
out_msg := 'OKAY';
zlod.crt_start_loading(in_facility, in_doorloc, in_loadno, l_overage, l_rfld_msg);
if substr(l_rfld_msg,1,4) <> 'OKAY' then
  out_errorno := -1;
  out_msg := in_loadno || ' ' || l_rfld_msg;
  zms.log_autonomous_msg('STARTLOAD',
        in_facility,
        null,
        out_msg,
        'E',
        in_userid,
        l_msg);
end if;
for slip in (select parentlpid, lpid, fromlpid,
                    item, lotnumber, serialnumber,
                    quantity, unitofmeasure, 
                    loadno, stopno, status,
                    location, facility, custid, orderid, shipid
               from shippingplate
              where loadno = in_loadno and stopno > 0
                and facility = in_facility
                and parentlpid is null)
loop
  zlod.load_plate(slip.facility, slip.location, in_doorloc, in_loadno, slip.stopno,
                  slip.lpid, in_userid, l_rfld_msg);
  if substr(l_rfld_msg,1,4) <> 'OKAY' then
    zms.log_autonomous_msg('LODPICK',
          slip.facility,
          slip.custid,
          slip.fromlpid || ' ' || slip.orderid || '-' || slip.shipid || ' ' ||
                          slip.item || ' ' || slip.lpid || ' ' || l_rfld_msg,
          'E',
          in_userid,
          l_msg);
    rollback;
    goto continue_slip_loop;
  end if;
  commit;
<< continue_slip_loop >>
  null;  
end loop;
exception when others then
  out_errorno := sqlcode;
  out_msg := 'lpfl ' || sqlerrm;
end load_plates_for_load;
end zpickentry;
/
show error package body zpickentry;
exit;
