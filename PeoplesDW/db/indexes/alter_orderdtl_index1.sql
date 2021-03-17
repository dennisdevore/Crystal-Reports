--
-- $Id$
--
drop index orderdtl_childorderid;

create index orderdtl_childorderid
   on orderdtl(childorderid);
exit;
