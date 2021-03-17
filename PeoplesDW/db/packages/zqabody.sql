create or replace package body alps.zqainspection as
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

type invadjtype is record (
     lpid         plate.lpid%type,
     adj1         varchar2(20),
     adj2         varchar2(20)
);

type invadjtbltype is table of invadjtype
     index by binary_integer;

invadj_tbl invadjtbltype;



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
       AND lotnumber = in_lot;

----------------------------------------------------------------------
CURSOR C_PLATE(in_lpid varchar2)
RETURN plate%rowtype
IS
    SELECT *
      FROM plate
     WHERE lpid = in_lpid;

----------------------------------------------------------------------
CURSOR C_QCREQUEST(in_id number)
RETURN qcrequest%rowtype
IS
    SELECT *
      FROM qcrequest
     WHERE id = in_id;

----------------------------------------------------------------------
CURSOR C_QCRESULT(in_id number, in_orderid number, in_shipid number,
       in_item varchar2, in_lot varchar2)
RETURN qcresult%rowtype
IS
    SELECT *
      FROM qcresult
     WHERE id = in_id
       AND orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item
       AND nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');

----------------------------------------------------------------------
CURSOR C_RQ(in_facility varchar2, in_custid varchar2,
       in_orderid number, in_shipid number, in_item varchar2,
       in_supplier varchar2, in_lotnumber varchar2, in_po varchar2)
IS
  SELECT *
    FROM qcrequest
   WHERE nvl(facility,in_facility) = in_facility
     AND custid = in_custid
     AND status in ('OP','IP')
     AND nvl(item, '(none)') = decode(item,null,'(none)',
                                  nvl(in_item,'(none)'))
     AND nvl(supplier, '(none)') = decode(supplier,null,'(none)',
                                  nvl(in_supplier,'(none)'))
     AND nvl(lotnumber, '(none)') = decode(lotnumber,null,'(none)',
                                  nvl(in_lotnumber,'(none)'))
     AND nvl(po, '(none)') = decode(po,null,'(none)',
                                  nvl(in_po,'(none)'))
     AND (type = 'NEXT'
        OR (type = 'REC'
           AND nvl(begindate,trunc(sysdate)) <= trunc(sysdate)
           AND nvl(enddate,trunc(sysdate)) >= trunc(sysdate))
        OR (type = 'SPEC'
           AND orderid = in_orderid
           AND shipid = in_shipid)
        OR (qa_by_po_item = 'Y')
         )
    order by decode(qa_by_po_item,'Y',1,2), item, lotnumber, supplier, decode(type,'SPEC',1,'NEXT',2,'REC',3);

cursor cur_Customer_Aux (in_custid varchar2) is
  select custid,qa_by_po_item
    from customer_aux
   where custid = in_custid;
CUS cur_Customer_Aux%rowtype;

----------------------------------------------------------------------




-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


PROCEDURE establish_auto_po_item_request
(
    in_custid    IN      varchar2,
    in_po        IN      varchar2,
    in_userid    IN      varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
) is

cntRows integer;
out_id number;

begin

out_errno := 0;
out_errmsg := 'OKAY';

out_id := 0;
begin
  select id
    into out_id
    from qcrequest
   where custid = in_custid
     and po = in_po
     and qa_by_po_item = 'Y';
exception when no_data_found then
  out_id := 0;
end;

if out_id = 0 then

  zqa.next_id(out_id, out_errmsg);
  if out_errmsg <> 'OKAY' then
    out_errno := 105;
    return;
  end if;

  insert into qcrequest(id, custid, status, type, sampletype,
                        samplesize, passpercent, lastuser,
                        lastupdate, po, qa_by_po_item,
                        putaway_before_inspection_yn,
                        putaway_after_inspection_yn)
   values (out_id, in_custid, 'IP', 'REC', 'QTY', 1, 100, in_userid,
           sysdate, in_po, 'Y',
           trim(substr(zci.default_value('QAPUTBEFOREINSPECT'),1,1)),
           trim(substr(zci.default_value('QAPUTAFTERINSPECT'),1,1)));

end if;

out_errmsg := 'OKAY';
out_errno := out_id;

exception when others then
  out_errno := sqlcode;
  out_errmsg := substr(sqlerrm,1,80);
end;


----------------------------------------------------------------------
--
-- next_id
--
----------------------------------------------------------------------
PROCEDURE next_id
(
    out_id  OUT   number,
    out_msg OUT   varchar2
)
IS

currcount integer;

BEGIN

currcount := 1;
while (currcount = 1)
loop
  select qcrequestseq.nextval
    into out_id
    from dual;
  select count(1)
    into currcount
    from qcrequest
   where id = out_id;
end loop;

out_msg := 'OKAY';

EXCEPTION when others then
  out_msg := sqlerrm;
END next_id;


----------------------------------------------------------------------
--
-- add_qa_plate
--
----------------------------------------------------------------------
PROCEDURE add_qa_plate
(
    in_lpid      IN      varchar2,
    in_user      IN      varchar2,
    out_action   OUT     varchar2,
    out_id       OUT     number,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
)
IS

PLT     plate%rowtype;
ORD     orderhdr%rowtype;

ITEM    custitemview%rowtype;
DTL     orderdtl%rowtype;

CURSOR C_QC_BY_PO(in_orderid number, in_shipid number, in_item varchar2,
       in_lot varchar2)
IS
  SELECT R.ID, Q.item
    FROM qcresult R, qcrequest Q
   WHERE R.ID = Q.ID
     AND R.orderid = in_orderid
     AND R.shipid = in_shipid
     AND R.item = in_item
     AND nvl(R.lotnumber, nvl(in_lot,'(none)')) = nvl(in_lot,'(none)')
  order by R.lotnumber;

CURSOR C_QC(in_orderid number, in_shipid number, in_item varchar2,
       in_lot varchar2)
IS
  SELECT R.ID, Q.item
    FROM qcresult R, qcrequest Q
   WHERE R.ID = Q.ID
     AND R.orderid = in_orderid
     AND R.shipid = in_shipid
     AND R.item = in_item
     AND nvl(R.lotnumber, nvl(in_lot,'(none)')) = nvl(in_lot,'(none)')
  order by R.lotnumber;

QC   C_QC%rowtype;

REQ  qcrequest%rowtype;
RES  qcresult%rowtype;

plt_lot plate.lotnumber%type;

qty number;

prevqtyrcvd qcresultdtl.qtyreceived%type;

errmsg  varchar2(200);
mark    varchar2(20);

BEGIN

   out_errno := 0;
   out_errmsg := 'OKAY';
   out_action := 'NONE';
   out_id := null;


-- Read plate
   PLT := NULL;
   OPEN C_PLATE(IN_LPID);
   FETCH C_PLATE INTO PLT;
   CLOSE C_PLATE;
   if PLT.lpid is null then
      out_errno := 100;
      out_errmsg := 'Invalid Plate';
      return;
   end if;


-- read order
   ORD := NULL;
   OPEN C_ORDHDR(PLT.orderid, PLT.shipid);
   FETCH C_ORDHDR INTO ORD;
   CLOSE C_ORDHDR;
   if ORD.orderid is null then
      out_errno := 101;
      out_errmsg := 'Invalid ORDER';
      return;
   end if;

