create or replace PACKAGE BODY alps.zordersummary
IS
--
-- $Id$
--

PROCEDURE get_default_from_to_dates
(out_2daysago IN OUT varchar2
,out_yesterday IN OUT varchar2
,out_today IN OUT varchar2
,out_tomorrow IN OUT varchar2
) is

strCurrTime varchar2(4);
intOffset integer;

begin

select to_char(sysdate, 'hh24mi')
  into strCurrTime
  from dual;
if strCurrTime >= '0300' then
  intOffset := 0;
else
  intOffset := 1;
end if;

out_2daysago := to_char(trunc(sysdate) - intOffset - 2,'mm/dd/yy');
out_yesterday := to_char(trunc(sysdate) - intOffset - 1,'mm/dd/yy');
out_today := to_char(trunc(sysdate) - intOffset,'mm/dd/yy');
out_tomorrow := to_char(trunc(sysdate) - intOffset + 1, 'mm/dd/yy');

exception when others then
  out_yesterday := '';
  out_today := '';
  out_tomorrow := '';
end get_default_from_to_dates;

PROCEDURE upgrade_delivery_service
(in_orderid IN number
,in_shipid IN number
,in_userid IN varchar2
,out_errorno IN OUT number
,out_msg IN OUT varchar2)
is

cursor curOrderHdr is
  select orderstatus,
         priority,
         carrier,
         deliveryservice
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderHdr%rowtype;

cursor curUpgradeCode(in_carrier in varchar2, in_servicecode in varchar2) is
  select upgradecode
    from carrierservicecodes
   where carrier = in_carrier
     and servicecode = in_servicecode;
uc curUpgradeCode%rowtype;

cursor curMultiShipCode(in_carrier in varchar2, in_servicecode in varchar2) is
  select multishipcode
    from carrierservicecodes
   where carrier = in_carrier
     and servicecode = in_servicecode;
mc curMultiShipCode%rowtype;

begin

out_errorno := 0;
out_msg := '';

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;
if oh.orderstatus is null then
  out_msg := 'Order not found: ' || in_orderid || '-' || in_shipid;
  out_errorno := -1;
  return;
end if;

if oh.orderstatus > '7' then
  out_msg := 'Invalid Order Status: ' || in_orderid || '-' || in_shipid
    || ' Status: ' || oh.orderstatus;
  out_errorno := -2;
  return;
end if;

uc := null;
open curUpgradeCode(oh.carrier,oh.deliveryservice);
fetch curUpgradeCode into uc;
close curUpgradeCode;
if uc.upgradecode is null then
  out_msg := 'Cannot determine upgrade: ' || in_orderid || '-' || in_shipid
    || ' Current Service: ' || oh.deliveryservice;
  out_errorno := -4;
  return;
end if;

mc := null;
open curMultiShipCode(oh.carrier,uc.upgradecode);
fetch curMultiShipCode into mc;
close curMultiShipCode;
if mc.MultiShipCode is null then
  out_msg := 'Cannot determine multiship code: ' || in_orderid || '-' || in_shipid
    || ' Upgraded Service: ' || uc.upgradecode;
  out_errorno := -5;
  return;
end if;

if oh.priority != 'E' then
  oh.priority := '0';
end if;

update orderhdr
   set priority = oh.priority,
       deliveryservice = uc.upgradecode,
       lastuser = in_userid,
       lastupdate = sysdate
 where orderid = in_orderid
   and shipid = in_shipid;

update multishiphdr
   set carriercode = mc.multishipcode
 where orderid = in_orderid
   and shipid = in_shipid;

update tasks
   set priority = '2'
 where priority != '0'
   and orderid = in_orderid
   and shipid = in_shipid;

out_errorno := 0;
out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := sqlerrm;
end upgrade_delivery_service;

end zordersummary;
/
show errors package body zordersummary;
exit;
