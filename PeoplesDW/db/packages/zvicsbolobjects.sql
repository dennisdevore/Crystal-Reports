drop table vicsbol;

create table vicsbol
(sessionid           number,
 ld_loadno           number(7),
 ld_trailer          varchar2(12),
 ld_seal             varchar2(15),
 ld_prono            varchar2(20),
 ld_comment          varchar2(4000),
 ld_bolcomment       varchar2(4000),
 ld_shiptems         varchar2(3),
 ld_billoflading     varchar2(40),
 ld_ldpassthruchar01 varchar2(255),
 ld_ldpassthruchar02 varchar2(255),
 ld_ldpassthruchar03 varchar2(255),
 ld_ldpassthruchar36 varchar2(255),
 ld_ldpassthruchar40 varchar2(255),
 oh_orderid          number(9),
 oh_shipid           number(2),
 oh_billoflading     varchar2(40),
 oh_reference        varchar2(20),
 oh_custid           varchar2(10),
 oh_hdrpassthruchar01 varchar2(255),
 oh_hdrpassthruchar06 varchar2(255),
 oh_hdrpassthruchar28 varchar2(255),
 oh_hdrpassthruchar36 varchar2(255),
 oh_bolcomment       varchar2(4000),
 cu_name             varchar2(40),
 cu_addr1            varchar2(40),
 cu_addr2            varchar2(40),
 cu_city             varchar2(30),
 cu_state            varchar2(5),
 cu_postalcode       varchar2(12),
 cu_country          varchar2(3),
 facility            varchar2(3),
 fac_name            varchar2(40),
 fac_addr1           varchar2(40),
 fac_addr2           varchar2(40),
 fac_city            varchar2(30),
 fac_state           varchar2(5),
 fac_postalcode      varchar2(12),
 fac_country         varchar2(3),
 cn_consignee        varchar2(40),
 cn_name             varchar2(40),
 cn_addr1            varchar2(40),
 cn_addr2            varchar2(40),
 cn_addr2_notnull    varchar2(40),
 cn_name_addr1_addr2 varchar2(167),
 cn_city             varchar2(30),
 cn_state            varchar2(5),
 cn_postalcode       varchar2(12),
 cn_country          varchar2(3),
 carrier             varchar2(10),
 car_name            varchar2(40),
 car_scac            varchar2(4),
 car_contact         varchar2(40),
 cr_name             varchar2(40),
 cr_addr1            varchar2(40),
 cr_addr2            varchar2(40),
 cr_city             varchar2(30),
 cr_state            varchar2(5),
 cr_postalcode       varchar2(12),
 cr_country          varchar2(3),
 order_count         number(9),
 order_count_nmfc    number(9),
 po_count            number(9),
 carrier_count       number(9),
 load_order_count    number(9),
 load_carrier_count  number(9),
 load_bol_count      number(9),
 prono_count         number(9),
 tf_count            number(9),
 print_status        varchar2(12),
 autogen             varchar2(1),
 lastupdate          date
);

create index vicsbol_sessionid_idx
 on vicsbol(sessionid);

create index vicsbol_lastupdate_idx
 on vicsbol(lastupdate);

create or replace package vicsbolpkg
as type bol_type is ref cursor return vicsbol%rowtype;

FUNCTION outpallets_orderid
(in_orderid in number
,in_shipid in number
) return number;

FUNCTION outpalletsweight_orderid
(in_orderid in number
,in_shipid in number
) return number;

FUNCTION outpallets_shipto
(in_loadno in number
,in_cn_name_addr1_addr2 in varchar2
,in_nmfc in varchar2
) return number;

FUNCTION outpalletsweight_shipto
(in_loadno in number
,in_cn_name_addr1_addr2 in varchar2
,in_nmfc in varchar2
) return number;

FUNCTION outpallets_loadno
(in_loadno in number
) return number;

FUNCTION outpalletsweight_loadno
(in_loadno in number
) return number;

FUNCTION handling_units
   (in_orderid  in number,
    in_shipid   in number)
return number;

FUNCTION handling_units_nmfc
   (in_orderid  in number,
    in_shipid   in number,
    in_nmfc     in varchar2)
return number;

FUNCTION handling_units_shipto
   (in_loadno in number,
    in_cn_name_addr1_addr2 in varchar2)
return number;

FUNCTION handling_units_loadno
   (in_loadno in number)
return number;

FUNCTION cn_consignee
   (in_orderid  in number,
    in_shipid   in number)
return varchar2;

FUNCTION cn_name
   (in_orderid  in number,
    in_shipid   in number)
return varchar2;

FUNCTION cn_addr1
   (in_orderid  in number,
    in_shipid   in number)
return varchar2;

FUNCTION cn_addr2
   (in_orderid  in number,
    in_shipid   in number)
return varchar2;

FUNCTION cn_name_addr1_addr2
   (in_orderid  in number,
    in_shipid   in number)
return varchar2;

end vicsbolpkg;
/

CREATE OR REPLACE VIEW VICS_BOL_ORDER_INFO
(ORDERID, SHIPID, LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2,
 QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP, WEIGHTSHIP,
 CUBESHIP, REFERENCE, BILLOFLADING, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR09, PO, CARRIER_PHONE,
 ORDER_CARTONS, PLTSHIP, CTNSHIP, CASESHIP, PCSSHIP, OUTPALLETS, OUTPALLETSWEIGHT,
 HANDLING_UNITS)
AS
select
orderid,
shipid,
loadno,
stopno,
shipno,
vicsbolpkg.cn_name(orderid, shipid) cn_name,
vicsbolpkg.cn_addr1(orderid, shipid) cn_addr1,
vicsbolpkg.cn_addr2(orderid, shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(orderid, shipid) cn_name_addr1_addr2,
qtyorder,
weightorder,
cubeorder,
qtypick,
weightpick,
cubepick,
qtyship,
weightship,
cubeship,
reference,
billoflading,
hdrpassthruchar01,
hdrpassthruchar09,
po,
carrier_phone,
ordercheckview_cartons(orderid, shipid) order_cartons,
plt_ship,
ctn_ship,
cases_ship,
pcs_ship,
nvl(vicsbolpkg.outpallets_orderid(orderid,shipid),0) outpallets,
nvl(vicsbolpkg.outpalletsweight_orderid(orderid,shipid),0) outpalletsweight,
nvl(vicsbolpkg.handling_units(orderid,shipid),0) handling_units
from(
select
OH.orderid,
OH.shipid,
OH.loadno,
OH.stopno,
OH.shipno,
sum(OD.qtyorder) QTYORDER,
sum(OD.weightorder) WEIGHTORDER,
sum(OD.cubeorder) CUBEORDER,
sum(OD.qtypick) QTYPICK,
sum(OD.weightpick) WEIGHTPICK,
sum(OD.cubepick) CUBEPICK,
sum(OD.qtyship) QTYSHIP,
sum(OD.weightship) WEIGHTSHIP,
sum(OD.cubeship) CUBESHIP,
OH.reference,
decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
       'Y', nvl(OH.hdrpassthruchar27, OH.billoflading),
       'L', nvl(OH.hdrpassthruchar27, OH.billoflading),
       OH.billoflading) BILLOFLADING,
OH.hdrpassthruchar01,
OH.hdrpassthruchar09,
OH.po,
CA.phone CARRIER_PHONE,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)) PLT_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)) CTN_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)) CASES_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)) PCS_SHIP
from orderhdr OH, orderdtl OD, loadstopship LSS, carrier CA
where OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OH.loadno = LSS.loadno (+)
  and OH.stopno = LSS.stopno (+)
  and OH.shipno = LSS.shipno (+)
  and LSS.carrier = CA.carrier (+)
group by OH.orderid,
         OH.shipid,
         OH.loadno,
         OH.stopno,
         OH.shipno,
         OH.reference,
         decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
                'Y', nvl(OH.hdrpassthruchar27, OH.billoflading),
                'L', nvl(OH.hdrpassthruchar27, OH.billoflading),
                OH.billoflading),
         OH.hdrpassthruchar01,
         OH.hdrpassthruchar09,
         OH.po,
         CA.phone);

CREATE OR REPLACE VIEW VICS_BOL_ORDER_INFO_NMFC
(ORDERID, SHIPID, LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2,
 QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP, YARDSSHIP, CUBESHIP,
 REFERENCE, BILLOFLADING, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR09, PO, CARRIER_PHONE, ORDER_CARTONS,
 PLTSHIP, CTNSHIP, CASESHIP, PCSSHIP, OUTPALLETS, OUTPALLETSWEIGHT, NMFC, NMFC_CLASS, DESCR,
 BOLTSHIP, WEIGHTSHIP)
