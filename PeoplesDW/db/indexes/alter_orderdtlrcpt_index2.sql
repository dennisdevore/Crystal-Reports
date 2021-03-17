--
-- $Id$
--
drop index orderdtlrcpt_orderdtl_idx;
drop index orderdtlrcpt_serial_idx;
drop index orderdtlrcpt_user1_idx;
drop index orderdtlrcpt_user2_idx;
drop index orderdtlrcpt_user3_idx;

create index orderdtlrcpt_orderdtl_idx
   on orderdtlrcpt(orderid, shipid, orderitem, orderlot, lpid);

create index orderdtlrcpt_serial_idx
   on orderdtlrcpt(custid, item, serialnumber);

create index orderdtlrcpt_user1_idx
   on orderdtlrcpt(custid, item, useritem1);

create index orderdtlrcpt_user2_idx
   on orderdtlrcpt(custid, item, useritem2);

create index orderdtlrcpt_user3_idx
   on orderdtlrcpt(custid, item, useritem3);

exit;
