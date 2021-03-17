create or replace package body alps.replenish as
--
-- $Id$
--

MSG_ITEM_LIMIT          constant integer := 7;
REPLENISH_DEFAULT_QUEUE constant varchar2(9) := 'replenish';

procedure send_replenish_msg
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cursor curQ is
  select upper(abbrev) as abbrev
    from ReplenishRequestQueues
   where code = in_facility;
q curQ%rowtype;

cursor curDefaultQ is
  select upper(abbrev) as abbrev
    from ReplenishRequestQueues
   order by abbrev;

sendstatus integer;
correlation varchar2(32) := 'REPLENISH';
l_msg varchar2(400);
msg varchar2(40);


begin

out_msg := null;
out_errorno := 0;

open curQ;
fetch curQ into q;
if curQ%found then
  correlation := correlation || q.abbrev;
else
  open curDefaultQ;
  fetch curDefaultQ into q;
  if curDefaultQ%found then
    correlation := correlation || q.abbrev;
  end if;
  close curDefaultQ;
end if;
close curQ;

--zms.log_msg('SRM', in_facility, null, 'corre = ' || correlation, 'T', in_userid, msg);


l_msg := nvl(rtrim(in_reqtype),'(none)') || chr(9) ||
         nvl(rtrim(in_facility),'(none)') || chr(9) ||
         nvl(rtrim(in_custid),'(none)') || chr(9) ||
         nvl(rtrim(in_item),'(none)') || chr(9) ||
         nvl(rtrim(in_locid),'(none)') || chr(9) ||
         nvl(rtrim(in_userid),'(none)') || chr(9) ||
         nvl(rtrim(in_trace),'(none)') || chr(9);

sendstatus := zqm.send_commit(REPLENISH_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);

if sendstatus != 1 then
  out_msg := 'Send error ' || sendstatus;
  out_errorno := 1;
  return;
end if;

out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zrpsrm ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end send_replenish_msg;

procedure send_replenish_msg_no_commit
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_custid            in varchar2
,in_item              in varchar2
,in_locid             in varchar2
,in_userid            in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cursor curQ is
  select upper(abbrev) as abbrev
    from ReplenishRequestQueues
   where code = in_facility;
q curQ%rowtype;

cursor curDefaultQ is
  select upper(abbrev) as abbrev
    from ReplenishRequestQueues
   order by abbrev;

sendstatus integer;
correlation varchar2(32) := 'REPLENISH';
l_msg varchar2(400);
msg varchar2(40);


begin

out_msg := null;
out_errorno := 0;

open curQ;
fetch curQ into q;
if curQ%found then
  correlation := correlation || q.abbrev;
else
  open curDefaultQ;
  fetch curDefaultQ into q;
  if curDefaultQ%found then
    correlation := correlation || q.abbrev;
  end if;
  close curDefaultQ;
end if;
close curQ;

--zms.log_msg('SRM', in_facility, null, 'corre = ' || correlation, 'T', in_userid, msg);


l_msg := nvl(rtrim(in_reqtype),'(none)') || chr(9) ||
         nvl(rtrim(in_facility),'(none)') || chr(9) ||
         nvl(rtrim(in_custid),'(none)') || chr(9) ||
         nvl(rtrim(in_item),'(none)') || chr(9) ||
         nvl(rtrim(in_locid),'(none)') || chr(9) ||
         nvl(rtrim(in_userid),'(none)') || chr(9) ||
         nvl(rtrim(in_trace),'(none)') || chr(9);

sendstatus := zqm.send(REPLENISH_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);

if sendstatus != 1 then
  out_msg := 'Send error ' || sendstatus;
  out_errorno := 1;
  return;
end if;

out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zrpsrmnc ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end send_replenish_msg_no_commit;

procedure recv_replenish_msg
(in_correlation       in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_custid           in out varchar2
,out_item             in out varchar2
,out_locid            in out varchar2
,out_userid           in out varchar2
,out_trace            in out varchar2
,out_errorno          in out number
,out_msg              in out varchar2) is

cntItem integer;
rc integer;
strText varchar2(255);
l_msg varchar2(400);
trans varchar2(20);
msg varchar2(40);

begin

out_msg := '';
out_errorno := 0;

--zms.log_msg('RRM', '107', null, 'cor = ' || in_correlation, 'T', 'USR', msg);

rc := zqm.receive_commit(REPLENISH_DEFAULT_QUEUE,in_correlation,null,zqm.DQ_REMOVE, trans, l_msg);

commit;

if rc != 1 then
  out_errorno := 1;
  out_msg := 'Cannot receive_message from ' || in_correlation;
  return;
end if;

cntItem := 0;
while (cntItem < MSG_ITEM_LIMIT)
loop
  cntItem := cntItem + 1;
  strText := zqm.get_field(l_msg,cntItem);

  if cntItem = 1 then
    out_reqtype := strText;
  elsif cntItem = 2 then
    out_facility := strText;
  elsif cntItem = 3 then
    out_custid := strText;
  elsif cntItem = 4 then
    out_item := strText;
  elsif cntItem = 5 then
    out_locid := strText;
  elsif cntItem = 6 then
    out_userid := strText;
  elsif cntItem = 7 then
    out_trace := strText;
  end if;

end loop;

out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zrprrm ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end recv_replenish_msg;

end replenish;
/
show error package body replenish;
exit;
