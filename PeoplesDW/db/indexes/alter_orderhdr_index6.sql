--
-- $Id$
--
drop index orderhdr_prono_idx;

create index orderhdr_prono_idx
on orderhdr(prono);
exit;
