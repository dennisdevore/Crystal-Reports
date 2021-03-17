drop table dre_asofsummarylot;

create global temporary table dre_asofsummarylot
(
  sessionid      number,
  facility       varchar2(3 byte),
  custid         varchar2(10 byte),
  item           varchar2(50 byte),
  currentqty     number(10),
  currentweight  number(10),
  lotnumber      varchar2(30 byte),
  invstatus      varchar2(30 byte),
  useritem       varchar2(4000 byte),
  expdate        date,
  mfgdate        date,
  descr          varchar2(40 byte),
  lastupdate     date
)
on commit preserve rows
nocache;

create index dre_asofsummary_lastupdate_idx on dre_asofsummarylot
(lastupdate);

create index dre_asofsummary_sessionid_idx on dre_asofsummarylot
(sessionid);

CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

/*for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
*/  --doit(cf.facility, cu.custid, cit.item, cit.descr);
  INSERT INTO dre_asofsummarylot
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT   sessionid, facility, custid, item, SUM(currentqty) AS currentqty,
             SUM(currentweight) AS currentweight, lotnumber, invstatus,
             
             --3 as truelink,
             useritem, expdate, mfgdate, descr, lastupdate
        FROM (SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                     numsessionid AS sessionid, rh.tofacility AS facility,
                     rh.custid, rd.item, NVL(rd.qtyentered, 0) AS currentqty,
                     NVL(rd.weightorder, 0) AS currentweight,
                     NVL(rd.lotnumber, 'NONE') AS lotnumber,
                     'Arrived' AS invstatus,                  --3 as truelink,
                     asofsummarylotpkg.get_useritem(rh.custid,
                       rd.item, rd.lotnumber) AS useritem,
                     asofsummarylotpkg.get_expdate(rh.custid,
                       rd.item, rd.lotnumber) AS expdate,
                     asofsummarylotpkg.get_mfgdate(rh.custid,
                       rd.item, rd.lotnumber) AS mfgdate,
                     citm.descr, SYSDATE AS lastupdate
                FROM receiverhdrview rh,
                     receiverdtlview rd,
                     orderhdr oh,
                     custitem citm
               WHERE rd.custid = citm.custid(+)
                 AND rd.item = citm.item(+)
                 AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
                 AND rh.ordertype = 'R'
                 AND rh.orderstatus = 'A'
                 AND rh.orderid = rd.orderid
                 AND rh.shipid = rd.shipid
                 AND rh.orderhdrrowid = oh.ROWID
                 AND rd.qtyentered <> 0
                 AND in_invstatus IN('ALL', 'Arrived')
                 AND (rh.custid = in_custid OR in_custid = 'ALL')
                 AND (rh.tofacility = in_facility OR in_facility = 'ALL')) a1
    GROUP BY a1.sessionid,
             a1.facility,
             a1.custid,
             a1.item,
             a1.lotnumber,
             a1.invstatus,
             a1.useritem,
             a1.expdate,
             a1.mfgdate,
             a1.descr,
             lastupdate;

--commit;

  /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from dre_asofsummarylot
      where sessionid = numSessionId
        and facility = cf.facility
        and custid = cu.custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then

      insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);

     else
      update dre_asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
         and facility = cf.facility
         and custid = cu.custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
*/
   --commit;
