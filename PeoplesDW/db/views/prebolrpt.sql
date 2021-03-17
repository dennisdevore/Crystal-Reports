create or replace view prebolrpt
(
OH_ORDERID
,OH_SHIPID
,OH_ENTRYDATE
,OH_APPTDATE
,OH_SHIPDATE
,OH_PO
,OH_ORDERSTATUS
,OH_BILLOFLADING
,OH_ARRIVALDATE
,OH_LOADNO
,OH_REFERENCE
,CN_NAME
,CN_ADDR1
,CN_ADDR2
,CN_CITY
,CN_STATE
,CN_POSTALCODE
,CN_COUNTRYCODE
,CR_NAME
,CR_ADDR1
,CR_ADDR2
,CR_CITY
,CR_STATE
,CR_POSTALCODE
,CR_COUNTRYCODE
,CAR_NAME
,CR_SCAC
,CU_CUSTID
,CU_NAME
,CU_ADDR1
,CU_ADDR2
,CU_CITY
,CU_STATE
,CU_POSTALCODE
,CU_COUNTRYCODE
,OD_ORDERID
,OD_SHIPID
,OD_ITEM
,SP_ITEM
,OD_QTYSHIP
,OD_WEIGHTSHIP
,OD_LOTNUMBER
,OD_LOTNUMBER_NULL
,FAC_NAME
,FAC_ADDR1
,FAC_ADDR2
,FAC_CITY
,FAC_STATE
,FAC_POSTALCODE
,FAC_COUNTRYCODE
,LD_TRAILER
,LD_SEAL
,LD_PRONO
,ODC_ITEM
,CI_DESCR
,CI_HAZARDOUS
,CI_LOTSUMBOL
,ST_ABBREV
,STRM_ABBREV
,PO_NUMBER
,DATE_SHIPPED
,QTY_ORDERED
,QTY_ENTERED
,UOM_ENTERED
)
as
select
       OH.orderid,
       OH.shipid,
       OH.entrydate,
       OH.apptdate,
       OH.shipdate,
       OH.po,
       OH.orderstatus,
       OH.billoflading,
       OH.arrivaldate,
       OH.loadno,
       OH.reference,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       decode(OH.shiptoname,null,CNS.addr2, OH.shiptoaddr2),
       decode(OH.shiptoname,null,CNS.city, OH.shiptocity),
       decode(OH.shiptoname,null,CNS.state, OH.shiptostate),
       decode(OH.shiptoname,null,CNS.postalcode, OH.shiptopostalcode),
       decode(OH.shiptoname,null,CNS.countrycode, OH.shiptocountrycode),
       decode(OH.shipterms,
                'PPD', CU.name,
                'COL', CN.name,
                '3RD',
                  decode(OH.billtoname,null,CN.name,OH.billtoname),
                CU.name),
       decode(OH.shipterms,
                'PPD', CU.addr1,
                'COL', CN.addr1,
                '3RD',
                  decode(OH.billtoname,null,CN.addr1,OH.billtoaddr1),
                CU.addr1),
       decode(OH.shipterms,
                'PPD', CU.addr2,
                'COL', CN.addr2,
                '3RD',
                  decode(OH.billtoname,null,CN.addr2,OH.billtoaddr2),
                CU.addr2),
       decode(OH.shipterms,
                'PPD', CU.city,
                'COL', CN.city,
                '3RD',
                  decode(OH.billtoname,null,CN.city, OH.billtocity),
                CU.city),
       decode(OH.shipterms,
                'PPD', CU.state,
                'COL', CN.state,
                '3RD',
                  decode(OH.billtoname,null,CN.state,OH.billtostate),
                CU.state),
       decode(OH.shipterms,
                'PPD', CU.postalcode,
                'COL', CN.postalcode,
                '3RD',
                  decode(OH.billtoname,null,CN.postalcode,OH.billtopostalcode),
                CU.postalcode),
       decode(OH.shipterms,
                'PPD', CU.countrycode,
                'COL', CN.countrycode,
                '3RD',
                  decode(OH.billtoname,null,CN.countrycode,OH.billtocountrycode),
                CU.countrycode),
       CR.name,
       CR.scac,
       CU.custid,
       CU.name,
       CU.addr1,
       CU.addr2,
       CU.city,
       CU.state,
       CU.postalcode,
       CU.countrycode,
       OD.orderid,
       OD.shipid,
       OD.item,
       SP.item,
       sum(SP.quantity),
       sum(SP.weight),
       decode(CI.lotsumbol,'Y',null,SP.lotnumber),
       nvl(SP.orderlot,'**NULL**'),
       FAC.name,
       FAC.addr1,
       FAC.addr2,
       FAC.city,
       FAC.state,
       FAC.postalcode,
       FAC.countrycode,
       LD.trailer,
       LD.seal,
       LD.prono,
       ODC.item,
       CI.descr,
       CI.hazardous,
       CI.lotsumbol,
       ST.abbrev,
       STRM.abbrev,
	  OH.HDRPASSTHRUCHAR03,
	  OH.DATESHIPPED,
	  OD.QTYORDER,
	  OD.QTYENTERED,
	  OD.UOMENTERED
