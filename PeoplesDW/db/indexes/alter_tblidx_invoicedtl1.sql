--
-- $Id$
--
drop index invoicedtl_idx;
create index  invoicedtl_idx on invoicedtl(
billstatus,
facility,
custid,
orderid,
shipid,
item,
activity,
activitydate);

drop index invoicedtl_inv_idx;
create index invoicedtl_inv_idx on invoicedtl(
invoice,
orderid,
shipid,
item,
lotnumber);

drop index invoicedtl_ord_idx;
create index invoicedtl_ord_idx on invoicedtl(
orderid,
shipid,
orderitem,
orderlot);

--exit;