-- Verify this is a receipt
   if ORD.ordertype <> 'R' then
      out_errno := 102;
      out_errmsg := 'Order not a receipt';
      return;
   end if;


-- check if have an existing open qa inspection for this order/ item/ lot
   QC := null;
   OPEN C_QC(PLT.orderid, PLT.shipid, PLT.item, PLT.lotnumber);
   FETCH C_QC into QC;
   CLOSE C_QC;

   REQ := null;
   RES := null;

   if QC.id is not null then
      OPEN C_QCREQUEST(QC.ID);
      FETCH C_QCREQUEST INTO REQ;
      CLOSE C_QCREQUEST;

   -- If the request did not specify lots do no track lots
      if REQ.lotnumber is null then
         plt_lot := null;
      else
         plt_lot := PLT.lotnumber;
      end if;

      OPEN C_QCRESULT(QC.ID, PLT.orderid, PLT.shipid, PLT.item, plt_lot);
      FETCH C_QCRESULT INTO RES;
      CLOSE C_QCRESULT;
   else
      out_errno := 103;
      out_errmsg := 'No pending QA';
      return;
   end if;

 -- Check the status of this plate and how to handle it
   if PLT.invstatus = 'IN' then
      RES.qtychecked := nvl(RES.qtychecked,0) + PLT.quantity;
      RES.qtyreceived := nvl(RES.qtyreceived,0) + PLT.quantity;
      out_id := REQ.id;
      if REQ.putaway_before_inspection_yn = 'Y' then
        out_action := 'PUT';
      else
        out_action := 'RF';
      end if;
   elsif PLT.invstatus = 'QA' then
      RES.qtyreceived := nvl(RES.qtyreceived,0) + PLT.quantity;
      out_id := REQ.id;
      out_action := 'PUT';
      update qcresult
         set qtyreceived = nvl(qtyreceived,0) + PLT.quantity
       where id = RES.id
         and orderid = RES.orderid
         and shipid = RES.shipid
         and item = RES.item
         and nvl(lotnumber,'(none)') = nvl(RES.lotnumber,'(none)');
      return;
   else
      out_errno := 104;
      out_errmsg := 'Plate invstatus must be IN or QA';
      return;
   end if;

   qty := greatest(RES.qtytoinspect - RES.qtychecked, 0);

   if qty > 0 then
      out_errmsg := 'OKAY: '||qty||' left for inspection';
   end if;



-- Need to check this guy so add an entry

-- update item
   begin
     INSERT INTO qcresultdtl(
      id,
      orderid,
      shipid,
      lpid,
      qtyreceived,
      qtychecked,
      qtypassed,
      qtyfailed,
      inspectdate,
      inspector,
      disposition,
      notes,
      lastuser,
      lastupdate,
      custid,
      item,
      lotnumber,
      po
     )
     values
     (
      REQ.id,
      PLT.orderid,
      PLT.shipid,
      PLT.lpid,
      PLT.quantity,
      PLT.quantity,
      0,
      0,
      null,
      null,
      null,
      null,
      in_user,
      sysdate,
      REQ.custid,
      RES.item,
      RES.lotnumber,
      ORD.po
     );
   exception when DUP_VAL_ON_INDEX then
      select qtyreceived
        into prevqtyrcvd
        from qcresultdtl
       where id = REQ.id
         and orderid = PLT.orderid
         and shipid = PLT.shipid
         and lpid = PLT.lpid
         and item = PLT.item
         and nvl(lotnumber,nvl(PLT.lotnumber,'(none)'))
                         = nvl(PLT.lotnumber,'(none)');
      update qcresultdtl
         set qtyreceived = PLT.quantity,
             qtychecked = PLT.quantity
       where id = REQ.id
         and orderid = PLT.orderid
         and shipid = PLT.shipid
         and lpid = PLT.lpid
         and item = PLT.item
         and nvl(lotnumber,nvl(PLT.lotnumber,'(none)'))
                         = nvl(PLT.lotnumber,'(none)');

      PLT.quantity := PLT.quantity - prevqtyrcvd;

   when others then
        null;
   end;

   update qcresult
      set qtyreceived = nvl(qtyreceived,0) + PLT.quantity,
          qtychecked = nvl(qtychecked,0) + PLT.quantity
    where id = RES.id
     and orderid = RES.orderid
     and shipid = RES.shipid
     and item = RES.item
     and nvl(lotnumber,'(none)') = nvl(RES.lotnumber,'(none)');

   out_id := REQ.id;
   if REQ.putaway_before_inspection_yn = 'Y' then
     out_action := 'PUT';
   else
     out_action := 'RF';
   end if;

   return;

EXCEPTION when others then
  out_errno := sqlcode;
  out_errmsg := sqlerrm;

END add_qa_plate;


----------------------------------------------------------------------
--
-- change_qa_plate
--
----------------------------------------------------------------------
PROCEDURE change_qa_plate
(
    in_lpid      IN      varchar2,
    in_status    IN      varchar2,
    in_user      IN      varchar2,
    out_adj1     OUT     varchar2,
    out_adj2     OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
)
IS

PLT     plate%rowtype;
ORD     orderhdr%rowtype;

ITEM    custitemview%rowtype;
DTL     orderdtl%rowtype;

CURSOR C_QC(in_orderid number, in_shipid number, in_item varchar2,
       in_lot varchar2)
IS
  SELECT R.ID, Q.item
    FROM qcresult R, qcrequest Q
   WHERE R.ID = Q.ID
     AND R.orderid = in_orderid
     AND R.shipid = in_shipid
     AND R.item = in_item
     AND nvl(R.lotnumber, nvl(in_lot,'(none)')) = nvl(in_lot,'(none)')
  order by R.lotnumber;

QC   C_QC%rowtype;

REQ  qcrequest%rowtype;
RES  qcresult%rowtype;

plt_lot plate.lotnumber%type;

qty number;

prevqtyrcvd qcresultdtl.qtyreceived%type;

l_controlnumber varchar2(10);
errno integer;

errmsg  varchar2(200);
mark    varchar2(20);

BEGIN

   out_errno := 0;
   out_errmsg := 'OKAY';


-- Read plate
   PLT := NULL;
   OPEN C_PLATE(IN_LPID);
   FETCH C_PLATE INTO PLT;
   CLOSE C_PLATE;
   if PLT.lpid is null then
      out_errno := 200;
      out_errmsg := 'Invalid Plate';
      return;
   end if;


-- read order
   ORD := NULL;
   OPEN C_ORDHDR(PLT.orderid, PLT.shipid);
   FETCH C_ORDHDR INTO ORD;
   CLOSE C_ORDHDR;
   if ORD.orderid is null then
      out_errno := 201;
      out_errmsg := 'Invalid ORDER';
      return;
   end if;

-- Verify this is a receipt
   if ORD.ordertype <> 'R' then
      out_errno := 202;
      out_errmsg := 'Order not a receipt';
      return;
   end if;


