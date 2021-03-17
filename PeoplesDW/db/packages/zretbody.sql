create or replace package body alps.zreturns as
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
-- add_return
--
----------------------------------------------------------------------
PROCEDURE add_return
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
    in_qty       IN      number,
    in_uom       IN      varchar2,
    in_lpid      IN      varchar2,
    in_mlpid     IN      varchar2,
    in_reason    IN      varchar2,
    in_invstatus IN      varchar2,
    in_invclass  IN      varchar2,
    in_facility  IN      varchar2,
    in_location  IN      varchar2,
    in_user      IN      varchar2,
    in_weight    IN      number,
    in_expdate   IN      date,
    out_errmsg   OUT     varchar2
)
IS

ITEM    custitemview%rowtype;
MPLATE  plate%rowtype;
DTL     orderdtl%rowtype;
LOC     location%rowtype;

mlpid   plate.lpid%type;
qty     number;
qtydm   number := 0;
qtygood number := 0;
wtdm   number := 0;
wtgood number := 0;
errmsg  varchar2(200);
mark    varchar2(20);
v_orderstatus orderhdr.orderstatus%type;

   lptype plate.type%type;
   xrefid plate.lpid%type;
   xreftype plate.type%type;
   parentid plate.lpid%type;
   parenttype plate.type%type;
   topid plate.lpid%type;
   toptype plate.type%type;
   msg varchar(80);

	l_weight plate.weight%type;
BEGIN

   out_errmsg := 'OKAY';

   begin
      select orderstatus into v_orderstatus
      from orderhdr
      where orderid = in_orderid and shipid = in_shipid;
      
      if (v_orderstatus not in ('0','1','A')) then
        out_errmsg := 'Invalid order status.';
        return;
      end if;
   exception
      when others then
        out_errmsg := 'Invalid order.';
        return;
   end;

-- Get cust item information
   ITEM := null;
   OPEN C_CUSTITEMV(in_custid, in_item);
   FETCH C_CUSTITEMV into ITEM;
   CLOSE C_CUSTITEMV;

   if ITEM.custid is null then
      out_errmsg := 'Invalid item.';
      return;
   end if;

   ITEM.cube := zci.item_cube(in_custid, in_item, in_uom);

-- Convert quantity to base uom
   zbut.translate_uom(in_custid, in_item, in_qty,
           in_uom, ITEM.baseuom, qty, errmsg);
   if substr(errmsg,1,4) != 'OKAY' then
      out_errmsg := errmsg;
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

-- Validate LPs
   if (not zlp.is_lpid(in_lpid)) then
      out_errmsg := 'Invalid LPID';
      return;
   end if;
   if in_mlpid is not null then
     if (not zlp.is_lpid(in_mlpid)) then
        out_errmsg := 'Invalid Master LPID';
        return;
     end if;
   end if;

   zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);

  if lptype != '?' then
        out_errmsg := 'LPID already exists';
        return;
  end if;

   zrf.identify_lp(in_mlpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);

  if lptype not in ( '?','MP') then
        out_errmsg := 'Master LPID not a master';
        return;
  end if;

  l_weight := in_weight;
  if nvl(ITEM.use_catch_weights,'N') = 'Y' then
	 zcwt.set_item_catch_weight(in_custid, in_item, in_orderid, in_shipid,
        in_qty, in_uom, l_weight, in_user, msg);
    if msg != 'OKAY' then
      out_errmsg := 'Error setting catch weight: ' || msg;
      return;
    end if;
    zcwt.add_item_lot_catch_weight(in_facility, in_custid, in_item, in_lot,
	     l_weight, msg);
    if msg != 'OKAY' then
   	out_errmsg := 'Error adding catch weight: ' || msg;
      return;
    end if;
  end if;

