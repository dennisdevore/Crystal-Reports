--
-- $Id$
--
set serveroutput on;

declare
lpid varchar2(15);
out_errno integer;
out_msg varchar2(255);
out_action varchar2(1);

cursor curPlate(in_lpid varchar2) is
  select *
	 from plate
   where lpid = in_lpid;
pl curPlate%rowtype;

begin


lpid := '&1';
pl := null;
open curPlate(lpid);
fetch curPLate into pl;
close curPlate;
if pl.lpid is null then
  zut.prt('plate not found');
  return;
end if;

zfmt.verify_format(pl.custid,pl.item,'S',pl.serialnumber,
  out_action,out_errno,out_msg);
zut.prt('serial ' || out_errno || ' ' || out_msg);
zfmt.verify_format(pl.custid,pl.item,'1',pl.useritem1,
  out_action,out_errno,out_msg);
zut.prt('cam ' || out_errno || ' ' || out_msg);
verify_format(pl.custid,pl.item,'S',pl.serialnumber,
  out_action,out_errno,out_msg);
zut.prt('serial ' || out_errno || ' ' || out_msg);
verify_format(pl.custid,pl.item,'1',pl.useritem1,
  out_action,out_errno,out_msg);
zut.prt('cam ' || out_errno || ' ' || out_msg);
exception when others then
  zut.prt('exception');
  zut.prt(sqlerrm);
end;
/
exit;
