create or replace function dre_bolrpt_mfgdate
   (in_lpid   in varchar2)
return date
is
   cursor c_mfgdate is
           select min(manufacturedate) manufacturedate
             from(select manufacturedate
                  from plate
                 where manufacturedate is not null
                 start with lpid = in_lpid
               connect by prior lpid = parentlpid
               union
                select manufacturedate
                  from deletedplate
                 where manufacturedate is not null
                 start with lpid = in_lpid
               connect by prior lpid = parentlpid);
   mfgdate c_mfgdate%rowtype;
begin
   open c_mfgdate;
   fetch c_mfgdate into mfgdate;
   close c_mfgdate;
   return mfgdate.manufacturedate;

exception
   when OTHERS then
      return null;
end dre_bolrpt_mfgdate;
/

CREATE OR REPLACE VIEW DRE_BOLRPT
(OH_ORDERID, OH_SHIPID, OH_ENTRYDATE, OH_APPTDATE, OH_SHIPDATE, 
 OH_PO, OH_ORDERSTATUS, OH_BILLOFLADING, OH_ARRIVALDATE, OH_LOADNO, 
 OH_REFERENCE, CN_NAME, CN_ADDR1, CN_ADDR2, CN_CITY, 
 CN_STATE, CN_POSTALCODE, CN_COUNTRYCODE, CR_NAME, CR_ADDR1, 
 CR_ADDR2, CR_CITY, CR_STATE, CR_POSTALCODE, CR_COUNTRYCODE, 
 CAR_NAME, CR_SCAC, CU_CUSTID, CU_NAME, CU_ADDR1, 
 CU_ADDR2, CU_CITY, CU_STATE, CU_POSTALCODE, CU_COUNTRYCODE, 
 OD_ORDERID, OD_SHIPID, OD_ITEM, OD_WEIGHTORDER, FAC_NAME, 
 FAC_ADDR1, FAC_ADDR2, FAC_CITY, FAC_STATE, FAC_POSTALCODE, 
 FAC_COUNTRYCODE, LD_TRAILER, LD_SEAL, LD_PRONO, ODC_ITEM, 
 CI_DESCR, CI_HAZARDOUS, CI_LOTSUMBOL, ST_ABBREV, STRM_ABBREV, 
 CUSTID, FAC_NUM, COD, COD_AMOUNT, OD_QTY_ORDER, 
 OD_CUBE_SHIP, CHEMCODE, BASEUOM, OH_SHIPTYPE, OH_INTERLINECARRIER, 
 OH_COMPANYCHECKOK, OH_TRANSAPPTDATE, OH_DELIVERYAPTCONFNAME, OD_LOTNUMBER, OD_LOTNUMBER_NULL, 
 OD_CUBE_ORDER, OD_DTLPASSTHRUCHAR01, OD_CONSIGNEESKU, OH_PASSTHRUCHAR01, OH_PASSTHRUCHAR02, 
 OH_PASSTHRUCHAR09, OH_PASSTHRUCHAR10, OH_PASSTHRUCHAR12, OH_PASSTHRUCHAR15, LABELUOM, 
 SECONDARYCHEMCODE, TERTIARYCHEMCODE, QUATERNARYCHEMCODE, IMOPRIMARYCHEMCODE, IMOSECONDARYCHEMCODE, 
 IMOTERTIARYCHEMCODE, IMOQUATERNARYCHEMCODE, IATAPRIMARYCHEMCODE, IATASECONDARYCHEMCODE, IATATERTIARYCHEMCODE, 
 IATAQUATERNARYCHEMCODE, OH_PRONO, GROSSWEIGHT, SP_QUANTITY, SP_WEIGHT, 
 MFG_DATE, EXP_DATE, USERITEM1, SP_CUBE, OH_DATESHIPPED, BOLITMCOMMENT, LINEORDER)
