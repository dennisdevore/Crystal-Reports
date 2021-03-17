CREATE OR REPLACE VIEW BILL_EXPORT_SAGE_SP1 AS
( 
   SELECT
       ih.masterinvoice,
       ih.custid        customer_id,
       ih.invoicedate   invoice_date,
       ih.postdate      post_date,
       to_date('')    due_date,
       ph.amount,
       to_number('') line_no,
       id.invoice,
       a.glacct,
       f.glid           facility_glid,
       id.billedamt
   FROM
       invoicehdr ih,
       invoicedtl id,
       facility f,
       activity a,
       posthdr ph
   WHERE
       ih.invoice = id.invoice
       AND id.facility = f.facility(+)
       AND id.activity = a.code (+)
       AND id.billstatus = 3
       AND ih.masterinvoice = ph.invoice
)
/