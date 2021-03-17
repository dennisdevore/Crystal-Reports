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
'ALL', -- custid
'TMSExport', -- formatid
null, -- importfilepath
'NOW', -- when
null, -- loadno
null, -- orderid
null, -- shipid
null, --userid
'webertms_hdr', -- tablename
'LastTMS',  --columnname
'ORDERDATE', --filtercolumnname
'ALL', -- company
'ALL', -- warehouse
--'19990101000000', -- begindatestr
--'20011231000000', -- enddatestr
null, -- begindatestr
null, -- enddatestr

out_errorno,
out_msg);

if out_errorno != 0 then
  zms.log_msg('ImpExp', '', 'ALL',
    'Request Export: ' || out_msg,
    'E', 'IMPEXP', strMsg);
end if;

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || substr(out_msg,1,200));


end;
/
exit;