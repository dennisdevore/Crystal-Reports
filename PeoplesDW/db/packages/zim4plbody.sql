create or replace package body alps.zimportproc4pl as
--
-- $Id: zim4plbody.sql 8906 2012-09-10 21:17:31Z eric $
--

IMP_USERID constant varchar2(8) := 'IMP4PL';

procedure import_4pl_945_header
(in_importfileid     varchar2
,in_custid           varchar2
,in_reference        varchar2
,in_orderid          number
,in_shipid           number
,in_company          varchar2
,in_warehouse        varchar2
,in_loadno           number
,in_trackingno       varchar2
,in_dateshipped      date
,in_commitdate       date
,in_shipviacode      varchar2
,in_lbs              number
,in_kgs              number
,in_gms              number
,in_ozs              number
,in_shipticket       varchar2
,in_height           number
,in_width            number
,in_length           number
,in_shiptoidcode     varchar2
,in_shiptoname       varchar2
,in_shiptocontact    varchar2
,in_shiptoaddr1      varchar2
,in_shiptoaddr2      varchar2
,in_shiptocity       varchar2
,in_shiptostate      varchar2
,in_shiptopostalcode varchar2
,in_shiptocountrycode varchar2
,in_shiptophone      varchar2
,in_billtoidcode     varchar2
,in_billtoname       varchar2
,in_billtocontact    varchar2
,in_billtoaddr1      varchar2
,in_billtoaddr2      varchar2
,in_billtocity       varchar2
,in_billtostate      varchar2
,in_billtopostalcode varchar2
,in_billtocountrycode varchar2
,in_billtophone      varchar2
,in_billtofax        varchar2
,in_billtoemail      varchar2
,in_carrier          varchar2
,in_carrier_name     varchar2
,in_packlistshipdate varchar2
,in_routing          varchar2
,in_shiptype         varchar2
,in_shipterms        varchar2
,in_reportingcode    varchar2
,in_depositororder   varchar2
,in_po               varchar2
,in_deliverydate     varchar2
,in_estdelivery      date
,in_billoflading     varchar2
,in_prono            varchar2
,in_masterbol        number
,in_splitshipno      varchar2
,in_invoicedate      varchar2
,in_effectivedate    varchar2
,in_totalunits       number
,in_totalweight      number
,in_uomweight        varchar2
,in_totalvolume      number
,in_uomvolume        varchar2
,in_ladingqty        number
,in_uom              varchar2
,in_warehouse_name   varchar2
,in_warehouse_id     varchar2
,in_depositor_name   varchar2
,in_depositor_id     varchar2
,in_hdrpassthruchar01 varchar2
,in_hdrpassthruchar02 varchar2
,in_hdrpassthruchar03 varchar2
,in_hdrpassthruchar04 varchar2
,in_hdrpassthruchar05 varchar2
,in_hdrpassthruchar06 varchar2
,in_hdrpassthruchar07 varchar2
,in_hdrpassthruchar08 varchar2
,in_hdrpassthruchar09 varchar2
,in_hdrpassthruchar10 varchar2
,in_hdrpassthruchar11 varchar2
,in_hdrpassthruchar12 varchar2
,in_hdrpassthruchar13 varchar2
,in_hdrpassthruchar14 varchar2
,in_hdrpassthruchar15 varchar2
,in_hdrpassthruchar16 varchar2
,in_hdrpassthruchar17 varchar2
,in_hdrpassthruchar18 varchar2
,in_hdrpassthruchar19 varchar2
,in_hdrpassthruchar20 varchar2
,in_hdrpassthruchar21 varchar2
,in_hdrpassthruchar22 varchar2
,in_hdrpassthruchar23 varchar2
,in_hdrpassthruchar24 varchar2
,in_hdrpassthruchar25 varchar2
,in_hdrpassthruchar26 varchar2
,in_hdrpassthruchar27 varchar2
,in_hdrpassthruchar28 varchar2
,in_hdrpassthruchar29 varchar2
,in_hdrpassthruchar30 varchar2
,in_hdrpassthruchar31 varchar2
,in_hdrpassthruchar32 varchar2
,in_hdrpassthruchar33 varchar2
,in_hdrpassthruchar34 varchar2
,in_hdrpassthruchar35 varchar2
,in_hdrpassthruchar36 varchar2
,in_hdrpassthruchar37 varchar2
,in_hdrpassthruchar38 varchar2
,in_hdrpassthruchar39 varchar2
,in_hdrpassthruchar40 varchar2
,in_hdrpassthruchar41 varchar2
,in_hdrpassthruchar42 varchar2
,in_hdrpassthruchar43 varchar2
,in_hdrpassthruchar44 varchar2
,in_hdrpassthruchar45 varchar2
,in_hdrpassthruchar46 varchar2
,in_hdrpassthruchar47 varchar2
,in_hdrpassthruchar48 varchar2
,in_hdrpassthruchar49 varchar2
,in_hdrpassthruchar50 varchar2
,in_hdrpassthruchar51 varchar2
,in_hdrpassthruchar52 varchar2
,in_hdrpassthruchar53 varchar2
,in_hdrpassthruchar54 varchar2
,in_hdrpassthruchar55 varchar2
,in_hdrpassthruchar56 varchar2
,in_hdrpassthruchar57 varchar2
,in_hdrpassthruchar58 varchar2
,in_hdrpassthruchar59 varchar2
,in_hdrpassthruchar60 varchar2
,in_hdrpassthrunum01 number
,in_hdrpassthrunum02 number
,in_hdrpassthrunum03 number
,in_hdrpassthrunum04 number
,in_hdrpassthrunum05 number
,in_hdrpassthrunum06 number
,in_hdrpassthrunum07 number
,in_hdrpassthrunum08 number
,in_hdrpassthrunum09 number
,in_hdrpassthrunum10 number
,in_hdrpassthrudate01 date
,in_hdrpassthrudate02 date
,in_hdrpassthrudate03 date
,in_hdrpassthrudate04 date
,in_hdrpassthrudoll01 number
,in_hdrpassthrudoll02 number
,in_trailer          varchar2
,in_seal             varchar2
,in_palletcount      number
,in_freightcost      number
,in_lateshipreason   varchar2
,in_carrier_del_serv varchar2
,in_shippingcost     number
,in_prono_or_all_trackingnos varchar2
,in_shipfrom_addr1   varchar2
,in_shipfrom_addr2   varchar2
,in_shipfrom_city    varchar2
,in_shipfrom_state   varchar2
,in_shipfrom_postalcode varchar2
,in_invoicenumber810 number
,in_invoiceamount810 number
,in_vicsbolnumber    varchar2
,in_scac             varchar2
,in_authorizationnbr varchar2
,in_link_shipment    varchar2
,in_delivery_requested date
,in_sscccount        number
,in_shipment         varchar2
,in_seq              number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is
errorno integer;

begin

insert into import_945_header
(importfileid
,custid
,reference
,orderid
,shipid
,company
,warehouse
,loadno
,trackingno
,dateshipped
,commitdate
,shipviacode
,lbs
,kgs
,gms
,ozs
,shipticket
,height
,width
,length
,shiptoidcode
,shiptoname
,shiptocontact
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptopostalcode
,shiptocountrycode
,shiptophone
,billtoidcode
,billtoname
,billtocontact
,billtoaddr1
,billtoaddr2
,billtocity
,billtostate
,billtopostalcode
,billtocountrycode
,billtophone
,billtofax
,billtoemail
,carrier
,carrier_name
,packlistshipdate
,routing
,shiptype
,shipterms
,reportingcode
,depositororder
,po
,deliverydate
,estdelivery
,billoflading
,prono
,masterbol
,splitshipno
,invoicedate
,effectivedate
,totalunits
,totalweight
,uomweight
,totalvolume
,uomvolume
,ladingqty
,uom
,warehouse_name
,warehouse_id
,depositor_name
,depositor_id
,hdrpassthruchar01
,hdrpassthruchar02
,hdrpassthruchar03
,hdrpassthruchar04
,hdrpassthruchar05
,hdrpassthruchar06
,hdrpassthruchar07
,hdrpassthruchar08
,hdrpassthruchar09
,hdrpassthruchar10
,hdrpassthruchar11
,hdrpassthruchar12
,hdrpassthruchar13
,hdrpassthruchar14
,hdrpassthruchar15
,hdrpassthruchar16
,hdrpassthruchar17
,hdrpassthruchar18
,hdrpassthruchar19
,hdrpassthruchar20
,hdrpassthruchar21
,hdrpassthruchar22
,hdrpassthruchar23
,hdrpassthruchar24
,hdrpassthruchar25
,hdrpassthruchar26
,hdrpassthruchar27
,hdrpassthruchar28
,hdrpassthruchar29
,hdrpassthruchar30
,hdrpassthruchar31
,hdrpassthruchar32
,hdrpassthruchar33
,hdrpassthruchar34
,hdrpassthruchar35
,hdrpassthruchar36
,hdrpassthruchar37
,hdrpassthruchar38
,hdrpassthruchar39
,hdrpassthruchar40
,hdrpassthruchar41
,hdrpassthruchar42
,hdrpassthruchar43
,hdrpassthruchar44
,hdrpassthruchar45
,hdrpassthruchar46
,hdrpassthruchar47
,hdrpassthruchar48
,hdrpassthruchar49
,hdrpassthruchar50
,hdrpassthruchar51
,hdrpassthruchar52
,hdrpassthruchar53
,hdrpassthruchar54
,hdrpassthruchar55
,hdrpassthruchar56
,hdrpassthruchar57
,hdrpassthruchar58
,hdrpassthruchar59
,hdrpassthruchar60
,hdrpassthrunum01
,hdrpassthrunum02
,hdrpassthrunum03
,hdrpassthrunum04
,hdrpassthrunum05
,hdrpassthrunum06
,hdrpassthrunum07
,hdrpassthrunum08
,hdrpassthrunum09
,hdrpassthrunum10
,hdrpassthrudate01
,hdrpassthrudate02
,hdrpassthrudate03
,hdrpassthrudate04
,hdrpassthrudoll01
,hdrpassthrudoll02
,trailer
,seal
,palletcount
,freightcost
,lateshipreason
,carrier_del_serv
,shippingcost
,prono_or_all_trackingnos
,shipfrom_addr1
,shipfrom_addr2
,shipfrom_city
,shipfrom_state
,shipfrom_postalcode
,invoicenumber810
,invoiceamount810
,vicsbolnumber
,scac
,authorizationnbr
,link_shipment
,delivery_requested
,sscccount
,shipment
,seq
,created
) values
(upper(in_importfileid)
,in_custid
,in_reference
,in_orderid
,in_shipid
,in_company
,in_warehouse
,in_loadno
,in_trackingno
,in_dateshipped
,in_commitdate
,in_shipviacode
,in_lbs
,in_kgs
,in_gms
,in_ozs
,in_shipticket
,in_height
,in_width
,in_length
,in_shiptoidcode
,in_shiptoname
,in_shiptocontact
,in_shiptoaddr1
,in_shiptoaddr2
,in_shiptocity
,in_shiptostate
,in_shiptopostalcode
,in_shiptocountrycode
,in_shiptophone
,in_billtoidcode
,in_billtoname
,in_billtocontact
,in_billtoaddr1
,in_billtoaddr2
,in_billtocity
,in_billtostate
,in_billtopostalcode
,in_billtocountrycode
,in_billtophone
,in_billtofax
,in_billtoemail
,in_carrier
,in_carrier_name
,in_packlistshipdate
,in_routing
,in_shiptype
,in_shipterms
,in_reportingcode
,in_depositororder
,in_po
,in_deliverydate
,in_estdelivery
,in_billoflading
,in_prono
,in_masterbol
,in_splitshipno
,in_invoicedate
,in_effectivedate
,in_totalunits
,in_totalweight
,in_uomweight
,in_totalvolume
,in_uomvolume
,in_ladingqty
,in_uom
,in_warehouse_name
,in_warehouse_id
,in_depositor_name
,in_depositor_id
,in_hdrpassthruchar01
,in_hdrpassthruchar02
,in_hdrpassthruchar03
,in_hdrpassthruchar04
,in_hdrpassthruchar05
,in_hdrpassthruchar06
,in_hdrpassthruchar07
,in_hdrpassthruchar08
,in_hdrpassthruchar09
,in_hdrpassthruchar10
,in_hdrpassthruchar11
,in_hdrpassthruchar12
,in_hdrpassthruchar13
,in_hdrpassthruchar14
,in_hdrpassthruchar15
,in_hdrpassthruchar16
,in_hdrpassthruchar17
,in_hdrpassthruchar18
,in_hdrpassthruchar19
,in_hdrpassthruchar20
,in_hdrpassthruchar21
,in_hdrpassthruchar22
,in_hdrpassthruchar23
,in_hdrpassthruchar24
,in_hdrpassthruchar25
,in_hdrpassthruchar26
,in_hdrpassthruchar27
,in_hdrpassthruchar28
,in_hdrpassthruchar29
,in_hdrpassthruchar30
,in_hdrpassthruchar31
,in_hdrpassthruchar32
,in_hdrpassthruchar33
,in_hdrpassthruchar34
,in_hdrpassthruchar35
,in_hdrpassthruchar36
,in_hdrpassthruchar37
,in_hdrpassthruchar38
,in_hdrpassthruchar39
,in_hdrpassthruchar40
,in_hdrpassthruchar41
,in_hdrpassthruchar42
,in_hdrpassthruchar43
,in_hdrpassthruchar44
,in_hdrpassthruchar45
,in_hdrpassthruchar46
,in_hdrpassthruchar47
,in_hdrpassthruchar48
,in_hdrpassthruchar49
,in_hdrpassthruchar50
,in_hdrpassthruchar51
,in_hdrpassthruchar52
,in_hdrpassthruchar53
,in_hdrpassthruchar54
,in_hdrpassthruchar55
,in_hdrpassthruchar56
,in_hdrpassthruchar57
,in_hdrpassthruchar58
,in_hdrpassthruchar59
,in_hdrpassthruchar60
,in_hdrpassthrunum01
,in_hdrpassthrunum02
,in_hdrpassthrunum03
,in_hdrpassthrunum04
,in_hdrpassthrunum05
,in_hdrpassthrunum06
,in_hdrpassthrunum07
,in_hdrpassthrunum08
,in_hdrpassthrunum09
,in_hdrpassthrunum10
,in_hdrpassthrudate01
,in_hdrpassthrudate02
,in_hdrpassthrudate03
,in_hdrpassthrudate04
,in_hdrpassthrudoll01
,in_hdrpassthrudoll02
,in_trailer
,in_seal
,in_palletcount
,in_freightcost
,in_lateshipreason
,in_carrier_del_serv
,in_shippingcost
,in_prono_or_all_trackingnos
,in_shipfrom_addr1
,in_shipfrom_addr2
,in_shipfrom_city
,in_shipfrom_state
,in_shipfrom_postalcode
,in_invoicenumber810
,in_invoiceamount810
,in_vicsbolnumber
,in_scac
,in_authorizationnbr
,in_link_shipment
,in_delivery_requested
,in_sscccount
,in_shipment
,in_seq
,systimestamp
);
out_msg := 'OKAY';

exception when others then
  out_msg := 'z45h ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_945_header;

procedure import_4pl_945_detail
(in_importfileid varchar2
,in_custid varchar2
,in_reference varchar2
,in_orderid number
,in_shipid number
,in_item varchar2
,in_lotnumber varchar2
,in_assignedid number
,in_shipticket varchar2
,in_trackingno varchar2
,in_servicecode varchar2
,in_lbs number
,in_kgs number
,in_gms number
,in_ozs number
,in_link_lotnumber varchar2
,in_inventoryclass varchar2
,in_statuscode varchar2
,in_linenumber varchar2
,in_orderdate date
,in_po varchar2
,in_qtyordered number
,in_qtyshipped number
,in_qtydiff number
,in_uom varchar2
,in_packlistshipdate date
,in_weight number
,in_weightquaifier varchar2
,in_weightunit varchar2
,in_description varchar2
,in_upc varchar2
,in_dtlpassthruchar01 varchar2
,in_dtlpassthruchar02 varchar2
,in_dtlpassthruchar03 varchar2
,in_dtlpassthruchar04 varchar2
,in_dtlpassthruchar05 varchar2
,in_dtlpassthruchar06 varchar2
,in_dtlpassthruchar07 varchar2
,in_dtlpassthruchar08 varchar2
,in_dtlpassthruchar09 varchar2
,in_dtlpassthruchar10 varchar2
,in_dtlpassthruchar11 varchar2
,in_dtlpassthruchar12 varchar2
,in_dtlpassthruchar13 varchar2
,in_dtlpassthruchar14 varchar2
,in_dtlpassthruchar15 varchar2
,in_dtlpassthruchar16 varchar2
,in_dtlpassthruchar17 varchar2
,in_dtlpassthruchar18 varchar2
,in_dtlpassthruchar19 varchar2
,in_dtlpassthruchar20 varchar2
,in_dtlpassthruchar21 varchar2
,in_dtlpassthruchar22 varchar2
,in_dtlpassthruchar23 varchar2
,in_dtlpassthruchar24 varchar2
,in_dtlpassthruchar25 varchar2
,in_dtlpassthruchar26 varchar2
,in_dtlpassthruchar27 varchar2
,in_dtlpassthruchar28 varchar2
,in_dtlpassthruchar29 varchar2
,in_dtlpassthruchar30 varchar2
,in_dtlpassthruchar31 varchar2
,in_dtlpassthruchar32 varchar2
,in_dtlpassthruchar33 varchar2
,in_dtlpassthruchar34 varchar2
,in_dtlpassthruchar35 varchar2
,in_dtlpassthruchar36 varchar2
,in_dtlpassthruchar37 varchar2
,in_dtlpassthruchar38 varchar2
,in_dtlpassthruchar39 varchar2
,in_dtlpassthruchar40 varchar2
,in_dtlpassthrunum01 number
,in_dtlpassthrunum02 number
,in_dtlpassthrunum03 number
,in_dtlpassthrunum04 number
,in_dtlpassthrunum05 number
,in_dtlpassthrunum06 number
,in_dtlpassthrunum07 number
,in_dtlpassthrunum08 number
,in_dtlpassthrunum09 number
,in_dtlpassthrunum10 number
,in_dtlpassthrunum11 number
,in_dtlpassthrunum12 number
,in_dtlpassthrunum13 number
,in_dtlpassthrunum14 number
,in_dtlpassthrunum15 number
,in_dtlpassthrunum16 number
,in_dtlpassthrunum17 number
,in_dtlpassthrunum18 number
,in_dtlpassthrunum19 number
,in_dtlpassthrunum20 number
,in_dtlpassthrudate01 date
,in_dtlpassthrudate02 date
,in_dtlpassthrudate03 date
,in_dtlpassthrudate04 date
,in_dtlpassthrudoll01 number
,in_dtlpassthrudoll02 number
,in_fromlpid varchar2
,in_smallpackagelbs number
,in_deliveryservice varchar2
,in_entereduom varchar2
,in_qtyshippedeuom number
,in_seq number
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

begin

out_errorno := 0;
out_msg := '';

insert into import_945_detail
(importfileid
,custid
,reference
,orderid
,shipid
,item
,lotnumber
,assignedid
,shipticket
,trackingno
,servicecode
,lbs
,kgs
,gms
,ozs
,link_lotnumber
,inventoryclass
,statuscode
,linenumber
,orderdate
,po
,qtyordered
,qtyshipped
,qtydiff
,uom
,packlistshipdate
,weight
,weightquaifier
,weightunit
,description
,upc
,dtlpassthruchar01
,dtlpassthruchar02
,dtlpassthruchar03
,dtlpassthruchar04
,dtlpassthruchar05
,dtlpassthruchar06
,dtlpassthruchar07
,dtlpassthruchar08
,dtlpassthruchar09
,dtlpassthruchar10
,dtlpassthruchar11
,dtlpassthruchar12
,dtlpassthruchar13
,dtlpassthruchar14
,dtlpassthruchar15
,dtlpassthruchar16
,dtlpassthruchar17
,dtlpassthruchar18
,dtlpassthruchar19
,dtlpassthruchar20
,dtlpassthruchar21
,dtlpassthruchar22
,dtlpassthruchar23
,dtlpassthruchar24
,dtlpassthruchar25
,dtlpassthruchar26
,dtlpassthruchar27
,dtlpassthruchar28
,dtlpassthruchar29
,dtlpassthruchar30
,dtlpassthruchar31
,dtlpassthruchar32
,dtlpassthruchar33
,dtlpassthruchar34
,dtlpassthruchar35
,dtlpassthruchar36
,dtlpassthruchar37
,dtlpassthruchar38
,dtlpassthruchar39
,dtlpassthruchar40
,dtlpassthrunum01
,dtlpassthrunum02
,dtlpassthrunum03
,dtlpassthrunum04
,dtlpassthrunum05
,dtlpassthrunum06
,dtlpassthrunum07
,dtlpassthrunum08
,dtlpassthrunum09
,dtlpassthrunum10
,dtlpassthrunum11
,dtlpassthrunum12
,dtlpassthrunum13
,dtlpassthrunum14
,dtlpassthrunum15
,dtlpassthrunum16
,dtlpassthrunum17
,dtlpassthrunum18
,dtlpassthrunum19
,dtlpassthrunum20
,dtlpassthrudate01
,dtlpassthrudate02
,dtlpassthrudate03
,dtlpassthrudate04
,dtlpassthrudoll01
,dtlpassthrudoll02
,fromlpid
,smallpackagelbs
,deliveryservice
,entereduom
,qtyshippedeuom
,seq
,created
)
values
(upper(in_importfileid)
,in_custid
,in_reference
,in_orderid
,in_shipid
,in_item
,in_lotnumber
,in_assignedid
,in_shipticket
,in_trackingno
,in_servicecode
,in_lbs
,in_kgs
,in_gms
,in_ozs
,in_link_lotnumber
,in_inventoryclass
,in_statuscode
,in_linenumber
,in_orderdate
,in_po
,in_qtyordered
,in_qtyshipped
,in_qtydiff
,in_uom
,in_packlistshipdate
,in_weight
,in_weightquaifier
,in_weightunit
,in_description
,in_upc
,in_dtlpassthruchar01
,in_dtlpassthruchar02
,in_dtlpassthruchar03
,in_dtlpassthruchar04
,in_dtlpassthruchar05
,in_dtlpassthruchar06
,in_dtlpassthruchar07
,in_dtlpassthruchar08
,in_dtlpassthruchar09
,in_dtlpassthruchar10
,in_dtlpassthruchar11
,in_dtlpassthruchar12
,in_dtlpassthruchar13
,in_dtlpassthruchar14
,in_dtlpassthruchar15
,in_dtlpassthruchar16
,in_dtlpassthruchar17
,in_dtlpassthruchar18
,in_dtlpassthruchar19
,in_dtlpassthruchar20
,in_dtlpassthruchar21
,in_dtlpassthruchar22
,in_dtlpassthruchar23
,in_dtlpassthruchar24
,in_dtlpassthruchar25
,in_dtlpassthruchar26
,in_dtlpassthruchar27
,in_dtlpassthruchar28
,in_dtlpassthruchar29
,in_dtlpassthruchar30
,in_dtlpassthruchar31
,in_dtlpassthruchar32
,in_dtlpassthruchar33
,in_dtlpassthruchar34
,in_dtlpassthruchar35
,in_dtlpassthruchar36
,in_dtlpassthruchar37
,in_dtlpassthruchar38
,in_dtlpassthruchar39
,in_dtlpassthruchar40
,in_dtlpassthrunum01
,in_dtlpassthrunum02
,in_dtlpassthrunum03
,in_dtlpassthrunum04
,in_dtlpassthrunum05
,in_dtlpassthrunum06
,in_dtlpassthrunum07
,in_dtlpassthrunum08
,in_dtlpassthrunum09
,in_dtlpassthrunum10
,in_dtlpassthrunum11
,in_dtlpassthrunum12
,in_dtlpassthrunum13
,in_dtlpassthrunum14
,in_dtlpassthrunum15
,in_dtlpassthrunum16
,in_dtlpassthrunum17
,in_dtlpassthrunum18
,in_dtlpassthrunum19
,in_dtlpassthrunum20
,in_dtlpassthrudate01
,in_dtlpassthrudate02
,in_dtlpassthrudate03
,in_dtlpassthrudate04
,in_dtlpassthrudoll01
,in_dtlpassthrudoll02
,in_fromlpid
,in_smallpackagelbs
,in_deliveryservice
,in_entereduom
,in_qtyshippedeuom
,in_seq
,systimestamp
);

out_msg := 'OKAY';

exception when others then
  out_msg := 'z45d ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_945_detail;

procedure end_of_import_4pl_945
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

strDebugYN char(1);

cursor curOHByOrderid(in_orderid number, in_shipid number) is
   select * from orderhdr
      where orderid = in_orderid
        and shipid = in_shipid;

cursor curOHByReference(in_custid varchar2, in_reference varchar2) is
   select * from orderhdr
      where custid = in_custid
        and reference = in_reference;
OH curOHByOrderid%rowtype;

cursor curPlate(in_facility varchar2, in_custid varchar2, in_item varchar2, in_lotnumber varchar2) is
   select *
      from plate
      where facility = in_facility
        and custid = in_custid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
        and invstatus = 'AV'
        and inventoryclass = 'RG'
        and quantity > nvl(qtytasked,0)
      order by creationdate;
PL curPlate%rowtype;


qtyNeeded integer;
l_parentlpid shippingplate.parentlpid%type;
l_lpid shippingplate.parentlpid%type;
dBaseUOM varchar2(3);
dCube custitem.cube%type;
l_msg varchar2(255);
spQty integer;
out_filename varchar2(255);
theWave orderhdr.wave%type;
theLoad orderhdr.loadno%type;
theStopno loadstopship.stopno%type;
theShipno loadstopship.shipno%type;
isLoaded varchar2(2);
out_errmsg varchar2(255);
usr varchar2(20);
doorLoc location.locid%type;
waveLoopCnt integer;
loadErr varchar2(255);
regen_needed char(1);
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;


procedure order_msg(in_msgtype varchar2, in_facility varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_autonomous_msg(IMP_USERID, in_facility, rtrim(in_custid),
    out_msg || ' file ' || out_filename, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  debugmsg(out_msg);
end;
procedure validate_detail(OH curOHByOrderid%rowtype, in_seq integer)
is
dQty integer;
dQtyOrder integer;

begin
  debugmsg('validate detail');
  for DTL in (select d.item, I.baseuom as uom, sum(d.qtyshipped) as qtyshipped
                from import_945_detail d, custitem I
                where importfileid = (upper(in_importfileid))
                  and d.seq = in_seq
                  and I.custid = d.custid
                  and I.item = d.item
               group by d.item, I.baseuom)  loop
     debugmsg('item ' || DTL.item || ' ' || DTL.uom || ' ' || DTL.qtyshipped);
     begin
        select baseuom, cube into dBaseuom, dCube
           from custitem
           where custid = OH.custid
             and item = DTL.item;
     exception when no_data_found then
        out_msg := '4PL 945 unkown item ' || OH.custid || ' ' || DTL.item || ' skipping order ' || OH.orderid || '-' || OH.shipid;
        order_msg('E',null);
        return;
     end;
     dQty := zlbl.uom_qty_conv(OH.custid, DTL.item, DTL.qtyshipped, DTL.uom, dBaseuom);
     begin
        select qtyorder into dQtyOrder
           from orderdtl
           where orderid = OH.orderid
             and shipid = OH.shipid
             and item = DTL.item;
     exception when no_data_found then
        out_msg := '4PL 945 item not on order ' || OH.custid || ' ' || DTL.item || ' skipping order ' || OH.orderid || '-' || OH.shipid;
        order_msg('E',null);
        return;
     end;
     if dQty > dQtyOrder then
        out_msg := '4PL 945 qty shipped > qty ordered ' || OH.custid || ' ' || DTL.item || ' ' || dQty || ' skipping order ' || OH.orderid || '-' || OH.shipid;
        order_msg('E',null);
        return;
     end if;
  end loop; /* for DTL */
  out_msg := 'OKAY';
end validate_detail;

procedure validate_picks(OH curOHByOrderid%rowtype, in_seq integer)
is
dBaseUOM varchar2(3);
dQty integer;
dQtyAvail integer;
begin
  debugmsg('validate picks');
  for DTL in (select d.item, d.lotnumber, I.baseuom as uom, sum(d.qtyshipped) as qtyshipped
                from import_945_detail d, custitem I
                where importfileid = (upper(in_importfileid))
                  and d.seq = in_seq
                  and I.custid = d.custid
                  and I.item = d.item
               group by d.item, d.lotnumber, I.baseuom)  loop
     debugmsg('item ' || DTL.item || ' ' || DTL.uom || ' ' || DTL.qtyshipped);
     begin
        select baseuom into dBaseuom
           from custitem
           where custid = OH.custid
             and item = DTL.item;
     exception when no_data_found then
        out_msg := '4PL 945 unkown item ' || OH.custid || ' ' || DTL.item || ' skipping order ' || OH.orderid || '-' || OH.shipid;
        order_msg('E',null);
        return;
     end;
     dQty := zlbl.uom_qty_conv(OH.custid, DTL.item, DTL.qtyshipped, DTL.uom, dBaseuom);
     select sum(quantity - nvl(qtytasked,0)) into dQtyAvail
        from plate
        where facility = OH.fromfacility
          and custid = OH.custid
          and item = DTL.item
          and nvl(lotnumber, '(none)') = nvl(DTL.lotnumber, '(none)')
          and invstatus = 'AV'
          and inventoryclass = 'RG';
     debugmsg('found ' || dQtyAvail);
     if dQty > dQtyAvail or
        dQtyAvail is null then
        out_msg := '4PL 945 qty shipped > qty avail ' || OH.custid || ' ' || DTL.item || ' ' || DTL.lotnumber || ' ' || dQty || ' skipping order ' || OH.orderid || '-' || OH.shipid;
        order_msg('E',null);
        return;

     end if;

  end loop; --for DTL
  out_msg := 'OKAY';
end validate_picks;


begin
if out_errorno = -12345 then
   strdebugyn := 'Y';
   debugmsg('debug is on');
else
   strdebugyn := 'N';
end if;
out_errorno := 0;
out_msg := '';
out_filename := substr(in_importfileid, instr(in_importfileid, '\', -1)+1);

for HDR in (select * from import_945_header where importfileid = upper(in_importfileid)) loop
   zoh.add_orderhistory_item(HDR.orderid, HDR.shipid,
         HDR.shipid, null, null,
         '945 Import',
         'File ' || out_filename,
         IMP_USERID, l_msg);
   debugmsg('seq is ' || HDR.seq);
   if HDR.orderid is not null then
      debugmsg('by order ' || HDR.orderid ||' ' || HDR.shipid);
      open curOHByOrderid(HDR.orderid, HDR.shipid);
      fetch curOHByOrderid into OH;
      if curOHByOrderid%notfound then
          out_msg := '4PL 945 order not found ' || HDR.orderid || ' ' || HDR.shipid;
          order_msg('E', null);
          close curOHByOrderid;
          goto continue_orderid_loop;
      end if;
      close curOHByOrderid;
   else
      debugmsg('by reference ' || HDR.custid || ' ' || HDR.reference);
      open curOHByReference(HDR.custid, HDR.reference);
      fetch curOHByReference into OH;
      if curOHByReference%notfound then
          out_msg := '4PL 945 order not found ' || HDR.custid || ' ' || HDR.reference;
          order_msg('E',null);
          close curOHByreference;
          goto continue_orderid_loop;
      end if;
      close curOHByReference;
   end if;
   debugmsg('order found ' || OH.orderid);
   if OH.orderstatus > '1' then
      out_msg := '4PL 945 invalid order status  ' || OH.orderstatus || ' ' ||  HDR.orderid || ' ' || HDR.shipid;
      order_msg('E',null);
      goto continue_orderid_loop;
   end if;
   if OH.ordertype <> 'O' then
      out_msg := '4PL 945 invalid order type  ' || OH.ordertype || ' ' ||  HDR.orderid || ' ' || HDR.shipid;
      order_msg('E',null);
      goto continue_orderid_loop;
   end if;
   /* loop throuh details for this order and check totals before proceeding */
   validate_detail(OH, HDR.seq);
   if out_msg != 'OKAY' then
     goto continue_orderid_loop;
   end if;
   validate_picks(OH, HDR.seq);
   if out_msg != 'OKAY' then
      goto continue_orderid_loop;
   end if;
    -- create a door location for this load. will be delete after close
   doorLoc := 'DO' || HDR.seq;
   begin
      insert into location
         (locid, facility, loctype, storagetype, section, checkdigit, status,
          equipprof, velocity, mixeditemsok, mixedlotsok, mixeduomok, lastuser,
          lastupdate, unitofstorage, descr, mixedcustsok)
      values
         (doorLoc, OH.fromfacility, 'DOR', 'NA','1', '10', 'E',
          'AL', 'B', 'Y', 'Y', 'Y', IMP_USERID,
          sysdate, 'N/A', 'Door', 'Y');
      commit;
   exception when DUP_VAL_ON_INDEX then
      null;
   end;
   ZLD.GET_NEXT_LOADNO(theLoad, out_errmsg);
   debugmsg('the load is '|| theLoad);
   zsp.get_next_shippinglpid(l_parentlpid, l_msg);
   if l_msg is not null then
      out_msg := 'No next shippinglpid: ' || l_msg;
      return;
   end if;
   zsod.build_outbound_load(theLoad, HDR.orderid, HDR.shipid, nvl(HDR.carrier, OH.carrier),
         nvl(HDR.trailer,'T945'), null, nvl(HDR.billoflading, OH.billoflading),
         'STG945', doorLoc, IMP_USERID, theStopno, theShipno, l_msg);

   insert into shippingplate -- one master for order
      (lpid, custid, facility, location, status,
       quantity, type, lastuser, lastupdate, orderid, shipid, weight,
       loadno, stopno, shipno)
     values (
       l_parentlpid, OH.custid, OH.fromfacility, OH.custid, 'L',
       0, 'M', IMP_USERID, sysdate, OH.orderid, OH.shipid, 0,
       theLoad, theStopno, theShipno);

   for DTL in (select d.item, d.lotnumber, I.baseuom as uom, I.cube, I.weight, d.qtyshipped
                 from import_945_detail d, custitem I
                 where importfileid = (upper(in_importfileid))
                   and seq = HDR.seq
                   and I.custid = d.custid
                   and I.item = d.item
               order by item, lotnumber, uom) loop
      qtyNeeded := DTL.qtyshipped;
      debugmsg(OH.fromfacility || ' ' || OH.CUSTID || ' ' || DTL.item || ' ' || DTL.lotnumber || ' ' || DTL.qtyshipped);
      open curPlate(OH.fromfacility, OH.custid, DTL.item, DTL.lotnumber);
      while qtyNeeded > 0 loop
         fetch curPlate into PL;
         exit when curPlate%notfound;
         zsp.get_next_shippinglpid(l_lpid, l_msg);
         if l_msg is not null then
            out_msg := 'No next shippinglpid: ' || l_msg;
            rollback;
            return;
         end if;
         if PL.quantity - nvl(PL.qtytasked,0) > qtyNeeded then
            spQty := qtyNeeded;
         else
            spQty := PL.quantity - nvl(PL.qtytasked,0);
         end if;
         qtyNeeded := qtyNeeded - spQty;
         debugmsg('create plates ' || l_lpid || ' ' ||spQty || ' ' || PL.lpid);
         insert into shippingplate
            (lpid, item, custid, facility, location, status,
             unitofmeasure, quantity, type, fromlpid,
             lotnumber, parentlpid,
             lastuser, lastupdate, invstatus, qtyentered, orderitem, uomentered,
             inventoryclass, orderid, shipid,
             weight,
             pickuom, pickqty,
             loadno, stopno, shipno)
         values(l_lpid, DTL.item, OH.custid, OH.fromfacility, OH.custid, 'L',
                dBaseuom, spQty, 'P', PL.lpid,
                DTL.lotnumber, l_parentlpid,
                IMP_USERID, sysdate, PL.invstatus, spQty, DTL.item, dbaseuom,
                PL.inventoryclass, HDR.orderid, HDR.shipid,
                spQty*zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom),
                DTL.uom,spQty,
                theLoad, theStopno, theShipno);
         update shippingplate
            set quantity = quantity + spQty,
                weight = weight + spQty*zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom)
            where lpid = l_parentlpid;
         debugmsg('update orderhdr ' || HDR.orderid || ' ' ||HDR.shipid);
         debugmsg('    ' || Pl.lpid || ' ' || DTL.item || ' ' || DTL.uom || ' ' || spQty );
         debugmsg('     cube ' || DTL.cube || ' weight ' || DTL.weight || ' ' ||
                  zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom));

         update orderdtl
            set qtypick = nvl(qtypick, 0) + spQty,
                weightpick = nvl(weightpick, 0) + (spQty * DTL.weight),-- spQty*zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom),
                cubepick = nvl(cubepick, 0) + (spQty * zci.item_cube(HDR.custid, DTL.item, DTL.UOM)),
                qtyship = nvl(qtyship, 0) + spQty,
                weightship = nvl(weightship, 0) + (spQty *DTL.weight), --spQty*zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom),
                cubeship = nvl(cubeship, 0) + (spQty * zci.item_cube(HDR.custid, DTL.item, DTL.UOM)),
                lastuser = IMP_USERID,
                lastupdate = sysdate
            where orderid = HDR.orderid
              and shipid = HDR.shipid
              and item = DTL.item;
         /*
         update orderhdr
            set qtypick = nvl(qtypick, 0) + spQty,
                weightpick = nvl(weightpick, 0) + (spQty*DTL.weight),
                cubepick = nvl(cubepick, 0) + (spQty * DTL.cube),
                qtyship = nvl(qtyship, 0) + spQty,
                weightship = nvl(weightship, 0) +  (spQty * DTL.weight), --spQty*zcwt.lp_item_weight(PL.lpid, HDR.custid, DTL.item, DTL.uom),
                cubeship = nvl(cubeship, 0) + (spQty * DTL.cube),
                lastuser = IMP_USERID,
                lastupdate = sysdate
            where orderid = HDR.orderid
              and shipid = HDR.shipid;
         */
         update loadstopship
            set qtyship = nvl(qtyship, 0) + spQty,
                weightship = nvl(weightship, 0) + DTL.weight,
                weightship_kgs = nvl(weightship_kgs,0)
                               + nvl(zwt.from_lbs_to_kgs(HDR.custid,DTL.weight),0),
                cubeship = nvl(cubeship, 0) + (spQty * DTL.cube),
                lastuser = IMP_USERID,
                lastupdate = sysdate
            where loadno = theLoad
              and stopno = theStopno
              and shipno = theShipno;

         zoh.add_orderhistory_item(HDR.orderid, HDR.shipid,
               HDR.shipid, DTL.item, DTL.lotnumber,
               'Pick Plate',
               'Pick Qty:'||SPqty||' from LP:'||PL.lpid,
               IMP_USERID, l_msg);
         if spQty = PL.quantity then
            zlp.plate_to_deletedplate(PL.lpid, IMP_USERID, null, out_errmsg);
         else
            update plate
               set quantity = quantity - spQty
             where lpid = PL.lpid;
         end if;
      end loop;
      close curPlate;
   end loop;

   if OH.billoflading is null then
      OH.billoflading := OH.orderid || ' ' || OH.shipid;
   end if;

   update loads
      set loadstatus = zrf.LOD_LOADED
    where loadno = theLoad;
   update loadstop
      set loadstopstatus = zrf.LOD_LOADED
    where loadno = theLoad
      and stopno = theStopno;
   update orderhdr
      set orderstatus = zrf.ORD_LOADED
    where orderid = HDR.orderid
      and shipid = HDR.shipid;
   commit;
   debugmsg('close it');
   zld.close_outbound_load(theLoad, OH.fromfacility, HDR.prono,
         HDR.dateshipped, IMP_USERID, 'N', regen_needed, out_errmsg);
   if out_errmsg <> 'OKAY' then
      out_msg := '4PL 945 load close error ' ||  HDR.orderid || ' ' || HDR.shipid || ' ' || out_errmsg;
      order_msg('E',OH.fromfacility);
      goto delete_loc;
   end if;
   zld.check_for_interface(theLoad,0,0,OH.fromfacility, 'REGORDTYPES',
        'REGI44SNFMT', 'RETORDTYPES', 'RETI9GIFMT', IMP_USERID, out_errmsg);
   debugmsg('CFI ' || out_errmsg);

<< delete_loc >>
   begin
      delete from location where locid = doorloc;
   exception when others then
      null;
   end;
   commit;
<< continue_orderid_loop >>
  null;
end loop;

out_msg := 'End of import 4pl 945: ' ||in_custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I', oh.fromfacility);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeoi ' || sqlerrm;
  out_errorno := sqlcode;
end end_of_import_4pl_945;


procedure import_4pl_944_header
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_company in varchar2
,in_warehouse in varchar2
,in_loadno in number
,in_cust_orderid in varchar2
,in_cust_shipid in varchar2
,in_shipfrom in varchar2
,in_shipfromid in varchar2
,in_receipt_date in date
,in_vendor in varchar2
,in_vendor_desc in varchar2
,in_bill_of_lading in varchar2
,in_carrier in varchar2
,in_routing in varchar2
,in_po varchar
,in_order_type in varchar2
,in_qtyorder in number
,in_qtyrcvd in number
,in_qtyrcvdgood in number
,in_qtyrcvddmgd in number
,in_reporting_code in varchar2
,in_some_date in date
,in_unload_date in date
,in_whse_receipt_num in varchar2
,in_transmeth_type in varchar2
,in_packer_number in varchar2
,in_vendor_order_num in varchar2
,in_warehouse_name in varchar2
,in_warehouse_id in varchar2
,in_depositor_name in varchar2
,in_depositor_id in varchar2
,in_hdrpassthruchar01 in varchar2
,in_hdrpassthruchar02 in varchar2
,in_hdrpassthruchar03 in varchar2
,in_hdrpassthruchar04 in varchar2
,in_hdrpassthruchar05 in varchar2
,in_hdrpassthruchar06 in varchar2
,in_hdrpassthruchar07 in varchar2
,in_hdrpassthruchar08 in varchar2
,in_hdrpassthruchar09 in varchar2
,in_hdrpassthruchar10 in varchar2
,in_hdrpassthruchar11 in varchar2
,in_hdrpassthruchar12 in varchar2
,in_hdrpassthruchar13 in varchar2
,in_hdrpassthruchar14 in varchar2
,in_hdrpassthruchar15 in varchar2
,in_hdrpassthruchar16 in varchar2
,in_hdrpassthruchar17 in varchar2
,in_hdrpassthruchar18 in varchar2
,in_hdrpassthruchar19 in varchar2
,in_hdrpassthruchar20 in varchar2
,in_hdrpassthruchar21 in varchar2
,in_hdrpassthruchar22 in varchar2
,in_hdrpassthruchar23 in varchar2
,in_hdrpassthruchar24 in varchar2
,in_hdrpassthruchar25 in varchar2
,in_hdrpassthruchar26 in varchar2
,in_hdrpassthruchar27 in varchar2
,in_hdrpassthruchar28 in varchar2
,in_hdrpassthruchar29 in varchar2
,in_hdrpassthruchar30 in varchar2
,in_hdrpassthruchar31 in varchar2
,in_hdrpassthruchar32 in varchar2
,in_hdrpassthruchar33 in varchar2
,in_hdrpassthruchar34 in varchar2
,in_hdrpassthruchar35 in varchar2
,in_hdrpassthruchar36 in varchar2
,in_hdrpassthruchar37 in varchar2
,in_hdrpassthruchar38 in varchar2
,in_hdrpassthruchar39 in varchar2
,in_hdrpassthruchar40 in varchar2
,in_hdrpassthruchar41 in varchar2
,in_hdrpassthruchar42 in varchar2
,in_hdrpassthruchar43 in varchar2
,in_hdrpassthruchar44 in varchar2
,in_hdrpassthruchar45 in varchar2
,in_hdrpassthruchar46 in varchar2
,in_hdrpassthruchar47 in varchar2
,in_hdrpassthruchar48 in varchar2
,in_hdrpassthruchar49 in varchar2
,in_hdrpassthruchar50 in varchar2
,in_hdrpassthruchar51 in varchar2
,in_hdrpassthruchar52 in varchar2
,in_hdrpassthruchar53 in varchar2
,in_hdrpassthruchar54 in varchar2
,in_hdrpassthruchar55 in varchar2
,in_hdrpassthruchar56 in varchar2
,in_hdrpassthruchar57 in varchar2
,in_hdrpassthruchar58 in varchar2
,in_hdrpassthruchar59 in varchar2
,in_hdrpassthruchar60 in varchar2
,in_hdrpassthrunum01 in number
,in_hdrpassthrunum02 in number
,in_hdrpassthrunum03 in number
,in_hdrpassthrunum04 in number
,in_hdrpassthrunum05 in number
,in_hdrpassthrunum06 in number
,in_hdrpassthrunum07 in number
,in_hdrpassthrunum08 in number
,in_hdrpassthrunum09 in number
,in_hdrpassthrunum10 in number
,in_hdrpassthrudate01 in date
,in_hdrpassthrudate02 in date
,in_hdrpassthrudate03 in date
,in_hdrpassthrudate04 in date
,in_hdrpassthrudoll01 in number
,in_hdrpassthrudoll02 in number
,in_prono in varchar2
,in_trailer in varchar2
,in_seal in varchar2
,in_palletcount in number
,in_facility in varchar2
,in_shippername in varchar2
,in_shippercontact in varchar2
,in_shipperaddr1 in varchar2
,in_shipperaddr2 in varchar2
,in_shippercity in varchar2
,in_shipperstate in varchar2
,in_shipperpostalcode in varchar2
,in_shippercountrycode in varchar2
,in_shipperphone in varchar2
,in_shipperfax in varchar2
,in_shipperemail in varchar2
,in_billtoname in varchar2
,in_billtocontact in varchar2
,in_billtoaddr1 in varchar2
,in_billtoaddr2 in varchar2
,in_billtocity in varchar2
,in_billtostate in varchar2
,in_billtopostalcode in varchar2
,in_billtocountrycode in varchar2
,in_billtophone in varchar2
,in_billtofax in varchar2
,in_billtoemail in varchar2
,in_rma in varchar2
,in_ordertype in varchar2
,in_returntrackingno in varchar2
,in_statususer in varchar2
,in_instructions in varchar2
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
) is
errorno integer;

