
CREATE OR REPLACE VIEW AGGRPICKLISTVIEW ( WAVE, 
WAVE_DESC, TASKID, TASKTYPE, FACILITY, 
ITEM, ITEM_DESC, LOT, FROMLPID, 
LOCATION, UOM, QTY, ORDERID, 
SHIPID, PICKTYPE, SHIPPLATETYPE, SERIALREQUIRED, 
WGHT,BASEUOM,BASEQTY ) AS select
       OH.wave,
       W.descr WAVE_DESC,
       SP.taskid,
       TT.descr TASKTYPE,
       SP.facility,
       SP.item,
       I.descr ITEM_DESC,
       SP.lotnumber LOT,
       SP.fromlpid FROMLPID,
       SP.location LOCATION,
       SP.pickuom UOM,
       SP.pickqty QTY,
       SP.orderid,
       SP.shipid,
       PT.descr PICKTYPE,
       SPT.descr SHIPPLATETYPE,
       I.serialrequired,
       SP.weight WGHT,
       I.baseuom,
       zlbl.uom_qty_conv(sp.custid,sp.item,sp.pickqty,sp.pickuom,i.baseuom) as BASEQTY
  from shippingplate SP, shippingplatetypes SPT, custitem I,
       orderhdr OH, tasks T, tasktypes TT, waves W, picktotypes PT
 where SP.type = SPT.code
   and SP.custid = I.custid
   and SP.item = I.item
   and SP.orderid = OH.orderid
   and SP.shipid = OH.shipid
   and SP.taskid = T.taskid(+)
   and T.tasktype = TT.code(+)
   and OH.wave = W.wave(+)
   and I.picktotype = PT.code(+);
comment on table AGGRPICKLISTVIEW  is '$Id$';

CREATE OR REPLACE VIEW AGGRPICKLISTWITHSKUVIEW ( WAVE, 
WAVE_DESC, TASKID, TASKTYPE, FACILITY, 
ITEM, ITEM_DESC, LOT, FROMLPID, 
LOCATION, UOM, QTY, ORDERID, 
SHIPID, PICKTYPE, SHIPPLATETYPE, SERIALREQUIRED, 
WGHT,BASEUOM,BASEQTY,CONSIGNEESKU ) AS select
       OH.wave,
       W.descr WAVE_DESC,
       SP.taskid,
       TT.descr TASKTYPE,
       SP.facility,
       SP.item,
       I.descr ITEM_DESC,
       SP.lotnumber LOT,
       SP.fromlpid FROMLPID,
       SP.location LOCATION,
       SP.pickuom UOM,
       SP.pickqty QTY,
       SP.orderid,
       SP.shipid,
       PT.descr PICKTYPE,
       SPT.descr SHIPPLATETYPE,
       I.serialrequired,
       SP.weight WGHT,
       I.baseuom,
       zlbl.uom_qty_conv(sp.custid,sp.item,sp.pickqty,sp.pickuom,i.baseuom) as BASEQTY,
       OD.consigneesku
  from shippingplate SP, shippingplatetypes SPT, custitem I,
       orderhdr OH, tasks T, tasktypes TT, waves W, picktotypes PT,
       orderdtl od
 where SP.type = SPT.code
   and SP.custid = I.custid
   and SP.item = I.item
   and SP.orderid = OH.orderid
   and SP.shipid = OH.shipid
   and SP.taskid = T.taskid(+)
   and SP.orderid = OD.orderid(+)
   and SP.shipid = OD.shipid(+)
   and SP.orderitem = OD.item(+)
   and nvl(SP.orderlot,'(none)') = nvl(OD.lotnumber(+),'(none)')
   and T.tasktype = TT.code(+)
   and OH.wave = W.wave(+)
   and I.picktotype = PT.code(+);
comment on table AGGRPICKLISTWITHSKUVIEW  is '$Id$';
	exit;
