--
-- $Id$
--
drop index orderhdr_workorderseq;

create index orderhdr_workorderseq
   on orderhdr(workorderseq);

drop index orderhdr_parentorderid;

create index orderhdr_parentorderid
   on orderhdr(parentorderid);
exit;
