CREATE OR REPLACE VIEW ALPS.CTW_AGGRPICKLISTVIEW 
(
    WAVE,
    WAVE_DESC,
    TASKID,
    TASKTYPE,
    FACILITY,
    ITEM,
    ITEM_DESC,
    LOT,
    FROMLPID,
    LOCATION,
    UOM,
    QTY,
    ORDERID,
    SHIPID,
    PICKTYPE,
    SHIPPLATETYPE,
    SERIALREQUIRED,
	 WGHT,
	CUBE
)
AS
select
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
		 SP.pickqty * I.cube/1728
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
comment on table CTW_AGGRPICKLISTVIEW is '$Id$';
exit;
