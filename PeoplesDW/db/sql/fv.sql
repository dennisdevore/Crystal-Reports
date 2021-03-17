--
-- $Id$
--
break on report;

compute count of lpid on report;
compute sum of quantity on report;

select
location,
parentlpid,  -- multi-pallet label
lpid,        -- child-pallet label
item,
quantity,
serialnumber,
serialerror
useritem1,
user1error
from invalidformatview
where facility = 'DTV'
and custid = '17131'
and (serialnumber is not null
  or useritem1 is not null)
order by location,parentlpid,lpid;
exit;

