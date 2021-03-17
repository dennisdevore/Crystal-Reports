--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
begin

out_msg := '';
out_errorno := 0;

ziem.impexp_request('E',null,'HP',
    'Receipt Notification',null,'NOW',
    0,0,0,'BRIANB','customer','lastrcptnote',
    'arrivaldate',null,out_errorno,out_msg);
zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));

end;
/
exit;