AS 
SELECT oh.orderid, oh.shipid, oh.entrydate, oh.apptdate, oh.shipdate, oh.po,
       oh.orderstatus, oh.billoflading, oh.arrivaldate, oh.loadno,
       oh.REFERENCE, DECODE (oh.shiptoname, NULL, cns.NAME, oh.shiptoname),
       DECODE (oh.shiptoname, NULL, cns.addr1, oh.shiptoaddr1),
       DECODE (oh.shiptoname, NULL, cns.addr2, oh.shiptoaddr2),
       DECODE (oh.shiptoname, NULL, cns.city, oh.shiptocity),
       DECODE (oh.shiptoname, NULL, cns.state, oh.shiptostate),
       DECODE (oh.shiptoname, NULL, cns.postalcode, oh.shiptopostalcode),
       DECODE (oh.shiptoname, NULL, cns.countrycode, oh.shiptocountrycode),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.NAME, cnppd.NAME),
               'COL', cn.NAME,
               '3RD', DECODE (oh.billtoname, NULL, cn.NAME, oh.billtoname),
               cu.NAME
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.addr1, cnppd.addr1),
               'COL', cn.addr1,
               '3RD', DECODE (oh.billtoname, NULL, cn.addr1, oh.billtoaddr1),
               cu.addr1
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.addr2, cnppd.addr2),
               'COL', cn.addr2,
               '3RD', DECODE (oh.billtoname, NULL, cn.addr2, oh.billtoaddr2),
               cu.addr2
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.city, cnppd.city),
               'COL', cn.city,
               '3RD', DECODE (oh.billtoname, NULL, cn.city, oh.billtocity),
               cu.city
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.state, cnppd.state),
               'COL', cn.state,
               '3RD', DECODE (oh.billtoname, NULL, cn.state, oh.billtostate),
               cu.state
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee,
                              NULL, cu.postalcode,
                              cnppd.postalcode
                             ),
               'COL', cn.postalcode,
               '3RD', DECODE (oh.billtoname,
                              NULL, cn.postalcode,
                              oh.billtopostalcode
                             ),
               cu.postalcode
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee,
                              NULL, cu.countrycode,
                              cnppd.countrycode
                             ),
               'COL', cn.countrycode,
               '3RD', DECODE (oh.billtoname,
                              NULL, cn.countrycode,
                              oh.billtocountrycode
                             ),
               cu.countrycode
              ),
       cr.NAME, cr.scac, cu.custid, cu.NAME, cu.addr1, cu.addr2, cu.city,
       cu.state, cu.postalcode, cu.countrycode, od.orderid, od.shipid,
       od.item, od.weightorder, fac.NAME, fac.addr1, fac.addr2, fac.city,
       fac.state, fac.postalcode, fac.countrycode, ld.trailer, ld.seal,
       ld.prono, odc.item, ci.descr, ci.hazardous, ci.lotsumbol, st.abbrev,
       strm.abbrev, oh.custid, fac.facility, oh.cod, oh.amtcod, od.qtyorder,
       od.cubeship, ci.primarychemcode, ci.baseuom, oh.shiptype,
       oh.interlinecarrier, oh.companycheckok, oh.transapptdate,
       oh.deliveryaptconfname, sp.lotnumber, NVL (sp.lotnumber, '**NULL**'),
       od.cubeorder, od.dtlpassthruchar01, od.consigneesku,
       oh.hdrpassthruchar01, oh.hdrpassthruchar02, oh.hdrpassthruchar09,
       oh.hdrpassthruchar10, oh.hdrpassthruchar12, oh.hdrpassthruchar15,
       NVL (ci.labeluom, 'CS'), ci.secondarychemcode, ci.tertiarychemcode,
       ci.quaternarychemcode, ci.imoprimarychemcode, ci.imosecondarychemcode,
       ci.imotertiarychemcode, ci.imoquaternarychemcode,
       ci.iataprimarychemcode, ci.iatasecondarychemcode,
       ci.iatatertiarychemcode, ci.iataquaternarychemcode,
       oh.prono, 
       sum(sp.weight), 
       sum(sp.quantity), 
       sum(SP.weight - (zlbl.uom_qty_conv(od.custid,sp.item,SP.quantity,od.uom,ci.baseuom) * decode(ci.catch_weight_out_cap_type, 'N', nvl(ci.tareweight,0), 0))),
  	   nvl(dp.manufacturedate,dre_bolrpt_mfgdate(dp.lpid)) manufacturedate,
  	   dp.expirationdate,
  	   nvl(sp.useritem1,''),
  		 od.cubeship * sp.quantity / od.qtyship,
  		 nvl(oh.dateshipped, oh.shipdate),
       nvl((select drb.bolitmcomment
  		        from dre_rpt_bolitmcmtv4b drb
  		       where oh.orderid=drb.orderid
  		         and oh.shipid=drb.shipid
  		         and od.item=drb.item
  		         and od.lotnumber=drb.lotnumber),' ') as bolitmcomment,
  		 od.lineorder
  FROM orderhdr oh,
       consignee cn,
       consignee cns,
       carrier cr,
       custitemview ci,
       customer cu,
       orderdtl od,
       facility fac,
       loads ld,
       orderdtlbolcomments odc,
       shipmenttypes st,
       shipmentterms strm,
       consignee cnppd,
	   shippingplate sp,
	   dre_allplateview dp
 WHERE NVL (oh.consignee, oh.shipto) = cn.consignee(+)
   AND oh.shipto = cns.consignee(+)
   AND oh.carrier = cr.carrier(+)
   AND oh.custid = cu.custid
   AND oh.orderid = od.orderid
   AND oh.shipid = od.shipid
   AND oh.fromfacility = fac.facility
   AND oh.loadno = ld.loadno(+)
   AND od.custid = ci.custid
   AND od.item = ci.item
   AND od.orderid = odc.orderid(+)
   AND od.shipid = odc.shipid(+)
   AND od.item = odc.item(+)
   AND oh.shiptype = st.code(+)
   AND oh.shipterms = strm.code(+)
   AND oh.ordertype = 'O'
   AND od.linestatus <> 'X'
   AND cu.billfreightto = cnppd.consignee(+)
   AND sp.item = ci.item
   AND od.orderid = sp.orderid
   AND od.shipid = sp.shipid
   AND od.item = sp.orderitem
   AND sp.type in ('F','P')
   AND nvl(od.lotnumber,'(none)') = nvl(sp.orderlot,'(none)')
   AND sp.fromlpid = dp.lpid(+)