/*
  end loop;
 end loop;
end loop;
*/
/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotproc;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc8(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

/*for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
*/  --doit(cf.facility, cu.custid, cit.item, cit.descr);
  INSERT INTO dre_asofsummarylot
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM asofinventory a1, inventorystatus, custitem citm
     WHERE a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a2.facility = a1.facility
                 AND a2.custid = a1.custid
                 AND a2.item = a1.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a2.lotnumber, 'xxx') = NVL(a1.lotnumber, 'xxx')
                 AND a2.uom = a1.uom
                 AND a2.invstatus = a1.invstatus
                 AND a2.inventoryclass = a1.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM asofinventory a1, inventorystatus, custitem citm
     WHERE a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a2.facility = a1.facility
                 AND a2.custid = a1.custid
                 AND a2.item = a1.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a2.lotnumber, 'xxx') = NVL(a1.lotnumber, 'xxx')
                 AND a2.uom = a1.uom
                 AND a2.invstatus = a1.invstatus
                 AND a2.inventoryclass = a1.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT   sessionid, facility, custid, item, SUM(currentqty) AS currentqty,
             SUM(currentweight) AS currentweight, lotnumber, invstatus,
             
             --3 as truelink,
             useritem, expdate, mfgdate, descr, lastupdate
        FROM (SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                     numsessionid AS sessionid, rh.tofacility AS facility,
                     rh.custid, rd.item, NVL(rd.qtyentered, 0) AS currentqty,
                     NVL(rd.weightorder, 0) AS currentweight,
                     NVL(rd.lotnumber, 'NONE') AS lotnumber,
                     'Arrived' AS invstatus,                  --3 as truelink,
                     asofsummarylotpkg.get_useritem(rh.custid,
                       rd.item, rd.lotnumber) AS useritem,
                     asofsummarylotpkg.get_expdate(rh.custid,
                       rd.item, rd.lotnumber) AS expdate,
                     asofsummarylotpkg.get_mfgdate(rh.custid,
                       rd.item, rd.lotnumber) AS mfgdate,
                     citm.descr, SYSDATE AS lastupdate
                FROM receiverhdrview rh,
                     receiverdtlview rd,
                     orderhdr oh,
                     custitem citm
               WHERE rd.custid = citm.custid(+)
                 AND rd.item = citm.item(+)
                 AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
                 AND rh.ordertype = 'R'
                 AND rh.orderstatus = 'A'
                 AND rh.orderid = rd.orderid
                 AND rh.shipid = rd.shipid
                 AND rh.orderhdrrowid = oh.ROWID
                 AND rd.qtyentered <> 0
                 AND in_invstatus IN('ALL', 'Arrived')
                 AND (rh.custid = in_custid OR in_custid = 'ALL')
                 AND (rh.tofacility = in_facility OR in_facility = 'ALL')) a1
    GROUP BY a1.sessionid,
             a1.facility,
             a1.custid,
             a1.item,
             a1.lotnumber,
             a1.invstatus,
             a1.useritem,
             a1.expdate,
             a1.mfgdate,
             a1.descr,
             lastupdate;

--commit;

  /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from dre_asofsummarylot
      where sessionid = numSessionId
        and facility = cf.facility
        and custid = cu.custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then

      insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);

     else
      update dre_asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
         and facility = cf.facility
         and custid = cu.custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
*/
   --commit;
/*
  end loop;
 end loop;
end loop;
*/
/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotproc8;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc9(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

/*for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
*/  --doit(cf.facility, cu.custid, cit.item, cit.descr);
  INSERT INTO dre_asofsummarylot
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT   sessionid, facility, custid, item, SUM(currentqty) AS currentqty,
             SUM(currentweight) AS currentweight, lotnumber, invstatus,
             
             --3 as truelink,
             useritem, expdate, mfgdate, descr, lastupdate
        FROM (SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                     numsessionid AS sessionid, rh.tofacility AS facility,
                     rh.custid, rd.item, NVL(rd.qtyentered, 0) AS currentqty,
                     NVL(rd.weightorder, 0) AS currentweight,
                     NVL(rd.lotnumber, 'NONE') AS lotnumber,
                     'Arrived' AS invstatus,                  --3 as truelink,
                     asofsummarylotpkg.get_useritem(rh.custid,
                       rd.item, rd.lotnumber) AS useritem,
                     asofsummarylotpkg.get_expdate(rh.custid,
                       rd.item, rd.lotnumber) AS expdate,
                     asofsummarylotpkg.get_mfgdate(rh.custid,
                       rd.item, rd.lotnumber) AS mfgdate,
                     citm.descr, SYSDATE AS lastupdate
                FROM receiverhdrview rh,
                     receiverdtlview rd,
                     orderhdr oh,
                     custitem citm
               WHERE rd.custid = citm.custid(+)
                 AND rd.item = citm.item(+)
                 AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
                 AND rh.ordertype = 'R'
                 AND rh.orderstatus = 'A'
                 AND rh.orderid = rd.orderid
                 AND rh.shipid = rd.shipid
                 AND rh.orderhdrrowid = oh.ROWID
                 AND rd.qtyentered <> 0
                 AND in_invstatus IN('ALL', 'Arrived')
                 AND (rh.custid = in_custid OR in_custid = 'ALL')
                 AND (rh.tofacility = in_facility OR in_facility = 'ALL')) a1
    GROUP BY a1.sessionid,
             a1.facility,
             a1.custid,
             a1.item,
             a1.lotnumber,
             a1.invstatus,
             a1.useritem,
             a1.expdate,
             a1.mfgdate,
             a1.descr,
             lastupdate;

--commit;

  /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from dre_asofsummarylot
      where sessionid = numSessionId
        and facility = cf.facility
        and custid = cu.custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then

      insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);

     else
      update dre_asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
         and facility = cf.facility
         and custid = cu.custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
