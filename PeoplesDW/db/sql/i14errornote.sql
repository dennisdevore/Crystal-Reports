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
'HP', -- custid
'I14 Error Notification', -- formatid
'C:\dummyfile', -- importfilepath
'NOW', -- when
0, -- loadno
0, -- orderid
0, -- shipid
'ZTEST', -- userid
null, -- tablename
null,  --columnname
'importfileid', --filtercolumnname
null, -- company
null, -- warehouse
null, -- begindatestr
null, -- enddatestr
out_errorno,
out_msg);

if out_errorno != 0 then
  zms.log_msg('ImpExp', '', 'HP',
    'Request Export: ' || out_msg,
    'E', 'IMPEXP', strMsg);
end if;

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));


end;
/
exit;