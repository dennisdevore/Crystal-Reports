create or replace view custuombaseview
(custid
,item
,abbrev
,baseuom
)
as
select
custitem.custid,
custitem.item,
unitsofmeasure.abbrev,
baseuom
from custitem, unitsofmeasure
where custitem.baseuom = unitsofmeasure.code (+);

comment on table custuombaseview is '$Id$';

create or replace view custuomfromview
(custid
,item
,abbrev
,fromuom
)
as
select
custitemuom.custid,
custitemuom.item,
unitsofmeasure.abbrev,
fromuom
from custitemuom, custitem, unitsofmeasure
where custitemuom.custid = custitem.custid
  and custitemuom.item = custitem.item
  and custitemuom.fromuom = unitsofmeasure.code (+);
  
comment on table custuomfromview is '$Id$';

create or replace view custuomtoview
(custid
,item
,abbrev
,touom
)
as
select
custitemuom.custid,
custitemuom.item,
unitsofmeasure.abbrev,
touom
from custitemuom, custitem, unitsofmeasure
where custitemuom.custid = custitem.custid
  and custitemuom.item = custitem.item
  and custitemuom.touom = unitsofmeasure.code (+);

comment on table custuomtoview is '$Id$';

create or replace view custuomallview
(custid
,item
,abbrev
,uom
)
as
select custid,item,abbrev,baseuom
  from custuombaseview
union
select custid,item,abbrev,fromuom
  from custuomfromview
union
select custid,item,abbrev,touom
  from custuomtoview;

comment on table custuomallview is '$Id$';

create or replace view custuomview
(custid
,item
,abbrev
,uom
)
as
select distinct custid,item,abbrev,uom
from custuomallview;

comment on table custuomview is '$Id$';

exit;