*/
   --commit;
/*
  end loop;
 end loop;
end loop;
*/
/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotproc9;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc9s(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

/*for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
*/  --doit(cf.facility, cu.custid, cit.item, cit.descr);
  INSERT INTO dre_asofsummarylot
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass <> 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT   sessionid, facility, custid, item, SUM(currentqty) AS currentqty,
             SUM(currentweight) AS currentweight, lotnumber, invstatus,
             
             --3 as truelink,
             useritem, expdate, mfgdate, descr, lastupdate
        FROM (SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                     numsessionid AS sessionid, rh.tofacility AS facility,
                     rh.custid, rd.item, NVL(rd.qtyentered, 0) AS currentqty,
                     NVL(rd.weightorder, 0) AS currentweight,
                     NVL(rd.lotnumber, 'NONE') AS lotnumber,
                     'Arrived' AS invstatus,                  --3 as truelink,
                     asofsummarylotpkg.get_useritem(rh.custid,
                       rd.item, rd.lotnumber) AS useritem,
                     asofsummarylotpkg.get_expdate(rh.custid,
                       rd.item, rd.lotnumber) AS expdate,
                     asofsummarylotpkg.get_mfgdate(rh.custid,
                       rd.item, rd.lotnumber) AS mfgdate,
                     citm.descr, SYSDATE AS lastupdate
                FROM receiverhdrview rh,
                     receiverdtlview rd,
                     orderhdr oh,
                     custitem citm
               WHERE rd.custid = citm.custid(+)
                 AND rd.item = citm.item(+)
                 AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
                 AND rh.ordertype = 'R'
                 AND rh.orderstatus = 'A'
                 AND rh.orderid = rd.orderid
                 AND rh.shipid = rd.shipid
                 AND rh.orderhdrrowid = oh.ROWID
                 AND rd.qtyentered <> 0
                 AND in_invstatus IN('ALL', 'Arrived')
                 AND (rh.custid = in_custid OR in_custid = 'ALL')
                 AND (rh.tofacility = in_facility OR in_facility = 'ALL')) a1
    GROUP BY a1.sessionid,
             a1.facility,
             a1.custid,
             a1.item,
             a1.lotnumber,
             a1.invstatus,
             a1.useritem,
             a1.expdate,
             a1.mfgdate,
             a1.descr,
             lastupdate;

--commit;

  /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from dre_asofsummarylot
      where sessionid = numSessionId
        and facility = cf.facility
        and custid = cu.custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then

      insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);

     else
      update dre_asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
         and facility = cf.facility
         and custid = cu.custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
*/
   --commit;
