create or replace package body alps.zloadplates as
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

-- Add LPID Actions
AC_NONE         CONSTANT        integer := 0;
AC_INSERT       CONSTANT        integer := 1; -- Create new PA
AC_UPDATE       CONSTANT        integer := 2; -- Update existing PA
AC_ATTACH       CONSTANT        integer := 3; -- Attach to TOTE ???
AC_MIX          CONSTANT        integer := 4; -- Morph

-- MLPID Actions
MAC_NONE        CONSTANT        integer := 0; -- No MLPID
MAC_CREATE      CONSTANT        integer := 1; -- Create New MLPID
MAC_ADD         CONSTANT        integer := 2; -- Add to existing

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
CURSOR C_ORDHDR(in_orderid number, in_shipid number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE orderid = in_orderid
       AND shipid = in_shipid;

----------------------------------------------------------------------
CURSOR C_ORDDTL(in_orderid number, in_shipid number,
       in_item varchar2, in_lot varchar2)
RETURN orderdtl%rowtype
IS
    SELECT *
      FROM orderdtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item
       AND nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');

----------------------------------------------------------------------
CURSOR C_LOADS(in_loadno varchar2)
RETURN loads%rowtype
IS
    SELECT *
      FROM loads
     WHERE loadno = in_loadno;

----------------------------------------------------------------------
CURSOR C_CONSIGNEE(in_consignee varchar2)
RETURN consignee%rowtype
IS
    SELECT *
      FROM consignee
     WHERE consignee = in_consignee;

----------------------------------------------------------------------
CURSOR C_CARRIER(in_carrier varchar2)
RETURN carrier%rowtype
IS
    SELECT *
      FROM carrier
     WHERE carrier = in_carrier;

----------------------------------------------------------------------
CURSOR C_CUST(in_custid varchar2)
RETURN customer%rowtype
IS
    SELECT *
      FROM customer
     WHERE custid = in_custid;

----------------------------------------------------------------------
CURSOR C_SHIPPLATE(in_shiplpid varchar2)
RETURN shippingplate%rowtype
IS
    SELECT *
      FROM shippingplate
     WHERE lpid = in_shiplpid;

----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
CURSOR C_CUSTITEMV(in_custid varchar2, in_item varchar2)
RETURN custitemview%rowtype
IS
    SELECT *
      FROM custitemview
     WHERE custid = in_custid
       AND item = in_item;

----------------------------------------------------------------------
CURSOR C_LOCATION(in_facility varchar2, in_locid varchar2)
RETURN location%rowtype
IS
    SELECT *
      FROM location
     WHERE facility = in_facility
       AND locid = in_locid;

----------------------------------------------------------------------



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
--
-- crt_start_loading_real
--
----------------------------------------------------------------------
PROCEDURE crt_start_loading_real
(
    in_facility  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    in_opt_status IN     varchar2,
    out_overage  OUT     varchar2,
    out_errmsg   OUT     varchar2
)
IS
  cursor c_ld is
     select sum(nvl(qtyship,0)) as qtyship,
            sum(nvl(qtypick,0)) as qtypick,
            sum(nvl(qtycommit,0)) as qtycommit,
            sum(nvl(qtyorder,0)) as qtyorder
        from orderhdr
        where loadno = in_loadno
          and fromfacility = in_facility;
  ld c_ld%rowtype;

  LOAD  loads%rowtype;
  STAGE location%rowtype;
  DOCK  location%rowtype;

  errmsg varchar2(100);

BEGIN
   out_errmsg := 'OKAY';
   out_overage := 'N';



-- Validate dock location
   DOCK := null;
   OPEN C_LOCATION(in_facility, in_dockloc);
   FETCH C_LOCATION into DOCK;
   CLOSE C_LOCATION;
   if DOCK.locid is null then
      out_errmsg := 'Invalid dock door location';
      return;
   end if;

   if DOCK.loctype != 'DOR' then
      out_errmsg := 'Dock Location not a door.';
      return;
   end if;

-- Validate Load
   LOAD := null;
   OPEN C_LOADS(in_loadno);
   FETCH C_LOADS into LOAD;
   CLOSE C_LOADS;

   if LOAD.loadno is null then
      out_errmsg := 'Load not found.';
      return;
   end if;

   if nvl(LOAD.doorloc,'XX') != in_dockloc then
      out_errmsg := 'Load not at door.';
      return;
   end if;

   if substr(LOAD.loadtype,1,1) != 'O' then
      out_errmsg := 'Load not outbound type.';
      return;
   end if;

   open c_ld;
   fetch c_ld into ld;
   close c_ld;
   if (ld.qtypick + ld.qtycommit) > ld.qtyorder then
      out_overage := 'Y';
   end if;

   if (LOAD.loadstatus = zrf.LOD_LOADED)
   and ((ld.qtyship != ld.qtypick) or (ld.qtycommit != 0)) then
      return;
   end if;

   if (LOAD.loadstatus not in (zrf.LOD_PICKED, zrf.LOD_LOADING, in_opt_status)) then
      out_errmsg := 'Load status not picked or loading.';
      return;
   end if;

EXCEPTION when others then
  out_errmsg := sqlerrm;

END crt_start_loading_real;


----------------------------------------------------------------------
--
-- crt_start_loading
--
----------------------------------------------------------------------
PROCEDURE crt_start_loading
(
    in_facility  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    out_overage  OUT     varchar2,
    out_errmsg   OUT     varchar2
)
IS
BEGIN
    crt_start_loading_real(in_facility, in_dockloc, in_loadno, 'xx',
        out_overage, out_errmsg);
END crt_start_loading;

----------------------------------------------------------------------
--
-- load_plate_real
--
----------------------------------------------------------------------
PROCEDURE load_plate_real
(
    in_facility  IN      varchar2,
    in_stageloc  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_lpid      IN      varchar2,
    in_user      IN      varchar2,
    in_opt_status IN     varchar2,
    out_errmsg   OUT     varchar2
)
IS

   cursor c_upd_dtl(in_lpid varchar2) is
      select P.orderid, P.shipid, P.shipno, P.quantity, P.orderitem,
             P.orderlot, P.weight,
             zci.item_cube(P.custid, P.orderitem, P.unitofmeasure) cube, I.useramt1,
             X.allow_overpicking
         from shippingplate P, custitem I, customer_aux X
         where P.facility||'' = in_facility
           and P.location = in_stageloc
           and P.lpid in (select lpid from shippingplate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid)
           and P.type in ('F', 'P')
           and P.loadno = in_loadno
           and P.stopno = in_stopno
           and P.status = 'S'
           and I.custid = P.custid
           and I.item = P.orderitem
           and X.custid = P.custid;

   cursor c_upd_hdr(in_lpid varchar2) is
      select distinct P.orderid, P.shipid, O.qtypick, O.qtyship, O.orderstatus, O.qtycommit
         from shippingplate P, orderhdr O
         where P.facility||'' = in_facility
           and P.location = in_stageloc
           and P.lpid in (select lpid from shippingplate
                              start with lpid = in_lpid
                              connect by prior lpid = parentlpid)
           and P.type in ('F', 'P')
           and P.loadno = in_loadno
           and P.stopno = in_stopno
           and P.status = 'S'
           and O.orderid = P.orderid
           and O.shipid = P.shipid
           and O.orderstatus >= zrf.ORD_PICKING;

   cursor c_lp(in_lpid varchar2) is
      select rowid, fromlpid, type
         from shippingplate
         where facility = in_facility
           and location = in_stageloc
           and loadno = in_loadno
           and stopno = in_stopno
           and lpid = in_lpid
           and status = 'S'
           and parentlpid is null;

   cursor c_ld is
      select sum(nvl(qtyship,0)) as qtyship,
             sum(nvl(qtypick,0)) as qtypick,
             sum(nvl(qtycommit,0)) as qtycommit,
             sum(nvl(qtyorder,0)) as qtyorder
         from orderhdr
        where loadno = in_loadno
          and fromfacility = in_facility;
   ld c_ld%rowtype;

   cursor c_lod is
      select carrier, trailer
        from loads
       where loadno = in_loadno;
   lod c_lod%rowtype;

   neworderstatus orderhdr.orderstatus%type;
   newloadstopstatus loadstop.loadstopstatus%type;
   newloadstatus loads.loadstatus%type;
   msg varchar(80);
   aType trailer.activity_type%type;

  LOAD  loads%rowtype;
  STAGE location%rowtype;
  DOCK  location%rowtype;

  SP    shippingplate%rowtype;

   l_qtyorder orderdtl.qtyorder%type;
   l_qtyship orderdtl.qtyship%type;

BEGIN
  out_errmsg := 'OKAY';

-- Validate stage location
   STAGE := null;
   OPEN C_LOCATION(in_facility, in_stageloc);
   FETCH C_LOCATION into STAGE;
   CLOSE C_LOCATION;
   if STAGE.locid is null then
      out_errmsg := 'Invalid staging location';
      return;
   end if;

-- Validate dock location
   DOCK := null;
   OPEN C_LOCATION(in_facility, in_dockloc);
   FETCH C_LOCATION into DOCK;
   CLOSE C_LOCATION;
   if DOCK.locid is null then
      out_errmsg := 'Invalid dock door location';
      return;
   end if;

   if DOCK.loctype != 'DOR' then
      out_errmsg := 'Dock Location not a door.';
      return;
   end if;

-- Validate Load
   LOAD := null;
   OPEN C_LOADS(in_loadno);
   FETCH C_LOADS into LOAD;
   CLOSE C_LOADS;

   if LOAD.loadno is null then
      out_errmsg := 'Load not found.';
      return;
   end if;

   if LOAD.doorloc != in_dockloc then
      out_errmsg := 'Load not at door.';
      return;
   end if;

   if substr(LOAD.loadtype,1,1) != 'O' then
      out_errmsg := 'Load not outbound type.';
      return;
   end if;

   if (LOAD.loadstatus not in (zrf.LOD_PICKING, zrf.LOD_PICKED, zrf.LOD_LOADING, in_opt_status)) then
      open c_ld;
      fetch c_ld into ld;
      close c_ld;
      if (LOAD.loadstatus = zrf.LOD_LOADED)
      and ((ld.qtyship != ld.qtypick) or (ld.qtycommit != 0)) then
         null;
      else
         out_errmsg := 'Load status not picked or loading.';
         return;
      end if;
   end if;

-- Now ready to load the plate

-- Get the shipping plate to load
   SP := null;
   OPEN C_SHIPPLATE(in_lpid);
   FETCH C_SHIPPLATE INTO SP;
   CLOSE C_SHIPPLATE;

   if SP.lpid is null then
      out_errmsg := 'Invalid ship plate.';
      return;
   end if;

   if SP.type not in ('C', 'F', 'M') then
      out_errmsg := 'Ship plate not carton, full or master';
      return;
   end if;

   if zcu.credit_hold(SP.custid) = 'Y' then
       out_errmsg := 'Cannot load plate-- Customer '||SP.custid||' is on credit hold';
       return;
   end if;

-- update detail data first
   for d in c_upd_dtl(SP.lpid) loop
      update orderdtl
         set qtyship = nvl(qtyship, 0) + d.quantity,
             weightship = nvl(weightship, 0) + d.weight,
             cubeship = nvl(cubeship, 0) + (d.quantity * d.cube),
             amtship = nvl(amtship, 0) + (d.quantity * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = d.orderid
           and shipid = d.shipid
           and item = d.orderitem
           and nvl(lotnumber, '(none)') = nvl(d.orderlot, '(none)')
         returning qtyorder, qtyship into l_qtyorder, l_qtyship;

      if (l_qtyship > l_qtyorder) and (nvl(d.allow_overpicking,'N') != 'Y') then
         out_errmsg := 'Plate would cause shipped qty to exceed ordered qty';
         return;
      end if;

      update loadstopship
         set qtyship = nvl(qtyship, 0) + d.quantity,
             weightship = nvl(weightship, 0) + d.weight,
             cubeship = nvl(cubeship, 0) + (d.quantity * d.cube),
             amtship = nvl(amtship, 0) + (d.quantity * zci.item_amt(null,d.orderid,d.shipid,d.orderitem,d.orderlot)),
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = in_stopno
           and shipno = d.shipno;
   end loop;

-- update order header data next
   for h in c_upd_hdr(SP.lpid) loop
      zoc.order_check_required(h.orderid, h.shipid, out_errmsg);
      if (out_errmsg <> 'OKAY') then
        return;
      end if;
      if ((h.qtyship = h.qtypick) and (h.qtycommit = 0)) then
         neworderstatus := zrf.ORD_LOADED;
      else
         neworderstatus := zrf.ORD_LOADING;
      end if;

      if (neworderstatus != h.orderstatus) then
         update orderhdr
            set orderstatus = neworderstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where orderid = h.orderid
              and shipid = h.shipid;
      end if;
     zoh.add_orderhistory_item(h.orderid, h. shipid, SP.lpid,
         SP.item, SP.lotnumber, 'Load Plate',
         'Load plate Qty '||SP.quantity, in_user, msg);

   end loop;


-- update the load data
   select min(orderstatus) into newloadstopstatus
      from orderhdr
      where loadno = in_loadno
        and stopno = in_stopno;
   if (newloadstopstatus > zrf.LOD_PICKED) then
      update loadstop
         set loadstopstatus = newloadstopstatus,
             lastuser = in_user,
             lastupdate = sysdate
         where loadno = in_loadno
           and stopno = in_stopno
           and loadstopstatus < newloadstopstatus;
--    if the stop didn't change, the load won't
--    if (sql%rowcount != 0) then
         select min(loadstopstatus) into newloadstatus
            from loadstop
            where loadno = in_loadno;
         update loads
            set loadstatus = newloadstatus,
                lastuser = in_user,
                lastupdate = sysdate
            where loadno = in_loadno
              and loadstatus < newloadstatus;
         if newloadstatus = zrf.LOD_LOADING or
            newloadstatus = zrf.LOD_LOADED then
            lod := null;
            open c_lod;
            fetch c_lod into lod;
            close c_lod;
            if newloadstatus = zrf.LOD_LOADING then
               aType := 'LDN';
            else
               aType := 'LOD';
            end if;
            begin
               update trailer
                  set activity_type = aType,
                      contents_status = newloadstatus,
                      lastuser = in_user,
                      lastupdate = sysdate
                where carrier = lod.carrier
                  and trailer_number = lod.trailer
                  and loadno = in_loadno
                  and contents_status <> newloadstatus;
            exception when no_data_found then
               null;
            end;
         end if;

--    end if;
   end if;

-- move the shippingplates
   for l in c_lp(in_lpid) loop
      zrf.move_shippingplate(l.rowid, in_dockloc, 'L', in_user, null, msg);
      if (msg is not null) then
         out_errmsg := msg;
         return;
      end if;

--    delete any deconsolidation moves
      if l.type = 'F' then
         delete tasks
            where lpid = l.fromlpid
              and facility = in_facility
              and tasktype = 'MV';
         if sql%rowcount != 0 then
            delete subtasks
               where lpid = l.fromlpid
                 and facility = in_facility
                 and tasktype = 'MV';
         end if;
      end if;
   end loop;


EXCEPTION when others then
  out_errmsg := sqlerrm;

END load_plate_real;

----------------------------------------------------------------------
--
-- load_plate
--
----------------------------------------------------------------------
PROCEDURE load_plate
(
    in_facility  IN      varchar2,
    in_stageloc  IN      varchar2,
    in_dockloc   IN      varchar2,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_lpid      IN      varchar2,
    in_user      IN      varchar2,
    out_errmsg   OUT     varchar2
)
IS
BEGIN
    load_plate_real(in_facility, in_stageloc, in_dockloc,
        in_loadno, in_stopno, in_lpid, in_user, 'xx',
        out_errmsg);

END load_plate;

----------------------------------------------------------------------
--
-- check_plate_load - This procedure is to load a plate if the customer
--      is set to load on label print, and if the order goes to loaded
--      to request the packlist
--
----------------------------------------------------------------------
procedure check_plate_load
   (in_lpid        in varchar2,
    in_termid      in varchar2,
    in_userid      in varchar2,
    out_message    out varchar2)
is

errno number;
errmsg varchar2(255);

l_lpid plate.lpid%type;

lptype plate.type%type;
xrefid plate.lpid%type;
xreftype plate.type%type;
parentid plate.lpid%type;
parenttype plate.type%type;
topid plate.lpid%type;
toptype plate.type%type;

l_overage varchar2(1);


CURSOR C_SP(in_lpid varchar2)
IS
select lpid, custid, facility, orderid, shipid, loadno, stopno, location
from shippingplate
where lpid = in_lpid;

SP C_SP%rowtype;

CURSOR C_CA(in_custid varchar2)
IS
select load_plate_on_label
from customer_aux
where custid = in_custid;

CA C_CA%rowtype;

ORD C_ORDHDR%rowtype;

LD C_LOADS%rowtype;

CURSOR C_TRM(in_fac varchar2, in_termid varchar2)
RETURN multishipterminal%rowtype
IS
    SELECT *
      FROM multishipterminal
     WHERE facility = in_fac
       AND termid = in_termid;

TRM C_TRM%rowtype;

l_prt varchar2(255);
l_cnt pls_integer;
l_termid varchar2(255);

CUST customer%rowtype;
CARR carrier%rowtype;
PROCEDURE appmsg(in_msg varchar2)
IS
BEGIN
    zms.log_msg('LABELLD',SP.facility, ORD.custid, in_msg,'W',in_userid,
        errmsg);
EXCEPTION WHEN OTHERS THEN
    null;
END;

procedure get_rfprinter
   (in_orderid in number,
    in_shipid  in number,
    out_prt    out varchar2)
is
   cursor c_sp(p_orderid number, p_shipid number) is
      select H.lastupdate as lastupdate, H.lastuser as lastuser, S.facility as facility
         from shippingplate S, shippingplatehistory H
         where S.orderid = p_orderid
           and S.shipid = p_shipid
           and H.lpid = S.lpid
           and H.status = 'S'
      union
      select lastupdate, lastuser, facility
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and status = 'S'
      order by 1 desc;
   sp c_sp%rowtype := null;
   cursor c_uh(p_userid varchar2) is
      select rptprinter
         from userheader
         where nameid = p_userid;
   uh c_uh%rowtype := null;
   cursor c_pr(p_facility varchar2, p_prtid varchar2) is
      select winshare
         from printer
         where facility = p_facility
           and prtid = p_prtid;
begin
   out_prt := null;

   open c_sp(in_orderid, in_shipid);
   fetch c_sp into sp;
   close c_sp;
   if sp.lastuser is not null then
      open c_uh(sp.lastuser);
      fetch c_uh into uh;
      close c_uh;
      if uh.rptprinter is not null then
         open c_pr(sp.facility, uh.rptprinter);
         fetch c_pr into out_prt;
         close c_pr;
      end if;
   end if;
end get_rfprinter;

procedure get_terminalid
   (in_orderid in number,
    in_shipid  in number,
    out_termid out varchar2)
is
   cursor c_sp(p_orderid number, p_shipid number) is
      select H.lastupdate as lastupdate, S.fromlpid as fromlpid
         from shippingplate S, shippingplatehistory H
         where S.orderid = p_orderid
           and S.shipid = p_shipid
           and S.parentlpid is null
           and H.lpid = S.lpid
           and H.status = 'S'
      union
      select lastupdate, fromlpid
         from shippingplate
         where orderid = p_orderid
           and shipid = p_shipid
           and parentlpid is null
           and status = 'S'
      order by 1 desc;
   sp c_sp%rowtype := null;
   cursor c_md(p_orderid number, p_shipid number, p_cartonid varchar2) is
      select termid
         from multishipdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and cartonid = p_cartonid;
begin
   out_termid := null;

   open c_sp(in_orderid, in_shipid);
   fetch c_sp into sp;
   close c_sp;
   if sp.fromlpid is not null then
      open c_md(in_orderid, in_shipid, sp.fromlpid);
      fetch c_md into out_termid;
      close c_md;
   end if;
end get_terminalid;

begin
    out_message := '';

    if in_termid = '(none)' then
        l_termid := null;
    else
        l_termid := in_termid;
    end if;

    zrf.identify_lp(in_lpid, lptype, xrefid, xreftype,
      parentid, parenttype, topid, toptype, out_message);

    l_lpid := null;

    if lptype = 'XP' then
        l_lpid := xrefid;
    end if;
    if lptype in ('C','F','M','P') then
        l_lpid := in_lpid;
    end if;

    if l_lpid is null then
        out_message := 'Invalid lp type:'||lptype;
        appmsg(out_message);
        return;
    end if;

    SP := null;
    OPEN C_SP(l_lpid);
    FETCH C_SP into SP;
    CLOSE C_SP;

    if SP.custid is null then
        out_message := 'Invalid lp:'||l_lpid;
        appmsg(out_message);
        return;
    end if;

    if zcu.credit_hold(SP.custid) = 'Y' then
       out_message := 'Cannot load plate-- Customer '||SP.custid||' is on credit hold';
       appmsg(out_message);
       return;
    end if;

    CA := null;
    OPEN C_CA(SP.custid);
    FETCH C_CA into CA;
    CLOSE C_CA;

    if nvl(CA.load_plate_on_label,'N') != 'Y' then
        out_message := 'Not a load on label customer';
--        appmsg(out_message);
        return;
    end if;

-- Load the plate specified
    ORD := null;
    OPEN C_ORDHDR(SP.orderid, SP.shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

    if ORD.orderid is null then
        out_message := 'Invalid Order';
        appmsg(out_message);
        return;
    end if;

    if ORD.shiptype = 'S' then
        CARR := null;
        OPEN C_CARRIER(ORD.carrier);
        FETCH C_CARRIER into CARR;
        CLOSE C_CARRIER;
        if nvl(CARR.multiship,'N') != 'Y' then
            select count(1) into l_cnt
               from shippingplate
               where orderid = SP.orderid
                 and shipid = SP.shipid
                 and status in ('U','P','FA');
            if l_cnt = 0 then    -- everything at least staged
               get_terminalid(SP.orderid, SP.shipid, l_termid);
               goto bypass_loading;
            end if;
        end if;
        out_message := 'Small Package Ship Type';
        -- appmsg(out_message);
        return;
    end if;

    if ORD.loadno is null then
        out_message := 'Order not assigned to load';
        appmsg(out_message);
        return;
    end if;

--
    LD := null;
    OPEN C_LOADS(ORD.loadno);
    FETCH C_LOADS into LD;
    CLOSE C_LOADS;

    if LD.loadno is null then
        out_message := 'Invalid Load';
        appmsg(out_message);
        return;
    end if;

    if LD.doorloc is null then
        out_message := 'Load not assigned to door';
        appmsg(out_message);
        return;
    end if;


    if nvl(LD.stageloc,'noload') != nvl(SP.location,'nosp') then
        appmsg('Plate location:'|| nvl(SP.location,'(none)')
            || ' does not match the load stage loc:'
            || nvl(LD.stageloc,'(none)'));
    end if;


    crt_start_loading_real(LD.facility, LD.doorloc, LD.loadno, zrf.LOD_PICKING,
        l_overage, out_message);

    if out_message != 'OKAY' then
        appmsg(out_message);
        return;
    end if;

    load_plate_real(LD.facility, SP.location, LD.doorloc,
        LD.loadno, nvl(SP.stopno,1), SP.lpid, in_userid, zrf.LOD_PICKING,
        out_message);

    if out_message != 'OKAY' then
        appmsg(out_message);
        return;
    end if;

    ORD := null;
    OPEN C_ORDHDR(SP.orderid, SP.shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

    if ORD.orderstatus != '8' then       -- Loaded
        out_message := 'Not Loaded : '||ORD.orderstatus;
        return;
    end if;

-- Order is loaded so try to do the stuff.
<<bypass_loading>>
    l_prt := null;

    if l_termid is not null then
        TRM := null;
        OPEN C_TRM(SP.facility, l_termid);
        FETCH C_TRM into TRM;
        CLOSE C_TRM;
        l_prt := TRM.packprinter;
    else
        get_rfprinter(ORD.orderid, ORD.shipid, l_prt);
    end if;

    if l_prt is null then
        begin
            select packlistprinter
              into l_prt
              from custfacility
             where custid = ORD.custid
              and facility = SP.facility;
        exception when others then
            l_prt := null;
        end;
    end if;

    if l_prt is null then
        out_message := 'No printer located';
        appmsg(out_message);
        return;
    end if;


  -- Check customer if printing pack list
    CUST := null;
    OPEN C_CUST(ORD.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

    zcu.pack_list_format(ORD.orderid,ORD.shipid,CUST.packlist,CUST.packlistrptfile);

    if CUST.packlistrptfile is not null then
        if CUST.packlist = 'S' then
          zvm.send_vics_bol_request('MULTI',
            0,
            ORD.orderid,
            ORD.shipid,
            'PACK',
            l_prt,
            errno,
            errmsg);
        else
          zmnq.send_shipping_msg(ORD.orderid,
                          ORD.shipid,
                          l_prt,
                          CUST.packlistrptfile,
                          '',
						  '',
                          errmsg);
        end if;
    end if;


exception
   when OTHERS then
      out_message := substr(sqlerrm, 1, 80);
end check_plate_load;


end zloadplates;
/

show errors package body zloadplates;
exit;
