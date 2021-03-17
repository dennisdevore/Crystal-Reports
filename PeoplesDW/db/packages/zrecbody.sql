create or replace package body alps.zreceive as
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
-- check_order
--
----------------------------------------------------------------------
PROCEDURE check_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_loadno    IN      number,
    out_errmsg   OUT     varchar2
)
IS

  CURSOR C_PLATE(in_orderid number, in_shipid number) IS
    SELECT *
      FROM PLATE
     WHERE status not in ('P','U', 'D')
       AND TYPE = 'PA'
       AND orderid = in_orderid
       AND shipid = in_shipid;



  ORD   orderhdr%rowtype;
  LOAD  loads%rowtype;

  errmsg varchar2(100);

BEGIN
   out_errmsg := 'OKAY';

-- Verify order and its type
   ORD := null;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR into ORD;
   CLOSE C_ORDHDR;

   if ORD.orderid is null then
      out_errmsg := 'Order not found.';
      return;
   end if;

   if ORD.ordertype not in ('R', 'T') then
      out_errmsg := 'Order not a receiving order type.';
      return;
   end if;

-- If there is a load get its information
   if in_loadno != nvl(ORD.loadno, -1) then
      out_errmsg := 'Order not for specified load.';
      return;
   end if;

EXCEPTION when others then
  out_errmsg := sqlerrm;

END check_order;


----------------------------------------------------------------------
--
-- find_orders
--
----------------------------------------------------------------------
PROCEDURE find_orders
(
    in_loadno    IN      number,
    out_orderid  OUT     number,
    out_shipid   OUT     number,
    out_count    OUT     number,
    out_errmsg   OUT     varchar2
)
IS

  ORD   orderhdr%rowtype;

CURSOR C_ORDHDR_LOAD(in_loadno number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE loadno = in_loadno;

  errmsg varchar2(100);

  cnt integer;
  CUST customer%rowtype;

BEGIN
   out_errmsg := 'OKAY';

   ORD := null;
   cnt := 0;

   for crec in C_ORDHDR_LOAD(in_loadno) loop
       cnt := cnt + 1;
       if ORD.orderid is null then
          ORD := crec;
       end if;

       CUST := null;
       OPEN C_CUST(crec.custid);
       FETCH C_CUST into CUST;
       CLOSE C_CUST;

       if nvl(CUST.paperbased, 'N') = 'Y' then
         out_errmsg := 'Load contains an order for an Aggregate Inventory Customer and may not be received with this function.';
       end if;
   end loop;


   out_orderid := ORD.orderid;
   out_shipid := ORD.shipid;
   out_count := cnt;
EXCEPTION when others then
  out_errmsg := sqlerrm;

END find_orders;

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
LOAD  loads%rowtype;
BEGIN

    out_errmsg := 'OKAY';

   LOAD := null;
   OPEN C_LOADS(NLP.loadno);
   FETCH C_LOADS into LOAD;
   CLOSE C_LOADS;

   if LOAD.loadstatus != 'A' then
      out_errmsg := 'Load not in arrived status.';
      return FALSE;
   end if;

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
      NLP.lastuser,
      sysdate
   );

   -- zrf.tally_lp_receipt(NLP.lpid, NLP.lastuser, errmsg);
   -- if errmsg is not null then
   --    out_errmsg := errmsg;
   --    return FALSE;
   -- end if;

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
-- update_order
--
----------------------------------------------------------------------
FUNCTION update_order
(
   ORD         IN  orderhdr%rowtype,
   NLP         IN  plate%rowtype,
   ITEM        IN  custitemview%rowtype,
   qty         IN  number,
   out_errmsg  OUT varchar2
)
RETURN BOOLEAN
IS
DTL     orderdtl%rowtype;

qtydm   number := 0;
qtygood number := 0;
wtdm number := 0;
wtgood number := 0;
l_msg varchar2(255);

BEGIN

    out_errmsg := 'OKAY';

   DTL := null;
   OPEN C_ORDDTL(ORD.orderid, ORD.shipid,
        NLP.item, NLP.lotnumber);
   FETCH C_ORDDTL into DTL;
   CLOSE C_ORDDTL;

   if NLP.invstatus = 'DM' then
      qtydm := qty;
      wtdm := NLP.weight;
   else
      qtygood := qty;
      wtgood := NLP.weight;
   end if;

   INSERT INTO orderdtlrcpt(
         orderid,
         shipid,
         orderitem,
         item,
         orderlot,
         facility,
         custid,
         lotnumber,
         uom,
         inventoryclass,
         invstatus,
         lpid,
         qtyrcvd,
         lastuser,
         lastupdate,
         qtyrcvdgood,
         qtyrcvddmgd,
         serialnumber,
         useritem1,
         useritem2,
         useritem3,
         weight,
         parentlpid
   )
   values
   (
        ORD.orderid,
        ORD.shipid,
        NLP.item,
        NLP.item,
        NLP.lotnumber,
        NLP.facility,
        NLP.custid,
        NLP.lotnumber,
        NLP.unitofmeasure,
        NLP.inventoryclass,
        NLP.invstatus,
        NLP.lpid,
        NLP.qtyrcvd,
        NLP.lastuser,
        sysdate,
        decode(NLP.invstatus,'DM',0,NLP.qtyrcvd),
        decode(NLP.invstatus,'DM',NLP.qtyrcvd,0),
        NLP.serialnumber,
        NLP.useritem1,
        NLP.useritem2,
        NLP.useritem3,
        NLP.weight,
        NLP.parentlpid
   );

   zrec.update_receipt_dtl
      (ORD.orderid, ORD.shipid, NLP.item, NLP.lotnumber, ITEM.baseuom,
       NLP.item, NLP.unitofmeasure, qty, qtygood, qtydm, NLP.weight,
       wtgood, wtdm,
       zci.item_cube(ORD.custid,NLP.item,NLP.unitofmeasure) * qty,
       zci.item_cube(ORD.custid,NLP.item,NLP.unitofmeasure) * qtygood,
       zci.item_cube(ORD.custid,NLP.item,NLP.unitofmeasure) * qtydm,
       zci.item_amt(ORD.custid,ORD.orderid,ORD.shipid,NLP.item,NLP.lotnumber) * qty,
       zci.item_amt(ORD.custid,ORD.orderid,ORD.shipid,NLP.item,NLP.lotnumber) * qtygood,
       zci.item_amt(ORD.custid,ORD.orderid,ORD.shipid,NLP.item,NLP.lotnumber) * qtydm,
       NLP.lastuser, 'Automatically created by receive load', l_msg);

   if l_msg != 'OKAY' then
      out_errmsg := l_msg;
      return FALSE;
   end if;

