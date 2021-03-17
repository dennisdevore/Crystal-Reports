create or replace view orderdtlcmtview
(orderdtlrowid
,comment1
)
as
select
orderdtl.rowid,
comment1
from orderdtl;
comment on table orderdtlcmtview is '$Id$';

create or replace view orderdtlcmtviewA
(orderdtlrowid
,comment1
)
as
select
orderdtl.rowid,
zbol.orderdtlcomments(orderdtl.rowid)
from orderdtl;
comment on table orderdtlcmtviewA is '$Id$';

create or replace view orderiddtlcmtview
(orderid,
 shipid,
comment1
)
as
select
orderdtl.orderid,
orderdtl.shipid,
orderdtl.comment1
from orderdtl;
comment on table orderiddtlcmtview is '$Id$';

create or replace view orderiddtlcmtviewA
(orderid,
 shipid,
 comment1
)
as
select
orderdtl.orderid,
orderdtl.shipid,
zbol.orderiddtlcomments(orderdtl.orderid,orderdtl.shipid)
from orderdtl;
comment on table orderiddtlcmtviewA is '$Id$';

exit;
