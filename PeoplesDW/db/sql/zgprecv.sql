--
-- $Id$
--
set serveroutput on;
declare
oh orderhdr%rowtype;
ld loads%rowtype;
ls loadstop%rowtype;
ss loadstopship%rowtype;
out_msg varchar2(255);
facility varchar2(3);
userid varchar2(12);
out_errorno integer;


begin

zut.prt('update order');
update orderhdr
set loadno = 0, orderstatus = '1'
where orderid = 21;

zut.prt('set variables');
facility := '001';
userid := 'ZTEST';
oh.orderid := 21;
oh.shipid := 1;
ld.carrier := 'YEL';
ld.stageloc := '12345';
ld.doorloc := 'DOOR01';
ld.loadno := 141;
ls.stopno := 1;
ss.shipno := 1;
out_msg := '';

zut.prt('exec zgp');
zgp.pick_request('COMORD',null,null,0,1,1,
  null,null,0,null,null,out_errorno,out_msg);

zut.prt('out_errorno: ' || out_errorno);
zut.prt('out_msg: ' || out_msg);

end;
/