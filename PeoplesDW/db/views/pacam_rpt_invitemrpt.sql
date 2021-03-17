CREATE OR REPLACE VIEW PACAM_RPT_INVITEMRPT
(
idrowid,
invoice,
billstatus,
billstatusabbev,
facility,
custid,
orderid,
shipid,
po,
item,
lotnumber,
activitydate,
activity,
activityabbrev,
enteredqty,
entereduom,
calceduom,
billedqty,
billedrate,
billedamt,
minimum,
minimumord,
calculation,
sumamount,
billmethod,
weight,
useinvoice,
moduom
)
as
SELECT invitemrpt.idrowid, invitemrpt.invoice, invitemrpt.billstatus,
       invitemrpt.billstatusabbev, invitemrpt.facility, invitemrpt.custid,
       invitemrpt.orderid, invitemrpt.shipid, invitemrpt.po, invitemrpt.item,
       invitemrpt.lotnumber, invitemrpt.activitydate, invitemrpt.activity,
       invitemrpt.activityabbrev, invitemrpt.enteredqty,
       invitemrpt.entereduom, invitemrpt.calceduom, invitemrpt.billedqty,
       invitemrpt.billedrate, invitemrpt.billedamt, invitemrpt.MINIMUM,
       invitemrpt.minimumord, invitemrpt.calculation, invitemrpt.sumamount,
       invitemrpt.billmethod, invitemrpt.weight, invitemrpt.useinvoice,
       invitemrpt.moduom
  FROM (SELECT /*+ USE_HASH (AC_3) */
               id_4.ROWID idrowid, id_4.invoice, id_4.billstatus,
               bs_2.abbrev billstatusabbev, id_4.facility, id_4.custid,
               DECODE (id_4.orderid, 0, 99999999, id_4.orderid) orderid,
               NVL (id_4.shipid, 1) shipid, id_4.po, id_4.item,
               id_4.lotnumber, id_4.activitydate, id_4.activity,
               ac_3.abbrev activityabbrev, id_4.enteredqty, id_4.entereduom,
               id_4.calceduom, id_4.billedqty, id_4.billedrate,
               id_4.billedamt, id_4.MINIMUM,
               DECODE (id_4.billmethod,
                       'SCLN', 11,
                       'SCIT', 12,
                       'SCOR', 13,
                       'SCIN', 14,
                       'LINE', 1,
                       'ITEM', 2,
                       'ORDR', 3,
                       'INV', 4,
                       'ACCT', 0,
                       NVL (id_4.MINIMUM, 0)
                      ) minimumord,
               DECODE (NVL (id_4.MINIMUM, -1),
                       -1, TO_CHAR (id_4.billedqty)
                        || ' '
                        || id_4.calceduom
                        || ' @ '
                        || DECODE (id_4.billedrate * 100,
                                   FLOOR (id_4.billedrate * 100), LTRIM
                                                    (TO_CHAR (id_4.billedrate,
                                                              '999,990.99'
                                                             )
                                                    ),
                                   LTRIM (TO_CHAR (id_4.billedrate))
                                  ),
                       DECODE (SUBSTR (id_4.billmethod, 1, 2),
                               'SC', ' Surcharge @ '
                                || LTRIM (TO_CHAR (id_4.MINIMUM, '990.99'))
                                || '%',
                                  ' Min Adj @ '
                               || LTRIM (TO_CHAR (id_4.MINIMUM, '999,990.99'))
                              )
                      ) calculation,
               NVL (id_4.billedamt, 0) sumamount,
               DECODE (id_4.billmethod,
                       'QTYM', bm_1.abbrev || '-' || id_4.moduom,
                       bm_1.abbrev
                      ) billmethod,
               id_4.weight, id_4.useinvoice, id_4.moduom
          FROM customer c_0,
               billingmethod bm_1,
               billstatus bs_2,
               activity ac_3,
               invoicedtl id_4
         WHERE id_4.billstatus = bs_2.code(+)
           AND id_4.activity = ac_3.code(+)
           AND id_4.billmethod = bm_1.code(+)
           AND id_4.invoice > 0
           AND id_4.billedqty > 0
           AND id_4.billstatus != '4'
           AND c_0.custid = id_4.custid
           AND id_4.invtype != 'A'
        UNION
        SELECT   id_9.ROWID, id_9.invoice, id_9.billstatus, bs_7.abbrev,
                 id_9.facility, id_9.custid,
                 DECODE (SIGN (id_9.orderid), 1, id_9.orderid, NULL),
                 NVL (id_9.shipid, 1), id_9.po, NULL, NULL,
                 TRUNC (id_9.activitydate), id_9.activity, ac_8.abbrev, 0,
                 ' ', id_9.calceduom, SUM (id_9.billedqty), id_9.billedrate,
                 SUM (id_9.billedamt), id_9.MINIMUM,
                 DECODE (id_9.billmethod,
                         'SCLN', 11,
                         'SCIT', 12,
                         'SCOR', 13,
                         'SCIN', 14,
                         'LINE', 1,
                         'ITEM', 2,
                         'ORDR', 3,
                         'INV', 4,
                         'ACCT', 0,
                         NVL (id_9.MINIMUM, 0)
                        ),
                 ' ', 0,
                 DECODE (id_9.billmethod,
                         'QTYM', bm_6.abbrev || '-' || id_9.moduom,
                         bm_6.abbrev
                        ),
                 0, id_9.useinvoice, id_9.moduom
            FROM customer c_5,
                 billingmethod bm_6,
                 billstatus bs_7,
                 activity ac_8,
                 invoicedtl id_9
           WHERE id_9.billstatus = bs_7.code(+)
             AND id_9.activity = ac_8.code(+)
             AND id_9.billmethod = bm_6.code(+)
             AND id_9.invoice > 0
             AND id_9.billedqty > 0
             AND id_9.billstatus != '4'
             AND c_5.custid = id_9.custid
             AND id_9.invtype = 'A'
             AND NVL (c_5.sumassessorial, 'N') != 'Y'
        GROUP BY id_9.ROWID,
                 id_9.invoice,
                 id_9.billstatus,
                 bs_7.abbrev,
                 id_9.facility,
                 id_9.custid,
                 DECODE (SIGN (id_9.orderid), 1, id_9.orderid, NULL),
                 NVL (id_9.shipid, 1),
                 id_9.po,
                 NULL,
                 NULL,
                 TRUNC (id_9.activitydate),
                 id_9.activity,
                 ac_8.abbrev,
                 0,
                 ' ',
                 id_9.calceduom,
                 id_9.billedrate,
                 id_9.MINIMUM,
                 DECODE (id_9.billmethod,
                         'SCLN', 11,
                         'SCIT', 12,
                         'SCOR', 13,
                         'SCIN', 14,
                         'LINE', 1,
                         'ITEM', 2,
                         'ORDR', 3,
                         'INV', 4,
                         'ACCT', 0,
                         NVL (id_9.MINIMUM, 0)
                        ),
                 ' ',
                 0,
                 DECODE (id_9.billmethod,
                         'QTYM', bm_6.abbrev || '-' || id_9.moduom,
                         bm_6.abbrev
                        ),
                 0,
                 id_9.useinvoice,
                 id_9.moduom
        UNION
        SELECT   DECODE (c.custid, 'JoW', c.ROWID, NULL), ID.invoice, NULL,
                 NULL, NULL, ID.custid, ih.orderid, 1, NULL, NULL, NULL,
                 TRUNC (SYSDATE), NULL, NULL, 0, NULL, NULL, 0, 0, 0, 0, 0,
                 NULL, 0, NULL, 0, NULL, NULL
            FROM customer c,
                 billingmethod bm,
                 billstatus bs,
                 activity ac,
                 invoicehdr ih,
                 invoicedtl ID
           WHERE ID.billstatus = bs.code(+)
             AND ID.activity = ac.code(+)
             AND ID.billmethod = bm.code(+)
             AND ID.invoice > 0
             AND ID.billedqty > 0
             AND ID.billstatus != '4'
             AND c.custid = ID.custid
             AND ID.invtype = 'A'
             AND NVL (c.sumassessorial, 'N') = 'Y'
             AND ih.invoice = ID.invoice
        GROUP BY DECODE (c.custid, 'JoW', c.ROWID, NULL),
                 ID.invoice,
                 ih.orderid,
                 1,
                 ID.custid,
                 TRUNC (SYSDATE)) invitemrpt;

comment on table PACAM_RPT_INVITEMRPT is '$Id: pacam_rpt_invitemrpt.sql 1 2005-05-26 14:00:00Z eric $';

exit;                 