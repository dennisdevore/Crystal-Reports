create or replace package body alps.zvicsmsg as
--
-- $Id$
--

QUEUENAME       CONSTANT    varchar2(4) := 'vics';
TIMEOUT         CONSTANT    integer := 10;
VICS_ITEM_LIMIT CONSTANT    integer := 6;

procedure send_vics_bol_request
(in_userid   in varchar2
,in_loadno   in number
,in_orderid  in number
,in_shipid   in number
,in_reqtype  in varchar2
,in_printer  in varchar2
,out_errorno out number
,out_msg     out varchar2
)
is PRAGMA AUTONOMOUS_TRANSACTION;
   status number;
   msgno varchar2(10);
   l_msg varchar2(1000);
begin

l_msg :=  nvl(rtrim(in_userid),'(none)') || chr(9) ||
          nvl(rtrim(to_char(in_loadno)),'0') || chr(9) ||
          nvl(rtrim(to_char(in_orderid)),'0') || chr(9) ||
          nvl(rtrim(to_char(in_shipid)),'0')|| chr(9) ||
          nvl(rtrim(in_reqtype),'NONE') || chr(9) ||
          nvl(rtrim(in_printer),'NONE') || chr(9);

status := zqm.send(QUEUENAME,'MSG',l_msg,1,queuename);
commit;

if (status != 1) then
  out_errorno := 101;
  out_msg := 'Send error ' || status;
else
  out_errorno := 0;
  out_msg := 'OKAY';
end if;

exception when OTHERS then
  out_errorno := 100;
  out_msg := substr(sqlerrm, 1, 80);
  rollback;
end send_vics_bol_request;

procedure get_vics_bol_request
(out_userid           in out varchar2
,out_loadno           in out varchar2
,out_orderid          in out varchar2
,out_shipid           in out varchar2
,out_reqtype          in out varchar2
,out_printer          in out varchar2
,out_errorno          in out varchar2
,out_msg              in out varchar2
)
is PRAGMA AUTONOMOUS_TRANSACTION;

cntItem integer;
rc integer;
strText varchar2(255);
trans varchar2(20);
msg varchar2(1000);

begin

out_msg := '';
out_errorno := '0';
out_userid := 'NONE';
out_loadno := '0';
out_orderid := '0';
out_shipid := '0';
out_reqtype := 'NONE';
out_printer := 'NONE';

rc := zqm.receive(QUEUENAME,null,
                  TIMEOUT,zqm.DQ_REMOVE, trans, msg);
commit;
if rc = -1 then
  out_reqtype := 'TIME';
  out_msg := 'TIMEOUT';
  return;
end if;

if rc != 1 then
  out_errorno := '1';
  out_msg := 'Cannot receive_message from ' || QUEUENAME || ' (' || rc || ')';
  return;
end if;

out_userid := nvl(zqm.get_field(msg,1),'(none)');
out_loadno := nvl(zqm.get_field(msg,2),'(none)');
out_orderid := nvl(zqm.get_field(msg,3),'(none)');
out_shipid := nvl(zqm.get_field(msg,4),'(none)');
out_reqtype := nvl(zqm.get_field(msg,5),'(none)');
out_printer := nvl(zqm.get_field(msg,6),'(none)');

out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'ziemrm ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
  rollback;
end get_vics_bol_request;

end zvicsmsg;
/
show errors package body zvicsmsg;
--exit;
