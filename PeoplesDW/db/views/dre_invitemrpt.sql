create or replace view dre_invitemrpt as
select i.idrowid,
i.invoice,
i.billstatus,
i.billstatusabbev,
i.facility,
i.custid,
i.orderid,
i.shipid,
i.po,
i.item,
nvl(i.lotnumber,'**NULL**') lotnumber,
i.activitydate,
i.activity,
i.activityabbrev,
i.enteredqty,
i.entereduom,
i.calceduom,
i.billedqty,
i.billedrate,
i.billedamt,
i.minimum,
i.minimumord,
i.calculation,
i.sumamount,
i.billmethod,
i.weight,
i.useinvoice,
i.moduom,
i.lpid,
i.gross,
i.length,
i.width,
i.height,
i.revenuegroup,
id.billmethod billmethodbase,
zinvcmt.invitemexpdate(i.orderid, i.shipid, i.item,i.lotnumber) expirationdate,
zinvcmt.invitemmandate(i.orderid, i.shipid, i.item,i.lotnumber) manufacturedate,
zinvcmt.invitemqtyrcvd(i.orderid, i.shipid, i.item,i.lotnumber) quantity,
od.lineorder
from invitemrpt i, invoicedtl id, orderdtl od
where i.idrowid = id.rowid
and i.orderid = od.orderid (+)
and i.shipid = od.shipid (+)
and i.item = od.item (+)
and nvl(i.lotnumber,'(none)') = nvl(od.lotnumber (+),'(none)');

comment on table dre_invitemrpt is '$Id';

exit;
