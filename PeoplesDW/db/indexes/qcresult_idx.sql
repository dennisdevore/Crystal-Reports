--
-- $Id$
--
drop index pk_qcresult;

create unique index pk_qcresult 
       on qcresult(id, orderid, shipid, item, lotnumber);

drop index qcresult_order_idx;

create index qcresult_order_idx
       on qcresult(orderid, shipid, id);

-- exit