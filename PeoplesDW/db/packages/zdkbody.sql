create or replace package body alps.zdekit as
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
-- insert_plate -
--
----------------------------------------------------------------------
FUNCTION insert_plate
(
   NLP         IN  plate%rowtype,
   out_errmsg  OUT varchar2
)
RETURN BOOLEAN
IS
errmsg varchar2(100);
BEGIN

    out_errmsg := 'OKAY';

   INSERT INTO PLATE
   (
      lpid,
      item,
      custid,
      facility,
      location,
      status,
      unitofmeasure,
      quantity,
      type,
      serialnumber,
      lotnumber,
      useritem1,
      useritem2,
      useritem3,
      creationdate,
      condition,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      loadno,
      stopno,
      shipno,
      qtyentered,
      itementered,
      uomentered,
      parentlpid,
      weight,
      countryof,
      expirationdate,
      manufacturedate,
      expiryaction,
      po,
      lastoperator,
      disposition,
      qtyrcvd,
      parentfacility,
      parentitem,
      recmethod,
      fromlpid,
      anvdate,
      lastuser,
      lastupdate
   )
   VALUES
   (
      NLP.lpid,
      NLP.item,
      NLP.custid,
      NLP.facility,
      NLP.location,
      NLP.status,
      NLP.unitofmeasure,
      NLP.quantity,
      NLP.type,
      NLP.serialnumber,
      NLP.lotnumber,
      NLP.useritem1,
      NLP.useritem2,
      NLP.useritem3,
      sysdate,
      NLP.condition,
      substr(NLP.invstatus,1,2),
      substr(NLP.inventoryclass,1,2),
      NLP.orderid,
      NLP.shipid,
      NLP.loadno,
      NLP.stopno,
      NLP.shipno,
      NLP.qtyentered,
      NLP.itementered,
      NLP.uomentered,
      NLP.parentlpid,
      NLP.weight,
      NLP.countryof,
      NLP.expirationdate,
      NLP.manufacturedate,
      NLP.expiryaction,
      NLP.po,
      NLP.lastoperator,
      NLP.disposition,
      NLP.qtyrcvd,
      NLP.parentfacility,
      NLP.parentitem,
      NLP.recmethod,
      NLP.fromlpid,
      NLP.anvdate,
      NLP.lastuser,
      sysdate
   );

   return TRUE;

EXCEPTION WHEN OTHERS THEN
   out_errmsg := sqlerrm;
   return FALSE;

END insert_plate;



----------------------------------------------------------------------
--
-- update_plate -
--
----------------------------------------------------------------------
FUNCTION update_plate
(
   LP          IN  plate%rowtype,
   ITEM        IN  custitemview%rowtype,
   qty         IN  number,
   in_qty      IN  number,
   in_weight   IN  number,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
)
RETURN BOOLEAN
IS
errmsg varchar2(100);
BEGIN

    out_errmsg := 'OKAY';

      update plate
         set quantity = quantity + qty,
             lastoperator = in_user,
             lasttask = null,
             lastuser =  in_user,
             lastupdate = sysdate,
             qtyentered = nvl(qtyentered, 0) + in_qty,
             weight = nvl(weight, 0) + in_weight,
             qtyrcvd = nvl(qtyrcvd, 0) + qty
         where lpid = LP.lpid;
      if LP.parentlpid is not null then
              update plate
                      set quantity = nvl(quantity, 0) + qty,
                weight = nvl(weight, 0) + in_weight,
                     lastoperator = in_user,
                lastuser =  in_user,
                lastupdate = sysdate
            where lpid = LP.parentlpid;
      end if;

      return TRUE;

EXCEPTION WHEN OTHERS THEN
   out_errmsg := sqlerrm;
   return FALSE;

END update_plate;



