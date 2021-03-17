CREATE OR REPLACE PACKAGE BODY zsplitorder
IS
--
-- $Id$
--
-- ******************************************************************
-- *                                                                *
-- *    CONSTANTS                                                   *
-- *                                                                *
-- ******************************************************************


-- ******************************************************************
-- *                                                                *
-- *    CURSORS                                                     *
-- *                                                                *
-- ******************************************************************

-- ******************************************************************
-- *                                                                *
-- *  MESSAGING FUNCTIONS                                           *
-- *                                                                *
-- ******************************************************************

lock_id CONSTANT number := 1234;


----------------------------------------------------------------------
--
-- lock_it
--
----------------------------------------------------------------------
PROCEDURE lock_it
(
    out_errmsg  OUT varchar2
)
IS
errno number;
BEGIN
    out_errmsg := 'OKAY';

    errno := dbms_lock.request(lock_id,
                2,
                dbms_lock.maxwait,
                TRUE);
    if errno not in (0) then
        out_errmsg := 'Lock failed. Code='||errno;

    end if;

END lock_it;

----------------------------------------------------------------------
--
-- block_it
--
----------------------------------------------------------------------
PROCEDURE block_it
(
    out_errmsg  OUT varchar2
)
IS
errno number;
BEGIN
    out_errmsg := 'OKAY';

    errno := dbms_lock.request(lock_id,
                6,
                dbms_lock.maxwait,
                TRUE);
    if errno not in (0, 4) then
        out_errmsg := 'Lock failed. Code='||errno;

    end if;

END block_it;

----------------------------------------------------------------------
--
-- release_it
--
----------------------------------------------------------------------
PROCEDURE release_it
(
    out_errmsg  OUT varchar2
)
IS
errno number;
BEGIN
    out_errmsg := 'OKAY';

    errno := dbms_lock.release(lock_id);

    if errno not in (0, 4) then
        out_errmsg := 'Lock release failed. Code='||errno;

    end if;

END release_it;

----------------------------------------------------------------------
--
-- split_order
--
----------------------------------------------------------------------
PROCEDURE split_order
(
    in_orderid  number,
    in_shipid   number,
    in_userid   varchar2,
    out_errmsg  OUT varchar2
)
IS
CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid
FOR UPDATE;

ORD orderhdr%rowtype;
NORD orderhdr%rowtype;


