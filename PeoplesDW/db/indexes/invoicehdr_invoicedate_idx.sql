--
-- $Id$
--
--drop index invoicehdr_invoicedate_idx;

create index invoicehdr_invoicedate_idx on invoicehdr(facility, invoicedate)
tablespace users16kb;
exit;
