--
-- $Id$
--
drop index orderdtl_xdockorderid;

create index orderdtl_xdockorderid
   on orderdtl(xdockorderid);
exit;
