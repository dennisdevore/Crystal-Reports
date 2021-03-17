--
-- $Id$
--
drop index orderhdr_rma_idx;

create index orderhdr_rma_idx
on orderhdr(rma);
exit;
