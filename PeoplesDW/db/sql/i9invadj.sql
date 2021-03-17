--
-- $Id$
--
set serveroutput on;
declare

out_errorno integer;
out_msg varchar2(255);
facility varchar2(3);
strMsg varchar2(255);
parm invadjactivity%rowtype;
cntadj integer;

cursor curInvAdj is
  select rowid
    from invadjactivity
   where lpid = parm.lpid
     and whenoccurred = parm.whenoccurred;

begin

parm.lpid := '914766766766766';
parm.whenoccurred := to_date('20010412221427','yyyymmddhh24miss');

out_msg := '';
out_errorno := 0;
cntadj := 0;

for xx in curInvAdj
loop
  ziem.impexp_request(
  'E', -- reqtype
  null, -- facility
  'HP', -- custid
  'I9 Inventory Adjustment', -- formatid
  null, -- importfilepath
  'NOW', -- when
  0, -- loadno
  0, -- orderid
  0, -- shipid
  xx.rowid, -- rowid
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
    zms.log_msg('ImpExp', '', 'CCC',
      'Request Export: ' || out_msg,
      'E', 'IMPEXP', strMsg);
  end if;
  zut.prt('out_errorno: ' || out_errorno);
  zut.prt('out_msg: ' || substr(out_msg,1,200));
  cntadj := cntadj + 1;
end loop;

if cntadj = 0 then
  zut.prt('no adjustment rows found');
end if;

end;
/
exit;                                 