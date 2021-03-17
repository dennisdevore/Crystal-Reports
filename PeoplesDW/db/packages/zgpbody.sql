create or replace package body alps.genpicks as
--
-- $Id$
--

GP_ITEM_LIMIT           constant       integer := 13;
GENPICKS_DEFAULT_QUEUE  CONSTANT       varchar2(4) := 'pick';
USER_DEFAULT_QUEUE      CONSTANT       varchar2(5) := 'userq';


procedure pick_request
(in_reqtype           in varchar2
,in_facility          in varchar2
,in_userid            in varchar2
,in_wave              in number
,in_orderid           in number
,in_shipid            in number
,in_item              in varchar2
,in_lotnumber         in varchar2
,in_qty               in number
,in_taskpriority      in varchar2
,in_picktype          in varchar2
,in_trace             in varchar2
,out_errorno          in out number
,out_msg              in out varchar2) IS


cursor curOrderhdr is
  select nvl(fromfacility,tofacility) as fromfacility, custid
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;
oh curOrderhdr%rowtype;

cursor curOrderhdrWave is
  select nvl(fromfacility,tofacility) as fromfacility, custid
    from orderhdr
   where wave = in_wave;

cursor c_sid is
   select sys_context('USERENV','SESSIONID')
      from dual;

sendstatus integer;
recvstatus integer;
dummy varchar2(256);
correlation varchar2(32) := 'PICK';
sid number := null;
msg varchar2(400);
l_msg varchar2(400);
trans varchar2(20);
queabbrev PickRequestQueues.abbrev%type;


FUNCTION find_queue(in_facility varchar2, in_custid varchar2)
return varchar2
IS
CURSOR C_Q(in_fac varchar2, in_custid varchar2)
IS
SELECT abbrev
  FROM PickRequestQueues
 WHERE code = upper(in_custid)||'/'||upper(in_fac);

CURSOR C_QDefault
IS
SELECT abbrev
  FROM PickRequestQueues
 order by abbrev;

que C_Q%rowtype;

BEGIN

    if in_facility is not null and in_custid is not null then
        que := null;
        OPEN C_Q(in_facility, in_custid);
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;
    if in_custid is not null then
        que := null;
        OPEN C_Q('*', in_custid);
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;
    if in_facility is not null then
        que := null;
        OPEN C_Q(in_facility, '*');
        FETCH C_Q into que;
        CLOSE C_Q;
        if que.abbrev is not null then
            return que.abbrev;
        end if;
    end if;

    OPEN C_QDefault;
    FETCH C_QDefault into que;
    CLOSE C_QDefault;
    
    if que.abbrev is not null then
        return que.abbrev;
    end if;
    
    return null;
    
END find_queue;

begin

out_msg := null;
out_errorno := 0;

oh := null;
open curOrderHdr;
fetch curOrderHdr into oh;
close curOrderHdr;


if rtrim(oh.fromfacility) is null then
  open curOrderHdrWave;
  fetch curOrderHdrWave into oh;
  close curOrderHdrWave;
end if;

if rtrim(in_facility) is not null then
  oh.fromfacility := in_facility;
end if;

queabbrev := find_queue(oh.fromfacility, oh.custid);
if (queabbrev is not null) then
  correlation := correlation || queabbrev;
end if;

open c_sid;
fetch c_sid into sid;
close c_sid;

l_msg := (nvl(rtrim(in_reqtype),'(none)')) || chr(9) ||
       (nvl(rtrim(oh.fromfacility),'(none)')) || chr(9) ||
       (nvl(rtrim(in_userid),'(none)')) || chr(9) ||
       (nvl(rtrim(to_char(in_wave)),'0')) || chr(9) ||
       (nvl(rtrim(to_char(in_orderid)),'0')) || chr(9) ||
       (nvl(rtrim(to_char(in_shipid)),'0')) || chr(9) ||
       (nvl(rtrim(in_item),'(none)')) || chr(9) ||
       (nvl(rtrim(in_lotnumber),'(none)')) || chr(9) ||
       (nvl(rtrim(to_char(in_qty)),'0.00')) || chr(9) ||
       (nvl(rtrim(in_taskpriority),'(none)')) || chr(9) ||
       (nvl(rtrim(in_picktype),'(none)')) || chr(9) ||
       (nvl(rtrim(in_trace),'(none)')) || chr(9) ||
       (nvl(rtrim(sid),'0')) || chr(9);
