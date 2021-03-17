create or replace package body zpecas as
--
-- $Id$
--

----------------------------------------------------------------------
CURSOR C_TRANS(in_trans number)
IS
SELECT *
  FROM xchngin
 WHERE transmission = in_trans;
----------------------------------------------------------------------
CURSOR C_PLT(in_plt varchar2)
IS
SELECT *
  FROM alps.plate
 WHERE lpid = in_plt;
----------------------------------------------------------------------
CURSOR C_ORD(in_orderid number, in_shipid number)
IS
SELECT *
  FROM alps.orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;
----------------------------------------------------------------------




----------------------------------------------------------------------
--
-- Trace - write an entry to the trace file if it is opened
--
----------------------------------------------------------------------
PROCEDURE Trace
(
    in_src      varchar2,
    in_msg      varchar2
)
IS
ds varchar2(20);
fn varchar2(200);           -- File Name
FP utl_file.file_type;
BEGIN

    zlog.add(in_src, in_msg);

    return;

    fn := 'pecas_'||to_char(sysdate,'MMDD')||'.log';
    FP := utl_file.fopen('c:\Synapse\log', fn,'a');

    ds := to_char(sysdate, 'MM/DD/YY HH24:MI:SS');
    utl_file.put_line(FP,ds||' '||in_src||': '||substr(in_msg,1,150)); 
    utl_file.fclose(FP);

EXCEPTION WHEN OTHERS THEN
    -- sa_log.add('000','MP Trace',substr(sqlerrm,1,200));
    null;
END Trace;

----------------------------------------------------------------------
--
-- plant - convert from facility to plant
--
----------------------------------------------------------------------
FUNCTION plant
(
    in_facility varchar2
)
RETURN  varchar2
IS
BEGIN
    if in_facility = '001' then
        return '1001';
    elsif in_facility = '002' then
        return '1002';
    end if;
    return null;

END plant;

----------------------------------------------------------------------
--
-- facility - convert from plant to facility
--
----------------------------------------------------------------------
FUNCTION facility
(
    in_plant varchar2
)
RETURN  varchar2
IS
BEGIN
    if in_plant = '1001' then
        return '001';
    elsif in_plant = '1002' then
        return '002';
    end if;
    return null;

END facility;



PROCEDURE Custom
(
    in_data IN OUT alps.cdata
)
IS
BEGIN
    Trace('Custom',in_data.item);

END;



----------------------------------------------------------------------
--
-- app_msg - log an error message to application log
--
----------------------------------------------------------------------
PROCEDURE app_msg
(
    in_facility varchar2,
    in_custid   varchar2,
    in_text     varchar2,
    in_type     varchar2
)
IS
errmsg varchar2(255);
BEGIN
    zms.log_msg('Pecas IF',in_facility,in_custid,in_text, in_type,
        'PECAS',errmsg);

END app_msg;


----------------------------------------------------------------------
--
-- add_XO - insert a xchngOut record 
--
----------------------------------------------------------------------
FUNCTION add_XO
(
    in_type varchar2,
    in_tran number := NULL
)
RETURN number
IS
 l_tran number;

CURSOR C_NS
IS
SELECT  transseq.nextval
  FROM dual;
 

BEGIN
    if in_tran is null then
        l_tran := null;
        OPEN C_NS;
        FETCH C_NS into l_tran;
        CLOSE C_NS;
        if l_tran is null then
            return 0;
        end if;
    else
        l_tran := in_tran;
    end if;
    insert into xchngOut(type, transmission, create_date, processed)
    values (in_type, l_tran, sysdate, 'N');


    return l_tran;
EXCEPTION WHEN OTHERS THEN
    app_msg('', '', substr('Failed Insert of xchngOut:'||sqlerrm,1,250),
        'E');
    return 0;
END add_XO;


