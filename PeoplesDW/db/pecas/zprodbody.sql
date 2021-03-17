create or replace package body zprod as
--
-- $Id$
--

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
CURSOR C_ORD_JOB(in_custid varchar2, in_jobno varchar2)
IS
SELECT *
  FROM alps.orderhdr
 WHERE custid = in_custid
   AND reference = in_jobno||'/001'
   AND ordertype = 'P';
----------------------------------------------------------------------
CURSOR C_ORDDTL(in_orderid number, in_shipid number, in_item varchar2)
IS
SELECT *
  FROM alps.orderdtl
 WHERE orderid = in_orderid
   AND shipid = in_shipid
   AND item = in_item
   AND lotnumber is null;
----------------------------------------------------------------------
CURSOR C_ITMSIZE(in_custid varchar2, in_item varchar2)
IS
SELECT *
  FROM jobitemsizeview
 WHERE custid = in_custid
   AND item = in_item;
----------------------------------------------------------------------
CURSOR C_CUSTITEMV(in_custid varchar2, in_item varchar2)
RETURN alps.custitemview%rowtype
IS
    SELECT *
      FROM alps.custitemview
     WHERE custid = in_custid
       AND item = in_item;
----------------------------------------------------------------------
CURSOR C_LOC(in_facility varchar2, in_locid varchar2)
IS
SELECT *
  FROM alps.location
 WHERE locid = in_locid
   AND facility = in_facility;
----------------------------------------------------------------------
CURSOR C_LFH(in_lpid varchar2)
IS
SELECT *
  FROM load_flag_hdr H
 WHERE H.lpid = in_lpid;







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
-- is_lpid - verify format of lpid
--
----------------------------------------------------------------------
FUNCTION is_lpid (in_lpid IN varchar2)
        RETURN boolean
IS
BEGIN
        if (translate(in_lpid, '0123456789', 'nnnnnnnnnn') = 'nnnnnnnnnnnnnnn') then
                return true;
        else
                return false;
        end if;
END;



----------------------------------------------------------------------
--
-- create_load_flag - Create Load Flags for an Order
--
----------------------------------------------------------------------
PROCEDURE create_load_flag
(
    in_orderid  number,
    in_shipid   number,
    in_jobno    varchar2,
    in_item     varchar2,
    in_pieces   number,
    in_cartons  number,
    in_overage  number,
    in_dt       date,
    out_errmsg  OUT varchar2
)
IS

ORD alps.orderhdr%rowtype;
PORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
PDTL alps.orderdtl%rowtype;
ITM jobitemsizeview%rowtype;

l_pieces number;
l_cartons number;
l_overage number;
l_qtyorder alps.orderdtl.qtyorder%type;

ctns number;
plts number;
remains number;
last_ctns number;


l_lpid alps.plate.lpid%type;
errmsg varchar2(255);


BEGIN
    out_errmsg := 'OKAY';


    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order: '||in_orderid||'/'||in_shipid||' not found';
        return;
    end if;


    DTL := null;
    OPEN C_ORDDTL(in_orderid, in_shipid, in_item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        out_errmsg := 'Order Line: '||in_orderid||'/'||in_shipid||
            '/'||in_item||' not found';
        return;
    end if;


    PORD := null;
    OPEN C_ORD_JOB(ORD.custid, in_jobno);
    FETCH C_ORD_JOB into PORD;
    CLOSE C_ORD_JOB;

    PDTL := null;
    OPEN C_ORDDTL(PORD.orderid, PORD.shipid, in_item);
    FETCH C_ORDDTL into PDTL;
    CLOSE C_ORDDTL;



    ITM := null;
    OPEN C_ITMSIZE(ORD.custid, in_item);
    FETCH C_ITMSIZE into ITM;
    CLOSE C_ITMSIZE;


    if ITM.item is null and in_pieces is null then
        out_errmsg := 'Item Sizes for: '||ORD.custid||
            '/'||in_item||' not found';
        return;
    end if;

    l_cartons := nvl(in_cartons, 
            nvl(DTL.dtlpassthrunum02,ITM.ctn_plt));
    l_pieces := nvl(in_pieces, 
            nvl(DTL.dtlpassthrunum01,ITM.pcs_ctn));

    l_overage := nvl(in_overage, nvl(ORD.hdrpassthrunum10, 
                        nvl(PDTL.dtlpassthrunum10,0))) 
                /100;

    l_qtyorder := DTL.qtyorder * (1 + l_overage);
    

    ctns := ceil(l_qtyorder/l_pieces);
    plts := ceil(ctns/l_cartons);
    remains := mod(l_qtyorder, l_pieces);

    -- trace('CLF','Cartons:'||ctns||' Plts:'||plts||' Remains:'||remains);



    for ix in 1..plts loop
        zrf.get_next_lpid(l_lpid, errmsg);

        insert into load_flag_hdr(type, jobno,facility,custid,lpid,status,
                    skidno, total_skid, created)
            values( 'D', in_jobno, ORD.fromfacility, ORD.custid,l_lpid,'NEW',
                    ix, plts, in_dt);

        if ix = plts then
            if remains = 0 then

               last_ctns := mod(ctns,l_cartons);
               if last_ctns = 0 then
                  last_ctns := l_cartons;
               end if;
               insert into load_flag_dtl (lpid, orderid, shipid, item, pieces,
                    quantity)
                values (l_lpid, in_orderid, in_shipid, in_item, l_pieces,
                        --mod(ctns,l_cartons));
                        last_ctns);

            else
               last_ctns := mod(ctns,l_cartons) -1 ;
               if last_ctns = -1 then
                  last_ctns := l_cartons -1;
               end if;
               if last_ctns > 0 then
                 insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
                  values (l_lpid, in_orderid, in_shipid, in_item,
                    l_pieces, last_ctns);
                end if;

               insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
                values (l_lpid, in_orderid, in_shipid, in_item,
                        remains, 1);
            end if;
        else
            insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
            values (l_lpid, in_orderid, in_shipid, in_item,
                    l_pieces, l_cartons);

        end if;
    end loop;


    UPDATE alps.orderhdr
       SET orderstatus = '4' -- Released
           -- hdrpassthrunum01 = nvl(in_pieces,hdrpassthrunum01),
           -- hdrpassthrunum02 = nvl(in_cartons,hdrpassthrunum02)
--           hdrpassthrunum10 = nvl(in_overage,hdrpassthrunum02)
     WHERE orderid = in_orderid
       AND shipid = in_shipid;


-- Digital Printing
    UPDATE alps.orderdtl
       SET
           dtlpassthrunum01 = nvl(in_pieces,dtlpassthrunum01),
           dtlpassthrunum02 = nvl(in_cartons,dtlpassthrunum02)
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item;


EXCEPTION WHEN OTHERS THEN

    out_errmsg := 'CLF:'||sqlerrm;

END create_load_flag;


----------------------------------------------------------------------
--
-- next_skid_build
--
----------------------------------------------------------------------
PROCEDURE next_skid_build
(
    out_buildno  OUT number
)
IS
buildno number;
BEGIN
    out_buildno := 0;
    select skidbuildseq.nextval
      into out_buildno
      from dual;

    return;
EXCEPTION WHEN OTHERS THEN
    out_buildno := -1;

END next_skid_build;


----------------------------------------------------------------------
--
-- clear_cartons - Clear cartons for a session
--
----------------------------------------------------------------------
PROCEDURE clear_cartons
(
    in_buildno  number
)
IS
BEGIN
    delete from skid_build
     where buildno = in_buildno;
EXCEPTION WHEN OTHERS THEN
    null;
END clear_cartons;

----------------------------------------------------------------------
--
-- create_cartons - Create Cartons for an Order
--
----------------------------------------------------------------------
PROCEDURE create_cartons
(
    in_buildno  number,
    in_orderid  number,
    in_shipid   number,
    in_jobno    varchar2,
    in_item     varchar2,
    in_pieces   number,
    in_cartons  number,
    out_errmsg  OUT varchar2
)
IS

ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
ITM jobitemsizeview%rowtype;

l_pieces number;
l_ppc number;
l_cartons number;

ctns number;
plts number;
remains number;

l_lpid alps.plate.lpid%type;
errmsg varchar2(255);

l_cartonno number;

CURSOR C_SKID(in_buildno number, in_orderid number, in_shipid number)
IS
SELECT cartonno, sum(pieces/pieces_per_carton) pct_used
  FROM skid_build
 WHERE buildno = in_buildno
   AND orderid = in_orderid
   AND shipid = in_shipid
 GROUP by cartonno
 ORDER BY 2;


