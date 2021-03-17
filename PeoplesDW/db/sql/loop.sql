--
-- $Id: auditorderhdr.sql 1 2005-05-26 12:20:03Z ed $
--
set serveroutput on;

declare
notfound boolean;
totcount integer;
okycount integer;
errcount integer;
out_errno pls_integer;
out_msg varchar2(255);

begin

totcount := 0;
okycount := 0;
errcount := 0;

for oh in (select orderid,shipid,loadno
             from orderhdr
            where wave = 124858)
loop

  totcount := totcount + 1;
  zut.prt(oh.orderid || '-' || oh.shipid || ' ' || oh.loadno);
  
end loop;

zut.prt('totcount: ' || totcount);
zut.prt('okycount: ' || okycount);
zut.prt('errcount: ' || errcount);

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
