--
-- $Id: posthdr_index.sql 8548 2012-06-12 21:08:10Z eric $
--

create unique index posthdr_invoice_idx on
   posthdr(invoice);

create index posthdr_postdate_idx on
   posthdr(postdate);

exit;