-- add plate
   mark := 'Plate';
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
      lastuser,
      lastupdate,
      parentfacility,
      parentitem,
      expirationdate
   )
   VALUES
   (
      in_lpid,
      in_item,
      in_custid,
      in_facility,
      in_location,
      'A',-- status,
      ITEM.baseuom,
      qty,
      'PA',
      in_serial,
      in_lot,
      in_useritem1,
      in_useritem2,
      in_useritem3,
      sysdate,
      substr(in_reason,1,2),
      substr(in_invstatus,1,2),
      substr(in_invclass,1,2),
      in_orderid,
      in_shipid,
      in_loadno,
      in_stopno,
      in_shipno,
      in_qty,
      in_item,
      in_uom,
      in_mlpid,
      l_weight,
      in_user,
      sysdate,
      in_facility,
      in_item,
      in_expdate
   );

        zrf.tally_lp_receipt(in_lpid, in_user, errmsg);
   if errmsg is not null then
      out_errmsg := errmsg;
      return;
   end if;

-- update or add master plate
   mark := 'Parent';

   if in_mlpid is not null then
      MPLATE := null;
      OPEN C_PLATE(in_mlpid);
      FETCH C_PLATE into MPLATE;
      CLOSE C_PLATE;

      if MPLATE.lpid is null then
         mlpid := in_mlpid;
         zplp.build_empty_parent(
            mlpid,
            in_facility,
            in_location,
            'A', -- status
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
            substr(in_invstatus,1,2),
            substr(in_invclass,1,2),
            errmsg
         );
         if errmsg is not null then
            out_errmsg := errmsg;
            return;
         end if;
                elsif (MPLATE.item = zunk.UNK_RTRN_ITEM) then
         mlpid := in_mlpid;
                        zunk.empty_unknown_lp(mlpid, in_user, errmsg);
        if errmsg is not null then
                out_errmsg := errmsg;
                return;
        end if;

         zplp.build_empty_parent(
            mlpid,
            in_facility,
            in_location,
            'A', -- status
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
            substr(in_invstatus,1,2),
            substr(in_invclass,1,2),
            errmsg
         );
         if errmsg is not null then
            out_errmsg := errmsg;
            return;
         end if;
                elsif (MPLATE.type != 'MP') then
              out_errmsg := 'Not a Multi Plate';
           return;
      end if;
      zplp.attach_child_plate(
         in_mlpid,
         in_lpid,
         '',
         '',
         in_user,
         errmsg
      );
      if errmsg is not null then
         out_errmsg := errmsg;
         return;
      end if;
   end if;

-- update orderhdr
   UPDATE orderhdr
      SET orderstatus = 'A',
          lastuser = in_user,
          lastupdate = sysdate
    WHERE orderid = in_orderid
      AND shipid = in_shipid
      AND orderstatus != 'A';

