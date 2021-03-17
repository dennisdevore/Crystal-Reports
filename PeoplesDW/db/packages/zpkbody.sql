CREATE OR REPLACE PACKAGE BODY ALPS.zpack as
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
CURSOR C_CARRIER(in_carrier varchar2)
RETURN carrier%rowtype
IS
    SELECT *
      FROM carrier
     WHERE carrier = in_carrier;

----------------------------------------------------------------------
CURSOR C_CARRIERSL(in_carrier varchar2, in_facility varchar2)
RETURN carrierstageloc%rowtype
IS
    SELECT *
      FROM carrierstageloc
     WHERE carrier = in_carrier
       AND facility = in_facility;

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
CURSOR C_ORDHDR_WAVE(in_wave number)
RETURN orderhdr%rowtype
IS
    SELECT *
      FROM orderhdr
     WHERE wave = in_wave;

----------------------------------------------------------------------
CURSOR C_LOCATION(in_facility varchar2, in_location varchar2)
RETURN location%rowtype
IS
    SELECT *
      FROM location
     WHERE facility = in_facility
       AND locid = in_location;

----------------------------------------------------------------------
CURSOR C_PLATE_ITEM(in_tote varchar2, in_item varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE parentlpid = in_tote
     AND   item = in_item;

----------------------------------------------------------------------
CURSOR C_ITEM_UPC(in_custid varchar2, in_item varchar2)
RETURN custitemupcview%rowtype
IS
    SELECT custid, item, itemalias
      FROM custitemalias
     WHERE custid = in_custid
     AND   aliasdesc like 'UPC%'
     AND   itemalias = in_item
     AND   nvl(partial_match_yn,'N') = 'N';

----------------------------------------------------------------------


-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- verify_carton
--
----------------------------------------------------------------------
PROCEDURE verify_carton
(
    in_carton       IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
   cnt integer;
BEGIN
    out_errmsg := 'OKAY';

    cnt := 0;

    select count(1)
       into cnt
       from plate
       where lpid = in_carton;
    if (cnt = 0) then
       select count(1)
          into cnt
          from deletedplate
          where lpid = in_carton;
      if (cnt = 0) then
       select count(1)
          into cnt
          from multishipdtl
          where cartonid = in_carton;
      end if;
    end if;

    if cnt > 0 then
        out_errmsg := 'Duplicate cartonid';
    end if;

END verify_carton;


----------------------------------------------------------------------
--
-- start_a_carton
--
----------------------------------------------------------------------
PROCEDURE start_a_carton
(
    in_tote         IN      varchar2,
    in_cartonid     IN      varchar2,
    in_user         IN      varchar2,
    out_carton      OUT     varchar2,
    out_errmsg      OUT     varchar2
)
IS
  TOTE plate%rowtype;
  CUST customer%rowtype;

  clip shippingplate.lpid%type := null;
  xlip plate.lpid%type := null;

  errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- get tote and order information
    TOTE := null;
    OPEN C_PLATE(in_tote);
    FETCH C_PLATE into TOTE;
    CLOSE C_PLATE;

    if TOTE.lpid is null then
       out_errmsg := 'Invalid tote';
       return;
    end if;

-- Get customer info for this order pick task
    CUST := null;
    OPEN C_CUST(TOTE.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

-- Verify cartonid
    if in_cartonid is not null then
        zpk.verify_carton(in_cartonid, errmsg);
        if errmsg != 'OKAY' then
            out_errmsg := errmsg;
            return;
        end if;
    end if;

-- create a carton shipping plate
    zsp.get_next_shippinglpid(clip, errmsg);
    if errmsg is not null then
       out_errmsg := errmsg;
       return;
    end if;

    if in_cartonid is not null then
        xlip := in_cartonid;
    else
        zrf.get_next_lpid(xlip, errmsg);
        if (errmsg is not null) then
           out_errmsg := errmsg;
           return;
        end if;
    end if;

    insert into shippingplate
         (lpid, facility, location, status, quantity, type,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          fromlpid, totelpid)
    values
         (clip, TOTE.facility, TOTE.location, 'PA', 0, 'C',
          in_user, sysdate, 0, NULL, TOTE.custid,
          TOTE.loadno, TOTE.stopno, TOTE.shipno, null, null,
          xlip, TOTE.lpid);

-- create the crossreference plate for the carton
    insert into plate
       (lpid, type, parentlpid, lastuser, lastupdate, lasttask, lastoperator, custid, facility)
    values
       (xlip, 'XP', clip, in_user, sysdate, 'PA', in_user, TOTE.custid, TOTE.facility);

-- assign the carton to the custid, orderid, shipid
   out_carton := xlip;

END start_a_carton;

----------------------------------------------------------------------
--
-- abandon_carton
--
----------------------------------------------------------------------
PROCEDURE abandon_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  TOTE plate%rowtype;
  CUST customer%rowtype;

  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

  cnt integer;

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- get tote and order information
    TOTE := null;
    OPEN C_PLATE(in_tote);
    FETCH C_PLATE into TOTE;
    CLOSE C_PLATE;

    if TOTE.lpid is null then
       out_errmsg := 'Invalid tote';
       return;
    end if;

-- Get customer info for this order pick task
    CUST := null;
    OPEN C_CUST(TOTE.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;


-- verify the carton is empty
   cnt := 0;
   select count(1)
     into cnt
     from shippingplate
    where parentlpid = CRTN.lpid;

   if cnt > 0 then
       out_errmsg := 'Carton is not empty. It can not be removed';
       return;
   end if;

-- delete the carton shipping plate
   delete from shippingplate
    where lpid = CRTN.lpid;

-- delete the carton crossreference
   delete from plate
    where lpid = CRTNX.lpid;


END abandon_carton;

----------------------------------------------------------------------
--
-- pick_item_into_carton
--
----------------------------------------------------------------------
PROCEDURE pick_item_into_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_lpid         IN      varchar2,
    in_qty          IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  TOTE plate%rowtype;
  CUST customer%rowtype;

  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

  PLT   plate%rowtype;
  SP    shippingplate%rowtype;

  err   varchar2(10);
  errmsg    varchar2(200);

  splip shippingplate.lpid%type := null;

  item_weight number(10,4);
  item_cube number(10,4);
  item_amt number(10,2);

  remqty commitments.qty%type;
  comrowid rowid;

  cnt integer;

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- get the customer and order information for this pack
-- get tote and order information
    TOTE := null;
    OPEN C_PLATE(in_tote);
    FETCH C_PLATE into TOTE;
    CLOSE C_PLATE;

    if TOTE.lpid is null then
       out_errmsg := 'Invalid tote';
       return;
    end if;

-- Get customer info for this order pick task
    CUST := null;
    OPEN C_CUST(TOTE.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;


   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;


-- get the plate and shipping plate info
    PLT := null;
    OPEN C_PLATE(in_lpid);
    FETCH C_PLATE into PLT;
    CLOSE C_PLATE;

    if PLT.lpid is null then
       out_errmsg := 'Invalid picking item';
       return;
    end if;

    if nvl(PLT.parentlpid,'XX') != TOTE.lpid then
       out_errmsg := 'Item not in specified tote.';
       return;
    end if;

    if in_qty > PLT.quantity then
       out_errmsg := 'Quantity to pack greater than available quantity..';
       return;
    end if;

    SP := null;
    OPEN C_SHIPPLATE(PLT.fromshippinglpid);
    FETCH C_SHIPPLATE into SP;
    CLOSE C_SHIPPLATE;

   cnt := 0;
   select count(1)
     into cnt
     from shippingplate
    where lpid = CRTN.lpid
      and (orderid != SP.orderid
           or shipid != SP.shipid);

    if nvl(cnt,0) > 0 then
       out_errmsg := 'Cannot mix orders in carton.';
       return;
    end if;

    update shippingplate
      set orderid = SP.orderid,
          shipid = SP.shipid,
          loadno = SP.loadno,
          stopno = SP.stopno,
          shipno = SP.shipno
     where lpid = CRTN.lpid;

-- if we are picking all of the item into the carton
   if in_qty = PLT.quantity then
--    put the shipping plate into the carton
      update shippingplate
         set parentlpid = CRTN.lpid
       where lpid = PLT.fromshippinglpid;

--    update carton by shipping amount
      update shippingplate
         set quantity = nvl(quantity, 0) + sp.quantity,
             weight = nvl(weight, 0) + sp.weight,
             orderid = SP.orderid,
             shipid = SP.shipid,
             loadno = SP.loadno,
             stopno = SP.stopno,
             shipno = SP.shipno
       where lpid = CRTN.lpid;

      if SP.type = 'P' then
--       delete the plate entry
         zrf.decrease_lp(
                 PLT.lpid,
                 PLT.custid,
                 PLT.item,
                 in_qty,
                 PLT.lotnumber,
                 PLT.unitofmeasure,
                 in_user,
                 PLT.lasttask,
                 PLT.invstatus,
                 PLT.inventoryclass,
                 err,
                 errmsg);
      else
         zplp.detach_child_plate(TOTE.lpid, PLT.lpid, PLT.location, null, null,
               PLT.status, in_user, PLT.lasttask, errmsg);
--       make sure tote keeps data needed for packing if it goes empty
         update plate
            set custid = TOTE.custid,
                orderid = TOTE.orderid,
                shipid = TOTE.shipid
            where lpid = TOTE.lpid;
      end if;
-- else
   else
--    create a new shipping plate from the old one
--    add the qty to the new SP
--    place the new SP in the carton
      zsp.get_next_shippinglpid(splip, errmsg);
      if errmsg is not null then
         out_errmsg := errmsg;
         return;
      end if;

      insert into shippingplate
        (
            lpid,
            item,
            custid,
            facility,
            location,
            status,
            holdreason,
            unitofmeasure,
            quantity,
            type,
            fromlpid,
            serialnumber,
            lotnumber,
            parentlpid,
            useritem1,
            useritem2,
            useritem3,
            lastuser,
            lastupdate,
            invstatus,
            qtyentered,
            orderitem,
            uomentered,
            inventoryclass,
            loadno,
            stopno,
            shipno,
            orderid,
            shipid,
            weight,
            ucc128,
            labelformat,
            taskid,
            dropseq,
            orderlot,
            pickuom,
            pickqty,
            trackingno,
            cartonseq,
            checked,
            manufacturedate,
            expirationdate
        )
      values
        (
            splip,
            SP.item,
            SP.custid,
            SP.facility,
            SP.location,
            SP.status,
            SP.holdreason,
            SP.unitofmeasure,
            in_qty,
            SP.type,
            SP.fromlpid,
            SP.serialnumber,
            SP.lotnumber,
            CRTN.lpid,
            SP.useritem1,
            SP.useritem2,
            SP.useritem3,
            SP.lastuser,
            SP.lastupdate,
            SP.invstatus,
            SP.qtyentered,
            SP.orderitem,
            SP.uomentered,
            SP.inventoryclass,
            SP.loadno,
            SP.stopno,
            SP.shipno,
            SP.orderid,
            SP.shipid,
            SP.weight *( in_qty/SP.quantity),
            SP.ucc128,
            SP.labelformat,
            SP.taskid,
            SP.dropseq,
            SP.orderlot,
            SP.pickuom,
            SP.pickqty,
            SP.trackingno,
            SP.cartonseq,
            SP.checked,
            SP.manufacturedate,
            SP.expirationdate
        );


--    update carton by shipping amount
      update shippingplate
         set quantity = nvl(quantity, 0) + in_qty,
             weight = nvl(weight, 0)
                  + SP.weight  *( (in_qty)/SP.quantity),
             orderid = SP.orderid,
             shipid = SP.shipid,
             loadno = SP.loadno,
             stopno = SP.stopno,
             shipno = SP.shipno
       where lpid = CRTN.lpid;


--    reduce the old SP by the qty
--    and switch any full to a partial
      update shippingplate
         set quantity = quantity - in_qty,
             weight = SP.weight  *( (SP.quantity - in_qty)/SP.quantity),
             type = 'P'
       where lpid = SP.lpid;

--    reduce the plate by the qty
      zrf.decrease_lp(
              PLT.lpid,
              PLT.custid,
              PLT.item,
              in_qty,
              PLT.lotnumber,
              PLT.unitofmeasure,
              in_user,
              PLT.lasttask,
              PLT.invstatus,
              PLT.inventoryclass,
              err,
              errmsg);

   end if;


   item_weight := zci.item_weight(SP.custid, SP.item,
               SP.unitofmeasure);

   item_cube := zci.item_cube(SP.custid, SP.item,
               SP.unitofmeasure);

   item_amt := zci.item_amt(SP.custid, SP.orderid, SP.shipid, SP.item, SP.lotnumber);  --prn 25133

  update commitments
     set qty = nvl(qty, 0) - in_qty,
         lastuser = in_user,
         lastupdate = sysdate
   where orderid = SP.orderid
     and shipid = SP.shipid
     and item = SP.orderitem
     and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)')
    returning qty, rowid into remqty, comrowid;

  if (sql%rowcount != 0) then
     if (remqty <= 0) then
        delete commitments
         where rowid = comrowid;
     end if;
  end if;

-- Update the quantity packed in the orderdtl
  update orderdtl
     set qty2pack = nvl(qty2pack, 0) - in_qty,
         weight2pack = nvl(weight2pack, 0) - (in_qty * item_weight),
         cube2pack = nvl(cube2pack, 0) - (in_qty * item_cube),
         amt2pack = nvl(amt2pack, 0) - (in_qty * item_amt)
   where orderid = SP.orderid
     and shipid = SP.shipid
     and item = SP.orderitem
     and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)');

-- if the tote is empty
--    release the tote

END pick_item_into_carton;


----------------------------------------------------------------------
--
-- unpick_item
--
----------------------------------------------------------------------
PROCEDURE unpick_item
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_lpid         IN      varchar2,
    in_qty          IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  TOTE plate%rowtype;
  CUST customer%rowtype;

  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

  SP  shippingplate%rowtype;
  PLT plate%rowtype;

  l_lpid plate.lpid%type := null;

  errmsg varchar2(255);

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- get the info for the tote and the order
    TOTE := null;
    OPEN C_PLATE(in_tote);
    FETCH C_PLATE into TOTE;
    CLOSE C_PLATE;

    if TOTE.lpid is null then
       out_errmsg := 'Invalid tote';
       return;
    end if;

-- Get customer info for this order pick task
    CUST := null;
    OPEN C_CUST(TOTE.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;


   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

-- Get Shipping plate of item.
   SP := null;
   OPEN C_SHIPPLATE(in_lpid);
   FETCH C_SHIPPLATE into SP;
   CLOSE C_SHIPPLATE;
   if SP.lpid is null then
       out_errmsg := 'Invalid item shipping plate.';
       return;
   end if;


-- Locate plate in tote for this item
   PLT := null;
   begin
   select P.*
     into PLT
     from plate P, shippingplate S
    where P.parentlpid = in_tote
      and P.item = SP.item
      and nvl(P.lotnumber, '(none)') = nvl(SP.lotnumber,'(none)')
      and S.lpid = P.fromshippinglpid
      and S.orderid = SP.orderid
      and S.shipid = SP.shipid;
   exception when others then
    PLT := null;
   end;

-- if we still have a plate for the item
    if PLT.lpid is not null then
--    add qty unpicking to the plate
      update plate
         set quantity = quantity + SP.quantity,
             weight = weight + SP.weight
       where lpid = PLT.lpid;
--    add qty unpicking to the tote
      update plate
         set quantity = quantity + SP.quantity,
             weight = weight + SP.weight
       where lpid = TOTE.lpid;
--    add qty unpicking to the old SP
      update shippingplate
         set quantity = quantity + SP.quantity,
             weight = weight + SP.weight
       where lpid = PLT.fromshippinglpid;
-- Remove packed shippingplate
      delete from shippingplate
       where lpid = SP.lpid;
-- Decrease Carton
      update shippingplate
         set quantity = quantity - SP.quantity,
             weight = weight - SP.weight
       where lpid = CRTN.lpid;

-- else
    else
--    create plate for the item
    zrf.get_next_lpid(l_lpid, errmsg);
    if (errmsg is not null) then
       out_errmsg := errmsg;
       return;
    end if;

    insert into plate (lpid, item, lotnumber, orderid, shipid,
        custid, facility, location, status,
        unitofmeasure, quantity, type, creationdate, lastoperator,
        lasttask, parentlpid, lastuser, lastupdate, invstatus,
        qtyentered, itementered, uomentered, inventoryclass,
        weight, fromlpid, taskid, fromshippinglpid, childfacility,
        childitem)
    values (l_lpid, SP.item, SP.lotnumber, SP.orderid, SP.shipid,
        SP.custid, SP.facility, SP.location, 'M',
        SP.unitofmeasure, SP.quantity, 'PA', sysdate, in_user,
        'UP', in_tote, in_user, sysdate, SP.invstatus,
        SP.quantity, SP.item, SP.unitofmeasure, SP.inventoryclass,
        SP.weight, SP.fromlpid, TOTE.taskid, SP.lpid, SP.facility,
        SP.item);
--    add qty to the plate
    update plate
       set quantity = quantity + SP.quantity,
           weight = weight + SP.weight,
           orderid = SP.orderid,
           shipid = SP.shipid
     where lpid = TOTE.lpid;

--    attach SP to plate
    update shippingplate
       set parentlpid = null
     where lpid = SP.lpid;
-- Reduce carton
    update shippingplate
       set quantity = quantity - SP.quantity,
           weight = weight - SP.weight
     where lpid = CRTN.lpid;


    end if;

-- Clear orderid in carton if no contents
    update shippingplate
       set orderid = null,
           shipid = null
     where lpid = CRTN.lpid
       and quantity = 0;


END unpick_item;

----------------------------------------------------------------------
--
-- print_a_carton
--
----------------------------------------------------------------------
PROCEDURE print_a_carton
(
    in_carton       IN      varchar2,
    in_event        IN      varchar2,
    in_slbl         IN      varchar2,
    in_mlbl         IN      varchar2,
    in_llbl         IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;
  ORD orderhdr%rowtype;

  CURSOR C_profid(in_custid varchar2, in_consignee varchar2)
  IS
    SELECT profid, consignee
      FROM custitemlabelprofiles
     WHERE custid = in_custid
       AND NVL(consignee, in_consignee) = in_consignee
       AND item is null
     ORDER BY
          decode(consignee, in_consignee, -2, 0);
--          + decode(item, in_item, -1, 0);

  CURSOR C_LPL_CNT(in_profid varchar2, in_event varchar2, in_orderid number, in_shipid number)
  IS
    SELECT count(1)
      FROM labelprofileline
     WHERE profid = in_profid
       AND businessevent = in_event
       AND uom is null
       AND zlbl.is_order_satisfied(in_orderid, in_shipid, passthrufield, passthruvalue) = 'Y';

  CURSOR C_LPL(in_profid varchar2, in_event varchar2, in_orderid number, in_shipid number)
  IS
    SELECT rowidtochar(rowid) RID, printerstock, print
      FROM labelprofileline
     WHERE profid = in_profid
       AND businessevent = in_event
       AND uom is null
       AND zlbl.is_order_satisfied(in_orderid, in_shipid, passthrufield, passthruvalue) = 'Y';

  PROF C_PROFID%rowtype;
  cnt integer;
  printer varchar2(10);

  errmsg varchar2(200);

BEGIN
    out_errmsg := 'OKAY';

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

-- Get order information for this carton etc.
    ORD := null;
    if CRTN.shipid = 0 then
        OPEN C_ORDHDR_WAVE(CRTN.orderid);
        FETCH C_ORDHDR_WAVE into ORD;
        CLOSE C_ORDHDR_WAVE;
    else
        OPEN C_ORDHDR(CRTN.orderid, CRTN.shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
    end if;

    if ORD.orderid is null then
       out_errmsg := 'No order found for this carton!!!';
       return;
    end if;

-- Check to see if we have any profiles to use in order

   PROF := null;
   for crec in C_PROFID(CRTN.custid, nvl(ORD.shipto,'(none)')) loop
      cnt := 0;
      OPEN C_LPL_CNT(crec.profid, in_event, CRTN.orderid, CRTN.shipid);
      FETCH C_LPL_CNT into cnt;
      CLOSE C_LPL_CNT;

     if nvl(cnt, 0) > 0 then
        PROF := crec;
        exit;
     end if;

   end loop;

   if PROF.profid is null then
      out_errmsg := 'No labels found to print';
      return;
   end if;


   for crec in C_LPL(PROF.profid, in_event, CRTN.orderid, CRTN.shipid) loop
       if crec.printerstock = 'S' then
          printer := in_slbl;
       elsif crec.printerstock = 'M' then
          printer := in_mlbl;
       elsif crec.printerstock = 'L' then
          printer := in_llbl;
       else
          printer := null;
       end if;
       if printer is not null and crec.print = 'Y' then
        --  zut.prt('LPID:'|| CRTN.lpid
        --    ||' PROF:'||PROF.profid
        --    ||' Printer:'||printer);

          zlbl.print_a_plate(CRTN.lpid, crec.RID, printer, CRTN.facility,
            in_user, errmsg, 'A');

       end if;
   end loop;

END print_a_carton;

----------------------------------------------------------------------
--
-- route_a_carton - determine how to route a carton based on carrier type
--
----------------------------------------------------------------------
PROCEDURE route_a_carton
(
    in_carton       IN      varchar2,
    out_location    OUT     varchar2,
    out_type        OUT     varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;
  ORD orderhdr%rowtype;
  CARR carrier%rowtype;
  CSL carrierstageloc%rowtype;

  CURSOR C_STAGELOC(in_orderid varchar2, in_shipid varchar2)
  IS
    SELECT stageloc
       FROM orderhdrview
      WHERE orderid = in_orderid
        AND shipid = in_shipid;

  stageloc orderhdr.stageloc%type;

BEGIN
  out_errmsg := 'OKAY';
  out_type := null;
  out_location := null;

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

-- Get order information for this carton etc.
    ORD := null;
    if CRTN.shipid = 0 then
        OPEN C_ORDHDR_WAVE(CRTN.orderid);
        FETCH C_ORDHDR_WAVE into ORD;
        CLOSE C_ORDHDR_WAVE;
    else
        OPEN C_ORDHDR(CRTN.orderid, CRTN.shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
    end if;

    if ORD.orderid is null then
       out_errmsg := 'No order found for this carton!!!';
       return;
    end if;

-- Get carrier information
   CARR := null;
   OPEN C_CARRIER(ORD.carrier);
   FETCH C_CARRIER into CARR;
   CLOSE C_CARRIER;

   CSL := null;
   OPEN C_CARRIERSL(ORD.carrier, CRTN.facility);
   FETCH C_CARRIERSL into CSL;
   CLOSE C_CARRIERSL;

-- if carrier is small package;
   out_type := CARR.carriertype;

   stageloc := NULL;
   OPEN C_STAGELOC(ORD.orderid, ORD.shipid);
   FETCH C_STAGELOC into stageloc;
   CLOSE C_STAGELOC;

   if CARR.carriertype = 'S' then
      null;
      if stageloc is not null then
         out_location := stageloc;
         return;
      end if;
      out_location := CSL.stageloc;
      return;
   else
      out_location := stageloc;
   end if;

END route_a_carton;

----------------------------------------------------------------------
--
-- close_a_carton
--
----------------------------------------------------------------------
PROCEDURE close_a_carton
(
    in_carton       IN      varchar2,
    in_type         IN      varchar2,
    in_location     IN      varchar2,
    in_weight       IN      number,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;
  ORD orderhdr%rowtype;

  CURSOR C_SPR(in_lpid varchar2)
  IS
     SELECT rowidtochar(rowid) RID
       FROM shippingplate
      WHERE lpid = in_lpid;

  SPR C_SPR%rowtype;

  cnt integer;

  errmsg varchar2(200);

BEGIN
  out_errmsg := 'OKAY';

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

-- Get order information for this carton etc.
    ORD := null;
    if CRTN.shipid = 0 then
        OPEN C_ORDHDR_WAVE(CRTN.orderid );
        FETCH C_ORDHDR_WAVE into ORD;
        CLOSE C_ORDHDR_WAVE;
    else
        OPEN C_ORDHDR(CRTN.orderid, CRTN.shipid);
        FETCH C_ORDHDR into ORD;
        CLOSE C_ORDHDR;
    end if;

    if ORD.orderid is null then
       out_errmsg := 'No order found for this carton!!!';
       return;
    end if;

-- update carton status and wieght (if provided)
-- if small package update multiship tables
--
   if in_weight is not null then
      update shippingplate
         set weight = in_weight
       where lpid = CRTN.lpid;
   end if;

   SPR := null;
   OPEN C_SPR(CRTN.lpid);
   FETCH C_SPR into SPR;
   CLOSE C_SPR;

   zrf.move_shippingplate(SPR.rid,
        in_location,
        'S',
        in_user,
        'PK',
        errmsg);

  if errmsg is not null then
     out_errmsg := errmsg;
     return;
  end if;

  if in_type = 'S' then
  -- need to ship a carton here ???? add routine to zmnbody
     zmn.stage_carton(in_carton, 'pack', out_errmsg);

  end if;

  --update shippingplate
  --set totelpid=null
  --where lpid = CRTN.lpid;

  for crec in (select distinct orderid, shipid
                 from shippingplate
                where parentlpid = CRTN.lpid)
  loop

      ORD := null;
      OPEN C_ORDHDR(crec.orderid, crec.shipid);
      FETCH C_ORDHDR into ORD;
      CLOSE C_ORDHDR;


      update orderhdr
         set orderstatus = zrf.ORD_PICKED,
             lastuser = in_user,
             lastupdate = sysdate
         where orderid = ORD.ORDERID
           and shipid = ORD.SHIPID
           and orderstatus < zrf.ORD_PICKED
           and qtycommit = 0;

      if (ORD.LOADNO is not null) then
         select count(1) into cnt
            from orderhdr
            where loadno = ORD.LOADNO
             and stopno = ORD.STOPNO
             and orderstatus < zrf.ORD_PICKED;
         if (cnt = 0) then
            update loadstop
               set loadstopstatus = zrf.LOD_PICKED,
                   lastuser = in_user,
                   lastupdate = sysdate
               where loadno = ORD.LOADNO
                 and stopno = ORD.STOPNO
                 and loadstopstatus < zrf.LOD_PICKED;
            select count(1) into cnt
               from loadstop
               where loadno = ORD.LOADNO
                 and loadstopstatus < zrf.LOD_PICKED;
            if (cnt = 0) then
               update loads
                  set loadstatus = zrf.LOD_PICKED,
                      lastuser = in_user,
                      lastupdate = sysdate
                  where loadno = ORD.LOADNO
                    and loadstatus < zrf.LOD_PICKED;
            end if;
         end if;
      end if;
  end loop;

END close_a_carton;




----------------------------------------------------------------------
--
-- bind_carton
--
----------------------------------------------------------------------
PROCEDURE bind_carton
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

   update shippingplate
      set totelpid = in_tote
    where lpid = CRTN.lpid;

END bind_carton;


----------------------------------------------------------------------
--
-- unbind_carton
--
----------------------------------------------------------------------
PROCEDURE unbind_carton
(
    in_carton       IN      varchar2,
    in_user         IN      varchar2,
    out_errmsg      OUT     varchar2
)
IS
  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       return;
   end if;

   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       return;
   end if;

   update shippingplate
      set totelpid = null
    where lpid = CRTN.lpid;

END unbind_carton;


----------------------------------------------------------------------
--
-- pick_item_into_carton_by_upc
--
----------------------------------------------------------------------
PROCEDURE pick_item_into_carton_by_upc
(
    in_tote         IN      varchar2,
    in_carton       IN      varchar2,
    in_item         IN      varchar2,
    in_qty          IN      number,
  in_old_qty      IN      number,
    in_user         IN      varchar2,
  out_errnum      OUT     number,
    out_errmsg      OUT     varchar2
)
IS
  TOTE plate%rowtype;
  CUST customer%rowtype;

  CRTNX plate%rowtype;
  CRTN  shippingplate%rowtype;

  PLT   plate%rowtype;
  SP    shippingplate%rowtype;
  UPC   custitemupcview%rowtype;

  err   varchar2(10);
  errmsg    varchar2(200);

  splip shippingplate.lpid%type := null;

  item_weight number(10,4);
  item_cube number(10,4);
  item_amt number(10,2);
  cnt integer;
  new_qty number(10,2);
  old_qty number(10,2);
  pack_qty number(10,2);
  item_code varchar(20);
  remqty commitments.qty%type;
  comrowid rowid;

BEGIN
    out_errmsg := 'OKAY';       -- assume everything is OK
    out_errnum := 0;

-- get the customer and order information for this pack
-- get tote and order information
    TOTE := null;
    OPEN C_PLATE(in_tote);
    FETCH C_PLATE into TOTE;
    CLOSE C_PLATE;

    if TOTE.lpid is null then
       out_errmsg := 'Invalid tote';
       out_errnum := 1;
       return;
    end if;

-- Get customer info for this order pick task
    CUST := null;
    OPEN C_CUST(TOTE.custid);
    FETCH C_CUST into CUST;
    CLOSE C_CUST;

-- read the carton and the shippingplate
   CRTNX := null;
   OPEN C_PLATE(in_carton);
   FETCH C_PLATE into CRTNX;
   CLOSE C_PLATE;
   if CRTNX.lpid is null then
       out_errmsg := 'Invalid carton.';
       out_errnum := 1;
       return;
   end if;

   if CRTNX.type != 'XP' then
       out_errmsg := 'Specified lpid not for a carton reference.';
       out_errnum := 1;
       return;
   end if;


   CRTN := null;
   OPEN C_SHIPPLATE(CRTNX.parentlpid);
   FETCH C_SHIPPLATE into CRTN;
   CLOSE C_SHIPPLATE;
   if CRTN.lpid is null then
       out_errmsg := 'Invalid carton shipping plate.';
       out_errnum := 1;
       return;
   end if;

   if CRTN.type != 'C' then
       out_errmsg := 'Specified lpid not for a carton.';
       out_errnum := 1;
       return;
   end if;

   cnt := 0;
   select count(1)
   into cnt
   from custitem
   where custid = CUST.CUSTID
   and item = in_item;

   item_code := '';
   if cnt = 0 then
--   retrieve the item from upc code
     UPC := null;
     OPEN C_ITEM_UPC(CUST.CUSTID, in_item);
     FETCH C_ITEM_UPC into UPC;
     CLOSE C_ITEM_UPC;
     if UPC.item is null then
         out_errmsg := 'Invalid item code.';
     out_errnum := 2;
         return;
     end if;

   item_code := UPC.item;
   else
     item_code := in_item;
   end if;

-- verify there is enough quantity to pack
   cnt := 0;
   select nvl(sum(quantity),0)
   into cnt
   from totecontentsview
   where totelpid = in_tote
   and item = item_code;

   if (cnt + in_old_qty) < in_qty then
       out_errmsg := 'Quantity to pack greater than available quantity.';
     out_errnum := 3;
       return;
   end if;

   new_qty := in_qty;
   old_qty := in_old_qty;
   pack_qty := 0;

-- get the plate and shipping plate info
   for PLT in C_PLATE_ITEM(in_tote, item_code) loop
      SP := null;
      OPEN C_SHIPPLATE(PLT.fromshippinglpid);
      FETCH C_SHIPPLATE into SP;
      CLOSE C_SHIPPLATE;

      cnt := 0;
      select count(1)
        into cnt
        from shippingplate
       where lpid = CRTN.lpid
         and (orderid != SP.orderid
              or shipid != SP.shipid);

       if nvl(cnt,0) > 0 then
          out_errmsg := 'Cannot mix orders in carton.';
          return;
       end if;

       update shippingplate
         set orderid = SP.orderid,
             shipid = SP.shipid
        where lpid = CRTN.lpid;


    if new_qty < (PLT.quantity + old_qty) then
      pack_qty := new_qty;
      else
      pack_qty := (PLT.quantity + old_qty);
    end if;

    select max(lpid)
    into splip
    from shippingplate
    where parentlpid = CRTN.lpid
    and item = SP.item;

      item_weight := zci.item_weight(SP.custid, SP.item,
                SP.unitofmeasure);

      item_cube := zci.item_cube(SP.custid, SP.item,
                SP.unitofmeasure);

      item_amt := zci.item_amt(SP.custid, SP.orderid, SP.shipid, SP.item, SP.lotnumber);  --prn 25133

      if splip is null then
      if pack_qty < PLT.quantity then
--        create a new shipping plate from the old one
--        add the qty to the new SP
--        place the new SP in the carton
          zsp.get_next_shippinglpid(splip, errmsg);
          if errmsg is not null then
            out_errmsg := errmsg;
            out_errnum := 1;
            return;
          end if;

          insert into shippingplate
          (
              lpid,
              item,
              custid,
              facility,
              location,
              status,
              holdreason,
              unitofmeasure,
              quantity,
              type,
              fromlpid,
              serialnumber,
              lotnumber,
              parentlpid,
              useritem1,
              useritem2,
              useritem3,
              lastuser,
              lastupdate,
              invstatus,
              qtyentered,
              orderitem,
              uomentered,
              inventoryclass,
              loadno,
              stopno,
              shipno,
              orderid,
              shipid,
              weight,
              ucc128,
              labelformat,
              taskid,
              dropseq,
              orderlot,
              pickuom,
              pickqty,
              trackingno,
              cartonseq,
              checked,
              manufacturedate,
              expirationdate
            )
          values
            (
              splip,
              SP.item,
              SP.custid,
              SP.facility,
              SP.location,
              SP.status,
              SP.holdreason,
              SP.unitofmeasure,
              pack_qty,
              SP.type,
              SP.fromlpid,
              SP.serialnumber,
              SP.lotnumber,
              CRTN.lpid,
              SP.useritem1,
              SP.useritem2,
              SP.useritem3,
              SP.lastuser,
              SP.lastupdate,
              SP.invstatus,
              SP.qtyentered,
              SP.orderitem,
              SP.uomentered,
              SP.inventoryclass,
              SP.loadno,
              SP.stopno,
              SP.shipno,
              SP.orderid,
              SP.shipid,
              SP.weight *( pack_qty/SP.quantity),
              SP.ucc128,
              SP.labelformat,
              SP.taskid,
              SP.dropseq,
              SP.orderlot,
              SP.pickuom,
              SP.pickqty,
              SP.trackingno,
              SP.cartonseq,
              SP.checked,
              SP.manufacturedate,
              SP.expirationdate
            );

--          update carton by shipping amount
            update shippingplate
               set quantity = nvl(quantity, 0) + pack_qty,
                   weight = nvl(weight, 0) + (item_weight * pack_qty),
                   orderid = SP.orderid,
                   shipid = SP.shipid
             where lpid = CRTN.lpid;

--          reduce the old SP by the qty
            update shippingplate
               set quantity = quantity - pack_qty,
                   weight = nvl(weight, 0) - (item_weight * pack_qty)
             where lpid = SP.lpid;
    else
--        put the shipping plate into the carton
          update shippingplate
             set parentlpid = CRTN.lpid
           where lpid = PLT.fromshippinglpid;

--        update carton by shipping amount
          update shippingplate
             set quantity = nvl(quantity, 0) + pack_qty,
                 weight = nvl(weight, 0) + (item_weight * pack_qty),
                 orderid = SP.orderid,
                 shipid = SP.shipid
           where lpid = CRTN.lpid;
        end if;
      else
--      if old qty > 0, move items from carton to old SP
      if old_qty > 0 then

--        reduce the shipping plate by the old qty
          update shippingplate
             set quantity = quantity - old_qty,
                 weight = nvl(weight, 0) - (item_weight * old_qty)
           where lpid = splip;

--        reduce the carton by the old qty
          update shippingplate
             set quantity = quantity - old_qty,
                 weight = nvl(weight, 0) - (item_weight * old_qty),
                 orderid = SP.orderid,
                 shipid = SP.shipid
           where lpid = CRTN.lpid;

--        increase the old SP by the old qty
          update shippingplate
             set quantity = nvl(quantity, 0) + old_qty,
                 weight = nvl(weight, 0) + (item_weight * old_qty)
           where lpid = SP.lpid;

--        increase the plate by the old qty
          update plate
             set quantity = nvl(quantity, 0) + old_qty,
                 weight = nvl(weight, 0) + (item_weight * old_qty)
           where lpid = PLT.lpid;

--        increase the tote by the old qty
          update plate
             set quantity = nvl(quantity, 0) + old_qty,
                 weight = nvl(weight, 0) + (item_weight * old_qty)
           where lpid = TOTE.lpid;

          update commitments
             set qty = nvl(qty, 0) + old_qty
           where orderid = SP.orderid
             and shipid = SP.shipid
             and item = SP.orderitem
             and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)');

--        Update the quantity packed in the orderdtl
          update orderdtl
             set qty2pack = nvl(qty2pack, 0) + old_qty,
                 weight2pack = nvl(weight2pack, 0) + (old_qty * item_weight),
                 cube2pack = nvl(cube2pack, 0) + (old_qty * item_cube),
                 amt2pack = nvl(amt2pack, 0) + (old_qty * item_amt)
           where orderid = SP.orderid
             and shipid = SP.shipid
             and item = SP.orderitem
             and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)');

          old_qty := 0;
    end if;

      if pack_qty < PLT.quantity then
--        update shipping plate by shipping amount
          update shippingplate
             set quantity = nvl(quantity, 0) + pack_qty,
                 weight = nvl(weight, 0) + (item_weight * pack_qty)
           where lpid = splip;

--        update carton by shipping amount
          update shippingplate
             set quantity = nvl(quantity, 0) + pack_qty,
                 weight = nvl(weight, 0) + (item_weight * pack_qty),
                 orderid = SP.orderid,
                 shipid = SP.shipid
           where lpid = CRTN.lpid;

--        reduce the old SP by the qty
          update shippingplate
             set quantity = quantity - pack_qty,
                 weight = nvl(weight, 0) - (item_weight * pack_qty)
           where lpid = SP.lpid;
        else
--        put the shipping plate into the carton
          update shippingplate
             set parentlpid = CRTN.lpid
           where lpid = PLT.fromshippinglpid;

--        update carton by shipping amount
          update shippingplate
             set quantity = nvl(quantity, 0) + pack_qty,
                 weight = nvl(weight, 0) + (item_weight * pack_qty),
                 orderid = SP.orderid,
                 shipid = SP.shipid
           where lpid = CRTN.lpid;
    end if;
      end if;

--    reduce the plate by the qty
      zrf.decrease_lp(
              PLT.lpid,
              PLT.custid,
              PLT.item,
              pack_qty,
              PLT.lotnumber,
              PLT.unitofmeasure,
              in_user,
              PLT.lasttask,
              PLT.invstatus,
              PLT.inventoryclass,
              err,
              errmsg);

    update commitments
       set qty = nvl(qty, 0) - pack_qty,
           lastuser = in_user,
           lastupdate = sysdate
     where orderid = SP.orderid
       and shipid = SP.shipid
       and item = SP.orderitem
       and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)')
    returning qty, rowid into remqty, comrowid;

    if (sql%rowcount != 0) then
       if (remqty <= 0) then
          delete commitments
           where rowid = comrowid;
       end if;
    end if;

--   Update the quantity packed in the orderdtl
     update orderdtl
       set qty2pack = nvl(qty2pack, 0) - pack_qty,
           weight2pack = nvl(weight2pack, 0) - (pack_qty * item_weight),
           cube2pack = nvl(cube2pack, 0) - (pack_qty * item_cube),
           amt2pack = nvl(amt2pack, 0) - (pack_qty * item_amt)
     where orderid = SP.orderid
       and shipid = SP.shipid
       and item = SP.orderitem
       and nvl(lotnumber, '(none)') = nvl(SP.lotnumber, '(none)');

   new_qty := new_qty - pack_qty;
   if new_qty <= 0 then
     exit;
     end if;

   end loop;

END pick_item_into_carton_by_upc;


FUNCTION packing_comments
(
    in_orderid      IN      number,
    in_shipid       IN      number
)
RETURN varchar2
IS

cursor c_cv(in_orderid number, in_shipid number)
is
select *
  from outcustcmtview
 where orderid = in_orderid
   and shipid = in_shipid;

cv c_cv%rowtype;


out_cmt varchar2(4000);
len integer;

BEGIN
    out_cmt := '';

    cv := null;
    open c_cv(in_orderid,in_shipid);
    fetch c_cv into cv;
    close c_cv;

    out_cmt := substr(cv.ohc_comment,1,4000);

    len := length(out_cmt);

    if len > 0 then
        out_cmt := out_cmt || chr(13) || chr(10);
        len := length(out_cmt);
    end if;


    if cv.ci_custid is not null then
        out_cmt := out_cmt || substr(cv.ci_comment,1,4000 - len);
    else
        out_cmt := out_cmt || substr(cv.cid_comment,1,4000 - len);
    end if;

    return out_cmt;
EXCEPTION WHEN OTHERS THEN
    return 'Failed lookup of comments';
END packing_comments;


FUNCTION item_packing_comments
(
    in_orderid      IN      number,
    in_shipid       IN      number,
    in_item         IN      varchar2,
    in_lotnumber    IN      varchar2
)
RETURN varchar2
IS

cursor c_cv(in_orderid number, in_shipid number,
    in_item varchar2, in_lotnumber varchar2)
is
select *
  from outitmcmtview
 where orderid = in_orderid
   and shipid = in_shipid
   and item = in_item
   and lotnumber = nvl(in_lotnumber,'**NULL**');
cv c_cv%rowtype;


out_cmt varchar2(4000);
len integer;

BEGIN
    out_cmt := '';

    cv := null;
    open c_cv(in_orderid,in_shipid,in_item, in_lotnumber);
    fetch c_cv into cv;
    close c_cv;

    out_cmt := substr(cv.od_comment,1,4000);

    len := length(out_cmt);

    if len > 0 then
        out_cmt := out_cmt || chr(13) || chr(10);
        len := length(out_cmt);
    end if;


    if cv.ci_item is not null then
        out_cmt := out_cmt || substr(cv.ci_comment,1,4000 - len);
    else
        out_cmt := out_cmt || substr(cv.cid_comment,1,4000 - len);
    end if;

    return out_cmt;
EXCEPTION WHEN OTHERS THEN
    return 'Failed lookup of comments';
END item_packing_comments;

PROCEDURE print_carton_pack_list
(in_orderid IN number
,in_shipid IN number
,in_cartonid IN varchar2
,in_printer IN varchar2
,in_report IN varchar2
,in_userid IN varchar2
,out_msg IN OUT varchar2
)
is
strMsg varchar2(255);
begin
   out_msg := 'OKAY';

   zmnq.send_shipping_msg(in_orderid,
                          in_shipid,
                          in_printer,
                          in_report,
                          in_cartonid,
						  null,
                          strMsg);
                          
exception when others then
  out_msg := substr(sqlerrm,1,255);
end;
FUNCTION carton_packlist_format
(in_custid IN varchar2
)
RETURN varchar2
is
out_carton_packlist_format customer_aux.carton_packlist_format%type;
begin
out_carton_packlist_format := null;
begin
  select carton_packlist_format
    into out_carton_packlist_format
    from customer_aux
   where custid = in_custid;
exception when others then
   null;
end;
if out_carton_packlist_format is null then
  out_carton_packlist_format := zci.default_value('CARTONPACKLISTREPORT');
end if;
return nvl(out_carton_packlist_format,'(none)');
exception when others then
  out_carton_packlist_format := null;
end carton_packlist_format;
end zpack;
/

show errors package body zpack;
exit;
