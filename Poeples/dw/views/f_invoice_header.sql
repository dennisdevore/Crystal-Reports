--create or replace view d_invoice_detail as
SELECT
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      H.lastupdate Modification_Time,            -- Take the maximum date.
      H.invoice Unique_Key1,
      H.invoice,
      H.masterinvoice Master_Invoice,
      H.invoicedate Invoice_Date,
      H.invdate Invoice_Time,
      IT.code   Invoice_Type,
      IT.abbrev Invoice_Type_Abbrev,
      H.invstatus Bill_Status,
      NVL (B.abbrev, 'UNKNOWN') Bill_Status_Abbrev,
      H.custid Customer,
      C.name   Customer_Name,
      H.facility,
      H.postdate  Post_Date,
      H.printdate Print_Date,
      zbut.invoice_total (H.invoice, H.invtype) Invoice_Total,
      zcu.item_label (H.custid) Item_Label,
      zcu.lot_label (H.custid) Lot_Label,
      DECODE(H.invtype,
            'R', C.rcptname,
            'S', C.rnewname,
            'A', outbname,
            C.miscname) Name,
      DECODE(H.invtype,
            'R', C.rcptcontact,
            'S', C.rnewcontact,
            'A', outbcontact,
            C.misccontact) Contact,
      DECODE(H.invtype,
            'R', C.rcptaddr1,
            'S', C.rnewaddr1,
            'A', outbaddr1,
            C.miscaddr1) Address1,
      DECODE(H.invtype,
            'R', C.rcptaddr2,
            'S', C.rnewaddr2,
            'A', outbaddr2,
            C.miscaddr2) Address2,
      DECODE(H.invtype,
            'R', C.rcptcity,
            'S', C.rnewcity,
            'A', outbcity,
            C.misccity) City,
      DECODE(H.invtype,
            'R', C.rcptstate,
            'S', C.rnewstate,
            'A', outbstate,
            C.miscstate) State,
      DECODE(H.invtype,
            'R', C.rcptpostalcode,
            'S', C.rnewpostalcode,
            'A', outbpostalcode,
            C.miscpostalcode) Postal_Code,
      DECODE(H.invtype,
            'R', C.rcptcountrycode,
            'S', C.rnewcountrycode,
            'A', outbcountrycode,
            C.misccountrycode) Country_Code,
      DECODE(H.invtype,
            'R', C.rcptphone,
            'S', C.rnewphone,
            'A', outbphone,
            C.miscphone) Phone,
      DECODE(H.invtype,
            'R', C.rcptfax,
            'S', C.rnewfax,
            'A', outbfax,
            C.miscfax) Fax,
      DECODE(H.invtype,
            'R', C.rcptemail,
            'S', C.rnewemail,
            'A', outbemail,
            C.miscemail) Email,
      L.rcvddate Received_Date,
      L.prono Pro_Number,
      L.loadno Load_Number,
      CR.name Carrier_Name,
      DECODE(C.sumassessorial,
             'Y', 'Y',
             SUBSTR (zbut.invoice_check_sum (H.invoice), 1, 1)) Sum_Assessorial_YN,
      H.renewfromdate Renew_From_Date,
      H.renewtodate   Renew_To_Date,
      NULL OrderId,
      NULL ShipId,
      NULL PO,
      NULL Reference,
      NULL scac,
      NULL Ship_To_Name,
     (SELECT COUNT (*)
      FROM invoicehdr H2
      WHERE H2.masterinvoice = H.masterinvoice) Invoice_Count,
      H.STATUSUPDATE Status_Update
FROM
      invoicehdr          H,
      invhdrrpt_custaddr  C,
      invoicetypes        IT,
      billstatus          B,
      loads               L,
      carrier             CR
WHERE
      H.custid = C.custid(+)
  AND H.invtype = IT.code(+)
  AND H.invstatus = B.code(+)
  AND H.loadno = L.loadno(+)
  AND L.carrier = CR.carrier(+)
  AND NOT EXISTS (SELECT 1
                  FROM invoicedtl DTL, orderhdr OH
                  WHERE DTL.invoice = H.invoice
                    AND DTL.orderid = H.orderid
                    AND DTL.orderid = OH.orderid
                    AND DTL.shipid = OH.shipid)
 and h.invoice = 3818386