SKD C_SKID%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order: '||in_orderid||'/'||in_shipid||' not found';
        return;
    end if;


    DTL := null;
    OPEN C_ORDDTL(in_orderid, in_shipid, in_item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        out_errmsg := 'Order Line: '||in_orderid||'/'||in_shipid||
            '/'||in_item||' not found';
        return;
    end if;


    ITM := null;
    OPEN C_ITMSIZE(ORD.custid, in_item);
    FETCH C_ITMSIZE into ITM;
    CLOSE C_ITMSIZE;


    if ITM.item is null and in_pieces is null then
        out_errmsg := 'Item Sizes for: '||ORD.custid||
            '/'||in_item||' not found';
        return;
    end if;

    l_cartons := nvl(in_cartons, 
            nvl(DTL.dtlpassthrunum02,ITM.ctn_plt));
    l_ppc := nvl(in_pieces, 
            nvl(DTL.dtlpassthrunum01,ITM.pcs_ctn));
    l_pieces := l_ppc;

    -- Check for resuming a carton
    SKD := null;
    OPEN C_SKID(in_buildno, in_orderid, in_shipid);
    FETCH C_SKID into SKD;
    CLOSE C_SKID;

    if SKD.cartonno is not null and SKD.pct_used < 1 then
        remains := trunc(l_pieces * (1 - SKD.pct_used));

        if remains > DTL.qtyorder then
            remains := DTL.qtyorder;
        end if;

        if remains > 0 then
          insert into skid_build (buildno, skidno, orderid, shipid, item,
                      pieces, cartonno, pieces_per_carton)
           values (in_buildno, 0, in_orderid, in_shipid, in_item,
                      remains, SKD.cartonno, l_ppc);
        end if;

        DTL.qtyorder := DTL.qtyorder - remains;

    end if;



    ctns := ceil(DTL.qtyorder/l_pieces);
    remains := mod(DTL.qtyorder, l_pieces);

    -- trace('CC','Cartons:'||ctns||' Plts:'||plts||' Remains:'||remains);

    l_cartonno := 0;
    select nvl(max(cartonno),0)
      into l_cartonno
     from skid_build
    where buildno = in_buildno
      and orderid = in_orderid
      and shipid = in_shipid;

    for ix in 1..ctns loop


        if ix = ctns and remains > 0 then
            l_pieces := remains;
        end if;

        insert into skid_build (buildno, skidno, orderid, shipid, item,
                    pieces, cartonno, pieces_per_carton)
         values (in_buildno, 0, in_orderid, in_shipid, in_item,
                    l_pieces, ix+l_cartonno, l_ppc);

    end loop;


    -- UPDATE alps.orderhdr
    --   SET
    --       hdrpassthrunum01 = nvl(in_pieces,hdrpassthrunum01),
    --       hdrpassthrunum02 = nvl(in_cartons,hdrpassthrunum02)
    -- WHERE orderid = in_orderid
    --   AND shipid = in_shipid;

-- Digital Printing
    UPDATE alps.orderdtl
       SET
           dtlpassthrunum01 = nvl(in_pieces,dtlpassthrunum01),
           dtlpassthrunum02 = nvl(in_cartons,dtlpassthrunum02)
     WHERE orderid = in_orderid
       AND shipid = in_shipid
       AND item = in_item;

EXCEPTION WHEN OTHERS THEN

    out_errmsg := 'CC:'||sqlerrm;

END create_cartons;



----------------------------------------------------------------------
--
-- merge_cartons - Merge Cartons into skids
--
----------------------------------------------------------------------
PROCEDURE merge_cartons
(
    in_buildno  number,
    out_errmsg  OUT varchar2
)
IS

type cartonrec is record (
    cartonno            skid_build.cartonno%type,
    pieces              skid_build.pieces%type,
    pieces_per_carton   skid_build.pieces_per_carton%type,
    pct                 number
);

type cartonrectable is table of cartonrec
     index by binary_integer;

acr cartonrec;

cartonrecs cartonrectable;
ix integer;
iy integer;


total_pct number;
crtns integer;

BEGIN
    out_errmsg := 'OKAY';

    for crec in (select orderid, shipid
                   from skid_build
                  where buildno = in_buildno
                    and pieces < pieces_per_carton
                   group by orderid, shipid
                   having count(1) > 1)
    loop
        -- zut.prt('Order id: '||crec.orderid||'/'||crec.shipid);
        total_pct := 0;

        for cr2 in (select cartonno, pieces, pieces_per_carton,
                        pieces/pieces_per_carton pct
                      from skid_build
                     where buildno = in_buildno
                       and pieces < pieces_per_carton
                       and orderid = crec.orderid
                       and shipid = crec.shipid)
        loop

            -- zut.prt('... Pieces:'||cr2.pieces||'/'||cr2.pieces_per_carton
            --         ||' = '||cr2.pct);
            ix := cartonrecs.count + 1;
            cartonrecs(ix).cartonno := cr2.cartonno;
            cartonrecs(ix).pieces := cr2.pieces;
            cartonrecs(ix).pieces_per_carton := cr2.pieces_per_carton;
            cartonrecs(ix).pct := cr2.pct;
            total_pct := total_pct + cr2.pct;

        end loop;

        crtns := ceil(total_pct);
        zut.prt('Total Pct: '||total_pct||' Cartons:'||crtns);
        
        if crtns < cartonrecs.count then
            zut.prt('Need to rearrange cartons');

        end if;


        for ix in 1..cartonrecs.count
        loop
            if cartonrecs(ix).cartonno > 0 then
                zut.prt('Cartonno: '||cartonrecs(ix).cartonno);
            end if;
        end loop;

        cartonrecs.delete;

    end loop; 
                  


EXCEPTION WHEN OTHERS THEN

    out_errmsg := 'MC:'||sqlerrm;

END merge_cartons;


----------------------------------------------------------------------
--
-- create_carton_skids - Merge Cartons into skids
--
----------------------------------------------------------------------
PROCEDURE create_carton_skids
(
    in_buildno  number,
    in_jobno    varchar2,
    in_cartons  number,
    in_method   varchar2,   -- ORDER, ITEM, COMBINE BY ORDER, COMBINE BY ITEM
    out_errmsg  OUT varchar2
)
IS

--CURSOR C_ORDER_OLD(in_buildno number)
--IS
--SELECT rowid, skid_build.*
--  FROM skid_build
-- WHERE buildno = in_buildno
-- ORDER BY orderid, shipid, cartonno, pieces desc;

CURSOR C_ORDER(in_buildno number)
IS
SELECT distinct buildno, skidno, orderid, shipid, cartonno
  FROM skid_build
 WHERE buildno = in_buildno
 ORDER BY orderid, shipid, cartonno;

CURSOR C_ITEM(in_buildno number)
IS
SELECT rowid, skid_build.*
  FROM skid_build
 WHERE buildno = in_buildno
 ORDER BY item, pieces desc, orderid, shipid, cartonno;


CURSOR C_SIZE(in_buildno number)
IS
SELECT rowid, skid_build.*
  FROM skid_build
 WHERE buildno = in_buildno
 ORDER BY item, pieces desc, orderid, shipid;

l_skidno  integer;
l_crtnno  integer;
currsz  integer;
curr_item skid_build.item%type;

l_orderid number;
l_shipid number;

BEGIN
    out_errmsg := 'OKAY';

l_skidno := 1;
l_crtnno := 0;
currsz := null;
l_orderid := null;
curr_item := null;


if in_method in ( 'ORDER','COMBINE BY ORDER') then
  for crec in C_ORDER(in_buildno)
  loop
    if l_orderid is null then
        l_orderid := crec.orderid;
        l_shipid := crec.shipid;
    end if;

    l_crtnno := l_crtnno + 1;
    if l_crtnno > in_cartons
     or (
           in_method = 'ORDER' and
          (l_orderid != crec.orderid or l_shipid != crec.shipid))
    then
        l_orderid := crec.orderid;
        l_shipid := crec.shipid;
        l_skidno := l_skidno + 1;
        l_crtnno := 1;
    end if;
    update skid_build
      set skidno = l_skidno
     where buildno = crec.buildno
       and orderid = crec.orderid
       and shipid = crec.shipid
       and cartonno = crec.cartonno;
  end loop;
elsif in_method in ( 'COMBINE BY ITEM', 'ITEM') then
  for crec in C_ITEM(in_buildno)
  loop
    if l_orderid is null then
        l_orderid := crec.orderid;
        l_shipid := crec.shipid;
    end if;
    if curr_item is null then
        curr_item := crec.item;
    end if;

    l_crtnno := l_crtnno + 1;
    if l_crtnno > in_cartons
    --  or (
    --        in_method = 'ORDER' and
    --        (l_orderid != crec.orderid or l_shipid != crec.shipid))
      or (
            in_method = 'ITEM' and
            (curr_item != crec.item))
    then
        l_orderid := crec.orderid;
        l_shipid := crec.shipid;
        l_skidno := l_skidno + 1;
        l_crtnno := 1;
        curr_item := crec.item;
    end if;
    update skid_build
      set skidno = l_skidno
     where rowid = crec.rowid;

  end loop;

elsif in_method = 'SIZE' then

  for crec in C_SIZE(in_buildno)
  loop
    if currsz is null then
        currsz := crec.pieces;
    end if;
    if curr_item is null then
        curr_item := crec.item;
    end if;
    l_crtnno := l_crtnno + 1;
    if l_crtnno > in_cartons or currsz != crec.pieces
       or curr_item != crec.item then
        l_skidno := l_skidno + 1;
        l_crtnno := 1;
        currsz := crec.pieces;
        curr_item := crec.item;
    end if;
    update skid_build
      set skidno = l_skidno
     where rowid = crec.rowid;

  end loop;
end if;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCS:'||sqlerrm;

END create_carton_skids;


----------------------------------------------------------------------
--
-- create_carton_load_flags - Merge Cartons into load_flags
--
----------------------------------------------------------------------
PROCEDURE create_carton_load_flags
(
    in_buildno  number,
    in_jobno    varchar2,
    in_type     varchar2,
    out_errmsg  OUT varchar2
)
IS
l_lpid alps.plate.lpid%type;
l_ctnid alps.plate.lpid%type;
l_crtnno number;
errmsg varchar2(255);

l_sn integer;
l_dt date;

cnt integer;

ORD alps.orderhdr%rowtype;
ORL alps.orderdtl%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    l_sn := 0;
    l_dt := sysdate;

    cnt := 0;
    select count(1)
      into cnt
      from skid_build
     where buildno = in_buildno
       and nvl(weight,0) = 0;

    if nvl(cnt,0) > 0 and in_type = 'Batched' then
        out_errmsg := 'There are cartons with unspecified or zero weights.';
        return;
    end if;

    for cskid in (select distinct S.skidno, O.custid, O.fromfacility
                    from skid_build S, alps.orderhdr O
                  where S.buildno = in_buildno
                    and O.orderid = S.orderid
                    and O.shipid = S.shipid)
    loop

        zrf.get_next_lpid(l_lpid, errmsg);
        l_sn := l_sn + 1;

        insert into load_flag_hdr(type, jobno,facility,custid,lpid,status,
                    skidno, total_skid, created)
            values( decode(in_type,'Unbatched','U','S'), 
                    in_jobno, cskid.fromfacility, cskid.custid,l_lpid,'NEW',
                    l_sn, -2, l_dt);

        ORD := null;
        for cord in (select orderid, shipid, item, pieces, weight,
                            count(1) crtns
                      from skid_build
                      where buildno = in_buildno
                        and skidno = cskid.skidno
                      group by orderid, shipid, item, pieces, weight)
        loop
               insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity, weight)
                values (l_lpid, cord.orderid, cord.shipid, cord.item,
                        cord.pieces,
                        cord.crtns, cord.weight);

        -- If this is a new order add the multiship header record
                if nvl(ORD.orderid,0) != cord.orderid
                or nvl(ORD.shipid,0) != cord.shipid then
                    OPEN C_ORD(cord.orderid, cord.shipid);
                    FETCH C_ORD into ORD;
                    CLOSE C_ORD;
                    zmn.add_multishiphdr(ORD, null, errmsg);
                end if;

        end loop;

        -- Add the carton data for the carton labels
        l_crtnno := 0;
        ORD := null;
        for cctn in (select orderid, shipid, item, pieces, weight,
                        cartonno
                       from skid_build
                      where buildno = in_buildno
                        and skidno = cskid.skidno
                       order by orderid, shipid, cartonno)
        loop
            if nvl(ORD.orderid,0) != cctn.orderid
            or nvl(ORD.shipid,0) != cctn.shipid then
                OPEN C_ORD(cctn.orderid, cctn.shipid);
                FETCH C_ORD into ORD;
                CLOSE C_ORD;
                l_crtnno := 0;
            end if;


            if cctn.cartonno != l_crtnno then
                l_crtnno := cctn.cartonno;
               zrf.get_next_lpid(l_ctnid, errmsg);
        -- Add the multiship detail info even though there is no plates
               ORL := null;
               OPEN C_ORDDTL(ORD.orderid,ORD.shipid,
                    cctn.item);
               FETCH C_ORDDTL into ORL;
               CLOSE C_ORDDTL;
               insert into multishipdtl(
                   orderid,
                   shipid,
                   cartonid,
                   estweight,
                   status,
                   length,
                   width,
                   height,
                   dtlpassthruchar01,
                   dtlpassthruchar02,
                   dtlpassthruchar03,
                   dtlpassthruchar04,
                   dtlpassthruchar05,
                   dtlpassthruchar06,
                   dtlpassthruchar07,
                   dtlpassthruchar08,
                   dtlpassthruchar09,
                   dtlpassthruchar10,
                   dtlpassthruchar11,
                   dtlpassthruchar12,
                   dtlpassthruchar13,
                   dtlpassthruchar14,
                   dtlpassthruchar15,
                   dtlpassthruchar16,
                   dtlpassthruchar17,
                   dtlpassthruchar18,
                   dtlpassthruchar19,
                   dtlpassthruchar20,
                   dtlpassthrunum01,
                   dtlpassthrunum02,
                   dtlpassthrunum03,
                   dtlpassthrunum04,
                   dtlpassthrunum05,
                   dtlpassthrunum06,
                   dtlpassthrunum07,
                   dtlpassthrunum08,
                   dtlpassthrunum09,
                   dtlpassthrunum10,
                   dtlpassthrudate01,
                   dtlpassthrudate02,
                   dtlpassthrudate03,
                   dtlpassthrudate04,
                   dtlpassthrudoll01,
                   dtlpassthrudoll02
               )
               values (
                   ORD.orderid,
                   ORD.shipid,
                   l_ctnid,
                   nvl(cctn.weight,0.1),
                   'READY',
                   zci.item_uom_length(ORD.custid,cctn.item,'PCS'),
                   zci.item_uom_width(ORD.custid,cctn.item,'PCS'),
                   zci.item_uom_height(ORD.custid,cctn.item,'PCS'),
                   ORL.dtlpassthruchar01,
                   ORL.dtlpassthruchar02,
                   ORL.dtlpassthruchar03,
                   ORL.dtlpassthruchar04,
                   ORL.dtlpassthruchar05,
                   ORL.dtlpassthruchar06,
                   ORL.dtlpassthruchar07,
                   ORL.dtlpassthruchar08,
                   ORL.dtlpassthruchar09,
                   ORL.dtlpassthruchar10,
                   ORL.dtlpassthruchar11,
                   ORL.dtlpassthruchar12,
                   ORL.dtlpassthruchar13,
                   ORL.dtlpassthruchar14,
                   ORL.dtlpassthruchar15,
                   ORL.dtlpassthruchar16,
                   ORL.dtlpassthruchar17,
                   ORL.dtlpassthruchar18,
                   ORL.dtlpassthruchar19,
                   ORL.dtlpassthruchar20,
                   ORL.dtlpassthrunum01,
                   ORL.dtlpassthrunum02,
                   ORL.dtlpassthrunum03,
                   ORL.dtlpassthrunum04,
                   ORL.dtlpassthrunum05,
                   ORL.dtlpassthrunum06,
                   ORL.dtlpassthrunum07,
                   ORL.dtlpassthrunum08,
                   ORL.dtlpassthrunum09,
                   ORL.dtlpassthrunum10,
                   ORL.dtlpassthrudate01,
                   ORL.dtlpassthrudate02,
                   ORL.dtlpassthrudate03,
                   ORL.dtlpassthrudate04,
                   ORL.dtlpassthrudoll01,
                   ORL.dtlpassthrudoll02
               );
            end if;
            insert into load_flag_ctn (lpid, orderid, shipid, item,
                pieces, cartonid, weight)
             values (l_lpid, cctn.orderid, cctn.shipid, cctn.item,
                    cctn.pieces, l_ctnid, cctn.weight);

       end loop;
    end loop;

    update load_flag_hdr
       set total_skid = l_sn
     where jobno = in_jobno
       and type = decode(in_type,'Unbatched','U','S')
       and total_skid = -2
       and created = l_dt;

    for cord in (select distinct orderid, shipid
                   from skid_build
                  where buildno = in_buildno)
    loop
        UPDATE alps.orderhdr
           SET orderstatus = '4'
         WHERE orderid = cord.orderid
           AND shipid = cord.shipid;

    end loop;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCLF:'||sqlerrm;

END create_carton_load_flags;


----------------------------------------------------------------------
--
-- create_carton_load_flags_OLD - Merge Cartons into load_flags
--
----------------------------------------------------------------------
PROCEDURE create_carton_load_flags_OLD
(
    in_buildno  number,
    in_jobno    varchar2,
    in_type     varchar2,
    out_errmsg  OUT varchar2
)
IS
l_lpid alps.plate.lpid%type;
l_ctnid alps.plate.lpid%type;
l_crtnno number;
errmsg varchar2(255);

l_sn integer;
l_dt date;

cnt integer;

