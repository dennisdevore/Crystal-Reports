drop table orderactivityrpt;

create global temporary table orderactivityrpt
(sessionid       number
,facility        varchar2(3)
,custid          varchar2(10)
,custname        varchar2(40)
,orderid         number(9)
,shipid          number(2)
,reference       varchar2(20)
,po              varchar2(20)
,ordertype       varchar2(12)
,orderstatus     varchar2(12)
,shipdate        date
,consignee       varchar2(10)
,consigneename   varchar2(40)
,qtyship         number(10)
,weightship      number(17,8)
,shipplatecount  number(7)
,rcvddate        date
,shipper         varchar2(10)
,shippername     varchar2(40)
,qtyrcvd         number(10)
,weightrcvd      number(17,8)
,rcvdplatecount  number(7)
) on commit preserve rows;

create index orderactivityrpt_sessionid_idx
 on orderactivityrpt(sessionid,facility,custid);

create or replace package orderactivityrptPKG
as type id_type is ref cursor return orderactivityrpt%rowtype;
end orderactivityrptPKG;
/

--
-- $Id$
--

create or replace procedure orderactivityrptPROC
(ai_cursor IN OUT orderactivityrptPKG.id_type
,in_facility IN varchar2
,in_begdate IN date
,in_enddate IN date
)
as

cursor curShipments is
  select oh.orderid, oh.shipid, oh.custid, oh.reference, oh.po, oh.ordertype,
         oh.dateshipped, oh.shipto, nvl(cn.name, oh.shiptoname) shiptoname,
         nvl(oh.qtyship,0) qtyship, nvl(oh.weightship,0) weightship,
         cu.name custname
    from orderhdr oh, customer cu, consignee cn
   where fromfacility = in_facility
   	 and oh.orderstatus = '9'
     and oh.ordertype in ('O','U')
     and oh.dateshipped >= trunc(in_begdate)
     and oh.dateshipped < trunc(in_enddate) + 1
     and cu.custid = oh.custid
     and oh.shipto = cn.consignee (+)
   union
  select oh.orderid, oh.shipid, oh.custid, oh.reference, oh.po, oh.ordertype,
         oh.lastupdate dateshipped, oh.shipto, nvl(cn.name, oh.shiptoname) shiptoname,
         nvl(oh.qtyship,0) qtyship, nvl(oh.weightship,0) weightship,
         cu.name custname
    from orderhdr oh, customer cu, consignee cn
   where fromfacility = in_facility
   	 and oh.orderstatus = '9'
     and oh.ordertype not in ('O','U')
     and oh.lastupdate >= trunc(in_begdate)
     and oh.lastupdate < trunc(in_enddate) + 1
     and cu.custid = oh.custid
     and oh.shipto = cn.consignee (+);
cs curShipments%rowtype;

cursor curShipPlate(in_orderid number, in_shipid number) is
  select count(1) platecount
    from shippingplate
   where orderid = in_orderid
     and shipid = in_shipid
     and type in ('F','P');
csp curShipPlate%rowtype;

cursor curReceipts is
  select oh.orderid, oh.shipid, oh.custid, oh.reference, oh.po, oh.ordertype,
         ld.rcvddate, oh.shipper, cn.name shippername,
         nvl(oh.qtyrcvd,0) qtyrcvd, nvl(oh.weightrcvd,0) weightrcvd,
         cu.name custname
    from loads ld, orderhdr oh, customer cu, consignee cn
   where ld.rcvddate >= trunc(in_begdate)
     and ld.rcvddate < trunc(in_enddate) + 1
     and oh.loadno = ld.loadno
     and oh.tofacility = in_facility
   	 and oh.orderstatus = 'R'
     and oh.ordertype in ('O','U')
     and cu.custid = oh.custid
     and oh.shipper = cn.consignee (+)
   union
  select oh.orderid, oh.shipid, oh.custid, oh.reference, oh.po, oh.ordertype,
         oh.lastupdate rcvddate, oh.shipper, cn.name shippername,
         nvl(oh.qtyrcvd,0) qtyrcvd, nvl(oh.weightrcvd,0) weightrcvd,
         cu.name custname
    from orderhdr oh, customer cu, consignee cn
   where oh.tofacility = in_facility
   	 and oh.orderstatus = 'R'
     and oh.ordertype not in ('O','U')
     and oh.lastupdate >= trunc(in_begdate)
     and oh.lastupdate < trunc(in_enddate) + 1
     and cu.custid = oh.custid
     and oh.shipper = cn.consignee (+);
cr curReceipts%rowtype;

cursor curRcptPlate(in_orderid number, in_shipid number) is
  select count(1) platecount
    from (
      select lpid
        from plate
       where orderid = in_orderid
         and shipid = in_shipid
       union
      select lpid
        from deletedplate
       where orderid = in_orderid
         and shipid = in_shipid);
crp curRcptPlate%rowtype;

numSessionId number;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from orderactivityrpt
where sessionid = numSessionId;
commit;

for cs in curShipments
loop
  csp := null;
  open curShipPlate(cs.orderid, cs.shipid);
  fetch curShipPlate into csp;
  close curShipPlate;
  
  insert into orderactivityrpt (
    sessionid, facility, custid, custname, orderid, shipid, reference, po, ordertype, orderstatus,
    shipdate, consignee, consigneename, qtyship, weightship, shipplatecount,
    rcvddate, shipper, shippername, qtyrcvd, weightrcvd, rcvdplatecount)
  values(
    numSessionId, in_facility, cs.custid, cs.custname, cs.orderid, cs.shipid, cs.reference, cs.po, cs.ordertype, '9',
    cs.dateshipped, cs.shipto, cs.shiptoname, cs.qtyship, cs.weightship, csp.platecount,
    null, null, null, 0, 0, 0);
end loop;

for cr in curReceipts
loop
  crp := null;
  open curRcptPlate(cr.orderid, cr.shipid);
  fetch curRcptPlate into crp;
  close curRcptPlate;
  
  insert into orderactivityrpt (
    sessionid, facility, custid, custname, orderid, shipid, reference, po, ordertype, orderstatus,
    shipdate, consignee, consigneename, qtyship, weightship, shipplatecount,
    rcvddate, shipper, shippername, qtyrcvd, weightrcvd, rcvdplatecount)
  values(
    numSessionId, in_facility, cr.custid, cr.custname, cr.orderid, cr.shipid, cr.reference, cr.po, cr.ordertype, 'R',
    null, null, null, 0, 0, 0,
    cr.rcvddate, cr.shipper, cr.shippername, cr.qtyrcvd, cr.weightrcvd, crp.platecount);
end loop;

open ai_cursor for
select *
   from orderactivityrpt
  where sessionid = numSessionId;

end orderactivityrptPROC;
/

show errors procedure orderactivityrptPROC;
exit;