-- Update loadstopship
   if ORD.loadno is not null then
      UPDATE loadstopship
         SET
             qtyrcvd = nvl(qtyrcvd,0) + qty,
             weightrcvd = nvl(weightrcvd,0) + NLP.weight,
             weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(ORD.custid,NLP.weight),0),
             cubercvd = nvl(cubercvd,0) +
               (qty * zci.item_cube(ORD.custid,NLP.item,NLP.unitofmeasure)),
             amtrcvd = nvl(amtrcvd,0) + (qty * zci.item_amt(ORD.custid,ORD.orderid,ORD.shipid,NLP.item,NLP.lotnumber)),
             lastuser = NLP.lastuser,
             lastupdate = sysdate
       WHERE loadno = ORD.loadno
         AND stopno = ORD.stopno
         AND shipno = ORD.shipno;
   end if;

   return TRUE;

EXCEPTION WHEN OTHERS THEN
   out_errmsg := sqlerrm;
   return FALSE;

END update_order;



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
    if nvl(in_lp1.anvdate,to_date('19900101','YYYYMMDD'))
          != nvl(in_lp2.anvdate,to_date('19900101','YYYYMMDD')) then
       out_errmsg := 'Incompatible anniversary date';
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
-- add_receipt_lpid
--
----------------------------------------------------------------------
PROCEDURE add_receipt_lpid
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_loadno    IN      number,
    in_stopno    IN      number,
    in_shipno    IN      number,
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
  NLP   plate%rowtype; -- the new plate to create information
  ONLP  plate%rowtype; -- the plate info to update order information
  MLP   plate%rowtype;
  ITEM  custitemview%rowtype;
  ORD   orderhdr%rowtype;
  DTL   orderdtl%rowtype;
  LOC   location%rowtype;
  LOAD  loads%rowtype;
  errmsg varchar2(100);
  errno  number;


  compat BOOLEAN;
  action integer;
  mp_action integer;
  qa_action varchar2(10);
  qa_id       number;
  qa_qty      number;
  new_invstatus plate.invstatus%type;

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

CURSOR C_SUBPLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE parentlpid = in_lpid;

CURSOR C_CAUX(in_custid varchar2)
IS
    SELECT verify_sale_life_yn
      FROM customer_aux
     WHERE custid = in_custid;

CAUX C_CAUX%rowtype;

l_invstatus plate.invstatus%type;

BEGIN
   out_errmsg := 'OKAY';
   action := AC_NONE;
   mp_action := MAC_NONE;

   mark := 'BEGIN';

-- Get customer info
    CAUX := null;
    OPEN C_CAUX(in_custid);
    FETCH C_CAUX into CAUX;
    CLOSE C_CAUX;

-- Verify order and its type
   ORD := null;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR into ORD;
   CLOSE C_ORDHDR;

   if ORD.orderid is null then
      out_errmsg := 'Order not found.';
      return;
   end if;

-- Verify Load OK
   LOAD := null;
   OPEN C_LOADS(ORD.loadno);
   FETCH C_LOADS into LOAD;
   CLOSE C_LOADS;

   if LOAD.loadno is null then
      out_errmsg := 'Load not found.';
      return;
   end if;

   if LOAD.loadstatus != 'A' then
      out_errmsg := 'Load not in arrived status.';
      return;
   end if;

-- Validate LPs
   if (not zlp.is_lpid(in_lpid)) then
      out_errmsg := 'Invalid LPID';
      return;
   end if;

   mark := 'LOC';

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

   mark := 'QACH';
-- Check if this is a QA item

   qa_action := 'NONE';

   zqa.check_qa_order_item(in_orderid, in_shipid, in_item, in_lot,
      in_qty, in_user,
      qa_qty, qa_action, errno, errmsg);

   if qa_action in ('IN','QA','QC') then
     new_invstatus := qa_action;
     qa_action := 'QR';
   else
     new_invstatus := in_invstatus;
   end if;

   if qa_action = 'QR' then

      if new_invstatus not in ('IN','QA') then
         out_errmsg := 'This is a QA item and must be either QA or IN status';
         return;
      end if;

      if in_mlpid is not null and new_invstatus = 'IN' then
         out_errmsg := 'This plate is for inspection (IN) so must be a single plate.';
         return;
      end if;

      if nvl(in_action,'XX') != 'QA' and
         new_invstatus = 'QA' and qa_qty > 0 then
         -- out_errmsg := 'Still need '||qa_qty||' for inspection';
         out_errmsg := 'QACK:'||qa_qty;
         return;
      end if;

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

