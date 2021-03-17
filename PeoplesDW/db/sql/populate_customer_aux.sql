insert into customer_aux(
custid,
generatecofa,
lastuser,
lastupdate,
generatebolnumber,
allow_overpicking,
asnlineno,
mixed_order_shiplp_ok,
order_by_lot,
qa_by_po_item,
system_generated_lps,
trackoutboundtemps,
unique_order_identifier,
warn_overwt_orders,
warn_overwt_loads,
allow_lineitem_weights,
auto_assign_inbound_load,
estimate_cartons,
load_plate_on_label,
require_phyinv_item,
shipping_insurance,
track_picked_pf_lps
)
select
custid,
'N',
'SYSTEM',
sysdate,
'N',
'N',
'N',
'Y',
'N',
'N',
'N',
'N',
'R',
'N',
'N',
'N',
'N',
'N',
'N',
'Y',
'N',
'N'
from customer cu
where not exists(
select 1
from customer_aux cua
where cua.custid = cu.custid);

exit;

