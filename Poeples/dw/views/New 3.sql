--CREATE OR REPLACE FORCE VIEW ALPS.INVITEM
--(
--   ITEMROWID,
--   INVOICE,
--   BILLSTATUS,
--   BILLSTATUSABBEV,
--   FACILITY,
--   CUSTID,
--   ORDERID,
--   SHIPID,
--   PO,
--   ITEM,
--   LOTNUMBER,
--   BUSINESSEVENT,
--   ACTIVITY,
--   ACTIVITYABBREV,
--   DTLCOUNT,
--   MINIMUM,
--   MINIMUMORD,
--   CALCULATION,
--   SUMAMOUNT,
--   BILLMETHOD,
--   LOADNO,
--   BILLEDQTY,
--   LASTUSER,
--   LASTUPDATE,
--   STATUSUSER,
--   STATUSUPDATE,
--   BMCODE,
--   REFERENCE,
--   SHIPTONAME,
--   PALLETTYPE
--)
--AS
WITH
   Activities AS
     (SELECT
            a.CODE Activity,
            a.ABBREV,
            A.REVENUEGROUP,
            rg.abbrev RevenueGroup_Abbrev,
            rg.descr RevenueGroup_Descr
      FROM
            ACTIVITY a,
            REVENUEREPORTGROUPS rg
      WHERE
         a.REVENUEGROUP = rg.CODE(+))
   SELECT /*+ ordered */
          ID.invoice,
          ID.billstatus,
          BS.abbrev,
          ID.facility,
          ID.custid,
          ID.orderid,
          ID.shipid,
          OH.po,
          ID.item,
          ID.lotnumber,
          ID.businessevent,
          ID.activity,
          AC.abbrev,
          1,
          ID.minimum,
          NVL (ID.minimum, 0),
          DECODE (
             NVL (ID.minimum, -1),
             -1,    TO_CHAR (billedqty)
                 || ' '
                 || calceduom
                 --          || decode(ID.billmethod,'QTYM','%'||ID.moduom,'')
                 || ' @ '
                 || DECODE (
                       billedrate * 100,
                       FLOOR (billedrate * 100), LTRIM (
                                                    TO_CHAR (billedrate,
                                                             '999,990.99')),
                       LTRIM (TO_CHAR (billedrate))),
             -- ' Min Adj @ '||ltrim(to_char(ID.minimum, '999,990.99'))),
             DECODE (
                SUBSTR (ID.billmethod, 1, 2),
                'SC',    ' Surcharge @ '
                      || LTRIM (TO_CHAR (ID.minimum, '990.99'))
                      || '%',
                ' Min Adj @ ' || LTRIM (TO_CHAR (ID.minimum, '999,990.99')))),
          NVL (ID.billedamt, 0),
          DECODE (ID.billmethod,
                  'QTYM', BM.abbrev || '-' || ID.moduom,
                  BM.abbrev),
          DECODE (ID.loadno, 0, NULL, ID.loadno),
          ID.billedqty,
          ID.lastuser,
          ID.lastupdate,
          ID.statususer,
          ID.statusupdate,
          ID.billmethod,
          OH.reference,
          DECODE (OH.shiptoname, NULL, CO.name, OH.shiptoname),
          ID.pallettype
,ID.INVTYPE
,IT.ABBREV INVTYPE_ABBREV
,ac.REVENUEGROUP
,ac.REVENUEGROUP_abbrev, ID.ACTIVITYDATE, ID.INVDATE
     FROM invoicedtl     ID,
          billingmethod  BM,
          billstatus     BS,
          Activities     AC,
          orderhdr       OH,
          consignee      CO,
          invoicetypes   IT
    WHERE     ID.billstatus = BS.code(+)
          AND ID.activity = AC.Activity(+)
          AND ID.billmethod = BM.code(+)
          AND (   ID.invoice > 0
               OR (ID.invoice < 0 AND ID.billstatus IN ('E', '4')))
          AND ID.orderid = OH.orderid(+)
          AND ID.shipid = OH.shipid(+)
          AND OH.shipto = CO.consignee(+)
AND ID.INVTYPE = IT.CODE(+)
--and ac.REVENUEGROUP = rg.code(+)
and ID.INVOICE = 3818386
   UNION
   SELECT /*+ ordered */         -- Get In-progress invoice details.
          ID.invoice,
          ID.billstatus,
          CASE
            WHEN id.billstatus = 0 THEN
               'In Progress'
            ELSE
               BS.abbrev
          END Billstatus_abbrev,
          ID.facility,
          ID.custid,
          ID.orderid,
          ID.shipid,
          ID.po,
          ID.item,
          ID.lotnumber,
          ID.businessevent,
          ID.activity,
          AC.abbrev,
          1,
          ID.minimum,
          NVL (ID.minimum, 0),
          DECODE (
             NVL (ID.minimum, -1),
             -1,    TO_CHAR (billedqty)
                 || ' '
                 || calceduom
                 --          || decode(ID.billmethod,'QTYM','%'||ID.moduom,'')
                 || ' @ '
                 || DECODE (
                       billedrate * 100,
                       FLOOR (billedrate * 100), LTRIM (
                                                    TO_CHAR (billedrate,
                                                             '999,990.99')),
                       LTRIM (TO_CHAR (billedrate))),
             ' Min Adj @ ' || LTRIM (TO_CHAR (ID.minimum, '999,990.99'))),
          NVL (ID.billedamt, 0),
          DECODE (ID.billmethod,
                  'QTYM', BM.abbrev || '-' || ID.moduom,
                  BM.abbrev),
          DECODE (ID.loadno, 0, NULL, ID.loadno),
          ID.billedqty,
          ID.lastuser,
          ID.lastupdate,
          ID.statususer,
          ID.statusupdate,
          ID.billmethod,
          OH.reference,
          DECODE (OH.shiptoname, NULL, CO.name, OH.shiptoname),
          ID.pallettype
,ID.INVTYPE
,IT.ABBREV INVTYPE_ABBREV
,ac.REVENUEGROUP
,ac.REVENUEGROUP_abbrev, ID.ACTIVITYDATE, ID.INVDATE
     FROM invoicedtl     ID,
          billingmethod  BM,
          billstatus     BS,
          Activities     AC,
          orderhdr       OH,
          consignee      CO,
          invoicetypes   IT
    WHERE     ID.billstatus = BS.code(+)
          AND ID.activity = AC.Activity(+)
          AND ID.billmethod = BM.code(+)
          AND (ID.invoice = 0)
          AND ID.orderid = OH.orderid(+)
          AND ID.shipid = OH.shipid(+)
          AND OH.shipto = CO.consignee(+)
AND ID.INVTYPE = IT.CODE(+)
--and ac.REVENUEGROUP = rg.code(+)
and ID.INVOICE = 0
          ;
--
--COMMENT ON TABLE ALPS.INVITEM IS '$Id: invitem1view.sql 17847 2017-02-23 22:46:56Z tgrover $';
