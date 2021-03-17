--
-- $Id: cfi.sql 1 2005-05-26 12:20:03Z ed $
--
set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);
l_loadno loads.loadno%type;
l_orderid orderhdr.orderid%type;
l_shipid orderhdr.shipid%type;
l_fromfacility orderhdr.fromfacility%type;
l_tofacility orderhdr.tofacility%type;
l_facility orderhdr.tofacility%type;
l_ordertype orderhdr.ordertype%type;
l_custid orderhdr.custid%type;
l_custname customer.name%type;

begin

l_orderid := &&1;
l_shipid := &&2;

select loadno, fromfacility, tofacility, ordertype, custid
  into l_loadno, l_fromfacility, l_tofacility, l_ordertype, l_custid
  from orderhdr
 where orderid = l_orderid
   and shipid = l_shipid;

if nvl(l_loadno,0) != 0 then
  l_orderid := 0;
  l_shipid := 0;
end if;

if l_ordertype = 'O' then
  l_facility := l_fromfacility;
else
  l_facility := l_tofacility;
end if;

select name
  into l_custname
  from customer
 where custid = l_custid;
zut.prt(l_custid || ' ' || l_custname);

out_msg := 'DEBUG';
out_errorno := 0;

zut.prt(l_loadno || ' ' || l_orderid || '/' || l_shipid || ' ' ||
        l_facility || ' ' || l_ordertype);

zld.check_for_interface
(l_loadno
,l_orderid
,l_shipid
,'IDR'
,'REGORDTYPES'
,'REGI44SNFMT'
,'RETORDTYPES'
,'RETI9GIFMT'
,'SYNAPSE',
out_msg
);

zut.prt(out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
