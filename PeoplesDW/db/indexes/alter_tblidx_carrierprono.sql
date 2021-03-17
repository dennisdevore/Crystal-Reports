--
-- $Id$
--
drop index carrierprono_assign_status_idx;

create index carrierprono_assign_status_idx on carrierprono
(carrier, zone, assign_status);

drop index carrierprono_idx;

create unique index carrierprono_idx on carrierprono
(carrier, zone, seq);

drop index carrierprono_prono_idx;

create unique index carrierprono_prono_idx on carrierprono
(carrier, zone, prono);
--exit