begin

insert into import_944_header
(importfileid
,custid
,reference
,orderid
,shipid
,company
,warehouse
,loadno
,cust_orderid
,cust_shipid
,shipfrom
,shipfromid
,receipt_date
,vendor
,vendor_desc
,bill_of_lading
,carrier
,routing
,po
,order_type
,qtyorder
,qtyrcvd
,qtyrcvdgood
,qtyrcvddmgd
,reporting_code
,some_date
,unload_date
,whse_receipt_num
,transmeth_type
,packer_number
,vendor_order_num
,warehouse_name
,warehouse_id
,depositor_name
,depositor_id
,hdrpassthruchar01
,hdrpassthruchar02
,hdrpassthruchar03
,hdrpassthruchar04
,hdrpassthruchar05
,hdrpassthruchar06
,hdrpassthruchar07
,hdrpassthruchar08
,hdrpassthruchar09
,hdrpassthruchar10
,hdrpassthruchar11
,hdrpassthruchar12
,hdrpassthruchar13
,hdrpassthruchar14
,hdrpassthruchar15
,hdrpassthruchar16
,hdrpassthruchar17
,hdrpassthruchar18
,hdrpassthruchar19
,hdrpassthruchar20
,hdrpassthruchar21
,hdrpassthruchar22
,hdrpassthruchar23
,hdrpassthruchar24
,hdrpassthruchar25
,hdrpassthruchar26
,hdrpassthruchar27
,hdrpassthruchar28
,hdrpassthruchar29
,hdrpassthruchar30
,hdrpassthruchar31
,hdrpassthruchar32
,hdrpassthruchar33
,hdrpassthruchar34
,hdrpassthruchar35
,hdrpassthruchar36
,hdrpassthruchar37
,hdrpassthruchar38
,hdrpassthruchar39
,hdrpassthruchar40
,hdrpassthruchar41
,hdrpassthruchar42
,hdrpassthruchar43
,hdrpassthruchar44
,hdrpassthruchar45
,hdrpassthruchar46
,hdrpassthruchar47
,hdrpassthruchar48
,hdrpassthruchar49
,hdrpassthruchar50
,hdrpassthruchar51
,hdrpassthruchar52
,hdrpassthruchar53
,hdrpassthruchar54
,hdrpassthruchar55
,hdrpassthruchar56
,hdrpassthruchar57
,hdrpassthruchar58
,hdrpassthruchar59
,hdrpassthruchar60
,hdrpassthrunum01
,hdrpassthrunum02
,hdrpassthrunum03
,hdrpassthrunum04
,hdrpassthrunum05
,hdrpassthrunum06
,hdrpassthrunum07
,hdrpassthrunum08
,hdrpassthrunum09
,hdrpassthrunum10
,hdrpassthrudate01
,hdrpassthrudate02
,hdrpassthrudate03
,hdrpassthrudate04
,hdrpassthrudoll01
,hdrpassthrudoll02
,prono
,trailer
,seal
,palletcount
,facility
,shippername
,shippercontact
,shipperaddr1
,shipperaddr2
,shippercity
,shipperstate
,shipperpostalcode
,shippercountrycode
,shipperphone
,shipperfax
,shipperemail
,billtoname
,billtocontact
,billtoaddr1
,billtoaddr2
,billtocity
,billtostate
,billtopostalcode
,billtocountrycode
,billtophone
,billtofax
,billtoemail
,rma
,ordertype
,returntrackingno
,statususer
,instructions
,seq
,created
) values
(upper(in_importfileid)
,in_custid
,in_reference
,in_orderid
,in_shipid
,in_company
,in_warehouse
,in_loadno
,in_cust_orderid
,in_cust_shipid
,in_shipfrom
,in_shipfromid
,in_receipt_date
,in_vendor
,in_vendor_desc
,in_bill_of_lading
,in_carrier
,in_routing
,in_po
,in_order_type
,in_qtyorder
,in_qtyrcvd
,in_qtyrcvdgood
,in_qtyrcvddmgd
,in_reporting_code
,in_some_date
,in_unload_date
,in_whse_receipt_num
,in_transmeth_type
,in_packer_number
,in_vendor_order_num
,in_warehouse_name
,in_warehouse_id
,in_depositor_name
,in_depositor_id
,in_hdrpassthruchar01
,in_hdrpassthruchar02
,in_hdrpassthruchar03
,in_hdrpassthruchar04
,in_hdrpassthruchar05
,in_hdrpassthruchar06
,in_hdrpassthruchar07
,in_hdrpassthruchar08
,in_hdrpassthruchar09
,in_hdrpassthruchar10
,in_hdrpassthruchar11
,in_hdrpassthruchar12
,in_hdrpassthruchar13
,in_hdrpassthruchar14
,in_hdrpassthruchar15
,in_hdrpassthruchar16
,in_hdrpassthruchar17
,in_hdrpassthruchar18
,in_hdrpassthruchar19
,in_hdrpassthruchar20
,in_hdrpassthruchar21
,in_hdrpassthruchar22
,in_hdrpassthruchar23
,in_hdrpassthruchar24
,in_hdrpassthruchar25
,in_hdrpassthruchar26
,in_hdrpassthruchar27
,in_hdrpassthruchar28
,in_hdrpassthruchar29
,in_hdrpassthruchar30
,in_hdrpassthruchar31
,in_hdrpassthruchar32
,in_hdrpassthruchar33
,in_hdrpassthruchar34
,in_hdrpassthruchar35
,in_hdrpassthruchar36
,in_hdrpassthruchar37
,in_hdrpassthruchar38
,in_hdrpassthruchar39
,in_hdrpassthruchar40
,in_hdrpassthruchar41
,in_hdrpassthruchar42
,in_hdrpassthruchar43
,in_hdrpassthruchar44
,in_hdrpassthruchar45
,in_hdrpassthruchar46
,in_hdrpassthruchar47
,in_hdrpassthruchar48
,in_hdrpassthruchar49
,in_hdrpassthruchar50
,in_hdrpassthruchar51
,in_hdrpassthruchar52
,in_hdrpassthruchar53
,in_hdrpassthruchar54
,in_hdrpassthruchar55
,in_hdrpassthruchar56
,in_hdrpassthruchar57
,in_hdrpassthruchar58
,in_hdrpassthruchar59
,in_hdrpassthruchar60
,in_hdrpassthrunum01
,in_hdrpassthrunum02
,in_hdrpassthrunum03
,in_hdrpassthrunum04
,in_hdrpassthrunum05
,in_hdrpassthrunum06
,in_hdrpassthrunum07
,in_hdrpassthrunum08
,in_hdrpassthrunum09
,in_hdrpassthrunum10
,in_hdrpassthrudate01
,in_hdrpassthrudate02
,in_hdrpassthrudate03
,in_hdrpassthrudate04
,in_hdrpassthrudoll01
,in_hdrpassthrudoll02
,in_prono
,in_trailer
,in_seal
,in_palletcount
,in_facility
,in_shippername
,in_shippercontact
,in_shipperaddr1
,in_shipperaddr2
,in_shippercity
,in_shipperstate
,in_shipperpostalcode
,in_shippercountrycode
,in_shipperphone
,in_shipperfax
,in_shipperemail
,in_billtoname
,in_billtocontact
,in_billtoaddr1
,in_billtoaddr2
,in_billtocity
,in_billtostate
,in_billtopostalcode
,in_billtocountrycode
,in_billtophone
,in_billtofax
,in_billtoemail
,in_rma
,in_ordertype
,in_returntrackingno
,in_statususer
,in_instructions
,in_seq
,systimestamp
);
out_msg := 'OKAY';