-- Verify expiration shelflife
    l_invstatus := null;
    if CAUX.verify_sale_life_yn = 'Y' and in_invstatus = 'AV'
     and nvl(ITEM.min_sale_life,0) > 0 then
        if in_expdate is not null then
            if in_expdate < trunc(sysdate) + ITEM.min_sale_life then
                l_invstatus := 'VC';
            end if;
        end if;
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
   NLP.expirationdate := zrf.calc_expiration(to_char(in_expdate, 'MM/DD/RRRR'),
         to_char(in_mfgdate, 'MM/DD/RRRR'), ITEM.shelflife);
   NLP.manufacturedate := in_mfgdate;
   NLP.orderid := in_orderid;
   NLP.shipid := in_shipid;
   NLP.loadno := in_loadno;
   NLP.stopno := in_stopno;
   NLP.shipno := in_shipno;
   NLP.quantity := qty;
   NLP.unitofmeasure := ITEM.baseuom;
   NLP.parentlpid := null;  -- was in_mlpid
   NLP.invstatus := nvl(l_invstatus, in_invstatus);
   NLP.inventoryclass := in_invclass;
   NLP.facility := in_facility;
   NLP.location := in_location;
   NLP.lastuser := in_user;
   NLP.recmethod := in_handtype;
   NLP.expiryaction := ITEM.expiryaction;
   NLP.po := ORD.po;
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

   NLP.weight := in_weight;
   if nvl(ITEM.use_catch_weights,'N') = 'Y' then
      if nvl(ITEM.catch_weight_in_cap_type,'G') = 'N' then
         NLP.weight := NLP.weight + zci.item_tareweight(NLP.custid, NLP.item, NLP.unitofmeasure)
               * NLP.quantity;
      end if;
      zcwt.set_item_catch_weight(NLP.custid, NLP.item, NLP.orderid, NLP.shipid,
            NLP.qtyentered, NLP.uomentered, NLP.weight, in_user, msg);
      if msg != 'OKAY' then
         out_errmsg := 'Error setting catch weight: ' || msg;
         return;
      end if;
      zcwt.add_item_lot_catch_weight(in_facility, NLP.custid, NLP.item, NLP.lotnumber,
            NLP.weight, msg);
      if msg != 'OKAY' then
         out_errmsg := 'Error adding catch weight: ' || msg;
         return;
      end if;
   end if;

   mark := 'CHKS';

   -- Check if doing an ASN capture only
   ONLP := NLP;
   if ITEM.serialrequired != 'Y'
    and ITEM.serialasncapture = 'Y' then
      NLP.serialnumber := null;
   end if;

   if ITEM.user1required != 'Y'
    and ITEM.user1asncapture = 'Y' then
      NLP.useritem1 := null;
   end if;

   if ITEM.user2required != 'Y'
    and ITEM.user2asncapture = 'Y' then
      NLP.useritem2 := null;
   end if;

   if ITEM.user3required != 'Y'
    and ITEM.user3asncapture = 'Y' then
      NLP.useritem3 := null;
   end if;

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
            in_orderid,
            in_shipid,
            in_loadno,
            in_stopno,
            in_shipno,
            in_lot,
            nvl(l_invstatus, in_invstatus),
            in_invclass,
            msg
         );
         if msg is not null then
            out_errmsg := msg;
            return;
         end if;
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
   -- Update order
      if not update_order(ORD, ONLP, ITEM, qty, msg) then
         out_errmsg := msg;
         return;
      end if;
   elsif action = AC_UPDATE then
   -- Update order
      if not update_order(ORD, ONLP,ITEM, qty, msg) then
         out_errmsg := msg;
         return;
      end if;
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
      -- update the order
      if not update_order(ORD, ONLP,ITEM, qty, msg) then
         out_errmsg := msg;
         return;
      end if;
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
      -- update order
      if not update_order(ORD, ONLP,ITEM, qty, msg) then
         out_errmsg := msg;
         return;
      end if;

   else
      out_errmsg := 'Unknown action = '|| action;
   end if;

   if qa_action = 'QR' and out_errmsg = 'OKAY' then
      zqa.add_qa_plate(in_lpid, in_user,qa_action,qa_id,errno, errmsg);
   end if;

EXCEPTION when others then
  out_errmsg := mark || '-' || sqlerrm;

END add_receipt_lpid;

----------------------------------------------------------------------
--
-- complete_plate -
--
----------------------------------------------------------------------
PROCEDURE complete_plate
(
   in_lpid     IN  varchar2,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
)
IS

CURSOR C_SUBPLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE parentlpid = in_lpid
       AND status = 'U';

CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid
       AND status = 'U';

errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';


    for crec in C_SUBPLATE(in_lpid) loop
        update plate
           set status = 'A',
              lastuser = in_user,
              lastupdate = sysdate
        where lpid = crec.lpid;
        if crec.type = 'PA' then
           null;
           -- zrf.tally_lp_receipt(crec.lpid, in_user, errmsg);
        end if;
    end loop;

    for crec in C_PLATE(in_lpid) loop
        update plate
           set status = 'A',
              lastuser = in_user,
              lastupdate = sysdate
        where lpid = crec.lpid;
        if crec.type = 'PA' then
           null;
           -- zrf.tally_lp_receipt(crec.lpid, in_user, errmsg);
        end if;
    end loop;

EXCEPTION when others then
    out_errmsg := sqlerrm;
END complete_plate;

----------------------------------------------------------------------
--
-- empty_trailer -
--
----------------------------------------------------------------------
PROCEDURE empty_trailer
(
   in_dock       IN  varchar2,
   in_facility   IN  varchar2,
   in_loadno     IN  number,
   in_user       IN  varchar2,
   in_nosetemp   IN  number,
   in_middletemp IN  number,
   in_tailtemp   IN  number,
   out_errmsg    OUT varchar2
)
IS
err varchar2(10);
msg varchar2(100);

CURSOR C_PLATE(in_loadno number)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE loadno = in_loadno
       AND status = 'U'
       AND zrf.is_location_physical(facility, location) = 'Y';

errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- First make all the plates available
    for crec in C_PLATE(in_loadno) loop
        update plate
           set status = 'A',
              lastuser = in_user,
              lastupdate = sysdate
        where lpid = crec.lpid;
        if crec.type = 'PA' then
           null;
           -- zrf.tally_lp_receipt(crec.lpid, in_user, errmsg);
        end if;
    end loop;

    zrf.mark_dock_empty(in_dock,in_facility,'',in_user, in_loadno, in_nosetemp,
         in_middletemp, in_tailtemp, err, msg);

    if msg is not null then
       out_errmsg := msg;
       return;
    end if;



