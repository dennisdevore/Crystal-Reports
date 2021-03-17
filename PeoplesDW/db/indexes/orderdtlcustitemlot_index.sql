--
-- $Id$
--
--drop index orderdtl_custitemlot_idx;

create index orderdtl_custitemlot_idx
   on orderdtl(custid, item, lotnumber) tablespace users16kb;

exit;