exception when others then
  out_msg := 'z44h ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_944_header;

procedure import_4pl_944_detail
(in_importfileid in varchar2
,in_custid in varchar2
,in_reference in varchar2
,in_orderid in number
,in_shipid in number
,in_item in varchar2
,in_lotnumber in varchar2
,in_line_number in number
,in_upc in varchar2
,in_description in varchar2
,in_uom in varchar2
,in_qtyrcvd in number
,in_cubercvd in number
,in_qtyrcvdgood in number
,in_cubercvdgood in number
,in_qtyrcvddmgd in number
,in_qtyorder in number
,in_weightitem in number
,in_weightqualifier char
,in_weightunitcode char
,in_volume in number
,in_uom_volume in varchar2
,in_dtlpassthruchar01 in varchar2
,in_dtlpassthruchar02 in varchar2
,in_dtlpassthruchar03 in varchar2
,in_dtlpassthruchar04 in varchar2
,in_dtlpassthruchar05 in varchar2
,in_dtlpassthruchar06 in varchar2
,in_dtlpassthruchar07 in varchar2
,in_dtlpassthruchar08 in varchar2
,in_dtlpassthruchar09 in varchar2
,in_dtlpassthruchar10 in varchar2
,in_dtlpassthruchar11 in varchar2
,in_dtlpassthruchar12 in varchar2
,in_dtlpassthruchar13 in varchar2
,in_dtlpassthruchar14 in varchar2
,in_dtlpassthruchar15 in varchar2
,in_dtlpassthruchar16 in varchar2
,in_dtlpassthruchar17 in varchar2
,in_dtlpassthruchar18 in varchar2
,in_dtlpassthruchar19 in varchar2
,in_dtlpassthruchar20 in varchar2
,in_dtlpassthruchar21 in varchar2
,in_dtlpassthruchar22 in varchar2
,in_dtlpassthruchar23 in varchar2
,in_dtlpassthruchar24 in varchar2
,in_dtlpassthruchar25 in varchar2
,in_dtlpassthruchar26 in varchar2
,in_dtlpassthruchar27 in varchar2
,in_dtlpassthruchar28 in varchar2
,in_dtlpassthruchar29 in varchar2
,in_dtlpassthruchar30 in varchar2
,in_dtlpassthruchar31 in varchar2
,in_dtlpassthruchar32 in varchar2
,in_dtlpassthruchar33 in varchar2
,in_dtlpassthruchar34 in varchar2
,in_dtlpassthruchar35 in varchar2
,in_dtlpassthruchar36 in varchar2
,in_dtlpassthruchar37 in varchar2
,in_dtlpassthruchar38 in varchar2
,in_dtlpassthruchar39 in varchar2
,in_dtlpassthruchar40 in varchar2
,in_dtlpassthruchar41 in varchar2
,in_dtlpassthruchar42 in varchar2
,in_dtlpassthruchar43 in varchar2
,in_dtlpassthruchar44 in varchar2
,in_dtlpassthruchar45 in varchar2
,in_dtlpassthruchar46 in varchar2
,in_dtlpassthruchar47 in varchar2
,in_dtlpassthruchar48 in varchar2
,in_dtlpassthruchar49 in varchar2
,in_dtlpassthruchar50 in varchar2
,in_dtlpassthruchar51 in varchar2
,in_dtlpassthruchar52 in varchar2
,in_dtlpassthruchar53 in varchar2
,in_dtlpassthruchar54 in varchar2
,in_dtlpassthruchar55 in varchar2
,in_dtlpassthruchar56 in varchar2
,in_dtlpassthruchar57 in varchar2
,in_dtlpassthruchar58 in varchar2
,in_dtlpassthruchar59 in varchar2
,in_dtlpassthruchar60 in varchar2
,in_dtlpassthrunum01 in number
,in_dtlpassthrunum02 in number
,in_dtlpassthrunum03 in number
,in_dtlpassthrunum04 in number
,in_dtlpassthrunum05 in number
,in_dtlpassthrunum06 in number
,in_dtlpassthrunum07 in number
,in_dtlpassthrunum08 in number
,in_dtlpassthrunum09 in number
,in_dtlpassthrunum10 in number
,in_dtlpassthrunum11 in number
,in_dtlpassthrunum12 in number
,in_dtlpassthrunum13 in number
,in_dtlpassthrunum14 in number
,in_dtlpassthrunum15 in number
,in_dtlpassthrunum16 in number
,in_dtlpassthrunum17 in number
,in_dtlpassthrunum18 in number
,in_dtlpassthrunum19 in number
,in_dtlpassthrunum20 in number
,in_dtlpassthrudate01 in date
,in_dtlpassthrudate02 in date
,in_dtlpassthrudate03 in date
,in_dtlpassthrudate04 in date
,in_dtlpassthrudoll01 in number
,in_dtlpassthrudoll02 in number
,in_qtyonhold in number
,in_qtyrcvd_invstatus in varchar2
,in_serialnumber in varchar2
,in_useritem1 in varchar2
,in_useritem2 in varchar2
,in_useritem3 in varchar2
,in_orig_line_number in number
,in_unload_date in date
,in_condition in varchar2
,in_invclass in varchar2
,in_manufacturedate in date
,in_invstatus in varchar2
,in_cubercvddmgd in number
,in_seq in number
,out_errorno in out number
,out_msg in out varchar2
) is
errorno integer;