AS
select
OH.orderid,
OH.shipid,
OH.loadno,
OH.stopno,
OH.shipno,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
sum(OD.qtyorder) QTYORDER,
sum(OD.weightorder) WEIGHTORDER,
sum(OD.cubeorder) CUBEORDER,
sum(OD.qtypick) QTYPICK,
sum(OD.weightpick) WEIGHTPICK,
sum(OD.cubepick) CUBEPICK,
sum(OD.qtyship) QTYSHIP,
sum(OD.weightship) YARDSSHIP,
sum(OD.cubeship) CUBESHIP,
OH.reference,
decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
       'Y', nvl(OH.hdrpassthruchar27, OH.billoflading),
       'L', nvl(OH.hdrpassthruchar27, OH.billoflading),
       OH.billoflading) BILLOFLADING,
OH.hdrpassthruchar01,
OH.hdrpassthruchar09,
OH.po,
CA.phone CARRIER_PHONE,
ordercheckview_cartons(OH.orderid, OH.shipid) ORDER_CARTONS,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)) PLT_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)) CTN_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)) CASES_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)) PCS_SHIP,
nvl(vicsbolpkg.outpallets_orderid(OH.orderid, OH.shipid),0) outpallets,
nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid, OH.shipid),0) outpalletsweight,
CI.nmfc,
NCC.class NMFC_CLASS,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Bolt'),'BT')),0)) BOLT_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,CI.baseuom)*CI.itmpassthrunum01,0)) WEIGHTSHIP
from orderhdr OH, orderdtl OD, loadstopship LSS, carrier CA, custitem CI, nmfclasscodes NCC
where OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
  and OH.loadno = LSS.loadno (+)
  and OH.stopno = LSS.stopno (+)
  and OH.shipno = LSS.shipno (+)
  and LSS.carrier = CA.carrier (+)
group by OH.orderid,
         OH.shipid,
         OH.loadno,
         OH.stopno,
         OH.shipno,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         OH.reference,
         decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
                'Y', nvl(OH.hdrpassthruchar27, OH.billoflading),
                'L', nvl(OH.hdrpassthruchar27, OH.billoflading),
                OH.billoflading),
         OH.hdrpassthruchar01,
         OH.hdrpassthruchar09,
         OH.po,
         CA.phone,
         CI.nmfc,
         NCC.class,
         NCC.descr;

CREATE OR REPLACE VIEW VICS_BOL_CARRIER_INFO
(LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2, NMFC, NMFC_CLASS,
 DESCR, HAZARDOUS, BOLNUMBER, QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK,
 QTYSHIP, WEIGHTSHIP, CUBESHIP, PLTSHIP, CTNSHIP, CASESHIP, PCSSHIP, OUTPALLETS, OUTPALLETSWEIGHT,
 UOM, ORDER_CARTONS, HANDLING_UNITS, HANDLING_UNITS_SHIPTO)
AS
select loadno,
stopno,
shipno,
cn_name,
cn_addr1,
cn_addr2,
cn_name_addr1_addr2,
nmfc,
nmfc_class,
descr,
hazardous,
bolnumber,
sum(qtyorder),
sum(weightorder),
sum(cubeorder),
sum(qtypick),
sum(weightpick),
sum(cubepick),
sum(qtyship),
sum(weightship),
sum(cubeship),
sum(pltship),
sum(ctnship),
sum(caseship),
sum(pcsship),
nvl(vicsbolpkg.outpallets_shipto(loadno,cn_name_addr1_addr2,nmfc),0),
nvl(vicsbolpkg.outpalletsweight_shipto(loadno,cn_name_addr1_addr2,nmfc),0),
uom,
sum(order_cartons),
sum(handling_units),
sum(handling_units)
from(
select
OH.loadno,
OH.stopno,
OH.shipno,
OH.orderid,
OH.shipid,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
CI.nmfc,
NCC.class NMFC_CLASS,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
decode(CI.hazardous,'Y','X','') HAZARDOUS,
decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
       'Y', nvl(OH.hdrpassthruchar27, LD.billoflading),
       'L', nvl(OH.hdrpassthruchar27, LD.billoflading),
       LD.billoflading) BOLNUMBER,
sum(OD.qtyorder) QTYORDER,
sum(OD.weightorder) WEIGHTORDER,
sum(OD.cubeorder) CUBEORDER,
sum(OD.qtypick) QTYPICK,
sum(OD.weightpick) WEIGHTPICK,
sum(OD.cubepick) CUBEPICK,
sum(OD.qtyship) QTYSHIP,
sum(OD.weightship) WEIGHTSHIP,
sum(OD.cubeship) CUBESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)) PLTSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)) CTNSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)) CASESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)) PCSSHIP,
min(OD.uom) UOM,
ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc) ORDER_CARTONS,
vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc) HANDLING_UNITS
from orderhdr OH, orderdtl OD, custitem CI, nmfclasscodes NCC, loads LD
where OD.orderid = OH.orderid
  and OD.shipid = OH.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
  and OH.loadno = LD.loadno
group by OH.loadno,
         OH.stopno,
         OH.shipno,
         OH.orderid,
         OH.shipid,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid),
         CI.nmfc,
         NCC.class,
         NCC.descr,
         decode(CI.hazardous,'Y','X',''),
         decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
                'Y', nvl(OH.hdrpassthruchar27, LD.billoflading),
                'L', nvl(OH.hdrpassthruchar27, LD.billoflading),
                LD.billoflading),
         ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc),
         vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc))
group by loadno,
stopno,
shipno,
cn_name,
cn_addr1,
cn_addr2,
cn_name_addr1_addr2,
nmfc,
nmfc_class,
descr,
hazardous,
bolnumber,
uom;

CREATE OR REPLACE VIEW VICS_BOL_CARRIER_CTN_INFO
(LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2, NMFC, NMFC_CLASS,
 DESCR, HAZARDOUS, QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP,
 WEIGHTSHIP, CUBESHIP, PLTSHIP, CTNSHIP, UOM, CARTONS, HANDLING_UNITS)
AS
select
loadno,
stopno,
shipno,
cn_name,
cn_addr1,
cn_addr2,
cn_name_addr1_addr2,
nmfc,
class,
descr,
hazardous,
sum(qtyorder),
sum(weightorder),
sum(cubeorder),
sum(qtypick),
sum(weightpick),
sum(cubepick),
sum(qtyship),
sum(weightship),
sum(cubeship),
sum(pltship),
sum(ctnship),
uom,
sum(ordercheckview_cartons(orderid, shipid)),
sum(vicsbolpkg.handling_units(orderid, shipid))
from(
select
OH.orderid,
OH.shipid,
OH.loadno,
OH.stopno,
OH.shipno,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
CI.nmfc,
NCC.class,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
decode(CI.hazardous,'Y','X','') hazardous,
sum(OD.qtyorder) qtyorder,
sum(OD.weightorder) weightorder,
sum(OD.cubeorder) cubeorder,
sum(OD.qtypick) qtypick,
sum(OD.weightpick) weightpick,
sum(OD.cubepick) cubepick,
sum(OD.qtyship) qtyship,
sum(OD.weightship) weightship,
sum(OD.cubeship) cubeship,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,nvl(zci.default_value('PALLETSUOM'),'PLT')),0)) pltship,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,nvl(zci.default_value('CARTONSUOM'),'CTN')),0)) ctnship,
OD.uom
from orderhdr OH, orderdtl OD, custitem CI, nmfclasscodes NCC
where OD.orderid = OH.orderid
  and OD.shipid = OH.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
group by OH.orderid,
         OH.shipid,
         OH.loadno,
         OH.stopno,
         OH.shipno,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         CI.nmfc,
         NCC.class,
         NCC.descr,
         decode(CI.hazardous,'Y','X',''),
         OD.uom)
group by loadno,
         stopno,
         shipno,
         cn_name,
         cn_addr1,
         cn_addr2,
         cn_name_addr1_addr2,
         nmfc,
         class,
         descr,
         hazardous,
         uom;

CREATE OR REPLACE VIEW VICS_BOL_LD_CARRIER_INFO
(LOADNO, STOPNO, SHIPNO, NMFC, NMFC_CLASS, DESCR, HAZARDOUS, QTYORDER, WEIGHTORDER, CUBEORDER,
 QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP, WEIGHTSHIP, CUBESHIP, PLTSHIP, CTNSHIP, CASESHIP,
 PCSSHIP, OUTPALLETS, OUTPALLETSWEIGHT, UOM, ORDER_CARTONS, HANDLING_UNITS, HANDLING_UNITS_LOADNO)
