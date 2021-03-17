--
-- $Id$
--
set serveroutput on;

declare
out_abbrev varchar2(12);
out_descr varchar2(32);
out_whse varchar2(12);
out_regular_whse varchar2(12);
out_returns_whse varchar2(12);
out_errorno integer;
out_msg varchar2(255);
in_viewnum integer;

begin


in_viewnum := &viewnum;
zim5.end_i44_rcpt_note(upper('&custid'),in_viewnum,out_errorno,out_msg);
zut.prt('out_errorno is >' || out_errorno || '<');
zut.prt('out_msg is >' || out_msg || '<');
exception when others then
  zut.prt('others...');

  zut.prt(sqlerrm);
end;
/
--exit;
