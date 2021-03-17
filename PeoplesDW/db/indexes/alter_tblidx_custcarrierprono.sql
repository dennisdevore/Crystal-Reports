--
-- $Id$
--
drop index custcarrierprono_idx;

create unique index custcarrierprono_idx on custcarrierprono
(custid,carrier);
--exit;


