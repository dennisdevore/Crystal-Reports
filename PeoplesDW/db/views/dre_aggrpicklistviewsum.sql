create or replace view DRE_AGGRPICKLISTVIEWSUM as
select orderid,shipid,item,uom,sum(qty) as qty, sum(wght) as wght, sum(grossweight) as grossweight
from DRE_AGGRPICKLISTVIEW
group by orderid, shipid,item,uom;
comment on table DRE_AGGRPICKLISTVIEWSUM is '$Id$';
exit;
