create or replace view picklistview
(
    wave,
    wave_desc,
    taskid,
    tasktype,
    facility,
    locseq,
    item,
    item_desc,
    lpid,
    lot,
    fromloc,
    toloc,
    uom,
    qty,
    orderid,
    shipid,
    picktype,
    shipplatetype,
    serialrequired,
    qtypcs,
    qtyctn
)
as
select
       T.wave,
       W.descr,
       T.taskid,
       TT.descr,
       T.facility,
       S.locseq,
       S.item,
       I.descr,
       S.lpid,
       S.orderlot,
       S.fromloc,
       S.toloc,
       S.pickuom,
       S.pickqty,
       S.orderid,
       S.shipid,
       PT.descr,
       SPT.descr,
       I.serialrequired,
       nvl(zlbl.uom_qty_conv(I.custid, I.item, nvl(S.pickqty,0), S.pickuom, 'PCS'),0),
       nvl(zlbl.uom_qty_conv(I.custid, I.item, nvl(S.pickqty,0), S.pickuom, 'CTN'),0)
  from shippingplatetypes SPT, custitem I, waves W,
       picktotypes PT, tasktypes TT, subtasks S, tasks T
 where W.wave = T.wave
   and T.taskid = S.taskid
   and T.tasktype = TT.code(+)
   and S.picktotype = PT.code(+)
   and S.shippingtype = SPT.code(+)
   and S.custid = I.custid(+)
   and S.item = I.item(+);
   
comment on table picklistview is '$Id$';
   
	exit;
