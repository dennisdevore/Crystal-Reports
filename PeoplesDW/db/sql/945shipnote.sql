--
-- $Id$
--
set serveroutput on;
declare
out_errorno integer;
out_msg varchar2(255);
facility varchar2(3);
strMsg varchar2(255);

begin

out_msg := '';
out_errorno := 0;

ziem.impexp_request(
'E', -- reqtype
null, -- facility
'ONE', -- custid
'945 Test', -- formatid
null, -- importfilepath
'NOW', -- when
null, -- loadno
537, -- orderid
1, -- shipid
'ZTEST', --userid
null, -- tablename
null,  --columnname
null, --filtercolumnname
null, -- company
null, -- warehouse
null, -- begindatestr
null, -- enddatestr
out_errorno,
out_msg);

if out_errorno != 0 then
  zms.log_msg('ImpExp', '', 'HS',
    'Request Export: ' || out_msg,
    'E', 'IMPEXP', strMsg);
end if;

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));


end;
/
exit;