-- check if have an existing open qa inspection for this order/ item/ lot
   QC := null;
   OPEN C_QC(PLT.orderid, PLT.shipid, PLT.item, PLT.lotnumber);
   FETCH C_QC into QC;
   CLOSE C_QC;

   REQ := null;
   RES := null;

   if QC.id is not null then
      OPEN C_QCREQUEST(QC.ID);
      FETCH C_QCREQUEST INTO REQ;
      CLOSE C_QCREQUEST;

   -- If the request did not specify lots do no track lots
      if REQ.lotnumber is null then
         plt_lot := null;
      else
         plt_lot := PLT.lotnumber;
      end if;

      OPEN C_QCRESULT(QC.ID, PLT.orderid, PLT.shipid, PLT.item, plt_lot);
      FETCH C_QCRESULT INTO RES;
      CLOSE C_QCRESULT;
   else
      out_errno := 203;
      out_errmsg := 'No pending QA';
      return;
   end if;

 -- verify plate has QA status
   if PLT.invstatus not in ('IN','QA') then
      out_errno := 205;
      out_errmsg := 'Plate current invstatus must be IN or QA';
      return;
   end if;

 -- check we are changing status
   if PLT.invstatus = in_status then
      out_errno := 206;
      out_errmsg := 'Plate current invstatus matches new status:'||in_status;
      return;
   end if;


 -- verify valid new status
   if in_status not in ('IN','QA') then
      out_errno := 204;
      out_errmsg := 'Plate new invstatus must be IN or QA';
      return;
   end if;

   zia.change_invstatus(in_lpid, in_status,
             'QA','QA',in_user,
             out_adj1, out_adj2, l_controlnumber, errno, errmsg, 'Y');

   if errno != 0 then
       out_errno := errno;
       out_errmsg := 'LP:'||in_lpid||' Errno:'||errno||' / ' || errmsg;
       return;
   end if;


 -- Check the status of this plate and how to handle it
   if in_status = 'IN' then

      RES.qtychecked := nvl(RES.qtychecked,0) + PLT.quantity;
   elsif in_status = 'QA' then

      update qcresult
         set qtychecked = nvl(qtychecked,0) - PLT.quantity
       where id = RES.id
         and orderid = RES.orderid
         and shipid = RES.shipid
         and item = RES.item
         and nvl(lotnumber,'(none)') = nvl(RES.lotnumber,'(none)');

      delete qcresultdtl
       where lpid = in_lpid
         and id = RES.id;

      return;
   else
      out_errno := 204;
      out_errmsg := 'Plate new invstatus must be IN or QA';
      return;
   end if;

   qty := greatest(RES.qtytoinspect - RES.qtychecked, 0);

   if qty > 0 then
      out_errmsg := 'OKAY: '||qty||' left for inspection';
   end if;

-- Need to check this guy so add an entry

-- update item
   begin
     INSERT INTO qcresultdtl(
      id,
      orderid,
      shipid,
      lpid,
      qtyreceived,
      qtychecked,
      qtypassed,
      qtyfailed,
      inspectdate,
      inspector,
      disposition,
      notes,
      lastuser,
      lastupdate,
      custid,
      item,
      lotnumber,
      po
     )
     values
     (
      REQ.id,
      PLT.orderid,
      PLT.shipid,
      PLT.lpid,
      PLT.quantity,
      PLT.quantity,
      0,
      0,
      null,
      null,
      null,
      null,
      in_user,
      sysdate,
      RES.custid,
      RES.item,
      RES.lotnumber,
      ORD.po
     );
   exception when DUP_VAL_ON_INDEX then
      select qtyreceived
        into prevqtyrcvd
        from qcresultdtl
       where id = REQ.id
         and orderid = PLT.orderid
         and shipid = PLT.shipid
         and lpid = PLT.lpid
         and item = PLT.item
         and nvl(lotnumber,nvl(PLT.lotnumber,'(none)')) =
                           nvl(PLT.lotnumber,'(none)');
      update qcresultdtl
         set qtyreceived = PLT.quantity,
             qtychecked = PLT.quantity
       where id = REQ.id
         and orderid = PLT.orderid
         and shipid = PLT.shipid
         and lpid = PLT.lpid
         and item = PLT.item
         and nvl(lotnumber,nvl(PLT.lotnumber,'(none)')) =
                           nvl(PLT.lotnumber,'(none)');

      PLT.quantity := PLT.quantity - prevqtyrcvd;

   when others then
        null;
   end;

   update qcresult
        set qtychecked = nvl(qtychecked,0) + PLT.quantity
    where id = RES.id
     and orderid = RES.orderid
     and shipid = RES.shipid
     and item = RES.item
     and nvl(lotnumber,'(none)') = nvl(RES.lotnumber,'(none)');


   return;

EXCEPTION when others then
  out_errno := sqlcode;
  out_errmsg := sqlerrm;

END change_qa_plate;


----------------------------------------------------------------------
--
-- check_qa_order
--
----------------------------------------------------------------------
PROCEDURE check_qa_order
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_user      IN      varchar2,
    out_action   OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
)
IS
CURSOR C_ORDDTL(in_orderid number, in_shipid number)
IS
  SELECT nvl(OH.tofacility,OH.fromfacility) facility, OH.custid,
         OH.shipper supplier,
         OD.item, OD.lotnumber, nvl(OD.qtyorder,0) qtyorder, OD.uom
    FROM orderdtl OD, orderhdr OH
   WHERE OH.orderid = in_orderid
     AND OH.shipid = in_shipid
     AND OH.orderstatus = 'A'
     AND OH.orderid = OD.orderid
     AND OH.shipid = OD.shipid
     AND OD.linestatus != 'X';

CURSOR c_qc_result(in_orderid number, in_shipid number)
IS
  SELECT QR.id, QR.qtyexpected, QR.qtytoinspect, QR.qtyreceived, QR.status,
         QR.orderid, QR.shipid, QR.lotnumber,
         QRQ.type, QRQ.sampletype, QRQ.samplesize, QRQ.sampleuom,
         QRQ.status rq_status, QR.custid, QR.item, I.baseuom
    FROM custitem I, qcrequest QRQ, qcresult QR
   WHERE QR.orderid = in_orderid
     AND QR.shipid = in_shipid
     AND QRQ.id = QR.id
     AND QR.custid = I.custid
     AND QR.item = I.item
     AND nvl(QR.lotnumber, '(none)') = nvl(QRQ.lotnumber, '(none)');

cursor c_qc_request (in_id number) is
  select *
    from qcrequest
   where id = in_id;

CRQ C_RQ%rowtype;
qtytocheck integer;
cnt integer;
errmsg varchar2(200);
ORD orderhdr%rowtype;
cntRows integer;
cntOpenRows integer;
auto_status qcresult.status%type;
intErrNo integer;
l_exclude integer;

PROCEDURE add_qcresult(OD C_ORDDTL%rowtype, RQ C_RQ%rowtype, in_qty integer)
IS
BEGIN
    begin
        INSERT INTO qcresult
          ( id,
            orderid,
            shipid,
            supplier,
            receiptdate,
            qtyexpected,
            qtytoinspect,
            status,
            lastuser,
            lastupdate,
            custid,
            item,
            lotnumber,
            po
          )
        VALUES
          (
            RQ.id,
            in_orderid,
            in_shipid,
            OD.supplier,
            sysdate,
            OD.qtyorder,
            in_qty,
            'IP',
            in_user,
            sysdate,
            OD.custid,
            OD.item,
            RQ.lotnumber,
            RQ.po
          );
     EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           UPDATE qcresult
              SET qtyexpected = qtyexpected + OD.qtyorder,
                  qtytoinspect = qtytoinspect + in_qty
            WHERE id = RQ.id
              AND orderid = in_orderid
              AND shipid = in_shipid
              AND item = OD.item
              AND nvl(lotnumber,'(none)') = nvl(RQ.lotnumber,'(none)');
        WHEN OTHERS THEN
            null;
     end;