/*
  end loop;
 end loop;
end loop;
*/
/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotproc9s;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc9_sv(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

/*for cu in curCustomer
loop
 for cf in curFacility
 loop
  for cit in curCustItems(cu.custid)
  loop
*/  --doit(cf.facility, cu.custid, cit.item, cit.descr);
  INSERT INTO dre_asofsummarylot
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT numsessionid, a1.facility, a1.custid, a1.item, a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate,
           citm.descr, SYSDATE
      FROM (SELECT   a2.facility, a2.custid, a2.item, a2.lotnumber, a2.uom,
                     MAX(a2.effdate) AS effdate, a2.invstatus,
                     a2.inventoryclass
                FROM asofinventory a2
               WHERE a2.effdate <= TRUNC(in_effdate)
                 AND (a2.custid = in_custid OR in_custid = 'ALL')
                 AND (a2.facility = in_facility OR in_facility = 'ALL')
                 AND a2.inventoryclass = 'RG'
            GROUP BY a2.facility,
                     a2.custid,
                     a2.item,
                     a2.lotnumber,
                     a2.uom,
                     a2.invstatus,
                     a2.inventoryclass) a2,
           asofinventory a1,
           inventorystatus,
           custitem citm
     WHERE a1.facility = a2.facility
       AND a1.custid = a2.custid
       AND a1.item = a2.item
       AND a1.effdate = a2.effdate
       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
       AND a1.uom = a2.uom
       AND a1.invstatus = a2.invstatus
       AND a1.inventoryclass = a2.inventoryclass
       AND a1.custid = citm.custid(+)
       AND a1.item = citm.item(+)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
       AND (a1.custid = in_custid OR in_custid = 'ALL')
       AND (a1.facility = in_facility OR in_facility = 'ALL')
    UNION ALL
    SELECT   sessionid, facility, custid, item, SUM(currentqty) AS currentqty,
             SUM(currentweight) AS currentweight, lotnumber, invstatus,
             
             --3 as truelink,
             useritem, expdate, mfgdate, descr, lastupdate
        FROM (SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                     numsessionid AS sessionid, rh.tofacility AS facility,
                     rh.custid, rd.item, NVL(rd.qtyentered, 0) AS currentqty,
                     NVL(rd.weightorder, 0) AS currentweight,
                     NVL(rd.lotnumber, 'NONE') AS lotnumber,
                     'Arrived' AS invstatus,                  --3 as truelink,
                     asofsummarylotpkg.get_useritem(rh.custid,
                       rd.item, rd.lotnumber) AS useritem,
                     asofsummarylotpkg.get_expdate(rh.custid,
                       rd.item, rd.lotnumber) AS expdate,
                     asofsummarylotpkg.get_mfgdate(rh.custid,
                       rd.item, rd.lotnumber) AS mfgdate,
                     citm.descr, SYSDATE AS lastupdate
                FROM receiverhdrview rh,
                     receiverdtlview rd,
                     orderhdr oh,
                     custitem citm
               WHERE rd.custid = citm.custid(+)
                 AND rd.item = citm.item(+)
                 AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
                 AND rh.ordertype = 'R'
                 AND rh.orderstatus = 'A'
                 AND rh.orderid = rd.orderid
                 AND rh.shipid = rd.shipid
                 AND rh.orderhdrrowid = oh.ROWID
                 AND rd.qtyentered <> 0
                 AND in_invstatus IN('ALL', 'Arrived')
                 AND (rh.custid = in_custid OR in_custid = 'ALL')
                 AND (rh.tofacility = in_facility OR in_facility = 'ALL')) a1
    GROUP BY a1.sessionid,
             a1.facility,
             a1.custid,
             a1.item,
             a1.lotnumber,
             a1.invstatus,
             a1.useritem,
             a1.expdate,
             a1.mfgdate,
             a1.descr,
             lastupdate;

--commit;

  /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
   loop
     select count(1)
       into aosCount
       from dre_asofsummarylot
      where sessionid = numSessionId
        and facility = cf.facility
        and custid = cu.custid
        and item = cit.item
        and nvl(lotnumber,'NONE') = caos.lotnumber
        and invstatus = caos.invstatus;
     if aosCount = 0 then

      insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                        caos.currentqty, caos.currentweight, caos.lotnumber,
                                        caos.invstatus, caos.useritem, caos.expdate,
                                        caos.mfgdate, cit.descr, sysdate);

     else
      update dre_asofsummarylot
         set currentqty = currentqty + caos.currentqty,
             currentweight = currentweight + caos.currentweight
       where sessionid = numSessionId
         and facility = cf.facility
         and custid = cu.custid
         and item = cit.item
         and nvl(lotnumber,'NONE') = caos.lotnumber
         and invstatus = caos.invstatus;
     end if;
   end loop;
*/
   --commit;
