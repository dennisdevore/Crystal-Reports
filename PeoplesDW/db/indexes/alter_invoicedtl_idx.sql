--
-- $Id$
--
drop index invoicedtl_load_idx;

create index invoicedtl_load_idx on invoicedtl(loadno, custid);
exit;