END add_qcresult;


BEGIN

   out_errno := 0;
   out_errmsg := 'OKAY';
   out_action := 'NONE';

   ORD := NULL;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR INTO ORD;
   CLOSE C_ORDHDR;
   if ORD.orderid is null then
      out_errno := 101;
      out_errmsg := 'Invalid ORDER';
      return;
   end if;

   -- Verify this is a receipt
   if ORD.ordertype <> 'R' then
      out_errno := 102;
      out_errmsg := 'Order not a receipt';
      return;
   end if;

   CUS := null;
   open cur_Customer_Aux(ORD.custid);
   fetch cur_Customer_Aux into CUS;
   close cur_Customer_Aux;
   if CUS.CustId is null then
      out_errno := 103;
      out_errmsg := 'Invalid Cust';
      return;
   end if;


   if CUS.qa_by_po_item = 'Y' then
     l_exclude := 0;
     begin
       execute immediate 'select count(1) from Exclude_PO_Prefix_' || rtrim(ORD.custid)
               || ' where code = substr(''' || ORD.po || ''', 1, length(rtrim(code)))'
            into l_exclude;
     exception when others then
       l_exclude := 0;
     end;
     if l_exclude != 0 then
       out_errmsg := 'OKAY';
       return;
     end if;
   end if;

   if CUS.qa_by_po_item = 'Y' then

     establish_auto_po_item_request(ORD.custid, ORD.po, in_user, intErrNo, out_errmsg);

     if out_errmsg <> 'OKAY' then
       out_errno := intErrNo;
       return;
     end if;

     open c_qc_request(out_errno);
     fetch c_qc_request into CRQ;
     close c_qc_request;
     cntOpenRows := 0;

     for crec in C_ORDDTL(in_orderid, in_shipid)
     loop
       begin
         select status
           into auto_status
           from qcresult
          where id = CRQ.id
            and item = crec.item;
         cntRows := 1;
       exception when no_data_found then
         cntRows := 0;
       end;
       if cntRows = 0 then
         cntOpenRows := cntOpenRows + 1;
         add_qcresult(crec, CRQ, 1);
       elsif cntRows <> 0 and auto_status not in ('PA','FA') then
         cntOpenRows := cntOpenRows + 1;
       end if;
     end loop;

     if cntOpenRows <> 0 then
       out_action := 'QA';
     end if;

     return;

   end if;

   -- if already have entries return we will QA
   cnt := 0;
   select count(1)
     into cnt
     from qcinspectionview
    where orderid = in_orderid
      and shipid = in_shipid
      and status in ('OP','IP')
      and nvl(qa_by_po_item,'N') = 'N';

   if cnt > 0 then
     out_action := 'QA';
     return;
   end if;

   -- check expected items for QA setup
   for crec in C_ORDDTL(in_orderid, in_shipid)
   loop

     -- try to locate qcrequest that is still open for this item

     for crq in C_RQ(crec.facility,crec.custid,in_orderid,in_shipid,
        crec.item, crec.supplier,crec.lotnumber,ord.po)
     loop

       out_action := 'QA';
       qtytocheck := 0;

       add_qcresult(crec, crq, qtytocheck);

       exit;

     end loop;

   end loop;

   -- for each one recalc qty and update request to close it
   -- If this is a NEXT or SPEC close the request so we do not start another
   for crec in c_qc_result(in_orderid, in_shipid) loop

     if crec.type in ('NEXT','SPEC') and crec.status = 'OP' then
        update qcrequest
           set status = 'IP'
         where id = crec.id;
     end if;
     -- Determine how many to check
     if crec.sampletype = 'ALL' then
       qtytocheck := crec.qtyexpected;
     elsif crec.sampletype = 'QTY' then
       -- convert to base UOM
       -- Determine the weight of the objects
       zbut.translate_uom(crec.custid, crec.item, crec.samplesize,
              crec.sampleuom, crec.baseuom, qtytocheck, errmsg);
       if errmsg != 'OKAY' then
         qtytocheck := 0;
       end if;
     elsif crec.sampletype = 'PCT' then
       qtytocheck := crec.qtyexpected * crec.samplesize / 100;
     else
       qtytocheck := 0;
     end if;

     update qcresult
        set qtytoinspect = qtytocheck
      where id = crec.id
        and orderid = crec.orderid
        and shipid = crec.shipid
        and item = crec.item
        and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)');

   end loop;

EXCEPTION when others then
  out_errno := sqlcode;
  out_errmsg := 'CQAO'||sqlerrm;
END check_qa_order;

----------------------------------------------------------------------
--
-- check_qa_order_item
--
----------------------------------------------------------------------
PROCEDURE check_qa_order_item
(
    in_orderid   IN      number,
    in_shipid    IN      number,
    in_item      IN      varchar2,
    in_lot       IN      varchar2,
    in_qty       IN      number,
    in_user      IN      varchar2,
    out_qty      OUT     number,
    out_action   OUT     varchar2,
    out_errno    OUT     number,
    out_errmsg   OUT     varchar2
)
IS
CURSOR C_ORDDTL(in_orderid number, in_shipid number,
       in_item varchar2, in_lot varchar2)
IS
  SELECT nvl(OH.tofacility,OH.fromfacility) facility, OH.custid,
         OH.shipper supplier,
         OD.item, OD.lotnumber, nvl(OD.qtyorder,0) qtyorder, OD.uom
    FROM orderdtl OD, orderhdr OH
   WHERE OH.orderid = in_orderid
     AND OH.shipid = in_shipid
     AND OH.orderstatus = 'A'
     AND OH.orderid = OD.orderid
     AND OH.shipid = OD.shipid
     AND OD.item = in_item
     AND nvl(OD.lotnumber,'(none)') = nvl(in_lot,'(none)')
     AND OD.linestatus != 'X';

CURSOR c_qc_result(in_orderid number, in_shipid number, in_id number,
             in_item varchar2, in_lot varchar2)
IS
  SELECT QR.id, QR.qtyexpected, QR.qtytoinspect, QR.qtyreceived,
         QR.qtychecked, QR.status, QR.lotnumber,
         QR.orderid, QR.shipid,
         QRQ.type, QRQ.sampletype, QRQ.samplesize, QRQ.sampleuom,
         QRQ.status rq_status, QR.custid, QR.item, I.baseuom
    FROM custitem I, qcrequest QRQ, qcresult QR
   WHERE QR.orderid = in_orderid
     AND QR.shipid = in_shipid
     AND QR.id = in_id
     AND QRQ.id = QR.id
     AND QRQ.custid = I.custid
     AND QR.item = in_item
     AND nvl(QR.lotnumber,nvl(in_lot, '(none)')) = nvl(in_lot, '(none)')
     AND in_item = I.item;

CURSOR cur_qc_result_by_item(in_orderid number, in_shipid number, in_item varchar2,
       in_lot varchar2)
IS
  SELECT QR.id, QR.qtyexpected, QR.qtytoinspect, QR.qtyreceived,
         QR.qtychecked, QR.status,
         QR.orderid, QR.shipid,
         QRQ.type, QRQ.sampletype, QRQ.samplesize, QRQ.sampleuom,
         QRQ.status rq_status
    FROM qcrequest QRQ, qcresult QR
   WHERE QR.orderid = in_orderid
     AND QR.shipid = in_shipid
     AND QR.item = in_item
     AND nvl(QR.lotnumber,nvl(in_lot,'(none)')) = nvl(in_lot,'(none)')
     AND QRQ.id = QR.id
  ORDER BY QRQ.lotnumber;

OD C_ORDDTL%rowtype;
RQ C_RQ%rowtype;
ORD orderhdr%rowtype;

qtytocheck integer;
baseqty integer;
cnt integer;
curr_id integer;
auto_id number;
auto_count number;
auto_status qcresult.status%type;
errmsg varchar2(200);

PROCEDURE add_qcresult(OD C_ORDDTL%rowtype, RQ C_RQ%rowtype, in_qty integer)
IS
BEGIN
    begin
        INSERT INTO qcresult
          (
            id,
            orderid,
            shipid,
            supplier,
            receiptdate,
            qtyexpected,
            qtytoinspect,
            status,
            lastuser,
            lastupdate,
            custid,
            item,
            lotnumber,
            po
          )
        VALUES
          (
            RQ.id,
            in_orderid,
            in_shipid,
            OD.supplier,
            sysdate,
            OD.qtyorder,
            in_qty,
            'OP',
            in_user,
            sysdate,
            OD.custid,
            OD.item,
            RQ.lotnumber,
            RQ.po
          );
     EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           UPDATE qcresult
              SET qtyexpected = qtyexpected + OD.qtyorder,
                  qtytoinspect = qtytoinspect + in_qty
            WHERE id = RQ.id
              AND orderid = in_orderid
              AND shipid = in_shipid
              AND item = OD.item
              AND nvl(lotnumber,'(none)') = nvl(RQ.lotnumber,'(none)');
        WHEN OTHERS THEN
            null;
     end;


END add_qcresult;


BEGIN

    out_errno := 0;
    out_errmsg := 'OKAY';
    out_action := 'NONE';

    ORD := null;
    OPEN C_ORDHDR(in_orderid, in_shipid);
    FETCH C_ORDHDR into ORD;
    CLOSE C_ORDHDR;

   CUS := null;
   open cur_Customer_Aux(ORD.custid);
   fetch cur_Customer_Aux into CUS;
   close cur_Customer_Aux;
   if CUS.CustId is null then
      out_errno := 103;
      out_errmsg := 'Invalid Cust';
      return;
   end if;

   if CUS.qa_by_po_item = 'Y' then

     auto_id := 0;
     begin
       select id
          into auto_id
          from qcrequest
         where custid = ORD.custid
           and po = ORD.po
           and qa_by_po_item = 'Y';
     exception when no_data_found then
       auto_id := 0;
     end;

     if (auto_id = 0) then
       out_errno := 104;
       out_errmsg := 'Auto QA not found';
       return;
     end if;

     auto_count := 0;
     begin
       select status
         into auto_status
         from qcresult
        where id = auto_id
          and item = in_item;
       auto_count := 1;
     exception when no_data_found then
       auto_count := 0;
     end;

     if (auto_count = 0) then
       out_action := 'IN';
     elsif (auto_status = 'PA') then  -- already passed
       out_action := 'NONE';
     elsif (auto_status = 'FA') then  -- already failed
       out_action := 'QC';
     else
       out_action := 'QA';  -- in progress
     end if;

     if (auto_count = 0) then
        insert into qcresult
          (id, orderid, shipid, supplier, receiptdate, qtyexpected,
           qtytoinspect, status, lastuser, lastupdate, custid, item, po
          )
          values
          (auto_id, in_orderid, in_shipid, ORD.shipper, sysdate, in_qty,
           in_qty, 'IP', in_user, sysdate, ORD.custid, in_item, ORD.po);
     elsif (auto_status not in ('PA','FA')) then
       update qcresult
          set qtyexpected = qtyexpected + in_qty,
              status = 'IP',
              lastuser = in_user,
              lastupdate = sysdate
        where id = auto_id
          and item = in_item;
     end if;

     return;

   end if;

  -- if already have entries return we will QA
    for crec in cur_qc_result_by_item(in_orderid, in_shipid, in_item, in_lot) loop

       out_action := 'QR';

       out_qty := crec.qtytoinspect - nvl(crec.qtychecked,0);

       if nvl(crec.qtyexpected,0) < nvl(crec.qtyreceived,0) + in_qty then

         for crec2 in c_qc_result(in_orderid, in_shipid, crec.id,
          in_item, in_lot) loop

             baseqty := greatest(nvl(crec2.qtyexpected,0),
                     nvl(crec2.qtyreceived,0) + in_qty);

             -- Determine how many to check
             if crec2.sampletype = 'ALL' then
                qtytocheck := baseqty;
                elsif crec2.sampletype = 'QTY' then
                -- convert to base UOM
             -- Determine the weight of the objects
                zbut.translate_uom(crec2.custid, crec2.item, crec2.samplesize,
                  crec2.sampleuom, crec2.baseuom, qtytocheck, errmsg);
                if errmsg != 'OKAY' then
                   qtytocheck := 0;
                end if;
             elsif crec2.sampletype = 'PCT' then
                qtytocheck := baseqty * crec2.samplesize / 100;
             else
                qtytocheck := 0;
             end if;

             update qcresult
                set qtytoinspect = qtytocheck
              where id = crec2.id
                and orderid = crec2.orderid
                and shipid = crec2.shipid
                and item = crec2.item
                and nvl(lotnumber,'(none)') = nvl(crec2.lotnumber,'(none)');

             out_qty := qtytocheck - nvl(crec2.qtychecked,0);

         end loop;

       end if;

       return;

    end loop;

    OD := null;
    OPEN C_ORDDTL(in_orderid, in_shipid, in_item, in_lot);
    FETCH C_ORDDTL into OD;
    CLOSE C_ORDDTL;

    if OD.custid is null then
       OD.item := in_item;
       OD.lotnumber := in_lot;
       OD.facility := ORD.tofacility;
       OD.custid := ORD.custid;
       OD.supplier := ORD.shipper;
       OD.qtyorder := 0;
    end if;

    for crq in C_RQ(OD.facility,OD.custid,in_orderid,in_shipid,
         OD.item, OD.supplier,OD.lotnumber,ORD.po)
    loop
       out_action := 'QR';
       if crq.sampletype = 'ALL' then
          qtytocheck := OD.qtyorder;
       elsif crq.sampletype = 'QTY' then
          qtytocheck := crq.samplesize;
       elsif crq.sampletype = 'PCT' then
          qtytocheck := OD.qtyorder * crq.samplesize / 100;
       else
          qtytocheck := 0;
       end if;
       out_qty := qtytocheck;
       add_qcresult(OD, crq, qtytocheck);
       curr_id := crq.id;
       exit;
    end loop;


-- for each one recalc qty and update request to close it
-- If this is a NEXT or SPEC close the request so we do not start another
   for crec in c_qc_result(in_orderid, in_shipid, curr_id, in_item, in_lot) loop

     if crec.type in ('NEXT','SPEC') and crec.rq_status = 'OP' then
        update qcrequest
           set status = 'IP',
               lastuser = in_user,
               lastupdate = sysdate
         where id = crec.id;
     end if;

     baseqty := greatest(nvl(crec.qtyexpected,0), nvl(crec.qtyreceived,0)
                 + in_qty);
  -- Determine how many to check
     if crec.sampletype = 'ALL' then
        qtytocheck := baseqty;
     elsif crec.sampletype = 'QTY' then
     -- convert to base UOM
-- Determine the weight of the objects
      zbut.translate_uom(crec.custid, crec.item, crec.samplesize,
              crec.sampleuom, crec.baseuom, qtytocheck, errmsg);
      if errmsg != 'OKAY' then
         qtytocheck := 0;
      end if;
     elsif crec.sampletype = 'PCT' then
        qtytocheck := baseqty * crec.samplesize / 100;
     else
        qtytocheck := 0;
     end if;

     update qcresult
        set qtytoinspect = qtytocheck
      where id = crec.id
        and orderid = crec.orderid
        and shipid = crec.shipid
        and item = crec.item
        and nvl(lotnumber,'(none)') = nvl(crec.lotnumber,'(none)');

     out_qty := qtytocheck;

   end loop;

EXCEPTION when others then
  out_errno := sqlcode;
  out_errmsg := 'CQAO'||sqlerrm;
END check_qa_order_item;

----------------------------------------------------------------------
--
-- complete_inspection
--
------------------------------------------------------------------------
PROCEDURE complete_inspection
(
    in_id       IN      number,
    in_orderid  IN      number,
    in_shipid   IN      number,
    in_item     IN      varchar2,
    in_lot      IN      varchar2,
    in_passfail IN      varchar2, -- PASS if matches percentage
                                  -- FAIL if matches percentage
                                  -- F_PASS - force pass
                                  -- F_FAIL - force fail
    in_user     IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)
IS

  ORD     orderhdr%rowtype;
  REQ  qcrequest%rowtype;
  RES  qcresult%rowtype;

  plt_lot plate.lotnumber%type;

  ld_status loads.loadstatus%type;

  force BOOLEAN;
  pass BOOLEAN;
  l_controlnumber varchar2(10);
  l_invstatus varchar2(2);
  l_new_qcresult_status varchar2(2);
  adj1 varchar2(20);
  adj2 varchar2(20);

  errno integer;
  errmsg varchar2(255);
  logMsg varchar2(255);

  ix integer;
  cnt integer;

  CURSOR C_PLT(in_orderid number, in_shipid number,
         in_item varchar2, in_lot varchar2)
  IS
    SELECT lpid, lotnumber
      FROM plate
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item
       AND nvl(lotnumber,'(none)') = nvl(in_lot,nvl(lotnumber,'(none)'))
       AND invstatus in ('QA','IN');

  CURSOR C_CUST(in_custid varchar2)
  IS
    SELECT QAEnforceSamples
      FROM customer
     WHERE custid = in_custid;

CUST C_CUST%rowtype;



BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

-- NOTE THERE MAY BE MORE THAT ONE REQUEST FOR AN ORDER

-- read order
   ORD := NULL;
   OPEN C_ORDHDR(in_orderid, in_shipid);
   FETCH C_ORDHDR INTO ORD;
   CLOSE C_ORDHDR;
   if ORD.orderid is null then
      out_errno := 100;
      out_errmsg := 'Invalid ORDER';
      return;
   end if;

-- Verify trailer is closed for receipts
   if ORD.ordertype = 'R' then
     select loadstatus
       into ld_status
       from loads
      where loadno = ORD.loadno;

     if ld_status not in ('E','R') then
        out_errno := 101;
        out_errmsg := 'Load must have trailer empty';
        return;
     end if;
   end if;

-- Get the original request
   REQ := null;
   OPEN C_QCREQUEST(in_id);
   FETCH C_QCREQUEST into REQ;
   CLOSE C_QCREQUEST;

   if REQ.id is null then
      out_errno := 104;
      out_errmsg := 'No qa request for id.';
      return;
   end if;

-- check if there are any open qa results for this order

-- If the request did not specify lots do no track lots
   if REQ.lotnumber is null then
      plt_lot := null;
   else
      plt_lot := in_lot;
   end if;

   RES := null;
   OPEN C_QCRESULT(in_id, in_orderid, in_shipid, in_item, plt_lot);
   FETCH C_QCRESULT into RES;
   CLOSE C_QCRESULT;

   if RES.id is null then
      out_errno := 102;
      out_errmsg := 'No qa for id.';
      return;
   end if;

   if RES.status not in ('OP','IP') then
      out_errno := 103;
      out_errmsg := 'QA not open.';
      return;
   end if;


-- Verify we completed OK
   if nvl(RES.qtychecked,0) !=
           nvl(RES.qtypassed,0) + nvl(RES.qtyfailed,0) then
       out_errno := 105;
       out_errmsg := 'Did not complete inspection. Expected:'
             ||to_char(nvl(RES.qtychecked,0))
             ||' Inspected:'
             ||to_char(nvl(RES.qtypassed,0) + nvl(RES.qtyfailed,0));
       return;
   end if;

-- determine how to process close
   force := (substr(in_passfail,1,2) = 'F_');
   pass := (substr(in_passfail,-4) = 'PASS');


-- Get customer info
   CUST := null;
   OPEN C_CUST(RES.custid);
   FETCH C_CUST into CUST;
   CLOSE C_CUST;

-- Verfiy if we did all we did all
   if REQ.sampletype = 'PCT'
    and (100*nvl(RES.qtychecked,0)/nvl(RES.qtyreceived,1)) < REQ.samplesize
    and (not force
     or nvl(CUST.QAEnforceSamples,'N') = 'Y')
   then
       out_errno := 111;
       out_errmsg := 'Did not complete inspection percentage ('
             || to_char(nvl(REQ.samplesize,0))
             || '). Received:'
             ||to_char(nvl(RES.qtyreceived,0))
             ||' Inspected:'
             ||to_char(nvl(RES.qtychecked,0));
       return;

   end if;

   if REQ.sampletype = 'QTY' and nvl(RES.qtychecked,0) < REQ.samplesize
    and nvl(RES.qtychecked,0) < nvl(RES.qtyreceived,0)
    and (not force
     or nvl(CUST.QAEnforceSamples,'N') = 'Y')
   then
       out_errno := 111;
       out_errmsg := 'Did not complete inspection percentage ('
             || to_char(nvl(REQ.samplesize,0))
             || '). Received:'
             ||to_char(nvl(RES.qtyreceived,0))
             ||' Inspected:'
             ||to_char(nvl(RES.qtychecked,0));
       return;

   end if;

   if REQ.sampletype = 'ALL'
    and nvl(RES.qtychecked,0) < nvl(RES.qtyreceived,0)
    and (not force
     or nvl(CUST.QAEnforceSamples,'N') = 'Y')
   then
       out_errno := 111;
       out_errmsg := 'Did not complete inspection percentage ('
             || to_char(nvl(REQ.samplesize,0))
             || '). Received:'
             ||to_char(nvl(RES.qtyreceived,0))
             ||' Inspected:'
             ||to_char(nvl(RES.qtychecked,0));
       return;

   end if;


   if not force then
      if 100*(RES.qtypassed/RES.qtychecked) < REQ.passpercent then
         if pass then
            out_errno := 106;
            out_errmsg := 'Does not meet pass percentage of '
                       ||REQ.passpercent ||'%';
            return;
         end if;
      else
         if not pass then
            out_errno := 107;
            out_errmsg := 'Does not meet fail percentage of '
                       ||REQ.passpercent ||'%';
            return;
         end if;
      end if;
   end if;

   l_controlnumber := null;

-- Update the plates for this order to the proper status
   if not pass then
      l_invstatus := 'QC';
      l_new_qcresult_status := 'PA';
   else
      l_invstatus := 'AV';
      l_new_qcresult_status := 'FA';
   end if;

   invadj_tbl.delete;

   for crec in C_PLT(in_orderid, in_shipid, RES.item, RES.lotnumber) loop

       if REQ.lotnumber is null and crec.lotnumber is not null then
       -- check if there is a lotted inspection for this plate

          cnt := 0;
          select count(1)
            into cnt
           from qcresult R, qcrequest Q
           where Q.custid = REQ.custid
             and Q.item = REQ.item
             and Q.lotnumber = crec.lotnumber
             and R.id = Q.id
             and R.status in ('OP','IP')
             and R.item = Q.item
             and R.lotnumber = Q.lotnumber;

          if cnt > 0 then
             goto L_CONTINUE;
          end if;

       end if;

       zia.change_invstatus(crec.lpid, l_invstatus,
                'QA','QA',in_user,
                adj1, adj2,l_controlnumber, errno, errmsg, 'Y');

        if errno != 0 then
           out_errno := 108;
           out_errmsg := 'LP:'||crec.lpid||' Errno:'||errno||' / ' || errmsg;
           return;
        end if;

        ix := invadj_tbl.count + 1;
        invadj_tbl(ix).lpid := crec.lpid;
        invadj_tbl(ix).adj1 := adj1;
        invadj_tbl(ix).adj2 := adj2;


<<L_CONTINUE>>

        null;

   end loop;

   update qcresult
      set status = l_new_qcresult_status,
          controlnumber = l_controlnumber,
          inspectdate = sysdate,
          lastuser = in_user,
          lastupdate = sysdate
    where id = in_id
      and orderid = in_orderid
      and shipid = in_shipid
      and item = in_item
      and nvl(lotnumber,'(none)') = nvl(in_lot,'(none)');

-- If this is a NEXT or SPEC close the request so we do not start another
   if REQ.type in ('NEXT','SPEC') and REQ.status in ('OP','IP') then
      update qcrequest
         set status = 'CM'
       where id = REQ.id;
   end if;

   for ix in 1..invadj_tbl.count loop
      if adj1 is not null then
         errmsg := 'NOCOMMIT';
         zim6.check_for_adj_interface(invadj_tbl(ix).adj1, errno, errmsg);
         if errno != 0 then
            -- Log error message here
             zms.log_msg('QA', REQ.facility, REQ.custid,
               'Failed adjust interface status change. LP:'
               || invadj_tbl(ix).Lpid
               || ' to status ' ||
               l_invstatus,
               'E', in_user, logMsg);
         end if;
      end if;
      if adj2 is not null then
         errmsg := 'NOCOMMIT';
         zim6.check_for_adj_interface(invadj_tbl(ix).adj2, errno, errmsg);
         if errno != 0 then
            -- Log error message here
             zms.log_msg('QA', REQ.facility, REQ.custid,
               'Failed adjust interface status change. LP:'
               || invadj_tbl(ix).Lpid
               || ' to status ' ||
               l_invstatus,
               'E', in_user, logMsg);
         end if;
      end if;
   end loop;

   invadj_tbl.delete;

EXCEPTION when others then

  out_errno := sqlcode;

  out_errmsg := sqlerrm;

END complete_inspection;

PROCEDURE qa_cancel_request
(
    in_id       IN      number,
    in_userid   IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)

is

cursor curQcRequest is
  select status
    from qcrequest
   where id = in_id;
rq curQcRequest%rowtype;

begin

out_errno := 0;
out_errmsg := 'OKAY';

rq := null;
open curQcRequest;
fetch curQcRequest into rq;
close curQcRequest;

if rq.status is null then
  out_errno := -1;
  out_errmsg := 'Invalid QA Request ID: ' || in_id;
  return;
end if;

if rq.status <> 'OP' then
  out_errno := -1;
  out_errmsg := 'Request status must be ''OP''';
  return;
