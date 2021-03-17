--
-- $Id$
--
set serveroutput on;

declare

out_errorno integer;

begin

zmi3.get_cto_sto_prefix('HP','D720123',
  out_errorno);
zut.prt(out_errorno);

zmi3.get_cto_sto_prefix('HP','C',
  out_errorno);
zut.prt(out_errorno);

zmi3.get_cto_sto_prefix('HP','C123B#ABA',
  out_errorno);
zut.prt(out_errorno);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
