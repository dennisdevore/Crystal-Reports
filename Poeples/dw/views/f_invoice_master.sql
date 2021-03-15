--CREATE OR REPLACE FORCE VIEW ALPS.INVOICEMASTER
--(
--   MASTERINVOICE,
--   INVSTATUS,
--   CUSTID,
--   CUSTNAME,
--   FACILITY,
--   POSTDATE,
--   PRINTDATE,
--   INVTOTAL,
--   USERID,
--   CSR,
--   INVOICEDATE
--)
--AS
SELECT
      sys_context('USERENV','SERVICE_NAME') DB_Service_Name,
      H.lastupdate Modification_Time,            -- Take the maximum date.
      H.masterinvoice Master_Invoice,
      H.invstatus Bill_Status,
      H.custid Customer,
      C.name Customer_Name,
      H.facility,
      H.postdate  Post_Date,
      H.printdate Print_Date,
      SUM(  NVL (D.billedamt, (NVL (D.calcedamt, 0)))
          * DECODE (D.invtype, 'C', -1, 1)) Invoice_Total,
      H.lastuser Last_Update_User,
      C.csr,
      H.invoicedate Ivoice_Date
FROM
      billstatus B,
      customer   C,
      invoicedtl D,
      invoicehdr H
WHERE
      H.custid = C.custid(+)
  AND H.invstatus = B.code(+)
  AND H.invoice = D.invoice(+)
  AND '4' != D.billstatus(+)
  AND H.masterinvoice IS NOT NULL
and h.invoice = 3818386
GROUP BY
      H.lastupdate,
      H.masterinvoice,
      H.invstatus,
      H.custid,
      C.name,
      H.facility,
      H.postdate,
      H.printdate,
      H.lastuser,
      C.csr,
      H.invoicedate;