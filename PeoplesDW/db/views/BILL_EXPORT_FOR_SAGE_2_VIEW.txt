CREATE OR REPLACE FORCE VIEW "ALPS"."BILL_EXPORT_FOR_SAGE_2_VIEW" ("INVOICE", "POSTDATE", "INVDATE", "CUSTID", "FACILITY", "INVTYPE", "BILLEDAMT") AS 
  SELECT
    P.invoice,
    P.postdate,
    P.invdate,
    IH.custid,
    IH.facility,
    IH.invtype,
    SUM(ID.billedamt)
  FROM
    posthdr P,
    invoicehdr IH,
    invoicedtl ID
  WHERE
    IH.masterinvoice = TO_CHAR(P.invoice, 'FM09999999')
  AND IH.invstatus   = '3'
  AND ID.invoice     = IH.invoice
  AND ID.billstatus  = '3'
  AND IH.facility   <> 'VIS'
  GROUP BY
    P.invoice,
    P.postdate,
    P.invdate,
    P.amount,
    IH.custid,
    IH.facility,
    IH.invtype;
 

   COMMENT ON TABLE "ALPS"."BILL_EXPORT_FOR_SAGE_2_VIEW"  IS '$Id: bill_export_for_sage_2_view.sql 135 2014-05-08 08:59:48Z kcb $';