/*
  end loop;
 end loop;
end loop;
*/
/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotproc9_sv;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotprocs(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
           NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
           1 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             inventorystatus.abbrev,
             'Available', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 inventorystatus.abbrev,
                 'Available', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;

  PROCEDURE doit(
    in_facility VARCHAR2,
    in_custid VARCHAR2,
    in_item VARCHAR2,
    in_descr VARCHAR2
  )
  IS
  BEGIN
    INSERT INTO dre_asofsummarylot
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
             NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
             
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass = 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION ALL
      SELECT numsessionid, in_facility, in_custid, in_item, a1.currentqty,
             NVL(
               NVL(
                 a1.currentweight,
                 (
                    zci.item_weight(a1.custid, a1.item, a1.uom)
                  * a1.currentweight
                 )
               ),
               0
             ) AS currentweight,
             NVL(a1.lotnumber, 'NONE') AS lotnumber,
             DECODE(
               inventorystatus.abbrev,
               'Available', 'Unavailable',
               NVL(inventorystatus.abbrev, 'Unavailable')
             ) AS invstatus,
             
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
             asofsummarylotpkg.get_useritem(a1.custid, a1.item,
               a1.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(a1.custid, a1.item,
               a1.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
               a1.lotnumber) AS mfgdate,
             in_descr, SYSDATE
        FROM asofinventory a1, inventorystatus
       WHERE a1.facility = in_facility
         AND a1.custid = in_custid
         AND a1.item = in_item
         AND a1.effdate =
               (SELECT MAX(a2.effdate)
                  FROM asofinventory a2
                 WHERE a1.facility = a2.facility
                   AND a1.custid = a2.custid
                   AND a1.item = a2.item
                   AND a2.effdate <= TRUNC(in_effdate)
                   AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                   AND a1.uom = a2.uom
                   AND a1.invstatus = a2.invstatus
                   AND a1.inventoryclass = a2.inventoryclass)
         AND a1.inventoryclass <> 'RG'
         AND a1.invstatus = inventorystatus.code(+)
         AND (
                 in_invstatus = 'ALL'
              OR DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) = in_invstatus
             )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
         AND a1.currentqty <> 0
      UNION
      SELECT   numsessionid, rh.tofacility, rh.custid, rd.item,
               NVL(SUM(rd.qtyentered), 0) AS currentqty,
               NVL(SUM(rd.weightorder), 0) AS currentweight,
               NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
               
               --3 as truelink,
               asofsummarylotpkg.get_useritem(rh.custid, rd.item,
                 rd.lotnumber) AS useritem,
               asofsummarylotpkg.get_expdate(rh.custid, rd.item,
                 rd.lotnumber) AS expdate,
               asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
                 rd.lotnumber) AS mfgdate,
               in_descr, SYSDATE
          FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
         WHERE rh.tofacility = in_facility
           AND rh.custid = in_custid
           AND rd.item = in_item
           AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
           AND rh.ordertype = 'R'
           AND rh.orderstatus = 'A'
           AND rh.orderid = rd.orderid
           AND rh.shipid = rd.shipid
           AND rh.orderhdrrowid = oh.ROWID
           AND in_invstatus IN('ALL', 'Arrived')
      GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;

    COMMIT;
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM dre_asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM dre_asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

  FOR cu IN curcustomer
  LOOP
    FOR cf IN curfacility
    LOOP
      FOR cit IN curcustitems(cu.custid)
      LOOP
        --doit(cf.facility, cu.custid, cit.item, cit.descr);
        INSERT INTO dre_asofsummarylot
          SELECT numsessionid, cf.facility, cu.custid, cit.item,
                 a1.currentqty,
                 NVL(
                   NVL(
                     a1.currentweight,
                     (
                        zci.item_weight(a1.custid, a1.item, a1.uom)
                      * a1.currentweight
                     )
                   ),
                   0
                 ) AS currentweight,
                 NVL(a1.lotnumber, 'NONE') AS lotnumber,
                 
--    nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')) as INVSTATUS,
                 NVL(inventorystatus.abbrev, 'Unavailable') AS invstatus,
                 
--  1 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
                 asofsummarylotpkg.get_useritem(a1.custid,
                   a1.item, a1.lotnumber) AS useritem,
                 asofsummarylotpkg.get_expdate(a1.custid, a1.item,
                   a1.lotnumber) AS expdate,
                 asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
                   a1.lotnumber) AS mfgdate,
                 cit.descr, SYSDATE
            FROM asofinventory a1, inventorystatus
           WHERE a1.facility = cf.facility
             AND a1.custid = cu.custid
             AND a1.item = cit.item
             AND a1.effdate =
                   (SELECT MAX(a2.effdate)
                      FROM asofinventory a2
                     WHERE a2.facility = cf.facility
                       AND a2.custid = cu.custid
                       AND a2.item = cit.item
                       AND a2.effdate <= TRUNC(in_effdate)
                       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                       AND a2.uom = a1.uom
                       AND a2.invstatus = a1.invstatus
                       AND a2.inventoryclass = a1.inventoryclass)
             AND a1.inventoryclass = 'RG'
             AND a1.invstatus = inventorystatus.code(+)
             AND (
                     in_invstatus = 'ALL'
                  OR NVL(inventorystatus.abbrev, 'Unavailable') = in_invstatus
                 )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
             AND a1.currentqty <> 0
          UNION ALL
          SELECT numsessionid, cf.facility, cu.custid, cit.item,
                 a1.currentqty,
                 NVL(
                   NVL(
                     a1.currentweight,
                     (
                        zci.item_weight(a1.custid, a1.item, a1.uom)
                      * a1.currentweight
                     )
                   ),
                   0
                 ) AS currentweight,
                 NVL(a1.lotnumber, 'NONE') AS lotnumber,
                 DECODE(
                   inventorystatus.abbrev,
                   'Available', 'Unavailable',
                   NVL(inventorystatus.abbrev, 'Unavailable')
                 ) AS invstatus,
                 