ORD alps.orderhdr%rowtype;
ORL alps.orderdtl%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    l_sn := 0;
    l_dt := sysdate;

    cnt := 0;
    select count(1)
      into cnt
      from skid_build
     where buildno = in_buildno
       and nvl(weight,0) = 0;

    if nvl(cnt,0) > 0 and in_type = 'Batched' then
        out_errmsg := 'There are cartons with unspecified or zero weights.';
        return;
    end if;

    for cskid in (select distinct S.skidno, O.custid, O.fromfacility
                    from skid_build S, alps.orderhdr O
                  where S.buildno = in_buildno
                    and O.orderid = S.orderid
                    and O.shipid = S.shipid)
    loop

        zrf.get_next_lpid(l_lpid, errmsg);
        l_sn := l_sn + 1;

        insert into load_flag_hdr(type, jobno,facility,custid,lpid,status,
                    skidno, total_skid, created)
            values( decode(in_type,'Unbatched','U','S'), 
                    in_jobno, cskid.fromfacility, cskid.custid,l_lpid,'NEW',
                    l_sn, -2, l_dt);

        ORD := null;
        for cord in (select orderid, shipid, item, pieces, weight,
                            count(1) crtns
                      from skid_build
                      where buildno = in_buildno
                        and skidno = cskid.skidno
                      group by orderid, shipid, item, pieces, weight)
        loop
               insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity, weight)
                values (l_lpid, cord.orderid, cord.shipid, cord.item,
                        cord.pieces,
                        cord.crtns, cord.weight);

        -- If this is a new order add the multiship header record
                if nvl(ORD.orderid,0) != cord.orderid
                or nvl(ORD.shipid,0) != cord.shipid then
                    OPEN C_ORD(cord.orderid, cord.shipid);
                    FETCH C_ORD into ORD;
                    CLOSE C_ORD;
                    zmn.add_multishiphdr(ORD, null, errmsg);
                end if;

        -- Add the carton data for the carton labels
                for ix in 1..cord.crtns
                loop
                   zrf.get_next_lpid(l_ctnid, errmsg);
                   insert into load_flag_ctn (lpid, orderid, shipid, item,
                        pieces, cartonid, weight)
                    values (l_lpid, cord.orderid, cord.shipid, cord.item,
                            cord.pieces, l_ctnid, cord.weight);
        -- Add the multiship detail info even though there is no plates
                   ORL := null;
                   OPEN C_ORDDTL(ORD.orderid,ORD.shipid,
                        cord.item);
                   FETCH C_ORDDTL into ORL;
                   CLOSE C_ORDDTL;
                   insert into multishipdtl(
                       orderid,
                       shipid,
                       cartonid,
                       estweight,
                       status,
                       length,
                       width,
                       height,
                       dtlpassthruchar01,
                       dtlpassthruchar02,
                       dtlpassthruchar03,
                       dtlpassthruchar04,
                       dtlpassthruchar05,
                       dtlpassthruchar06,
                       dtlpassthruchar07,
                       dtlpassthruchar08,
                       dtlpassthruchar09,
                       dtlpassthruchar10,
                       dtlpassthruchar11,
                       dtlpassthruchar12,
                       dtlpassthruchar13,
                       dtlpassthruchar14,
                       dtlpassthruchar15,
                       dtlpassthruchar16,
                       dtlpassthruchar17,
                       dtlpassthruchar18,
                       dtlpassthruchar19,
                       dtlpassthruchar20,
                       dtlpassthrunum01,
                       dtlpassthrunum02,
                       dtlpassthrunum03,
                       dtlpassthrunum04,
                       dtlpassthrunum05,
                       dtlpassthrunum06,
                       dtlpassthrunum07,
                       dtlpassthrunum08,
                       dtlpassthrunum09,
                       dtlpassthrunum10,
                       dtlpassthrudate01,
                       dtlpassthrudate02,
                       dtlpassthrudate03,
                       dtlpassthrudate04,
                       dtlpassthrudoll01,
                       dtlpassthrudoll02
                   )
                   values (
                       ORD.orderid,
                       ORD.shipid,
                       l_ctnid,
                       nvl(cord.weight,0.1),
                       'READY',
                       zci.item_uom_length(ORD.custid,cord.item,'PCS'),
                       zci.item_uom_width(ORD.custid,cord.item,'PCS'),
                       zci.item_uom_height(ORD.custid,cord.item,'PCS'),
                       ORL.dtlpassthruchar01,
                       ORL.dtlpassthruchar02,
                       ORL.dtlpassthruchar03,
                       ORL.dtlpassthruchar04,
                       ORL.dtlpassthruchar05,
                       ORL.dtlpassthruchar06,
                       ORL.dtlpassthruchar07,
                       ORL.dtlpassthruchar08,
                       ORL.dtlpassthruchar09,
                       ORL.dtlpassthruchar10,
                       ORL.dtlpassthruchar11,
                       ORL.dtlpassthruchar12,
                       ORL.dtlpassthruchar13,
                       ORL.dtlpassthruchar14,
                       ORL.dtlpassthruchar15,
                       ORL.dtlpassthruchar16,
                       ORL.dtlpassthruchar17,
                       ORL.dtlpassthruchar18,
                       ORL.dtlpassthruchar19,
                       ORL.dtlpassthruchar20,
                       ORL.dtlpassthrunum01,
                       ORL.dtlpassthrunum02,
                       ORL.dtlpassthrunum03,
                       ORL.dtlpassthrunum04,
                       ORL.dtlpassthrunum05,
                       ORL.dtlpassthrunum06,
                       ORL.dtlpassthrunum07,
                       ORL.dtlpassthrunum08,
                       ORL.dtlpassthrunum09,
                       ORL.dtlpassthrunum10,
                       ORL.dtlpassthrudate01,
                       ORL.dtlpassthrudate02,
                       ORL.dtlpassthrudate03,
                       ORL.dtlpassthrudate04,
                       ORL.dtlpassthrudoll01,
                       ORL.dtlpassthrudoll02
                   );


                end loop;

        end loop;

    end loop;

    update load_flag_hdr
       set total_skid = l_sn
     where jobno = in_jobno
       and type = decode(in_type,'Unbatched','U','S')
       and total_skid = -2
       and created = l_dt;

    for cord in (select distinct orderid, shipid
                   from skid_build
                  where buildno = in_buildno)
    loop
        UPDATE alps.orderhdr
           SET orderstatus = '4'
         WHERE orderid = cord.orderid
           AND shipid = cord.shipid;

    end loop;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CCLF:'||sqlerrm;

END create_carton_load_flags_OLD;


----------------------------------------------------------------------
--
-- update_carton_skid - update carton number for skid
--
----------------------------------------------------------------------
PROCEDURE update_carton_skid
(
    in_buildno  number,
    in_orderid  number,
    in_shipid   number,
    in_carton   number,
    in_skid     number,
    out_errmsg  OUT varchar2
)
IS
BEGIN
    out_errmsg := 'OKAY';

    update skid_build
      set skidno = in_skid
     where buildno = in_buildno
      and orderid = in_orderid
      and shipid = in_shipid
      and cartonno = in_carton;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'UCS:'||sqlerrm;

END update_carton_skid;

----------------------------------------------------------------------
--
-- update_carton_weights - update carton weights by size
--
----------------------------------------------------------------------
PROCEDURE update_carton_weight
(
    in_buildno  number,
    in_item     varchar2,
    in_pieces   number,
    in_weight   number,
    out_errmsg  OUT varchar2
)
IS
BEGIN
    out_errmsg := 'OKAY';

    update skid_build
      set weight = in_weight
     where buildno = in_buildno
      and item = decode(in_item,'ALL',item,in_item)
      and pieces = decode(in_pieces,0,pieces,in_pieces);

EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'UCW:'||sqlerrm;

END update_carton_weight;



