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
    'Error Notification','C:\OHLTEST\IMPORT\INCOMING\DEMANDORDER 6-22','NOW',
    0,0,0,'BRIANB',null,null,'importfileid',null,
    out_errorno,out_msg);

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));

end;
/
exit;