create or replace view freight_aims_st
(
loadno,
custid,
facility,
shipto_link,
controlno,
shipdate
)
as
select
loadno,
custid,
fromfacility,
hdrpassthruchar01,
orderid,
statusupdate
from orderhdr;

comment on table freight_aims_st is '$Id$';

create or replace view freight_aims_bol
(
loadno,
custid,
facility,
shipto_link,
carrier,
shipterms,
orderid,
shipid,
shipdate,
prono,
HDRPASSTHRUCHAR01,
HDRPASSTHRUCHAR02,
HDRPASSTHRUCHAR03,
HDRPASSTHRUCHAR04,
HDRPASSTHRUCHAR05,
HDRPASSTHRUCHAR06,
HDRPASSTHRUCHAR07,
HDRPASSTHRUCHAR08,
HDRPASSTHRUCHAR09,
HDRPASSTHRUCHAR10,
HDRPASSTHRUCHAR11,
HDRPASSTHRUCHAR12,
HDRPASSTHRUCHAR13,
HDRPASSTHRUCHAR14,
HDRPASSTHRUCHAR15,
HDRPASSTHRUCHAR16,
HDRPASSTHRUCHAR17,
HDRPASSTHRUCHAR18,
HDRPASSTHRUCHAR19,
HDRPASSTHRUCHAR20,
HDRPASSTHRUNUM01,
HDRPASSTHRUNUM02,
HDRPASSTHRUNUM03,
HDRPASSTHRUNUM04,
HDRPASSTHRUNUM05,
HDRPASSTHRUNUM06,
HDRPASSTHRUNUM07,
HDRPASSTHRUNUM08,
HDRPASSTHRUNUM09,
HDRPASSTHRUNUM10,
HDRPASSTHRUDATE01,
HDRPASSTHRUDATE02,
HDRPASSTHRUDATE03,
HDRPASSTHRUDATE04,
HDRPASSTHRUDOLL01,
HDRPASSTHRUDOLL02,
PO,
BILLOFLADING,
reference
)
as
select
oh.loadno,
oh.custid,
oh.fromfacility,
oh.hdrpassthruchar01,
oh.carrier,
oh.shipterms,
oh.orderid,
oh.shipid,
oh.statusupdate,
oh.prono,
oh.hdrPASSTHRUCHAR01,
oh.hdrPASSTHRUCHAR02,
oh.hdrPASSTHRUCHAR03,
oh.hdrPASSTHRUCHAR04,
oh.hdrPASSTHRUCHAR05,
oh.hdrPASSTHRUCHAR06,
oh.hdrPASSTHRUCHAR07,
oh.hdrPASSTHRUCHAR08,
oh.hdrPASSTHRUCHAR09,
oh.hdrPASSTHRUCHAR10,
oh.hdrPASSTHRUCHAR11,
oh.hdrPASSTHRUCHAR12,
oh.hdrPASSTHRUCHAR13,
oh.hdrPASSTHRUCHAR14,
oh.hdrPASSTHRUCHAR15,
oh.hdrPASSTHRUCHAR16,
oh.hdrPASSTHRUCHAR17,
oh.hdrPASSTHRUCHAR18,
oh.hdrPASSTHRUCHAR19,
oh.hdrPASSTHRUCHAR20,
oh.hdrPASSTHRUNUM01,
oh.hdrPASSTHRUNUM02,
oh.hdrPASSTHRUNUM03,
oh.hdrPASSTHRUNUM04,
oh.hdrPASSTHRUNUM05,
oh.hdrPASSTHRUNUM06,
oh.hdrPASSTHRUNUM07,
oh.hdrPASSTHRUNUM08,
oh.hdrPASSTHRUNUM09,
oh.hdrPASSTHRUNUM10,
oh.hdrPASSTHRUDATE01,
oh.hdrPASSTHRUDATE02,
oh.hdrPASSTHRUDATE03,
oh.hdrPASSTHRUDATE04,
oh.hdrPASSTHRUDOLL01,
oh.hdrPASSTHRUDOLL02,
oh.po,
oh.billoflading,
oh.reference
from loads lo, orderhdr oh;

comment on table freight_aims_bol is '$Id$';