-- update or add orderdtl
   mark := 'OrderDtl';

   if substr(in_invstatus,1,2) = 'DM' then
      qtydm := qty;
      wtdm := l_weight;
   else
      qtygood := qty;
      wtgood := l_weight;
   end if;

   DTL := null;
   OPEN C_ORDDTL(in_orderid, in_shipid,
        in_item, in_lot);
   FETCH C_ORDDTL into DTL;
   CLOSE C_ORDDTL;



   if DTL.orderid is null then
      INSERT INTO ORDERDTL(
         orderid,
         shipid,
         item,
         custid,
         lotnumber,
         fromfacility,
         uom,
         linestatus,
         itementered,
         uomentered,
         qtyrcvd,
         qtyrcvdgood,
         qtyrcvddmgd,
         statususer,
         statusupdate,
         lastuser,
         lastupdate,
         priority,
         weightrcvd,
         weightrcvdgood,
         weightrcvddmgd,
         cubercvd,
         cubercvdgood,
         cubercvddmgd,
         amtrcvd,
         amtrcvdgood,
         amtrcvddmgd
      )
      VALUES(
         in_orderid,
         in_shipid,
         in_item,
         in_custid,
         in_lot,
         in_facility,
         ITEM.baseuom,
         'A',
         in_item,
         in_uom,
         qty,
         qtygood,
         qtydm,
         in_user,
         sysdate,
         in_user,
         sysdate,
         'N',
         l_weight,
         wtgood,
         wtdm,
         ITEM.cube * qty,
         ITEM.cube * qtygood,
         ITEM.cube * qtydm,
         ITEM.useramt1 * qty,
         ITEM.useramt1 * qtygood,
         ITEM.useramt1 * qtydm
      );
   else
      UPDATE orderdtl
         SET
             qtyrcvd = nvl(qtyrcvd,0) + qty,
             qtyrcvdgood = nvl(qtyrcvdgood,0) + qtygood,
             qtyrcvddmgd = nvl(qtyrcvddmgd,0) + qtydm,
             weightrcvd = nvl(weightrcvd,0) + l_weight,
             weightrcvdgood = nvl(weightrcvdgood,0) + wtgood,
             weightrcvddmgd = nvl(weightrcvddmgd,0) + wtdm,
             cubercvd = nvl(cubercvd,0) + (qty * ITEM.cube),
             cubercvdgood = nvl(cubercvdgood,0) + (qtygood * ITEM.cube),
             cubercvddmgd = nvl(cubercvddmgd,0) + (qtydm * ITEM.cube),
             amtrcvd = nvl(amtrcvd,0) + (qty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             amtrcvdgood = nvl(amtrcvdgood,0) + (qtygood * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             amtrcvddmgd = nvl(amtrcvddmgd,0) + (qtydm * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
             lastuser = in_user,
             lastupdate = sysdate
       WHERE orderid = in_orderid
         AND shipid = in_shipid
         AND item = in_item
         AND nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');

   end if;

-- Update loadstopship
   mark := 'LoadStopShip';
   if in_loadno is not null then
      UPDATE loadstopship
         SET
             qtyrcvd = nvl(qtyrcvd,0) + qty,
             weightrcvd = nvl(weightrcvd,0) + l_weight,
             weightrcvd_kgs = nvl(weightrcvd_kgs,0)
                            + nvl(zwt.from_lbs_to_kgs(in_custid,l_weight),0),
             cubercvd = nvl(cubercvd,0) + (qty * ITEM.cube),
             amtrcvd = nvl(amtrcvd,0) + (qty * zci.item_amt(in_custid,in_orderid,in_shipid,in_item,in_lot)),
             lastuser = in_user,
             lastupdate = sysdate
       WHERE loadno = in_loadno
         AND stopno = in_stopno
         AND shipno = in_shipno;
   end if;

EXCEPTION when others then
  out_errmsg := sqlerrm;

END add_return;

----------------------------------------------------------------------
--
-- close_return
--
----------------------------------------------------------------------
PROCEDURE close_return
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_user      IN      varchar2,
    out_errmsg   OUT     varchar2
)
IS

  CURSOR C_PLATE(in_orderid number, in_shipid number) IS
    SELECT pl.facility,
    	     pl.custid,
    	     nvl(od.item, pl.item) item,
    	     pl.lotnumber,
    	     pl.unitofmeasure,
    	     pl.quantity,
    	     pl.weight,
    	     pl.inventoryclass,
    	     pl.invstatus,
    	     pl.lpid
    FROM PLATE pl, orderdtlrcpt od
     WHERE pl.status not in ('P','U', 'D')
       AND pl.TYPE = 'PA'
       AND pl.orderid = in_orderid
       AND pl.shipid = in_shipid
       AND pl.orderid = od.orderid (+)
       AND pl.shipid = od.shipid (+)
       AND pl.lpid = od.lpid (+);



  ORD   orderhdr%rowtype;
  LOAD  loads%rowtype;
  CUST  C_CUST%rowtype;
  errmsg varchar2(100);
  in_new_orderid integer;
  in_new_shipid  integer;
  out_logmsg varchar2(1000);

  rc integer;

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

   if ORD.ordertype != 'Q' then
      out_errmsg := 'Order not a return order type.';
      return;
   end if;

   CUST := null;
   OPEN C_CUST(ORD.custid);
   FETCH C_CUST into CUST;
   CLOSE C_CUST;

-- If there is a load get its information
   LOAD := null;
   if ORD.loadno is not null then
       OPEN C_LOADS(ORD.loadno);
       FETCH C_LOADS into LOAD;
       CLOSE C_LOADS;
   end if;

-- If no load do asof inventory as of today
   if LOAD.loadno is null then
      LOAD.rcvddate := trunc(sysdate);
   end if;

-- Receive the order
   UPDATE orderhdr
      SET orderstatus = 'R',
          statususer = in_user,
          statusupdate = sysdate,
          lastuser = in_user,
          lastupdate = sysdate
    WHERE orderid = in_orderid
      AND shipid = in_shipid;

-- Add the asof inventory for the returned items
   for crec in C_PLATE(in_orderid, in_shipid) loop
       zbill.add_asof_inventory(
           crec.facility,
           crec.custid,
           crec.item,
           crec.lotnumber,
           crec.unitofmeasure,
           trunc(LOAD.rcvddate),
           crec.quantity,
           crec.weight,
           'Returns',
           'RT',
           crec.inventoryclass,
           crec.invstatus,
           in_orderid,
           in_shipid,
           crec.lpid,
           in_user,
           out_errmsg
       );
	   if out_errmsg != 'OKAY' then
		  zms.log_msg('close-return', crec.facility, crec.custid, out_errmsg, 'E', in_user, out_logmsg);
		  return;
	   end if;
   end loop;


-- Do returns bill if necessary
   rc := zbr.calc_customer_return(null, in_orderid, in_shipid,
        ORD.custid, in_user, out_errmsg);

-- Carry over unreceived expected items. 
-- This creates a new return order for any expected item which was not received.
   if nvl(CUST.carryover_unrcvd_qty_return_yn, 'N') = 'Y' then
     in_new_orderid := null;
     in_new_shipid  := null;
     zret.return_carryover(in_orderid, in_shipid, in_new_orderid, in_new_shipid, in_user, out_errmsg);
   end if;
   if out_errmsg != 'OKAY' then
     return;
   end if;

EXCEPTION when others then
  out_errmsg := sqlerrm;

END close_return;

--------------------------------------------------------------------
--
-- close_multi_returns
--
----------------------------------------------------------------------
PROCEDURE close_multi_returns
(   
    in_included_rowids         IN      clob,
    in_facility                IN      varchar2,
    in_user                    IN      varchar2,
    out_errmsg                 OUT     varchar2,
    out_errorno                IN OUT  number,
    out_error_count            IN OUT  number,
    out_completed_count IN OUT  number
)
IS
  type cur_type is ref cursor;
  l_cur cur_type;
  
  l_orderid orderhdr.orderid%type;
  l_shipid orderhdr.shipid%type;
  l_custid customer.custid%type;
  
  l_sql varchar2(4000);
  i pls_integer;
  l_loop_count pls_integer;
  l_rowid_length pls_integer := 18;
  
  l_log_msg appmsgs.msgtext%type;

begin
  out_errmsg := 'OKAY';
  l_log_msg := 'START OF CLOSE_MULTI_RETURNS';
  zms.log_autonomous_msg('RETURNS', in_facility, null, l_log_msg, 'I', in_user, out_errmsg);
  
  out_errorno := 0;
  out_error_count := 0;
  out_completed_count := 0;
  
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
		
	  zret.close_return(
        l_orderid ,
        l_shipid,
        in_user ,
        out_errmsg );
	  
      if out_errmsg = 'OKAY' then
	    commit;
        out_completed_count := out_completed_count + 1;
	  else
        rollback;
        out_error_count := out_error_count + 1;
		l_log_msg := out_errmsg;
		zms.log_autonomous_msg('RETURNS', in_facility, l_custid, 
			'custid= '||l_custid||' orderid= '||l_orderid || ' shipid= '||l_shipid||' - '||
		    l_log_msg, 'E', in_user, out_errmsg);
	  end if;
    end loop;

    close l_cur;

  end loop;

  l_log_msg := 'END OF CLOSE_MULTI_RETURNS '|| '-' ||
               ' ERROR_COUNT = ' || out_error_count ||
               ' COMPLETE_RETURNS_COUNT = ' || out_completed_count;
  zms.log_autonomous_msg('RETURNS', in_facility, l_custid, l_log_msg, 'I', in_user, out_errmsg);
		
exception when others then
  out_errorno := sqlcode;
  out_errmsg := sqlerrm;

end close_multi_returns;

PROCEDURE return_carryover
(in_orderid IN number
,in_shipid IN number
,in_new_orderid IN OUT number
,in_new_shipid IN OUT number
,in_user IN varchar2
,out_errmsg OUT varchar2
)
IS
CURSOR C_ORDTL(in_orderid number, in_shipid number,
       in_item varchar2, in_lot varchar2)
IS
    SELECT qtyrcvd, weightrcvd, cubercvd,amtrcvd
      FROM orderdtl
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item
       AND nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');
cnt integer;
modeApprvd integer;
totEntered integer;
totRcvd integer;
totRoll integer;
currLineEntered integer;
currLineRcvd integer;
currLineRoll integer;
ORDHDR C_ORDHDR%rowtype;
ORDTL C_ORDTL%rowtype;
l_orderid number;
l_shipid number;

BEGIN
    out_errmsg := 'OKAY';
    
-- Verify return order is correct
    ORDHDR := null;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORDHDR;
    CLOSE C_ORDHDR;

    if ORDHDR.orderid is null then
        out_errmsg := 'orderid-shipid <'||in_orderid||'-'||in_shipid||'> does not exist';
        return;
    end if;

    if ORDHDR.ordertype != 'Q' then
        out_errmsg := 'orderid-shipid <'||in_orderid||'-'||in_shipid||'> is not a return order';
        return;
    end if;

    -- Verify orginal order is correct
    if (ORDHDR.origorderid is null or ORDHDR.origshipid is null) then
    
      select count(1)
        into cnt
       from orderhdr
      where orderid = in_orderid
        and shipid = in_shipid
        and qtyorder > nvl(qtyrcvd,0);
    else
-- Verify still something left to return           
    select count(1)
      into cnt
     from  orderhdr
       where orderid = ORDHDR.origorderid
         and shipid = ORDHDR.origshipid
         and orderstatus = '9'
       and qtyship > 
              (select nvl(sum(qtyrcvd),0)
                from  orderhdr
                where origorderid = ORDHDR.origorderid 
                  and origshipid = ORDHDR.origshipid);
    end if;
      
    if nvl(cnt,0) = 0 then
        return;
    end if;

-- Setup new orderid shipid of not provided by calling routine
    if in_new_orderid is null then
        in_new_orderid := in_orderid;
    end if;

    if in_new_shipid is null then
      begin
        select max(shipid) + 1
          into in_new_shipid
          from orderhdr
         where orderid = in_orderid;
      exception when others then
        in_new_shipid := in_shipid + 1;
      end;
    end if;

    l_orderid := null;
    l_shipid := null;
    if (ORDHDR.origorderid is null and ORDHDR.origshipid is null) or
        (ORDHDR.shipid > 1)
        then
       l_orderid := in_orderid;
       l_shipid := in_shipid;
    else
       l_orderid := ORDHDR.origorderid;
       l_shipid := ORDHDR.origshipid;
    end if;
-- Clone Order Header
    zcl.clone_table_row('ORDERHDR',
        'ORDERID = '||in_orderid||' and SHIPID = '||in_shipid,
        in_new_orderid||','||in_new_shipid||',null,null,null,null',
        'ORDERID,SHIPID,LOADNO,STOPNO,SHIPNO,WAVE',
        null,
        in_user,
        out_errmsg);

    if out_errmsg != 'OKAY' then
        return;
    end if;

-- Clean up the orderhdr
    update  orderhdr
       set  orderstatus = '0',
            commitstatus = '0',
            loadno = null,
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
            wave = null,
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
            bulkretorderid = null,
            bulkretshipid = null,
            returntrackingno = null,
            packlistshipdate = null,
            edicancelpending = null,
            --backorderyn = 'N',
            tms_status = decode(nvl(ORDHDR.tms_status,'X'),'X','X','1'),
            tms_status_update = sysdate,
            tms_shipment_id = null,
            tms_release_id = null
     where orderid = in_new_orderid
       and shipid = in_new_shipid;

-- For each orderdtl
    for cod in (select * from orderdtl 
                 where orderid = l_orderid
                   and shipid = l_shipid)
    loop
        zcl.clone_orderdtl(cod.orderid, cod.shipid, cod.item, cod.lotnumber,
                in_new_orderid, in_new_shipid, cod.item, cod.lotnumber,
                null, in_user, out_errmsg);

        if out_errmsg != 'OKAY' then
            return;
        end if;
        
        ORDTL := NULL;
          OPEN C_ORDTL(in_orderid, in_shipid, cod.item, cod.lotnumber);
          FETCH C_ORDTL INTO ORDTL;
          CLOSE C_ORDTL;

        update  orderdtl 
           set  linestatus = 'A',
                commitstatus = null,
                qtyorder = GREATEST(nvl(nvl(cod.qtyship,cod.qtyorder),0) 
                                  - nvl(ORDTL.qtyrcvd,0),0),
                weightorder = GREATEST(nvl(cod.weightorder,0) 
                                  - nvl(ORDTL.weightrcvd,0),0),
                cubeorder = GREATEST(nvl(cod.cubeorder,0) 
                                  - nvl(ORDTL.cubercvd,0),0),
                amtorder = GREATEST(nvl(cod.amtorder,0) 
                                  - nvl(ORDTL.amtrcvd,0),0),
                qtyentered = GREATEST(nvl(cod.qtyorder,0) 
                                  - nvl(ORDTL.qtyrcvd,0),0),
                uomentered = uom,
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
                qtyrcvdgood = null,
                weightrcvdgood = null,
                cubercvdgood = null,
                amtrcvdgood = null,
                qtyrcvddmgd = null,
                weightrcvddmgd = null,
                cubercvddmgd = null,
                amtrcvddmgd = null,
                qtypick = null,
                weightpick = null,
                cubepick = null,
                amtpick = null,
                childorderid = null,
                childshipid = null,
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
                asnvariance = null
         where orderid = in_new_orderid
           and shipid = in_new_shipid
           and item = cod.item
           and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)');

        zcl.clone_table_row('ORDERDTLBOLCOMMENTS',
            'ORDERID = '||cod.orderid||' and SHIPID = '||cod.shipid
                ||' and ITEM = '''||cod.item||''''
                ||' and nvl(LOTNUMBER,''(none)'') = '''
                    ||nvl(cod.lotnumber,'(none)')||'''',
            in_new_orderid||','||in_new_shipid||','''||cod.item
                ||''','''||cod.lotnumber||'''',
            'ORDERID,SHIPID,ITEM,LOTNUMBER',
            null,
            in_user,
            out_errmsg);
               
        -- Receive against earliest delivery date instead of lowest line.
        -- Assumption made here that the 'dtlpassthrudate01' holds the delivery date of the line.
        -- Furthermore, the 'approved qty' on a line must also be taken into account and given priority.
        
        totEntered := nvl(cod.qtyorder,0);
        totRcvd := nvl(ORDTL.qtyrcvd,0);
        totRoll := GREATEST(0,totEntered - totRcvd );
        currLineEntered := 0;
        currLineRcvd := 0;
        currLineRoll :=0;
        
        -- check if created clones need to support qty approved feature.
        select count(1)
         into modeApprvd
         from orderdtlline
         where orderid = l_orderid
          and shipid = l_shipid
          and item = cod.item
          and nvl(lotnumber,'(none)') = nvl(cod.lotnumber,'(none)')
          and nvl(qtyapproved,0) > 0;

        -- Clone the order detail lines and handle any qtyapproved feature handling.
        for ol in (select *
                        from orderdtlline
                       where orderid = l_orderid
                         and shipid = l_shipid
                         and item = cod.item
                         and nvl(lotnumber,'(none)') =
                             nvl(cod.lotnumber,'(none)')
                        order by qtyapproved desc nulls last, dtlpassthrudate01 desc, linenumber desc)
        loop
           -- make a clone of the order detail line.
           zcl.clone_table_row('ORDERDTLLINE',
                    'ORDERID = '|| ol.orderid ||' and SHIPID = '||ol.shipid
                        ||' and ITEM = '''||ol.item||''''
                        ||' and nvl(LOTNUMBER,''(none)'') = '''
                            ||nvl(ol.lotnumber,'(none)')||''''
                        ||' and LINENUMBER = '|| ol.linenumber,
                            in_new_orderid||','||in_new_shipid||','''||ol.item
                        ||''','''||ol.lotnumber||''','||ol.linenumber,
                    'ORDERID,SHIPID,ITEM,LOTNUMBER,LINENUMBER',
                    null, in_user, out_errmsg);
                         
           if out_errmsg != 'OKAY' then
              return;
           end if;
              
            -- The qty approval feature can change the entered qty distribution across the detail lines.
            if ( modeApprvd > 0 ) then
              -- determine the portion of recveived quantity to attribute to this line. Do not allow
              -- approved quantity to exceed total received quantity.
              currLineRcvd := LEAST( totRcvd, nvl(ol.qtyapproved,0) );
              
              -- If the entered qty on this line is less than approved, this line needs to take more
              -- of the total and a later line(s) will have to give up the difference.
              currLineEntered := GREATEST ( nvl(ol.qty,0), currLineRcvd );
              -- If the currLineEntered for this line exceeds the amount of entered qty remaining
              -- we are in a situation where and earlier line has grabbed more than originally
              -- entered. Limit this line to the remainder.
              currLineEntered := LEAST ( currLineEntered, totEntered);
              
              -- calculate the qty to rollover for this line
              currLineRoll := GREATEST(0, currLineEntered - currLineRcvd);
              -- if all quantity that needs to be rolled has been put on previous lines
              -- then this line does not need to rollover any qty.
              currLineRoll := LEAST ( currLineRoll, totRoll );
              
              -- update the clone with the proper rolled over qty.
              update orderdtlline
               set qty = currLineRoll,
                 qtyentered = currLineRoll,
                 qtyapproved = null,
                 uomentered = cod.uom
               where orderid = in_new_orderid
               and shipid = in_new_shipid
               and item = ol.item
               and nvl(lotnumber,'(none)') = nvl(ol.lotnumber,'(none)')
               and linenumber = ol.linenumber;
               
              -- Adjust the total counters in preparation for the next pass.
              -- When one of the totals hits zero it stays at zero and will affect
              -- what is available to the next line.
              totEntered := GREATEST(0, totEntered - currLineEntered);
              totRcvd := GREATEST(0, totRcvd - currLineRcvd );
              totRoll := GREATEST(0, totRoll - currLineRoll );
           else
              update orderdtlline
              set qty = LEAST(ol.qty, totRoll),
                qtyentered = LEAST(ol.qty, totRoll),
                uomentered = cod.uom
              where orderid = in_new_orderid
              and shipid = in_new_shipid
              and item = ol.item
              and nvl(lotnumber,'(none)') = nvl(ol.lotnumber,'(none)')
              and linenumber = ol.linenumber;
              -- decrement receipt qty tracker.  Do not allow negative number.
              totRoll := GREATEST(0, totRoll - LEAST(ol.qty, totRoll));
           end if;
        end loop;

        --  Clone Order Detail with remaining receipt qty or zero
        --    For each Order Detail Line
        --      Clone orderdtline with remaining receipt qty for line 
    end loop;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;
END return_carryover;

end zreturns;
/

show errors package body zreturns;
exit;
