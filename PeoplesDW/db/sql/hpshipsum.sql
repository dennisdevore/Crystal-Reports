--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
facility varchar2(3);

begin

out_msg := '';
out_errorno := 0;

update customer
   set lastshipsum = '01-JUL-1999'
 where custid = 'HP';
commit;

ziem.impexp_request('E',null,'HP',
    'Shipping Summary',null,'NOW',
    0,0,0,'BRIANB','customer','lastshipsum',
    'dateshipped',null,out_errorno,out_msg);

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));


end;
/
exit;