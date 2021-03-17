create or replace view bolcustcmtview
(
    orderid,
    shipid,
    type,
    OHC_custid,
    OHC_comment,
    CI_custid,
    CI_comment,
    CID_custid,
    CID_comment,
    LBC_bolcomment,
    LSBC_bolcomment,
    LSSBC_bolcomment,
    CDF_comment
)
as
select
    OH.orderid,
    OH.shipid,
    decode(OHC.orderid, null, (decode(CI.custid,null,'CID','CI')), 'OHC'),
    OHC.orderid,
    OHC.bolcomment,
    CI.custid,
    CI.comment1,
    CID.custid,
    CID.comment1,
    LBC.bolcomment,
    LSBC.bolcomment,
    LSSBC.bolcomment,
    CDF.comment1
from
    orderhdr OH,
    orderhdrbolcomments OHC,
    custitembolcomments CI,
    custitembolcomments CID,
    custitembolcomments CDF,
    loadsbolcomments LBC,
    loadstopbolcomments LSBC,
    loadstopshipbolcomments LSSBC
where
    OH.orderid = OHC.orderid(+) and
    OH.shipid = OHC.shipid(+) and
    OH.custid = CI.custid(+) and
    CI.item(+) = 'default' and
    nvl(OH.consignee,OH.shipto) = CI.consignee(+) and
    OH.custid = CID.custid(+) and
    CID.item(+) = 'default' and
    CID.consignee(+) = 'default' and
    CDF.custid(+) = 'default' and
    CDF.item(+) = 'default' and
    nvl(OH.consignee,OH.shipto) = CDF.consignee(+) and
    OH.loadno = LBC.loadno(+) and
    OH.loadno = LSBC.loadno(+) and
    OH.stopno = LSBC.stopno(+) and
    OH.loadno = LSSBC.loadno(+) and
    OH.stopno = LSSBC.stopno(+) and
    OH.shipno = LSSBC.shipno(+);
comment on table bolcustcmtview is '$Id$';    

create or replace view bolcustcmtviewA
(
    orderid,
    shipid,
    bolcomment
)
as
select
    OH.orderid,
    OH.shipid,
    zbol.bolcustcomments(OH.orderid, OH.shipid)
from
    orderhdr OH;
comment on table bolcustcmtviewA is '$Id$';
    
create or replace view bolcustcmtviewB
(
    orderid,
    shipid,
    bolcomment
)
as
select
    OH.orderid,
    OH.shipid,
    zbol.allbolcustcomments(OH.orderid, OH.shipid)
from
    orderhdr OH;    
comment on table bolcustcmtviewB is '$Id$';

create or replace view bolcustcmtviewc
(
    orderid,
    shipid,
    type,
    OHC_custid,
    OHC_comment,
    CI_custid,
    CI_comment,
    CID_custid,
    CID_comment,
    LBC_bolcomment,
    LSBC_bolcomment,
    LSSBC_bolcomment,
    CDF_comment
)
as
select
    OH.orderid,
    OH.shipid,
    decode(OHC.orderid, null, (decode(CI.custid,null,'CID','CI')), 'OHC'),
    OHC.orderid,
    zbol.bolohccomment(OH.orderid, OH.shipid),
    CI.custid,
    zbol.bolcicomment(OH.orderid, OH.shipid),
    CID.custid,
    zbol.bolcidcomment(OH.orderid, OH.shipid),
    zbol.bollbccomment(OH.orderid, OH.shipid),
    zbol.bollsbccomment(OH.orderid, OH.shipid),
    zbol.bollssbccomment(OH.orderid, OH.shipid),
    zbol.bolcdfcomment(OH.orderid, OH.shipid)
from
    orderhdr OH,
    orderhdrbolcomments OHC,
    custitembolcomments CI,
    custitembolcomments CID,
    custitembolcomments CDF,
    loadsbolcomments LBC,
    loadstopbolcomments LSBC,
    loadstopshipbolcomments LSSBC
where
    OH.orderid = OHC.orderid(+) and
    OH.shipid = OHC.shipid(+) and
    OH.custid = CI.custid(+) and
    CI.item(+) = 'default' and
    nvl(OH.consignee,OH.shipto) = CI.consignee(+) and
    OH.custid = CID.custid(+) and
    CID.item(+) = 'default' and
    CID.consignee(+) = 'default' and
    CDF.custid(+) = 'default' and
    CDF.item(+) = 'default' and
    nvl(OH.consignee,OH.shipto) = CDF.consignee(+) and
    OH.loadno = LBC.loadno(+) and
    OH.loadno = LSBC.loadno(+) and
    OH.stopno = LSBC.stopno(+) and
    OH.loadno = LSSBC.loadno(+) and
    OH.stopno = LSSBC.stopno(+) and
    OH.shipno = LSSBC.shipno(+);
comment on table bolcustcmtviewc is '$Id$';    



exit;
