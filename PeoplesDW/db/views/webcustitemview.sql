CREATE OR REPLACE VIEW WEBCUSTITEMVIEW
 ( FACILITY,   CUSTID, ITEM, DESCR, CNTTOTAL,   QTYTOTAL, QTYALLOC ) AS 
SELECT 
  tot.facility as facility,
  tot.custid as custid,
  tot.item as item,
  ci.descr as descr,
  sum(tot.lipcount) as CNTTOTAL,
  sum(tot.qty) as QTYTOTAL,
  zit.alloc_qty(tot.custid,
  tot.item,
  tot.facility) as QTYALLOC
FROM 
  custitem ci,
  custitemtot tot
WHERE 
  tot.custid = ci.custid  and
  tot.item = ci.item and
  tot.status not in ('D','P')
group by tot.facility,tot.custid,tot.item,ci.descr;

comment on table WEBCUSTITEMVIEW is '$Id$';

exit;