AS
select loadno,
1,
1,
nmfc,
nmfc_class,
descr,
hazardous,
sum(qtyorder),
sum(weightorder),
sum(cubeorder),
sum(qtypick),
sum(weightpick),
sum(cubepick),
sum(qtyship),
sum(weightship),
sum(cubeship),
sum(pltship),
sum(ctnship),
sum(caseship),
sum(pcsship),
nvl(vicsbolpkg.outpallets_loadno(loadno),0),
nvl(vicsbolpkg.outpalletsweight_loadno(loadno),0),
uom,
sum(order_cartons),
sum(handling_units),
nvl(vicsbolpkg.handling_units_loadno(loadno),0)
from(
select
OH.loadno,
OH.stopno,
OH.shipno,
OH.orderid,
OH.shipid,
CI.nmfc,
NCC.class NMFC_CLASS,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
decode(CI.hazardous,'Y','X','') HAZARDOUS,
decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
       'Y', nvl(OH.hdrpassthruchar27, LD.billoflading),
       'L', nvl(OH.hdrpassthruchar27, LD.billoflading),
       LD.billoflading) BOLNUMBER,
sum(OD.qtyorder) QTYORDER,
sum(OD.weightorder) WEIGHTORDER,
sum(OD.cubeorder) CUBEORDER,
sum(OD.qtypick) QTYPICK,
sum(OD.weightpick) WEIGHTPICK,
sum(OD.cubepick) CUBEPICK,
sum(OD.qtyship) QTYSHIP,
sum(OD.weightship) WEIGHTSHIP,
sum(OD.cubeship) CUBESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)) PLTSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)) CTNSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)) CASESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)) PCSSHIP,
min(OD.uom) UOM,
ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc) ORDER_CARTONS,
vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc) HANDLING_UNITS
from orderhdr OH, orderdtl OD, custitem CI, nmfclasscodes NCC,
     loads LD
where OD.orderid = OH.orderid
  and OD.shipid = OH.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
  and OH.loadno = LD.loadno
group by OH.loadno,
         OH.stopno,
         OH.shipno,
         OH.orderid,
         OH.shipid,
         CI.nmfc,
         NCC.class,
         NCC.descr,
         decode(CI.hazardous,'Y','X',''),
         decode(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N'),
                'Y', nvl(OH.hdrpassthruchar27, LD.billoflading),
                'L', nvl(OH.hdrpassthruchar27, LD.billoflading),
                LD.billoflading),
         ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc),
         vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc))
group by loadno,
nmfc,
nmfc_class,
descr,
hazardous,
uom;

CREATE OR REPLACE VIEW VICS_BOL_TF_INFO
(loadno, cn_name_addr1_addr2, item, descr, lotnumber, useritem1, quantity, unitofmeasure,
 weight, manufacturedate, expirationdate, po, hdrpassthruchar02,
 hdrpassthrunum02, hdrpassthrunum06)
AS
select loadno,
       cn_name_addr1_addr2,
       item,
       descr,
       lotnumber,
       useritem1,
       sum(quantity) quantity,
       unitofmeasure,
       sum(weight) weight,
       manufacturedate,
       expirationdate,
       po,
       hdrpassthruchar02,
       hdrpassthrunum02,
       hdrpassthrunum06
  from (
  select vboi.loadno,
         vboi.cn_name_addr1_addr2,
         sp.item,
         ci.descr,
         sp.lotnumber,
         sp.useritem1,
         sp.quantity,
         sp.unitofmeasure,
         sp.weight,
         trunc(sp.manufacturedate) manufacturedate,
         trunc(sp.expirationdate) expirationdate,
         (select po
            from orderhdr
           where (orderid,shipid) in (
            select orderid,shipid
              from plate
             where lpid = sp.fromlpid
             union
            select orderid,shipid
              from deletedplate
             where lpid = sp.fromlpid)) po,
         (select hdrpassthruchar02
            from orderhdr
           where (orderid,shipid) in (
            select orderid,shipid
              from plate
             where lpid = sp.fromlpid
             union
            select orderid,shipid
              from deletedplate
             where lpid = sp.fromlpid)) hdrpassthruchar02,
         (select hdrpassthrunum02
            from orderhdr
           where (orderid,shipid) in (
            select orderid,shipid
              from plate
             where lpid = sp.fromlpid
             union
            select orderid,shipid
              from deletedplate
             where lpid = sp.fromlpid)) hdrpassthrunum02,
         (select hdrpassthrunum06
            from orderhdr
           where (orderid,shipid) in (
            select orderid,shipid
              from plate
             where lpid = sp.fromlpid
             union
            select orderid,shipid
              from deletedplate
             where lpid = sp.fromlpid)) hdrpassthrunum06
    from vics_bol_order_info vboi,
         shippingplateview sp,
         custitem ci
   where sp.orderid=vboi.orderid
     and sp.shipid=vboi.shipid
     and sp.type in ('F','P')
     and ci.custid=sp.custid
     and ci.item=sp.item)
 group by loadno,
          cn_name_addr1_addr2,
          item,
          descr,
          lotnumber,
          useritem1,
          unitofmeasure,
          manufacturedate,
          expirationdate,
          po,
          hdrpassthruchar02,
          hdrpassthrunum02,
          hdrpassthrunum06;

create or replace procedure vicsbolprocbase
(bol_cursor IN OUT vicsbolpkg.bol_type
,in_loadno IN number
,in_billtoflag_yn IN varchar2)
as

cursor curLoads is
  select ld.facility,
         ld.loadstatus, 
         ld.statusupdate,
         ld.carrier,
         ld.trailer,
         ld.seal,
         ld.prono,
         ld.shipterms,
         ld.ldpassthruchar01,
         ld.ldpassthruchar02,
         ld.ldpassthruchar03,
         ld.ldpassthruchar36,
         ld.ldpassthruchar40,
         ld.billoflading,
         zbol.loadscmt(ld.rowid) as loadcomment,
         lbc.bolcomment
    from loads ld, loadsbolcommentsview lbc
   where ld.loadno = in_loadno
     and ld.loadno = lbc.loadno (+);
ld curLoads%rowtype;

cursor curCarrier(in_carrier IN varchar2) is
  select name,
         scac,
         contact
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;
lssc curCarrier%rowtype;

cursor curOrderHdrByLoad is
  select orderid,
         shipid,
         shipterms,
         prono,
         billoflading,
         reference,
         custid,
         shipto,
         shiptoname,
         shiptoaddr1,
         shiptoaddr2,
         shiptocity,
         shiptostate,
         shiptopostalcode,
         shiptocountrycode,
         consignee,
         billtoname,
         billtoaddr1,
         billtoaddr2,
         billtocity,
         billtostate,
         billtopostalcode,
         billtocountrycode,
         hdrpassthruchar01,
         hdrpassthruchar06,
         hdrpassthruchar26,
         hdrpassthruchar27,
         hdrpassthruchar28,
         hdrpassthruchar36,
         zbol.orderhdrbolcomments(orderid, shipid) bolcomment,
         vicsbolpkg.cn_name_addr1_addr2(orderid, shipid) cn_name_addr1_addr2
    from orderhdr
   where loadno = in_loadno
   order by cn_name_addr1_addr2;
oh curOrderHdrByLoad%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select cu.name,
	       cu.addr1,
	       cu.addr2,
	       cu.city,
	       cu.state,
	       cu.postalcode,
	       cu.countrycode,
	       cu.manufacturerucc
	  from customer cu,
	       customer_aux ca
	 where cu.custid = in_custid
	   and ca.custid = cu.custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility IN varchar2) is
	select name,
	       addr1,
	       addr2,
	       city,
	       state,
	       postalcode,
	       countrycode
	  from facility
	 where facility = in_facility;
fa curFacility%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
	select upper(trim(consignee)) consignee,
	       upper(trim(name)) name,
	       upper(trim(addr1)) addr1,
	       upper(trim(addr2)) addr2,
	       upper(trim(city)) city,
	       upper(trim(state)) state,
	       upper(trim(postalcode)) postalcode,
	       upper(trim(countrycode)) countrycode
	  from consignee
	 where consignee = in_consignee;
cn curConsignee%rowtype;
cr curConsignee%rowtype;


numSessionId number;
dtlCount integer;
orderCount integer;
orderCountNMFC integer;
poCount integer;
carrierCount integer;
loadOrderCount integer;
loadCarrierCount integer;
bolCount integer;
pronoCount integer;
tfCount integer;
print_status varchar2(12);
billoflading varchar2(40);
autogen varchar2(1);

l_cn_name_addr1_addr2 varchar2(167);
l_cn_addr2_not_null varchar2(40);

FUNCTION VICSChkDigit
           (in_Data in varchar2)
           RETURN varchar2 IS
         OutData varchar2(17);

VarData varchar2 (16);
VarNumber number;