begin

insert into import_944_detail
(importfileid
,custid
,reference
,orderid
,shipid
,item
,lotnumber
,line_number
,upc
,description
,uom
,qtyrcvd
,cubercvd
,qtyrcvdgood
,cubercvdgood
,qtyrcvddmgd
,qtyorder
,weightitem
,weightqualifier
,weightunitcode
,volume
,uom_volume
,dtlpassthruchar01
,dtlpassthruchar02
,dtlpassthruchar03
,dtlpassthruchar04
,dtlpassthruchar05
,dtlpassthruchar06
,dtlpassthruchar07
,dtlpassthruchar08
,dtlpassthruchar09
,dtlpassthruchar10
,dtlpassthruchar11
,dtlpassthruchar12
,dtlpassthruchar13
,dtlpassthruchar14
,dtlpassthruchar15
,dtlpassthruchar16
,dtlpassthruchar17
,dtlpassthruchar18
,dtlpassthruchar19
,dtlpassthruchar20
,dtlpassthruchar21
,dtlpassthruchar22
,dtlpassthruchar23
,dtlpassthruchar24
,dtlpassthruchar25
,dtlpassthruchar26
,dtlpassthruchar27
,dtlpassthruchar28
,dtlpassthruchar29
,dtlpassthruchar30
,dtlpassthruchar31
,dtlpassthruchar32
,dtlpassthruchar33
,dtlpassthruchar34
,dtlpassthruchar35
,dtlpassthruchar36
,dtlpassthruchar37
,dtlpassthruchar38
,dtlpassthruchar39
,dtlpassthruchar40
,dtlpassthruchar41
,dtlpassthruchar42
,dtlpassthruchar43
,dtlpassthruchar44
,dtlpassthruchar45
,dtlpassthruchar46
,dtlpassthruchar47
,dtlpassthruchar48
,dtlpassthruchar49
,dtlpassthruchar50
,dtlpassthruchar51
,dtlpassthruchar52
,dtlpassthruchar53
,dtlpassthruchar54
,dtlpassthruchar55
,dtlpassthruchar56
,dtlpassthruchar57
,dtlpassthruchar58
,dtlpassthruchar59
,dtlpassthruchar60
,dtlpassthrunum01
,dtlpassthrunum02
,dtlpassthrunum03
,dtlpassthrunum04
,dtlpassthrunum05
,dtlpassthrunum06
,dtlpassthrunum07
,dtlpassthrunum08
,dtlpassthrunum09
,dtlpassthrunum10
,dtlpassthrunum11
,dtlpassthrunum12
,dtlpassthrunum13
,dtlpassthrunum14
,dtlpassthrunum15
,dtlpassthrunum16
,dtlpassthrunum17
,dtlpassthrunum18
,dtlpassthrunum19
,dtlpassthrunum20
,dtlpassthrudate01
,dtlpassthrudate02
,dtlpassthrudate03
,dtlpassthrudate04
,dtlpassthrudoll01
,dtlpassthrudoll02
,qtyonhold
,qtyrcvd_invstatus
,serialnumber
,useritem1
,useritem2
,useritem3
,orig_line_number
,unload_date
,condition
,invclass
,manufacturedate
,invstatus
,cubercvddmgd
,seq
,created
) values
(upper(in_importfileid)
,in_custid
,in_reference
,in_orderid
,in_shipid
,in_item
,in_lotnumber
,in_line_number
,in_upc
,in_description
,in_uom
,in_qtyrcvd
,in_cubercvd
,in_qtyrcvdgood
,in_cubercvdgood
,in_qtyrcvddmgd
,in_qtyorder
,in_weightitem
,in_weightqualifier
,in_weightunitcode
,in_volume
,in_uom_volume
,in_dtlpassthruchar01
,in_dtlpassthruchar02
,in_dtlpassthruchar03
,in_dtlpassthruchar04
,in_dtlpassthruchar05
,in_dtlpassthruchar06
,in_dtlpassthruchar07
,in_dtlpassthruchar08
,in_dtlpassthruchar09
,in_dtlpassthruchar10
,in_dtlpassthruchar11
,in_dtlpassthruchar12
,in_dtlpassthruchar13
,in_dtlpassthruchar14
,in_dtlpassthruchar15
,in_dtlpassthruchar16
,in_dtlpassthruchar17
,in_dtlpassthruchar18
,in_dtlpassthruchar19
,in_dtlpassthruchar20
,in_dtlpassthruchar21
,in_dtlpassthruchar22
,in_dtlpassthruchar23
,in_dtlpassthruchar24
,in_dtlpassthruchar25
,in_dtlpassthruchar26
,in_dtlpassthruchar27
,in_dtlpassthruchar28
,in_dtlpassthruchar29
,in_dtlpassthruchar30
,in_dtlpassthruchar31
,in_dtlpassthruchar32
,in_dtlpassthruchar33
,in_dtlpassthruchar34
,in_dtlpassthruchar35
,in_dtlpassthruchar36
,in_dtlpassthruchar37
,in_dtlpassthruchar38
,in_dtlpassthruchar39
,in_dtlpassthruchar40
,in_dtlpassthruchar41
,in_dtlpassthruchar42
,in_dtlpassthruchar43
,in_dtlpassthruchar44
,in_dtlpassthruchar45
,in_dtlpassthruchar46
,in_dtlpassthruchar47
,in_dtlpassthruchar48
,in_dtlpassthruchar49
,in_dtlpassthruchar50
,in_dtlpassthruchar51
,in_dtlpassthruchar52
,in_dtlpassthruchar53
,in_dtlpassthruchar54
,in_dtlpassthruchar55
,in_dtlpassthruchar56
,in_dtlpassthruchar57
,in_dtlpassthruchar58
,in_dtlpassthruchar59
,in_dtlpassthruchar60
,in_dtlpassthrunum01
,in_dtlpassthrunum02
,in_dtlpassthrunum03
,in_dtlpassthrunum04
,in_dtlpassthrunum05
,in_dtlpassthrunum06
,in_dtlpassthrunum07
,in_dtlpassthrunum08
,in_dtlpassthrunum09
,in_dtlpassthrunum10
,in_dtlpassthrunum11
,in_dtlpassthrunum12
,in_dtlpassthrunum13
,in_dtlpassthrunum14
,in_dtlpassthrunum15
,in_dtlpassthrunum16
,in_dtlpassthrunum17
,in_dtlpassthrunum18
,in_dtlpassthrunum19
,in_dtlpassthrunum20
,in_dtlpassthrudate01
,in_dtlpassthrudate02
,in_dtlpassthrudate03
,in_dtlpassthrudate04
,in_dtlpassthrudoll01
,in_dtlpassthrudoll02
,in_qtyonhold
,in_qtyrcvd_invstatus
,in_serialnumber
,in_useritem1
,in_useritem2
,in_useritem3
,in_orig_line_number
,in_unload_date
,in_condition
,nvl(in_invclass,'RG')
,in_manufacturedate
,nvl(in_invstatus, 'AV')
,in_cubercvddmgd
,in_seq
,systimestamp
);
out_msg := 'OKAY';

