create or replace package body ztms_transynd
AS
--
-- $Id$
--

----------------------------------------------------------------------
--
-- check_wave_format
--
----------------------------------------------------------------------
PROCEDURE check_wave_format
(
    in_wave     IN      integer,
    in_format   IN      varchar2,
    in_status   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_WAVE
IS
SELECT tms_status
  FROM waves
 WHERE wave = in_wave;

WV C_WAVE%rowtype;

CURSOR C_FMT
IS
SELECT COUNT(1)
  FROM customer C, orderhdr O
 WHERE O.wave = in_wave
  and  C.custid = O.custid
  and (NVL(tms_status,'X') != in_status
   or NVL(C.tms_orders_to_plan_format,'$$NONE$$')
      != in_format);

CURSOR C_NOFMT
IS
SELECT COUNT(1)
  FROM orderhdr
 WHERE wave = in_wave
  and NVL(tms_status,'X') != 'X';

cnt integer;

BEGIN
    out_errmsg := 'OKAY';


    WV := null;
    OPEN C_WAVE;
    FETCH C_WAVE into WV;
    CLOSE C_WAVE;


    cnt := 0;
    if in_format = '$$NONE$$' then
        if WV.tms_status != 'X' then
            out_errmsg := 'The receiving wave is set for TMS';
            return;
        end if;
        OPEN C_NOFMT;
        FETCH C_NOFMT into cnt;
        CLOSE C_NOFMT;
    else
        if WV.tms_status = 'X' then
            out_errmsg := 'The receiving wave is not set for TMS';
            return;
        end if;
        OPEN C_FMT;
        FETCH C_FMT into cnt;
        CLOSE C_FMT;
    end if;


    if nvl(cnt,0) > 0 then
        out_errmsg := 'The receiving wave is not valid TMS for format:'''
            ||in_format||'''';
    end if;


END check_wave_format;

----------------------------------------------------------------------
--
-- send_wave - send a waves orders to TMS
--
----------------------------------------------------------------------
PROCEDURE send_wave
(
    in_wave     IN      integer,
    in_format   IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_WAVE
IS
SELECT tms_status
  FROM waves
 WHERE wave = in_wave;
WV C_WAVE%rowtype;

  l_errorno integer;
  l_msg varchar2(255);

CURSOR C_FMT
IS
SELECT C.tms_orders_to_plan_format
  FROM customer C, orderhdr O
 WHERE O.wave = in_wave
   and C.custid = O.custid;


  l_format customer.tms_orders_to_plan_format%type;



BEGIN
    out_errmsg := 'OKAY';

    WV := null;
    OPEN C_WAVE;
    FETCH C_WAVE into WV;
    CLOSE C_WAVE;

    if nvl(WV.tms_status,'X') != '1' then
        out_errmsg := 'Wave has invalid tms status:'||WV.tms_status;
        return;
    end if;


    if in_format is null then
        l_format := null;
        OPEN C_FMT;
        FETCH C_FMT into l_format;
        CLOSE C_FMT;
    else
        l_format := in_format;

    end if;


    update waves
       set tms_status = '2',
           tms_status_update = sysdate
     where wave = in_wave;

    l_msg := '';
    l_errorno := 0;

    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        'ALL', -- custid
        l_format, -- formatid
        null, -- importfilepath
        'NOW', -- when
        in_wave, -- loadno (wave)
        0, -- orderid
        0, -- shipid
        in_userid, --userid
        'WAVES', -- tablename
        '',  --columnname
        '', --filtercolumnname
        '', -- company
        '', -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        l_errorno,
        l_msg);
    if l_errorno != 0 then
        out_errmsg := l_msg;
    end if;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'send_wave: '||substr(sqlerrm,1,80);
END send_wave;

----------------------------------------------------------------------
--
-- deplan_order
--
----------------------------------------------------------------------
PROCEDURE deplan_order
(
    in_wave     IN      integer,
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_ORD
IS
SELECT wave, tms_status, carrier, shipto, custid, fromfacility
  FROM orderhdr
 WHERE orderid = in_orderid
   and shipid = in_shipid
 for update of wave,tms_status;

ORD C_ORD%rowtype;

CURSOR C_WAVE(in_facility varchar2, in_custid varchar2,
        in_carrier varchar2, in_shipto varchar2)
IS
  SELECT *
    FROM waves
   WHERE wavestatus = '1' -- Comitted
     AND tms_status = '1' -- Not Optimized
     AND facility = in_facility
     AND exists
    (select * from orderhdr
      where custid = in_custid
        and carrier = in_carrier
        and wave = waves.wave);

CURSOR C_CURWAVE(in_wave integer)
IS
  SELECT *
    FROM waves
   WHERE wave = in_wave ;

WV waves%rowtype;

l_wave waves.wave%type;
cnt integer;

BEGIN
    out_errmsg := 'OKAY';

    ORD := NULL;
    OPEN C_ORD;
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if nvl(ORD.wave,-1) != in_wave then
        out_errmsg := 'Order not currently in wave';
        return;
    end if;

    if nvl(ORD.tms_status,'X') != '2' then
        out_errmsg := 'Order not currently optimizing.';
        return;
    end if;

-- Locate Wave for it to join
    WV := null;
    OPEN C_WAVE(ORD.fromfacility, ord.custid, ord.carrier,
                    nvl(ORD.shipto,'*NULL*')) ;
    FETCH C_WAVE into WV;
    CLOSE C_WAVE;

    l_wave := WV.wave;

-- If no wave found create a new wave for the order
    if WV.wave is null then

        OPEN C_CURWAVE(ORD.wave);
        FETCH C_CURWAVE into WV;
        CLOSE C_CURWAVE;


        zwv.get_next_wave(l_wave,out_errmsg);
        if substr(out_errmsg,1,4) != 'OKAY' then
            return;
        end if;
        insert into waves
            (wave, descr, wavestatus,
            facility, lastuser, lastupdate,
            stageloc,picktype,sortloc,batchcartontype,
            taskpriority,orderlimit,sdi_max_units,
            tms_status, tms_status_update)
        values
            (l_wave, WV.descr, '1',
            ORD.fromfacility, in_userid, sysdate,
            WV.stageloc, WV.picktype, WV.sortloc, WV.batchcartontype,
            WV.taskpriority,WV.orderlimit,WV.sdi_max_units,
            '1',sysdate);
    end if;




    -- remove order from plan

    update orderhdr
       set wave = l_wave,
           tms_status = '1',
           tms_status_update = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;


    select count(*)
      into cnt
      from orderhdr
     where wave = in_wave;

    if cnt = 0 then
        update waves
          set wavestatus = '4'
         where wave = in_wave;

    end if;



END;


----------------------------------------------------------------------
--
-- plan_order
--
----------------------------------------------------------------------
PROCEDURE plan_order
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_shipment IN      varchar2,
    in_release  IN      varchar2,
    in_carrier  IN      varchar2,
    in_deliveryservice IN varchar2,
    in_shipdate IN      date,
    in_arrivaldate IN   date,
    in_apptdate IN      date,
    in_shiptype IN      varchar2,
    in_scac     IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_ORD
IS
  SELECT *
    FROM orderhdr
   WHERE orderid = in_orderid
    AND shipid = in_shipid;
ORD C_ORD%rowtype;

CURSOR C_WAVE(in_facility varchar2,
        in_ship varchar2, in_carrier varchar2, in_shipto varchar2)
IS
  SELECT *
    FROM waves
   WHERE wavestatus = '1' -- Comitted
     AND tms_status = '3' -- Optimized
     AND facility = in_facility
     AND exists
    (select * from orderhdr
      where tms_shipment_id = in_ship
        and carrier = in_carrier
        and wave = waves.wave);


CURSOR C_CURWAVE(in_wave integer)
IS
  SELECT *
    FROM waves
   WHERE wave = in_wave ;

WV waves%rowtype;

l_wave waves.wave%type;
cnt integer;

BEGIN
    out_errmsg := 'OKAY';

-- Read the order information
    ORD := null;
    OPEN C_ORD;
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

-- Verify it is part of a planning run to TMS system
    if nvl(ORD.tms_status, 'X') not in ('2','3') then
        out_errmsg := 'Order:'||in_orderid||'/'||in_shipid
                ||' not currently being optimized.';
        return;
    end if;

-- Locate Wave for it to join
    WV := null;
    OPEN C_WAVE(ORD.fromfacility, in_shipment, in_carrier,
                    nvl(ORD.shipto,'*NULL*')) ;
    FETCH C_WAVE into WV;
    CLOSE C_WAVE;

    l_wave := WV.wave;

-- If no wave found create a new wave for the order
    if WV.wave is null then

        OPEN C_CURWAVE(ORD.wave);
        FETCH C_CURWAVE into WV;
        CLOSE C_CURWAVE;


        zwv.get_next_wave(l_wave,out_errmsg);
        if substr(out_errmsg,1,4) != 'OKAY' then
            return;
        end if;
        insert into waves
            (wave, descr, wavestatus,
            facility, lastuser, lastupdate,
            stageloc,picktype,sortloc,batchcartontype,
            taskpriority,orderlimit,sdi_max_units,
            tms_status, tms_status_update)
        values
            (l_wave, in_scac||': '||to_char(in_shipdate,'YYYYMMDDHH24MISS'),
            '1',
            ORD.fromfacility, in_userid, sysdate,
            WV.stageloc, WV.picktype, WV.sortloc, WV.batchcartontype,
            WV.taskpriority,WV.orderlimit,WV.sdi_max_units,
            '3',sysdate);
    end if;


-- Add order to wave (is there a zwave funtion to use)
    update orderhdr
       set tms_status = '3',
           tms_status_update = sysdate,
           wave = l_wave,
           carrier = in_carrier,
           deliveryservice = in_deliveryservice,
           tms_shipment_id = in_shipment,
           tms_release_id = in_release,
           shipdate = nvl(in_shipdate,shipdate),
           arrivaldate = nvl(in_arrivaldate,arrivaldate),
           apptdate = nvl(in_apptdate,apptdate),
           shiptype = nvl(in_shiptype,shiptype),
           lastuser = in_userid,
           lastupdate = sysdate
     where orderid = in_orderid
       and shipid = in_shipid;

   update orderlabor
      set wave = l_wave,
          lastuser = in_userid,
          lastupdate = sysdate
    where orderid = in_orderid
      and shipid = in_shipid;

-- Update old wave if has changed
   if ORD.wave != l_wave then
       select count(1) into cnt
          from orderhdr
          where wave = ORD.wave;
       if (cnt = 0) then
          update waves
             set wavestatus = '4',
                 lastuser = in_userid,
                 lastupdate = sysdate
             where wave = ORD.wave;
       end if;
   end if;

exception when others then
  out_errmsg := substr(sqlerrm,1,80);
END plan_order;

----------------------------------------------------------------------
--
-- release_wave - release an optimized wave to planning
--
----------------------------------------------------------------------
PROCEDURE release_wave
(
    in_wave     IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_WAVE
IS
SELECT wave, tms_status
  FROM waves
 WHERE wave = in_wave;
WV C_WAVE%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    WV := null;
    OPEN C_WAVE;
    FETCH C_WAVE into WV;
    CLOSE C_WAVE;

    if WV.wave is null then
        out_errmsg := 'Wave '||in_wave||' does not exist.';
        return;
    end if;

    if nvl(WV.tms_status,'X') != '3' then
        out_errmsg := 'Wave '||in_wave||' has invalid status.';
        return;
    end if;

    update waves
       set tms_status = '4',
           tms_status_update = sysdate
     where wave = in_wave;

    update orderhdr
       set tms_status = '4',
           tms_status_update = sysdate
      where wave = in_wave;


EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'ReleaseWave: '||substr(sqlerrm,1,80);
END release_wave;


----------------------------------------------------------------------
--
-- send_order_change - send an orderstatus change to TMS
--
----------------------------------------------------------------------
PROCEDURE send_order_change
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_ORD
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;
ORD C_ORD%rowtype;

  l_errorno integer;
  l_msg varchar2(255);

CURSOR C_FMT(in_custid varchar2)
IS
SELECT tms_status_changes_format
  FROM customer
 WHERE custid = in_custid;


  l_format customer.tms_status_changes_format%type;



BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD;
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.custid is null then
        out_errmsg := 'Order not found:'||in_orderid||'/'||in_shipid;
        return;
    end if;


    l_format := null;
    OPEN C_FMT(ORD.custid);
    FETCH C_FMT into l_format;
    CLOSE C_FMT;

    if l_format is null then
        out_errmsg := 'Order change format not found for customer:'
                ||ORD.custid;
        return;
    end if;


    l_msg := '';
    l_errorno := 0;

    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        ORD.custid, -- custid
        l_format, -- formatid
        null, -- importfilepath
        'NOW', -- when
        0, -- loadno (wave)
        in_orderid, -- orderid
        in_shipid, -- shipid
        in_userid, --userid
        'ORDERHDR', -- tablename
        '',  --columnname
        '', --filtercolumnname
        '', -- company
        '', -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        l_errorno,
        l_msg);
    if l_errorno != 0 then
        out_errmsg := l_msg;
    end if;

END send_order_change;


----------------------------------------------------------------------
--
-- send_order_ship - send an order shipped to TMS
--
----------------------------------------------------------------------
PROCEDURE send_order_ship
(
    in_orderid  IN      integer,
    in_shipid   IN      integer,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_ORD
IS
SELECT *
  FROM orderhdr
 WHERE orderid = in_orderid
   AND shipid = in_shipid;
ORD C_ORD%rowtype;

  l_errorno integer;
  l_msg varchar2(255);

CURSOR C_FMT(in_custid varchar2)
IS
SELECT tms_actual_ship_format
  FROM customer
 WHERE custid = in_custid;


  l_format customer.tms_actual_ship_format%type;



BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD;
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.custid is null then
        out_errmsg := 'Order not found:'||in_orderid||'/'||in_shipid;
        return;
    end if;


    l_format := null;
    OPEN C_FMT(ORD.custid);
    FETCH C_FMT into l_format;
    CLOSE C_FMT;

    if l_format is null then
        out_errmsg := 'Ship format not found for customer:'
                ||ORD.custid;
        return;
    end if;

    l_msg := '';
    l_errorno := 0;

    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        ORD.custid, -- custid
        l_format, -- formatid
        null, -- importfilepath
        'NOW', -- when
        0, -- loadno (wave)
        in_orderid, -- orderid
        in_shipid, -- shipid
        in_userid, --userid
        'ORDERHDR', -- tablename
        '',  --columnname
        '', --filtercolumnname
        '', -- company
        '', -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        l_errorno,
        l_msg);
    if l_errorno != 0 then
        out_errmsg := l_msg;
    end if;

END send_order_ship;

----------------------------------------------------------------------
--
-- send_item_info - send item information to TMS
--
----------------------------------------------------------------------
PROCEDURE send_item_info
(
    in_custid   IN      varchar2,
    in_item     IN      varchar2,
    in_userid   IN      varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_ITM
IS
SELECT *
  FROM custitem
 WHERE custid = in_custid
   AND item = in_item;
ITM C_ITM%rowtype;

  l_errorno integer;
  l_msg varchar2(255);

CURSOR C_FMT(in_custid varchar2)
IS
SELECT tms_item_format
  FROM customer
 WHERE custid = in_custid;


  l_format customer.tms_item_format%type;



BEGIN
    out_errmsg := 'OKAY';

    ITM := null;
    OPEN C_ITM;
    FETCH C_ITM into ITM;
    CLOSE C_ITM;

    if ITM.custid is null then
        out_errmsg := 'Item not found:'||in_item;
        return;
    end if;


    l_format := null;
    OPEN C_FMT(in_custid);
    FETCH C_FMT into l_format;
    CLOSE C_FMT;

    if l_format is null then
        out_errmsg := 'Item format not found for customer:'
                ||in_custid;
        return;
    end if;

    l_msg := '';
    l_errorno := 0;

    ziem.impexp_request(
        'E', -- reqtype
        null, -- facility
        in_custid, -- custid
        l_format, -- formatid
        in_item, -- importfilepath
        'NOW', -- when
        0, -- loadno (wave)
        0, -- orderid
        0, -- shipid
        in_userid, --userid
        'CUSTITEM', -- tablename
        '',  --columnname
        '', --filtercolumnname
        '', -- company
        '', -- warehouse
        null, -- begindatestr
        null, -- enddatestr
        l_errorno,
        l_msg);
    if l_errorno != 0 then
        out_errmsg := l_msg;
    end if;

END send_item_info;

----------------------------------------------------------------------
--
-- process_transmission
--
----------------------------------------------------------------------
PROCEDURE process_transmission
(
    in_transmission  IN      number,
    in_userid       IN  varchar2,
    out_errmsg  IN OUT  varchar2
)
IS

CURSOR C_HDR(in_trans number)
IS
SELECT *
  FROM tmsplanship_hdr
 WHERE sendertransmissionno = in_trans;

HDR tmsplanship_hdr%rowtype;

cursor curStopDtl(in_release varchar2)
is
select sendertransmissionno,
       stopsequence
  from tmsplanship_shipstopdtl
 where sendertransmissionno = in_transmission
   and shipunit like in_release||'%'
   and shipmentstopactivity = 'D';
std curStopDtl%rowtype;

cursor curStop(in_stopsequence number)
is
select sendertransmissionno,
       arrivaltimeestimated as apptarrivaldate,
       arrivaltimeplanned as shipdate
  from tmsplanship_shipstop
 where sendertransmissionno = in_transmission
   and stopsequence = in_stopsequence;
stp curStop%rowtype;

cursor curBOLComments(in_orderid number, in_shipid number)
is
select bc.*
  from orderhdr oh,
       tmsplanship_bolcomments bc
 where oh.orderid = in_orderid
 and oh.shipid = in_shipid
 and bc.sendertransmissionno = in_transmission
 and ((upper(oh.shipto) = upper(bc.shipto))
   or (upper(oh.shiptoaddr1) = upper(bc.addr)
   and upper(oh.shiptocity) = upper(bc.city)
   and upper(oh.shiptostate) = upper(bc.state)
   and upper(oh.shiptopostalcode) = upper(bc.postalcode)));
BOL curBOLComments%rowtype;

cursor curOHBOLComments(in_orderid number, in_shipid number)
is
select *
  from orderhdrbolcomments
  where orderid = in_orderid
  and shipid = in_shipid;
OHBOL curOHBOLComments%rowtype;

l_carrier varchar2(4);
l_deliveryservice varchar2(4);
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_pos integer;
strMsg varchar2(255);
cntHdr integer;
cntRel integer;
cntOrd integer;
cntBol integer;

BEGIN

    out_errmsg := 'OKAY';

    HDR := null;
    BOL := null;

    OPEN C_HDR(in_transmission);
    FETCH C_HDR into HDR;
    CLOSE C_HDR;

    if HDR.sendertransmissionno is null then
      out_errmsg := 'Invalid transmission number ' || hdr.sendertransmissionno;
      return;
    end if;


    cntHdr := 0;
    cntRel := 0;
    cntOrd := 0;

    for cshdr in (select H.*
                    from tmsplanship_shiphdr H
                   where H.sendertransmissionno = HDR.sendertransmissionno)
    loop

        cntHdr := cntHdr + 1;
        l_carrier := substr(cshdr.serviceprovideraliasvalue,5,4);
        l_deliveryservice := substr(cshdr.serviceproviderdeliveryservice,1,4);

        for crel in (select *
                       from tmsplanship_rel
                      where sendertransmissionno = HDR.sendertransmissionno)
        loop

            cntRel := cntRel + 1;

            l_pos := instr(crel.transorderheader,'-');
            l_orderid := substr(crel.transorderheader,1,l_pos-1);
            l_shipid := substr(crel.transorderheader,l_pos+1);

            if nvl(l_orderid,0) != 0 then

              std := null;
              open curStopDtl(crel.release);
              fetch curStopDtl into std;
              close curStopDtl;

              if nvl(std.sendertransmissionno,0) != 0 then

                stp := null;
                open curStop(std.stopsequence);
                fetch curStop into stp;
                close curStop;

                if nvl(stp.sendertransmissionno,0) != 0 then

                  plan_order(l_orderid, l_shipid, cshdr.shipment,
                      crel.release, l_carrier, l_deliveryservice,
                      stp.shipdate, stp.apptarrivaldate, stp.apptarrivaldate,
                      crel.shiptype, cshdr.serviceprovider,
                      in_userid, out_errmsg);

                  if out_errmsg <> 'OKAY' then
                    zms.log_msg('TMSPLAN', null, null,
                      'Not planned: ' || out_errmsg,
                      'E', in_userid, strMsg);
                  end if;

                else

                  zms.log_msg('TMSPLAN', null, null,
                    'Transmission ' || in_transmission || ' No Delivery Stop found for release ' ||
                    crel.release || ' stop sequence ' || std.stopsequence, 'E', in_userid, strMsg);

                end if;

              else
                zms.log_msg('TMSPLAN', null, null,
                  'Transmission ' || in_transmission || ' No Delivery StopDtl found for release ' ||
                  crel.release, 'E', in_userid, strMsg);
              end if;

            end if;

            BOL := null;
            OPEN curBOLComments(l_orderid, l_shipid);
            FETCH curBOLComments into BOL;
            CLOSE curBOLComments;

            if BOL.sendertransmissionno is not null then
               cntBol := 0;

               OHBOL := null;
               OPEN curOHBOLComments(l_orderid, l_shipid);
               FETCH curOHBOLComments into OHBOL;
               CLOSE curOHBOLComments;

               if OHBOL.orderid is not null
               then
                  OHBOL.bolcomment := rtrim(OHBOL.bolcomment)||CHR(13)||CHR(10)||rtrim(BOL.bolcomment);
                  update orderhdrbolcomments
                  set bolcomment = OHBOL.bolcomment,
                      lastuser = in_userid,
                      lastupdate = sysdate
                  where orderid = l_orderid
                  and shipid = l_shipid;
               else
                  insert into orderhdrbolcomments
                  (
                     orderid,
                     shipid,
                     bolcomment,
                     lastuser,
                     lastupdate
                  )
                  values
                  (
                     l_orderid,
                     l_shipid,
                     BOL.bolcomment,
                     in_userid,
                     sysdate
                  );
               end if;
            end if;
        end loop;

    end loop;

    zms.log_msg('TMSPLAN', null, null,
      'Transmission ' || in_transmission || ': ' || cntHdr || ' ship headers '||
        cntRel || ' releases ',
      'I', in_userid, strMsg);

    out_errmsg := 'OKAY';

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'ProcTrans: '||substr(sqlerrm,1,80);
END process_transmission;


end ztms_transynd;
/
show error package body ztms_transynd;
exit;