BEGIN

      VarData := NULL;

                IF LENGTH(in_Data) <> 16 THEN
          zut.prt(substr('Invalid Field length' || length(in_data),1,60));
                         OutData := '99999999999999999';

                         RETURN OutData;

                END IF;

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := TO_NUMBER(SUBSTR(in_Data,1,7));

--This statement will raise a VALUE_ERROR Exception when it converts a non-numeric value
VarNumber := TO_NUMBER(SUBSTR(in_Data,8,9));

VarNumber := 10 - MOD(TO_NUMBER(SUBSTR(TRIM(in_Data),1,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),2,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),3,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),4,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),5,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),6,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),7,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),8,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),9,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),10,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),11,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),12,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),13,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),14,1)) * 3 +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),15,1)) +
                         TO_NUMBER(SUBSTR(TRIM(in_Data),16,1)) * 3,10);

IF VarNumber = 10 THEN

                                  VarNumber := 0;

                         END IF;

OutData := in_Data || TO_CHAR(VarNumber);

RETURN OutData;


EXCEPTION
                 WHEN OTHERS THEN

                 RETURN '99999999999999999';

END VICSChkDigit;


begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from vicsbol
where sessionid = numSessionId;
commit;

delete from vicsbol
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from vicsbol
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table vicsbol';
end if;

ld := null;
open curLoads;
fetch curLoads into ld;
close curLoads;

if (ld.loadstatus = '9') and (ld.statusupdate < (sysdate-(5/1440))) then
	print_status := 'REPRINT';
end if;

ca := null;
open curCarrier(ld.carrier);
fetch curCarrier into ca;
close curCarrier;

fa := null;
open curFacility(ld.facility);
fetch curFacility into fa;
close curFacility;

select count(1), count(distinct cn_name_addr1_addr2)
  into loadOrderCount, bolCount
  from vics_bol_order_info
 where loadno = NVL(in_loadno, UID);
   
select count(distinct nmfc)
  into loadCarrierCount
  from vics_bol_ld_carrier_info
 where loadno = NVL(in_loadno, UID);
     
select count(1)
  into pronoCount
  from(
  select distinct(nvl(oh.prono,ld.prono))
    from orderhdr oh, loads ld
   where oh.loadno = in_loadno
     and ld.loadno = oh.loadno);
     
l_cn_name_addr1_addr2 := null;
l_cn_addr2_not_null := null;
cn := null;
for oh in curOrderHdrByLoad
loop
	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  if (cn.name is null) or (l_cn_name_addr1_addr2 is null) or
     (l_cn_name_addr1_addr2 <> oh.cn_name_addr1_addr2) then

    l_cn_name_addr1_addr2 := oh.cn_name_addr1_addr2;
    cn := null;
    cn.consignee := vicsbolpkg.cn_consignee(oh.orderid, oh.shipid);

    if (cn.consignee is not null) then
      open curConsignee(cn.consignee);
      fetch curConsignee into cn;
      close curConsignee;
    else
      cn.name := vicsbolpkg.cn_name(oh.orderid, oh.shipid);
      cn.addr1 := vicsbolpkg.cn_addr1(oh.orderid, oh.shipid);
      cn.addr2 := upper(trim(oh.shiptoaddr2));
      cn.city := upper(trim(oh.shiptocity));
      cn.state := upper(trim(oh.shiptostate));
      cn.postalcode := upper(trim(oh.shiptopostalcode));
      cn.countrycode := upper(trim(oh.shiptocountrycode));
    end if;

    l_cn_addr2_not_null := vicsbolpkg.cn_addr2(oh.orderid, oh.shipid);

    select count(1)
      into orderCount
      from vics_bol_order_info
     where loadno = NVL(in_loadno, UID)
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(distinct po)
      into poCount
      from vics_bol_order_info
     where loadno = NVL(in_loadno, UID)
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(1)
      into orderCountNMFC
      from vics_bol_order_info_nmfc
     where loadno = NVL(in_loadno, UID)
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(1)
      into carrierCount
      from vics_bol_carrier_info
     where loadno = NVL(in_loadno, UID)
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(1)
      into tfCount
      from vics_bol_tf_info
     where loadno = NVL(in_loadno, UID)
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
  end if;
  
  cr := null;
  if ((oh.shipterms = '3RD') and
      (nvl(oh.billtoname,'(none)') = '(none)')) or
     (nvl(oh.consignee,'(none)') <> '(none)') then
    open curConsignee(nvl(oh.consignee,oh.shipto));
    fetch curConsignee into cr;
    close curConsignee;
  elsif oh.shipterms = '3RD' then
  	cr.name := upper(trim(oh.billtoname));
  	cr.addr1 := upper(trim(oh.billtoaddr1));
  	cr.addr2 := upper(trim(oh.billtoaddr2));
  	cr.city := upper(trim(oh.billtocity));
  	cr.state := upper(trim(oh.billtostate));
  	cr.postalcode := upper(trim(oh.billtopostalcode));
  	cr.countrycode := upper(trim(oh.billtocountrycode));
  end if;
  
  autogen := nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N');
 if ((autogen = 'Y') or (autogen = 'L')) then
    billoflading := substr(oh.hdrpassthruchar27,1,40);
  elsif (autogen = 'P') or (nvl(ld.billoflading,'(none)') <> '(none)') then
    billoflading := ld.billoflading;
  else
    billoflading := vicschkdigit(lpad(nvl(cu.manufacturerucc,'0000000'),7,'0')||trim(to_char(nvl(in_loadno,0),'000000000')));
    ld.ldpassthruchar02 := null;
  end if;
  
	insert into vicsbol values(
	  numSessionId, in_loadno, ld.trailer, ld.seal, nvl(oh.prono,ld.prono),
	  ld.loadcomment, ld.bolcomment, nvl(oh.shipterms,nvl(ld.shipterms,'COL')),
	  billoflading, ld.ldpassthruchar01, ld.ldpassthruchar02, ld.ldpassthruchar03, ld.ldpassthruchar36, ld.ldpassthruchar40,
	  oh.orderid, oh.shipid, oh.billoflading, oh.reference, oh.custid, oh.hdrpassthruchar01, oh.hdrpassthruchar06, oh.hdrpassthruchar28, oh.hdrpassthruchar36,
	  oh.bolcomment, cu.name, cu.addr1, cu.addr2, cu.city, cu.state, cu.postalcode, cu.countrycode,
	  ld.facility, fa.name, fa.addr1, fa.addr2, fa.city, fa.state, fa.postalcode, fa.countrycode,
	  cn.consignee, cn.name, cn.addr1, cn.addr2, l_cn_addr2_not_null, l_cn_name_addr1_addr2, cn.city, cn.state, cn.postalcode, cn.countrycode,
	  ld.carrier, ca.name, ca.scac, ca.contact,
	  cr.name, cr.addr1, cr.addr2, cr.city, cr.state, cr.postalcode, cr.countrycode,
	  orderCount, orderCountNMFC, poCount, carrierCount, loadOrderCount, loadCarrierCount, bolCount, pronoCount, tfCount,
	  print_status, autogen, sysdate);
end loop;

commit;

open bol_cursor for
 select *
   from vicsbol
  where sessionid = numSessionId;
  
end vicsbolprocbase;
/
create or replace procedure vicsbolproc
(bol_cursor IN OUT vicsbolpkg.bol_type
,in_loadno IN number)
as
begin
	vicsbolprocbase(bol_cursor, in_loadno, 'N');
end vicsbolproc;
/

create or replace procedure vicsbolproc2
(bol_cursor IN OUT vicsbolpkg.bol_type
,in_loadno IN number)
as
begin
	vicsbolprocbase(bol_cursor, in_loadno, 'Y');
end vicsbolproc2;
/
CREATE OR REPLACE VIEW VICS_BOL_AI_ORDER_INFO
(ORDERID, SHIPID, LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2,
 QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP, WEIGHTSHIP, CUBESHIP,
 REFERENCE, BILLOFLADING, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR09, PO, CARRIER_PHONE, PLTSHIP,
 CTNSHIP, CASESHIP, PCSSHIP, ORDER_CARTONS, OUTPALLETS, OUTPALLETSWEIGHT, HANDLING_UNITS)
AS
select
OH.orderid,
OH.shipid,
OH.loadno,
OH.stopno,
OH.shipno,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
sum(OD.qtyorder),
sum(OD.weightorder),
sum(OD.cubeorder),
sum(OD.qtypick),
sum(OD.weightpick),
sum(OD.cubepick),
sum(OD.qtyship),
sum(OD.weightship),
sum(OD.cubeship),
OH.reference,
OH.billoflading,
OH.hdrpassthruchar01,
OH.hdrpassthruchar09,
OH.po,
CA.phone,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)),
ordercheckview_cartons(OH.orderid, OH.shipid),
nvl(vicsbolpkg.outpallets_orderid(OH.orderid,OH.shipid),0),
nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid,OH.shipid),0),
vicsbolpkg.handling_units(OH.orderid, OH.shipid)
from orderhdr OH, orderdtl OD, loadstopship LSS, carrier CA
where OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and OH.loadno = LSS.loadno (+)
  and OH.stopno = LSS.stopno (+)
  and OH.shipno = LSS.shipno (+)
  and LSS.carrier = CA.carrier (+)
