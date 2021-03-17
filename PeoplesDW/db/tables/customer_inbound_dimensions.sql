--
-- $Id: customer_dimensions.sql 1 2013-05-02 12:20:03Z ay $
--
create table cust_inbound_dimensions
(custid varchar2(10) not null
,uom varchar2(4) not null
,invclass varchar2(2) not null
,length number(10,4) not null
,width  number(10,4) not null
,height number(10,4) not null
,pallet_weight number(10,4) not null
,lastuser varchar2(12)
,lastupdate date
);

create unique index cust_inbound_dimensions_idx on 
                    cust_inbound_dimensions(custid,uom,invclass);
exit;
                   
