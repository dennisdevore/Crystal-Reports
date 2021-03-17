--
-- $Id: custitem_dimensions.sql 1 2013-05-02 12:20:03Z ay $
--
create table custitem_inbound_dimensions
(custid varchar2(10) not null
,item   varchar2(20) not null
,uom varchar2(4) not null
,invclass varchar2(2) not null
,length number(10,4) not null
,width  number(10,4) not null
,height number(10,4) not null
,pallet_weight number(10,4) not null
,lastuser varchar2(12)
,lastupdate date
);

create unique index custitem_inbound_dimensions_ix on 
                    custitem_inbound_dimensions(custid, item,uom,invclass);
exit;
