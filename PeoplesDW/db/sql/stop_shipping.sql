--
-- $Id$
--
set serveroutput on
declare
  CURSOR C_INVD(in_invoice number)
  IS
    SELECT rowid, billstatus, activity
      FROM invoicedtl
     WHERE invoice = in_invoice;

errmsg varchar2(400);
rc integer;
testid  varchar2(8);

uom varchar2(4);
rate number;

orderid number;
shipid number;
cartonid varchar2(15);


begin
        dbms_output.enable(1000000);


    zmnq.send_shipping_msg(-1,1,'','','','',errmsg);

exception when others then
          zut.prt('Exception');

end;
/