--  2 as truelink,
--    decode(A1.inventoryclass,'RG',
--           nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--           decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable'))
--          )  as INVSTATUS,
--    decode(A1.inventoryclass,'RG',1,2) as truelink,
                 asofsummarylotpkg.get_useritem(a1.custid,
                   a1.item, a1.lotnumber) AS useritem,
                 asofsummarylotpkg.get_expdate(a1.custid, a1.item,
                   a1.lotnumber) AS expdate,
                 asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
                   a1.lotnumber) AS mfgdate,
                 cit.descr, SYSDATE
            FROM asofinventory a1, inventorystatus
           WHERE a1.facility = cf.facility
             AND a1.custid = cu.custid
             AND a1.item = cit.item
             AND a1.effdate =
                   (SELECT MAX(a2.effdate)
                      FROM asofinventory a2
                     WHERE a2.facility = cf.facility
                       AND a2.custid = cu.custid
                       AND a2.item = cit.item
                       AND a2.effdate <= TRUNC(in_effdate)
                       AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                       AND a2.uom = a1.uom
                       AND a2.invstatus = a1.invstatus
                       AND a2.inventoryclass = a1.inventoryclass)
             AND a1.inventoryclass <> 'RG'
             AND a1.invstatus = inventorystatus.code(+)
             AND (
                     in_invstatus = 'ALL'
                  OR DECODE(
                       inventorystatus.abbrev,
                       'Available', 'Unavailable',
                       NVL(inventorystatus.abbrev, 'Unavailable')
                     ) = in_invstatus
                 )
--    decode(A1.inventoryclass,'RG',
--      nvl(INVENTORYSTATUS.ABBREV, decode(A1.INVSTATUS,'AV','Available','Unavailable')),
--      decode(A1.INVSTATUS,'AV','Unavailable',nvl(INVENTORYSTATUS.ABBREV,'Unavailable')) ) = in_invstatus)
             AND a1.currentqty <> 0
          UNION ALL
          SELECT
--    numSessionId, cf.facility, cu.custid, cit.item,
                   numsessionid, rh.tofacility, rh.custid, rd.item,
                   NVL(SUM(rd.qtyentered), 0) AS currentqty,
                   NVL(SUM(rd.weightorder), 0) AS currentweight,
                   NVL(rd.lotnumber, 'NONE') AS lotnumber,
                   'Arrived' AS invstatus,                    --3 as truelink,
                   asofsummarylotpkg.get_useritem(rh.custid,
                     rd.item, rd.lotnumber) AS useritem,
                   asofsummarylotpkg.get_expdate(rh.custid,
                     rd.item, rd.lotnumber) AS expdate,
                   asofsummarylotpkg.get_mfgdate(rh.custid,
                     rd.item, rd.lotnumber) AS mfgdate,
                   cit.descr, SYSDATE
              FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
             WHERE rh.tofacility = cf.facility
               AND rh.custid = cu.custid
               AND rd.item = cit.item
               AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
               AND rh.ordertype = 'R'
               AND rh.orderstatus = 'A'
               AND rh.orderid = rd.orderid
               AND rh.shipid = rd.shipid
               AND rh.orderhdrrowid = oh.ROWID
               AND in_invstatus IN('ALL', 'Arrived')
          GROUP BY rh.tofacility, rh.custid, rd.item, rd.lotnumber;
--commit;

      /*   for caos in curAsOfSearch(cu.custid, cf.facility, cit.item)
         loop
           select count(1)
             into aosCount
             from dre_asofsummarylot
            where sessionid = numSessionId
              and facility = cf.facility
              and custid = cu.custid
              and item = cit.item
              and nvl(lotnumber,'NONE') = caos.lotnumber
              and invstatus = caos.invstatus;
           if aosCount = 0 then

            insert into dre_asofsummarylot values(numSessionId, cf.facility, cu.custid, cit.item,
                                              caos.currentqty, caos.currentweight, caos.lotnumber,
                                              caos.invstatus, caos.useritem, caos.expdate,
                                              caos.mfgdate, cit.descr, sysdate);

           else
            update dre_asofsummarylot
               set currentqty = currentqty + caos.currentqty,
                   currentweight = currentweight + caos.currentweight
             where sessionid = numSessionId
               and facility = cf.facility
               and custid = cu.custid
               and item = cit.item
               and nvl(lotnumber,'NONE') = caos.lotnumber
               and invstatus = caos.invstatus;
           end if;
         end loop;
      */
         --commit;
      END LOOP;
    END LOOP;
  END LOOP;