----------------------------------------------------------------------
--
-- processed_xchngin
--
----------------------------------------------------------------------
PROCEDURE processed_xchngin
(
    in_tran     number
)
IS
l_type  varchar2(2);
TRN xchngin%rowtype;
BEGIN

    TRN := null;
    OPEN C_TRANS(in_tran);
    FETCH C_TRANS into TRN;
    CLOSE C_TRANS;

    if TRN.transmission is null then
        return;
    end if;

    UPDATE xchngin
       SET processed = 'Y',
           processed_date = sysdate
     WHERE transmission = in_tran;

    if TRN.type = 'ES' then
        UPDATE xchngExShipHdr
           SET processed = 'Y',
               processed_date = sysdate
         WHERE transmission = in_tran;
        UPDATE xchngExShipNotes
           SET processed = 'Y',
               processed_date = sysdate
         WHERE transmission = in_tran;
        UPDATE xchngExShipDetail
           SET processed = 'Y',
               processed_date = sysdate
         WHERE transmission = in_tran;
    elsif TRN.type = 'ER' then
        UPDATE xchngExRcpt
           SET processed = 'Y',
               processed_date = sysdate
         WHERE transmission = in_tran;
    else
        trace('PX','Unknown trans type:'||TRN.type);
        
    end if;
END processed_xchngin;

----------------------------------------------------------------------
--
-- update_customer
--
----------------------------------------------------------------------
PROCEDURE update_customer
(
    in_custid   varchar2
)
IS
CURSOR C_CUST(in_cust varchar2)
IS
SELECT *
  FROM alps.customer
 WHERE custid = in_cust;

CUS alps.customer%rowtype;

CURSOR C_XCUS(in_cust varchar2, in_type varchar2)
IS
SELECT *
  FROM xchngcustomer
 WHERE customer = upper(in_cust)
   AND address_type = in_type;

XCUS xchngcustomer%rowtype;

errmsg varchar2(255);

BEGIN
    CUS := null;
    OPEN C_CUST(in_custid);
    FETCH C_CUST into CUS;
    CLOSE C_CUST;

    if CUS.custid is null then
        zcl.clone_customer('DEFAULT',in_custid,'PECAS',errmsg);
        update alps.customer
           set status = 'ACTV'
         where custid = in_custid;
    end if;


    XCUS := null;
    OPEN  C_XCUS(in_custid, BaseAddType);
    FETCH C_XCUS into XCUS;
    CLOSE C_XCUS;

    update alps.customer
       set name = XCUS.name,
           lookup = upper(XCUS.name),
           contact = XCUS.contactname,
           addr1 = XCUS.addr1,
           addr2 = XCUS.addr2,
           city = XCUS.city,
           state = XCUS.state,
           postalcode = XCUS.postalcode,
           countrycode = XCUS.countrycode,
           phone = XCUS.phone,
           fax = XCUS.fax,
           lastuser = 'PECAS',
           lastupdate = sysdate
     where custid = in_custid;

    update xchngcustomer
       set processed = 'Y',
           processed_date = sysdate
     where customer = upper(in_custid)
       and address_type = BaseAddType;

EXCEPTION WHEN OTHERS THEN
    app_msg('',in_custid,'UC:'||sqlerrm,'E');
END update_customer;

----------------------------------------------------------------------
--
-- update_custitem
--
----------------------------------------------------------------------
PROCEDURE update_custitem
(
    in_custid   varchar2,
    in_item     varchar2,
    in_descr    varchar2
)
IS
CURSOR C_ITM(in_cust varchar2, in_item varchar2)
IS
SELECT *
  FROM alps.custitem
 WHERE custid = in_cust
   AND item = in_item;

ITM alps.custitem%rowtype;

errmsg varchar2(255);

BEGIN
    ITM := null;
    OPEN C_ITM(in_custid, in_item);
    FETCH C_ITM into ITM;
    CLOSE C_ITM;

    if ITM.item is null then
        zcl.clone_custitem('DEFAULT','DEFAULT',
                in_custid,in_item,'PECAS',errmsg);
        update alps.custitem
           set status = 'ACTV'
         where custid = in_custid
           and item = in_item;
    end if;

    update alps.custitem
       set descr = in_descr,
           lastuser = 'PECAS',
           lastupdate = sysdate
     where custid = in_custid
       and item = in_item;


EXCEPTION WHEN OTHERS THEN
    app_msg('',in_custid,'UCI:'||sqlerrm,'E');
END update_custitem;