EXCEPTION when others then
    out_errmsg := sqlerrm;
END empty_trailer;


----------------------------------------------------------------------
--
-- transfer_plate -
--
----------------------------------------------------------------------
PROCEDURE transfer_plate
(
   in_lpid     IN  varchar2,
   in_facility IN  varchar2,
   in_location IN  varchar2,
   in_loadno   IN  number,
   in_user     IN  varchar2,
   out_errmsg  OUT varchar2
)
IS

LOC location%rowtype;

err varchar2(10);
msg varchar2(100);
BEGIN

  out_errmsg := 'OKAY';

-- Validate location
   LOC := null;
   OPEN C_LOCATION(in_facility, in_location);
   FETCH C_LOCATION into LOC;
   CLOSE C_LOCATION;
   if LOC.locid is null then
      out_errmsg := 'Invalid location';
      return;
   end if;

  zrfxo.receive_lp(in_lpid, in_loadno, in_user, err, msg);

  if err != 'N' or msg is not null then
     out_errmsg := msg;
     return;
  end if;


  update plate
     set location = in_location,
         facility = in_facility,
         disposition = null
   where lpid in (select lpid from plate
                   start with lpid = in_lpid
                   connect by prior lpid = parentlpid);


EXCEPTION when others then
    out_errmsg := sqlerrm;
END transfer_plate;

procedure check_line_qty
(in_custid IN varchar2
,in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_qty_to_receive IN number
,out_errorno IN OUT number
,out_errmsg OUT varchar2
)
is

cursor curCustomer is
  select custid,
         nvl(recv_line_check_yn,'N') as recv_line_check_yn,
         nvl(recv_line_variance_pct,0) as recv_line_variance_pct
    from customer
   where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdr is
    select po
      from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curOrderDtl is
  select orderid,
         nvl(qtyorder,0) as qtyorder,
         nvl(qtyrcvd,0) as qtyrcvd
    from orderdtl
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'NONE') = nvl(in_lotnumber,'NONE');
od curOrderDtl%rowtype;

cursor curOrderDtlLineFirst is
  select qty
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'NONE') = nvl(in_lotnumber,'NONE')
     and nvl(xdock,'N') = 'N'
   order by dtlpassthrudate01;
olf curOrderDtlLineFirst%rowtype;

cursor curOrderDtlLineSum is
  select sum(nvl(qtyapproved,0)) as qtyapproved,
         count(qtyapproved) as count
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_item
     and nvl(lotnumber,'NONE') = nvl(in_lotnumber,'NONE')
     and nvl(xdock,'N') = 'N';
ols curOrderDtlLineSum%rowtype;

begin

out_errorno := 0;

cu := null;
open curCustomer;
fetch curCustomer into cu;
close curCustomer;

if cu.custid is null then
  return;
end if;

if cu.recv_line_check_yn != 'Y' then
  return;
end if;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;

-- if no po, then its a warehouse transfer, so skip line check
if rtrim(oh.po) is null then
  return;
end if;

od := null;
open curOrderDtl;
fetch curOrderDtl into od;
close curOrderDtl;

if od.orderid is null then
  return;
end if;

ols := null;
open curOrderDtlLineSum;
fetch curOrderDtlLineSum into ols;
close curOrderDtlLineSum;

if ols.count = 0 then
  od.qtyorder := od.qtyorder + round(od.qtyorder * cu.recv_line_variance_pct / 100);
  if od.qtyrcvd + nvl(in_qty_to_receive,0) > od.qtyorder then
    goto line_qty_exceeded;
  end if;
end if;

if od.qtyrcvd + nvl(in_qty_to_receive,0) <= nvl(ols.qtyapproved,0) then
  return;
end if;

olf := null;
open curOrderDtlLineFirst;
fetch curOrderDtlLineFirst into olf;
close curOrderDtlLineFirst;

olf.qty := nvl(olf.qty,0) + round(nvl(olf.qty,0) * cu.recv_line_variance_pct / 100);
if od.qtyrcvd + nvl(in_qty_to_receive,0) <= olf.qty then
  return;
end if;

<< line_qty_exceeded >>

out_errorno := -1;
out_errmsg := 'Line quantity exceeded';

exception when others then
  out_errorno := sqlcode;
  out_errmsg := substr(sqlerrm,1,80);
end check_line_qty;

PROCEDURE change_qtyapproved
(in_orderid IN number
,in_shipid IN number
,in_item IN varchar2
,in_lotnumber IN varchar2
,in_linenumber IN number
,in_qtyapproved IN number
,in_facility IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg  IN OUT varchar2
)
is

cursor Corderhdr is
  select nvl(ordertype,'?') as ordertype,
         nvl(tofacility,' ') as tofacility
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh Corderhdr%rowtype;

begin

out_msg := '';
out_errorno := 0;

open Corderhdr;
fetch Corderhdr into oh;
if Corderhdr%notfound then
  close Corderhdr;
  out_msg := 'Order header not found: ' || in_orderid || '-' || in_shipid;
  out_errorno := -1;
  return;
end if;

if oh.ordertype not in ('R','Q','C') then
  out_msg := 'Invalid order type: ' || oh.ordertype;
  out_errorno := -2;
  return;
end if;

if (oh.tofacility != in_facility) then
  out_msg := 'Order not associated with your facility ' || oh.tofacility;
  out_errorno := -3;
  return;
end if;

update orderdtlline
   set qtyapproved = in_qtyapproved,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and nvl(lotnumber,'(NONE)') = nvl(in_lotnumber,'(NONE)')
   and linenumber = in_linenumber;

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := substr(sqlerrm,1,80);
  out_errorno := sqlcode;
end change_qtyapproved;


procedure check_overage
   (in_orderid   in number,
    in_shipid    in number,
    in_custid    in varchar2,
    in_item      in varchar2,
    in_lotnumber in varchar2,
    in_qty       in number,
    out_errno    out number,
    out_msg      out varchar2,
    out_supcode  out varchar2)
