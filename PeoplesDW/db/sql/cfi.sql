--
-- $Id: cfi.sql 1 2005-05-26 12:20:03Z ed $
--
set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
out_movement_code varchar2(255);

begin

out_msg := 'DEBUG';
out_errorno := 0;

zld.check_for_interface
(1947
,0
,0
,'818'
,'REGORDTYPES'
,'REGI44SNFMT'
,'RETORDTYPES'
,'RETI9GIFMT'
,'SYNAPSE',
out_msg
);

zut.prt(out_msg);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