----------------------------------------------------------------------
--
-- update_custitem_uom
--
----------------------------------------------------------------------
PROCEDURE update_custitem_uom
(
    in_custid   varchar2,
    in_jobno    varchar2,
    in_item     varchar2,
    in_crtn     number,
    in_plt      number,
    in_overage  number,
    in_userid   varchar2
)
IS
CURSOR C_ITM(in_cust varchar2, in_item varchar2)
IS
SELECT *
  FROM alps.custitem
 WHERE custid = in_cust
   AND item = in_item;

ITM alps.custitem%rowtype;

errmsg varchar2(255);

BEGIN
    ITM := null;
    OPEN C_ITM(in_custid, in_item);
    FETCH C_ITM into ITM;
    CLOSE C_ITM;

    if ITM.item is null then
        return;
    end if;


    delete from alps.custitemuom
     where custid = in_custid
       and item = in_item;

    insert into alps.custitemuom(custid,item,sequence,qty,
        fromuom,touom,picktotype,velocity,lastuser,lastupdate)
    values(in_custid,in_item,10, in_crtn,
        BaseUOM_,CtnUOM_,'FULL','A',in_userid,sysdate);

    insert into alps.custitemuom(custid,item,sequence,qty,
        fromuom,touom,picktotype,velocity,lastuser,lastupdate)
    values(in_custid,in_item,20, in_plt,
        CtnUOM_,PltUOM_,'FULL','A',in_userid,sysdate);

    update alps.orderdtl
       set dtlpassthrunum10 = nvl(in_overage,0)
     where (orderid, shipid) =
        (select orderid, shipid
           from alps.orderhdr
          where custid = in_custid
            and reference = in_jobno
            and ordertype = 'P'
            and orderstatus not in ('X','R'))
       and item = in_item;


EXCEPTION WHEN OTHERS THEN
    app_msg('',in_custid,'UCIU:'||sqlerrm,'E');
END update_custitem_uom;



----------------------------------------------------------------------
--
-- process_exp_receipt
--
----------------------------------------------------------------------
PROCEDURE process_exp_receipt(
    TRN xchngin%rowtype
)
IS
CURSOR C_ER(in_transmission number)
IS
SELECT transmission, status, upper(customer), plant, jobno, upper(item),
       expected_qty, descr, pcs_per_carton, ctn_per_pallet, create_date,
       processed, processed_date
  FROM xchngExRcpt
 WHERE transmission = in_transmission;

ER xchngExRcpt%rowtype;


cursor C_OrderHdr(in_custid varchar2, in_ref varchar2) 
IS
  SELECT orderid,
         shipid,
         orderstatus,
         nvl(fromfacility,tofacility) facility,
         ordertype
    FROM alps.orderhdr
   WHERE custid = rtrim(in_custid)
     AND reference = rtrim(in_ref)
   ORDER by orderstatus;
OH C_OrderHdr%rowtype;

l_orderid alps.orderhdr.orderid%type;
l_shipid alps.orderhdr.shipid%type;
l_errno number;
l_msg varchar2(255);
l_func varchar2(1);


