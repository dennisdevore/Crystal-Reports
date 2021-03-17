create or replace view custitembolcommentsview
(
custid,
item,
consignee,
comment1,
lastuser,
lastupdate,
consigneename,
customername
)
as
select
custitembolcomments.custid,
custitembolcomments.item,
custitembolcomments.consignee,
custitembolcomments.comment1,
custitembolcomments.lastuser,
custitembolcomments.lastupdate,
nvl(consignee.name,'(Default)'),
nvl(customer.lookup,'(Default)')
from custitembolcomments, consignee, customer
where custitembolcomments.consignee = consignee.consignee(+)
  and custitembolcomments.custid = customer.custid(+);
  
comment on table custitembolcommentsview is '$Id$';
  


create or replace view custitembolcommentsviewA
(
custid,
item,
consignee,
comment1,
lastuser,
lastupdate,
consigneename,
customername
)
as
select
custitembolcomments.custid,
custitembolcomments.item,
custitembolcomments.consignee,
zbol.custitembolcomments(custitembolcomments.custid,
	custitembolcomments.item,custitembolcomments.consignee),
custitembolcomments.lastuser,
custitembolcomments.lastupdate,
nvl(consignee.name,'(Default)'),
nvl(customer.lookup,'(Default)')
from custitembolcomments, consignee, customer
where custitembolcomments.consignee = consignee.consignee(+)
  and custitembolcomments.custid = customer.custid(+);
  
comment on table custitembolcommentsviewA is '$Id$';


create or replace view custitemincommentsview
(
custid,
item,
comment1,
lastuser,
lastupdate,
itemdescr
)
as
select
custitemincomments.custid,
custitemincomments.item,
custitemincomments.comment1,
custitemincomments.lastuser,
custitemincomments.lastupdate,
custitem.descr
from custitemincomments, custitem
where custitemincomments.custid = custitem.custid(+)
  and custitemincomments.item = custitem.item(+);
  
comment on table custitemincommentsview is '$Id$';
  
create or replace view custitemincommentsviewa
(
custid,
item,
comment1,
lastuser,
lastupdate,
itemdescr
)
as
select
custitemincomments.custid,
custitemincomments.item,
zbol.custitemincomments(custitemincomments.custid,
	custitemincomments.item),
custitemincomments.lastuser,
custitemincomments.lastupdate,
custitem.descr
from custitemincomments, custitem
where custitemincomments.custid = custitem.custid(+)
  and custitemincomments.item = custitem.item(+);
  
comment on table custitemincommentsviewa is '$Id$';
  
create or replace view custitemoutcommentsview
(
custid,
item,
consignee,
comment1,
lastuser,
lastupdate,
consigneename,
itemdescr,
customername
)
as
select
custitemoutcomments.custid,
custitemoutcomments.item,
custitemoutcomments.consignee,
custitemoutcomments.comment1,
custitemoutcomments.lastuser,
custitemoutcomments.lastupdate,
nvl(consignee.name,'(Default)'),
custitem.descr,
nvl(customer.lookup,'(Default)')
from custitemoutcomments, consignee, custitem, customer
where custitemoutcomments.consignee = consignee.consignee(+)
  and custitemoutcomments.custid = customer.custid(+)
  and custitemoutcomments.custid = custitem.custid(+)
  and custitemoutcomments.item = custitem.item(+);
  
comment on table custitemoutcommentsview is '$Id$';
  
create or replace view custitemoutcommentsviewa
(
custid,
item,
consignee,
comment1,
lastuser,
lastupdate,
consigneename,
itemdescr,
customername
)
as
select
custitemoutcomments.custid,
custitemoutcomments.item,
custitemoutcomments.consignee,
zbol.custitemoutcomments(custitemoutcomments.custid,
	custitemoutcomments.item,custitemoutcomments.consignee),
custitemoutcomments.lastuser,
custitemoutcomments.lastupdate,
nvl(consignee.name,'(Default)'),
custitem.descr,
nvl(customer.lookup,'(Default)')
from custitemoutcomments, consignee, custitem, customer
where custitemoutcomments.consignee = consignee.consignee(+)
  and custitemoutcomments.custid = customer.custid(+)
  and custitemoutcomments.custid = custitem.custid(+)
  and custitemoutcomments.item = custitem.item(+);
  
comment on table custitemoutcommentsviewa is '$Id$';
  
exit;
