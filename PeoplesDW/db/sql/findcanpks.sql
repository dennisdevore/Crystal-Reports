--
-- $Id$
--
select T.orderid, T.taskid, T.tasktype, T.curruserid, T.priority
	from tasks T, orderhdr H
	where T.tasktype in ('PK','OP')
	  and T.orderid = H.orderid
	  and H.orderstatus = 'X'
	order by T.orderid
/
