create or replace view invusageactview
(
    facility,
    custid,
    inventoryclass,
    effdate,
    item,
    receipts,
    ships,
    adjusts,
    returns
)
as
select
    facility,
    custid,
    nvl(inventoryclass,'RG'),
    effdate,
    item,
    sum(decode(trantype,'RC',adjustment,0)) ,
    sum(decode(trantype,'SH',adjustment,0)) ,
    sum(decode(trantype,'AD',adjustment,0)) ,
    sum(decode(trantype,'RT',adjustment,0))
from asofinventorydtl
group by 
    facility,
    custid,
    nvl(inventoryclass,'RG'),
    effdate,
    item;

comment on table invusageactview is '$Id$';


create or replace view invusagebalview
(
    facility,
    custid,
    inventoryclass,
    classname,
    effdate,
    item,
    itemname,
    receipts,
    ships,
    adjusts,
    returns,
    balbegin,
    balend
)
as
select
    I.facility,
    I.custid,
    I.inventoryclass,
    CL.descr,
    I.effdate,
    I.item,
    CI.descr,
    I.receipts,
    I.ships,
    I.adjusts,
    I.returns,
    zbut.asof_begin(I.facility, I.custid, I.item, 
                    I.inventoryclass, I.effdate), 
    zbut.asof_end(I.facility, I.custid, I.item, 
                  I.inventoryclass, I.effdate)
 from inventoryclass CL, custitem CI,  invusageactview I
where I.inventoryclass = CL.code(+)
  and I.custid = CI.custid(+)
  and I.item  = CI.item(+);

comment on table invusagebalview is '$Id$';

 exit;