----------------------------------------------------------------------
--
-- compatible_plates - check if two plates are compatible (combineable)
--
----------------------------------------------------------------------
FUNCTION compatible_plates
(
   in_lp1       IN  plate%rowtype,
   in_lp2       IN  plate%rowtype,
   out_errmsg   OUT varchar2
)
RETURN BOOLEAN
IS
BEGIN
    if in_lp1.custid != in_lp2.custid then
       out_errmsg := 'Incompatible customer';
       return FALSE;
    end if;
    if in_lp1.item != in_lp2.item then
       out_errmsg := 'Incompatible item';
       return FALSE;
    end if;
    if in_lp2.holdreason is not null then
       out_errmsg := 'Incompatible hold reason';
       return FALSE;
    end if;
    if in_lp1.unitofmeasure != in_lp2.unitofmeasure then
       out_errmsg := 'Incompatible unit of measure';
       return FALSE;
    end if;
    if nvl(in_lp1.serialnumber,'<NONE>')
           != nvl(in_lp2.serialnumber,'<NONE>') then
       out_errmsg := 'Incompatible serial number';
       return FALSE;
    end if;
    if nvl(in_lp1.lotnumber,'<NONE>') != nvl(in_lp2.lotnumber,'<NONE>') then
       out_errmsg := 'Incompatible lot number';
       return FALSE;
    end if;
    if nvl(in_lp1.manufacturedate,to_date('19900101','YYYYMMDD'))
          != nvl(in_lp2.manufacturedate,to_date('19900101','YYYYMMDD')) then
       out_errmsg := 'Incompatible manufacture date';
       return FALSE;
    end if;
    if nvl(in_lp1.expirationdate,to_date('19900101','YYYYMMDD'))
          != nvl(in_lp2.expirationdate,to_date('19900101','YYYYMMDD')) then
       out_errmsg := 'Incompatible expiration';
       return FALSE;
    end if;
    if in_lp2.condition is not null then
       out_errmsg := 'Incompatible condition';
       return FALSE;
    end if;
    if nvl(in_lp1.countryof,'<NONE>') != nvl(in_lp2.countryof,'<NONE>') then
       out_errmsg := 'Incompatible origin';
       return FALSE;
    end if;
    if nvl(in_lp1.useritem1,'<NONE>') != nvl(in_lp2.useritem1,'<NONE>') then
       out_errmsg := 'Incompatible user item 1';
       return FALSE;
    end if;
    if nvl(in_lp1.useritem2,'<NONE>') != nvl(in_lp2.useritem2,'<NONE>') then
       out_errmsg := 'Incompatible user item 2';
       return FALSE;
    end if;
    if nvl(in_lp1.useritem3,'<NONE>') != nvl(in_lp2.useritem3,'<NONE>') then
       out_errmsg := 'Incompatible user item 3';
       return FALSE;
    end if;
    if in_lp1.invstatus != in_lp2.invstatus then
       out_errmsg := 'Incompatible inventory status';
       return FALSE;
    end if;
    if in_lp1.inventoryclass != in_lp2.inventoryclass then
       out_errmsg := 'Incompatible inventory class';
       return FALSE;
    end if;

    out_errmsg := 'OKAY';
    return TRUE;

END compatible_plates;



----------------------------------------------------------------------
--
-- add_restored_lpid
--
----------------------------------------------------------------------
PROCEDURE add_restored_lpid
(
    in_kitlpid   IN      varchar2,
    in_custid    IN      varchar2,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_serial    IN      varchar2,
    in_useritem1 IN      varchar2,
    in_useritem2 IN      varchar2,
    in_useritem3 IN      varchar2,
    in_countryof IN      varchar2,
    in_expdate   IN      date,
    in_mfgdate   IN      date,
    in_qty       IN      number,
    in_uom       IN      varchar2,
    in_lpid      IN      varchar2,
    in_mlpid     IN      varchar2,
    in_invstatus IN      varchar2,
    in_invclass  IN      varchar2,
    in_facility  IN      varchar2,
    in_location  IN      varchar2,
    in_user      IN      varchar2,
    in_handtype  IN      varchar2,
    in_action    IN      varchar2,
    in_weight    IN      number,
    out_errmsg   OUT     varchar2
)
IS
  LP    plate%rowtype;
  NLP   plate%rowtype;
  MLP   plate%rowtype;
  ITEM  custitemview%rowtype;
  LOC   location%rowtype;
  KLP   plate%rowtype;


  compat BOOLEAN;
  action integer;
  mp_action integer;

  qty   number;


-- idetify_lp parameters
   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   msg varchar(80);

-- idetify_lp parameters
   m_lptype plate.type%type;
   m_xrefid plate.lpid%type;
   m_xreftype plate.type%type;
   m_parentid plate.lpid%type;
   m_parenttype plate.type%type;
   m_topid plate.lpid%type;
   m_toptype plate.type%type;

   mark varchar2(10);

   cnt integer;

