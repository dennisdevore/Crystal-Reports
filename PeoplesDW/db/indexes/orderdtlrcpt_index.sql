--
-- $Id$
--
drop index orderdtlrcpt_orderdtl_idx;

create index orderdtlrcpt_orderdtl_idx
   on orderdtlrcpt(orderid,shipid,orderitem,orderlot,lpid);

exit;
