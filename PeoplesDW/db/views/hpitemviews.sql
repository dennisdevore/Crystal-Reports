create or replace view hpitemview
(custid
,item
,weight
,cube
,picktotype
,cartontype
,profid
,expiryaction
,expdaterequired
,fifowindowdays
,allocrule
,productgroup
,serialrequired
)
as
select
custid,
item,
weight,
cube,
picktotype,
cartontype,
profid,
expiryaction,
expdaterequired,
fifowindowdays,
allocrule,
productgroup,
serialrequired
from custitemview;

comment on table hpitemview is '$Id$';

create or replace view hpitemaliasview
(custid
,item
,alias
)
as
select
custid,
item,
itemalias
from custitemalias;

comment on table hpitemaliasview is '$Id$';

create or replace view hpitempickfrontsview
(custid
,item
,pickfront
,minqty
,minuom
,maxqty
,maxuom
)
as
select
custid,
item,
pickfront,
replenishqty,
replenishuom,
maxqty,
maxuom
from itempickfronts;

comment on table hpitempickfrontsview is '$Id$';

exit;