CURSOR C_ODL(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and nvl(xdock,'N') = 'N'
   order by linenumber;


CURSOR C_CUSTOMER(in_custid varchar2) is
  select linenumbersyn
    from customer
   where custid = in_custid;
CUS C_CUSTOMER%ROWTYPE;

qtyShip integer;
qtyLine integer;

cordid waves.wave%type;
l_shipid orderhdr.shipid%type;

errno number;
errmsg varchar2(255);

l_qty orderdtl.qtyorder%type;
l_wt orderdtl.weightorder%type;
l_cube orderdtl.cubeorder%type;
l_amt orderdtl.amtorder%type;


tot_qty orderhdr.qtyorder%type;
tot_wt orderhdr.weightorder%type;
tot_cube orderhdr.cubeorder%type;
tot_amt orderhdr.amtorder%type;

minlss loadstop.loadstopstatus%type;
maxlss loadstop.loadstopstatus%type;
newloadstopstatus loadstop.loadstopstatus%type;
newloadstatus loads.loadstatus%type;

c_dat cdata;

cnt integer;

BEGIN
    out_errmsg := 'OKAY';


-- Verify Order not fully loaded
    cnt := 0;
    select count(1)
      into cnt
     from orderdtl D
     where D.orderid = in_orderid
       and D.shipid = in_shipid
       and nvl(D.qtyorder,0) > nvl(D.qtyship,0)
       and D.linestatus != 'X';

-- If there are no order lines to split don't split
    if nvl(cnt,0) = 0 then
        return;
    end if;

-- Lock the global lock;


    SAVEPOINT retry_order;
    block_it(errmsg);
    if errmsg != 'OKAY' then
        out_errmsg := errmsg;
        return;
    end if;

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

-- Do not allow consolidated orders to be split
    cordid := zcord.cons_orderid(in_orderid, in_shipid);

    if nvl(cordid,0) > 0 then
        rollback to retry_order;
        out_errmsg := 'Cannot split a consolidated order.';
        release_it(errmsg);
        return;
    end if;

-- If nothing loaded yet just remove from order
    if nvl(ORD.qtyship,0) = 0 then
        zld.deassign_order_from_load(ORD.orderid, ORD.shipid, ORD.fromfacility,
                in_userid, 'N', errno, out_errmsg);
        release_it(errmsg);
        return;
    end if;

-- Clone new order
    select max(shipid) +1
      into l_shipid
      from orderhdr
     where orderid = in_orderid;

    zcl.clone_orderhdr(in_orderid, in_shipid, ORD.orderid, l_shipid,
        null, in_userid, errmsg);

    UPDATE  orderhdr
       SET  loadno = null,
            stopno = null,
            shipno = null,
            qtyorder = 0,
            weightorder = 0,
            cubeorder = 0,
            amtorder = 0,
            qtycommit = null,
            weightcommit = null,
            cubecommit = null,
            amtcommit = null,
            qtyship = null,
            weightship = null,
            cubeship = null,
            amtship = null,
            qtytotcommit = null,
            weighttotcommit = null,
            cubetotcommit = null,
            amttotcommit = null,
            qtyrcvd = null,
            weightrcvd = null,
            cubercvd = null,
            amtrcvd = null,
            statusupdate = sysdate,
            lastupdate = sysdate,
            qtypick = null,
            weightpick = null,
            cubepick = null,
            amtpick = null,
            staffhrs = null,
            qty2sort = null,
            weight2sort = null,
            cube2sort = null,
            amt2sort = null,
            qty2pack = null,
            weight2pack = null,
            cube2pack = null,
            amt2pack = null,
            qty2check = null,
            weight2check = null,
            cube2check = null,
            amt2check = null,
            confirmed = null,
            rejectcode = null,
            rejecttext = null,
            dateshipped = null,
            origorderid = null,
            origshipid = null,
            bulkretorderid = null,
            bulkretshipid = null,
            returntrackingno = null,
            packlistshipdate = null,
            edicancelpending = null,
            tms_status = decode(nvl(ORD.tms_status,'X'),'X','X','1'),
            tms_status_update = sysdate,
            tms_shipment_id = null,
            tms_release_id = null
      WHERE orderid = ORD.orderid
        AND shipid = l_shipid;

    NORD := null;
    OPEN C_ORD(ORD.orderid, l_shipid);
    FETCH C_ORD into NORD;
    CLOSE C_ORD;

-- Go thru the orderdtl and split off
    tot_qty := 0;
    tot_wt := 0;
    tot_cube := 0;
    tot_amt := 0;

    for cod in (select * from orderdtl
                 where orderid = in_orderid
                   and shipid = in_shipid
                   and linestatus != 'X'
                   and nvl(qtyorder,0) > nvl(qtyship,0))
    loop

        COD.qtyship := nvl(COD.qtyship, 0);
        COD.weightship := nvl(COD.weightship, 0);
        COD.cubeship := nvl(COD.cubeship, 0);
        COD.amtship := nvl(COD.amtship, 0);


        l_qty := nvl(COD.qtyorder,0) - nvl(COD.qtyship,0);
        if nvl(l_qty,0) <= 0 then
            goto CONTINUE;
        end if;
        l_wt := l_qty * zci.item_weight(cod.custid, cod.item, cod.uom);
        l_cube := l_qty * zci.item_cube(cod.custid, cod.item, cod.uom);
        l_amt := l_qty * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);

        zcl.clone_orderdtl(COD.orderid, COD.shipid,
                    COD.item, COD.lotnumber,
                    NORD.orderid, NORD.shipid,
                    COD.item, COD.lotnumber,
                    null,
                    in_userid,
                    errmsg);

    -- Remove stuff from old order detail
        UPDATE  orderdtl
           SET  qtyorder = COD.qtyship,
                weightorder = COD.weightship,
                cubeorder = COD.cubeship,
                amtorder = COD.amtship,
                qtytotcommit = COD.qtyship,
                weighttotcommit = COD.weightship,
                cubetotcommit = COD.cubeship,
                amttotcommit = COD.amtship,
                qtypick = COD.qtyship,
                weightpick = COD.weightship,
                cubepick = COD.cubeship,
                amtpick = COD.amtship,
                qty2sort = 0,
                weight2sort = 0,
                cube2sort = 0,
                amt2sort = 0,
                qty2pack = 0,
                weight2pack = 0,
                cube2pack = 0,
                amt2pack = 0,
                qty2check = 0,
                weight2check = 0,
                cube2check = 0,
                amt2check = 0
          WHERE orderid = COD.orderid
            AND shipid = COD.shipid
            AND item = COD.item
            AND nvl(lotnumber,'(none)') = nvl(COD.lotnumber,'(none)');

    -- Add to new order
        UPDATE  orderdtl
           SET  qtyorder = l_qty,
                weightorder = l_wt,
                cubeorder = l_cube,
                amtorder = l_amt,
                qtycommit = 0,
                weightcommit = 0,
                cubecommit = 0,
                amtcommit = 0,
                qtyship = 0,
                weightship = 0,
                cubeship = 0,
                amtship = 0,
                qtytotcommit = COD.qtytotcommit - COD.qtyship,
                weighttotcommit = COD.weighttotcommit - COD.weightship,
                cubetotcommit = COD.cubetotcommit - COD.cubeship,
                amttotcommit = COD.amttotcommit - COD.amtship,
                qtypick = COD.qtypick - COD.qtyship,
                weightpick = COD.weightpick - COD.weightship,
                cubepick = COD.cubepick - COD.cubeship,
                amtpick = COD.amtpick - COD.amtship,
                -- childorderid = null,
                -- childshipid = null,
                staffhrs = COD.staffhrs * (l_qty/COD.qtyorder),
                qty2sort = COD.qty2sort,
                weight2sort = COD.weight2sort,
                cube2sort = COD.cube2sort,
                amt2sort = COD.amt2sort,
                qty2pack = COD.qty2pack,
                weight2pack = COD.weight2pack,
                cube2pack = COD.cube2pack,
                amt2pack = COD.amt2pack,
                qty2check = COD.qty2check,
                weight2check = COD.weight2check,
                cube2check = COD.cube2check,
                amt2check = COD.amt2check,
                asnvariance = null
          WHERE orderid = NORD.orderid
            AND shipid = NORD.shipid
            AND item = COD.item
            AND nvl(lotnumber,'(none)') = nvl(COD.lotnumber,'(none)');




        CUS := null;
        OPEN C_CUSTOMER(ORD.custid);
        FETCH C_CUSTOMER into CUS;
        CLOSE C_CUSTOMER;

        if CUS.linenumbersyn = 'Y' then
          qtyShip := nvl(cod.qtyship,0);

          for ol in C_ODL(cod.orderid,cod.shipid,
                cod.item,cod.lotnumber)
          loop
            if qtyShip > ol.qty then
              qtyLine := 0;
              qtyShip := qtyShip - ol.qty;
            else
              update orderdtlline
                 set qty = qtyShip
               where orderid = cod.orderid
                 and shipid = cod.shipid
                 and item = cod.item
                 and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
                 and linenumber = ol.linenumber;
              qtyLine := ol.qty - qtyShip;
              qtyShip := 0;
            end if;

            if qtyLine = 0 then
              goto continue_line_loop;
            end if;

            zcl.clone_table_row('ORDERDTLLINE',
                'ORDERID = '|| cod.orderid ||' and SHIPID = '||cod.shipid
                    ||' and ITEM = '''||cod.item||''''
                    ||' and nvl(LOTNUMBER,''(none)'') = '''
                        ||nvl(cod.lotnumber,'(none)')||''''
                    ||' and LINENUMBER = '|| ol.linenumber,
                NORD.orderid||','||NORD.shipid||','''||ol.item
                    ||''','''||ol.lotnumber||''','||ol.linenumber||','||qtyLine,
                'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER,QTY',
                null, in_userid, errmsg);

            if errmsg != 'OKAY' then
                zut.prt('ODL failed :'||errmsg);

            end if;

          << continue_line_loop >>
            null;
          end loop;

          delete orderdtlline
           where orderid = cod.orderid
             and shipid = cod.shipid
             and item = cod.item
             and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
             and qty = 0;

        end if;



        tot_qty := tot_qty + l_qty;
        tot_wt := tot_wt + l_wt;
        tot_cube := tot_cube + l_cube;
        tot_amt := tot_amt + l_amt;





<<CONTINUE>>
        null;

    end loop;

-- Update Old Order Status
    UPDATE orderhdr
       SET orderstatus = '8',
           statusupdate = sysdate
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid;

-- Update New Order Status
    NORD := null;
    OPEN C_ORD(ORD.orderid, l_shipid);
    FETCH C_ORD into NORD;
    CLOSE C_ORD;

    NORD.orderstatus := '4';    -- At least released

    if NORD.qtypick > 0 then
        NORD.orderstatus := '5'; -- Picking in Progress
        if NORD.qtypick >= NORD.qtyorder then
            NORD.orderstatus := '6'; -- Picking Complete
        end if;
    end if;

    UPDATE orderhdr
       SET orderstatus = NORD.orderstatus,
           statusupdate = sysdate
     WHERE orderid = NORD.orderid
       AND shipid = NORD.shipid;

-- Change Commitments
    UPDATE commitments
       SET orderid = NORD.orderid,
           shipid = NORD.shipid
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid;

-- Change tasks, subtasks and batchtasks
    UPDATE batchtasks
       SET orderid = NORD.orderid,
           shipid = NORD.shipid,
           loadno = null,
           stopno = null,
           shipno = null
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid;

    UPDATE subtasks
       SET orderid = NORD.orderid,
           shipid = NORD.shipid,
           loadno = null,
           stopno = null,
           shipno = null
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid;

    UPDATE tasks
       SET orderid = NORD.orderid,
           shipid = NORD.shipid,
           loadno = null,
           stopno = null,
           shipno = null
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid;

-- Change Master Shipping Plates clear loads if mixed
    UPDATE shippingplate
       SET loadno = null,
           stopno = null,
           shipno = null
     WHERE lpid in
    (SELECT parentlpid
       FROM shippingplate
      WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid
       AND status not in ('L','SH')
       AND type = 'M');

-- Change shippingplates
    UPDATE shippingplate
       SET orderid = NORD.orderid,
           shipid = NORD.shipid,
           loadno = null,
           stopno = null,
           shipno = null
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid
       AND status not in ('L','SH');

-- Change Totes
    UPDATE plate
       SET orderid = NORD.orderid,
           shipid = NORD.shipid,
           loadno = null,
           stopno = null,
           shipno = null
     WHERE orderid = ORD.orderid
       AND shipid = ORD.shipid
       AND type = 'TO';

-- Trigger custom code for split orders
    c_dat := zcus.init_cdata;

    c_dat.orderid := ORD.orderid;
    c_dat.shipid := ORD.shipid;
    c_dat.num01 := NORD.orderid;
    c_dat.num02 := NORD.shipid;

    zcus.execute('SPLO', c_dat);

-- Adjust old load totals and statuses
    UPDATE loadstopship
       SET qtyorder = nvl(qtyorder,0) - NORD.qtyorder,
           weightorder = nvl(weightorder,0) - NORD.weightorder,
           weight_entered_lbs = nvl(weight_entered_lbs,0) - nvl(NORD.weight_entered_lbs,0),
           weight_entered_kgs = nvl(weight_entered_kgs,0) - nvl(NORD.weight_entered_kgs,0),
           cubeorder = nvl(cubeorder,0) - NORD.cubeorder,
           amtorder = nvl(amtorder,0) - NORD.amtorder,
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE loadno = ORD.loadno
       AND stopno = ORD.stopno
       AND shipno = ORD.shipno;

    SELECT min(orderstatus), max(orderstatus) into minlss, maxlss
      FROM orderhdr
     WHERE loadno = ORD.loadno
       AND stopno = ORD.stopno;

    newloadstopstatus := '4'; -- Released
    if minlss = maxlss then
        newloadstopstatus := minlss;
    else
        if maxlss = '8' then
            newloadstopstatus := '7';
        elsif maxlss = '6' then
            newloadstopstatus := '6';
        else
            newloadstopstatus := maxlss;
        end if;
    end if;


    UPDATE loadstop
       SET loadstopstatus = newloadstopstatus,
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE loadno = ORD.loadno
       AND stopno = ORD.stopno
       AND loadstopstatus != newloadstopstatus;

    SELECT min(loadstopstatus) into newloadstatus
      FROM loadstop
     WHERE loadno = ORD.loadno;

    UPDATE loads
       SET loadstatus = newloadstatus,
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE loadno = ORD.loadno
       AND loadstatus != newloadstatus;


-- Add Order History to both orders
    INSERT INTO orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    VALUES
      (sysdate, ORD.orderid, ORD.shipid, in_userid,
           'Split Order', 'Order Split to '||NORD.orderid||'/'||NORD.shipid);
    INSERT INTO orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    VALUES
      (sysdate, NORD.orderid, NORD.shipid, in_userid,
           'Split Order', 'Order Split from '||ORD.orderid||'/'||ORD.shipid);

    release_it(errmsg);


EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'split_order:'||sqlerrm;
    rollback to retry_order;

END split_order;


----------------------------------------------------------------------
--
-- split_load
--
----------------------------------------------------------------------
PROCEDURE split_load
(
    in_loadno   number,
    in_userid   varchar2,
    out_errmsg  OUT varchar2
)
IS
  errmsg varchar2(255);

BEGIN
  out_errmsg := 'OKAY';
  for cod in (select distinct H.orderid, H.shipid, H.orderstatus,
                        H.qtyship, H.qtyorder, H.qtypick
                from orderdtl D, orderhdr H
               where H.loadno = in_loadno
                 and D.orderid = H.orderid
                 and D.shipid = H.shipid
                 and nvl(D.qtyorder,0) > nvl(D.qtyship,0)
                 and D.linestatus != 'X')
  loop
    split_order(cod.orderid, cod.shipid, in_userid, errmsg);
    if errmsg != 'OKAY' then
       out_errmsg := to_char(cod.orderid)||'/'||to_char(cod.shipid)
            ||': '||errmsg;
       return;
    end if;

  end loop;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'split_load:'||sqlerrm;
END split_load;


----------------------------------------------------------------------
--
-- load_not_loaded - Return number of active order lines not fully loaded
--
----------------------------------------------------------------------
FUNCTION load_not_loaded
(
    in_loadno   number
)
RETURN number
IS
cnt integer;

BEGIN
    cnt := 0;

    select count(1)
      into cnt
     from orderdtl D, orderhdr H
     where H.loadno = in_loadno
       and D.orderid = H.orderid
       and D.shipid = H.shipid
       and nvl(D.qtyorder,0) > nvl(D.qtyship,0)
       and D.linestatus != 'X';

    return nvl(cnt,0);


END load_not_loaded;


----------------------------------------------------------------------
--
-- split_shipment_begin
--
----------------------------------------------------------------------
PROCEDURE split_shipment_begin
(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  OUT varchar2
)
IS
BEGIN

    out_errmsg := 'OKAY';

    delete from splitshipmentdtl
     where orderid = in_orderid
       and shipid = in_shipid;

    insert into splitshipmentdtl
    select orderid, shipid, item, nvl(lotnumber,'(none)'), uom, qtyorder, 0
      from orderdtl
     where orderid = in_orderid
       and shipid = in_shipid;



EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'split_shipment_begin:'||sqlerrm;
END split_shipment_begin;


----------------------------------------------------------------------
--
-- split_shipment_end
--
----------------------------------------------------------------------
PROCEDURE split_shipment_end
(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  OUT varchar2
)
IS
BEGIN
    out_errmsg := 'OKAY';

    delete from splitshipmentdtl
     where orderid = in_orderid
       and shipid = in_shipid;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'split_shipment_end:'||sqlerrm;
END split_shipment_end;



------------------------------------------------------------------------
--
-- split_shipment
--
------------------------------------------------------------------------
PROCEDURE split_shipment
(
    in_orderid      IN number,
    in_shipid       IN number,
    in_userid       IN varchar2,
    in_new_orderid  IN OUT number,
    in_new_shipid   IN OUT number,
    out_errmsg      OUT varchar2
)
IS


CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid
FOR UPDATE;

ORD orderhdr%rowtype;
NORD orderhdr%rowtype;





CURSOR C_ODL(in_orderid number,in_shipid number,
 in_orderitem varchar2, in_orderlot varchar2) is
  select *
    from orderdtlline
   where orderid = in_orderid
     and shipid = in_shipid
     and item = in_orderitem
     and nvl(lotnumber,'(none)') = nvl(in_orderlot,'(none)')
     and nvl(xdock,'N') = 'N'
   order by linenumber;


CURSOR C_CUSTOMER(in_custid varchar2) is
  select linenumbersyn
    from customer
   where custid = in_custid;
CUS C_CUSTOMER%ROWTYPE;

l_qtyToSplit integer;
qtyLine integer;

cordid waves.wave%type;
l_shipid orderhdr.shipid%type;

errno number;
errmsg varchar2(255);

l_qty orderdtl.qtyorder%type;
l_wt orderdtl.weightorder%type;
l_cube orderdtl.cubeorder%type;
l_amt orderdtl.amtorder%type;


tot_qty orderhdr.qtyorder%type;
tot_wt orderhdr.weightorder%type;
tot_cube orderhdr.cubeorder%type;
tot_amt orderhdr.amtorder%type;

minlss loadstop.loadstopstatus%type;
maxlss loadstop.loadstopstatus%type;
newloadstopstatus loadstop.loadstopstatus%type;
newloadstatus loads.loadstatus%type;

c_dat cdata;

cnt integer;

OD orderdtl%rowtype;
NOD orderdtl%rowtype;

l_qty_commit orderdtl.qtycommit%type;

qty_uom number;

BEGIN
    out_errmsg := 'OKAY';


SAVEPOINT retry_order;

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;


    if ORD.orderid is null then
        out_errmsg := 'Invalid orderid:'||in_orderid||'/'||in_shipid;
        return;
    end if;

    if ORD.ordertype != 'O' then
        rollback to retry_order;
        out_errmsg := 'Not a customer outbound order (shipment).';
        return;
    end if;

    if ORD.orderstatus > '2' then
        rollback to retry_order;
        out_errmsg := 'Order status can not be past committed.';
        return;
    end if;

    if nvl(ORD.loadno,0) > 0 then
        rollback to retry_order;
        out_errmsg := 'Order can not be part of a load.';
        return;
    end if;


-- set count of order details created to 0
    cnt := 0;


-- Do not allow consolidated orders to be split
    cordid := zcord.cons_orderid(in_orderid, in_shipid);

    if nvl(cordid,0) > 0 then
        rollback to retry_order;
        out_errmsg := 'Cannot split a consolidated order.';
        return;
    end if;



-- Clone new order
    select max(shipid) +1
      into l_shipid
      from orderhdr
     where orderid = in_orderid;

    zcl.clone_table_row('ORDERHDR',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        ORD.orderid||','||l_shipid||',null',
        'ORDERID,SHIPID,WAVE',
        null,
        in_userid,
        out_errmsg);


    -- zut.prt('Order shipid:'||ORD.orderid||'/'||l_shipid);


    UPDATE  orderhdr
       SET  loadno = null,
            stopno = null,
            shipno = null,
            qtyorder = 0,
            weightorder = 0,
            cubeorder = 0,
            amtorder = 0,
            qtycommit = null,
            weightcommit = null,
            cubecommit = null,
            amtcommit = null,
            qtyship = null,
            weightship = null,
            cubeship = null,
            amtship = null,
            qtytotcommit = null,
            weighttotcommit = null,
            cubetotcommit = null,
            amttotcommit = null,
            qtyrcvd = null,
            weightrcvd = null,
            cubercvd = null,
            amtrcvd = null,
            statusupdate = sysdate,
            lastupdate = sysdate,
            qtypick = null,
            weightpick = null,
            cubepick = null,
            amtpick = null,
            staffhrs = null,
            qty2sort = null,
            weight2sort = null,
            cube2sort = null,
            amt2sort = null,
            qty2pack = null,
            weight2pack = null,
            cube2pack = null,
            amt2pack = null,
            qty2check = null,
            weight2check = null,
            cube2check = null,
            amt2check = null,
            confirmed = null,
            rejectcode = null,
            rejecttext = null,
            dateshipped = null,
            origorderid = null,
            origshipid = null,
            bulkretorderid = null,
            bulkretshipid = null,
            returntrackingno = null,
            packlistshipdate = null,
            edicancelpending = null,
            tms_status = decode(nvl(ORD.tms_status,'X'),'X','X','1'),
            tms_status_update = sysdate,
            tms_shipment_id = null,
            tms_release_id = null,
            wave = null
      WHERE orderid = ORD.orderid
        AND shipid = l_shipid;




    NORD := null;
    OPEN C_ORD(ORD.orderid, l_shipid);
    FETCH C_ORD into NORD;
    CLOSE C_ORD;



    zcl.clone_table_row('ORDERHDRBOLCOMMENTS',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        NORD.orderid||','||NORD.shipid,
        'ORDERID,SHIPID',
        null,
        in_userid,
        out_errmsg);

    if out_errmsg != 'OKAY' then
        rollback to retry_order;
        return;
    end if;


-- Go thru the orderdtl and split off
    tot_qty := 0;
    tot_wt := 0;
    tot_cube := 0;
    tot_amt := 0;

    for cod in (select OD.*, nvl(S.qtytosplit,0) qtytosplit
                  from orderdtl OD, splitshipmentdtl S
                 where OD.orderid = in_orderid
                   and OD.shipid = in_shipid
                   and S.orderid = OD.orderid
                   and S.shipid = OD.shipid
                   and S.item = OD.item
                   and nvl(S.lotnumber,'(none)')
                            = nvl(OD.lotnumber,'(none)')
                   and linestatus != 'X'
                   and nvl(S.qtytosplit,0) > 0)

    loop

    --    zut.prt('Qty to split:' || cod.qtytosplit);

    -- Check if can convert by base UOM
        qty_uom := zcu.equiv_uom_qty(ORD.custid,COD.item,COD.uom,
                COD.qtytosplit, COD.uomentered);

        if qty_uom != trunc(qty_uom) then
            rollback to retry_order;
            out_errmsg := 'Cannot split because UOM conversion failed.';
            return;
        end if;

        COD.qtyship := nvl(COD.qtyship, 0);
        COD.weightship := nvl(COD.weightship, 0);
        COD.cubeship := nvl(COD.cubeship, 0);
        COD.amtship := nvl(COD.amtship, 0);


        l_qty := nvl(COD.qtyorder,0) - nvl(COD.qtytosplit,0);

        if nvl(l_qty,0) < 0 then
            goto CONTINUE;
        end if;
        l_wt := l_qty * zci.item_weight(cod.custid, cod.item, cod.uom);
        l_cube := l_qty * zci.item_cube(cod.custid, cod.item, cod.uom);
        l_amt := l_qty * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);

        cnt := cnt + 1;

        zcl.clone_orderdtl(COD.orderid, COD.shipid,
                    COD.item, COD.lotnumber,
                    NORD.orderid, NORD.shipid,
                    COD.item, COD.lotnumber,
                    null,
                    in_userid,
                    errmsg);

-- determine order commitments
        OD := null;
        NOD := null;

        l_qty_commit := 0;
        if COD.qtycommit > 0 then
            OD.qtycommit := least(l_qty, COD.qtycommit);
            l_qty_commit := greatest(COD.qtycommit - l_qty,0);

            OD.weightcommit := OD.qtycommit
                            * zci.item_weight(cod.custid, cod.item, cod.uom);
            OD.cubecommit := OD.qtycommit
                            * zci.item_cube(cod.custid, cod.item, cod.uom);
            OD.amtcommit := OD.qtycommit
                            * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);

            NOD.qtycommit := COD.qtycommit - OD.qtycommit;
            NOD.weightcommit := NOD.qtycommit
                            * zci.item_weight(cod.custid, cod.item, cod.uom);
            NOD.cubecommit := NOD.qtycommit
                            * zci.item_cube(cod.custid, cod.item, cod.uom);
            NOD.amtcommit := NOD.qtycommit
                            * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);

        end if;
        if COD.qtytotcommit > 0 then
            OD.qtytotcommit := least(l_qty, COD.qtytotcommit);
            OD.weighttotcommit := OD.qtytotcommit
                            * zci.item_weight(cod.custid, cod.item, cod.uom);
            OD.cubetotcommit := OD.qtytotcommit
                            * zci.item_cube(cod.custid, cod.item, cod.uom);
            OD.amttotcommit := OD.qtytotcommit
                            * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);

            NOD.qtytotcommit := COD.qtytotcommit - OD.qtytotcommit;
            NOD.weighttotcommit := NOD.qtytotcommit
                            * zci.item_weight(cod.custid, cod.item, cod.uom);
            NOD.cubetotcommit := NOD.qtytotcommit
                            * zci.item_cube(cod.custid, cod.item, cod.uom);
            NOD.amttotcommit := NOD.qtytotcommit
                            * zci.item_amt(cod.custid, cod.orderid, cod.shipid, cod.item, cod.lotnumber);


        end if;



    -- Remove stuff from old order detail
        UPDATE  orderdtl
           SET  qtyorder = l_qty,
                weightorder = l_wt,
                cubeorder = l_cube,
                amtorder = l_amt,
                qtytotcommit = OD.qtytotcommit,
                weighttotcommit = OD.weighttotcommit,
                cubetotcommit = OD.cubetotcommit,
                amttotcommit = OD.amttotcommit,
                qtyentered = qtyentered - qty_uom
          WHERE orderid = COD.orderid
            AND shipid = COD.shipid
            AND item = COD.item
            AND nvl(lotnumber,'(none)') = nvl(COD.lotnumber,'(none)');

    -- Add to new order
        UPDATE  orderdtl
           SET  qtyorder = nvl(qtyorder,0) - l_qty,
                weightorder = nvl(weightorder,0) - l_wt,
                cubeorder = nvl(cubeorder,0) - l_cube,
                amtorder = nvl(amtorder,0) - l_amt,
                staffhrs = COD.staffhrs * (l_qty/COD.qtyorder),
                qtyentered = nvl(qtyorder,0) - l_qty,
                itementered = cod.item,
                uomentered = cod.uom,
                qtytotcommit = null,
                weighttotcommit = null,
                cubetotcommit = null,
                amttotcommit = null,
                qtycommit = null,
                weightcommit = null,
                cubecommit = null,
                amtcommit = null
          WHERE orderid = NORD.orderid
            AND shipid = NORD.shipid
            AND item = COD.item
            AND nvl(lotnumber,'(none)') = nvl(COD.lotnumber,'(none)');


        zcl.clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid
                ||' and ITEM = '''||cod.item||''''
                ||' and nvl(LOTNUMBER,''(none)'') = '''
                    ||nvl(cod.lotnumber,'(none)')||'''',
            NORD.orderid||','||NORD.shipid||','''||cod.item
                ||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
            null,
            in_userid,
            out_errmsg);



        L_qtytosplit := nvl(OD.qtycommit,0);

