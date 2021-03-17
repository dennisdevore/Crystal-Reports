create or replace view plttrkcustbalview
(
    custid,
    facility,
    pallettype,
    curdate,
    begbal,
    endbal
)
as
select custid, 
       facility, 
       pallettype, 
       trunc_lastupdate,
       zpt.calc_cust_begbal(custid, facility, pallettype, trunc_lastupdate) begbal,
       zpt.calc_cust_endbal(custid, facility, pallettype, trunc_lastupdate) endbal
from pallethistory_sum_cust;

comment on table plttrkcustbalview is '$Id$';


create or replace view plttrkcarrbalview
(
    carrier,
    facility,
    pallettype,
    curdate,
    begbal,
    endbal
)
as
select distinct carrier, 
       facility, 
       pallettype, 
       trunc(lastupdate),
       zpt.calc_carr_begbal(carrier, facility, pallettype, trunc(lastupdate)) begbal,
       zpt.calc_carr_endbal(carrier, facility, pallettype, trunc(lastupdate)) endbal
from pallethistory;

comment on table plttrkcarrbalview is '$Id$';


create or replace view plttrkconsbalview
(
    consignee,
    facility,
    pallettype,
    curdate,
    begbal,
    endbal
)
as
select distinct b.consignee,
       a.facility,
       pallettype,
       trunc(a.lastupdate),
       zpt.calc_cons_begbal(b.consignee, a.facility, pallettype, trunc(a.lastupdate)) begbal,
       zpt.calc_cons_endbal(b.consignee, a.facility, pallettype, trunc(a.lastupdate)) endbal
from pallethistory a, orderhdr b
where a.orderid = b.orderid (+) and
	  a.shipid  = b.shipid (+) and
	  consignee > ' ';
comment on table plttrkconsbalview is '$Id$';

create or replace view plttrkcustrptview(
       custid,
       cust_name,
       facility,
       facility_name,
       pallettype,
       pallettype_descr,
       curdate,
       begbal,
       endbal
)
as
select
    P.custid,
    C.name,
    P.facility,
    F.name,
    P.pallettype,
    PT.descr,
    P.curdate,
    P.begbal,
    P.endbal
 from pallettypes PT, facility F, customer C, plttrkcustbalview P
where P.custid = C.custid(+)
  and P.facility = F.facility(+)
  and P.pallettype = PT.code;

comment on table plttrkcustrptview is '$Id$';


create or replace view plttrkcarrrptview(
       carrier,
       carrier_name,
       facility,
       facility_name,
       pallettype,
       pallettype_descr,
       curdate,
       begbal,
       endbal
)
as
select
    P.carrier,
    C.name,
    P.facility,
    F.name,
    P.pallettype,
    PT.descr,
    P.curdate,
    P.begbal,
    P.endbal
 from pallettypes PT, facility F, carrier C, plttrkcarrbalview P
where P.carrier = C.carrier(+)
  and P.facility = F.facility(+)
  and P.pallettype = PT.code;

comment on table plttrkcarrrptview is '$Id$';


create or replace view plttrkconsrptview(
       consignee,
       consignee_name,
       facility,
       facility_name,
       pallettype,
       pallettype_descr,
       curdate,
       begbal,
       endbal
)
as
select
    P.consignee,
    C.name,
    P.facility,
    F.name,
    P.pallettype,
    PT.descr,
    P.curdate,
    P.begbal,
    P.endbal
 from pallettypes PT, facility F, consignee C, plttrkconsbalview P
where P.consignee = C.consignee(+)
  and P.facility = F.facility(+)
  and P.pallettype = PT.code;

comment on table plttrkconsrptview is '$Id$';


create or replace view plttrkhistrptview(
       custid,
       facility,
       pallettype,
       loadno,
       carrier,
       consignee,
       shipto,
       shiptoname,
       adjreason,
       curdate,
       cnt,
       comment1,
       orderid,
       shipid,
       reference
)
as
select
       p.custid,
       p.facility,
       p.pallettype,
       p.loadno,
       p.carrier,
       o.consignee,
       o.shipto,
       o.shiptoname,
       p.adjreason,
       trunc(p.lastupdate),
       nvl(p.inpallets,0) - nvl(p.outpallets,0) as cnt,
       p.comment1,
       nvl(p.orderid,0),
       nvl(p.shipid,0),
       o.reference
  from pallethistory p, orderhdr o
 where p.orderid = o.orderid (+)
   and nvl(p.shipid,1) = o.shipid (+);
  
comment on table plttrkhistrptview is '$Id$';
  
exit;