----------------------------------------------------------------------
--
-- plate_to_production
--
----------------------------------------------------------------------
PROCEDURE plate_to_production(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS
LP alps.plate%rowtype;
l_errmsg varchar2(255);

adjreason varchar2(12);
adjrowid1 varchar2(20);
adjrowid2 varchar2(20);

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    LP := null;
    OPEN C_PLT(in_lpid);
    FETCH C_PLT INTO LP;
    CLOSE C_PLT;

    if LP.lpid is null then
        out_errno := 1;
        out_errmsg := 'Plate does not exist';
        return;
    end if;


    adjreason := 'SP';

    zia.inventory_adjustment(lp.lpid, lp.custid, lp.item, lp.inventoryclass,
               lp.invstatus, lp.lotnumber, lp.serialnumber, lp.useritem1,
               lp.useritem2, lp.useritem3, lp.location, lp.expirationdate,
               0, lp.custid, lp.item, lp.inventoryclass, lp.invstatus,
               lp.lotnumber, lp.serialnumber, lp.useritem1, lp.useritem2,
               lp.useritem3, lp.location, lp.expirationdate, lp.quantity,
               lp.facility, adjreason, in_userid, 'SP', 0, lp.weight,
               lp.manufacturedate, lp.manufacturedate,
               lp.anvdate, lp.anvdate,
               adjrowid1, adjrowid2, out_errno, out_errmsg);


EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'PTP:'||sqlerrm;
END plate_to_production;


----------------------------------------------------------------------
--
-- receive_production_qty
--
----------------------------------------------------------------------
PROCEDURE receive_production_qty
(
    in_orderid  number,
    in_shipid   number,
    in_item   varchar2,
    in_qty   number,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS
new_status alps.orderhdr.orderstatus%type;

ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
ITM alps.custitemview%rowtype;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    new_status := 'A';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errno := 10;
        out_errmsg := 'Order '||in_orderid||'/'||in_shipid||' does not exist';
        return;
    end if;

    if ORD.ordertype <> 'P' then
        out_errno := 11;
        out_errmsg := 'Order '||in_orderid||'/'||in_shipid
                ||' is not a production order';
        return;
    end if;

    DTL := null;
    OPEN C_ORDDTL(ORD.orderid, ORD.shipid, in_item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        out_errno := 12;
        out_errmsg := 'Order Line: '||ORD.orderid||'/'||ORD.shipid||
            '/'||in_item||' not found';
        return;
    end if;



    ITM := NULL;
    OPEN C_CUSTITEMV(ORD.custid, in_item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;

    if ITM.custid is null then
        out_errno := 13;
        out_errmsg := 'Invalid item.';
        return;
    end if;



    update alps.orderdtl
       set qtyrcvd = nvl(qtyrcvd,0) + in_qty,
           weightrcvd = nvl(weightrcvd, 0) + (in_qty * ITM.weight),
           cubercvd = nvl(cubercvd, 0) + (in_qty * ITM.cube),
           amtrcvd = nvl(amtrcvd, 0) + (in_qty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           qtyrcvdgood = nvl(qtyrcvdgood,0) + in_qty,
           weightrcvdgood = nvl(weightrcvdgood, 0) + (in_qty * ITM.weight),
           cubercvdgood = nvl(cubercvdgood, 0) + (in_qty * ITM.cube),
           amtrcvdgood = nvl(amtrcvdgood, 0) + (in_qty * zci.item_amt(custid,orderid,shipid,item,lotnumber))
     where orderid = DTL.orderid
       and shipid = DTL.shipid
       and item = DTL.item
       and lotnumber is null;

    update alps.orderhdr
       set orderstatus = 'A'
     where orderid = ORD.orderid
       and shipid = ORD.shipid
       and orderstatus != 'A';



EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'RPQ:'||sqlerrm;
END;



----------------------------------------------------------------------
--
-- complete_production_order
--
----------------------------------------------------------------------
PROCEDURE complete_production_order(
    in_orderid  number,
    in_shipid   number,
    out_errmsg  OUT varchar2
)
IS
ORD alps.orderhdr%rowtype;

BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order '||in_orderid||'/'||in_shipid||' does not exist';
        return;
    end if;

    if ORD.ordertype <> 'P' then
        out_errmsg := 'Order '||in_orderid||'/'||in_shipid
                ||' is not a production order';
        return;
    end if;

    if ORD.orderstatus <> 'A' then
        out_errmsg := 'Order '||in_orderid||'/'||in_shipid
                ||' is not active';
        return;
    end if;


    update alps.orderhdr
       set orderstatus = 'R'
     where orderid = in_orderid
       and shipid = in_shipid;

EXCEPTION WHEN OTHERS THEN
    out_errmsg := sqlerrm;

END complete_production_order;




----------------------------------------------------------------------
--
-- receive_fg_over_plate - receive a finished goods overs plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_over_plate
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_jobno    varchar2,
    in_custid   varchar2,
    in_item     varchar2,
    in_qty      number,
    in_uom      varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT varchar2
)
IS

LOC alps.location%rowtype;

ORD alps.orderhdr%rowtype;

ITM alps.custitemview%rowtype;

qty alps.plate.quantity%type;

errmsg  varchar2(255);

PLT alps.plate%rowtype;

l_weight alps.plate.weight%type;

lptype alps.plate.type%type;
xrefid alps.plate.lpid%type;
xreftype alps.plate.type%type;
parentid alps.plate.lpid%type;
parenttype alps.plate.type%type;
topid alps.plate.lpid%type;
toptype alps.plate.type%type;
msg varchar(80);
errno number;

CD alps.cdata;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';


    ORD := null;
    OPEN C_ORD_JOB(in_custid, in_jobno);
    FETCH C_ORD_JOB into ORD;
    CLOSE C_ORD_JOB;

    if ORD.orderid is null then
        out_errno := 1;
        out_errmsg := 'Invalid production job.';
        return;
    end if;


    if in_facility != ORD.tofacility then
        out_errno := 8;
        out_errmsg := 'Invalid facility';
        return;
    end if;

    LOC := null;
    OPEN C_LOC(in_facility, in_location);
    FETCH C_LOC into LOC;
    CLOSE C_LOC;

    if LOC.locid is null then
        out_errno := 2;
        out_errmsg := 'Invalid location.';
        return;
    end if;

    if LOC.facility != ORD.tofacility then
        out_errno := 3;
        out_errmsg := 'Invalid facility.';
        return;
    end if;

    ITM := NULL;
    OPEN C_CUSTITEMV(in_custid, in_item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;

    if ITM.custid is null then
        out_errno := 4;
        out_errmsg := 'Invalid item.';
        return;
    end if;

    zbut.translate_uom(in_custid, in_item, in_qty,
           in_uom, ITM.baseuom, qty, errmsg);
    if substr(errmsg,1,4) != 'OKAY' then
        out_errno := 5;
        out_errmsg := errmsg;
        return;
    end if;

    if (not is_lpid(in_lpid)) then
      out_errno := 6;
      out_errmsg := 'Invalid LPID';
      return;
    end if;

    PLT := null;

    OPEN C_PLT(in_lpid);
    FETCH C_PLT into PLT;
    CLOSE C_PLT;

    if PLT.lpid = in_lpid then
        out_errno := 7;
        out_errmsg := 'LPID already exists';
        return;
    end if;


    zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);

    if lptype != '?' then
        out_errno := 7;
        out_errmsg := 'LPID already exists';
        return;
    end if;





-- add plate
   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem
   )
   VALUES
   (
      in_lpid,
      in_item,
      in_custid,
      in_facility,
      in_location,
      'A',-- status,
      ITM.baseuom,
      qty,
      'PA',
      in_jobno,
      sysdate,
      'AV',
      'RG',
      ORD.orderid,
      ORD.shipid,
      in_qty,
      in_item,
      in_uom,
      in_weight,
      in_userid,
      sysdate,
      in_facility,
      in_item
   );


  -- add asof inventory for the plate
  zbill.add_asof_inventory(
        in_facility,
        in_custid,
        in_item,
        null,
        ITM.baseuom,
        trunc(sysdate),
        qty,
        in_weight,
        'Received',
        'RC',
        'RG',
        'AV',
        ORD.orderid,
        ORD.shipid,
        in_lpid,
        in_userid,
        errmsg
     );

    receive_production_qty(ORD.orderid, ORD.shipid, in_item, qty,
        errno, errmsg);
    if errmsg != 'OKAY' then
        out_errno := errno;
        out_errmsg := errmsg;
        return;

    end if;

    if ORD.hdrpassthruchar10 = 'PECAS' then
        CD := zcus.init_cdata;
        CD.lpid := in_lpid;
        CD.char01 := ORD.reference;

        zpecas.prod_receipt(CD);
    end if;



EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'rwp:'||sqlerrm;

END receive_fg_over_plate;


----------------------------------------------------------------------
--
-- receive_wip_plate - receive a work in process plate
--
----------------------------------------------------------------------
PROCEDURE receive_wip_plate
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_jobno    varchar2,
    in_custid   varchar2,
    in_item     varchar2,
    in_qty      number,
    in_uom      varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT varchar2
)
IS

LOC alps.location%rowtype;

ORD alps.orderhdr%rowtype;

ITM alps.custitemview%rowtype;

qty alps.plate.quantity%type;

errmsg  varchar2(255);

PLT alps.plate%rowtype;

l_weight alps.plate.weight%type;

lptype alps.plate.type%type;
xrefid alps.plate.lpid%type;
xreftype alps.plate.type%type;
parentid alps.plate.lpid%type;
parenttype alps.plate.type%type;
topid alps.plate.lpid%type;
toptype alps.plate.type%type;
msg varchar(80);
errno number;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';


    ORD := null;
    OPEN C_ORD_JOB(in_custid, in_jobno);
    FETCH C_ORD_JOB into ORD;
    CLOSE C_ORD_JOB;

    if ORD.orderid is null then
        out_errno := 1;
        out_errmsg := 'Invalid production job.';
        return;
    end if;

    if in_facility != ORD.tofacility then
        out_errno := 8;
        out_errmsg := 'Invalid facility';
        return;
    end if;


    LOC := null;
    OPEN C_LOC(in_facility, in_location);
    FETCH C_LOC into LOC;
    CLOSE C_LOC;

    if LOC.locid is null then
        out_errno := 2;
        out_errmsg := 'Invalid location.';
        return;
    end if;

    if LOC.facility != ORD.tofacility then
        out_errno := 3;
        out_errmsg := 'Invalid facility.';
        return;
    end if;

    ITM := NULL;
    OPEN C_CUSTITEMV(in_custid, in_item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;

    if ITM.custid is null then
        out_errno := 4;
        out_errmsg := 'Invalid item.';
        return;
    end if;

    zbut.translate_uom(in_custid, in_item, in_qty,
           in_uom, ITM.baseuom, qty, errmsg);
    if substr(errmsg,1,4) != 'OKAY' then
        out_errno := 5;
        out_errmsg := errmsg;
        return;
    end if;

    if (not is_lpid(in_lpid)) then
      out_errno := 6;
      out_errmsg := 'Invalid LPID';
      return;
    end if;

    PLT := null;

    OPEN C_PLT(in_lpid);
    FETCH C_PLT into PLT;
    CLOSE C_PLT;

    if PLT.lpid = in_lpid then
        out_errno := 7;
        out_errmsg := 'LPID already exists';
        return;
    end if;


    zrf.identify_lp(in_lpid, lptype, xrefid, xreftype, parentid, parenttype,
         topid, toptype, msg);

    if lptype != '?' then
        out_errno := 7;
        out_errmsg := 'LPID already exists';
        return;
    end if;





-- add plate
   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem
   )
   VALUES
   (
      in_lpid,
      in_item,
      in_custid,
      in_facility,
      in_location,
      'A',-- status,
      ITM.baseuom,
      qty,
      'PA',
      in_jobno,
      sysdate,
      'AV',
      'RG',
      ORD.orderid,
      ORD.shipid,
      in_qty,
      in_item,
      in_uom,
      in_weight,
      in_userid,
      sysdate,
      in_facility,
      in_item
   );


  -- add asof inventory for the plate
  zbill.add_asof_inventory(
        in_facility,
        in_custid,
        in_item,
        null,
        ITM.baseuom,
        trunc(sysdate),
        in_qty,
        in_weight,
        'Received',
        'RC',
        'RG',
        'AV',
        ORD.orderid,
        ORD.shipid,
        in_lpid,
        in_userid,
        errmsg
     );



EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'rwp:'||sqlerrm;

END receive_wip_plate;


----------------------------------------------------------------------
--
-- putaway_plate
--
----------------------------------------------------------------------
PROCEDURE putaway_plate(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errno   OUT  number,
    out_errmsg  OUT varchar2
)
IS
LP alps.plate%rowtype;
l_errmsg varchar2(255);

l_fac varchar2(10);
l_loc varchar2(20);

CURSOR C_LOC(in_facility varchar2, in_location varchar2)
IS
SELECT loctype
  FROM alps.location
 WHERE facility = in_facility
   AND locid = in_location;

LOC C_LOC%rowtype;

CURSOR C_TSK(in_lpid varchar2, in_location varchar2)
IS
SELECT taskid
  FROM alps.tasks
 WHERE lpid = in_lpid
   AND fromloc = in_location;

TSK  C_TSK%rowtype;

l_code  varchar2(4);

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    LP := null;
    OPEN C_PLT(in_lpid);
    FETCH C_PLT INTO LP;
    CLOSE C_PLT;

    if LP.lpid is null then
        out_errmsg := 'Plate does not exist';
        return;
    end if;

    l_code := 'TANR';

    LOC := null;
    OPEN C_LOC(LP.facility, LP.location);
    FETCH C_LOC INTO LOC;
    CLOSE C_LOC;

    if LOC.loctype = 'XFER' then
        l_code := 'TARS';
    end if;

    zput.putaway_lp(l_code,in_lpid,LP.facility,LP.location,in_userid,
        'Y','FT',l_errmsg,l_fac,l_loc);


    if l_code = 'TARS' then
        TSK := null;
        OPEN C_TSK(LP.lpid, LP.location);
        FETCH C_TSK INTO TSK;
        CLOSE C_TSK;

        update alps.tasks
           set priority = '5'
         where taskid = TSK.taskid;

    end if;

    if l_errmsg is not null then
        out_errmsg := l_errmsg;
    end if;
EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := 'PP:'||sqlerrm;
END putaway_plate;


----------------------------------------------------------------------
--
-- copy_load_flag_dtl_wk - copies current load_flag_dtl table to work table
--
----------------------------------------------------------------------
PROCEDURE copy_load_flag_dtl_wk(
    in_lpid     IN  varchar2
)
IS
BEGIN

    delete from load_flag_dtl_wk
     where lpid = in_lpid;

    insert into load_flag_dtl_wk
    select * from load_flag_dtl
     where lpid = in_lpid;

END copy_load_flag_dtl_wk;

----------------------------------------------------------------------
--
-- clear_load_flag_dtl_wk - clears current load_flag_dtl work table
--
----------------------------------------------------------------------
PROCEDURE clear_load_flag_dtl_wk(
    in_lpid     IN  varchar2
)
IS
BEGIN
    delete from load_flag_dtl_wk
     where lpid = in_lpid;

END clear_load_flag_dtl_wk;

----------------------------------------------------------------------
--
-- update_load_flag_dtl_wk - copies current load_flag_dtl_wk table to
--          actual load_flag_dtl table
--
----------------------------------------------------------------------
PROCEDURE update_load_flag_dtl_wk(
    in_lpid     IN  varchar2
)
IS
BEGIN
    delete from load_flag_dtl
     where lpid = in_lpid;

    insert into load_flag_dtl
    select * from load_flag_dtl_wk
     where lpid = in_lpid;

END update_load_flag_dtl_wk;


----------------------------------------------------------------------
--
-- update_LFD_entry - update new values for a single LFD work entry
--
----------------------------------------------------------------------
PROCEDURE update_LFD_entry
(
    in_lpid     IN  varchar2,
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_item     IN  varchar2,
    in_orig_pieces  IN  varchar2,
    in_pieces   IN  number,
    in_quantity IN  number,
    in_weight   IN  number,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS

CURSOR C_LFD(in_lpid varchar2,
             in_orderid number,
             in_shipid number,
             in_item varchar2,
             in_pieces number)
IS
SELECT rowid, L.*
  FROM load_flag_dtl_wk L
 WHERE lpid = in_lpid
   AND orderid = in_orderid
   AND shipid = in_shipid
   AND item = in_item
   AND pieces = in_pieces;

LFD C_LFD%rowtype;
NLFD C_LFD%rowtype;
BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';

    LFD := null;
    OPEN C_LFD(in_lpid, in_orderid, in_shipid, in_item, in_orig_pieces);
    FETCH C_LFD into LFD;
    CLOSE C_LFD;


    if lfd.lpid is null and in_orig_pieces > 0 then
        out_errno := 1;
        out_errmsg := 'Invalid carton set';
        return;
    end if;

    NLFD := null;
    if in_pieces != in_orig_pieces then
        OPEN C_LFD(in_lpid, in_orderid, in_shipid, in_item, in_pieces);
        FETCH C_LFD into NLFD;
        CLOSE C_LFD;
    end if;


   if in_quantity = 0 or in_pieces = 0 then
        delete from load_flag_dtl_wk
         where rowid = LFD.rowid;
        return;
    end if;


    if NLFD.lpid is null then
      if LFD.lpid is null then
        insert into load_flag_dtl_wk (lpid, orderid, shipid, item, pieces,
                    quantity, weight)
        values (in_lpid, in_orderid, in_shipid, in_item, in_pieces,
                        in_quantity, in_weight);

      else
        update load_flag_dtl_wk
           set pieces = in_pieces,
               quantity = in_quantity,
               weight = in_weight
         where rowid = LFD.rowid;
      end if;
      return;
    end if;

    delete from load_flag_dtl_wk
     where rowid = LFD.rowid;

    update load_flag_dtl_wk
       set quantity = quantity + in_quantity,
           weight = in_weight
     where rowid = NLFD.rowid;



EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := sqlerrm;

END update_LFD_entry;


----------------------------------------------------------------------
--
-- receive_fg_small_pkg - receive a finished goods load flagged plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_small_pkg
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS

CURSOR C_LFH(in_lpid varchar2)
IS
SELECT H.type, H.jobno, H.facility, H.custid, H.lpid, H.status,
       sum(D.pieces*D.quantity) pieces
  FROM load_flag_hdr H, load_flag_dtl D
 WHERE H.lpid = in_lpid
   AND H.lpid = D.lpid
  GROUP by H.type, H.jobno, H.facility, H.custid, H.lpid, H.status;

cnt integer;
CURSOR C_LFD(in_lpid varchar2)
IS
SELECT H.custid, H.jobno, H.lpid, D.orderid, D.shipid, D.item,
    D.pieces, D.quantity, D.weight
  FROM load_flag_dtl D, load_flag_hdr H
 WHERE H.lpid = in_lpid
   AND H.lpid = D.lpid;

slip alps.shippingplate.lpid%type := null;

clip alps.shippingplate.lpid%type := null;

c_lpid alps.plate.lpid%type := null;

errmsg varchar2(255);


CURSOR curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         loctype,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from alps.location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;


CURSOR C_STAGELOC(in_lpid varchar2)
IS
select C.carrier, C.facility, C.stageloc
from alps.carrierstageloc C, load_flag_dtl D, alps.orderhdr O
where D.lpid = in_lpid
and O.orderid = D.orderid
and O.shipid = D.shipid
and C.facility = O.fromfacility
and C.carrier = O.carrier
and C.shiptype = 'S';

STGLOC C_STAGELOC%rowtype;

LFH C_LFH%rowtype;

PORD alps.orderhdr%rowtype;
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
TK  alps.tasks%rowtype;
ITM alps.custitemview%rowtype;

new_status alps.orderhdr.orderstatus%type;
CD alps.cdata;
errno number;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';


    LFH := null;
    OPEN C_LFH(in_lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;
    if LFH.lpid is null then
        out_errno := 5;
        out_errmsg := 'Invalid Load Flag ID';
        return;
    end if;

    if LFH.type not in ('S','U') then -- Small Package type
        out_errno := 6;
        out_errmsg := 'Not small package type load';
        return;
    end if;


    if in_facility != LFH.facility then
        out_errno := 8;
        out_errmsg := 'Invalid facility';
        return;
    end if;

    if LFH.status = 'RECEIVED' then
        out_errno := 7;
        out_errmsg := 'Plate has already been received.';
        return;
    end if;


-- Create the load flagged plate multi-pallet and the master shippingplate
    ORD := null;

-- add multiplate for the sub-plates
   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem
   )
   VALUES
   (
      in_lpid,
      null,
      LFH.custid,
      in_facility,
      in_location,
      'P',-- status,
      ITM.baseuom,
      0,
      'MP',
      LFH.jobno,
      sysdate,
      'AV',
      'RG',
      PORD.orderid,
      PORD.shipid,
      LFH.pieces,
      null,
      'PCS',
      in_weight,
      in_userid,
      sysdate,
      in_facility,
      null
   );




-- Now create a shipping plate for it
    zsp.get_next_shippinglpid(slip, errmsg);
    if errmsg is not null then
       out_errno := 4;
       out_errmsg := errmsg;
       return;
    end if;

    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          unitofmeasure,invstatus, inventoryclass,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          fromlpid, pickuom, pickqty)
    values
         (slip, in_facility, in_location, 'P', 0, 'M',
          'PCS', 'AV','RG',
          in_userid, sysdate, in_weight, null, LFH.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, 0, 0,
          in_lpid, 'PCS', 0);


--    zut.prt('LFH:'||LFH.lpid);

-- Now we need to create the pick task and subtask for the plate
--  or if not stagable to send it to storage.

    TK := null;
    TK.picktotype := 'PAL';
    TK.priority := '3';     -- Normal Priority
    TK.tasktype := 'PK';
    TK.cartontype := 'NONE';
    TK.cartonseq := null;
    ztsk.get_next_taskid(TK.taskid,errmsg);


-- Find Small Pacakge stage location
    STGLOC := null;
    OPEN C_STAGELOC(in_lpid);
    FETCH C_STAGELOC into STGLOC;
    CLOSE C_STAGELOC;

    TK.toloc := STGLOC.stageloc;

    TK.fromloc := in_location;
    TK.pickuom := ITM.baseuom;
    TK.pickqty := LFH.pieces;

    fromloc := null;
    open curLocation(in_facility,TK.fromloc);
    fetch curLocation into fromloc;
    close curLocation;
    toloc := null;
    open curLocation(in_facility,TK.toloc);
    fetch curLocation into toloc;
    close curLocation;

    if fromloc.loctype = 'XFR' then
        TK.priority := '5';     --Suspended Priority
    end if;

    insert into alps.tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, step1_complete)
      values
      (TK.taskid, TK.tasktype, in_facility, fromloc.section,TK.fromloc,
       fromloc.equipprof,toloc.section,TK.toloc,toloc.equipprof,null,
       LFH.custid,ITM.item,in_lpid,ITM.baseuom,0,
       fromloc.pickingseq,ORD.loadno,ORD.stopno,ORD.shipno,
       ORD.orderid,ORD.shipid,DTL.item,DTL.lotnumber,
       TK.priority,TK.priority,null,'PRODPICK',sysdate,
       TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zci.item_cube(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zlb.staff_hours(in_facility,LFH.custid,ITM.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),'Y');
    insert into alps.subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup, step1_complete)
      values
      (TK.taskid,TK.tasktype,in_facility,
       fromloc.section,TK.fromloc,fromloc.equipprof,toloc.section,
       TK.toloc,toloc.equipprof,null,LFH.custid,ITM.item,in_lpid,
       ITM.Baseuom,0,fromloc.pickingseq,ORD.loadno,
       ORD.stopno,ORD.shipno,ORD.orderid,ORD.shipid,DTL.item,
       DTL.lotnumber,TK.priority,TK.priority,null,'PRODPICK',
       sysdate,TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zci.item_cube(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zlb.staff_hours(in_facility,LFH.custid,ITM.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),TK.cartonseq,
       slip, 'F', zwv.cartontype_group(TK.cartontype),'Y');


    update alps.shippingplate
       set taskid = TK.taskid
     where lpid in (select lpid from alps.shippingplate
     							start with lpid = slip
                        connect by prior lpid = parentlpid);
--    where lpid = slip;

--    update alps.plate
--       set qtytasked = nvl(qtytasked,0) + LFH.pieces
--     where lpid = in_lpid
--       and parentfacility is not null;

    update load_flag_hdr
       set status = 'RECEIVED'
     where lpid = in_lpid;


EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := sqlerrm;

END receive_fg_small_pkg;


----------------------------------------------------------------------
--
-- receive_fg_small_pkg_old - receive a finished goods load flagged plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_small_pkg_old
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS

CURSOR C_LFH(in_lpid varchar2)
IS
SELECT H.type, H.jobno, H.facility, H.custid, H.lpid,
       sum(D.pieces*D.quantity) pieces
  FROM load_flag_hdr H, load_flag_dtl D
 WHERE H.lpid = in_lpid
   AND H.lpid = D.lpid
  GROUP by H.type, H.jobno, H.facility, H.custid, H.lpid;

cnt integer;
CURSOR C_LFD(in_lpid varchar2)
IS
SELECT H.custid, H.jobno, H.lpid, D.orderid, D.shipid, D.item,
    D.pieces, D.quantity, D.weight
  FROM load_flag_dtl D, load_flag_hdr H
 WHERE H.lpid = in_lpid
   AND H.lpid = D.lpid;

slip alps.shippingplate.lpid%type := null;

clip alps.shippingplate.lpid%type := null;

c_lpid alps.plate.lpid%type := null;

errmsg varchar2(255);


CURSOR curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         loctype,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from alps.location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;


CURSOR C_STAGELOC(in_lpid varchar2)
IS
select C.carrier, C.facility, C.stageloc
from alps.carrierstageloc C, load_flag_dtl D, alps.orderhdr O
where D.lpid = in_lpid
and O.orderid = D.orderid
and O.shipid = D.shipid
and C.facility = O.fromfacility
and C.carrier = O.carrier
and C.shiptype = 'S';

STGLOC C_STAGELOC%rowtype;

LFH C_LFH%rowtype;

PORD alps.orderhdr%rowtype;
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
TK  alps.tasks%rowtype;
ITM alps.custitemview%rowtype;

new_status alps.orderhdr.orderstatus%type;
CD alps.cdata;
errno number;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';


    LFH := null;
    OPEN C_LFH(in_lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;
    if LFH.lpid is null then
        out_errno := 5;
        out_errmsg := 'Invalid Load Flag ID';
        return;
    end if;

    if LFH.type != 'S' then -- Small Package type
        out_errno := 6;
        out_errmsg := 'Not small package type load';
        return;
    end if;


    if in_facility != LFH.facility then
        out_errno := 8;
        out_errmsg := 'Invalid facility';
        return;
    end if;


-- Create the load flagged plate multi-pallet and the master shippingplate
    ORD := null;

-- add multiplate for the sub-plates
   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem
   )
   VALUES
   (
      in_lpid,
      null,
      LFH.custid,
      in_facility,
      in_location,
      'P',-- status,
      ITM.baseuom,
      LFH.pieces,
      'MP',
      LFH.jobno,
      sysdate,
      'AV',
      'RG',
      PORD.orderid,
      PORD.shipid,
      LFH.pieces,
      null,
      'PCS',
      in_weight,
      in_userid,
      sysdate,
      in_facility,
      null
   );



-- Now create a shipping plate for it
    zsp.get_next_shippinglpid(slip, errmsg);
    if errmsg is not null then
       out_errno := 4;
       out_errmsg := errmsg;
       return;
    end if;

    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          unitofmeasure,invstatus, inventoryclass,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          fromlpid, pickuom, pickqty)
    values
         (slip, in_facility, in_location, 'P', LFH.pieces, 'M',
          'PCS', 'AV','RG',
          in_userid, sysdate, in_weight, null, LFH.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, 0, 0,
          in_lpid, 'PCS', LFH.pieces);


--    zut.prt('LFH:'||LFH.lpid);



    for LFD in C_LFD(in_lpid)
    loop

     for ix in 1..LFD.quantity
     loop
        ORD := null;
        OPEN C_ORD(LFD.orderid, LFD.shipid);
        FETCH C_ORD into ORD;
        CLOSE C_ORD;

        if ORD.orderid is null then
            out_errno := 2;
            out_errmsg := 'Order: '||LFD.orderid
                    ||'/'||LFD.shipid||' not found';
            return;
        end if;


        PORD := null;
        OPEN C_ORD_JOB(LFD.custid, LFD.jobno);
        FETCH C_ORD_JOB into PORD;
        CLOSE C_ORD_JOB;


        new_status := zrf.ord_picking;

        DTL := null;
        OPEN C_ORDDTL(LFD.orderid, LFD.shipid, LFD.item);
        FETCH C_ORDDTL into DTL;
        CLOSE C_ORDDTL;

        if DTL.orderid is null then
            out_errno := 3;
            out_errmsg := 'Order Line: '||LFD.orderid||'/'||LFD.shipid||
                '/'||LFD.item||' not found';
            return;
        end if;

        ITM := NULL;
        OPEN C_CUSTITEMV(LFD.custid, LFD.item);
        FETCH C_CUSTITEMV into ITM;
        CLOSE C_CUSTITEMV;


    -- add plate
       zrf.get_next_lpid(c_lpid, errmsg);
       zsp.get_next_shippinglpid(clip, errmsg);
       if errmsg is not null then
           out_errno := 4;
           out_errmsg := errmsg;
           return;
       end if;

       INSERT INTO ALPS.PLATE
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
          useritem1,
          creationdate,
          invstatus,
          inventoryclass,
          orderid,
          shipid,
          qtyentered,
          itementered,
          uomentered,
          weight,
          lastuser,
          lastupdate,
          parentfacility,
          parentitem,
          parentlpid,
          fromshippinglpid
       )
       VALUES
       (
          c_lpid,
          LFD.item,
          LFD.custid,
          in_facility,
          in_location,
          'P',-- status,
          ITM.baseuom,
          LFD.pieces,
          'PA',
          LFD.jobno,
          sysdate,
          'AV',
          'RG',
          PORD.orderid,
          PORD.shipid,
          LFD.pieces,
          LFD.item,
          'PCS',
          in_weight,
          in_userid,
          sysdate,
          in_facility,
          LFD.item,
          in_lpid,
          clip
       );

    -- Create the load_flag_ctn entry so we know this is stuff to
    --      export to the small package system

        insert into load_flag_ctn (lpid, orderid, shipid, item,
               pieces, cartonid, weight)
        values (in_lpid, LFD.orderid, LFD.shipid, LFD.item,
                LFD.pieces, c_lpid, LFD.weight);


    -- Now create a shipping plate for it

        insert into alps.shippingplate
             (lpid, facility, location, status, quantity, type,
              unitofmeasure,invstatus, inventoryclass,
              lastuser, lastupdate, weight, item, custid,
              loadno, stopno, shipno, orderid, shipid,
              orderitem, orderlot,
              fromlpid, pickuom, pickqty, parentlpid)
        values
             (clip, in_facility, in_location, 'P', LFD.pieces, 'F',
              ITM.baseuom, 'AV','RG',
              in_userid, sysdate, in_weight, LFD.item, LFD.custid,
              ORD.loadno, ORD.stopno, ORD.shipno, ORD.orderid, ORD.shipid,
              LFD.item, null,
              c_lpid, ITM.baseuom, LFD.pieces, slip);


      -- add asof inventory for the plate
      zbill.add_asof_inventory(
            in_facility,
            LFD.custid,
            LFD.item,
            null,
            ITM.baseuom,
            trunc(sysdate),
            LFD.pieces,
            in_weight,
            'Received',
            'RC',
            'RG',
            'AV',
            PORD.orderid,
            PORD.shipid,
            in_lpid,
            in_userid,
            errmsg
         );


        receive_production_qty(PORD.orderid, PORD.shipid, LFD.item, LFD.pieces,
            errno, errmsg);
        if errmsg != 'OKAY' then
            out_errno := errno;
            out_errmsg := errmsg;
            return;

        end if;

        if PORD.hdrpassthruchar10 = 'PECAS' then
            CD := zcus.init_cdata;
            CD.lpid := c_lpid;
            CD.char01 := PORD.reference;

            zpecas.prod_receipt(CD);
        end if;

    -- Update the order information
        UPDATE alps.orderdtl
           SET qtypick = nvl(qtypick, 0) + LFD.pieces,
               weightpick = nvl(weightpick, 0) + (LFD.pieces * ITM.weight),
               cubepick = nvl(cubepick, 0) + (LFD.pieces * ITM.cube),
               amtpick = nvl(amtpick, 0) + (LFD.pieces * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
               lastuser = in_userid,
               lastupdate = sysdate
         WHERE orderid = LFD.orderid
           AND shipid = LFD.shipid
           AND item = LFD.item
           AND nvl(lotnumber, '(none)') = '(none)';

        if ORD.qtypick + LFD.pieces > ORD.qtyorder then
            new_status := zrf.ORD_PICKED;

        end if;

        if new_status > ORD.orderstatus then

            update alps.orderhdr
               set orderstatus = new_status,
                   lastuser = in_userid,
                   lastupdate = sysdate
             where orderid = LFD.orderid
               and shipid = LFD.shipid;
        end if;

        zoh.add_orderhistory_item(LFD.orderid, LFD.shipid,
               in_lpid, LFD.item, null,
                'Pick Plate',
                'Pick Qty:'||LFD.pieces||' from Production',
                in_userid, errmsg);

      end loop;
    end loop;


-- Now we need to create the pick task and subtask for the plate
--  or if not stagable to send it to storage.

    TK := null;
    TK.picktotype := 'PAL';
    TK.priority := '3';     -- Normal Priority
    TK.tasktype := 'PK';
    TK.cartontype := 'NONE';
    TK.cartonseq := null;
    ztsk.get_next_taskid(TK.taskid,errmsg);


-- Find Small Pacakge stage location
    STGLOC := null;
    OPEN C_STAGELOC(in_lpid);
    FETCH C_STAGELOC into STGLOC;
    CLOSE C_STAGELOC;

    TK.toloc := STGLOC.stageloc;

    TK.fromloc := in_location;
    TK.pickuom := ITM.baseuom;
    TK.pickqty := LFH.pieces;

    fromloc := null;
    open curLocation(in_facility,TK.fromloc);
    fetch curLocation into fromloc;
    close curLocation;
    toloc := null;
    open curLocation(in_facility,TK.toloc);
    fetch curLocation into toloc;
    close curLocation;

    if fromloc.loctype = 'XFR' then
        TK.priority := '5';     --Suspended Priority
    end if;

    insert into alps.tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, step1_complete)
      values
      (TK.taskid, TK.tasktype, in_facility, fromloc.section,TK.fromloc,
       fromloc.equipprof,toloc.section,TK.toloc,toloc.equipprof,null,
       LFH.custid,ITM.item,in_lpid,ITM.baseuom,LFH.pieces,
       fromloc.pickingseq,ORD.loadno,ORD.stopno,ORD.shipno,
       ORD.orderid,ORD.shipid,DTL.item,DTL.lotnumber,
       TK.priority,TK.priority,null,'PRODPICK',sysdate,
       TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zci.item_cube(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zlb.staff_hours(in_facility,LFH.custid,ITM.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),'Y');
    insert into alps.subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup, step1_complete)
      values
      (TK.taskid,TK.tasktype,in_facility,
       fromloc.section,TK.fromloc,fromloc.equipprof,toloc.section,
       TK.toloc,toloc.equipprof,null,LFH.custid,ITM.item,in_lpid,
       ITM.Baseuom,LFH.pieces,fromloc.pickingseq,ORD.loadno,
       ORD.stopno,ORD.shipno,ORD.orderid,ORD.shipid,DTL.item,
       DTL.lotnumber,TK.priority,TK.priority,null,'PRODPICK',
       sysdate,TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zci.item_cube(LFH.custid,ITM.item,ITM.Baseuom) * LFH.pieces,
       zlb.staff_hours(in_facility,LFH.custid,ITM.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),TK.cartonseq,
       clip, 'F', zwv.cartontype_group(TK.cartontype),'Y');


    update alps.shippingplate
       set taskid = TK.taskid
     where lpid in (select lpid from alps.shippingplate
     							start with lpid = slip
                        connect by prior lpid = parentlpid);