group by OH.orderid,
         OH.shipid,
         OH.loadno,
         OH.stopno,
         OH.shipno,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid),
         OH.reference,
         OH.billoflading,
         OH.hdrpassthruchar01,
         OH.hdrpassthruchar09,
         OH.po,
         CA.phone,
         ordercheckview_cartons(OH.orderid, OH.shipid),
         nvl(vicsbolpkg.outpallets_orderid(OH.orderid,OH.shipid),0),
         nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid,OH.shipid),0),
         vicsbolpkg.handling_units(OH.orderid, OH.shipid);

CREATE OR REPLACE VIEW VICS_BOL_AI_ORDER_INFO_NMFC
(ORDERID, SHIPID, LOADNO, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2,
 QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP, YARDSHIP, CUBESHIP,
 REFERENCE, BILLOFLADING, HDRPASSTHRUCHAR01, HDRPASSTHRUCHAR09, PO, CARRIER_PHONE, PLTSHIP,
 CTNSHIP, CASESHIP, PCSSHIP, ORDER_CARTONS, OUTPALLETS, OUTPALLETSWEIGHT, NMFC, NMFC_CLASS,
 DESCR, BOLTSHIP, WEIGHTSHIP)
AS
select
OH.orderid,
OH.shipid,
OH.loadno,
OH.stopno,
OH.shipno,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
sum(OD.qtyorder),
sum(OD.weightorder),
sum(OD.cubeorder),
sum(OD.qtypick),
sum(OD.weightpick),
sum(OD.cubepick),
sum(OD.qtyship),
sum(OD.weightship),
sum(OD.cubeship),
OH.reference,
OH.billoflading,
OH.hdrpassthruchar01,
OH.hdrpassthruchar09,
OH.po,
CA.phone,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)),
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)),
ordercheckview_cartons(OH.orderid, OH.shipid),
nvl(vicsbolpkg.outpallets_orderid(OH.orderid,OH.shipid),0),
nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid,OH.shipid),0),
CI.nmfc,
NCC.class NMFC_CLASS,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Bolt'),'BT')),0)) BOLT_SHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,CI.baseuom)*CI.itmpassthrunum01,0)) WEIGHTSHIP
from orderhdr OH, orderdtl OD, loadstopship LSS, carrier CA,
     custitem CI, nmfclasscodes NCC
where OH.orderid = OD.orderid
  and OH.shipid = OD.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
  and OH.loadno = LSS.loadno (+)
  and OH.stopno = LSS.stopno (+)
  and OH.shipno = LSS.shipno (+)
  and LSS.carrier = CA.carrier (+)
group by OH.orderid,
         OH.shipid,
         OH.loadno,
         OH.stopno,
         OH.shipno,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid),
         OH.reference,
         OH.billoflading,
         OH.hdrpassthruchar01,
         OH.hdrpassthruchar09,
         OH.po,
         CA.phone,
         ordercheckview_cartons(OH.orderid, OH.shipid),
         CI.nmfc,
         NCC.class,
         NCC.descr;

CREATE OR REPLACE VIEW VICS_BOL_AI_CARRIER_INFO
(BILLOFLADING, STOPNO, SHIPNO, CN_NAME, CN_ADDR1, CN_ADDR2, CN_NAME_ADDR1_ADDR2, NMFC, NMFC_CLASS,
 DESCR, HAZARDOUS, QTYORDER, WEIGHTORDER, CUBEORDER, QTYPICK, WEIGHTPICK, CUBEPICK, QTYSHIP,
 WEIGHTSHIP, CUBESHIP, PLTSHIP, CTNSHIP, CASESHIP, PCSSHIP, UOM, ORDER_CARTONS, OUTPALLETS,
 OUTPALLETSWEIGHT, HANDLING_UNITS)
AS
select billoflading,
stopno,
shipno,
cn_name,
cn_addr1,
cn_addr2,
cn_name_addr1_addr2,
nmfc,
nmfc_class,
descr,
hazardous,
sum(qtyorder),
sum(weightorder),
sum(cubeorder),
sum(qtypick),
sum(weightpick),
sum(cubepick),
sum(qtyship),
sum(weightship),
sum(cubeship),
sum(pltship),
sum(ctnship),
sum(caseship),
sum(pcsship),
uom,
sum(order_cartons),
outpallets,
outpalletsweight,
sum(handling_units)
from(
select
OH.billoflading,
OH.stopno,
OH.shipno,
OH.orderid,
OH.shipid,
vicsbolpkg.cn_name(OH.orderid, OH.shipid) cn_name,
vicsbolpkg.cn_addr1(OH.orderid, OH.shipid) cn_addr1,
vicsbolpkg.cn_addr2(OH.orderid, OH.shipid) cn_addr2,
vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) cn_name_addr1_addr2,
CI.nmfc,
NCC.class NMFC_CLASS,
decode(NCC.class,null,'**NO NMFC**',NCC.descr) descr,
decode(CI.hazardous,'Y','X','') HAZARDOUS,
sum(OD.qtyorder) QTYORDER,
sum(OD.weightorder) WEIGHTORDER,
sum(OD.cubeorder) CUBEORDER,
sum(OD.qtypick) QTYPICK,
sum(OD.weightpick) WEIGHTPICK,
sum(OD.cubepick) CUBEPICK,
sum(OD.qtyship) QTYSHIP,
sum(OD.weightship) WEIGHTSHIP,
sum(OD.cubeship) CUBESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('PALLETSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Pallet'),'PLT'))),0)) PLTSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl(zci.default_value('CARTONSUOM'),nvl((select min(code) from unitsofmeasure where abbrev='Carton'),'CTN'))),0)) CTNSHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Case'),'CS')),0)) CASESHIP,
sum(nvl(zlbl.uom_qty_conv(OD.custid,OD.item,OD.qtyship,OD.uom,
    nvl((select min(code) from unitsofmeasure where abbrev='Pieces'),'PCS')),0)) PCSSHIP,
min(OD.uom) UOM,
ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc) ORDER_CARTONS,
nvl(vicsbolpkg.outpallets_orderid(OH.orderid,OH.shipid),0) OUTPALLETS,
nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid,OH.shipid),0) OUTPALLETSWEIGHT,
vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc) HANDLING_UNITS
from orderhdr OH, orderdtl OD, custitem CI, nmfclasscodes NCC
where OD.orderid = OH.orderid
  and OD.shipid = OH.shipid
  and CI.custid = OD.custid
  and CI.item = OD.item
  and CI.nmfc = NCC.nmfc (+)
group by OH.billoflading,
         OH.stopno,
         OH.shipno,
         OH.orderid,
         OH.shipid,
         vicsbolpkg.cn_name(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr1(OH.orderid, OH.shipid),
         vicsbolpkg.cn_addr2(OH.orderid, OH.shipid),
         vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid),
         CI.nmfc,
         NCC.class,
         NCC.descr,
         decode(CI.hazardous,'Y','X',''),
         ordercheckview_cartons_nmfc(OH.orderid, OH.shipid, CI.nmfc),
         nvl(vicsbolpkg.outpallets_orderid(OH.orderid,OH.shipid),0),
         nvl(vicsbolpkg.outpalletsweight_orderid(OH.orderid,OH.shipid),0),
         vicsbolpkg.handling_units_nmfc(OH.orderid, OH.shipid, CI.nmfc))
group by billoflading,
stopno,
shipno,
cn_name,
cn_addr1,
cn_addr2,
cn_name_addr1_addr2,
nmfc,
nmfc_class,
descr,
hazardous,
uom,
outpallets,
outpalletsweight;

create or replace procedure vicsbolaiproc
(bol_cursor IN OUT vicsbolpkg.bol_type
,in_bolnumber IN varchar2)
as

cursor curCarrier(in_carrier IN varchar2) is
  select name,
         scac,
         contact
    from carrier
   where carrier = in_carrier;
ca curCarrier%rowtype;
lssc curCarrier%rowtype;

