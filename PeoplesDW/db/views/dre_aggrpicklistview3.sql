CREATE OR REPLACE VIEW DRE_AGGRPICKLISTVIEW3
(WAVE, WAVE_DESC, TASKID, TASKTYPE, FACILITY, 
 ITEM, ITEM_DESC, LOT, FROMLPID, LOCATION, 
 UOM, QTY, ORDERID, SHIPID, PICKTYPE, 
 SHIPPLATETYPE, SERIALREQUIRED, WGHT, CUBE, LOTREQUIRED, 
 USER1REQUIRED, USER2REQUIRED, USER3REQUIRED, GROSSWEIGHT, MFG_DATE)
AS 
SELECT /*+ USE_HASH (W) */
       oh.wave, w.descr wave_desc, sp.taskid, tt.descr tasktype, sp.facility,
       sp.item, i.descr item_desc, sp.lotnumber lot, sp.fromlpid fromlpid,
       sp.LOCATION LOCATION, sp.pickuom uom, sp.pickqty qty, sp.orderid,
       sp.shipid, pt.descr picktype, spt.descr shipplatetype,
       i.serialrequired, sp.weight wght, (sp.pickqty * i.CUBE / 1728) CUBE,
       i.lotrequired, i.user1required, i.user2required, i.user3required,
       (  sp.weight
        + (  alps.zlabels.uom_qty_conv (sp.custid,
                                        sp.item,
                                        sp.pickqty,
                                        sp.pickuom,
                                        i.baseuom
                                       )
           * NVL (i.tareweight, 0)
          )
       ) grossweight,
       (SELECT MAX (NVL (dp.manufacturedate, dp.expirationdate))
          FROM (SELECT plate.lpid, plate.item, plate.custid, plate.facility,
                       plate.LOCATION, plate.status, plate.unitofmeasure,
                       plate.quantity, plate.TYPE, plate.serialnumber,
                       plate.lotnumber, plate.expirationdate,
                       plate.expiryaction, plate.po, plate.recmethod,
                       plate.condition, plate.lastoperator, plate.lasttask,
                       plate.fifodate, plate.parentlpid, plate.useritem1,
                       plate.useritem2, plate.useritem3, plate.invstatus,
                       plate.inventoryclass,
                       SUBSTR
                          (alps.zplate.platestatus_abbrev (plate.status),
                           1,
                           12
                          ) statusabbrev,
                       SUBSTR
                          (alps.zitem.uom_abbrev (plate.unitofmeasure),
                           1,
                           12
                          ) unitofmeasureabbrev,
                       SUBSTR
                          (alps.zplate.handlingtype_abbrev (plate.recmethod),
                           1,
                           12
                          ) recmethodabbrev,
                       SUBSTR
                          (alps.zplate.invstatus_abbrev (plate.invstatus),
                           1,
                           12
                          ) invstatusabbrev,
                       SUBSTR
                          (alps.zplate.inventoryclass_abbrev
                                                         (plate.inventoryclass),
                           1,
                           12
                          ) inventoryclassabbrev,
                       SUBSTR
                             (alps.zitem.item_descr (plate.custid, plate.item),
                              1,
                              32
                             ) itemdescr,
                       SUBSTR
                          (alps.zplate.platetype_abbrev (plate.TYPE),
                           1,
                           12
                          ) platetypeabbrev,
                       SUBSTR
                          (alps.zcustitem.hazardous_item (plate.custid,
                                                          plate.item
                                                         ),
                           1,
                           1
                          ) hazardous,
                       SUBSTR
                          (alps.zplate.condition_abbrev (plate.condition),
                           1,
                           12
                          ) conditionabbrev,
                       plate.loadno, plate.orderid, plate.shipid,
                       plate.weight, 'P' plateordeleted,
                       plate.manufacturedate, plate.qtyrcvd
                  FROM plate, custitem custitem_0
                 WHERE plate.custid = custitem_0.custid(+)
                       AND plate.item = custitem_0.item(+)
                UNION ALL
                SELECT deletedplate.lpid, deletedplate.item,
                       deletedplate.custid, deletedplate.facility,
                       deletedplate.LOCATION, deletedplate.status,
                       deletedplate.unitofmeasure, deletedplate.quantity,
                       deletedplate.TYPE, deletedplate.serialnumber,
                       deletedplate.lotnumber, deletedplate.expirationdate,
                       deletedplate.expiryaction, deletedplate.po,
                       deletedplate.recmethod, deletedplate.condition,
                       deletedplate.lastoperator, deletedplate.lasttask,
                       deletedplate.fifodate, deletedplate.parentlpid,
                       deletedplate.useritem1, deletedplate.useritem2,
                       deletedplate.useritem3, deletedplate.invstatus,
                       deletedplate.inventoryclass,
                       SUBSTR
                          (alps.zplate.platestatus_abbrev (deletedplate.status),
                           1,
                           12
                          ),
                       SUBSTR
                           (alps.zitem.uom_abbrev (deletedplate.unitofmeasure),
                            1,
                            12
                           ),
                       SUBSTR
                          (alps.zplate.handlingtype_abbrev
                                                       (deletedplate.recmethod),
                           1,
                           12
                          ),
                       SUBSTR
                          (alps.zplate.invstatus_abbrev
                                                       (deletedplate.invstatus),
                           1,
                           12
                          ),
                       SUBSTR
                          (alps.zplate.inventoryclass_abbrev
                                                  (deletedplate.inventoryclass),
                           1,
                           12
                          ),
                       SUBSTR (alps.zitem.item_descr (deletedplate.custid,
                                                      deletedplate.item
                                                     ),
                               1,
                               32
                              ),
                       SUBSTR
                             (alps.zplate.platetype_abbrev (deletedplate.TYPE),
                              1,
                              12
                             ),
                       SUBSTR
                          (alps.zcustitem.hazardous_item (deletedplate.custid,
                                                          deletedplate.item
                                                         ),
                           1,
                           1
                          ),
                       SUBSTR
                          (alps.zplate.condition_abbrev
                                                       (deletedplate.condition),
                           1,
                           12
                          ),
                       deletedplate.loadno, deletedplate.orderid,
                       deletedplate.shipid, deletedplate.weight, 'D',
                       deletedplate.manufacturedate, deletedplate.qtyrcvd
                  FROM deletedplate, custitem custitem_1
                 WHERE deletedplate.custid = custitem_1.custid(+)
                       AND deletedplate.item = custitem_1.item(+)) dp
         WHERE sp.fromlpid = dp.lpid) mfg_date
  FROM shippingplate sp,
       shippingplatetypes spt,
       custitem i,
       orderhdr oh,
       tasks t,
       tasktypes tt,
       waves w,
       picktotypes pt
 WHERE sp.TYPE = spt.code
   AND sp.custid = i.custid
   AND sp.item = i.item
   AND sp.orderid = oh.orderid
   AND sp.shipid = oh.shipid
   AND sp.taskid = t.taskid(+)
   AND t.tasktype = tt.code(+)
   AND oh.wave = w.wave(+)
   AND i.picktotype = pt.code(+)
