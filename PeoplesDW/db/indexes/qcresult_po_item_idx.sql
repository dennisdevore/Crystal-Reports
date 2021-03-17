--
-- $Id: qcresult_po_item_idx.sql 1 2005-05-26 12:20:03Z ed $
--
create index qcresult_po_item_idx
   on qcresult(custid,po,item);

exit;
