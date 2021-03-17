--
-- $Id$
--
set serveroutput on;
declare
out_msg varchar2(255);
out_errorno number(4);
in_msg varchar2(255);
in_errorno number(4);
in_custid varchar2(10);
in_func varchar2(10);
out_orderid number(7);
out_shipid number(2);

begin

out_msg := '';

in_custid := 'HP';
in_errorno := 100;
in_msg := 'input msg';

zcf.create_func('HP','Class_To_Warehouse',out_errorno,out_msg);
zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || out_msg);

end;
/
--exit;