--    where lpid = slip;

--    update alps.plate
--       set qtytasked = nvl(qtytasked,0) + LFH.pieces
--     where lpid = in_lpid
--       and parentfacility is not null;

    update load_flag_hdr
       set status = 'RECEIVED'
     where lpid = in_lpid;


EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := sqlerrm;

END receive_fg_small_pkg_old;


----------------------------------------------------------------------
--
-- receive_fg_load_flag - receive a finished goods load flagged plate
--
----------------------------------------------------------------------
PROCEDURE receive_fg_load_flag
(
    in_facility varchar2,
    in_location varchar2,
    in_lpid     varchar2,
    in_weight   number,
    in_userid     varchar2,
    out_errno   OUT number,
    out_errmsg  OUT varchar2
)
IS

cnt integer;
CURSOR C_LFD(in_lpid varchar2)
IS
SELECT H.custid, H.jobno, H.lpid, D.orderid, D.shipid, D.item,
    sum(pieces * quantity) qty
  FROM load_flag_dtl D, load_flag_hdr H
 WHERE H.lpid = in_lpid
   AND H.lpid = D.lpid
GROUP BY H.custid, H.jobno, H.lpid, D.orderid, D.shipid, D.item;

  clip alps.shippingplate.lpid%type := null;
errmsg varchar2(255);


