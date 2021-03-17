--
-- $Id$
--
drop index invoicehdr_status_idx;

create index invoicehdr_status_idx 
       on invoicehdr(invstatus);

exit;
