CREATE OR REPLACE VIEW PACAM_RPT_INVOICEHDRRPT
(
 masterinvoice,
 invoice,
 invdate,
 invoicedate,
 invtypecode,
 invtype,
 invstatus,
 invstatusdesc,
 custid,
 custname,
 facility,
 postdate,
 printdate,
 invtotal,
 item_label,
 lot_label,
 name,
 contact,
 addr1,
 addr2,
 city,
 state,
 postalcode,
 countrycode,
 phone,
 fax,
 email,
 rcvddate,
 prono,
 loadno,
 carrier,
 sumassessorial,
 reference,
 renewfromdate,
 renewtodate
)
as
SELECT /*+ USE_HASH (B) */
       h.masterinvoice, h.invoice, h.invdate, h.invoicedate,
       it.code invtypecode, it.abbrev invtype, h.invstatus,
       NVL (b.abbrev, 'UNKNOWN') invstatusdesc, h.custid, c.NAME custname,
       h.facility, h.postdate, h.printdate,
       alps.zbillutility.invoice_total (h.invoice, h.invtype) invtotal,
       alps.zcustomer.item_label (h.custid) item_label,
       alps.zcustomer.lot_label (h.custid) lot_label, ca.NAME NAME,
       ca.contact contact, ca.addr1 addr1, ca.addr2 addr2, ca.city city,
       ca.state state, ca.postalcode postalcode, ca.countrycode countrycode,
       ca.phone phone, ca.fax fax, ca.email email, l.rcvddate, l.prono,
       l.loadno, cr.NAME carrier,
       DECODE
          (NVL (c.sumassessorial, 'N'),
           'Y', 'Y',
           SUBSTR (alps.zbillutility.invoice_check_sum (h.invoice), 1, 1)
          ) sumassessorial,
       oh.REFERENCE, h.renewfromdate, h.renewtodate
  FROM billstatus b,
       invoicetypes it,
       (SELECT customer_0.custid, 'R' invtype,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.NAME,
                       customer_0.rcptname
                      ) NAME,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.contact,
                       customer_0.rcptcontact
                      ) contact,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.addr1,
                       customer_0.rcptaddr1
                      ) addr1,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.addr2,
                       customer_0.rcptaddr2
                      ) addr2,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.city,
                       customer_0.rcptcity
                      ) city,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.state,
                       customer_0.rcptstate
                      ) state,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.postalcode,
                       customer_0.rcptpostalcode
                      ) postalcode,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.countrycode,
                       customer_0.rcptcountrycode
                      ) countrycode,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.phone,
                       customer_0.rcptphone
                      ) phone,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.fax,
                       customer_0.rcptfax
                      ) fax,
               DECODE (customer_0.rcptname,
                       NULL, customer_0.email,
                       customer_0.rcptemail
                      ) email
          FROM customer customer_0
        UNION
        SELECT customer_1.custid, 'S',
               DECODE (customer_1.rnewname,
                       NULL, customer_1.NAME,
                       customer_1.rnewname
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.contact,
                       customer_1.rnewcontact
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.addr1,
                       customer_1.rnewaddr1
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.addr2,
                       customer_1.rnewaddr2
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.city,
                       customer_1.rnewcity
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.state,
                       customer_1.rnewstate
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.postalcode,
                       customer_1.rnewpostalcode
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.countrycode,
                       customer_1.rnewcountrycode
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.phone,
                       customer_1.rcptphone
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.fax,
                       customer_1.rnewfax
                      ),
               DECODE (customer_1.rnewname,
                       NULL, customer_1.email,
                       customer_1.rnewemail
                      )
          FROM customer customer_1
        UNION
        SELECT customer_2.custid, 'M',
               DECODE (customer_2.miscname,
                       NULL, customer_2.NAME,
                       customer_2.miscname
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.contact,
                       customer_2.misccontact
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.addr1,
                       customer_2.miscaddr1
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.addr2,
                       customer_2.miscaddr2
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.city,
                       customer_2.misccity
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.state,
                       customer_2.miscstate
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.postalcode,
                       customer_2.miscpostalcode
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.countrycode,
                       customer_2.misccountrycode
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.phone,
                       customer_2.rcptphone
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.fax,
                       customer_2.miscfax
                      ),
               DECODE (customer_2.miscname,
                       NULL, customer_2.email,
                       customer_2.miscemail
                      )
          FROM customer customer_2
        UNION
        SELECT customer_3.custid, 'A',
               DECODE (customer_3.outbname,
                       NULL, customer_3.NAME,
                       customer_3.outbname
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.contact,
                       customer_3.outbcontact
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.addr1,
                       customer_3.outbaddr1
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.addr2,
                       customer_3.outbaddr2
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.city,
                       customer_3.outbcity
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.state,
                       customer_3.outbstate
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.postalcode,
                       customer_3.outbpostalcode
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.countrycode,
                       customer_3.outbcountrycode
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.phone,
                       customer_3.rcptphone
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.fax,
                       customer_3.outbfax
                      ),
               DECODE (customer_3.outbname,
                       NULL, customer_3.email,
                       customer_3.outbemail
                      )
          FROM customer customer_3) ca,
       customer c,
       carrier cr,
       loads l,
       orderhdr oh,
       invoicehdr h
 WHERE h.custid = c.custid(+)
   AND h.invtype = it.code(+)
   AND h.invstatus = b.code(+)
   AND h.loadno = l.loadno(+)
   AND l.carrier = cr.carrier(+)
   AND h.custid = ca.custid
   AND h.orderid = oh.orderid(+)
   AND 1 = oh.shipid(+)
   AND DECODE (h.invtype, 'C', 'M', h.invtype) = ca.invtype;

comment on table PACAM_RPT_INVOICEHDRRPT is '$Id: pacam_rpt_invoicehdrrpt.sql 1 2005-05-26 14:00:00Z eric $';

exit;   