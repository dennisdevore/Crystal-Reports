--
-- $Id$
--
drop index orderhdr_importfileid_idx;

create index orderhdr_importfileid_idx
on orderhdr(importfileid);
exit;
