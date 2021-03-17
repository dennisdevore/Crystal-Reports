--
-- $Id$
--
insert into orderpriority 
    values('B','Back Order','Back Order','N','SUP',sysdate);
insert into orderpriority 
    values('D','Drop Shipment','Drop Ship','N','SUP',sysdate);
commit;

exit;