CURSOR curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         loctype,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from alps.location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;


LFH load_flag_hdr%rowtype;

LFD C_LFD%rowtype;
PORD alps.orderhdr%rowtype;
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
TK  alps.tasks%rowtype;
ITM alps.custitemview%rowtype;

new_status alps.orderhdr.orderstatus%type;
CD alps.cdata;
errno number;

BEGIN
    out_errno := 0;
    out_errmsg := 'OKAY';


    LFH := null;
    OPEN C_LFH(in_lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;
    if LFH.lpid is null then
        out_errno := 5;
        out_errmsg := 'Invalid Load Flag ID';
        return;
    end if;

    if LFH.type in ('S','U') then -- Small Package and Unbatched Small Package
        receive_fg_small_pkg(in_facility, in_location,
                in_lpid, in_weight, in_userid,
                out_errno, out_errmsg);
        return;
    end if;

    -- This is for type 'D'estination and 'M'ail List
    cnt := 0;

    select count(distinct orderid||'/'||shipid||'/'||item)
      into cnt
      from load_flag_dtl
     where lpid = in_lpid;

    if cnt > 1 then
        out_errno := 1;
        out_errmsg := 'Only one order/item allowed';
        return;
    end if;


    if in_facility != LFH.facility then
        out_errno := 8;
        out_errmsg := 'Invalid facility';
        return;
    end if;


    LFD := null;
    OPEN C_LFD(in_lpid);
    FETCH C_LFD into LFD;
    CLOSE C_LFD;

    -- zut.prt('LFD:'||LFD.lpid);

    ORD := null;
    OPEN C_ORD(LFD.orderid, LFD.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errno := 2;
        out_errmsg := 'Order: '||LFD.orderid||'/'||LFD.shipid||' not found';
        return;
    end if;


    PORD := null;
    OPEN C_ORD_JOB(LFD.custid, LFD.jobno);
    FETCH C_ORD_JOB into PORD;
    CLOSE C_ORD_JOB;


    new_status := zrf.ord_picking;


    DTL := null;
    OPEN C_ORDDTL(LFD.orderid, LFD.shipid, LFD.item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        out_errno := 3;
        out_errmsg := 'Order Line: '||LFD.orderid||'/'||LFD.shipid||
            '/'||LFD.item||' not found';
        return;
    end if;

    ITM := NULL;
    OPEN C_CUSTITEMV(LFD.custid, LFD.item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;



-- add plate
   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem
   )
   VALUES
   (
      in_lpid,
      LFD.item,
      LFD.custid,
      in_facility,
      in_location,
      'P',-- status,
      ITM.baseuom,
      LFD.qty,
      'PA',
      LFD.jobno,
      sysdate,
      'AV',
      'RG',
      PORD.orderid,
      PORD.shipid,
      LFD.qty,
      LFD.item,
      'PCS',
      in_weight,
      in_userid,
      sysdate,
      in_facility,
      LFD.item
   );

-- Now create a shipping plate for it
    zsp.get_next_shippinglpid(clip, errmsg);
    if errmsg is not null then
       out_errno := 4;
       out_errmsg := errmsg;
       return;
    end if;


    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          unitofmeasure,invstatus, inventoryclass,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          orderitem, orderlot,
          fromlpid, pickuom, pickqty)
    values
         (clip, in_facility, in_location, 'P', LFD.qty, 'F',
          ITM.baseuom, 'AV','RG',
          in_userid, sysdate, in_weight, LFD.item, LFD.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, ORD.orderid, ORD.shipid,
          LFD.item, null,
          in_lpid, ITM.baseuom, LFD.qty);


  -- add asof inventory for the plate
  zbill.add_asof_inventory(
        in_facility,
        LFD.custid,
        LFD.item,
        null,
        ITM.baseuom,
        trunc(sysdate),
        LFD.qty,
        in_weight,
        'Received',
        'RC',
        'RG',
        'AV',
        PORD.orderid,
        PORD.shipid,
        in_lpid,
        in_userid,
        errmsg
     );


    receive_production_qty(PORD.orderid, PORD.shipid, LFD.item, LFD.qty,
        errno, errmsg);
    if errmsg != 'OKAY' then
        out_errno := errno;
        out_errmsg := errmsg;
        return;

    end if;

    if PORD.hdrpassthruchar10 = 'PECAS' then
        CD := zcus.init_cdata;
        CD.lpid := in_lpid;
        CD.char01 := PORD.reference;

        zpecas.prod_receipt(CD);
    end if;


-- Update the order information
    UPDATE alps.orderdtl
       SET qtypick = nvl(qtypick, 0) + LFD.qty,
           weightpick = nvl(weightpick, 0) + (LFD.qty * ITM.weight),
           cubepick = nvl(cubepick, 0) + (LFD.qty * ITM.cube),
           amtpick = nvl(amtpick, 0) + (LFD.qty * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = in_userid,
           lastupdate = sysdate
     WHERE orderid = LFD.orderid
       AND shipid = LFD.shipid
       AND item = LFD.item
       AND nvl(lotnumber, '(none)') = '(none)';

    if ORD.qtypick + LFD.qty > ORD.qtyorder then
        new_status := zrf.ORD_PICKED;

    end if;

    if new_status > ORD.orderstatus then

        update alps.orderhdr
           set orderstatus = new_status,
               lastuser = in_userid,
               lastupdate = sysdate
         where orderid = LFD.orderid
           and shipid = LFD.shipid;
    end if;

    zoh.add_orderhistory_item(LFD.orderid, LFD.shipid,
           in_lpid, LFD.item, null,
            'Pick Plate',
            'Pick Qty:'||LFD.qty||' from Production',
            in_userid, errmsg);


    update load_flag_hdr
       set status = 'RECEIVED'
     where lpid = in_lpid;

-- Now we need to create the pick task and subtask for the plate
--  or if not stagable to send it to storage.

    TK := null;
    TK.picktotype := 'PAL';
    TK.priority := '3';     -- Normal Priority
    TK.tasktype := 'PK';
    TK.cartontype := 'NONE';
    TK.cartonseq := null;
    ztsk.get_next_taskid(TK.taskid,errmsg);

    if ORD.stageloc is null then
      begin
        select loadstopstageloc
          into TK.toloc
          from alps.loadsorderview
         where orderid = ORD.orderid
           and shipid = ORD.shipid;
      exception when others then
        TK.toloc := null;
      end;
    else
      TK.toloc := ORD.stageloc;
    end if;



    if TK.toloc is null then
        out_errmsg := 'OKAY:PUTAWAY';
        out_errno := 100;
        return;
    end if;

    TK.fromloc := in_location;
    TK.pickuom := ITM.baseuom;
    TK.pickqty := LFD.qty;

    fromloc := null;
    open curLocation(in_facility,TK.fromloc);
    fetch curLocation into fromloc;
    close curLocation;
    toloc := null;
    open curLocation(in_facility,TK.toloc);
    fetch curLocation into toloc;
    close curLocation;
    if fromloc.loctype = 'XFR' then
        TK.priority := '5';     --Suspended Priority
    end if;

    insert into alps.tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, step1_complete)
      values
      (TK.taskid, TK.tasktype, in_facility, fromloc.section,TK.fromloc,
       fromloc.equipprof,toloc.section,TK.toloc,toloc.equipprof,null,
       LFD.custid,LFD.item,in_lpid,ITM.baseuom,LFD.qty,
       fromloc.pickingseq,ORD.loadno,ORD.stopno,ORD.shipno,
       ORD.orderid,ORD.shipid,DTL.item,DTL.lotnumber,
       TK.priority,TK.priority,null,'PRODPICK',sysdate,
       TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFD.custid,LFD.item,ITM.Baseuom) * LFD.qty,
       zci.item_cube(LFD.custid,LFD.item,ITM.Baseuom) * LFD.qty,
       zlb.staff_hours(in_facility,LFD.custid,LFD.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),'Y');
    insert into alps.subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup, step1_complete)
      values
      (TK.taskid,TK.tasktype,in_facility,
       fromloc.section,TK.fromloc,fromloc.equipprof,toloc.section,
       TK.toloc,toloc.equipprof,null,LFD.custid,LFD.item,in_lpid,
       ITM.Baseuom,LFD.qty,fromloc.pickingseq,ORD.loadno,
       ORD.stopno,ORD.shipno,ORD.orderid,ORD.shipid,DTL.item,
       DTL.lotnumber,TK.priority,TK.priority,null,'PRODPICK',
       sysdate,TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LFD.custid,LFD.item,ITM.Baseuom) * LFD.qty,
       zci.item_cube(LFD.custid,LFD.item,ITM.Baseuom) * LFD.qty,
       zlb.staff_hours(in_facility,LFD.custid,LFD.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),TK.cartonseq,
       clip, 'F', zwv.cartontype_group(TK.cartontype),'Y');


    update alps.shippingplate
       set taskid = TK.taskid
     where lpid = clip;

--    update alps.plate
--       set qtytasked = nvl(qtytasked,0) + LFD.qty
--     where lpid = in_lpid
--       and parentfacility is not null;


EXCEPTION WHEN OTHERS THEN
    out_errno := sqlcode;
    out_errmsg := sqlerrm;

END receive_fg_load_flag;


----------------------------------------------------------------------
--
-- fetch_picked_inventory
--
----------------------------------------------------------------------
PROCEDURE fetch_picked_inventory
(
    in_orderid  varchar2,
    in_shipid   varchar2,
    out_errmsg  OUT varchar2
)
IS

CURSOR curLocation(in_facility varchar2,in_locid varchar2) is
  select section,
         equipprof,
         pickingzone,
         nvl(pickingseq,0) as pickingseq
    from alps.location
   where facility = in_facility
     and locid = in_locid;
fromloc curLocation%rowtype;
toloc curLocation%rowtype;


ORD alps.orderhdr%rowtype;
TK  alps.tasks%rowtype;
LP  alps.plate%rowtype;
ITM alps.custitemview%rowtype;
cnt integer;

errmsg varchar2(255);

BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order: '||in_orderid||'/'||in_shipid||' not found';
        return;
    end if;


    if ORD.stageloc is null then
      begin
        select loadstopstageloc
          into ORD.stageloc
          from alps.loadsorderview
         where orderid = ORD.orderid
           and shipid = ORD.shipid;
      exception when others then
        ORD.stageloc := null;
      end;
    end if;