--        zut.prt('Commitments to leave:'||l_qtytosplit);

        for ccm in (select rowid, commitments.*
                      from commitments
                     where orderid = in_orderid
                       and shipid = in_shipid
                       and orderitem = COD.item
                       and nvl(orderlot,'(none)') = nvl(COD.lotnumber,'(none)'))
        loop
            if l_qtytosplit >= ccm.qty then
--                zut.prt('Leaving :'||ccm.qty);
                l_qtytosplit := l_qtytosplit - ccm.qty;
            elsif l_qtytosplit = 0 then
               delete commitments
                where rowid = ccm.rowid;
--                zut.prt('Removing :'||ccm.qty);
            else
                update commitments
                   set qty = l_qtytosplit
                 where rowid = ccm.rowid;
--                zut.prt('Update :'||ccm.qty||' to '||l_qtytosplit);
                l_qtytosplit := 0;
            end if;
        end loop;


        CUS := null;
        OPEN C_CUSTOMER(ORD.custid);
        FETCH C_CUSTOMER into CUS;
        CLOSE C_CUSTOMER;

        if CUS.linenumbersyn = 'Y' then
          -- l_qtytoSplit := nvl(cod.qtytosplit,0);
    -- Really qty to leave behind

          l_qtytosplit := nvl(COD.qtyorder,0) - nvl(COD.qtytosplit,0);

          for ol in C_ODL(cod.orderid,cod.shipid,
                cod.item,cod.lotnumber)
          loop
            if l_qtytosplit > ol.qty then
              qtyLine := 0;
              l_qtytosplit := l_qtytosplit - ol.qty;
            else
