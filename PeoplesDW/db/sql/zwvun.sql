--
-- $Id$
--
set serveroutput on;
declare
out_waveno number(7);
out_msg varchar2(255);
facility varchar2(3);
userid varchar2(12);
cnt integer;
picktype varchar2(4);
taskpriority varchar2(1);

begin

out_msg := '';
picktype := null;
taskpriority := null;

zwv.release_wave
  (485, '1', 'CH', taskpriority, picktype, 'ZBRIAN'
  ,out_msg);

zut.prt('out_msg: ' || out_msg);

end;
/
--exit;