is
   cursor c_cu(p_custid varchar2) is
      select nvl(overageunits,0) as overageunits,
             nvl(overageunitstype,'N') as overageunitstype,
             nvl(overagedollars,0) as overagedollars,
             nvl(overagedollarstype,'N') as overagedollarstype,
             nvl(overagedollarsfield,'1') as overagedollarsfield,
             overagesupcode
         from customer
         where custid = p_custid;
   cu c_cu%rowtype;
   cursor c_cur(p_custid varchar2) is
      select nvl(overageunits_return,0) as overageunits_return,
             nvl(overageunitstype_return,'N') as overageunitstype_return,
             nvl(overagedollars_return,0) as overagedollars_return,
             nvl(overagedollarstype_return,'N') as overagedollarstype_return,
             nvl(overagedollarsfield_return,'1') as overagedollarsfield_return,
             overagesupcode_return
         from customer
         where custid = p_custid;
   cur c_cur%rowtype;
   cursor c_ci(p_custid varchar2, p_item varchar2, p_amtfield varchar2) is
      select decode(p_amtfield, '1', nvl(useramt1,0), nvl(useramt2,0)) as amt
         from custitem
         where custid = p_custid
           and item = p_item;
   ci c_ci%rowtype;
   cursor c_od(p_orderid number, p_shipid number, p_item varchar2, p_lot varchar2) is
      select nvl(qtyorder,0) as qtyorder,
             nvl(qtyrcvd,0) as qtyrcvd
         from orderdtl
         where orderid = p_orderid
           and shipid = p_shipid
           and item = p_item
           and nvl(lotnumber,'(none)') = nvl(p_lot,'(none)');
   od c_od%rowtype;
   cursor c_oh(p_orderid number, p_shipid number) is
   select ordertype
      from orderhdr
      where orderid = p_orderid
        and shipid = p_shipid;
   oh c_oh%rowtype;
   rowfound boolean;
begin
   out_errno := 0;
   out_msg := null;
   out_supcode := null;

   if (in_orderid = 0) then
    return;
   end if;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   rowfound := c_oh%found;
   close c_oh;
   if not rowfound then
     out_errno := 7;
     out_msg := 'Order: '||in_orderid||' not found';
     return;
   end if;
   if oh.ordertype not in ('R','Q','C') then
     out_errno := 8;
     out_msg := 'Ordertype must be R or Q or C - Orderid: '||in_orderid;
     return;
   end if;

   if oh.ordertype = 'R' then
   open c_cu(in_custid);
   fetch c_cu into cu;
   rowfound := c_cu%found;
   close c_cu;
   if not rowfound then
      out_errno := 1;
      out_msg := 'Customer not found';
      return;
   end if;

   if (cu.overageunitstype = 'N') and (cu.overagedollarstype = 'N') then
      return;              -- nothing to enforce
   end if;

   open c_ci(in_custid, in_item, cu.overagedollarsfield);
   fetch c_ci into ci;
   rowfound := c_ci%found;
   close c_ci;
   if not rowfound then
      out_errno := 2;
      out_msg := 'Item not found';
      return;
   end if;

   out_supcode := cu.overagesupcode;
   open c_od(in_orderid, in_shipid, in_item, in_lotnumber);
   fetch c_od into od;
   rowfound := c_od%found;
   close c_od;
   if not rowfound then
      od.qtyorder := 0;
      od.qtyrcvd := 0;
   end if;

   if (cu.overageunitstype = 'A')
   and ((od.qtyrcvd+in_qty) > (od.qtyorder+cu.overageunits)) then
      out_errno := 3;
      return;
   end if;

   if (cu.overageunitstype = 'P')
   and ((od.qtyrcvd+in_qty) > (od.qtyorder*(1.0+(cu.overageunits/100.0)))) then
      out_errno := 4;
      return;
   end if;

   if (cu.overagedollarstype = 'A')
   and (((od.qtyrcvd+in_qty)*ci.amt) > (cu.overagedollars+(od.qtyorder*ci.amt))) then
      out_errno := 5;
      return;
   end if;

   if (cu.overagedollarstype = 'P')
   and (((od.qtyrcvd+in_qty)*ci.amt) > ((od.qtyorder*(1.0+(cu.overagedollars/100.0))*ci.amt))) then
      out_errno := 6;
      return;
   end if;
   elsif oh.ordertype = 'Q' then
     open c_cur(in_custid);
     fetch c_cur into cur;
     rowfound := c_cur%found;
     close c_cur;
     if not rowfound then
        out_errno := 1;
        out_msg := 'Customer not found';
        return;
     end if;

      if (cur.overageunitstype_return = 'N') and (cur.overagedollarstype_return = 'N') then
         return;              -- nothing to enforce
      end if;

      open c_ci(in_custid, in_item, cur.overagedollarsfield_return);
      fetch c_ci into ci;
      rowfound := c_ci%found;
      close c_ci;
      if not rowfound then
         out_errno := 2;
         out_msg := 'Item not found';
         return;
      end if;

      out_supcode := cur.overagesupcode_return;
      open c_od(in_orderid, in_shipid, in_item, in_lotnumber);
      fetch c_od into od;
      rowfound := c_od%found;
      close c_od;
      if not rowfound then
         od.qtyorder := 0;
         od.qtyrcvd := 0;
      end if;

      if (cur.overageunitstype_return = 'A')
      and ((od.qtyrcvd+in_qty) > (od.qtyorder+cur.overageunits_return)) then
         out_errno := 3;
         return;
      end if;

      if (cur.overageunitstype_return = 'P')
      and ((od.qtyrcvd+in_qty) > (od.qtyorder*(1.0+(cur.overageunits_return/100.0)))) then
         out_errno := 4;
         return;
      end if;

      if (cur.overagedollarstype_return = 'A')
      and (((od.qtyrcvd+in_qty)*ci.amt) > (cur.overagedollars_return+(od.qtyorder*ci.amt))) then
         out_errno := 5;
         return;
      end if;

      if (cur.overagedollarstype_return = 'P')
      and (((od.qtyrcvd+in_qty)*ci.amt) > ((od.qtyorder*(1.0+(cur.overagedollars_return/100.0))*ci.amt))) then
         out_errno := 6;
         return;
      end if;
   end if;