end if;

update qcrequest
   set status = 'CA'
 where id = in_id;

exception when others then
  out_errno := sqlcode;
  out_errmsg := sqlerrm;
end;

PROCEDURE inspect_lp
(
    in_lpid     IN      varchar2,
    in_result   IN      varchar2, -- 'PA'ss; 'FA'il
    in_userid   IN      varchar2,
    in_facility IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)

is

cursor curPlate is
  select *
    from plate
   where lpid = in_lpid;
PLT curPlate%rowtype;

cursor curQcResultDtl is
  select *
    from qcresultdtl
   where lpid = in_lpid;
QRD curQcResultDtl%rowtype;

cntErrs integer;
qa_id number;
qa_putaway_after_inspection_yn char(1);
newInvStatus varchar2(2);
adj1rowid rowid;
adj2rowid rowid;
errno integer;
errmsg varchar2(255);
strmsg varchar2(255);
l_controlnumber varchar2(10);
l_disposition qcresultdtl.disposition%type;
l_condition qcresultdtl.condition%type;
strFacility plate.facility%type;
strLocation plate.location%type;

begin

out_errno := 0;
out_errmsg := 'OKAY';

PLT := null;
open curPlate;
fetch curPlate into PLT;
close curPlate;

if PLT.lpid is null then
  out_errno := -1;
  out_errmsg := 'Lpid ' || in_lpid || ' not found';
  return;
