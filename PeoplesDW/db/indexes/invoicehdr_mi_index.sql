--
-- $Id$
--
drop index invoicehdr_mi_idx;

create index invoicehdr_mi_idx on invoicehdr(masterinvoice);

exit;