/*
delete from dre_asofsummarylot
      where sessionid = numSessionId
        and currentqty = 0;
*/
  COMMIT;

  OPEN aos_cursor FOR
    SELECT   sessionid, custid, item, currentqty, currentweight
--,sum(currentqty)
--,sum(currentweight)
             , lotnumber, invstatus, useritem, expdate, mfgdate, descr,
             lastupdate
        FROM dre_asofsummarylot
       WHERE sessionid = numsessionid
    ORDER BY item, invstatus;
--  group by sessionid, item, descr, useritem, expdate, mfgdate, invstatus, lotnumber, lastupdate;
END dre_asofsummarylotprocs;
/
CREATE OR REPLACE PROCEDURE dre_asofsummarylotproc_sv(
  aos_cursor IN OUT asofsummarylotpkg.aos_type,
  in_custid IN VARCHAR2,
  in_facility IN VARCHAR2,
  in_effdate IN DATE,
  in_invstatus IN VARCHAR2,
  in_debug_yn IN VARCHAR2
)
AS
  CURSOR curcustomer
  IS
    SELECT   custid
        FROM customer
       WHERE (custid = in_custid OR in_custid = 'ALL')
    ORDER BY custid;

  cu             curcustomer%ROWTYPE;

  CURSOR curfacility
  IS
    SELECT   facility
        FROM facility
       WHERE (facility = in_facility OR in_facility = 'ALL')
    ORDER BY facility;

  cf             curfacility%ROWTYPE;

  CURSOR curcustitems(in_custid IN VARCHAR2)
  IS
    SELECT   item, descr
        FROM custitem
       WHERE custid = in_custid
    ORDER BY item;

  CURSOR curasofsearch(
    in_custid IN VARCHAR2,
    in_facility IN VARCHAR2,
    in_item IN VARCHAR2
  )
  IS
    SELECT a1.currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentweight
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           NVL(
             inventorystatus.abbrev,
             DECODE(a1.invstatus, 'AV', 'Available', 'Unavailable')
           ) AS invstatus,
           1 AS truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a2.facility = a1.facility
                 AND a2.custid = a1.custid
                 AND a2.item = a1.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a2.lotnumber, 'xxx') = NVL(a1.lotnumber, 'xxx')
                 AND a2.uom = a1.uom
                 AND a2.invstatus = a1.invstatus
                 AND a2.inventoryclass = a1.inventoryclass)
       AND a1.inventoryclass = 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR NVL(
                 inventorystatus.abbrev,
                 DECODE(a1.invstatus, 'AV', 'Available', 'Unavailable')
               ) = in_invstatus
           )
       AND a1.currentqty <> 0
    UNION ALL
    SELECT a1.currentqty AS currentqty,
           NVL(
             NVL(
               a1.currentweight,
               (
                zci.item_weight(a1.custid, a1.item, a1.uom) * a1.currentqty
               )
             ),
             0
           ) AS currentweight,
           NVL(a1.lotnumber, 'NONE') AS lotnumber,
           DECODE(
             a1.invstatus,
             'AV', 'Unavailable',
             NVL(inventorystatus.abbrev, 'Unavailable')
           ) AS invstatus,
           2 AS truelink,
           asofsummarylotpkg.get_useritem(a1.custid, a1.item,
             a1.lotnumber) AS useritem,
           asofsummarylotpkg.get_expdate(a1.custid, a1.item,
             a1.lotnumber) AS expdate,
           asofsummarylotpkg.get_mfgdate(a1.custid, a1.item,
             a1.lotnumber) AS mfgdate
      FROM asofinventory a1, inventorystatus
     WHERE a1.facility = in_facility
       AND a1.custid = in_custid
       AND a1.item = in_item
       AND a1.effdate =
             (SELECT MAX(a2.effdate)
                FROM asofinventory a2
               WHERE a1.facility = a2.facility
                 AND a1.custid = a2.custid
                 AND a1.item = a2.item
                 AND a2.effdate <= TRUNC(in_effdate)
                 AND NVL(a1.lotnumber, 'xxx') = NVL(a2.lotnumber, 'xxx')
                 AND a1.uom = a2.uom
                 AND a1.invstatus = a2.invstatus
                 AND a1.inventoryclass = a2.inventoryclass)
       AND a1.inventoryclass <> 'RG'
       AND a1.invstatus = inventorystatus.code(+)
       AND (
               in_invstatus = 'ALL'
            OR DECODE(
                 a1.invstatus,
                 'AV', 'Unavailable',
                 NVL(inventorystatus.abbrev, 'Unavailable')
               ) = in_invstatus
           )
       AND a1.currentqty <> 0
    UNION ALL
    SELECT   NVL(SUM(rd.qtyentered), 0) AS currentqty,
             NVL(SUM(rd.weightorder), 0) AS currentweight,
             NVL(rd.lotnumber, 'NONE') AS lotnumber, 'Arrived' AS invstatus,
             3 AS truelink,
             asofsummarylotpkg.get_useritem(rh.custid, rd.item,
               rd.lotnumber) AS useritem,
             asofsummarylotpkg.get_expdate(rh.custid, rd.item,
               rd.lotnumber) AS expdate,
             asofsummarylotpkg.get_mfgdate(rh.custid, rd.item,
               rd.lotnumber) AS mfgdate
        FROM receiverhdrview rh, receiverdtlview rd, orderhdr oh
       WHERE rh.tofacility = in_facility
         AND rh.custid = in_custid
         AND rd.item = in_item
         AND TRUNC(oh.entrydate) <= TRUNC(in_effdate)
         AND rh.ordertype = 'R'
         AND rh.orderstatus = 'A'
         AND rh.orderid = rd.orderid
         AND rh.shipid = rd.shipid
         AND rh.orderhdrrowid = oh.ROWID
         AND in_invstatus IN('ALL', 'Arrived')
    GROUP BY rh.custid, rd.item, rd.lotnumber;

  numsessionid   NUMBER;
  aoscount       NUMBER;
