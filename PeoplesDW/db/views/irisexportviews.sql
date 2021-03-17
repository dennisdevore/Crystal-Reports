-- NOTE: these are static representations of views that
-- are created dynamically at export time; if changes are made here
-- they must also be reflected in the view definition logic in
-- zimp.begin_irisrecv/zimp.end_irisrecv
-- zimp.begin_irisship/zimp.end_irisship
-- zimp.begin_irisancl/zimp.end_irisancl
CREATE OR REPLACE VIEW ALPS.irisancl_dtl
(custid
,company
,warehouse
,orderid
,shipid
,reference
,opendate
,closedate
,name
,serviceclass
,servicename
,servicefee
,quantity
,shiptoname
,shiptocontact
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptopostalcode
,shiptocountrycode
)
as
select
I.custid,
I.company,
I.warehouse,
I.orderid,
I.shipid,
OH.reference,
OH.statusupdate,
oh.statusupdate,
C.name,
I.class,
I.service,
substr(to_char(I.charge,'099999999999.99'),2),
I.quantity,
OH.shiptoname,
OH.shiptocontact,
OH.shiptoaddr1,
OH.shiptoaddr2,
OH.shiptocity,
OH.shiptostate,
OH.shiptopostalcode,
OH.shiptocountrycode
from orderhdr OH, customer C,
     irisanclex I
where C.custid  = I.custid
  and OH.orderid(+) = I.orderid
  and OH.shipid(+) = I.shipid;

comment on table irisancl_dtl is '$Id$';


CREATE OR REPLACE VIEW ALPS.irisrecv_dtl
(custid
,company
,warehouse
,orderid
,shipid
,line
,sortord
,item
,lotnumber
,serialnumber
,reference
,opendate
,closedate
,name
,serviceclass
,servicename
,servicefee
,quantity
,lineord
,shipfromname
,shipfromcontact
,shipfromaddr1
,shipfromaddr2
,shipfromcity
,shipfromstate
,shipfrompostalcode
,shipfromcountrycode
)
as
select
I.custid,
I.company,
I.warehouse,
I.orderid,
I.shipid,
I.line,
I.sortord,
I.item,
I.lotnumber,
I.serialnumber,
OH.reference,
L.rcvddate,
OH.statusupdate,
C.name,
I.class,
I.service,
substr(to_char(I.charge,'099999999999.99'),2),
I.quantity,
decode(I.service,'RCO',0,I.line),
SH.name,
SH.contact,
SH.addr1,
SH.addr2,
SH.city,
SH.state,
SH.postalcode,
SH.countrycode
from shipper SH, loads L, orderhdr OH, customer C,
     irisrecvex I
where C.custid  = I.custid
  and OH.orderid(+) = I.orderid
  and OH.shipid(+) = I.shipid
  and L.loadno(+) = OH.loadno
  and SH.shipper(+) = OH.shipper;

comment on table irisrecv_dtl is '$Id$';


CREATE OR REPLACE VIEW ALPS.irisship_dtl
(custid
,company
,warehouse
,orderid
,shipid
,line
,sortord
,item
,lotnumber
,serialnumber
,reference
,po
,opendate
,closedate
,name
,serviceclass
,servicename
,servicefee
,quantity
,lineord
,weight
,pkgcount
,tracking
,carrier
,service
,shiptoname
,shiptocontact
,shiptoaddr1
,shiptoaddr2
,shiptocity
,shiptostate
,shiptopostalcode
,shiptocountrycode
)
as
select
I.custid,
I.company,
I.warehouse,
I.orderid,
I.shipid,
I.line,
I.sortord,
I.item,
I.lotnumber,
I.serialnumber,
OH.reference,
OH.po,
OH.statusupdate,
oh.dateshipped,
C.name,
I.class,
I.service,
substr(to_char(I.charge,'099999999999.99'),2),
I.quantity,
decode(I.service,'ORC',0,I.line),
I.weight,
I.pkgcount,
I.trackingno,
OH.carrier,
NVL(SUBSTR(OH.hdrpassthruchar13,6,3),OH.hdrpassthruchar07),   -- OH.deliveryservice,
OH.shiptoname,
OH.shiptocontact,
OH.shiptoaddr1,
OH.shiptoaddr2,
OH.shiptocity,
OH.shiptostate,
OH.shiptopostalcode,
OH.shiptocountrycode
from orderhdr OH, customer C,
     irisshipex I
where C.custid  = I.custid
  and OH.orderid(+) = I.orderid
  and OH.shipid(+) = I.shipid;

comment on table irisship_dtl is '$Id$';


exit;


