
CREATE OR REPLACE VIEW DRE_AGGRPICKLISTVIEW ( WAVE, 
WAVE_DESC, TASKID, TASKTYPE, FACILITY, 
ITEM, ITEM_DESC, LOT, FROMLPID, 
LOCATION, UOM, QTY, ORDERID, 
SHIPID, PICKTYPE, SHIPPLATETYPE, SERIALREQUIRED, 
WGHT, CUBE, LOTREQUIRED,USER1REQUIRED,USER2REQUIRED,USER3REQUIRED, 
GROSSWEIGHT,MFG_DATE, LINEORDER ) as select
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
	SP.pickqty * I.cube/1728 CUBE,
	I.LOTREQUIRED,
	I.USER1REQUIRED,
	I.USER2REQUIRED,
	I.USER3REQUIRED,
	SP.weight + (zlbl.uom_qty_conv(sp.custid,sp.item,sp.pickqty,sp.pickuom,i.baseuom) * nvl(I.tareweight,0)) as GROSSWEIGHT,
	(select max(nvl(dp.manufacturedate, dp.expirationdate)) from dre_allplateview dp where sp.fromlpid = dp.lpid) as MFG_DATE,
	  OD.lineorder
  from shippingplate SP, shippingplatetypes SPT, custitem I,
       orderhdr OH, tasks T, tasktypes TT, waves W, picktotypes PT,
      orderdtl OD
 where SP.type = SPT.code
   and SP.custid = I.custid
   and SP.item = I.item
   and SP.orderid = OH.orderid
   and SP.shipid = OH.shipid
   and SP.taskid = T.taskid(+)
   and T.tasktype = TT.code(+)
   and OH.wave = W.wave(+)
   and I.picktotype = PT.code(+)
   and SP.orderid = OD.orderid (+)
   and SP.shipid = OD.shipid (+)
   and SP.orderitem = OD.item (+)
   and nvl(SP.orderlot,'(none)') = nvl(OD.lotnumber (+),'(none)');
comment on table DRE_AGGRPICKLISTVIEW is '$Id$';
	exit;