cursor curOrderHdrByBOL is
  select orderid,
         shipid,
         shipterms,
         prono,
         billoflading,
         reference,
         custid,
         carrier,
         fromfacility,
         shipto,
         shiptoname,
         shiptoaddr1,
         shiptoaddr2,
         shiptocity,
         shiptostate,
         shiptopostalcode,
         shiptocountrycode,
         consignee,
         billtoname,
         billtoaddr1,
         billtoaddr2,
         billtocity,
         billtostate,
         billtopostalcode,
         billtocountrycode,
         hdrpassthruchar01,
         hdrpassthruchar06,
         hdrpassthruchar27,
         hdrpassthruchar28,
         hdrpassthruchar36,
         zbol.orderhdrbolcomments(orderid, shipid) bolcomment,
         vicsbolpkg.cn_name_addr1_addr2(orderid, shipid) cn_name_addr1_addr2
    from orderhdr
   where billoflading = in_bolnumber
   order by cn_name_addr1_addr2;
oh curOrderHdrByBOL%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select cu.name,
	       cu.addr1,
	       cu.addr2,
	       cu.city,
	       cu.state,
	       cu.postalcode,
	       cu.countrycode,
	       cu.manufacturerucc
	  from customer cu,
	       customer_aux ca
	 where cu.custid = in_custid
	   and ca.custid = cu.custid;
cu curCustomer%rowtype;

cursor curFacility(in_facility IN varchar2) is
	select name,
	       addr1,
	       addr2,
	       city,
	       state,
	       postalcode,
	       countrycode
	  from facility
	 where facility = in_facility;
fa curFacility%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
	select upper(trim(consignee)) consignee,
	       upper(trim(name)) name,
	       upper(trim(addr1)) addr1,
	       upper(trim(addr2)) addr2,
	       upper(trim(city)) city,
	       upper(trim(state)) state,
	       upper(trim(postalcode)) postalcode,
	       upper(trim(countrycode)) countrycode
	  from consignee
	 where consignee = in_consignee;
cn curConsignee%rowtype;
cr curConsignee%rowtype;

numSessionId number;
dtlCount integer;
orderCount integer;
orderCountNMFC integer;
poCount integer;
carrierCount integer;
loadOrderCount integer;
loadCarrierCount integer;

l_cn_name_addr1_addr2 varchar2(167);
l_cn_addr2_not_null varchar2(40);

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from vicsbol
where sessionid = numSessionId;
commit;

delete from vicsbol
where lastupdate < trunc(sysdate);
commit;

select count(1)
into dtlCount
from vicsbol
where lastupdate < sysdate;

if dtlCount = 0 then
  EXECUTE IMMEDIATE 'truncate table vicsbol';
end if;

select count(1)
  into loadOrderCount
  from vics_bol_ai_order_info
 where billoflading = in_bolnumber;
   
select count(1)
  into loadCarrierCount
  from vics_bol_ai_carrier_info
 where billoflading = in_bolnumber;
     
l_cn_name_addr1_addr2 := null;
l_cn_addr2_not_null := null;
cn := null;
for oh in curOrderHdrByBOL
loop
	ca := null;
  open curCarrier(oh.carrier);
  fetch curCarrier into ca;
  close curCarrier;

  fa := null;
  open curFacility(oh.fromfacility);
  fetch curFacility into fa;
  close curFacility;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  if (cn.name is null) or (l_cn_name_addr1_addr2 is null) or
     (l_cn_name_addr1_addr2 <> oh.cn_name_addr1_addr2) then

    l_cn_name_addr1_addr2 := oh.cn_name_addr1_addr2;
    cn := null;
    cn.consignee := vicsbolpkg.cn_consignee(oh.orderid, oh.shipid);

    if (cn.consignee is not null) then
      open curConsignee(cn.consignee);
      fetch curConsignee into cn;
      close curConsignee;
    else
      cn.name := vicsbolpkg.cn_name(oh.orderid, oh.shipid);
      cn.addr1 := vicsbolpkg.cn_addr1(oh.orderid, oh.shipid);
      cn.addr2 := upper(trim(oh.shiptoaddr2));
      cn.city := upper(trim(oh.shiptocity));
      cn.state := upper(trim(oh.shiptostate));
      cn.postalcode := upper(trim(oh.shiptopostalcode));
      cn.countrycode := upper(trim(oh.shiptocountrycode));
    end if;

    l_cn_addr2_not_null := vicsbolpkg.cn_addr2(oh.orderid, oh.shipid);

    select count(1)
      into orderCount
      from vics_bol_ai_order_info
     where billoflading = in_bolnumber
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(distinct po)
      into poCount
      from vics_bol_ai_order_info
     where billoflading = in_bolnumber
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(1)
      into orderCountNMFC
      from vics_bol_ai_order_info_nmfc
     where billoflading = in_bolnumber
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
       
    select count(1)
      into carrierCount
      from vics_bol_ai_carrier_info
     where billoflading = in_bolnumber
       and cn_name_addr1_addr2 = l_cn_name_addr1_addr2;
  end if;
  
  cr := null;
  if ((oh.shipterms = '3RD') and
      (nvl(oh.billtoname,'(none)') = '(none)')) or
     (nvl(oh.consignee,'(none)') <> '(none)') then
    open curConsignee(nvl(oh.consignee,oh.shipto));
    fetch curConsignee into cr;
    close curConsignee;
  elsif oh.shipterms = '3RD' then
  	cr.name := upper(trim(oh.billtoname));
  	cr.addr1 := upper(trim(oh.billtoaddr1));
  	cr.addr2 := upper(trim(oh.billtoaddr2));
  	cr.city := upper(trim(oh.billtocity));
  	cr.state := upper(trim(oh.billtostate));
  	cr.postalcode := upper(trim(oh.billtopostalcode));
  	cr.countrycode := upper(trim(oh.billtocountrycode));
  end if;
     
	insert into vicsbol values(
	  numSessionId, null, null, null, oh.prono,
	  null, null, nvl(oh.shipterms,'COL'),
	  null, null, null, null, null, null,
	  oh.orderid, oh.shipid, in_bolnumber, oh.reference, oh.custid, oh.hdrpassthruchar01, oh.hdrpassthruchar06, oh.hdrpassthruchar28, oh.hdrpassthruchar36,
	  oh.bolcomment, cu.name, cu.addr1, cu.addr2, cu.city, cu.state, cu.postalcode, cu.countrycode,
	  oh.fromfacility, fa.name, fa.addr1, fa.addr2, fa.city, fa.state, fa.postalcode, fa.countrycode,
	  cn.consignee, cn.name, cn.addr1, cn.addr2, l_cn_addr2_not_null, l_cn_name_addr1_addr2, cn.city, cn.state, cn.postalcode, cn.countrycode,
	  oh.carrier, ca.name, ca.scac, ca.contact,
	  cr.name, cr.addr1, cr.addr2, cr.city, cr.state, cr.postalcode, cr.countrycode,
	  orderCount, orderCountNMFC, poCount, carrierCount, loadOrderCount, loadCarrierCount, null, null, null,
	  null, null, sysdate);
end loop;

commit;

open bol_cursor for
 select *
   from vicsbol
  where sessionid = numSessionId;
  
end vicsbolaiproc;
/

CREATE OR REPLACE PACKAGE Body vicsbolpkg AS

FUNCTION outpallets_orderid
(in_orderid in number
,in_shipid in number
) return number
is
lOutPallets number;
begin
  lOutPallets := 0;

  select sum(nvl(PH.outpallets,0))
    into lOutPallets
    from orderhdr OH, pallethistory PH
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and PH.loadno = OH.loadno
     and PH.custid = OH.custid
     and PH.facility = OH.fromfacility
     and PH.orderid = OH.orderid
     and PH.shipid = OH.shipid;
  
  return lOutPallets;

exception when others then
  return 0;
end outpallets_orderid;

FUNCTION outpalletsweight_orderid
(in_orderid in number
,in_shipid in number
) return number
is
lOutPalletsWeight number;
begin
  lOutPalletsWeight := 0;

  select sum(nvl(to_number(PW.abbrev),0)*PH.outpallets)
    into lOutPalletsWeight
    from orderhdr OH, pallethistory PH, palletweights PW
   where OH.orderid = in_orderid
     and OH.shipid = in_shipid
     and PH.loadno = OH.loadno
     and PH.custid = OH.custid
     and PH.facility = OH.fromfacility
     and PH.orderid = OH.orderid
     and PH.shipid = OH.shipid
     and PH.pallettype = PW.code;
  
  return lOutPalletsWeight;

exception when others then
  return 0;
end outpalletsweight_orderid;

FUNCTION outpallets_shipto
(in_loadno in number
,in_cn_name_addr1_addr2 in varchar2
,in_nmfc in varchar2
) return number
is
lOutPallets number;
begin
  lOutPallets := 0;

  select sum(nvl(PH.outpallets,0))
    into lOutPallets
    from orderhdr OH, pallethistory PH
   where OH.loadno = in_loadno
     and PH.loadno = in_loadno
     and PH.custid = OH.custid
     and PH.facility = OH.fromfacility
     and PH.orderid = OH.orderid
     and PH.shipid = OH.shipid
     and vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) = in_cn_name_addr1_addr2
     and nvl(in_nmfc,'(none)') = nvl((
         select min(CI.nmfc)
           from orderdtl OD, custitem CI
          where OD.orderid = OH.orderid
            and OD.shipid = OH.shipid
            and CI.custid = OD.custid
            and CI.item = OD.item),'(none)');
  
  return lOutPallets;

