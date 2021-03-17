-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimp.begin_ship_sum/zimp.end_ship_sum
drop view orderconfirmview_hp;
drop view ship_summary_hdr_hp;
drop view ship_summary_dtl_hp;
drop view noship_summary_dtl_hp;
drop view ship_summary_tot_hp;
drop view ship_summary_grand_tot_hp;
CREATE OR REPLACE VIEW ALPS.ship_summary_hdr
(custid
,company
,warehouse
)
as
select
custid,
hdrpassthruchar05,
hdrpassthruchar06
from orderconfirmview
where orderstatus = '9'
group by custid,hdrpassthruchar05,hdrpassthruchar06;

comment on table ship_summary_hdr is '$Id$';

create or replace view alps.noship_summary_dtl
(custid
,company
,warehouse
,item
,itemdescr
,qty
)
as
select
'HP',
'H50',
'HPC1',
custitem.item,
custitem.descr,
0
from custitem
where custid = 'HP'
  and status = 'ACTV'
  and not exists
    (select * from orderhdr
      where dateshipped >= '01-JUL-00'
        and dateshipped < '01-JUL-00'
        and orderstatus = '9'
        and ordertype = 'O'
        and custid = 'HP'
        and hdrpassthruchar05 = 'H50'
        and hdrpassthruchar06 = 'HPC1'
        and exists (select *
                      from orderdtl
                     where orderhdr.orderid = orderdtl.orderid
                       and orderhdr.shipid = orderdtl.shipid
                       and orderdtl.item = custitem.item));

comment on table noship_summary_dtl is '$Id$';


create or replace view alps.ship_summary_dtl
(custid
,company
,warehouse
,item
,itemdescr
,qty
)
as
select
h.custid,
h.hdrpassthruchar05,
h.hdrpassthruchar06,
d.item,
substr(zit.item_descr(h.custid,d.item),1,255),
sum(nvl(d.qtyship,0))
from orderconfirmview h, orderdtlview d
where h.orderid = d.orderid
  and h.shipid = d.shipid
  and h.qtyship != 0
  and h.orderstatus = '9'
  group by h.custid,h.hdrpassthruchar05,h.hdrpassthruchar06,d.item,
  substr(zit.item_descr(h.custid,d.item),1,255)
union
select * from noship_summary_dtl;

comment on table ship_summary_dtl is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_summary_tot
(custid
,totalseq
,company
,warehouse
,totaltype
,ordercount
)
as
select
custid,
'A',
hdrpassthruchar05,
hdrpassthruchar06,
decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS'),
count(1) - 1
from orderconfirmview
where substr(reference,1,1) = 'H'
  and orderstatus = '9'
group by custid,'A',hdrpassthruchar05,hdrpassthruchar06,
  decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS')
union
select
custid,
'B',
hdrpassthruchar05,
hdrpassthruchar06,
decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS'),
count(1) - 1
from orderconfirmview
where substr(reference,1,1) != 'H'
  and orderstatus = '9'
group by custid,'B',hdrpassthruchar05,hdrpassthruchar06,
  decode(substr(reference,1,1),'H','WEBBV ORDERS','SYKES ORDERS')
union
select
custid,
'C',
hdrpassthruchar05,
hdrpassthruchar06,
'TOTAL ORDERS',
count(1) - 2
from orderconfirmview
where orderstatus = '9'
group by custid,'C',hdrpassthruchar05,hdrpassthruchar06,'TOTAL ORDERS';

comment on table ship_summary_tot is '$Id$';

CREATE OR REPLACE VIEW ALPS.ship_summary_grand_tot
(custid
,company
,warehouse
,itemcount
)
as
select
custid,
company,
warehouse,
count(1)
from ship_summary_dtl
group by custid,company,warehouse;

comment on table ship_summary_grand_tot is '$Id$';

--exit;