exception when others then
  out_msg := 'z44d ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_944_detail;

procedure end_of_import_4pl_944
(in_custid IN varchar2
,in_importfileid IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2
) is

strDebugYN char(1);

cursor curOHByOrderid(in_orderid number, in_shipid number) is
   select * from orderhdr
      where orderid = in_orderid
        and shipid = in_shipid;

cursor curOHByReference(in_custid varchar2, in_reference varchar2) is
   select * from orderhdr
      where custid = in_custid
        and reference = in_reference;
OH curOHByOrderid%rowtype;

cursor curPlate(in_facility varchar2, in_custid varchar2, in_item varchar2, in_lotnumber varchar2) is
   select *
      from plate
      where facility = in_facility
        and custid = in_custid
        and item = in_item
        and nvl(lotnumber,'(none)') = nvl(in_lotnumber,'(none)')
        and invstatus = 'AV'
        and inventoryclass = 'RG'
        and quantity > nvl(qtytasked,0)
      order by creationdate;
PL curPlate%rowtype;

qtyNeeded integer;
l_parentlpid shippingplate.parentlpid%type;
l_lpid shippingplate.parentlpid%type;
dBaseUOM varchar2(3);
dCube custitem.cube%type;
l_msg varchar2(255);
spQty integer;
out_filename varchar2(255);
doorLoc varchar(10);
out_orderid number(9);
out_loadno number(7);
out_errmsg varchar2(255);
crbResult integer;
procedure debugmsg(in_text varchar2) is