GROUP BY oh.orderid, oh.shipid, oh.entrydate, oh.apptdate, oh.shipdate, oh.po,
       oh.orderstatus, oh.billoflading, oh.arrivaldate, oh.loadno,
       oh.REFERENCE, DECODE (oh.shiptoname, NULL, cns.NAME, oh.shiptoname),
       DECODE (oh.shiptoname, NULL, cns.addr1, oh.shiptoaddr1),
       DECODE (oh.shiptoname, NULL, cns.addr2, oh.shiptoaddr2),
       DECODE (oh.shiptoname, NULL, cns.city, oh.shiptocity),
       DECODE (oh.shiptoname, NULL, cns.state, oh.shiptostate),
       DECODE (oh.shiptoname, NULL, cns.postalcode, oh.shiptopostalcode),
       DECODE (oh.shiptoname, NULL, cns.countrycode, oh.shiptocountrycode),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.NAME, cnppd.NAME),
               'COL', cn.NAME,
               '3RD', DECODE (oh.billtoname, NULL, cn.NAME, oh.billtoname),
               cu.NAME
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.addr1, cnppd.addr1),
               'COL', cn.addr1,
               '3RD', DECODE (oh.billtoname, NULL, cn.addr1, oh.billtoaddr1),
               cu.addr1
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.addr2, cnppd.addr2),
               'COL', cn.addr2,
               '3RD', DECODE (oh.billtoname, NULL, cn.addr2, oh.billtoaddr2),
               cu.addr2
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.city, cnppd.city),
               'COL', cn.city,
               '3RD', DECODE (oh.billtoname, NULL, cn.city, oh.billtocity),
               cu.city
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee, NULL, cu.state, cnppd.state),
               'COL', cn.state,
               '3RD', DECODE (oh.billtoname, NULL, cn.state, oh.billtostate),
               cu.state
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee,
                              NULL, cu.postalcode,
                              cnppd.postalcode
                             ),
               'COL', cn.postalcode,
               '3RD', DECODE (oh.billtoname,
                              NULL, cn.postalcode,
                              oh.billtopostalcode
                             ),
               cu.postalcode
              ),
       DECODE (oh.shipterms,
               'PPD', DECODE (cnppd.consignee,
                              NULL, cu.countrycode,
                              cnppd.countrycode
                             ),
               'COL', cn.countrycode,
               '3RD', DECODE (oh.billtoname,
                              NULL, cn.countrycode,
                              oh.billtocountrycode
                             ),
               cu.countrycode
              ),
       cr.NAME, cr.scac, cu.custid, cu.NAME, cu.addr1, cu.addr2, cu.city,
       cu.state, cu.postalcode, cu.countrycode, od.orderid, od.shipid,
       od.item, od.weightorder, fac.NAME, fac.addr1, fac.addr2, fac.city,
       fac.state, fac.postalcode, fac.countrycode, ld.trailer, ld.seal,
       ld.prono, odc.item, ci.descr, ci.hazardous, ci.lotsumbol, st.abbrev,
       strm.abbrev, oh.custid, fac.facility, oh.cod, oh.amtcod, od.qtyorder,
       od.cubeship, ci.primarychemcode, ci.baseuom, oh.shiptype,
       oh.interlinecarrier, oh.companycheckok, oh.transapptdate,
       oh.deliveryaptconfname, sp.lotnumber,
       od.cubeorder, od.dtlpassthruchar01, od.consigneesku,
       oh.hdrpassthruchar01, oh.hdrpassthruchar02, oh.hdrpassthruchar09,
       oh.hdrpassthruchar10, oh.hdrpassthruchar12, oh.hdrpassthruchar15,
       ci.labeluom, ci.secondarychemcode, ci.tertiarychemcode,
       ci.quaternarychemcode, ci.imoprimarychemcode, ci.imosecondarychemcode,
       ci.imotertiarychemcode, ci.imoquaternarychemcode,
       ci.iataprimarychemcode, ci.iatasecondarychemcode,
       ci.iatatertiarychemcode, ci.iataquaternarychemcode,
	     oh.prono, nvl(dp.manufacturedate,dre_bolrpt_mfgdate(dp.lpid)), dp.expirationdate, sp.useritem1,
	     od.cubeship * sp.quantity / od.qtyship, oh.dateshipped, od.lotnumber,
	     od.lineorder;
exit;