UNION
SELECT
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      H.lastupdate Modification_Time,            -- Take the maximum date.
      H.invoice Unique_Key1,
      H.invoice,
      H.masterinvoice,
      H.invdate,
      H.invoicedate,
      IT.code,
      IT.abbrev,
      H.invstatus,
      NVL (B.abbrev, 'UNKNOWN'),
      H.custid,
      C.name,
      H.facility,
      H.postdate,
      H.printdate,
      zbut.invoice_total (H.invoice, H.invtype),
      zcu.item_label (H.custid),
      zcu.lot_label (H.custid),
      DECODE(H.invtype,
             'R', C.rcptname,
             'S', C.rnewname,
             'A', outbname,
             C.miscname),
      DECODE(H.invtype,
             'R', C.rcptcontact,
             'S', C.rnewcontact,
             'A', outbcontact,
             C.misccontact),
      DECODE(H.invtype,
             'R', C.rcptaddr1,
             'S', C.rnewaddr1,
             'A', outbaddr1,
             C.miscaddr1),
      DECODE(H.invtype,
             'R', C.rcptaddr2,
             'S', C.rnewaddr2,
             'A', outbaddr2,
             C.miscaddr2),
      DECODE(H.invtype,
             'R', C.rcptcity,
             'S', C.rnewcity,
             'A', outbcity,
             C.misccity),
      DECODE(H.invtype,
             'R', C.rcptstate,
             'S', C.rnewstate,
             'A', outbstate,
             C.miscstate),
      DECODE(H.invtype,
             'R', C.rcptpostalcode,
             'S', C.rnewpostalcode,
             'A', outbpostalcode,
             C.miscpostalcode),
      DECODE(H.invtype,
             'R', C.rcptcountrycode,
             'S', C.rnewcountrycode,
             'A', outbcountrycode,
             C.misccountrycode),
      DECODE (H.invtype,
             'R', C.rcptphone,
             'S', C.rnewphone,
             'A', outbphone,
             C.miscphone),
      DECODE(H.invtype,
             'R', C.rcptfax,
             'S', C.rnewfax,
             'A', outbfax,
             C.miscfax),
      DECODE(H.invtype,
             'R', C.rcptemail,
             'S', C.rnewemail,
             'A', outbemail,
             C.miscemail),
      L.rcvddate,
      L.prono,
      L.loadno,
      CR.name,
      DECODE(C.sumassessorial,
             'Y', 'Y',
             SUBSTR (zbut.invoice_check_sum (H.invoice), 1, 1)),
      H.renewfromdate,
      H.renewtodate,
      OH.orderid,
      OH.shipid,
      OH.po,
      OH.reference,
      CA.scac,
      DECODE(OH.shiptoname, NULL, CO.name, OH.shiptoname),
     (SELECT COUNT (*)
      FROM invoicehdr H2
      WHERE H2.masterinvoice = H.masterinvoice),
      H.STATUSUPDATE
FROM
      invoicehdr          H,
      invhdrrpt_custaddr  C,
      invoicetypes        IT,
      billstatus          B,
      loads               L,
      carrier             CR,
      orderhdr            OH,
      carrier             CA,
      consignee           CO
WHERE
      H.custid = C.custid
  AND H.invtype = IT.code(+)
  AND H.invstatus = B.code(+)
  AND H.loadno = L.loadno(+)
  AND L.carrier = CR.carrier(+)
  AND H.orderid = OH.orderid
  AND OH.carrier = CA.carrier(+)
  AND OH.shipto = CO.consignee(+)
  AND EXISTS  (SELECT 1
               FROM invoicedtl DTL
               WHERE DTL.invoice = H.invoice
                 AND DTL.orderid = OH.orderid
                 AND DTL.shipid = OH.shipid)
    and h.invoice = 3818386
;

COMMENT ON TABLE ALPS.INVOICEHDRRPT IS '$Id: wss_invhdrrptview.sql 1002 2006-07-14 19:47:12Z eric $';
