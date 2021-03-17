-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zim6.begin_I9_inv_adj/zim6.end_I9_inv_adj

create or replace view alps.I9_inv_adj_dtl
(custid
,statusupdate
,movement
,specialstock
,reason
,item
,lpid
,origpo
,origpolinenumber
,salable_yn
,fromstorageloc
,tostorageloc
,qtyavailable
,qtynonsalable
,qtydamaged
,qty
,uom
,lotnumber
,manufacturedate
,adjuser
,useramt1
,useramt2
,invstatus
,custreference
,oldinvstatus
,newinvstatus
,facility
)
as
select
custid,
whenoccurred,
'001',
'K',
'PC',
item,
lpid,
useritem1,
999,
'Y',
adjuser,
lastuser,
adjqty,
nvl(adjqty,0),
nvl(adjqty,1),
nvl(adjqty,2),
uom,
lotnumber,
lastupdate,
adjuser,
nvl(adjqty,3),
nvl(adjqty,4),
invstatus,
custreference,
oldinvstatus,
newinvstatus,
facility
from invadjactivity
where rowid = '1';

comment on table I9_inv_adj_dtl is '$Id';

CREATE OR REPLACE VIEW ALPS.I9_inv_adj_hdr
(custid
,statusupdate
,movement
,specialstock
,reason
,item
,lpid
,origpo
,origpolinenumber
,salable_yn
,facility
)
as
select
distinct
 custid
,statusupdate
,movement
,specialstock
,reason
,item
,lpid
,origpo
,origpolinenumber
,salable_yn
,facility
from I9_inv_adj_dtl;

comment on table I9_inv_adj_hdr is '$Id';



create or replace view I9_inv_adj_sum
(custid
,statusupdate
,movement
,reason
,item
,uom
,lotnumber
,qtyavailable
,qtynonsalable
,qtydamaged
,qty
,invstatus
,custreference
,oldinvstatus
,newinvstatus
,facility
)
as
select
custid,
whenoccurred,
'001',
'PC',
item,
uom,
lotnumber,
nvl(adjqty,0),
nvl(adjqty,1),
nvl(adjqty,2),
nvl(adjqty,4),
invstatus,
custreference,
oldinvstatus,
newinvstatus,
facility
from invadjactivity
where rowid = '1';

exit;