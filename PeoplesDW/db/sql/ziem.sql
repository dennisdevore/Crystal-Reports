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
ziem.impexp_request('E',null,'HP',
    'Stock Status',
    null,
    'NOW',
    0,0,0,'BRIANB',null,null,null,out_errorno,out_msg);
*/
ziem.impexp_request('E',null,'HP',
    'Shipping Summary',null,'NOW',
    0,0,0,'BRIANB','customer','lastshipsum',
    'dateshipped',out_errorno,out_msg);
zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));

end;
/
--exit;