create or replace view freight_aims_b2a
(
loadno,
custid,
shipto_link,
purpose_code
)
as
select
loadno,
custid,
hdrpassthruchar01,
'00'
from orderhdr;

comment on table freight_aims_b2a is '$Id$';

create or replace view freight_aims_g62
(
loadno,
custid,
shipto_link,
date_qualifier,
date_value
)
as
select
loadno,
custid,
hdrpassthruchar01,
hdrpassthruchar02,
statusupdate
from orderhdr;

comment on table freight_aims_g62 is '$Id$';

create or replace view freight_aims_k1
(
loadno,
custid,
shipto_link,
comment1
)
as
select
loadno,
custid,
hdrpassthruchar01,
hdrpassthruchar02
from orderhdr;

comment on table freight_aims_k1 is '$Id$';

create or replace view freight_aims_n1
(
loadno,
custid,
orderid,
shipid,
shipto_link,
entity_identifier,
name,
code_qualifier,
code_value
)
as
select
loadno,
custid,
orderid,
shipid,
hdrpassthruchar01,
hdrpassthruchar02,
hdrpassthruchar03,
hdrpassthruchar04,
hdrpassthruchar05
from orderhdr;

comment on table freight_aims_n1 is '$Id$';

create or replace view freight_aims_n4
(
loadno,
custid,
shipto_link,
entity_identifier,
city_name,
state_code,
postalcode
)
as
select
loadno,
custid,
hdrpassthruchar01,
hdrpassthruchar02,
shiptocity,
shiptostate,
shiptopostalcode
from orderhdr;

comment on table freight_aims_n4 is '$Id$';

create or replace view freight_aims_at1
(
loadno,
custid,
shipto_link,
line_item_number
)
as
select
loadno,
custid,
hdrpassthruchar01,
hdrpassthruchar02
from orderhdr;

comment on table freight_aims_at1 is '$Id$';

create or replace view freight_aims_at2
(
loadno,
custid,
shipto_link,
pallet_quantity,
pallet_form_code,
weight_qualifier,
weight_unit_code,
weight,
pieces_quantity,
pieces_form_code,
cases_quantity
)
as
select
loadno,
custid,
hdrpassthruchar01,
qtyship,
'PLT',
'G',
'L',
weightship,
qtycommit,
'CTN',
qtyorder
from orderhdr;

comment on table freight_aims_at2 is '$Id$';

create or replace view freight_aims_se
(
loadno,
custid,
shipto_link,
total_segments,
controlno
)
as
select
loadno,
custid,
hdrpassthruchar01,
qtyorder,
orderid
from orderhdr;

comment on table freight_aims_se is '$Id$';

create or replace view freight_aims_package_quantity
(
loadno,
hdrpassthruchar02,
package_quantity
)
as
select
distinct
loadno,
hdrpassthruchar02,
zimfreight.case_count(loadno,hdrpassthruchar02)
  + zimfreight.carton_count(loadno,hdrpassthruchar02)
from orderhdr;

comment on table freight_aims_package_quantity is '$Id$';

create or replace view freight_aims_cod
(
loadno,
custid,
orderid,
shipid,
shipto_link,
billtoname,
billtocontact,
billtoaddr1,
billtoaddr2,
billtocity,
billtostate,
billtopostalcode,
billtocountrycode,
billtophone,
billtofax,
billtoemail
)
as
select
loadno,
custid,
orderid,
shipid,
hdrpassthruchar01,
billtoname,
billtocontact,
billtoaddr1,
billtoaddr2,
billtocity,
billtostate,
billtopostalcode,
billtocountrycode,
billtophone,
billtofax,
billtoemail
from orderhdr;

comment on table freight_aims_cod is '$Id$';

create or replace view freight_aims_itd
(
loadno,
custid,
orderid,
shipid,
shipto_link,
item,
itemdesc,
quantity,
uom,
weight
)
as
select
O.loadno,
O.custid,
O.orderid,
O.shipid,
O.hdrpassthruchar01,
D.item,
I.descr,
D.qtyship,
D.uom,
D.weightship
from custitem I, orderdtl D,orderhdr O
where D.orderid = O.orderid
and D.shipid = O.shipid
and I.custid = D.custid
and I.item = D.item;

comment on table freight_aims_itd is '$Id$';

exit;
