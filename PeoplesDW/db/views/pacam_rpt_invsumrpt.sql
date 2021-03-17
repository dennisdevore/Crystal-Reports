CREATE OR REPLACE VIEW PACAM_RPT_INVSUMRPT
(
invoice,
activity,
activityabbrev,
calceduom,
billedrate,
billmethod,
numentries,
sumqty,
sumamount
)
AS
SELECT invsumrpt.invoice, invsumrpt.activity, invsumrpt.activityabbrev,
       invsumrpt.calceduom, invsumrpt.billedrate, invsumrpt.billmethod,
       invsumrpt.numentries, invsumrpt.sumqty, invsumrpt.sumamount
  FROM (SELECT   /*+ USE_HASH (AC) */
                 id_1.invoice, id_1.activity, ac.abbrev activityabbrev,
                 id_1.calceduom, id_1.billedrate, bm.abbrev billmethod,
                 COUNT (1) numentries, SUM (id_1.billedqty) sumqty,
                 SUM (NVL (id_1.billedamt, 0)) sumamount
            FROM customer c_0, billingmethod bm, activity ac, invoicedtl id_1
           WHERE id_1.activity = ac.code
             AND id_1.billmethod = bm.code
             AND c_0.custid = id_1.custid
             AND id_1.invoice > 0
             AND id_1.invtype = 'A'
             AND NVL (c_0.sumassessorial, 'N') = 'Y'
        GROUP BY id_1.invoice,
                 id_1.activity,
                 ac.abbrev,
                 id_1.calceduom,
                 id_1.billedrate,
                 bm.abbrev
        UNION
        SELECT   ID.invoice, '', '', '', 0, '', 0, 0, 0
            FROM customer c, invoicedtl ID
           WHERE c.custid = ID.custid
             AND ID.invoice > 0
             AND (ID.invtype != 'A' OR NVL (c.sumassessorial, 'N') != 'Y')
        GROUP BY ID.invoice) invsumrpt;
        
comment on table PACAM_RPT_INVSUMRPT is '$Id: pacam_rpt_invsumrpt.sql 1 2005-05-26 14:00:00Z eric $';

exit;      