CURSOR C_SUBPLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE parentlpid = in_lpid;


BEGIN
   out_errmsg := 'OKAY';
   action := AC_NONE;
   mp_action := MAC_NONE;

   mark := 'BEGIN';

-- Validate LPs
   if (not zlp.is_lpid(in_lpid)) then
      out_errmsg := 'Invalid LPID';
      return;
   end if;

   mark := 'LOC';

-- Verify item is part of kit
   KLP := null;
   OPEN C_PLATE(in_kitlpid);
   FETCH C_PLATE into KLP;
   CLOSE C_PLATE;

   select count(1) into cnt
      from workordercomponents
      where custid = in_custid
        and item = KLP.item
        and (kitted_class = KLP.inventoryclass or kitted_class = 'no')
        and component = in_item;
   if (cnt = 0) then
                out_errmsg := 'Item not a component of this kit.';
      return;
   end if;

-- Validate location
   LOC := null;
   OPEN C_LOCATION(in_facility, in_location);
   FETCH C_LOCATION into LOC;
   CLOSE C_LOCATION;
   if LOC.locid is null then
      out_errmsg := 'Invalid location';
      return;
   end if;


   mark := 'ITEM';
-- Get cust item information
   ITEM := null;
   OPEN C_CUSTITEMV(in_custid, in_item);
   FETCH C_CUSTITEMV into ITEM;
   CLOSE C_CUSTITEMV;

   if ITEM.custid is null then
      out_errmsg := 'Invalid item.';
      return;
   end if;

   mark := 'MLPID';
-- If multi-lpid provided get its information
   MLP := null;
   if in_mlpid is not null then
      zrf.identify_lp(in_mlpid, m_lptype, m_xrefid, m_xreftype,
         m_parentid, m_parenttype,
         m_topid, m_toptype, msg);

      if m_lptype not in ('?','MP') then
         out_errmsg := 'MLPID is not a multi-plate.';
         return;
      end if;
      if m_lptype = 'MP' then
         OPEN C_PLATE(in_mlpid);
         FETCH C_PLATE INTO MLP;
         CLOSE C_PLATE;
         if MLP.custid != in_custid then
            out_errmsg := 'MLPID is not for this customer.';
            return;
         end if;
         if MLP.facility != in_facility then
            out_errmsg := 'MLPID is not in this facility.';
            return;
         end if;
         mp_action := MAC_ADD;
      else
         mp_action := MAC_CREATE;
      end if;
   end if;

-- Check LPID Status
   mark := 'LPID';
   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);

   mark := 'NLP';

   zbut.translate_uom(in_custid,ITEM.item,in_qty, in_uom,
    ITEM.baseuom, qty, msg);
   if substr(msg,1,4) != 'OKAY' then
      out_errmsg := msg;
      return;
   end if;


   NLP := null;

   NLP.lpid := in_lpid;
   NLP.custid := in_custid;
   NLP.item := ITEM.item;
   NLP.lotnumber := in_lot;
   NLP.serialnumber := in_serial;
   NLP.useritem1 := in_useritem1;
   NLP.useritem2 := in_useritem2;
   NLP.useritem3 := in_useritem3;
   NLP.countryof := in_countryof;
   NLP.expirationdate := NVL(in_expdate,
           NVL(in_mfgdate,trunc(sysdate))+ ITEM.shelflife);
   NLP.manufacturedate := in_mfgdate;
   NLP.quantity := qty;
   NLP.unitofmeasure := ITEM.baseuom;
   NLP.parentlpid := null;  -- was in_mlpid
   NLP.invstatus := in_invstatus;
   NLP.inventoryclass := in_invclass;
   NLP.facility := in_facility;
   NLP.location := in_location;
   NLP.lastuser := in_user;
   NLP.recmethod := in_handtype;
   NLP.expiryaction := ITEM.expiryaction;
   NLP.lastoperator := in_user;
   NLP.disposition := '';
   NLP.qtyrcvd := qty;
   NLP.parentfacility := in_facility;
   NLP.parentitem := ITEM.item;
   NLP.itementered := in_item;
   NLP.uomentered := in_uom;
   NLP.qtyentered := in_qty;
   NLP.status := 'U';
   NLP.type := 'PA';
   NLP.fromlpid := in_kitlpid;
   NLP.weight := in_weight;

   mark := 'CHKS';


   -- determine what we need to do with this plate
   if lptype = '?' then
      action := AC_INSERT;
   elsif lptype = 'DP' then
         out_errmsg := 'Deleted plate. Enter another LPID.';
         return;
   end if;


   if action = AC_NONE THEN