exception
   when OTHERS then
      out_errno := sqlcode;
      out_msg := substr(sqlerrm,1,80);
end check_overage;


procedure verify_master_receipt
   (in_mstr_orderid in number,
    in_mstr_shipid  in number,
    in_custid       in varchar2,
    in_rcpt_orderid in number,
    in_rcpt_shipid  in number,
    out_msg         out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select ordertype, orderstatus, custid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   rowfound boolean;
   l_cnt pls_integer;
begin
   out_msg := null;

   open c_oh(in_mstr_orderid, in_mstr_shipid);
   fetch c_oh into oh;
   rowfound := c_oh%found;
   close c_oh;
   if not rowfound then
      out_msg := 'Master receipt not found';
      return;
   end if;

   if oh.ordertype != 'A' then
      out_msg := 'Order is not a master receipt';
      return;
   end if;

   if oh.orderstatus > '9' then
      out_msg := 'Master receipt is not open';
      return;
   end if;

   if oh.custid != in_custid then
      out_msg := 'Master receipt is for customer '||oh.custid||' not customer '||in_custid;
      return;
   end if;

   l_cnt := 1;
   for od in (select item, lotnumber
               from orderdtl
               where orderid = in_rcpt_orderid
                 and shipid = in_rcpt_shipid) loop
      select count(1) into l_cnt
         from orderdtl
         where orderid = in_mstr_orderid
           and shipid = in_mstr_shipid
           and item = od.item
           and nvl(lotnumber, '(none)') = nvl(od.lotnumber, '(none)');
      exit when l_cnt = 0;
   end loop;

   if l_cnt = 0 then
      out_msg := 'Warning: receipt contains items not on master receipt';
      return;
   end if;

   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end verify_master_receipt;


procedure close_master_receipt
   (in_mstr_orderid in number,
    in_mstr_shipid  in number,
    in_userid       in varchar2,
    out_msg         out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select ordertype, orderstatus, rowid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   rowfound boolean;
   l_cnt pls_integer;
begin
   out_msg := null;

   open c_oh(in_mstr_orderid, in_mstr_shipid);
   fetch c_oh into oh;
   rowfound := c_oh%found;
   close c_oh;
   if not rowfound then
      out_msg := 'Master receipt not found';
      return;
   end if;

   if oh.ordertype != 'A' then
      out_msg := 'Order is not a master receipt';
      return;
   end if;

   if oh.orderstatus > '9' then
      out_msg := 'Master receipt is not open';
      return;
   end if;

   select count(1) into l_cnt
      from orderhdr
      where parentorderid = in_mstr_orderid
        and parentshipid = in_mstr_shipid
        and orderstatus < 'R';

   if l_cnt != 0 then
      out_msg := 'Master receipt has '||l_cnt||' open child receipts';
      return;
   end if;

   update orderhdr
      set orderstatus = 'R',
          lastuser = in_userid,
          lastupdate = sysdate
    where rowid = oh.rowid;

   zoh.add_orderhistory(in_mstr_orderid, in_mstr_shipid,
      'Order Closed',
      'Order Closed',
      in_userid, out_msg);

   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end close_master_receipt;


procedure update_receipt_dtl
   (in_orderid     in number,
    in_shipid      in number,
    in_item        in varchar2,
    in_lotnumber   in varchar2,
    in_uom         in varchar2,
    in_itementered in varchar2,
    in_uomentered  in varchar2,
    in_qty         in number,
    in_qtygood     in number,
    in_qtydmgd     in number,
    in_weight      in number,
    in_weightgood  in number,
    in_weightdmgd  in number,
    in_cube        in number,
    in_cubegood    in number,
    in_cubedmgd    in number,
    in_amt         in number,
    in_amtgood     in number,
    in_amtdmgd     in number,
    in_userid      in varchar2,
    in_comment     in varchar2,
    out_msg        out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select nvl(parentorderid,0) parentorderid,
             nvl(parentshipid,0) parentshipid,
             ordertype
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype := null;

   procedure upd_dtls
      (p_orderid in number,
       p_shipid  in number)
   is
      l_qtyent varchar2(1) := 'Y';
   begin
      if (oh.ordertype = 'C') and (oh.parentorderid != 0) then
         l_qtyent := 'N';
      end if;
      update orderdtl
         set qtyrcvd = nvl(qtyrcvd,0) + in_qty,
             qtyrcvdgood = nvl(qtyrcvdgood,0) + in_qtygood,
             qtyrcvddmgd = nvl(qtyrcvddmgd,0) + in_qtydmgd,
             weightrcvd = nvl(weightrcvd,0) + in_weight,
             weightrcvdgood = nvl(weightrcvdgood,0) + in_weightgood,
             weightrcvddmgd = nvl(weightrcvddmgd,0) + in_weightdmgd,
             cubercvd = nvl(cubercvd,0) + in_cube,
             cubercvdgood = nvl(cubercvdgood,0) + in_cubegood,
             cubercvddmgd = nvl(cubercvddmgd,0) + in_cubedmgd,
             amtrcvd = nvl(amtrcvd,0) + in_amt,
             amtrcvdgood = nvl(amtrcvdgood,0) + in_amtgood,
             amtrcvddmgd = nvl(amtrcvddmgd,0) + in_amtdmgd,
             lastuser = in_userid,
             lastupdate = sysdate
         where orderid = p_orderid
           and shipid = p_shipid
           and item = in_item
           and nvl(lotnumber, '(none)') = nvl(in_lotnumber, '(none)');
      if sql%rowcount = 0 then
         insert into orderdtl
            (orderid, shipid, item, custid, fromfacility,
             uom, linestatus,
             qtyentered,
             itementered, uomentered,
             qtyrcvd, qtyrcvdgood, qtyrcvddmgd,
             weightrcvd, weightrcvdgood, weightrcvddmgd,
             cubercvd, cubercvdgood, cubercvddmgd,
             amtrcvd, amtrcvdgood, amtrcvddmgd,
             comment1, statususer, statusupdate,
             lastuser, lastupdate, priority,
             rfautodisplay, lotnumber)
         select p_orderid, p_shipid, in_item, custid, fromfacility,
                in_uom, 'A',
                decode(l_qtyent,
                     'N', null,
                     zlbl.uom_qty_conv(custid, in_itementered, in_qty, in_uom, in_uomentered)),
                in_itementered, in_uomentered,
                in_qty, in_qtygood, in_qtydmgd,
                in_weight, in_weightgood, in_weightdmgd,
                in_cube, in_cubegood, in_cubedmgd,
                in_amt, in_amtgood, in_amtdmgd,
                in_comment, in_userid, sysdate,
                in_userid, sysdate, priority,
                'N', in_lotnumber
            from orderhdr
            where orderid = p_orderid
              and shipid = p_shipid;
      end if;
   end upd_dtls;

begin

   out_msg := null;

   open c_oh(in_orderid, in_shipid);
   fetch c_oh into oh;
   close c_oh;

   upd_dtls(in_orderid, in_shipid);
   if (oh.parentorderid != 0) and (oh.parentshipid != 0) then
      upd_dtls(oh.parentorderid, oh.parentshipid);
   end if;

   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end update_receipt_dtl;


procedure verify_inbound_notice
   (in_inot_orderid in number,
    in_inot_shipid  in number,
    in_custid       in varchar2,
    out_msg         out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select ordertype, orderstatus, custid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   rowfound boolean;
begin
   out_msg := null;

   open c_oh(in_inot_orderid, in_inot_shipid);
   fetch c_oh into oh;
   rowfound := c_oh%found;
   close c_oh;
   if not rowfound then
      out_msg := 'Inbound notice not found';
      return;
   end if;

   if oh.ordertype != 'I' then
      out_msg := 'Order is not an inbound notice';
      return;
   end if;

   if oh.orderstatus > '9' then
      out_msg := 'Inbound notice is not open';
      return;
   end if;

   if oh.custid != in_custid then
      out_msg := 'Inbound notice is for customer '||oh.custid||' not customer '||in_custid;
      return;
   end if;

   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end verify_inbound_notice;


procedure close_inbound_notice
   (in_inot_orderid in number,
    in_inot_shipid  in number,
    in_userid       in varchar2,
    out_msg         out varchar2)
is
   cursor c_oh(p_orderid number, p_shipid number) is
      select ordertype, orderstatus, rowid
         from orderhdr
         where orderid = p_orderid
           and shipid = p_shipid;
   oh c_oh%rowtype;
   rowfound boolean;
   l_cnt pls_integer;
begin
   out_msg := null;

   open c_oh(in_inot_orderid, in_inot_shipid);
   fetch c_oh into oh;
   rowfound := c_oh%found;
   close c_oh;
   if not rowfound then
      out_msg := 'Inbound notice not found';
      return;
   end if;

   if oh.ordertype != 'I' then
      out_msg := 'Order is not an inbound notice';
      return;
   end if;

   if oh.orderstatus > '9' then
      out_msg := 'Inbound notice is not open';
      return;
   end if;

   select count(1) into l_cnt
      from orderhdr
      where parentorderid = in_inot_orderid
        and parentshipid = in_inot_shipid
        and orderstatus < 'R';

   if l_cnt != 0 then
      out_msg := 'Inbound notice has '||l_cnt||' open child transload receipts';
      return;
   end if;

   update orderhdr
      set orderstatus = 'R',
          lastuser = in_userid,
          lastupdate = sysdate
    where rowid = oh.rowid;

   zoh.add_orderhistory(in_inot_orderid, in_inot_shipid,
      'Order Closed',
      'Order Closed',
      in_userid, out_msg);

   out_msg := 'OKAY';

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end close_inbound_notice;


procedure get_autoinc_value
   (in_custid  in varchar2,
    in_item    in varchar2,
    in_lotno   in varchar2,
    in_type    in varchar2,
    in_orderid in number,
    in_shipid  in number,
    out_value  out varchar2,
    out_msg    out varchar2)
is
   l_col varchar2(20);
begin
   out_value := null;
   out_msg := 'OKAY';

   if in_type = 'LOT' then
      l_col := 'lotnumber';
   elsif in_type = 'SER' then
      l_col := 'serialnumber';
   elsif in_type = 'US1' then
      l_col := 'useritem1';
   elsif in_type = 'US2' then
      l_col := 'useritem2';
   elsif in_type = 'US3' then
      l_col := 'useritem3';
   else
      return;
   end if;

   begin
      if in_lotno is not null then
         execute immediate 'select ' || l_col || ' from plate where orderid = :p_orderid'
               || ' and shipid = :p_shipid and item = :p_item and lotnumber = :p_lotno and rownum = 1'
            into out_value using in_orderid, in_shipid, in_item, in_lotno;
      else
         execute immediate 'select ' || l_col || ' from plate where orderid = :p_orderid'
               || ' and shipid = :p_shipid and item = :p_item and rownum = 1'
            into out_value using in_orderid, in_shipid, in_item;
      end if;
   exception
      when NO_DATA_FOUND then
         zci.get_auto_seq(in_custid, in_item, in_type, out_value);
   end;

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end get_autoinc_value;

procedure update_inbound_plate_dim
   (in_lpid    in varchar2,
    in_length  in number,
    in_width   in number,
    in_height  in number,
    in_plt_weight in number,
    in_user    in varchar2,
    out_msg    out varchar2)
is
  v_lpid plate%rowtype;
  v_dflt_length plate.length%type;
  v_dflt_width plate.width%type;
  v_dflt_height plate.height%type;
  v_dflt_plt_weight plate.pallet_weight%type;

  v_found char(1) := 'N';
begin
  out_msg := 'OKAY';

  begin
    select *
    into v_lpid
    from plate
    where lpid = in_lpid;
  exception
    when others then
      out_msg := 'Plate not found';
      return;
  end;

  begin
    select length, width, height, pallet_weight
    into v_dflt_length, v_dflt_width, v_dflt_height, v_dflt_plt_weight
    from custitem_inbound_dimensions
    where custid = v_lpid.custid and item = v_lpid.item and uom = v_lpid.uomentered and invclass = v_lpid.inventoryclass;

    v_found := 'I';
  exception
    when others then
      v_found := 'N';
  end;

  if (v_found = 'N') then
    begin
      select length, width, height, pallet_weight
      into v_dflt_length, v_dflt_width, v_dflt_height, v_dflt_plt_weight
      from cust_inbound_dimensions
      where custid = v_lpid.custid and uom = v_lpid.uomentered and invclass = v_lpid.inventoryclass;

      v_found := 'C';
    exception
      when others then
        v_found := 'N';
    end;
  end if;

  if (v_found = 'N') then
    out_msg := 'Dimensions should not be captured for this plate';
    return;
  end if;

  if (nvl(in_length,0) <> nvl(v_dflt_length,0) or nvl(in_width,0) <> nvl(v_dflt_width,0)
    or nvl(in_height,0) <> nvl(v_dflt_height,0) or nvl(in_plt_weight,0) <> nvl(v_dflt_plt_weight,0))
  then
    if (v_found = 'I') then
      update custitem_inbound_dimensions
      set length = nvl(in_length,0), width = nvl(in_width,0), height = nvl(in_height,0), pallet_weight = nvl(in_plt_weight,0),
        lastuser = in_user, lastupdate = sysdate
      where custid = v_lpid.custid and item = v_lpid.item and uom = v_lpid.uomentered and invclass = v_lpid.inventoryclass;
    elsif (v_found = 'C') then
      insert into custitem_inbound_dimensions (custid, item, uom, invclass,
        length, width, height, pallet_weight, lastuser, lastupdate)
      values (v_lpid.custid, v_lpid.item, v_lpid.uomentered, v_lpid.inventoryclass,
        nvl(in_length,0), nvl(in_width,0), nvl(in_height,0), nvl(in_plt_weight,0), in_user, sysdate);
    end if;
  end if;

  update plate
  set length = nvl(in_length,0), width = nvl(in_width, 0), height = nvl(in_height,0), pallet_weight = nvl(in_plt_weight,0),
        lastuser = in_user, lastupdate = sysdate
  where lpid = in_lpid;

exception
   when OTHERS then
      out_msg := substr(sqlerrm,1,80);
end update_inbound_plate_dim;

procedure get_useritem1_from_asn
   (in_orderid   in number,
    in_shipid    in number,
    in_item      in varchar2,
    out_useritem1 in out varchar2)
is
   cursor c_asn(in_ui1 varchar2) is
      select useritem1
        from asncartondtl
       where orderid = in_orderid
         and shipid = in_shipid
         and item = in_item
         and useritem1 > in_ui1
       order by useritem1;
   UI1 c_asn%rowtype;

   maxui1 plate.useritem1%type;
begin
   begin
     select max(useritem1) into maxui1
        from orderdtlrcpt
        where orderid = in_orderid
          and shipid = in_shipid
          and item = in_item;
   exception when others then
      maxui1 := null;
   end;
   if maxui1 is null then
      maxui1 := ' ';
   end if;
   UI1 := null;
   open c_asn(maxui1);
   fetch c_asn into UI1;
   close c_asn;
   if  UI1.useritem1 is null then
      return;
   end if;
   out_useritem1 := UI1.useritem1;
end;

procedure orderdtl_text
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotno      in varchar2,
    in_import_col in varchar2,
    out_text      out varchar2,
    out_msg       out varchar2)
is
cmdSql varchar2(255);
begin
   out_msg := 'OKAY';
   cmdSql := 'select ' || in_import_col || ' from orderdtl ' ||
             'where orderid = ' || in_orderid || ' and shipid = ' || in_shipid ||
             ' and item = ''' || in_item || ''' and nvl(lotnumber, ''(none)'') = ''' ||
               nvl(in_lotno, '(none)') || '''';
   execute immediate cmdSql into out_text;
   if out_text is null then
      out_msg := 'ERR';
   end if;
   return;
exception when others then
   out_msg := 'ERR';
end orderdtl_text;

procedure update_orderdtl_text
   (in_orderid    in number,
    in_shipid     in number,
    in_item       in varchar2,
    in_lotno      in varchar2,
    in_update_col in varchar2,
    in_text       in varchar2,
    out_msg       out varchar2)

is
cmdSql varchar2(10000);
strText varchar2(255);
strMsg varchar2(255);
begin
   out_msg := 'OKAY';
   select replace(in_text, '''','''''') into strText from dual;
   cmdSql := 'update orderdtl set ' || in_update_col || '= ''' || strText || '''' ||
             ' where orderid = ' || in_orderid || ' and shipid = ' || in_shipid ||
             '  and item = ''' || in_item || ''' and nvl(lotnumber, ''(none)'') = ''' ||
               nvl(in_lotno, '(none)') || '''';
  -- zms.log_autonomous_msg('TEST', null, '1CALJAM',cmdSql, 'D', 'TEST', strMsg);
   execute immediate cmdSql;
   return;
exception when others then
   out_msg := sqlerrm;
   --zms.log_autonomous_msg('TEST', null, '1CALJAM',out_msg, 'D', 'TEST', strMsg);
end update_orderdtl_text;

end zreceive;
/
show errors package body zreceive;

exit;