BEGIN
    -- Read Expected Receipt Record

    ER := null;
    OPEN C_ER(TRN.transmission);
    FETCH C_ER into ER;
    CLOSE C_ER;

    if ER.transmission is null then
        -- processed_xchngin(TRN.transmission);
        app_msg('','',
            'ER Transmission:'||TRN.transmission||' no exp receipt found',
            'E');
        return;
    end if;

    if ER.processed = 'Y' then
        trace('ExRcpt','Already processed '||ER.transmission);
    end if;


    --  If active
    --      update customer
    --      update item
    --      if production order exists
    --          update production order
    --      else
    --          add production order
    --  If canceled
    --      cancel production order
    --  if completed
    --      complete production order
    

    if ER.status = 'A' then
        trace('ExRcpt','Have an active order:');
        update_customer(ER.customer);
        update_custitem(ER.customer, ER.item, ER.descr);
        if ER.pcs_per_carton is not null then
            update_custitem_uom(ER.customer, ER.item, ER.jobno,
                ER.pcs_per_carton, ER.ctn_per_pallet, 0, 'PECAS');
        end if;


        -- Add order or update it
        l_func := 'U';
        zimppecas.pecas_import_order_header(
            l_func,ER.customer,'P',null, null, null, null, 
            null, facility(ER.plant), null, null, null,
            null,null,null, null, ER.jobno,
            null, 
            null,null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,
            null, null, null,
            null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,'PECAS', -- PTC01
            null,null,ER.plant,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,
            l_orderid, l_shipid, l_errno, l_msg
        );

        -- Add Order Line or Update It
        l_func := 'R';
        zimppecas.pecas_import_order_line(
            l_func,ER.customer,ER.jobno,ER.item,null,BaseUOM_,
            ER.expected_qty,null,null,null,
            null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,
            l_orderid, l_shipid, l_errno, l_msg
        );
    elsif ER.status = 'X' then
        if ER.item is null then
            trace('ExRcpt','Have a cancelled order:');
            l_func := 'D';
            zimppecas.pecas_import_order_header(
                l_func,ER.customer,'P',null, null, null, null, 
                null, facility(ER.plant), null, null, null,
                null,null,null, null, ER.jobno,
                null, 
                null,null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,
                null, null, null,
                null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null, -- PTC01
                null,null,ER.plant,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,
                l_orderid, l_shipid, l_errno, l_msg
            );
            if l_errno <> 0 then
                trace('ExRcpt','Error:'||l_msg);
            end if;
        else
            trace('ExRcpt','Have a cancelled item:');
            l_func := 'D';
            zimppecas.pecas_import_order_line(
                l_func,ER.customer,ER.jobno,ER.item,null,BaseUOM_,
                ER.expected_qty,null,null,null,
                null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,
                l_orderid, l_shipid, l_errno, l_msg
            );
        end if;
    elsif ER.status = 'C' then
        trace('ExRcpt','Have a completed order:');
        OH := null;
        OPEN C_Orderhdr(ER.customer, ER.jobno);
        FETCH C_Orderhdr into OH;
        CLOSE C_Orderhdr;

        zprod.complete_production_order(OH.orderid, OH.shipid, l_msg);
        if l_msg <> 'OKAY' then
            trace('ExRcpt','Error:'||l_msg);
        end if;

    else
        trace('ExRcpt','Have unknown status:'||ER.status);
    end if;


    -- Update the processed status for the transmission
    -- processed_xchngin(TRN.transmission);

EXCEPTION WHEN OTHERS THEN
    app_msg(facility(ER.plant),ER.customer,'ER Failed:'||sqlerrm,'E');
END process_exp_receipt;


----------------------------------------------------------------------
--
-- process_exp_shipment
--
----------------------------------------------------------------------
PROCEDURE process_exp_shipment(
    TRN xchngin%rowtype
)
IS

CURSOR C_ES(in_transmission number)
IS
--SELECT transmission, id, status, upper(customer), plant, sales_order_no,
--       pecas_ref, po, shiptoname, shiptoaddr1, shiptoaddr2, 
--       shiptocity, shiptostate, shiptopostalcode, shiptocountrycode,
--       ship_date, delivery_date, ship_terms, ship_type, carrier,
--       passthru06, passthru07, passthru08, passthru09,
--       create_date, processed, processed_date 
SELECT *
  FROM xchngExShipHdr
 WHERE transmission = in_transmission;

ES xchngExShipHdr%rowtype;

l_note long;
crlf char(2) := chr(13)||chr(10);

l_orderid alps.orderhdr.orderid%type;
l_shipid alps.orderhdr.shipid%type;
l_warnno number;
l_errno number;
l_msg varchar2(255);
l_func varchar2(1);