cntChar integer;
strMsg varchar2(255);
begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;

while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;


procedure order_msg(in_msgtype varchar2, in_facility varchar2) is
strMsg appmsgs.msgtext%type;
begin
  zms.log_autonomous_msg(IMP_USERID, in_facility, rtrim(in_custid),
    out_msg || ' file ' || out_filename, nvl(in_msgtype,'E'), IMP_USERID, strMsg);

end order_msg;

procedure validate_detail(OH curOHByOrderid%rowtype, in_seq integer)
is
cntRows integer;


begin
  debugmsg('validate detail');
  for DTL in (select distinct item
                from import_944_detail
                where importfileid = (upper(in_importfileid))
                  and seq = in_seq)  loop
--     debugmsg('item ' || DTL.item );
     select count(1) into cntRows
        from custitem
        where custid = OH.custid
          and item = DTL.item;
     if cntRows =0 then
           out_msg := '4PL 944 unkown item ' || OH.custid || ' ' || DTL.item || ' skipping order ' || OH.orderid || '-' || OH.shipid;
           order_msg('E',null);
           return;
     end if;
  end loop; /* for DTL */
  out_msg := 'OKAY';
end validate_detail;

begin
if out_errorno = -12345 then
   strdebugyn := 'Y';
   debugmsg('debug is on');
