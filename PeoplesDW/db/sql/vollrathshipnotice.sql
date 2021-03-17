--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
strMsg varchar2(255);
facility varchar2(3);

begin

ziem.impexp_request('E',null,'17200',
    'Vollrath Ship Notification',null,'NOW',
    0,3449254,1,'BRIANB',null,null,
    null,'ALL','ALL',
    null,null,
    out_errorno,out_msg);

if out_errorno <> 0 then
  zut.prt('out_errorno: ' || out_errorno);
  zut.prt('out_msg: ' || substr(out_msg,1,200));
  zms.log_msg('IMPEXP', null, null, out_msg, 'E', 'SCRIPT', strMsg);
end if;

end;
/
exit;
