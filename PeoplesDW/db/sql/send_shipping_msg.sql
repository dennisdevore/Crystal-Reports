--
-- $Id$
--
set serveroutput on

declare
orderid orderhdr.orderid%type;
shipid orderhdr.shipid%type;
printer varchar2(255);
report varchar2(255);
cartonid shippingplate.lpid%type;
email_addresses customer_aux.packlist_email_addresses;
errmsg varchar2(255);

begin

  orderid := 8926490;
  shipid := 1;
--  printer := 'PrimoPDF';
  printer := '\\DSK1\hp psc 2170 series';
  report := 'C:\Synapse\Reports\Shipping\generic_packlist(ZSHPPCKLST).rpt';
  cartonid := '';
  email_addresses := null;
  errmsg := '';

  zmnq.send_shipping_msg(orderid,shipid,printer,report,cartonid,email_addresses,errmsg);
  zut.prt('errmsg is ' || errmsg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