--zms.log_msg('PR', in_facility, null, 'cor = ' || correlation, 'T', in_userid, msg);
--zms.log_msg('PR', in_facility, null, l_msg, 'T', in_userid, msg);


if (in_reqtype <> 'GENSRT') or (in_picktype = 'MatIssue') or (in_reqtype = 'AIWREL') or (in_reqtype = 'MASSMAN') then
  sendstatus := zqm.send_commit(GENPICKS_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
else
  sendstatus := zqm.send(GENPICKS_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
end if;

if sendstatus != 1 then -- zqm.send returns 1 for success
  out_msg := 'Send error ' || sendstatus;
  out_errorno := 1;
  return;
end if;
--zms.log_msg('PR', in_facility, null, 'send status ' || sendstatus, 'T', in_userid, msg);

if (in_picktype = 'MatIssue') or (in_reqtype = 'AIWREL') or (in_reqtype = 'MASSMAN') then
  recvstatus := zqm.receive_commit(USER_DEFAULT_QUEUE,nvl(rtrim(in_userid),'(none)')||nvl(rtrim(sid),'0'),
                                   null,zqm.DQ_REMOVE, trans, l_msg);

  if (recvstatus != 1) then
    out_msg := 'Recv error ' || recvstatus;
    out_errorno := 2;
    return;
  end if;
  out_msg := zqm.get_field(l_msg,1);
else
  out_msg := 'OKAY';
end if;

exception when OTHERS then
  out_msg := 'zgppr ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end pick_request;

procedure receive_msg
(in_correlation       in varchar2
,out_reqtype          in out varchar2
,out_facility         in out varchar2
,out_userid           in out varchar2
,out_wave             in out number
,out_orderid          in out number
,out_shipid           in out number
,out_item             in out varchar2
,out_lotnumber        in out varchar2
,out_qty              in out number
,out_taskpriority     in out varchar2
,out_picktype         in out varchar2
,out_trace            in out varchar2
,out_sid              in out number
,out_errorno          in out number
,out_msg              in out varchar2) 
IS
cntItem integer;
rc integer;
strText varchar2(255);
trans varchar2(20);
msg varchar2(400);
begin

out_msg := '';
out_errorno := 0;

rc := zqm.receive_commit(GENPICKS_DEFAULT_QUEUE,in_correlation,null,zqm.DQ_REMOVE, trans, msg);

if rc != 1 then
  out_errorno := 1;
  out_msg := 'Cannot receive_message from genpicks ' || in_correlation;
  return;
end if;

cntItem := 0;
while (cntItem < GP_ITEM_LIMIT)
loop
  cntItem := cntItem + 1;
  strText := zqm.get_field(msg,cntItem);
  if strText is not null then 
    if cntItem = 1 then                   
      out_reqtype := strText;             
    elsif cntItem = 2 then                
      out_facility := strText;            
    elsif cntItem = 3 then                
      out_userid := strText;              
    elsif cntItem = 4 then                
      out_wave := to_number(strText);     
    elsif cntItem = 5 then                
      out_orderid := to_number(strText);  
    elsif cntItem = 6 then                
      out_shipid := to_number(strText);   
    elsif cntItem = 7 then                
      out_item := strText;                
    elsif cntItem = 8 then                
      out_lotnumber := strText;           
    elsif cntItem = 9 then                
      out_qty := to_number(strText);      
    elsif cntItem = 10 then               
      out_taskpriority := strText;        
    elsif cntItem = 11 then               
      out_picktype := strText;            
    elsif cntItem = 12 then               
      out_trace := strText;               
    elsif cntItem = 13 then               
      out_sid := to_number(strText);      
    end if;                               
  end if;
end loop;

out_msg := 'OKAY';

exception when OTHERS then
  out_msg := 'zgprm ' || substr(sqlerrm, 1, 80);
  out_errorno := sqlcode;
end receive_msg;


end genpicks;
/
show error package body genpicks;
exit;
