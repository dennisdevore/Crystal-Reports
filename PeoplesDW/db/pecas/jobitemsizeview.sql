create or replace view jobitemsizeview
(
    custid,
    jobno,
    item,
    pcs_ctn,
    ctn_plt,
    overage
)
as
select
    P.custid,
    P.reference,
    D.item,
    C.qty,
    L.qty,
    D.dtlpassthrunum10
 from alps.orderhdr P, alps.orderdtl D, 
      alps.custitemuom C, alps.custitemuom L
where P.orderid = D.orderid
  and P.shipid = D.shipid
  and P.ordertype = 'P'
  and P.orderstatus not in ('X','R')
  and C.custid(+) = D.custid
  and C.item(+) = D.item
  and C.fromuom(+) = 'PCS'
  and C.touom(+) = 'CTN'
  and L.custid(+) = D.custid
  and L.item(+) = D.item
  and L.fromuom(+) = 'CTN'
  and L.touom(+) = 'PLT';

comment on table jobitemsizeview is '$Id$';
drop public synonym jobitemsizeview;
create public synonym jobitemsizeview for pecas.jobitemsizeview;

exit;