-- Find potential candidates
    for crec in (select lpid, fromlpid, S.location
                   from alps.shippingplate S, alps.location L
                  where S.orderid = ORD.orderid
                    and S.shipid = ORD.shipid
                    and S.status = 'P'
                    and S.type = 'F'
                    and S.facility = L.facility
                    and S.location = L.locid
                    and L.loctype = 'STO')
    loop
        -- zut.prt('Found plate:'||crec.fromlpid||' StageLoc:'||
        --    ORD.stageloc);

        -- Check if task already exists

        select count(1)
          into cnt
          from alps.tasks
         where lpid = crec.fromlpid;

        if cnt > 0 then
            -- zut.prt('Task for lpid already exists');
            goto continue;
        end if;

        LP := null;
        OPEN C_PLT(crec.fromlpid);
        FETCH C_PLT INTO LP;
        CLOSE C_PLT;

        ITM := NULL;
        OPEN C_CUSTITEMV(LP.custid, LP.item);
        FETCH C_CUSTITEMV into ITM;
        CLOSE C_CUSTITEMV;


        TK := null;


        TK.picktotype := 'PAL';
        TK.priority := '3';     --Normal Priority
        TK.tasktype := 'PK';
        TK.cartontype := 'NONE';
        TK.cartonseq := null;
        ztsk.get_next_taskid(TK.taskid,errmsg);

        TK.toloc := ORD.stageloc;

        TK.fromloc := crec.location;
        TK.pickuom := ITM.baseuom;
        TK.pickqty := LP.quantity;

    fromloc := null;
    open curLocation(ORD.fromfacility,TK.fromloc);
    fetch curLocation into fromloc;
    close curLocation;
    toloc := null;
    open curLocation(ORD.fromfacility,TK.toloc);
    fetch curLocation into toloc;
    close curLocation;
    insert into alps.tasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, step1_complete)
      values
      (TK.taskid, TK.tasktype, ORD.fromfacility, fromloc.section,TK.fromloc,
       fromloc.equipprof,toloc.section,TK.toloc,toloc.equipprof,null,
       LP.custid,LP.item,LP.lpid,ITM.baseuom,LP.quantity,
       fromloc.pickingseq,ORD.loadno,ORD.stopno,ORD.shipno,
       ORD.orderid,ORD.shipid,LP.item,LP.lotnumber,
       TK.priority,TK.priority,null,'PRODPICK',sysdate,
       TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LP.custid,LP.item,ITM.Baseuom) * LP.quantity,
       zci.item_cube(LP.custid,LP.item,ITM.Baseuom) * LP.quantity,
       zlb.staff_hours(ORD.fromfacility,LP.custid,LP.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),'Y');
    insert into alps.subtasks
      (taskid, tasktype, facility, fromsection, fromloc,
       fromprofile,tosection,toloc,toprofile,touserid,
       custid,item,lpid,uom,qty,locseq,loadno,stopno,shipno,
       orderid,shipid,orderitem,orderlot,priority,
       prevpriority,curruserid,lastuser,lastupdate,
       pickuom, pickqty, picktotype, wave,
       pickingzone, cartontype, weight, cube, staffhrs, cartonseq,
       shippinglpid, shippingtype, cartongroup, step1_complete)
      values
      (TK.taskid,TK.tasktype,ORD.fromfacility,
       fromloc.section,TK.fromloc,fromloc.equipprof,toloc.section,
       TK.toloc,toloc.equipprof,null,LP.custid,LP.item,LP.lpid,
       ITM.Baseuom,LP.quantity,fromloc.pickingseq,ORD.loadno,
       ORD.stopno,ORD.shipno,ORD.orderid,ORD.shipid,LP.item,
       LP.lotnumber,TK.priority,TK.priority,null,'PRODPICK',
       sysdate,TK.pickuom,TK.pickqty,TK.picktotype,ORD.wave,
       fromloc.pickingzone,TK.cartontype,
       zci.item_weight(LP.custid,LP.item,ITM.Baseuom) * LP.quantity,
       zci.item_cube(LP.custid,LP.item,ITM.Baseuom) * LP.quantity,
       zlb.staff_hours(ORD.fromfacility,LP.custid,LP.item,TK.tasktype,
       fromloc.pickingzone,PltUOM_,1),TK.cartonseq,
       crec.lpid, 'F', zwv.cartontype_group(TK.cartontype),'Y');

    update alps.shippingplate
       set taskid = TK.taskid
     where lpid = crec.lpid;

<<continue>>
        null;
    end loop;




EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'FPI:'||sqlerrm;
END fetch_picked_inventory;



----------------------------------------------------------------------
--
-- fetch_picked_load
--
----------------------------------------------------------------------
PROCEDURE fetch_picked_load
(
    in_data IN OUT alps.cdata
)
IS
errmsg varchar2(255);
BEGIN
    in_data.out_no := 0;
    in_data.out_char := '';

    for crec in (select orderid, shipid
                   from alps.orderhdr
                  where loadno = in_data.loadno)
    loop
        fetch_picked_inventory(crec.orderid, crec.shipid, errmsg);
        if errmsg != 'OKAY' then
            in_data.out_no := 1;
            in_data.out_char := errmsg;
        end if;
    end loop;

END fetch_picked_load;



----------------------------------------------------------------------
--
-- lp_to_prod
--
----------------------------------------------------------------------
PROCEDURE lp_to_prod
(
    in_data IN OUT alps.cdata
)
IS
BEGIN
	zprod.plate_to_production(in_data.lpid, in_data.userid, in_data.out_no,
   		in_data.out_char);
END lp_to_prod;



----------------------------------------------------------------------
--
-- split_order
--
----------------------------------------------------------------------
PROCEDURE split_order
(
    in_data IN OUT alps.cdata
)
IS
errmsg varchar2(255);
BEGIN

-- Change the orderid on load_flag_details where
--      ShippingPlate has not been loaded or shipped

    UPDATE load_flag_dtl D
       SET D.orderid = in_data.num01,
           D.shipid = in_data.num02
     WHERE D.orderid = in_data.orderid
       AND D.shipid = in_data.shipid
       AND D.lpid not in
    (SELECT S.fromlpid
       FROM alps.shippingplate S
      WHERE S.orderid = in_data.orderid
        AND S.shipid = in_data.shipid
        AND S.fromlpid is not null
        AND S.status in ('L','SH'));

END split_order;


----------------------------------------------------------------------
--
-- cancel_load_flag
--
----------------------------------------------------------------------
PROCEDURE cancel_load_flag
(
    in_lpid     IN  varchar2,
    in_userid   IN  varchar2,
    out_errmsg  OUT varchar2
)
IS

LFH load_flag_hdr%rowtype;
cnt integer;
BEGIN
    out_errmsg := 'OKAY';

