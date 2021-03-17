--
-- $Id$
--
create index invoicehdr_post_idx on
  invoicehdr(custid,postdate);
exit;
