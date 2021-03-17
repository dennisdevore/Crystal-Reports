CREATE OR REPLACE VIEW DRE_BOLRPT_PRELIM_NOPREORDER
(OH_ORDERID, OH_SHIPID, OH_ENTRYDATE, OH_APPTDATE, OH_SHIPDATE, 
 OH_DATESHIPPED, OH_PO, OH_ORDERSTATUS, OH_BILLOFLADING, OH_ARRIVALDATE, 
 OH_LOADNO, OH_REFERENCE, CN_NAME, CN_ADDR1, CN_ADDR2, 
 CN_CITY, CN_STATE, CN_POSTALCODE, CN_COUNTRYCODE, CR_NAME, 
 CR_ADDR1, CR_ADDR2, CR_CITY, CR_STATE, CR_POSTALCODE, 
 CR_COUNTRYCODE, CAR_NAME, CR_SCAC, CU_CUSTID, CU_NAME, 
 CU_ADDR1, CU_ADDR2, CU_CITY, CU_STATE, CU_POSTALCODE, 
 CU_COUNTRYCODE, OD_ORDERID, OD_SHIPID, OD_ITEM, OD_WEIGHTORDER, 
 FAC_NAME, FAC_ADDR1, FAC_ADDR2, FAC_CITY, FAC_STATE, 
 FAC_POSTALCODE, FAC_COUNTRYCODE, LD_TRAILER, LD_SEAL, LD_PRONO, 
 ODC_ITEM, CI_DESCR, CI_HAZARDOUS, CI_LOTSUMBOL, ST_ABBREV, 
 STRM_ABBREV, CUSTID, FAC_NUM, COD, COD_AMOUNT, 
 OD_QTY_ORDER, OD_CUBE_SHIP, CHEMCODE, BASEUOM, OH_SHIPTYPE, 
 OH_INTERLINECARRIER, OH_COMPANYCHECKOK, OH_TRANSAPPTDATE, OH_DELIVERYAPTCONFNAME, OD_LOTNUMBER, 
 OD_LOTNUMBER_NULL, OD_CUBE_ORDER, OD_DTLPASSTHRUCHAR01, OD_CONSIGNEESKU, OH_PASSTHRUCHAR01, 
 OH_PASSTHRUCHAR02, OH_PASSTHRUCHAR09, OH_PASSTHRUCHAR10, OH_PASSTHRUCHAR12, OH_PASSTHRUCHAR15, 
 LABELUOM, SECONDARYCHEMCODE, TERTIARYCHEMCODE, QUATERNARYCHEMCODE, IMOPRIMARYCHEMCODE, 
 IMOSECONDARYCHEMCODE, IMOTERTIARYCHEMCODE, IMOQUATERNARYCHEMCODE, IATAPRIMARYCHEMCODE, IATASECONDARYCHEMCODE, 
 IATATERTIARYCHEMCODE, IATAQUATERNARYCHEMCODE, GROSSWEIGHT, OH_PRONO, SP_QUANTITY, 
 SP_WEIGHT, SP_CUBE, MFG_DATE, BOLITMCOMMENT, SP_USERITEM1, LINEORDER, OH_CONSIGNEE, OH_SHIPTO)