exception when others then
  return 0;
end outpallets_shipto;

FUNCTION outpalletsweight_shipto
(in_loadno in number
,in_cn_name_addr1_addr2 in varchar2
,in_nmfc in varchar2
) return number
is
lOutPalletsWeight number;
begin
  lOutPalletsWeight := 0;

  select sum(nvl(to_number(PW.abbrev),0)*PH.outpallets)
    into lOutPalletsWeight
    from orderhdr OH, pallethistory PH, palletweights PW
   where OH.loadno = in_loadno
     and PH.loadno = in_loadno
     and PH.custid = OH.custid
     and PH.facility = OH.fromfacility
     and PH.orderid = OH.orderid
     and PH.shipid = OH.shipid
     and vicsbolpkg.cn_name_addr1_addr2(OH.orderid, OH.shipid) = in_cn_name_addr1_addr2
     and PH.pallettype = PW.code
     and nvl(in_nmfc,'(none)') = nvl((
         select min(CI.nmfc)
           from orderdtl OD, custitem CI
          where OD.orderid = OH.orderid
            and OD.shipid = OH.shipid
            and CI.custid = OD.custid
            and CI.item = OD.item),'(none)');
  
  return lOutPalletsWeight;

exception when others then
  return 0;
end outpalletsweight_shipto;

FUNCTION outpallets_loadno
(in_loadno in number
) return number
is
lOutPallets number;
begin
  lOutPallets := 0;

  select sum(nvl(PH.outpallets,0))
    into lOutPallets
    from orderhdr OH, pallethistory PH
   where OH.loadno = in_loadno
     and OH.loadno = PH.loadno
     and OH.custid = PH.custid
     and OH.fromfacility = PH.facility
     and OH.orderid = PH.orderid
     and OH.shipid = PH.shipid;

  return lOutPallets;

exception when others then
  return 0;
end outpallets_loadno;

FUNCTION outpalletsweight_loadno
(in_loadno in number
) return number
is
lOutPalletsWeight number;
begin
  lOutPalletsWeight := 0;

  select sum(nvl(to_number(PW.abbrev),0)*PH.outpallets)
    into lOutPalletsWeight
    from orderhdr OH, pallethistory PH, palletweights PW
   where OH.loadno = in_loadno
     and OH.loadno = PH.loadno
     and OH.custid = PH.custid
     and OH.fromfacility = PH.facility
     and OH.orderid = PH.orderid
     and OH.shipid = PH.shipid
     and PH.pallettype = PW.code;
  
  return lOutPalletsWeight;

exception when others then
  return 0;
end outpalletsweight_loadno;

FUNCTION handling_units
   (in_orderid  in number,
    in_shipid   in number)
return number
is
   out_units number;
begin
   select count(1)
     into out_units
     from shippingplate
    where orderid = in_orderid
      and shipid = in_shipid
      and parentlpid is null;

   return out_units;

exception
   when OTHERS then
      return 0;
end handling_units;

FUNCTION handling_units_nmfc
   (in_orderid  in number,
    in_shipid   in number,
    in_nmfc     in varchar2)
return number
is
   out_units number;
   nmfc_count number;
begin
	
 	out_units := 0;
   for sp in (select lpid
                from shippingplate
               where orderid = in_orderid
                 and shipid = in_shipid
                 and parentlpid is null)
   loop
      select count(1)
        into nmfc_count
        from custitem ci,
      (select custid, item
         from shippingplate
        where orderid = in_orderid
          and shipid = in_shipid
        start with lpid = sp.lpid
      connect by prior lpid = parentlpid) sp1
       where ci.custid = sp1.custid
         and ci.item = sp1.item
         and nvl(ci.nmfc,'(none)') = nvl(in_nmfc,'(none)');
         
      if nmfc_count > 0 then
         out_units := out_units + 1;
      end if;
   end loop;
   
   return out_units;

exception
   when OTHERS then
      return 0;
end handling_units_nmfc;

FUNCTION handling_units_shipto
   (in_loadno in number,
    in_cn_name_addr1_addr2 in varchar2)
return number
is
   out_units number;
   sp_count number;
begin
	
 	 select count(1)
     into out_units
 	   from orderhdr OH, shippingplate SP
 	  where OH.loadno = in_loadno
 	    and cn_name_addr1_addr2(OH.orderid, OH.shipid) = in_cn_name_addr1_addr2
 	    and SP.orderid = OH.orderid
      and SP.shipid = OH.shipid
      and SP.parentlpid is null;

   return out_units;

exception
   when OTHERS then
      return 0;
end handling_units_shipto;

FUNCTION handling_units_loadno
   (in_loadno in number)
return number
is
   out_units number;
   sp_count number;
begin
	
 	 out_units := 0;
 	 for oh in(select OH.orderid orderid, OH.shipid shipid
 	             from orderhdr OH 
 	            where OH.loadno = in_loadno)
 	 loop
      for sp in (select lpid
                   from shippingplate
                  where orderid = oh.orderid
                    and shipid = oh.shipid
                    and parentlpid is null)
      loop
         select count(1)
           into sp_count
           from shippingplate
          where orderid = oh.orderid
            and shipid = oh.shipid
          start with lpid = sp.lpid
        connect by prior lpid = parentlpid;
            
         if sp_count > 0 then
            out_units := out_units + 1;
         end if;
      end loop;
   end loop;
   
   return out_units;

exception
   when OTHERS then
      return 0;
end handling_units_loadno;

FUNCTION cn_consignee
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
cursor curOrderHdr is
  select custid, loadno, shiptype, shipto, shiptoname, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select nvl(shiptopriority,'N') shiptopriority
	  from customer_aux
	 where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdrLoad(in_loadno number, in_hdrpassthruchar01 varchar2, in_postalcode varchar2) is
  select custid, loadno, shiptype, shipto, shiptoname, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where loadno = in_loadno
     and hdrpassthruchar01 = in_hdrpassthruchar01
     and shiptype = 'L'
     and shiptoname is not null
     and shiptopostalcode = in_postalcode
   order by orderid, shipid;
ohl curOrderHdrLoad%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
    select name, consignee
      from consignee
     where consignee = in_consignee;
cn curConsignee%rowtype;

begin

  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  cn := null;  
  if(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'Y') then
    open curConsignee(oh.hdrpassthruchar50);
    fetch curConsignee into cn;
    close curConsignee;
  end if;

  if(nvl(cn.name,'(none)') = '(none)') then
    if (nvl(oh.shiptoname,'(none)') = '(none)') or ((cu.shiptopriority = 'Y') and (nvl(oh.shipto,'(none)') != '(none)')) then
      open curConsignee(oh.shipto);
      fetch curConsignee into cn;
      close curConsignee;
    elsif((nvl(oh.loadno,0) <> 0) and (oh.shiptype = 'L') and
          (nvl(oh.hdrpassthruchar01,'(none)') != '(none)') and (nvl(oh.shiptopostalcode,'(none)') != '(none)')) then
      ohl := null;
      open curOrderHdrLoad(oh.loadno, oh.hdrpassthruchar01, oh.shiptopostalcode);
      fetch curOrderHdrLoad into ohl;
      close curOrderHdrLoad;
      
      cn.consignee := null;
    end if;

    if(nvl(cn.name,'(none)') = '(none)') then
      cn.consignee := null;
    end if;
  end if;

  return cn.consignee;
exception
   when OTHERS then
      return null;
end cn_consignee;

FUNCTION cn_name
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
cursor curOrderHdr is
  select custid, loadno, shiptype, shipto, shiptoname, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select nvl(shiptopriority,'N') shiptopriority
	  from customer_aux
	 where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdrLoad(in_loadno number, in_hdrpassthruchar01 varchar2, in_postalcode varchar2) is
  select custid, loadno, shiptype, shipto, shiptoname, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where loadno = in_loadno
     and hdrpassthruchar01 = in_hdrpassthruchar01
     and shiptype = 'L'
     and shiptoname is not null
     and shiptopostalcode = in_postalcode
   order by orderid, shipid;
ohl curOrderHdrLoad%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
    select name
      from consignee
     where consignee = in_consignee;
cn curConsignee%rowtype;

