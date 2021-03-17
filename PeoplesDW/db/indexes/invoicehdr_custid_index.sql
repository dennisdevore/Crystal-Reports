--
-- $Id$
--
drop index invoicehdr_custid_idx;

create index invoicehdr_custid_idx 
       on invoicehdr(custid, facility, invtype, invstatus)
       tablespace users16kb;

exit;
