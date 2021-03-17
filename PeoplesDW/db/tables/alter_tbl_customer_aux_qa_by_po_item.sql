--
-- $Id: alter_tbl_customer_aux_qa_by_po_item.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table customer_aux add
(
qa_by_po_item char(1) default 'N'
);

exit;