-- Determine type of top LPID
      if toptype is null then
         if parenttype is not null then
            toptype := parenttype;
            topid := parentid;
         elsif xreftype is not null then
            toptype := xreftype;
            topid := xrefid;
         else
            toptype := lptype;
            topid := in_lpid;
         end if;
      end if;

      if toptype in ('C','F','M','P') then
         out_errmsg := 'Plate is outbound.';
         return;
      end if;

   mark := 'SINGLE';
-- If need a single plate (??? ASK ED ABOUT THIS )
      if in_mlpid is not null and toptype != 'PA' then
         out_errmsg := 'Single LP only.';
         return;
      end if;

-- Read the actual plate specified
      LP := NULL;
      OPEN C_PLATE(in_lpid);
      FETCH C_PLATE INTO LP;
      CLOSE C_PLATE;

      if LP.qtytasked > 0 then
         out_errmsg := 'LP has picks.';
         return;
      end if;

      if LP.custid != in_custid then
         out_errmsg := 'LPID is not for this customer.';
         return;
      end if;
      if LP.facility != in_facility then
         out_errmsg := 'LPID is not in this facility.';
         return;
      end if;

-- If entered a tote check the tote info
      if LP.type = 'TO' then
         if LP.status != 'A' then
            out_errmsg := 'Tote is not available.';
            return;
         end if;
         action := AC_ATTACH;  -- Attach to tote
      elsif LP.type = 'MP' then
         if LP.status != 'U' then
            out_errmsg := 'Multi is not available.';
            return;
         end if;
         -- try to find compatible plate to add to

         action := AC_ATTACH;  -- Attach to multi-plate
      else  -- User entered the ID of an existing plate
         if LP.status != 'U' then
            out_errmsg := 'LP is not available.';
            return;
         end if;
      end if;
   end if;


-- Still don't have an action so do more checks must be a single plate
   if action = AC_NONE then
   -- are the LP's compatable ???
   --   same custid, item, status, holdreason, unitofmeasure,
   --        serialnumber, lotnumber, manufacturedate, expirationdate
   --        condition, countryof, useritem1, useritem2, useritem3,
   --        invstatus, inventoryclass
       compat := compatible_plates(NLP, LP, msg);
   -- if specified multi then plate must be compatible
       if in_mlpid is not null then
          if compat then
             if in_mlpid != parentid then
                out_errmsg := 'Multi-plate not same parent.';
                return;
             end if;
          else
             out_errmsg := msg;
             return;
          end if;
       end if;


       if compat then
          action := AC_UPDATE;
       else
       -- have non-compatable LP
          if nvl(in_action,'XX') != 'MP' then
             out_errmsg := 'MPXXPlate not compatible. Mix items?';
             return;
          else
            action := AC_MIX;
          end if;
       end if;
   end if;


   if action = AC_NONE then
      out_errmsg := 'Unknown error.';
      return;
   end if;

--
--
--
--
-- AC_NONE
-- AC_INSERT   - add a new plate
-- AC_UPDATE   - matching(?) plate add quantities
-- AC_ATTACH   - given multiplate create lip and attach to tote
-- AC_MIX      - have non-multi plate same customer but rest doesn't match
--               create new plate from data
--               create new plate from old plate
--               make old a multi (so multi has lip)
--               attach both to multi
-- AC_REUSE    - reuse an unknown lip from bulk unload
-- AC_UPATTACH - gave us a master (multi) that has a matching child
--               so update child with quantities
-- AC_REATTACH - was on another multi so reattach???
--