AS 
select    
OH.orderid,    
OH.shipid,    
OH.entrydate,    
OH.apptdate,    
OH.shipdate,    
nvl(oh.dateshipped, oh.shipdate),    
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
'PPD', decode(CNPPD.consignee,null,CU.name,CNPPD.name),    
'COL', CN.name,    
'3RD',    
decode(OH.billtoname,null,CN.name,OH.billtoname),    
CU.name),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.addr1,CNPPD.addr1),    
'COL', CN.addr1,    
'3RD',    
decode(OH.billtoname,null,CN.addr1,OH.billtoaddr1),    
CU.addr1),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.addr2,CNPPD.addr2),    
'COL', CN.addr2,    
'3RD',    
decode(OH.billtoname,null,CN.addr2,OH.billtoaddr2),    
CU.addr2),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.city,CNPPD.city),    
'COL', CN.city,    
'3RD',    
decode(OH.billtoname,null,CN.city, OH.billtocity),    
CU.city),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.state,CNPPD.state),    
'COL', CN.state,    
'3RD',    
decode(OH.billtoname,null,CN.state,OH.billtostate),    
CU.state),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.postalcode,CNPPD.postalcode),    
'COL', CN.postalcode,    
'3RD',    
decode(OH.billtoname,null,CN.postalcode,OH.billtopostalcode),    
CU.postalcode),    
decode(OH.shipterms,    
'PPD', decode(CNPPD.consignee,null,CU.countrycode,CNPPD.countrycode),    
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
--OD.weightorder,    
OD.wght,    
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
OH.custid,    
FAC.facility,    
OH.cod,    
OH.amtcod,    
OD.qty,    
--OD.qtyorder,    
OD.CUBE,    
--OD.CUBESHIP,    
CI.primarychemcode,    
CI.baseuom,    
OH.shiptype,    
OH.interlinecarrier,    
OH.companycheckok,    
OH.transapptdate,    
OH.deliveryaptconfname,    
--OD.lotnumber,    
OD.lot,    
--nvl(OD.lotnumber,'**NULL**'),    
OD.lot,    
OD.cube,    
--OD.cubeorder,    
--OD.DTLPASSTHRUCHAR01,    
null as DTLPASSTHRUCHAR01,    
--OD.CONSIGNEESKU,    
null as CONSIGNEESKU,    
OH.HDRPASSTHRUCHAR01,    
OH.HDRPASSTHRUCHAR02,    
OH.HDRPASSTHRUCHAR09,    
OH.HDRPASSTHRUCHAR10,    
OH.HDRPASSTHRUCHAR12,    
OH.HDRPASSTHRUCHAR15,    
NVL(CI.labeluom, 'CS'),    
CI.SECONDARYCHEMCODE,    
CI.TERTIARYCHEMCODE,    
CI.QUATERNARYCHEMCODE,    
CI.IMOPRIMARYCHEMCODE,    
CI.IMOSECONDARYCHEMCODE,    
CI.IMOTERTIARYCHEMCODE,    
CI.IMOQUATERNARYCHEMCODE,    
CI.IATAPRIMARYCHEMCODE,    
CI.IATASECONDARYCHEMCODE,    
CI.IATATERTIARYCHEMCODE,    
CI.IATAQUATERNARYCHEMCODE,    
OD.GROSSWEIGHT,    
OH.PRONO,    
--SP_QUANTITY, SP_WEIGHT, SP_CUBE,     
OD.QTY,    
OD.WGHT,    
OD.CUBE,    
OD.MFG_DATE,
NVL((SELECT DRB.BOLITMCOMMENT
		 FROM DRE_RPT_BOLITMCMTV4B DRB
		 WHERE OH.ORDERID=DRB.ORDERID AND
		       OH.SHIPID=DRB.SHIPID AND
		       OD.ITEM=DRB.ITEM AND
		       OD.LOT=DRB.LOTNUMBER),' ') AS BOLITMCOMMENT,
(select max(SP.USERITEM1)
   from shippingplate SP
  where SP.item = CI.item
    and OD.orderid = SP.orderid
    and OD.shipid = SP.shipid
    and OD.item = SP.orderitem
    and SP.type in ('F','P')
    and nvl(OD.lot,'(none)') = nvl(SP.orderlot,'(none)')) SP_USERITEM1,
OD.lineorder,
OH.consignee,
OH.shipto
from    
orderhdr OH,    
consignee CN,    
consignee CNS,    
carrier CR,    
custitem CI,    
customer CU,    
DRE_AGGRPICKLISTVIEW OD,    
facility FAC,    
loads LD,    
orderdtlbolcomments ODC,    
shipmenttypes ST,    
shipmentterms STRM,    
consignee CNPPD
where    
nvl(OH.consignee,OH.shipto) = CN.consignee(+) and    
OH.shipto = CNS.consignee(+) and    
OH.carrier = CR.carrier(+) and    
OH.custid = CU.custid and    
OH.orderid = OD.orderid and    
OH.shipid = OD.shipid and    
OH.fromfacility = FAC.facility and    
OH.loadno = LD.loadno(+) and    
OH.custid = CI.custid and    
--OD.custid = CI.custid and    
OD.item = CI.item and    
OD.orderid = ODC.orderid(+) and    
OD.shipid = ODC.shipid(+) and    
OD.item = ODC.item(+) and    
OH.shiptype = ST.code (+) and    
OH.shipterms = STRM.code (+) and    
OH.ordertype = 'O' and    
--OD.linestatus <> 'X' and    
OD.shipplatetype <> 'Master Pallet' and   
CU.billfreightto = CNPPD.consignee(+)  
and OD.qty is not null   
and OD.cube is not null;
comment on table DRE_BOLRPT_PRELIM_NOPREORDER is '$Id: dre_bolrpt_prelim_nopreorder.sql 86 2005-12-29 00:00:00Z eric $';
exit;