end if;

if PLT.facility != in_facility then
  out_errno := -2;
  out_errmsg := 'LiP ' || in_lpid || ' not in your facility';
  return;
end if;

qa_id := 0;
begin
  select id, putaway_after_inspection_yn
    into qa_id, qa_putaway_after_inspection_yn
    from qcrequest
   where custid = PLT.custid
     and po = PLT.po
     and qa_by_po_item = 'Y';
exception when no_data_found then
  qa_id := 0;
end;

if qa_id = 0 then
  out_errno := -3;
  out_errmsg := 'Auto QA Request not found';
  return;
end if;

QRD := null;
open curQcResultDtl;
fetch curQcResultDtl into QRD;
close curQcResultDtl;

if QRD.id is null then
  out_errno := -4;
  out_errmsg := 'Auto QA Result not found';
  return;
end if;

if in_result not in ('PA','FA') then
  out_errno := -5;
  out_errmsg := 'Result must be ''PA'' or ''FA''';
  return;
end if;

if PLT.invstatus != 'IN' then
  out_errno := -6;
  out_errmsg := 'LiP not in ''IN'' status';
  return;
end if;

if in_result = 'PA' then
  newInvStatus := 'AV';
else
  newInvStatus := 'QC';
end if;

l_controlnumber := null;
cntErrs := 0;