--              zut.prt('Update old line by:'||ol.linenumber||' = '||l_qtytosplit);
--              zut.prt('... UOMs :'||COD.uom||'/'||ol.uomentered
--                  ||' QTY_E:'||zcu.equiv_uom_qty(ORD.custid,COD.item,
--                                    COD.uom,l_qtytosplit, ol.uomentered));

              update orderdtlline
                 set qty = l_qtytosplit,
                     qtyentered = zcu.equiv_uom_qty(ORD.custid,COD.item,
                                    COD.uom,l_qtytosplit, ol.uomentered)
                where orderid = cod.orderid
                 and shipid = cod.shipid
                 and item = cod.item
                 and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
                 and linenumber = ol.linenumber;
              qtyLine := ol.qty - l_qtytosplit;
              l_qtytosplit := 0;
            end if;

            if qtyLine = 0 then
              goto continue_line_loop;
            end if;

            zcl.clone_table_row('ORDERDTLLINE',
                'ORDERID = '|| cod.orderid ||' and SHIPID = '||cod.shipid
                    ||' and ITEM = '''||cod.item||''''
                    ||' and nvl(LOTNUMBER,''(none)'') = '''
                        ||nvl(cod.lotnumber,'(none)')||''''
                    ||' and LINENUMBER = '|| ol.linenumber,
                NORD.orderid||','||NORD.shipid||','''||ol.item
                    ||''','''||ol.lotnumber||''','||ol.linenumber||','||qtyLine
                    ||','|| qtyLine
                    ||','''||COD.uom||'''',
                'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER,QTY,QTYENTERED,UOMENTERED',
                null, in_userid, errmsg);

            --zut.prt('Clone new line by:'||ol.linenumber||' = '||qtyLine);

            if errmsg != 'OKAY' then
                zut.prt('ODL failed :'||errmsg);

            end if;

          << continue_line_loop >>
            null;
          end loop;

          delete orderdtlline
           where orderid = cod.orderid
             and shipid = cod.shipid
             and item = cod.item
             and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
             and qty = 0;

        end if;



        tot_qty := tot_qty + l_qty;
        tot_wt := tot_wt + l_wt;
        tot_cube := tot_cube + l_cube;
        tot_amt := tot_amt + l_amt;

<<CONTINUE>>
        null;

    end loop;

--     zut.prt('Count = '||cnt);

    if cnt = 0 then
        rollback to retry_order;
        out_errmsg := 'Nothing was split.';
        return;
    end if;


-- Update New Order Status
    NORD := null;
    OPEN C_ORD(ORD.orderid, l_shipid);
    FETCH C_ORD into NORD;
    CLOSE C_ORD;

    UPDATE orderhdr
       SET orderstatus = '0',
	       commitstatus = '0',
           statusupdate = sysdate
     WHERE orderid = NORD.orderid
       AND shipid = NORD.shipid;

-- Add Order History to both orders
    INSERT INTO orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    VALUES
      (sysdate, ORD.orderid, ORD.shipid, in_userid,
           'Split Shipment', 'Order Split to '||NORD.orderid||'/'||NORD.shipid);
    INSERT INTO orderhistory
      (chgdate, orderid, shipid, userid, action, msg)
    VALUES
      (sysdate, NORD.orderid, NORD.shipid, in_userid,
           'Split Shipment', 'Order Split from '||ORD.orderid||'/'||ORD.shipid);
    delete from splitshipmentdtl
     where orderid = in_orderid
       and shipid = in_shipid;


    in_new_orderid := NORD.orderid;
    in_new_shipid := NORD.shipid;


EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'split_shipment:'||sqlerrm;
    rollback to retry_order;

END split_shipment;

procedure get_rf_lock
(in_loadno  IN number
,in_orderid IN number
,in_shipid  IN number     
,in_userid  IN varchar2
,out_msg    OUT varchar2
)

is 

l_errno       number;
l_lock_number number;
l_elapsed_begin date;
l_elapsed_end date;
begin
l_elapsed_begin := sysdate;
out_msg := 'OKAY';
if nvl(in_loadno,0) != 0 then
  l_lock_number := in_loadno;
elsif nvl(in_orderid,0) != 0 then
  l_lock_number := to_number(in_orderid || in_shipid);
else
  return;
end if;
zms.rf_debug_msg('RFDEBUG', null, null,
                'begin ZSO.GET_RF_LOCK - lock number: ' || l_lock_number,
                'T', in_userid);
l_errno := dbms_lock.request(l_lock_number,
                             dbms_lock.x_mode,
                             dbms_lock.maxwait,
                             TRUE);
if l_errno not in (0, 4) then
  out_msg := 'Rf lock not obtained. Lock = ' || l_lock_number ||
             ' Result = '|| l_errno;
end if;
l_elapsed_end := sysdate;
zms.rf_debug_msg('RFDEBUG', null, null,
                'end ZSO.GET_RF_LOCK - lock number: ' || l_lock_number ||
                ' out_msg: ' || out_msg ||
                ' (Elapsed: ' ||
                rtrim(substr(zlb.formatted_staffhrs((l_elapsed_end - l_elapsed_begin)*24),1,12)) ||
                ')',
                'T', in_userid);
exception when others then
  out_msg := 'Rf lock exception. SqlCode = ' || sqlcode;
end get_rf_lock;
------------------------------------------------------------------------
--
-- PACKAGE INITIALIZATION CODE
--
------------------------------------------------------------------------



-- None

END zsplitorder;
/

show error package body zsplitorder;
exit;
