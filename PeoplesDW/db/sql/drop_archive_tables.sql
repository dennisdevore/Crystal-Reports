--
-- $Id$
--
set serveroutput on size 200000;

declare

out_msg varchar2(255);
out_errorno integer;

begin

out_msg :=  null;

zarc.dropArchiveTables(out_errorno ,out_msg );

zut.prt('msg: ' || out_msg);
zut.prt('errorno: ' || out_errorno);

end;
/
exit;