BEGIN

    ES := null;
    OPEN C_ES(TRN.transmission);
    FETCH C_ES into ES;
    CLOSE C_ES;

    ES.customer := upper(ES.customer);

    if ES.transmission is null then
        -- processed_xchngin(TRN.transmission);
        app_msg('','',
            'ES Transmission:'||TRN.transmission||' no shiphdr found',
            'E');
        return;
    end if;

    if ES.status = 'A' then
        trace('ExShip','Have an active order:');
        update_customer(ES.customer);
        -- Add order or update it
        l_func := 'R';
        zimppecas.pecas_import_order_header(
            l_func,ES.customer,'O',null, ES.ship_date, ES.po, null, 
            facility(ES.plant), null, null, null, 'N',
            null,null,ES.ship_type, ES.carrier,ES.sales_order_no,
            ES.ship_terms, 
            null,null,null,null,null,null,null,null,null,null,null,
            ES.shiptoname,ES.shiptocontact,ES.shiptoaddr1,ES.shiptoaddr2,
            ES.shiptocity, ES.shiptostate, ES.shiptopostalcode,
            ES.shiptocountrycode,null,null,null,
            null,null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,
 -- PTC01
            ES.pecas_ref,null,null,null,null,
                ES.passthru06,ES.passthru07,ES.passthru08,ES.passthru09,
                'PECAS',
            ES.passthru11,ES.passthru12,ES.plant,null,null,
                null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,ES.delivery_date,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,
            l_orderid, l_shipid, l_errno, l_msg
        );

        -- If fails send response to Pecas
        if l_errno <> 0 then
            trace('ShipEx','Error:'||l_msg);
            l_errno := add_XO('SR',TRN.transmission);
            return;
        end if;
        -- Build then add instructions
        l_note := '';
        for crec in (select * from xchngexshipnotes 
                      where transmission = ES.transmission)
        loop
            trace('ExShip','Note:'||crec.qualifier||'-'||crec.note);
            l_note := l_note ||crec.qualifier||'-'||crec.note||crlf;

        end loop;
        trace('ExShip',l_note);

        zimppecas.pecas_import_order_header_inst(
            l_func,
            ES.customer, ES.sales_order_no, l_note, ES.pecas_ref,
            l_orderid, l_shipid, l_errno, l_msg
        );

        if l_errno <> 0 then
            trace('ShipEx','Instr Error:'||l_msg);
        end if;
        -- Add order details
        for crec in (select transmission, id, upper(item) item, qty,
                            customer_item,
                            create_date, processed, processed_date 
                      from xchngexshipdetail
                      where transmission = TRN.transmission)
        loop
          zimppecas.pecas_import_order_line(
            l_func,ES.customer,ES.sales_order_no,crec.item,null,BaseUOM_,
            crec.qty,null,null,null,
            null,null,null,null,crec.customer_item,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,null,null,null,
            null,null,null,null,null,null,null,ES.pecas_ref,'N',
            l_orderid, l_shipid, l_errno, l_msg
          );

          if l_errno <> 0 then
            trace('ShipEx','Line Error:'||l_msg);
          end if;
        end loop;
    elsif ES.status = 'X' then
        trace('ExShip','Have a cancelled order:');
            l_func := 'D';
            zimppecas.pecas_import_order_header(
                l_func,ES.customer,'P',null, null, null, null, 
                null, facility(ES.plant), null, null, null,
                null,null,null, null, ES.sales_order_no,
                null, 
                null,null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,
                null, null, null,
                null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null, -- PTC01
                null,null,ES.plant,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,
                null,null,null,null,null,null,null,null,
                l_orderid, l_shipid, l_errno, l_msg
            );
            if l_errno <> 0 then
                trace('ExShip','Error:'||l_msg);
            end if;
    else
        trace('ExShip','Have unknown status:'||ES.status);
    end if;


    -- Automatic release from hold if not '3RD' party ship terms
    -- which is mapped from '2' to '3RD' in zimppecasbody
    if ES.ship_terms != '2' then
        zoe.remove_order_from_hold(
            l_orderid,
            l_shipid,
            facility(ES.plant),
            'IMPPECAS',
            l_warnno,
            l_errno,
            l_msg
        );
    end if;

    -- Update the processed status for the transmission
    -- processed_xchngin(TRN.transmission);

EXCEPTION WHEN OTHERS THEN
    app_msg(facility(ES.plant),ES.customer,'ES Failed:'||sqlerrm,'E');
END process_exp_shipment;


----------------------------------------------------------------------
--
-- inv_adj - create inventory adjustment record
--
----------------------------------------------------------------------
PROCEDURE inv_adj
(
    in_data IN OUT alps.cdata
)
IS

PLT alps.plate%rowtype;
ORD alps.orderhdr%rowtype;

l_plant xchngInvAdj.plant%type;
l_tran number;