from
    orderhdr OH,
    consignee CN,
    consignee CNS,
    carrier CR,
    custitem CI,
    customer CU,
    orderdtl OD,
    shippingplate SP,
    facility FAC,
    loads LD,
    orderdtlbolcomments ODC,
    shipmenttypes ST,
    shipmentterms STRM
where
    nvl(OH.consignee,OH.shipto) = CN.consignee(+) and
    OH.shipto = CNS.consignee(+) and
    OH.carrier = CR.carrier(+) and
    OH.custid = CU.custid(+) and
    OH.orderid = OD.orderid and
    OH.shipid = OD.shipid and
    OH.fromfacility = FAC.facility(+) and
    OH.loadno = LD.loadno(+) and
    OD.custid = CI.custid and
    OD.item = CI.item and
    OD.orderid = ODC.orderid(+) and
    OD.shipid = ODC.shipid(+) and
    OD.item = ODC.item(+) and
    OD.orderid = SP.orderid and
    OD.shipid = SP.shipid and
    OD.item = SP.orderitem and
    SP.type in ('F','P') and
    nvl(OD.lotnumber,'(none)') = nvl(SP.orderlot,'(none)') and
    nvl(OD.lotnumber,'(none)') = nvl(ODC.lotnumber(+),'(none)') and
    OH.shiptype = ST.code (+) and
    OH.shipterms = STRM.code (+) and
    (OH.orderstatus = '8' or
    OH.orderstatus = '9' or
    OH.orderstatus = '6' or
    OH.orderstatus = '7')
group by
       OH.orderid,
       OH.shipid,
       OH.entrydate,
       OH.apptdate,
       OH.shipdate,
       OH.po,
       OH.orderstatus,
       OH.billoflading,
       OH.arrivaldate,
       OH.loadno,
       OH.reference,
       decode(OH.shiptoname,null,CNS.name,OH.shiptoname),
       decode(OH.shiptoname,null,CNS.addr1, OH.shiptoaddr1),
       decode(OH.shiptoname,null,CNS.addr2, OH.shiptoaddr2),
       decode(OH.shiptoname,null,CNS.city, OH.shiptocity),
       decode(OH.shiptoname,null,CNS.state, OH.shiptostate),
       decode(OH.shiptoname,null,CNS.postalcode, OH.shiptopostalcode),
       decode(OH.shiptoname,null,CNS.countrycode, OH.shiptocountrycode),
       decode(OH.shipterms,
                'PPD', CU.name,
                'COL', CN.name,
                '3RD',
                  decode(OH.billtoname,null,CN.name,OH.billtoname),
                CU.name),
       decode(OH.shipterms,
                'PPD', CU.addr1,
                'COL', CN.addr1,
                '3RD',
                  decode(OH.billtoname,null,CN.addr1,OH.billtoaddr1),
                CU.addr1),
       decode(OH.shipterms,
                'PPD', CU.addr2,
                'COL', CN.addr2,
                '3RD',
                  decode(OH.billtoname,null,CN.addr2,OH.billtoaddr2),
                CU.addr2),
       decode(OH.shipterms,
                'PPD', CU.city,
                'COL', CN.city,
                '3RD',
                  decode(OH.billtoname,null,CN.city, OH.billtocity),
                CU.city),
       decode(OH.shipterms,
                'PPD', CU.state,
                'COL', CN.state,
                '3RD',
                  decode(OH.billtoname,null,CN.state,OH.billtostate),
                CU.state),
       decode(OH.shipterms,
                'PPD', CU.postalcode,
                'COL', CN.postalcode,
                '3RD',
                  decode(OH.billtoname,null,CN.postalcode,OH.billtopostalcode),
                CU.postalcode),
       decode(OH.shipterms,
                'PPD', CU.countrycode,
                'COL', CN.countrycode,
                '3RD',
                  decode(OH.billtoname,null,CN.countrycode,OH.billtocountrycode)
,
                CU.countrycode),
       CR.name,
       CR.scac,
       CU.custid,
       CU.name,
       CU.addr1,
       CU.addr2,
       CU.city,
       CU.state,
       CU.postalcode,
       CU.countrycode,
       OD.orderid,
       OD.shipid,
       OD.item,
       SP.item,
       decode(CI.lotsumbol,'Y',null,SP.lotnumber),
       nvl(SP.orderlot,'**NULL**'),
       FAC.name,
       FAC.addr1,
       FAC.addr2,
       FAC.city,
       FAC.state,
       FAC.postalcode,
       FAC.countrycode,
       LD.trailer,
       LD.seal,
       LD.prono,
       ODC.item,
       CI.descr,
       CI.hazardous,
       CI.lotsumbol,
       ST.abbrev,
       STRM.abbrev,
  	  OH.HDRPASSTHRUCHAR03,
	  OH.DATESHIPPED,
	  OD.QTYORDER,
	  OD.QTYENTERED,
	  OD.UOMENTERED

/
comment on table prebolrpt is '$Id';
exit