-- Read Load Flag Header Information
    LFH := null;
    OPEN C_LFH(in_lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;

    if LFH.lpid is null then
        out_errmsg := 'Load Flag '||in_lpid||' does not exist';
        return;
    end if;

    if LFH.status != 'NEW' then
        out_errmsg := 'Invalid status to cancel Load Flag '||in_lpid;
        return;
    end if;

-- Determine If orders can be unreleased
    for crec in (select distinct orderid, shipid
                   from load_flag_dtl
                  where lpid = in_lpid)
    loop
        cnt := 0;

        select count(1)
          into cnt
          from load_flag_dtl
         where orderid = crec.orderid
           and shipid = crec.shipid
           and lpid != in_lpid;

        if nvl(cnt,0) = 0 then
            update alps.orderhdr
               set orderstatus = '1',
                   statususer = in_userid,
                   statusupdate = sysdate
             where orderid = crec.orderid
               and shipid = crec.shipid;

        end if;

    end loop;

-- Delete load_flag_dtl
    delete from load_flag_hdr
     where lpid = in_lpid;

-- Delete load_flag_hdr
    delete from load_flag_dtl
     where lpid = in_lpid;

-- Add entry to deleted plate table

    insert into alps.deletedplate
        (lpid, facility,custid, status, quantity, type, lastuser, lastupdate)
    values
        (in_lpid, LFH.facility, LFH.custid, 'D',0, 'PA', in_userid, sysdate);


EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'CNLF:'||sqlerrm;
END cancel_load_flag;

----------------------------------------------------------------------
--
-- regen_load_flag
--
----------------------------------------------------------------------
PROCEDURE regen_load_flag
(
    in_orderid  IN  number,
    in_shipid   IN  number,
    in_qty      IN  number,
    in_pieces   IN  number,
    in_cartons  IN  number,
    in_userid   IN  varchar2,
    out_errmsg  OUT varchar2
)
IS
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
ITM jobitemsizeview%rowtype;

l_item alps.orderdtl.item%type;

l_pieces number;
l_cartons number;

qty_lfd number;
qty_regen number;

ctns number;
plts number;
remains number;
last_ctns number;

l_lpid alps.plate.lpid%type;
errmsg varchar2(255);


BEGIN
    out_errmsg := 'OKAY';

    ORD := null;
    OPEN C_ORD(in_orderid, in_shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        out_errmsg := 'Order: '||in_orderid||'/'||in_shipid||' not found';
        return;
    end if;

    if ORD.orderstatus in ('X','9','0') then
        out_errmsg := 'Invalid order status:'||ORD.orderstatus;
        return;
    end if;

    begin
        select item
          into l_item
          from alps.orderdtl
         where orderid = ORD.orderid
           and shipid = ORD.shipid
           and linestatus != 'X';
    exception when others then
        out_errmsg := 'Item not found';
        return;
    end;


    qty_lfd := 0;

    select sum(pieces*quantity)
      into qty_lfd
      from load_flag_dtl
     where orderid = ORD.orderid
       and shipid = ORD.shipid;


    qty_regen := in_qty - nvl(qty_lfd,0);

    if qty_regen <= 0 then
        out_errmsg := 'Invalid net qty to regen:'||to_char(qty_regen);
        return;
    end if;

    DTL := null;
    OPEN C_ORDDTL(in_orderid, in_shipid, l_item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        out_errmsg := 'Order Line: '||in_orderid||'/'||in_shipid||
            '/'||l_item||' not found';
        return;
    end if;


    ITM := null;
    OPEN C_ITMSIZE(ORD.custid, l_item);
    FETCH C_ITMSIZE into ITM;
    CLOSE C_ITMSIZE;


    if ITM.item is null and in_pieces is null then
        out_errmsg := 'Item Sizes for: '||ORD.custid||
            '/'||l_item||' not found';
        return;
    end if;

    l_cartons := nvl(in_cartons, 
            nvl(DTL.dtlpassthrunum02,ITM.ctn_plt));
    l_pieces := nvl(in_pieces, 
            nvl(DTL.dtlpassthrunum01,ITM.pcs_ctn));


    ctns := ceil(qty_regen/l_pieces);
    plts := ceil(ctns/l_cartons);
    remains := mod(qty_regen, l_pieces);

    -- trace('CLF','Cartons:'||ctns||' Plts:'||plts||' Remains:'||remains);

    for ix in 1..plts loop
        zrf.get_next_lpid(l_lpid, errmsg);

        insert into load_flag_hdr(type, jobno,facility,custid,lpid,status,
                    skidno, total_skid, created)
            values( 'D',ORD.reference, ORD.fromfacility, 
                    ORD.custid,l_lpid,'NEW',
                    ix, plts, sysdate);

        if ix = plts then
            if remains = 0 then

               last_ctns := mod(ctns,l_cartons);
               if last_ctns = 0 then
                  last_ctns := l_cartons;
               end if;
               insert into load_flag_dtl (lpid, orderid, shipid, item, pieces,
                    quantity)
                values (l_lpid, in_orderid, in_shipid, l_item, l_pieces,
                        --mod(ctns,l_cartons));
                        last_ctns);

            else
               last_ctns := mod(ctns,l_cartons) -1 ;
               if last_ctns = -1 then
                  last_ctns := l_cartons -1;
               end if;
               if last_ctns > 0 then
                 insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
                  values (l_lpid, in_orderid, in_shipid, l_item,
                    l_pieces, last_ctns);
                end if;

               insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
                values (l_lpid, in_orderid, in_shipid, l_item,
                        remains, 1);
            end if;
        else
            insert into load_flag_dtl (lpid, orderid, shipid, item,
                    pieces, quantity)
            values (l_lpid, in_orderid, in_shipid, l_item,
                    l_pieces, l_cartons);

        end if;
    end loop;


    UPDATE alps.orderhdr
       SET orderstatus = '4' -- Released
           -- hdrpassthrunum01 = nvl(in_pieces,hdrpassthrunum01),
           -- hdrpassthrunum02 = nvl(in_cartons,hdrpassthrunum02)
     WHERE orderid = in_orderid
       AND shipid = in_shipid;




EXCEPTION WHEN OTHERS THEN
    out_errmsg := 'RLF:'||sqlerrm;
END regen_load_flag;


----------------------------------------------------------------------
--
-- process_ms_mixed_carton
--
----------------------------------------------------------------------
PROCEDURE process_ms_mixed_carton
(
    in_data IN OUT alps.cdata
)
IS
errmsg varchar2(255);
errno integer;

CURSOR C_LFC(in_cartonid varchar2)
IS
SELECT *
  FROM load_flag_ctn
 WHERE cartonid = in_cartonid;

LFC load_flag_ctn%rowtype;

CURSOR C_LFD(LFC IN load_flag_ctn%rowtype)
IS
SELECT *
  FROM load_flag_dtl        -- was ctn ??
 WHERE lpid = LFC.lpid
   AND orderid = LFC.orderid
   AND shipid = LFC.shipid
   AND item = LFC.item
   AND pieces = LFC.pieces;

LFD load_flag_dtl%rowtype;

LFH load_flag_hdr%rowtype;

PORD alps.orderhdr%rowtype;
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
TK  alps.tasks%rowtype;
ITM alps.custitemview%rowtype;

new_status alps.orderhdr.orderstatus%type;
CD alps.cdata;

clip alps.shippingplate.lpid%type := null;

c_lpid alps.plate.lpid%type := null;

CURSOR C_STAGELOC(in_lpid varchar2)
IS
select C.carrier, C.facility, C.stageloc
from alps.carrierstageloc C, load_flag_dtl D, alps.orderhdr O
where D.lpid = in_lpid
and O.orderid = D.orderid
and O.shipid = D.shipid
and C.facility = O.fromfacility
and C.carrier = O.carrier
and C.shiptype = 'S';

STGLOC C_STAGELOC%rowtype;


cnt number;


  mclip alps.shippingplate.lpid%type := null;
  xlip alps.plate.lpid%type := null;


BEGIN
    in_data.out_no := 0;
    in_data.out_char := '';



    -- zut.prt('At start of ms multi processing');

    LFC := null;
    OPEN C_LFC(in_data.lpid);
    FETCH C_LFC into LFC;
    CLOSE C_LFC;
    if LFC.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'Carton not found';
        return;
    end if;

    LFD := null;
    OPEN C_LFD(LFC);
    FETCH C_LFD into LFD;
    CLOSE C_LFD;
    if LFD.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'LF Detail not found';
        return;
    end if;

    LFH := null;
    OPEN C_LFH(LFC.lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;
    if LFH.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'LF Header not found';
        return;
    end if;

    ORD := null;
    OPEN C_ORD(LFD.orderid, LFD.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        in_data.out_no := 2;
        in_data.out_char := 'Order: '||LFD.orderid
                ||'/'||LFD.shipid||' not found';
        return;
    end if;

    PORD := null;
    OPEN C_ORD_JOB(LFH.custid, LFH.jobno);
    FETCH C_ORD_JOB into PORD;
    CLOSE C_ORD_JOB;

-- Find Small Pacakge stage location
    STGLOC := null;
    OPEN C_STAGELOC(LFH.lpid);
    FETCH C_STAGELOC into STGLOC;
    CLOSE C_STAGELOC;



-- create a carton shipping plate
    zsp.get_next_shippinglpid(mclip, errmsg);
    if errmsg is not null then
       in_data.out_no := 4;
       in_data.out_char := errmsg;
       return;
    end if;

    xlip := in_data.lpid;

    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          fromlpid)
    values
         (mclip, ORD.fromfacility, STGLOC.stageloc, 'PA', 0, 'C',
          in_data.userid, sysdate, 0, NULL, ORD.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, ORD.orderid, ORD.shipid,
          xlip);

-- create the crossreference plate for the carton
    insert into alps.plate
       (lpid, type, parentlpid, lastuser, lastupdate, lasttask, lastoperator, custid, facility)
    values
       (xlip, 'XP', mclip, in_data.userid, sysdate, 'PA', in_data.userid, ORD.custid, ORD.fromfacility);


-- Read load_flag_ctn, load_flag_dtl? data

 for LFC in C_LFC(in_data.lpid) loop

    LFD := null;
    OPEN C_LFD(LFC);
    FETCH C_LFD into LFD;
    CLOSE C_LFD;
    if LFD.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'LF Detail not found';
        return;
    end if;

    new_status := zrf.ord_picking;

    DTL := null;
    OPEN C_ORDDTL(LFD.orderid, LFD.shipid, LFD.item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        in_data.out_no := 3;
        in_data.out_char := 'Order Line: '||LFD.orderid||'/'||LFD.shipid||
            '/'||LFD.item||' not found';
        return;
    end if;

    ITM := NULL;
    OPEN C_CUSTITEMV(LFH.custid, LFD.item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;


-- Create Plate and shippingplate
   --zrf.get_next_lpid(c_lpid, errmsg);
   c_lpid := LFC.cartonid;
   zsp.get_next_shippinglpid(clip, errmsg);
   if errmsg is not null then
       in_data.out_no := 4;
       in_data.out_char := errmsg;
       return;
   end if;

-- Create the load_flag_ctn entry so we know this is stuff to
--      export to the small package system


-- Now create a shipping plate for it

    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          unitofmeasure,invstatus, inventoryclass,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          orderitem, orderlot,
          fromlpid, pickuom, pickqty, parentlpid)
    values
         (clip, LFH.facility, STGLOC.stageloc, 'S', LFD.pieces, 'P',
          ITM.baseuom, 'AV','RG',
          in_data.userid, sysdate, LFC.weight, LFD.item, LFH.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, ORD.orderid, ORD.shipid,
          LFD.item, null,
          c_lpid, ITM.baseuom, LFD.pieces, mclip);


  -- add asof inventory for the plate
  zbill.add_asof_inventory(
        LFH.facility,
        LFH.custid,
        LFD.item,
        null,
        ITM.baseuom,
        trunc(sysdate),
        LFD.pieces,
        LFC.weight,
        'Received',
        'RC',
        'RG',
        'AV',
        ORD.orderid,
        ORD.shipid,
        in_data.lpid,
        in_data.userid,
        errmsg
     );


    receive_production_qty(PORD.orderid, PORD.shipid, LFD.item, LFD.pieces,
        errno, errmsg);
    if errmsg != 'OKAY' then
        in_data.out_no := errno;
        in_data.out_char := errmsg;
        return;

    end if;

    if PORD.hdrpassthruchar10 = 'PECAS' then
        CD := zcus.init_cdata;
        CD.lpid := c_lpid;
        CD.char01 := PORD.reference;

        zpecas.prod_receipt(CD);
    end if;

-- Update the order information
    UPDATE alps.orderdtl
       SET qtypick = nvl(qtypick, 0) + LFC.pieces,
           weightpick = nvl(weightpick, 0) + (LFC.pieces * ITM.weight),
           cubepick = nvl(cubepick, 0) + (LFC.pieces * ITM.cube),
           amtpick = nvl(amtpick, 0) + (LFC.pieces * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = in_data.userid,
           lastupdate = sysdate
     WHERE orderid = LFD.orderid
       AND shipid = LFD.shipid
       AND item = LFD.item
       AND nvl(lotnumber, '(none)') = '(none)';

    if ORD.qtypick + LFC.pieces > ORD.qtyorder then
        new_status := zrf.ORD_PICKED;

    end if;

    if new_status > ORD.orderstatus then

        update alps.orderhdr
           set orderstatus = new_status,
               lastuser = in_data.userid,
               lastupdate = sysdate
         where orderid = LFD.orderid
           and shipid = LFD.shipid;
    end if;

    zoh.add_orderhistory_item(LFD.orderid, LFD.shipid,
           in_data.lpid, LFD.item, null,
            'Pick Plate',
            'Pick Qty:'||LFC.pieces||' from Production',
            in_data.userid, errmsg);

 end loop;

EXCEPTION WHEN OTHERS THEN
    in_data.out_no := sqlcode;
    in_data.out_char := 'PMMC:'||sqlerrm;
END process_ms_mixed_carton;


----------------------------------------------------------------------
--
-- process_multiship_carton
--
----------------------------------------------------------------------
PROCEDURE process_multiship_carton
(
    in_data IN OUT alps.cdata
)
IS
errmsg varchar2(255);
errno integer;

CURSOR C_LFC(in_cartonid varchar2)
IS
SELECT *
  FROM load_flag_ctn
 WHERE cartonid = in_cartonid;

LFC load_flag_ctn%rowtype;

CURSOR C_LFD
IS
SELECT *
  FROM load_flag_dtl        -- was ctn ????
 WHERE lpid = LFC.lpid
   AND orderid = LFC.orderid
   AND shipid = LFC.shipid
   AND item = LFC.item
   AND pieces = LFC.pieces;

LFD load_flag_dtl%rowtype;

LFH load_flag_hdr%rowtype;

PORD alps.orderhdr%rowtype;
ORD alps.orderhdr%rowtype;
DTL alps.orderdtl%rowtype;
TK  alps.tasks%rowtype;
ITM alps.custitemview%rowtype;

new_status alps.orderhdr.orderstatus%type;
CD alps.cdata;

clip alps.shippingplate.lpid%type := null;

c_lpid alps.plate.lpid%type := null;

CURSOR C_STAGELOC(in_lpid varchar2)
IS
select C.carrier, C.facility, C.stageloc
from alps.carrierstageloc C, load_flag_dtl D, alps.orderhdr O
where D.lpid = in_lpid
and O.orderid = D.orderid
and O.shipid = D.shipid
and C.facility = O.fromfacility
and C.carrier = O.carrier
and C.shiptype = 'S';

STGLOC C_STAGELOC%rowtype;


cnt number;


BEGIN
    in_data.out_no := 0;
    in_data.out_char := '';


    -- zut.prt('Start of regular processing');

    cnt := 0;
    select count(1)
      into cnt
      from alps.allplateview
     where lpid = in_data.lpid;

    if cnt > 0 then
        in_data.out_no := 5;
        in_data.out_char := 'Carton already exists';
        return;
    end if;

    cnt := 0;
    select count(1)
      into cnt
      from load_flag_ctn
     where cartonid = in_data.lpid;

    if cnt > 1 then
        process_ms_mixed_carton(in_data);
        return;
    end if;

-- Read load_flag_ctn, load_flag_dtl? data

    LFC := null;
    OPEN C_LFC(in_data.lpid);
    FETCH C_LFC into LFC;
    CLOSE C_LFC;
    if LFC.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'Carton not found';
        return;
    end if;

    LFD := null;
    OPEN C_LFD;
    FETCH C_LFD into LFD;
    CLOSE C_LFD;
    if LFD.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'LF Detail not found';
        return;
    end if;

    LFH := null;
    OPEN C_LFH(LFC.lpid);
    FETCH C_LFH into LFH;
    CLOSE C_LFH;
    if LFH.lpid is null then
        in_data.out_no := 1;
        in_data.out_char := 'LF Header not found';
        return;
    end if;

    ORD := null;
    OPEN C_ORD(LFD.orderid, LFD.shipid);
    FETCH C_ORD into ORD;
    CLOSE C_ORD;

    if ORD.orderid is null then
        in_data.out_no := 2;
        in_data.out_char := 'Order: '||LFD.orderid
                ||'/'||LFD.shipid||' not found';
        return;
    end if;

    PORD := null;
    OPEN C_ORD_JOB(LFH.custid, LFH.jobno);
    FETCH C_ORD_JOB into PORD;
    CLOSE C_ORD_JOB;

    new_status := zrf.ord_picking;

    DTL := null;
    OPEN C_ORDDTL(LFD.orderid, LFD.shipid, LFD.item);
    FETCH C_ORDDTL into DTL;
    CLOSE C_ORDDTL;

    if DTL.orderid is null then
        in_data.out_no := 3;
        in_data.out_char := 'Order Line: '||LFD.orderid||'/'||LFD.shipid||
            '/'||LFD.item||' not found';
        return;
    end if;

    ITM := NULL;
    OPEN C_CUSTITEMV(LFH.custid, LFD.item);
    FETCH C_CUSTITEMV into ITM;
    CLOSE C_CUSTITEMV;

-- Find Small Pacakge stage location
    STGLOC := null;
    OPEN C_STAGELOC(LFH.lpid);
    FETCH C_STAGELOC into STGLOC;
    CLOSE C_STAGELOC;



-- Create Plate and shippingplate
   --zrf.get_next_lpid(c_lpid, errmsg);
   c_lpid := LFC.cartonid;
   zsp.get_next_shippinglpid(clip, errmsg);
   if errmsg is not null then
       in_data.out_no := 4;
       in_data.out_char := errmsg;
       return;
   end if;

   INSERT INTO ALPS.PLATE
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
      useritem1,
      creationdate,
      invstatus,
      inventoryclass,
      orderid,
      shipid,
      qtyentered,
      itementered,
      uomentered,
      weight,
      lastuser,
      lastupdate,
      parentfacility,
      parentitem,
      parentlpid,
      fromshippinglpid
   )
   VALUES
   (
      c_lpid,
      LFD.item,
      LFH.custid,
      LFH.facility,
      STGLOC.stageloc,
      'P',-- status,
      ITM.baseuom,
      LFD.pieces,
      'PA',
      LFH.jobno,
      sysdate,
      'AV',
      'RG',
      PORD.orderid,
      PORD.shipid,
      LFD.pieces,
      LFD.item,
      'PCS',
      LFC.weight,
      in_data.userid,
      sysdate,
      LFH.facility,
      LFD.item,
      null,
      clip
   );

-- Create the load_flag_ctn entry so we know this is stuff to
--      export to the small package system


-- Now create a shipping plate for it

    insert into alps.shippingplate
         (lpid, facility, location, status, quantity, type,
          unitofmeasure,invstatus, inventoryclass,
          lastuser, lastupdate, weight, item, custid,
          loadno, stopno, shipno, orderid, shipid,
          orderitem, orderlot,
          fromlpid, pickuom, pickqty, parentlpid)
    values
         (clip, LFH.facility, STGLOC.stageloc, 'S', LFD.pieces, 'F',
          ITM.baseuom, 'AV','RG',
          in_data.userid, sysdate, LFC.weight, LFD.item, LFH.custid,
          ORD.loadno, ORD.stopno, ORD.shipno, ORD.orderid, ORD.shipid,
          LFD.item, null,
          c_lpid, ITM.baseuom, LFD.pieces, null);


  -- add asof inventory for the plate
  zbill.add_asof_inventory(
        LFH.facility,
        LFH.custid,
        LFD.item,
        null,
        ITM.baseuom,
        trunc(sysdate),
        LFD.pieces,
        LFC.weight,
        'Received',
        'RC',
        'RG',
        'AV',
        PORD.orderid,
        PORD.shipid,
        c_lpid,
        in_data.userid,
        errmsg
     );


    receive_production_qty(PORD.orderid, PORD.shipid, LFD.item, LFD.pieces,
        errno, errmsg);
    if errmsg != 'OKAY' then
        in_data.out_no := errno;
        in_data.out_char := errmsg;
        return;

    end if;

    if PORD.hdrpassthruchar10 = 'PECAS' then
        CD := zcus.init_cdata;
        CD.lpid := c_lpid;
        CD.char01 := PORD.reference;

        zpecas.prod_receipt(CD);
    end if;

-- Update the order information
    UPDATE alps.orderdtl
       SET qtypick = nvl(qtypick, 0) + LFC.pieces,
           weightpick = nvl(weightpick, 0) + (LFC.pieces * ITM.weight),
           cubepick = nvl(cubepick, 0) + (LFC.pieces * ITM.cube),
           amtpick = nvl(amtpick, 0) + (LFC.pieces * zci.item_amt(custid,orderid,shipid,item,lotnumber)),
           lastuser = in_data.userid,
           lastupdate = sysdate
     WHERE orderid = LFD.orderid
       AND shipid = LFD.shipid
       AND item = LFD.item
       AND nvl(lotnumber, '(none)') = '(none)';

    if ORD.qtypick + LFC.pieces > ORD.qtyorder then
        new_status := zrf.ORD_PICKED;

    end if;

    if new_status > ORD.orderstatus then

        update alps.orderhdr
           set orderstatus = new_status,
               lastuser = in_data.userid,
               lastupdate = sysdate
         where orderid = LFD.orderid
           and shipid = LFD.shipid;
    end if;

    zoh.add_orderhistory_item(LFD.orderid, LFD.shipid,
           in_data.lpid, LFD.item, null,
            'Pick Plate',
            'Pick Qty:'||LFC.pieces||' from Production',
            in_data.userid, errmsg);


EXCEPTION WHEN OTHERS THEN
    in_data.out_no := sqlcode;
    in_data.out_char := 'PMC:'||sqlerrm;
END process_multiship_carton;

END zprod;
/

show error package body zprod;
exit;