if in_result = 'PA' then
   l_disposition := nvl(trim(substr(zci.default_value('QAPASSDISPOSITION'),1,4)),'OK');
   l_condition := nvl(trim(substr(zci.default_value('QAPASSCONDITION'),1,2)),'GD');
else
   l_disposition := nvl(trim(substr(zci.default_value('QAFAILDISPOSITION'),1,4)),'UN');
   l_condition := nvl(trim(substr(zci.default_value('QAFAILCONDITION'),1,2)),'BD');
end if;

for LIPS in (select lpid,invstatus,location
               from plate
              where custid = PLT.custid
                and item = QRD.item
                and po = PLT.po
                and type = 'PA'
                and invstatus in ('IN','QA'))
loop

   adj1rowid := null;
   adj2rowid := null;

   zia.change_invstatus(LIPS.lpid, newInvStatus,
             'QA','QA',in_userid,
             adj1rowid, adj2rowid, l_controlnumber, errno, errmsg, 'Y');

   if errno != 0 then
     cntErrs := cntErrs + 1;
     zms.log_autonomous_msg('InspectLP', PLT.facility, PLT.custid, errmsg,
                           'E', in_userid, strmsg);
   end if;

   if adj1rowid is not null then
     zim6.check_for_adj_interface(adj1rowid, errno, errmsg);
     if errno != 0 then
       zms.log_autonomous_msg('InspectLP', PLT.facility, PLT.custid, errmsg,
                           'E', in_userid, strmsg);
     end if;
   end if;

   if adj2rowid is not null then
     zim6.check_for_adj_interface(adj2rowid, errno, errmsg);
     if errno != 0 then
       zms.log_autonomous_msg('InspectLP', PLT.facility, PLT.custid, errmsg,
                           'E', in_userid, strmsg);
     end if;
   end if;

   if LIPS.invstatus = 'IN' and
      qa_putaway_after_inspection_yn = 'Y' then
			zput.putaway_lp('TANR', LIPS.lpid, in_facility, LIPS.location, 'INSPECT', 'Y',
               null, errmsg, strFacility, strLocation);
			if errmsg is not null then
       zms.log_autonomous_msg('InspectLP', PLT.facility, PLT.custid, errmsg,
                           'E', in_userid, strmsg);
			end if;
   end if;

   if LIPS.invstatus = 'IN' then
      if in_result = 'PA' then
         update qcresultdtl
            set qtypassed = nvl(qtypassed,0) + PLT.quantity,
                qtychecked = nvl(qtychecked,0) + PLT.quantity,
                inspectdate = sysdate,
                inspector = in_userid,
                disposition = l_disposition,
                condition = l_condition
            where id = QRD.id
              and orderid = QRD.orderid
              and shipid = QRD.shipid
              and lpid = LIPS.lpid;
      else
         update qcresultdtl
            set qtyfailed = nvl(qtyfailed,0) + PLT.quantity,
                qtychecked = nvl(qtychecked,0) + PLT.quantity,
                inspectdate = sysdate,
                inspector = in_userid,
                disposition = l_disposition,
                condition = l_condition
            where id = QRD.id
              and orderid = QRD.orderid
              and shipid = QRD.shipid
              and lpid = LIPS.lpid;
      end if;
   end if;
