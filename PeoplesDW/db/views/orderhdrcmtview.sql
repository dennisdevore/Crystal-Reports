create or replace view orderhdrcmtview
(orderhdrrowid
,comment1
)
as
select
orderhdr.rowid,
orderhdr.comment1
from orderhdr;
comment on table orderhdrcmtview is '$Id$';

create or replace view orderhdrcmtviewA
(
    orderhdrrowid,
    comment1
)
as
select
   OH.rowid,
   zbol.orderhdrcomments(OH.rowid)
from
    orderhdr OH;
comment on table orderhdrcmtviewA is '$Id$';

create or replace view orderidhdrcmtview
(orderid,
 shipid,
comment1
)
as
select
orderhdr.orderid,
orderhdr.shipid,
orderhdr.comment1
from orderhdr;
comment on table orderidhdrcmtview is '$Id$';

create or replace view orderidhdrcmtviewA
(orderid,
 shipid,
 comment1
)
as
select
orderhdr.orderid,
orderhdr.shipid,
zbol.orderidhdrcomments(orderhdr.orderid,orderhdr.shipid)
from orderhdr;
comment on table orderidhdrcmtviewA is '$Id$';

exit;
