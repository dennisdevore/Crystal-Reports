--
-- $Id: qcrequest_po_idx.sql 1 2005-05-26 12:20:03Z ed $
--
create index qcrequest_po_idx
   on qcrequest(custid,po);

exit;
