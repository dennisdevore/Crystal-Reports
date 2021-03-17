create or replace view orderdtlorderlotcmtview as
select od.orderid,od.shipid,od.item,sp.lotnumber,sp.orderlot,od.comment1  
	from orderdtl od, shippingplate sp
	where od.orderid = sp.orderid and
		od.shipid = sp.shipid and
		od.item = sp.item and
		od.lotnumber = sp.orderlot and
		od.comment1 is not null and
		sp.lotnumber <> sp.orderlot;

comment on table orderdtlorderlotcmtview is '$Id$';

exit;