BEGIN
    Trace('INV_ADJ',in_data.item);

    PLT := null;
    OPEN C_PLT(in_data.lpid);
    FETCH C_PLT into PLT;
    CLOSE C_PLT;

    if PLT.lpid is null then
        trace('INV_ADJ', ' Plate not found:'||in_data.lpid);
        return;
    end if;    

    ORD := null;
    OPEN C_ORD(PLT.orderid, PLT.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if nvl(ORD.ordertype,'X') != 'P' then
        return;
    end if;


    l_plant := plant(PLT.facility);

    l_tran := add_XO('IA');

    if l_tran = 0 then
        app_msg(PLT.facility, PLT.custid, 
            'Failed insert of IA for:'||in_data.lpid||'/'
                ||in_data.quantity,'E');
        return;
    end if;

    INSERT into xchngInvAdj(transmission, plant, customer, jobno,
            item, qty_changed, adj_date, reason, 
            create_date, processed)
     VALUES (l_tran, l_plant,
            PLT.custid, PLT.useritem1,
            PLT.item, in_data.quantity, PLT.lastupdate, in_data.reason, 
            sysdate, 'N');

    in_data.out_no := 0;

EXCEPTION WHEN OTHERS THEN
    trace('INV_ADJ',sqlerrm);

END inv_adj;

----------------------------------------------------------------------
--
-- prod_receipt - create actual receipt 
--
----------------------------------------------------------------------
PROCEDURE prod_receipt
(
    in_data IN OUT alps.cdata
)
IS
PLT alps.plate%rowtype;
l_plant xchngInvAdj.plant%type;
l_tran number;



BEGIN
    Trace('PROD_RECEIPT',in_data.item);

    PLT := null;
    OPEN C_PLT(in_data.lpid);
    FETCH C_PLT into PLT;
    CLOSE C_PLT;

    if PLT.lpid is null then
        trace('PROD_RECEIPT', ' Plate not found:'||in_data.lpid);
        return;
    end if;    


    l_plant := plant(PLT.facility);

    l_tran := add_XO('AR');

    if l_tran = 0 then
        app_msg(PLT.facility, PLT.custid, 
            'Failed insert of AR for:'||in_data.lpid||'/'
                ||in_data.item,'E');
        return;
    end if;

    INSERT into xchngActRcpt(transmission, plant, customer, jobno,
            item, qty_received, receipt_date, 
            create_date, processed)
     VALUES (l_tran, l_plant,
            PLT.custid, in_data.char01, -- substr(PLT.item,1,6)||'/001',
            PLT.item, PLT.quantity, PLT.creationdate,
            sysdate, 'N');
EXCEPTION WHEN OTHERS THEN
    trace('Prod_Receipt',sqlerrm);

END prod_receipt;


----------------------------------------------------------------------
--
-- ship_order - create actual shipment record
--
----------------------------------------------------------------------
PROCEDURE ship_order
(
    in_data IN OUT alps.cdata
)
IS
ORD alps.orderhdr%rowtype;
l_plant xchngInvAdj.plant%type;
l_tran number;

BEGIN
    Trace('ship_order','Order:'||in_data.orderid||'/'||in_data.shipid);

    ORD := null;
    OPEN C_ORD(in_data.orderid, in_data.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        trace('SHIP_ORDER', 'ORder not found:'||in_data.orderid
            ||'/'||in_data.shipid);
        return;
    end if;    

    if nvl(ORD.hdrpassthruchar10,'XXX') != 'PECAS' then
        return;
    end if;

    l_plant := plant(ORD.fromfacility);

    l_tran := add_XO('AS');

    if l_tran = 0 then
        app_msg(ORD.fromfacility, ORD.custid, 
            'Failed insert of AS for:'||in_data.orderid||'/'
                ||in_data.shipid,'E');
        return;
    end if;

    for crec in (select * from alps.orderdtl 
                  where orderid = ORD.orderid
                    and shipid = ORD.shipid)
    loop
        INSERT into xchngActShip(transmission, plant, pecas_ref, customer,
            item, qty_shipped, ship_date, BOL, weight, ship_type, 
            create_date, processed)
        VALUES (l_tran, l_plant,
            ORD.hdrpassthruchar01, ORD.custid, crec.item,
            crec.qtyship, ORD.dateshipped, 
            nvl(ORD.billoflading,ORD.orderid||'-'||ORD.shipid), 
            crec.weightship,
            ORD.shiptype,
            sysdate, 'N');
    end loop;
EXCEPTION WHEN OTHERS THEN
    trace('ship_order',sqlerrm);

END ship_order;


----------------------------------------------------------------------
--
-- check_lpid - check if a lpid is to be used for production
--
----------------------------------------------------------------------
PROCEDURE check_lpid
(
    in_data IN OUT alps.cdata
)
IS

CURSOR C_CNT(in_lpid varchar2)
IS
SELECT COUNT(1)
  FROM load_flag_hdr
 WHERE lpid = in_lpid;

CURSOR C_CNT_CTN(in_lpid varchar2)
IS
SELECT COUNT(1)
  FROM load_flag_ctn
 WHERE cartonid = in_lpid;

cnt integer;

BEGIN

    --trace('CL','Have message with:'||in_data.lpid);
    --in_data.out_no := 1234;
    --in_data.out_char := 'This is a response to the stuff';

    in_data.out_no := 0;
    in_data.out_char := 'OKAY';
    cnt := 0;

    OPEN C_CNT(in_data.lpid);
    FETCH C_CNT into cnt;
    CLOSE C_CNT;

    if cnt > 0 then
        in_data.out_no := cnt;
        in_data.out_char := 'Duplicate LPID';
    end if;

    cnt := 0;

    OPEN C_CNT_CTN(in_data.lpid);
    FETCH C_CNT_CTN into cnt;
    CLOSE C_CNT_CTN;

    if cnt > 0 then
        in_data.out_no := cnt;
        in_data.out_char := 'Duplicate LPID';
    end if;



EXCEPTION WHEN OTHERS THEN
    trace('check_lpid',sqlerrm);
END check_lpid;


----------------------------------------------------------------------
--
-- process_input - process the input notify queue
--
----------------------------------------------------------------------
PROCEDURE process_input
IS
errno integer;
msg_in varchar2(200);
trans xchngin.transmission%type;
TRN xchngin%rowtype;

cleanup_date    number := 20040901; --null;
curr_date    number;

BEGIN
    loop
        errno := zqm.receive('pecas_in',msg_in,100);



        if errno = -1 then
            -- trace('ProcIn','TimeOut');
        -- Check if we need to cleanup the log. Do it every day.
            curr_date := to_char(sysdate,'YYYYMMDD');
            if cleanup_date is null then
                cleanup_date := curr_date;
            end if;

            if cleanup_date < curr_date then
                cleanup_date := null;
        -- Leave at least 2 days worth of log
                zlog.cleanup(sysdate - 2);
                zps.cleanup(sysdate - 2);
                commit;
            end if;
            goto continue;
        end if;

        trace('msg_in:',msg_in);
        if upper(msg_in) = 'STOP' then
            commit;
            exit;
        else
            trace('message',msg_in);
            begin
                trans := to_number(msg_in);
            exception when others then
                trans := 0;
            end;
            if trans > 0 then
                TRN := null;
                OPEN C_TRANS(trans);
                FETCH C_TRANS into TRN;
                CLOSE C_TRANS;
                if TRN.type = 'ER' then
                    trace('PI','Expected Receipt');
                    process_exp_receipt(TRN);
                elsif TRN.type = 'ES' then
                    trace('PI','Expected Shipment');
                    process_exp_shipment(TRN);
                end if;
                processed_xchngin(TRN.transmission);

            end if;
        end if;

        commit;

<<continue>>
        null;
    end loop;
EXCEPTION 
    WHEN OTHERS THEN
        trace('process_input',substr(sqlerrm,1,100));
END process_input;


----------------------------------------------------------------------
--
-- startup_process
--
----------------------------------------------------------------------
PROCEDURE startup_process
IS

job_name varchar2(200) := 'ZJOB.RUN_PECAS;';
CURSOR C_JOB
IS
SELECT *
  FROM user_jobs
 WHERE what = job_name;

JB user_jobs%rowtype;

iJob integer;

BEGIN
    iJob := 0;

    JB := null;

    OPEN C_JOB;
    FETCH C_JOB into JB;
    CLOSE C_JOB;

    if JB.job is null then
        dbms_job.submit(iJob,job_name,trunc(sysdate+1),'sysdate+1/72000');
    else
        iJob := JB.job;
    end if;

    dbms_job.broken(iJob,false);
    dbms_job.next_date(iJob,sysdate);

    commit;

END startup_process;

END zpecas;
/
exit;
