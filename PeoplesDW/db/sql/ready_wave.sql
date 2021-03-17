--
-- $Id$
--
set serveroutput on;
declare
in_waveno number(7);
out_msg varchar2(255);
facility varchar2(3);
userid varchar2(12);
cnt integer;
picktype varchar2(4);
taskpriority varchar2(1);

begin

in_waveno := &&1;

out_msg := '';
picktype := null;
taskpriority := null;

zwv.ready_wave
  (in_waveno, '1', 'ZC', 'ZBACK' , out_msg);

zut.prt('out_msg: ' || out_msg);

end;
/
exit;