UNION
SELECT 0 AS wave, NULL AS wave_desc, 0 AS taskid, NULL AS tasktype,
       a.fromfacility AS facility, a.item, c.descr AS item_desc,
       'PRE-ORDER' AS lot, NULL AS fromlpid, '??' AS LOCATION, a.uom,
       a.qtyorder - NVL (b.qty, 0) AS qty, a.orderid, a.shipid,
       NULL AS picktype, NULL AS shipplatetype, c.serialrequired,
       a.weightorder - NVL (b.wght, 0) AS wght,
       (a.qtyorder - NVL (b.qty, 0)) * c.CUBE / 1728 AS CUBE, c.lotrequired,
       c.user1required, c.user2required, c.user3required,
       (  a.weightorder
        - NVL (b.wght, 0)
        + (  alps.zlabels.uom_qty_conv (a.custid,
                                        a.item,
                                        a.qtyorder,
                                        a.uom,
                                        c.baseuom
                                       )
           * NVL (c.tareweight, 0)
          )
        - NVL (b.grossweight, 0)
       ) AS grossweight,
       TO_DATE ('1/1/1900', 'mm/dd/yyyy') AS mfg_date
  FROM orderdtl a,
       (SELECT   sp.orderid orderid, sp.shipid shipid, sp.item item,
                 sp.pickuom uom, SUM (sp.pickqty) AS qty,
                 SUM (sp.weight) AS wght,
                 SUM
                    ((  sp.weight
                      + (  alps.zlabels.uom_qty_conv (sp.custid,
                                                      sp.item,
                                                      sp.pickqty,
                                                      sp.pickuom,
                                                      i.baseuom
                                                     )
                         * NVL (i.tareweight, 0)
                        )
                     )
                    ) AS grossweight
            FROM shippingplate sp,
                 shippingplatetypes spt,
                 custitem i,
                 orderhdr oh,
                 tasks t,
                 tasktypes tt,
                 waves w,
                 picktotypes pt
           WHERE sp.TYPE = spt.code
             AND sp.custid = i.custid
             AND sp.item = i.item
             AND sp.orderid = oh.orderid
             AND sp.shipid = oh.shipid
             AND sp.taskid = t.taskid(+)
             AND t.tasktype = tt.code(+)
             AND oh.wave = w.wave(+)
             AND i.picktotype = pt.code(+)
        GROUP BY sp.orderid, sp.shipid, sp.item, sp.pickuom) b,
       custitem c
 WHERE a.orderid = b.orderid(+)
   AND a.shipid = b.shipid(+)
   AND a.item = b.item(+)
   AND a.uom = b.uom(+)
   AND a.qtyorder - NVL (b.qty, 0) > 0
   AND a.item = c.item
   AND a.custid = c.custid;
comment on table DRE_AGGRPICKLISTVIEW3 is '$Id$';
exit;
