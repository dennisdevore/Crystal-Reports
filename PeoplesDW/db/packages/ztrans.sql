drop table transanalysis;

create table transanalysis
(sessionid       number
,month           varchar(3)
,receipts        number(16)
,weightrcvd      number(16)
,shipments       number(16)
,weightshpd      number(16)
,inoutcharges    number(16,2)
,storecharges    number(16,2)
,othercharges    number(16,2)
,performance     number(4)
,lastupdate      date
);

create index transanalysis_sessionid_idx
 on transanalysis(sessionid,month);

create index transanalysis_lastupdate_idx
 on transanalysis(lastupdate);

create or replace package ztranspkg
as type ta_type is ref cursor return transanalysis%rowtype;
end ztranspkg;
/

CREATE OR REPLACE procedure transanalysisPROC
(ta_cursor IN OUT ztranspkg.ta_type
,in_facility IN varchar2
,in_year IN varchar2
,in_debug_yn IN varchar2)
as

numSessionId number;
iMonth number;
sMonth varchar2(3);
dFirstOfMonth date;
dtlReceipts transanalysis.receipts%type;
dtlWeightRcvd transanalysis.weightrcvd%type;
dtlShipments transanalysis.shipments%type;
dtlWeightShpd transanalysis.weightshpd%type;
dtlInOutCharges transanalysis.inoutcharges%type;
dtlStoreCharges transanalysis.storecharges%type;
dtlOtherCharges transanalysis.othercharges%type;
dtlPerformance transanalysis.performance%type;

procedure debugmsg(in_text varchar2) is
begin
  if upper(rtrim(in_debug_yn)) = 'Y' then
    zut.prt(in_text);
  end if;
exception when others then
  null;
end;

begin

select sys_context('USERENV','SESSIONID')
 into numSessionId
 from dual;

delete from transanalysis
where sessionid = numSessionId;
commit;

delete from transanalysis
where lastupdate < trunc(sysdate);
commit;

iMonth := 1;

loop
  sMonth := to_char(iMonth,'09');
  dFirstOfMonth := to_date(sMonth||'01'||in_year,'MMDDYYYY');
  dtlReceipts := 0.0;
  dtlWeightRcvd := 0.0;
  dtlShipments := 0.0;
  dtlWeightShpd := 0.0;
  dtlInOutCharges := 0.0;
  dtlStoreCharges := 0.0;
  dtlOtherCharges := 0.0;
  dtlPerformance := 100;

  select count(1) receipts
    into dtlReceipts
    from orderconfirmview
   where tofacility=in_facility
     and orderstatus='R'
     and statusupdate >= dFirstOfMonth
     and statusupdate < add_months(dFirstOfMonth,1)
     and nvl(qtyrcvd,0) != 0;

  select nvl(sum(nvl(od.weightrcvdgood,0) + nvl(od.weightrcvddmgd,0)),0)  weightrcvd
    into dtlWeightRcvd
    from orderconfirmview oc, orderdtlview od
   where oc.tofacility=in_facility
     and oc.orderstatus='R'
     and oc.statusupdate >= dFirstOfMonth
     and oc.statusupdate < add_months(dFirstOfMonth,1)
     and nvl(oc.qtyrcvd,0) != 0
     and oc.orderid = od.orderid
     and oc.shipid = od.shipid
     and od.linestatus !='X';

  if sql%rowcount = 0 or dtlWeightRcvd is null then
  	dtlWeightRcvd := 0;
  end if;

  select count(1) shipments
    into dtlShipments
    from orderhdr oh
   where oh.fromfacility = in_facility
     and oh.orderstatus = '9'
     and oh.statusupdate >= dFirstOfMonth
     and oh.statusupdate < add_months(dFirstOfMonth,1);

  select nvl(sum(sp.weight),0) weightshpd
    into dtlWeightShpd
    from shippingplate sp, orderhdr oh
   where oh.fromfacility = in_facility
     and oh.orderstatus = '9'
     and oh.orderid = sp.orderid
     and oh.shipid = sp.shipid
     and sp.type in ('F','P')
     and sp.status = 'SH'
     and oh.statusupdate >= dFirstOfMonth
     and oh.statusupdate < add_months(dFirstOfMonth,1);

  if sql%rowcount = 0 or dtlWeightShpd is null then
  	dtlWeightShpd := 0;
  end if;
  
  select sum(billedamt)
    into dtlInOutCharges
    from revenuedtlrptview
   where facility = in_facility
     and invdate >= dFirstOfMonth
     and invdate < add_months(dFirstOfMonth,1)
     and revtype in('Accessorial','Outbound','Receipt','Freight','Rcpt Hndlg','Sml Pack');

  if sql%rowcount = 0 or dtlInOutCharges is null then
  	dtlInOutCharges := 0.0;
  end if;
 
  select sum(billedamt)
    into dtlStoreCharges
    from revenuedtlrptview
   where facility = in_facility
     and invdate >= dFirstOfMonth
     and invdate < add_months(dFirstOfMonth,1)
     and revtype in('Renewal','Rcpt Store','Rnwl Store');

  if sql%rowcount = 0 or dtlStoreCharges is null then
  	dtlStoreCharges := 0.0;
  end if;
 
  select sum(billedamt)
    into dtlOtherCharges
    from revenuedtlrptview
   where facility = in_facility
     and invdate >= dFirstOfMonth
     and invdate < add_months(dFirstOfMonth,1)
     and revtype in('Credit','Misc.','Admin','Cartage','Labor','Misc','Pallet');

  if sql%rowcount = 0 or dtlOtherCharges is null then
  	dtlOtherCharges := 0.0;
  end if;
 
  insert into transanalysis values(numSessionId, sMonth, dtlReceipts, dtlWeightRcvd, dtlShipments, dtlWeightShpd, dtlInOutCharges, dtlStoreCharges, dtlOtherCharges, dtlPerformance, sysdate);
  
  iMonth := iMonth + 1;
  EXIT WHEN iMonth > 12;
end loop;

open ta_cursor for
select *
   from transanalysis
  where sessionid = numSessionId
  order by month;

end transanalysisPROC;
/
show errors package ztranspkg;
show errors procedure transanalysisPROC;
show errors package body ztranspkg;
exit;
