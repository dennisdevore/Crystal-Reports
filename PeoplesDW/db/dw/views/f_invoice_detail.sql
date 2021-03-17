create or replace view f_invoice_detail as
WITH
   Activities AS
     (SELECT
            a.CODE Activity,
            a.ABBREV Activity_Abbrev,
            a.REVENUEGROUP Revenue_Group,
            rg.ABBREV Revenue_Group_Abbrev,
            rg.DESCR  Revenue_Group_Descr
      FROM
            alps.ACTIVITY a,
            alps.REVENUEREPORTGROUPS rg
      WHERE
         a.REVENUEGROUP = rg.CODE(+))
SELECT
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      ID.lastupdate Modification_Time,
      ID.invoice,
      ID.INVTYPE Invoice_Type,
      IT.ABBREV  Invoice_Type_Abbrev,
      AC.Revenue_Group,
      AC.Revenue_Group_Abbrev,
      ID.billstatus Bill_Status,
      BS.abbrev     Bill_Status_Abbrev,
      ID.facility,
      ID.custid Customer,
      ID.orderid,
      ID.shipid,
      OH.po,
      OH.reference,
      ID.item,
      ID.lotnumber Lot_Number,
      ID.businessevent Business_event,
      ID.activity,
      AC.Activity_Abbrev,
      CASE
         WHEN ID.minimum IS NULL THEN
            0
         ELSE
            ID.minimum
      END Minimum,
      CASE
         WHEN ID.minimum IS NULL THEN
            TO_CHAR (ID.billedqty)
                 || ' '
                 || ID.calceduom
                 || ' @ '
                 || DECODE (
                       ID.billedrate * 100,
                       FLOOR (ID.billedrate * 100), LTRIM (
                                                    TO_CHAR (ID.billedrate,
                                                             '999,990.99')),
                       LTRIM (TO_CHAR (ID.billedrate)))
         ELSE
            DECODE (
                SUBSTR (ID.billmethod, 1, 2),
                'SC', ' Surcharge @ '
                      || LTRIM (TO_CHAR (ID.minimum, '990.99'))
                      || '%',
                ' Min Adj @ ' || LTRIM (TO_CHAR (ID.minimum, '999,990.99')))
      END Calculation,
      ID.billedqty Quantity,
      NVL(ID.billedamt, 0) Amount,
      ID.billmethod Bill_Method,
      DECODE (ID.billmethod,
              'QTYM', BM.abbrev || '-' || ID.moduom,
              BM.abbrev) Bill_Method_Descr,
      DECODE (ID.loadno, 0, NULL, ID.loadno) Load_Number,
      ID.lastuser   Last_Update_User,
      ID.lastupdate Last_Update_Time,
      ID.statususer   Status_Update_User,
      ID.statusupdate Status_Update_Time,
      DECODE (OH.shiptoname, NULL, CO.name, OH.shiptoname) Ship_To_Name,
      ID.pallettype Pallet_Type,
      ID.ACTIVITYDATE Activity_Date,
      ID.INVDATE Invoice_Time,
      OH.shipto Consignee
FROM
      alps.billingmethod  BM,
      alps.billstatus     BS,
      alps.Activities     AC,
      alps.orderhdr       OH,
      alps.consignee      CO,
      alps.invoicetypes   IT,
      alps.invoicedtl     ID
WHERE
      ID.billstatus = BS.code(+)
  AND ID.activity = AC.Activity(+)
  AND ID.billmethod = BM.code(+)
  AND (    ID.invoice > 0
       OR (ID.invoice < 0 AND ID.billstatus IN ('E', '4')))
  AND ID.orderid = OH.orderid(+)
  AND ID.shipid = OH.shipid(+)
  AND OH.shipto = CO.consignee(+)
  AND ID.INVTYPE = IT.CODE(+)
UNION ALL
SELECT
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      id.lastupdate Modification_Time,
      ID.invoice,
      ID.INVTYPE Invoice_Type,
      IT.ABBREV  Invoice_Type_Abbrev,
      AC.Revenue_Group,
      AC.Revenue_Group_Abbrev,
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
      OH.reference,
      ID.item,
      ID.lotnumber,
      ID.businessevent,
      ID.activity,
      AC.Activity_Abbrev,
      CASE
         WHEN ID.minimum IS NULL THEN
            0
         ELSE
            ID.minimum
      END Minimum,
      CASE
         WHEN ID.minimum IS NULL THEN
            TO_CHAR (ID.billedqty)
                 || ' '
                 || ID.calceduom
                 || ' @ '
                 || DECODE (
                       ID.billedrate * 100,
                       FLOOR (ID.billedrate * 100), LTRIM (
                                                    TO_CHAR (ID.billedrate,
                                                             '999,990.99')),
                       LTRIM (TO_CHAR (ID.billedrate)))
         ELSE
            DECODE (
                SUBSTR (ID.billmethod, 1, 2),
                'SC', ' Surcharge @ '
                      || LTRIM (TO_CHAR (ID.minimum, '990.99'))
                      || '%',
                ' Min Adj @ ' || LTRIM (TO_CHAR (ID.minimum, '999,990.99')))
      END Calculation,
      ID.billedqty Quantity,
      NVL (ID.billedamt, 0),
      ID.billmethod Bill_Method,
      DECODE (ID.billmethod,
              'QTYM', BM.abbrev || '-' || ID.moduom,
              BM.abbrev) Bill_Method_Descr,
      DECODE (ID.loadno, 0, NULL, ID.loadno) Load_Number,
      ID.lastuser Last_Update_User,
      ID.lastupdate Last_Update_Time,
      ID.statususer Status_Update_User,
      ID.statusupdate Status_Update_Time,
      DECODE (OH.shiptoname, NULL, CO.name, OH.shiptoname) Ship_To_Name,
      ID.pallettype Pallet_Type,
      ID.ACTIVITYDATE Activity_Date,
      ID.INVDATE Invoice_Time,
      OH.shipto Consignee
FROM
      alps.billingmethod  BM,
      alps.billstatus     BS,
      alps.Activities     AC,
      alps.orderhdr       OH,
      alps.consignee      CO,
      alps.invoicetypes   IT,
      alps.invoicedtl     ID
WHERE
      ID.billstatus = BS.code(+)
  AND ID.activity = AC.Activity(+)
  AND ID.billmethod = BM.code(+)
  AND ID.invoice = 0              -- Fetch In-progress invoices.
  AND ID.orderid = OH.orderid(+)
  AND ID.shipid = OH.shipid(+)
  AND OH.shipto = CO.consignee(+)
  AND ID.INVTYPE = IT.CODE(+)
;