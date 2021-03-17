--
-- $Id$
--
drop index invoicehdr_postdate_idx;
create index invoicehdr_postdate_idx on
  invoicehdr(postdate);
--exit;
