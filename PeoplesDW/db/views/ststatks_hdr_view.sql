create or replace view alps.ststatks_hdr
(custid
,facility
,date_created
,time_created
,freezer_id
,item
,descr
,lpid
,quantity
,uom)
as
select
p.custid,
p.facility,
to_char(sysdate, 'MMDDYYYY'),
to_char(sysdate, 'HHMM'),
null,
p.item,
i.descr,
p.lpid,
trunc(p.weight),
'LBS'
from plate p, custitem i, orderhdr o
where p.type = 'PA'
  and p.invstatus != 'SU'
  and p.orderid = o.orderid(+)
  and p.shipid = o.shipid(+)
  and nvl(o.orderstatus,'R') = 'R'
  and p.custid = i.custid
  and p.item = i.item;