end loop;


update qcresult
  set status = in_result,
      controlnumber = l_controlnumber,
      inspectdate = sysdate,
      lastuser = in_userid,
      lastupdate = sysdate
where id = QRD.id
  and custid = PLT.custid
  and po = PLT.po
  and item = QRD.item;

exception when others then
  out_errno := sqlcode;
  out_errmsg := sqlerrm;
end inspect_lp;


procedure delete_in_plate
(
    in_lpid      in      varchar2,
    out_errmsg   out     varchar2)
is
   cursor c_qc(in_orderid number, in_shipid number, in_item varchar2, in_lot varchar2) is
   select r.id, q.item
      from qcresult r, qcrequest q
      where r.id = q.id
        and r.orderid = in_orderid
        and r.shipid = in_shipid
        and r.item = in_item
        and nvl(r.lotnumber, nvl(in_lot,'(none)')) = nvl(in_lot,'(none)')
   order by r.lotnumber;
   qc c_qc%rowtype := null;
   req qcrequest%rowtype := null;
   res qcresult%rowtype := null;
   plt plate%rowtype := null;
   plt_lot plate.lotnumber%type;
begin
   out_errmsg := 'OKAY';

   open c_plate(in_lpid);
   fetch c_plate into plt;
   close c_plate;
   if plt.lpid is null then
      return;
   end if;

   if plt.invstatus != 'IN' then
      return;
   end if;

-- check if have an existing open qa inspection for this order/ item/ lot
   open c_qc(plt.orderid, plt.shipid, plt.item, plt.lotnumber);
   fetch c_qc into qc;
   close c_qc;

   if qc.id is not null then
      open c_qcrequest(qc.id);
      fetch c_qcrequest into req;
      close c_qcrequest;

   -- If the request did not specify lots do no track lots
      if req.lotnumber is null then
         plt_lot := null;
      else
         plt_lot := plt.lotnumber;
      end if;

      open c_qcresult(qc.id, plt.orderid, plt.shipid, plt.item, plt_lot);
      fetch c_qcresult into res;
      close c_qcresult;
   else
      return;
   end if;

   delete qcresultdtl
      where id = req.id
        and orderid = plt.orderid
        and shipid = plt.shipid
        and lpid = plt.lpid;

   if (sql%rowcount != 0) then
      update qcresult
         set qtyreceived = nvl(qtyreceived,0) - plt.quantity,
             qtychecked = nvl(qtychecked,0) - plt.quantity
         where id = res.id
           and orderid = res.orderid
           and shipid = res.shipid
           and item = res.item
           and nvl(lotnumber,'(none)') = nvl(res.lotnumber,'(none)');
   end if;

exception
   when OTHERS then
      out_errmsg := sqlerrm;

end delete_in_plate;

PROCEDURE set_virtual_status
(
    in_lpid     IN      varchar2,
    in_invstatus IN     varchar2,
    in_po       IN      varchar2,
    in_userid   IN      varchar2,
    out_errno   OUT     number,
    out_errmsg  OUT     varchar2
)
IS

l_adj1         varchar2(20);
l_adj2         varchar2(20);
l_controlnumber varchar2(10);

errno integer;
errmsg varchar2(255);
logMsg varchar2(255);

begin
    out_errno := 0;
    out_errmsg := '';

    for clp in (select lpid, facility, custid from plate
                 start with lpid = in_lpid
                 connect by prior lpid = parentlpid)
    loop
        update plate
          set po = nvl(po, in_po)
         where lpid = clp.lpid;


        zia.change_invstatus(clp.lpid, in_invstatus,
             'QA','QA',in_userid,
             l_adj1, l_adj2, l_controlnumber, errno, errmsg, 'Y');


      if l_adj1 is not null then
         zim6.check_for_adj_interface(l_adj1, errno, errmsg);
         if errno != 0 then
            -- Log error message here
             zms.log_msg('QA', clp.facility, clp.custid,
               'Failed adjust interface status change. LP:'
               || clp.Lpid
               || ' to status ' ||
               in_invstatus,
               'E', in_userid, logMsg);
         end if;
      end if;
      if l_adj2 is not null then
         zim6.check_for_adj_interface(l_adj2, errno, errmsg);
         if errno != 0 then
            -- Log error message here
             zms.log_msg('QA', clp.facility, clp.custid,
               'Failed adjust interface status change. LP:'
               || clp.Lpid
               || ' to status ' ||
               in_invstatus,
               'E', in_userid, logMsg);
         end if;
      end if;


    end loop;

end set_virtual_status;

end zqainspection;
/
show error package body zqainspection;
exit;