--   if in_mlpid is not null then
--     if parentid is null then
--      out_errmsg := 'Make MLPID, ';
--     else
--      out_errmsg := 'Add to MLPID, ';
--     end if;
--   else
--     if parentid is null then
--      out_errmsg := 'No MLPID ';
--     else
--      out_errmsg := 'Add to parent, ';
--     end if;
--   end if;


   if action = AC_INSERT then
   -- Insert new plate
      if not insert_plate(NLP, msg) then
         out_errmsg := msg;
         return;
      end if;
   -- If need a multi insert a new multi
      if mp_action = MAC_CREATE then
         MLP.lpid := in_mlpid;
         zplp.build_empty_parent(
            MLP.lpid,
            in_facility,
            in_location,
            'U', -- status
            'MP',
            in_user,
            '', -- disposition
            in_custid,
            in_item,
            null,
            null,
            null,
            null,
            null,
            in_lot,
            in_invstatus,
            in_invclass,
            msg
         );
         if msg is not null then
            out_errmsg := msg;
            return;
         end if;
         update plate
            set fromlpid = in_kitlpid
          where lpid = in_mlpid;
      end if;
      if mp_action in (MAC_CREATE, MAC_ADD) then
         zplp.attach_child_plate(
            in_mlpid,
            in_lpid,
            in_location,
            '',
            in_user,
            msg
         );
         if msg is not null then
            out_errmsg := msg;
            return;
         end if;
      end if;
   elsif action = AC_UPDATE then
   -- Update Plate
      if not update_plate(LP, ITEM, qty, in_qty, NLP.weight, in_user, msg) then
         out_errmsg := msg;
         return;
      end if;
   elsif action = AC_ATTACH then
      LP := null;
      for crec in C_SUBPLATE(in_lpid) loop
          if compatible_plates(NLP, crec, msg) then
             LP := crec;
             exit;
          end if;
      end loop;
      if LP.lpid is not null then
         -- update the plate
         if not update_plate(LP, ITEM, qty, in_qty, NLP.weight, in_user, msg) then
            out_errmsg := msg;
            return;
         end if;
      else
        -- get new lpid and add the plate
        zrf.get_next_lpid(NLP.lpid, msg);
        if not insert_plate(NLP, msg) then
           out_errmsg := msg;
           return;
        end if;
        -- attach to the parent
        zplp.attach_child_plate(
           in_lpid,
           NLP.lpid,
           in_location,
           '',
           in_user,
           msg
        );
        if msg is not null then
           out_errmsg := msg;
           return;
        end if;
      end if;
   elsif action = AC_MIX then
      -- Morph it
      zplp.morph_lp_to_multi(in_lpid, in_user, msg);
      if msg is not null then
         out_errmsg := msg;
         return;
      end if;

      zrf.get_next_lpid(NLP.lpid, msg);
      if msg is not null then
         out_errmsg := msg;
         return;
      end if;
      if not insert_plate(NLP, msg) then
         out_errmsg := msg;
         return;
      end if;
      -- attach to the parent
      zplp.attach_child_plate(
         in_lpid,
         NLP.lpid,
         in_location,
         '',
         in_user,
         msg
      );
      if msg is not null then
         out_errmsg := msg;
         return;
      end if;
   else
      out_errmsg := 'Unknown action = '|| action;
   end if;


EXCEPTION when others then
  out_errmsg := mark || '-' || sqlerrm;

END add_restored_lpid;

----------------------------------------------------------------------
--
-- complete_dekit -
--
----------------------------------------------------------------------
PROCEDURE complete_dekit
(
   in_lpid     IN  varchar2,
   in_location IN  varchar2,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
)
IS
msg varchar2(200);
LP plate%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    LP := null;

    open C_PLATE(in_lpid);
    fetch C_PLATE into LP;
    CLOSE C_PLATE;

    if LP.type = 'PA' then
      zlp.plate_to_deletedplate(in_lpid, in_user, null, msg);

      zbill.add_asof_inventory(LP.facility, LP.custid, LP.item, LP.lotnumber,
               LP.unitofmeasure, sysdate, -LP.quantity, -LP.weight, 'DeKit', 'AD',
               LP.inventoryclass, LP.invstatus, LP.orderid, LP.shipid, in_lpid,
               in_user, msg);
    else
      update plate
         set status = 'A',
             location = in_location,
             lastuser = in_user,
             lastupdate = sysdate
       where lpid = in_lpid;

    end if;

    update plate
       set status = 'A',
           location = in_location,
           lastuser = in_user,
           lastupdate = sysdate
     where fromlpid = in_lpid;

EXCEPTION when others then
    out_errmsg := sqlerrm;
END complete_dekit;

end zdekit;
/

show errors package body zdekit;
exit;