BEGIN
  SELECT SYS_CONTEXT('USERENV', 'SESSIONID')
    INTO numsessionid
    FROM DUAL;

  DELETE FROM asofsummarylot
        WHERE sessionid = numsessionid;

  COMMIT;

  DELETE FROM asofsummarylot
        WHERE lastupdate < TRUNC(SYSDATE);

  COMMIT;

  FOR cu IN curcustomer
  LOOP
    FOR cf IN curfacility
    LOOP
      FOR cit IN curcustitems(cu.custid)
      LOOP
        FOR caos IN curasofsearch(cu.custid, cf.facility, cit.item)
        LOOP
          SELECT COUNT(1)
            INTO aoscount
            FROM asofsummarylot
           WHERE sessionid = numsessionid
             AND custid = cu.custid
             AND item = cit.item
             AND NVL(lotnumber, 'NONE') = caos.lotnumber
             AND invstatus = caos.invstatus;

          IF aoscount = 0
          THEN
            INSERT INTO asofsummarylot
                 VALUES (numsessionid, cu.custid, cit.item, caos.currentqty,
                         caos.currentweight, caos.lotnumber, caos.invstatus,
                         caos.useritem, caos.expdate, caos.mfgdate,
                         cit.descr, SYSDATE);
          ELSE
            UPDATE asofsummarylot
               SET currentqty = currentqty + caos.currentqty,
                   currentweight = currentweight + caos.currentweight
             WHERE sessionid = numsessionid
			   AND custid = cu.custid
               AND item = cit.item
               AND NVL(lotnumber, 'NONE') = caos.lotnumber
               AND invstatus = caos.invstatus;
          END IF;
        END LOOP;

        COMMIT;
      END LOOP;
    END LOOP;
  END LOOP;

  DELETE FROM asofsummarylot
        WHERE sessionid = numsessionid AND currentqty = 0;

  COMMIT;

  OPEN aos_cursor FOR
    SELECT DISTINCT sessionid, custid, item, currentqty, currentweight,
                    lotnumber, invstatus, useritem, expdate, mfgdate, descr,
                    lastupdate
               FROM asofsummarylot
              WHERE sessionid = numsessionid
           ORDER BY item, invstatus;
END dre_asofsummarylotproc_sv;
/
exit;