else
   strdebugyn := 'N';
end if;
out_errorno := 0;
out_msg := '';
out_filename := substr(in_importfileid, instr(in_importfileid, '\', -1)+1);

for HDR in (select * from import_944_header where importfileid = upper(in_importfileid)) loop
   debugmsg('seq is ' || HDR.seq);
   if HDR.orderid is not null then
      debugmsg('by order ' || HDR.orderid ||' ' || HDR.shipid);
      open curOHByOrderid(HDR.orderid, HDR.shipid);
      fetch curOHByOrderid into OH;
      if curOHByOrderid%notfound then
          out_msg := '4PL 944 order not found ' || HDR.orderid || ' ' || HDR.shipid;
          order_msg('E', null);
          close curOHByOrderid;
          goto continue_orderid_loop;
      end if;
      close curOHByOrderid;
   else
      debugmsg('by reference ' || HDR.custid || ' ' || HDR.reference);
      open curOHByReference(HDR.custid, HDR.reference);
      fetch curOHByReference into OH;
      if curOHByReference%notfound then
          out_msg := '4PL 944 order not found ' || HDR.custid || ' ' || HDR.reference;
          order_msg('E',null);
          close curOHByreference;
          goto continue_orderid_loop;
      end if;
      close curOHByReference;
   end if;
   debugmsg('order found ' || OH.orderid);
   if OH.orderstatus > '1' then
      out_msg := '4PL 944 invalid order status  ' || OH.orderstatus || ' ' ||  HDR.orderid || ' ' || HDR.shipid;
      order_msg('E',null);
      goto continue_orderid_loop;
   end if;
   if OH.ordertype <> 'R' then
      out_msg := '4PL 944 invalid order type  ' || OH.ordertype || ' ' ||  HDR.orderid || ' ' || HDR.shipid;
      order_msg('E',null);
      goto continue_orderid_loop;
   end if;
   validate_detail(OH, HDR.seq);
   if out_msg != 'OKAY' then
     goto continue_orderid_loop;
   end if;
   /* create a door location for this load. will be delete after close */
   doorLoc := 'DR' || HDR.seq;
   update orderhdr set billoflading = nvl(HDR.bill_of_lading, billoflading)
      where orderid = OH.orderid
        and shipid = OH.shipid;
   OH.billoflading := nvl(HDR.bill_of_lading, OH.billoflading);
   insert into location
      (locid, facility, loctype, storagetype, section, checkdigit, status,
       equipprof, velocity, mixeditemsok, mixedlotsok, mixeduomok, lastuser,
       lastupdate, unitofstorage, descr, mixedcustsok)
   values
      (doorLoc, OH.tofacility, 'DOR', 'NA','1', '10', 'E',
       'AL', 'B', 'Y', 'Y', 'Y', IMP_USERID,
       sysdate, 'N/A', 'Door', 'Y');
   commit;
   for DTL in (select *
                 from import_944_detail
                 where importfileid = (upper(in_importfileid))
                   and seq = HDR.seq)  loop
      zrod.receive_item(OH.tofacility,OH.orderid,OH.shipid,OH.custid,OH.po,OH.reference,
         OH.billoflading,OH.shipper,HDR.carrier,HDR.trailer,HDR.seal,doorLoc,HDR.receipt_date,
         DTL.item,DTL.item,DTL.lotnumber,DTL.qtyrcvd,DTL.uom,OH.custid, -- location is customer
         DTL.invstatus,DTL.invclass,'FL',DTL.serialnumber,DTL.useritem1,DTL.useritem2,DTL.useritem3,
         null,null,null,IMP_USERID,null,null,null,null,out_orderid,out_loadno,out_errmsg);
      if out_errmsg <> 'OKAY' then
         out_msg := '4PL 944 Error creating inventory  ' || HDR.orderid || ' ' || HDR.shipid || ' ' || out_errmsg;
         order_msg('E',null);
         goto delete_loc;
      end if;
   end loop;
   /* close it */
   zrod.close_receipt(OH.tofacility, out_loadno, IMP_USERID, null, out_errmsg);
   if out_errmsg <> 'OKAY' then
      out_msg := '4PL 944 Error closing load  ' || HDR.orderid || ' ' || HDR.shipid || ' ' || out_errmsg;
      order_msg('E',null);
      goto delete_loc;
   end if;
   crbResult := zbillreceipt.calc_receipt_bills(out_loadno, IMP_USERID, out_errmsg);
   zld.check_for_interface(out_loadno, null, null, OH.tofacility,
          'REGORDTYPES', 'REGI9GRFMT', 'RETORDTYPES','RETI44RNFMT', IMP_USERID, out_errmsg);
<< delete_loc >>
   begin
      delete location
         where facility = OH.tofacility
           and locid = doorLoc;
   exception when others then
      null;
   end;
   commit;

<< continue_orderid_loop >>
  null;
end loop;

out_msg := 'End of import 4pl 944: ' ||in_custid || ' ' || in_importfileid || ' '
  || in_userid;
order_msg('I', oh.fromfacility);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimeoi ' || sqlerrm;
  out_errorno := sqlcode;
end end_of_import_4pl_944;

procedure import_4pl_846_header
(in_importfileid        in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
) is

begin
out_errorno := 0;
out_msg := 'OKAY';

insert into import_846_header
(importfileid
,facility
,custid
,created
)
values
(upper(in_importfileid)
,in_facility
,in_custid
,systimestamp
);

exception when others then
  out_msg := 'z46h ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_846_header;

procedure import_4pl_846_detail
(in_importfileid        in varchar2
,in_item                in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
) is

begin
out_errorno := 0;
out_msg := 'OKAY';

insert into import_846_detail
(importfileid
,item
,facility
,custid
,created
)
values
(upper(in_importfileid)
,in_item
,in_facility
,in_custid
,systimestamp
);

exception when others then
  out_msg := 'z46d ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_846_detail;

procedure import_4pl_846_quantity
(in_importfileid        in varchar2
,in_invstatus           in varchar2
,in_uom                 in varchar2
,in_quantity            in varchar2
,in_facility            in varchar2
,in_custid              in varchar2
,in_item                in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
) is

begin
out_errorno := 0;
out_msg := 'OKAY';

insert into import_846_quantity
(importfileid
,invstatus
,uom
,quantity
,facility
,custid
,item
,created
)
values
(upper(in_importfileid)
,in_invstatus
,in_uom
,in_quantity
,in_facility
,in_custid
,in_item
,systimestamp
);

exception when others then
  out_msg := 'z46q ' || sqlerrm;
  out_errorno := sqlcode;
end import_4pl_846_quantity;

procedure end_of_import_4pl_846
(in_importfileid        in varchar2
,in_custid              in varchar2
,in_userid              in varchar2
,out_errorno            in out number
,out_msg                in out varchar2
) is

  cursor c_rec(in_importfileid varchar2) is
    select invstatus,
           uom,
           quantity,
           facility,
           custid,
           item
      from import_846_quantity
     where importfileid = upper(in_importfileid);
  crec c_rec%rowtype;

  cursor c_cust(in_custid varchar2) is
    select custid, paperbased
      from customer
     where custid = in_custid;
  cu c_cust%rowtype;

  cursor c_item(in_custid varchar2, in_item varchar2) is
    select item, baseuom
      from custitem
     where custid = in_custid
       and item = in_item;
  it c_item%rowtype;

    cursor c_plate(in_custid varchar2, in_item varchar2, in_facility varchar2) is
    select *
      from plate
     where custid = in_custid
       and item = in_item
       and facility = in_facility
  order by creationdate;
  pl c_plate%rowtype;

  strdebugyn char(1);
  out_filename varchar2(255);
  out_adjrowid1 rowid;
  out_adjrowid2 rowid;
  crec_cnt number;
  l_quantity plate.quantity%type;
  l_invstatus inventorystatus.code%type;
  strMsg appmsgs.msgtext%type;

procedure debug_msg(in_text varchar2)
is
  cntchar integer;
begin
  if strdebugyn <>'Y' then
    return;
  end if;

  cntchar := 1;
  while (cntchar * 60) < (length(in_text)+60)
  loop
    zut.prt(substr(in_text,((cntchar-1)*60)+1,60));
    cntchar := cntchar + 1;
  end loop;
exception when others then
    null;
end debug_msg;

procedure write_msg(in_msgtype varchar2, in_facility varchar2) is
strMsg appmsgs.msgtext%type;
begin
  out_msg := out_msg ||' - file: <'||out_filename||'>';
  zms.log_autonomous_msg(IMP_USERID, in_facility, rtrim(in_custid), out_msg, nvl(in_msgtype,'E'), IMP_USERID, strMsg);
  debug_msg(out_msg);
end write_msg;

begin
  if out_errorno = -12345 then
    strdebugyn := 'Y';
    debug_msg('debug is on');
  else
     strdebugyn := 'N';
  end if;

  out_errorno := 0;
  out_msg := 'OKAY';
  crec_cnt := 0;
  out_filename := substr(in_importfileid, instr(in_importfileid, chr(92), -1)+1); -- chr(92)='\'

  if rtrim(in_importfileid) is null then
    out_msg :=  '4PL 846 Missing importfile ID';
    write_msg('E', null);
    return;
  end if;

  open c_rec(in_importfileid);
  loop
      fetch c_rec into crec;
      exit when c_rec%notfound;
      crec_cnt := crec_cnt + 1;

      open c_cust(crec.custid);
      fetch c_cust into cu;
      close c_cust;
      if cu.custid is null then
        out_msg := 'Invalid customer: '||crec.custid;
        write_msg('E',null);
        goto continue_crec_loop;
      end if;
      if nvl(cu.paperbased, 'N') = 'N' then
        out_msg := '4PL 846 Not an aggregate inventory customer';
        write_msg('E',null);
        goto continue_crec_loop;
      end if;

      open c_item(crec.custid, crec.item);
      fetch c_item into it;
      close c_item;
      if it.item is null then
        out_msg := '4PL 846 Invalid Item: '||crec.item;
        write_msg('E',null);
        goto continue_crec_loop;
      end if;

      open c_plate(crec.custid, crec.item, crec.facility);
      fetch c_plate into pl;
      close c_plate;
      if pl.lpid is null then
        out_msg := '4PL 846 No plate found for custid/item: '||crec.custid||'/'||crec.item;
        write_msg('E',null);
        goto continue_crec_loop;
      end if;

      -- Decode inv status (17 = Available 74 = Damaged QH = On Hold)
      select decode(crec.invstatus, '17','AV', '74','DM', 'QH','OH', null)
        into l_invstatus
        from dual;
      if l_invstatus is null then
        out_msg := '4PL 846 Inventory status not supported - item/custid/invstatus: '||
                    crec.item||'/'||crec.custid||'/'||crec.invstatus;
        write_msg('E',null);
        goto continue_crec_loop;
      end if;

      if pl.unitofmeasure != it.baseuom then
        l_quantity := zlbl.uom_qty_conv(crec.custid, crec.item, crec.quantity, crec.uom, pl.unitofmeasure);
        debug_msg('importedQty/convImportedQty/origPlateQty: '||
                  crec.quantity||crec.uom||'/'|| l_quantity||pl.unitofmeasure||'/'|| pl.quantity||pl.unitofmeasure);
      else
        l_quantity := zlbl.uom_qty_conv(crec.custid, crec.item, crec.quantity, crec.uom, it.baseuom);
        debug_msg('importedQty/convImportedQty/origPlateQty: '||
                  crec.quantity||crec.uom||'/'|| l_quantity||it.baseuom||'/'|| pl.quantity||pl.unitofmeasure);
      end if;

      if l_quantity < 0 then
         out_msg := '4PL 846 Quantity to adjust less than zero - item/custid/plate/qty/uom: '||
                     crec.item||'/'||crec.custid||'/'||pl.lpid||'/'||crec.quantity||'/'||crec.uom;
          write_msg('E',null);
        goto continue_crec_loop;
      end if;

      zia.inventory_adjustment(
       in_lpid                    => pl.lpid
      ,in_custid                  => pl.custid
      ,in_item                    => pl.item
      ,in_inventoryclass          => pl.inventoryclass
      ,in_invstatus               => l_invstatus
      ,in_lotnumber               => pl.lotnumber
      ,in_serialnumber            => pl.serialnumber
      ,in_useritem1               => pl.useritem1
      ,in_useritem2               => pl.useritem2
      ,in_useritem3               => pl.useritem3
      ,in_location                => pl.location
      ,in_expirationdate          => pl.expirationdate
      ,in_qty                     => l_quantity
      ,in_orig_custid             => pl.custid
      ,in_orig_item               => pl.item
      ,in_orig_inventoryclass     => pl.inventoryclass
      ,in_orig_invstatus          => pl.invstatus
      ,in_orig_lotnumber          => pl.lotnumber
      ,in_orig_serialnumber       => pl.serialnumber
      ,in_orig_useritem1          => pl.useritem1
      ,in_orig_useritem2          => pl.useritem2
      ,in_orig_useritem3          => pl.useritem3
      ,in_orig_location           => pl.location
      ,in_orig_expirationdate     => pl.expirationdate
      ,in_orig_qty                => pl.quantity
      ,in_facility                => pl.facility
      ,in_adjreason               => null
      ,in_userid                  => IMP_USERID
      ,in_tasktype                => null
      ,in_weight                  => null
      ,in_orig_weight             => null
      ,in_mfgdate                 => pl.manufacturedate
      ,in_orig_mfgdate            => pl.manufacturedate
      ,in_anvdate                 => pl.anvdate
      ,in_orig_anvdate            => pl.anvdate
      ,out_adjrowid1              => out_adjrowid1
      ,out_adjrowid2              => out_adjrowid2
      ,out_errorno                => out_errorno
      ,out_msg                    => out_msg
      ,in_custreference           => null
      ,in_tasks_ok                => null);
      debug_msg('zia.inventory_adjustment: '||out_msg||' '||out_errorno);

      if substr(out_msg,1,4) != 'OKAY' then
          out_msg := '4PL 846 item/custid/plate/qty/invstatus:'||
                     ' <'||crec.item||'/'||crec.custid||'/'||pl.lpid||'/'||l_quantity||'/'||crec.invstatus||'> '||
                      out_msg;
          write_msg('E',null);
          goto continue_crec_loop;
      end if;
      << continue_crec_loop >>
      null;
  end loop;
  close c_rec;

  out_msg := 'End of import 4pl 846:' || in_custid ||' '|| in_importfileid || ' ' || in_userid;
  write_msg('I',null);

exception when others then
  out_msg := '4PL 846 zimeoi '||sqlerrm;
  out_errorno := sqlcode;
end end_of_import_4pl_846;

end zimportproc4pl;
/
show error package body zimportproc4pl;
exit;