begin

  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  cn := null;  
  if(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'Y') then
    open curConsignee(oh.hdrpassthruchar50);
    fetch curConsignee into cn;
    close curConsignee;
  end if;

  if(nvl(cn.name,'(none)') = '(none)') then
    if (nvl(oh.shiptoname,'(none)') = '(none)') or ((cu.shiptopriority = 'Y') and (nvl(oh.shipto,'(none)') != '(none)')) then
      open curConsignee(oh.shipto);
      fetch curConsignee into cn;
      close curConsignee;
    elsif((nvl(oh.loadno,0) <> 0) and (oh.shiptype = 'L') and
          (nvl(oh.hdrpassthruchar01,'(none)') != '(none)') and (nvl(oh.shiptopostalcode,'(none)') != '(none)')) then
      ohl := null;
      open curOrderHdrLoad(oh.loadno, oh.hdrpassthruchar01, oh.shiptopostalcode);
      fetch curOrderHdrLoad into ohl;
      close curOrderHdrLoad;
      
      cn.name := ohl.shiptoname;
    end if;

    if(nvl(cn.name,'(none)') = '(none)') then
      cn.name := oh.shiptoname;
    end if;
  end if;

  return upper(trim(cn.name));
exception
   when OTHERS then
      return null;
end cn_name;

FUNCTION cn_addr1
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
cursor curOrderHdr is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr1, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select nvl(shiptopriority,'N') shiptopriority
	  from customer_aux
	 where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdrLoad(in_loadno number, in_hdrpassthruchar01 varchar2, in_postalcode varchar2) is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr1, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where loadno = in_loadno
     and hdrpassthruchar01 = in_hdrpassthruchar01
     and shiptype = 'L'
     and shiptoname is not null
     and shiptopostalcode = in_postalcode
   order by orderid, shipid;
ohl curOrderHdrLoad%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
    select name, addr1
      from consignee
     where consignee = in_consignee;
cn curConsignee%rowtype;

begin

  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  cn := null;  
  if(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'Y') then
    open curConsignee(oh.hdrpassthruchar50);
    fetch curConsignee into cn;
    close curConsignee;
  end if;

  if(nvl(cn.name,'(none)') = '(none)') then
    if (nvl(oh.shiptoname,'(none)') = '(none)') or ((cu.shiptopriority = 'Y') and (nvl(oh.shipto,'(none)') != '(none)')) then
      open curConsignee(oh.shipto);
      fetch curConsignee into cn;
      close curConsignee;
    elsif((nvl(oh.loadno,0) <> 0) and (oh.shiptype = 'L') and
          (nvl(oh.hdrpassthruchar01,'(none)') != '(none)') and (nvl(oh.shiptopostalcode,'(none)') != '(none)')) then
      ohl := null;
      open curOrderHdrLoad(oh.loadno, oh.hdrpassthruchar01, oh.shiptopostalcode);
      fetch curOrderHdrLoad into ohl;
      close curOrderHdrLoad;
      
      cn.addr1 := ohl.shiptoaddr1;
    end if;

    if(nvl(cn.name,'(none)') = '(none)') then
      cn.addr1 := oh.shiptoaddr1;
    end if;
  end if;

  return upper(trim(cn.addr1));
exception
   when OTHERS then
      return 0;
end cn_addr1;

FUNCTION cn_addr2
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
cursor curOrderHdr is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr2, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select nvl(shiptopriority,'N') shiptopriority
	  from customer_aux
	 where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdrLoad(in_loadno number, in_hdrpassthruchar01 varchar2, in_postalcode varchar2) is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr2, shiptopostalcode,
         hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where loadno = in_loadno
     and hdrpassthruchar01 = in_hdrpassthruchar01
     and shiptype = 'L'
     and shiptoname is not null
     and shiptopostalcode = in_postalcode
   order by orderid, shipid;
ohl curOrderHdrLoad%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
    select name, addr2
      from consignee
     where consignee = in_consignee;
cn curConsignee%rowtype;

begin

  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  cn := null;  
  if(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'Y') then
    open curConsignee(oh.hdrpassthruchar50);
    fetch curConsignee into cn;
    close curConsignee;
  end if;

  if(nvl(cn.name,'(none)') = '(none)') then
    if (nvl(oh.shiptoname,'(none)') = '(none)') or ((cu.shiptopriority = 'Y') and (nvl(oh.shipto,'(none)') != '(none)')) then
      open curConsignee(oh.shipto);
      fetch curConsignee into cn;
      close curConsignee;
    elsif((nvl(oh.loadno,0) <> 0) and (oh.shiptype = 'L') and
          (nvl(oh.hdrpassthruchar01,'(none)') != '(none)') and (nvl(oh.shiptopostalcode,'(none)') != '(none)')) then
      ohl := null;
      open curOrderHdrLoad(oh.loadno, oh.hdrpassthruchar01, oh.shiptopostalcode);
      fetch curOrderHdrLoad into ohl;
      close curOrderHdrLoad;
      
      cn.addr2 := ohl.shiptoaddr2;
    end if;

    if(nvl(cn.name,'(none)') = '(none)') then
      cn.addr2 := oh.shiptoaddr2;
    end if;
  end if;

  return upper(trim(nvl(cn.addr2,'(NONE)')));
exception
   when OTHERS then
      return 0;
end cn_addr2;

FUNCTION cn_name_addr1_addr2
   (in_orderid  in number,
    in_shipid   in number)
return varchar2
is
cursor curOrderHdr is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr1, shiptoaddr2,
         shiptocity, shiptostate, shiptopostalcode, hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curCustomer(in_custid IN varchar2) is
	select nvl(shiptopriority,'N') shiptopriority
	  from customer_aux
	 where custid = in_custid;
cu curCustomer%rowtype;

cursor curOrderHdrLoad(in_loadno number, in_hdrpassthruchar01 varchar2, in_postalcode varchar2) is
  select custid, loadno, shiptype, shipto, shiptoname, shiptoaddr1, shiptoaddr2,
         shiptocity, shiptostate, shiptopostalcode, hdrpassthruchar01, hdrpassthruchar50
    from orderhdr
   where loadno = in_loadno
     and hdrpassthruchar01 = in_hdrpassthruchar01
     and shiptype = 'L'
     and shiptoname is not null
     and shiptopostalcode = in_postalcode
   order by orderid, shipid;
ohl curOrderHdrLoad%rowtype;

cursor curConsignee(in_consignee IN varchar2) is
    select name, addr1, addr2, city, state, postalcode
      from consignee
     where consignee = in_consignee;
cn curConsignee%rowtype;

l_name_addr1_addr2 varchar2(167);

begin

  l_name_addr1_addr2 := null;
  
  oh := null;
  open curOrderHdr;
  fetch curOrderHdr into oh;
  close curOrderHdr;

	cu := null;
  open curCustomer(oh.custid);
  fetch curCustomer into cu;
  close curCustomer;

  cn := null;  
  if(nvl(zci.default_value('VICSBOLNUMBERAUTOGEN'),'N') = 'Y') then
    open curConsignee(oh.hdrpassthruchar50);
    fetch curConsignee into cn;
    close curConsignee;
    
    l_name_addr1_addr2 := cn.name || cn.addr1 || cn.addr2 || cn.city || cn.state || cn.postalcode;
  end if;

  if(nvl(l_name_addr1_addr2,'(none)') = '(none)') then
    if (nvl(oh.shiptoname,'(none)') = '(none)') or ((cu.shiptopriority = 'Y') and (nvl(oh.shipto,'(none)') != '(none)')) then
      open curConsignee(oh.shipto);
      fetch curConsignee into cn;
      close curConsignee;
      
      l_name_addr1_addr2 := cn.name || cn.addr1 || cn.addr2 || cn.city || cn.state || cn.postalcode;
    elsif((nvl(oh.loadno,0) <> 0) and (oh.shiptype = 'L') and
          (nvl(oh.hdrpassthruchar01,'(none)') != '(none)') and (nvl(oh.shiptopostalcode,'(none)') != '(none)')) then
      ohl := null;
      open curOrderHdrLoad(oh.loadno, oh.hdrpassthruchar01, oh.shiptopostalcode);
      fetch curOrderHdrLoad into ohl;
      close curOrderHdrLoad;
      
      l_name_addr1_addr2 := ohl.shiptoname || ohl.shiptoaddr1 || ohl.shiptoaddr2 || ohl.shiptocity || ohl.shiptostate || ohl.shiptopostalcode;
    end if;

    if(nvl(cn.name,'(none)') = '(none)') then
      l_name_addr1_addr2 := oh.shiptoname || oh.shiptoaddr1 || oh.shiptoaddr2 || oh.shiptocity || oh.shiptostate || oh.shiptopostalcode;
    end if;
  end if;

  return l_name_addr1_addr2;
exception
   when OTHERS then
      return null;
end cn_name_addr1_addr2;

end vicsbolpkg;
/

exit;
