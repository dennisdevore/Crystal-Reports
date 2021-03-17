--
-- $Id$
--
set serveroutput on;
declare
out_msg varchar2(255);
out_pickqty number(12,6);
lo location%rowtype;

begin
out_msg := '';
zut.prt('execute');
zbut.translate_uom('1150','BR01',1,
                'CR','CR',out_pickqty,out_msg);
zut.prt('out_pickqty: ' || out_pickqty);
if mod(out_pickqty,1) != 0 then
  zut.prt('not an even uom');
else
  zut.prt('okay uom');
end if;
zut.prt('out_msg: ' || out_msg);
end;
/
