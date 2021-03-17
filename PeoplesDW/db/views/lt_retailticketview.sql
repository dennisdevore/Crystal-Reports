create or replace view lt_retailticketview
(
orderid
,shipid
,custid
,po
,reference
,shiptoname
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptppostalcode
,carrier
,hptchar05
,hptchar09
,hptchar10
,hptchar12
,hptchar15
,hptchar17
,hptchar18
,hptchar19
,hptchar20
,hptchar21
,hptchar22
,hptchar24
,hptchar27
,hptchar28
,hptchar29
,hptchar32
,hptchar33
,hptchar34
,hptchar35
,hptchar36
,hptchar37
,hptchar38
,hptchar39
,hptchar40
,hptchar41
,hptchar42
,hptchar43
,hptchar44
,hptchar47
,hptchar48
,hptchar49
,hptchar50
,hptchar51
,hptchar52
,hptchar60
,hptdate01
,item
,weightpick
,consigneesku
,dptchar11
,dptdoll01
,dptdoll02
,description
,abbreviation
,iptchar01
,iptchar02
,iptchar03
,iptchar04
,iptnum03
,iptnum04
,baseuom_weight
,baseuom_cube
,itemcountry
,lpid
,picktolp
,quantity
,plate_weight
,lotnumber
,serialnumber
,caseupc
,itemupc
)
as
select
    h.orderid,
    h.shipid,
    h.custid,
    h.po,
    h.reference,
    h.shiptoname,
    h.shiptoaddr1,
    h.shiptoaddr2,
    h.shiptocity,
    h.shiptostate,
    h.shiptopostalcode,
    h.carrier,
    h.hdrpassthruchar05,
    h.hdrpassthruchar09,
    h.hdrpassthruchar10,
    h.hdrpassthruchar12,
    h.hdrpassthruchar15,
    h.hdrpassthruchar17,
    h.hdrpassthruchar18,
    h.hdrpassthruchar19,
    h.hdrpassthruchar20,
    h.hdrpassthruchar21,
    h.hdrpassthruchar22,
    h.hdrpassthruchar24,
    h.hdrpassthruchar27,
    h.hdrpassthruchar28,
    h.hdrpassthruchar29,
    h.hdrpassthruchar32,
    h.hdrpassthruchar33,
    h.hdrpassthruchar34,
    h.hdrpassthruchar35,
    h.hdrpassthruchar36,
    h.hdrpassthruchar37,
    h.hdrpassthruchar38,
    h.hdrpassthruchar39,
    h.hdrpassthruchar40,
    h.hdrpassthruchar41,
    h.hdrpassthruchar42,
    h.hdrpassthruchar43,
    h.hdrpassthruchar44,
    h.hdrpassthruchar47,
    h.hdrpassthruchar48,
    h.hdrpassthruchar49,
    h.hdrpassthruchar50,
    h.hdrpassthruchar51,
    h.hdrpassthruchar52,
    h.hdrpassthruchar60,
    h.hdrpassthrudate01,
    d.item,
    d.weightpick,
    d.consigneesku,
    d.dtlpassthruchar11,
    d.dtlpassthrudoll01,
    d.dtlpassthrudoll02,
    i.descr,
    i.abbrev,
    i.itmpassthruchar01,
    i.itmpassthruchar02,
    i.itmpassthruchar03,
    i.itmpassthruchar04,
    i.itmpassthrunum03,
    i.itmpassthrunum04,
    i.weight,
    i.cube,
    cc.abbrev,
    s.lpid,
    s.fromlpid,
    s.quantity,
    s.weight,
    s.lotnumber,
    s.serialnumber,
    nvl(d.dtlpassthruchar03, i.itmpassthruchar02),
    nvl(d.dtlpassthruchar01, i.itmpassthruchar01)
  from orderdtl d,
    orderhdr h,
    custitem i,
    shippingplate s,
    countrycodes cc
  where h.orderid = d.orderid
  and h.shipid = d.shipid
  and d.orderid = s.orderid
  and d.shipid = s.shipid
  and d.item = s.orderitem
  and h.custid = i.custid
  and d.item = i.item
  and s.type in ('F','P')
  and nvl(i.countryof,'zzz') = cc.code(+)

/
comment on table LT_RETAILTICKETVIEW is '$Id';
exit
