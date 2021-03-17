create or replace view lbl_jcpenneyhuman_view
(
   lpid,
   store,
   po,
   sub,
   sscc,
   itemno,
   casepack
) as
select SP.lpid,
       SL.hdrpasschar01,
       SL.po,
       SL.sscc,
       SL.hdrpasschar08,
       SL.dtlpasschar02,
       IU.qty
   from shippingplate SP,
        orderhdr OH,
        ucc_standard_labels SL,
        custitemuom IU
   where OH.orderid = SP.orderid
     and OH.shipid = SP.shipid
     and OH.hdrpassthruchar13 = '0010000'
     and SL.orderid = OH.orderid
     and SL.shipid = OH.shipid
     and IU.custid(+) = SL.custid
     and IU.item(+) = SL.item
     and IU.fromuom(+) = 'PCS'
     and IU.touom(+) = 'CTN';

comment on table lbl_jcpenneyhuman_view is '$Id';

exit;
