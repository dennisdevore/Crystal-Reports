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
zoe.check_for_export_procs('HP','C:\OHLTEST\IMPORT\INCOMING\DEMAND ORDER 6-22','BRIANB',
    out_errorno,out_msg);

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));

end;
/
exit;