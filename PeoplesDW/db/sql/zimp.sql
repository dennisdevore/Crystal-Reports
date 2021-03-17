--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
facility varchar2(3);
userid varchar2(12);
cnt integer;
picktype varchar2(4);
taskpriority varchar2(1);
sb subtasks%rowtype;
out_orderid orderhdr.orderid%type;
out_shipid orderhdr.shipid%type;
in_func char(1);

begin
out_orderid := 0;
out_shipid := 0;
out_msg := '';
out_errorno := 0;
in_func := 'A';
zut.prt('call zimp');
/*
zimp.import_order_header
(in_func
,'AAAAA'
,'O'
,to_date('200007011234', 'yyyymmddhh24mi')
,to_date('200007021234', 'yyyymmddhh24mi')
,'PO'
,'RMA'
,'001'
,'002'
,'SHIPTO'
,'BOL'
,'1'
,'SHIPPER'
,'CONSIGNEE'
,'X'
,'CARRIER'
,'REFERENCE'
,'X'
,'SHIPTONAME'
,'SHIPTOCONTACT'
,'SHIPTOADDR1'
,'SHIPTOADDR2'
,'SHIPTOCITY'
,'ST'
,'11111-0111'
,'USA'
,'888-123-1010'
,'888-123-1019'
,'SHIPTO@EMAIL'
,'BILLTONAME'
,'BILLTOCONTACT'
,'BILLTOADDR1'
,'BILLTOADDR2'
,'BILLTOCITY'
,'BS'
,'11111-0111'
,'USA'
,'888-123-1010'
,'888-123-1019'
,'BILLTO@EMAIL'
,out_orderid
,out_shipid
,out_errorno
,out_msg
);
*/
zimp.update_confirm_date('HP','H202029',sysdate,'XXX',
  out_errorno, out_msg);

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));

--rollback;
end;
/
--exit;