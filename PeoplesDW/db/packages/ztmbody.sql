create or replace package body alps.ztaskmanager as
--
-- $Id$
--


-- Private functions


FUNCTION find_correlation(in_facility varchar2)
return varchar2
IS
   cursor c_Q is
      select abbrev
         from taskrequestqueues
         where code = in_facility;
   q c_Q%rowtype;
   cursor c_defQ is
      select abbrev
         from taskrequestqueues
         order by abbrev;

   que C_Q%rowtype;
   correlation varchar2(32);
BEGIN
   correlation := 'WORK';
   open c_Q;
   fetch c_Q into q;
   if c_Q%found then
      correlation := correlation || q.abbrev;
   else
      open c_defQ;
      fetch c_defQ into q;
      if c_defQ%found then
         correlation := correlation || q.abbrev;
      end if;
      close c_defQ;
   end if;
   close c_Q;

   return correlation;

EXCEPTION WHEN OTHERS THEN
    return correlation;

END find_correlation;


-- Public procedures


procedure get_cluster_pick
   (in_requested in number,
    in_userid    in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_wave      in number,
    in_tasktype  in varchar2,
    out_assigned out number,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);
begin
   out_assigned := 0;
   out_msg := null;

--   dbm := in_requested || '~' || in_userid || '~' || in_facility || '~' || in_location || '~' || in_equipment
--          || '~' || in_allcusts;
--   zms.log_msg('GCP', 'E', ' ', substr(dbm,1,254),'T','gcp', dbm);


   correlation := ztm.find_correlation(in_facility);

   l_msg := 'CLUSTERPK' || chr(9) ||
             in_facility || chr(9) ||
             in_location || chr(9) ||
             in_userid || chr(9) ||
             in_equipment || chr(9);

   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) || in_onlycust || chr(9);
   else
      l_msg := l_msg || in_allcusts || chr(9) || in_groupid || chr(9);
   end if;
   l_msg := l_msg || in_requested || chr(9) ||
             in_wave || chr(9) || in_tasktype || chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;

   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_assigned, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_cluster_pick;


procedure get_voice_cluster
   (in_requested in number,
    in_userid    in varchar2,
    in_facility  in varchar2,
    in_location  in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    out_assigned out number,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   status number;
   tmp_tasktype tasks.tasktype%type;
   l_msg varchar2(1000);
begin
   out_assigned := 0;
   out_msg := null;

   correlation := ztm.find_correlation(in_facility);

   l_msg := 'VOICECLUSTER' || chr(9) ||
             in_facility || chr(9) ||
             in_location || chr(9) ||
             in_userid || chr(9) ||
             in_equipment || chr(9);

   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) || in_onlycust || chr(9);
   else
      l_msg := l_msg || in_allcusts || chr(9) || in_groupid || chr(9);
   end if;
   l_msg := l_msg || in_requested || chr(9) ||
             0 || chr(9) || 'OP' || chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;

   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_assigned, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
   rollback;
end get_voice_cluster;


procedure get_sys_order_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_orderid   in number,
    in_shipid    in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   cnt integer;
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);

begin
   out_taskid := '0';
   out_msg := null;
   correlation := ztm.find_correlation(in_facility);

--   dbm := in_userid || '~' || in_facility || '~' || in_orderid || '~' || in_equipment
--          || '~' || in_allcusts;
--   zms.log_msg('GSO', 'E', ' ', substr(dbm,1,254),'T','gso', dbm);


   l_msg := 'SYSORPK' || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            in_equipment || chr(9) ||
            in_orderid || chr(9) ||
            in_shipid || chr(9);
   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) ||
               in_onlycust;
   else
      l_msg := l_msg || in_allcusts || chr(9) ||
               in_groupid;
   end if;
   l_msg := l_msg || chr(9) || in_tasktype|| chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;


   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_taskid, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_sys_order_pick;

procedure get_sort_item_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_lpid      in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   cnt integer;
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);

begin
   out_taskid := '0';
   out_msg := null;
   correlation := ztm.find_correlation(in_facility);

--   dbm := in_userid || '~' || in_facility || '~' || in_orderid || '~' || in_equipment
--          || '~' || in_allcusts;
--   zms.log_msg('GSO', 'E', ' ', substr(dbm,1,254),'T','gso', dbm);


   l_msg := 'SRTITMPK' || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            in_equipment || chr(9) ||
            in_lpid || chr(9);
   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) ||
               in_onlycust;
   else
      l_msg := l_msg || in_allcusts || chr(9) ||
               in_groupid;
   end if;
   l_msg := l_msg || chr(9) || in_tasktype|| chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;


   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_taskid, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_sort_item_pick;

procedure get_sort_item_pick_wave
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_wave      in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   cnt integer;
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);

begin
   out_taskid := '0';
   out_msg := null;
   correlation := ztm.find_correlation(in_facility);

--   dbm := in_userid || '~' || in_facility || '~' || in_orderid || '~' || in_equipment
--          || '~' || in_allcusts;
--   zms.log_msg('GSO', 'E', ' ', substr(dbm,1,254),'T','gso', dbm);


   l_msg := 'SRTITMPKW' || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            in_equipment || chr(9) ||
            in_wave || chr(9);
   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) ||
               in_onlycust;
   else
      l_msg := l_msg || in_allcusts || chr(9) ||
               in_groupid;
   end if;
   l_msg := l_msg || chr(9) || in_tasktype|| chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;


   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_taskid, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_sort_item_pick_wave;

procedure get_sort_item_pick_load
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_equipment in varchar2,
    in_loadno    in number,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktype  in varchar2,
    out_taskid   out varchar2,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   cnt integer;
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);

begin
   out_taskid := '0';
   out_msg := null;
   correlation := ztm.find_correlation(in_facility);

--   dbm := in_userid || '~' || in_facility || '~' || in_orderid || '~' || in_equipment
--          || '~' || in_allcusts;
--   zms.log_msg('GSO', 'E', ' ', substr(dbm,1,254),'T','gso', dbm);


   l_msg := 'SRTITMPKL' || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            in_equipment || chr(9) ||
            in_loadno || chr(9);
   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) ||
               in_onlycust;
   else
      l_msg := l_msg || in_allcusts || chr(9) ||
               in_groupid;
   end if;
   l_msg := l_msg || chr(9) || in_tasktype|| chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;


   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_taskid, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_sort_item_pick_load;

procedure get_a_task
   (in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    out_taskid           out varchar2,
    out_tasktype         out varchar2,
    out_msg              out varchar2,
    in_wave              in number default null)
is
   logmsg varchar(255);
   msg varchar(255) := null;
   tid varchar(255) := '0';
   tty varchar(255) := null;
   dbm varchar(255);
begin
   out_taskid := '0';
   out_msg := null;
   out_tasktype := null;

--   dbm := in_userid || '~' || in_facility || '~' || in_location || '~' || in_equipment
--          || '~' || in_tasktypeindicator || '!' || in_tasktypeindicator ||
--          '^' || in_tasktypestr || '&' || in_allcusts || '*' || in_groupid || '(' ||
--          in_onlycust ||')' || in_nextlinepickby || '++' || in_wave;
--   zms.log_autonomous_msg('GAT', 'E', ' ', substr(dbm,1,254),'T','gat', dbm);


   work_request('TASK', in_userid, in_facility, in_location, in_equipment,
         in_tasktypeindicator, in_tasktypestr, in_allcusts, in_groupid,
         in_onlycust, in_nextlinepickby, nvl(in_wave,0), msg);
   if (msg is null) then
      work_response(in_userid, in_facility, tid, tty, msg);
   end if;
   if tty = '(none)' then
      tty := null;
   end if;
   if ((nvl(length(tid), 0) > 15) or (nvl(length(tty), 0) > 2) or (nvl(length(msg), 0) > 80)) then
      rollback;
      zms.log_msg('GET_A_TASK', in_facility, null, 'tid=<'||tid||'>', 'T', in_userid, logmsg);
      zms.log_msg('GET_A_TASK', in_facility, null, 'tty=<'||tty||'>', 'T', in_userid, logmsg);
      zms.log_msg('GET_A_TASK', in_facility, null, 'msg=<'||msg||'>', 'T', in_userid, logmsg);
      commit;
   end if;

   out_taskid := tid;
   out_msg := msg;
   out_tasktype := tty;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end get_a_task;


procedure work_request
   (in_type              in varchar2,
    in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    in_wave              in number,
    out_msg              out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   status integer;
   errmsg varchar2(255);
   dbm varchar2(255);
begin
   out_msg := null;

--   dbm := in_userid || '~' || in_facility || '~' || in_location || '~' || in_equipment
--          || '~' || in_tasktypeindicator;
--   zms.log_msg('WR', 'E', ' ', substr(dbm,1,254),'T','wr', dbm);


   correlation := ztm.find_correlation(in_facility);

   l_msg := in_type || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            in_location || chr(9) ||
            in_equipment || chr(9) ||
            in_tasktypeindicator || chr(9) ||
            in_tasktypestr || chr(9) ||
            '0' || chr(9);  -- request type of get any task
   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) || in_onlycust;
   else
      l_msg := l_msg || in_allcusts || chr(9) ||
               in_groupid;
   end if;
   l_msg := l_msg || chr(9) || in_nextlinepickby|| chr(9) ||
            in_wave || chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;
   if status != 1 then
      out_msg := 'Send error ' || status;
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end work_request;


procedure work_response
   (in_userid     in varchar2,
    in_facility   in varchar2,
    out_taskid    out varchar2,
    out_tasktype  out varchar2,
    out_msg       out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   recvstatus integer;
   trans varchar2(20);
   msg varchar2(1000);
--   correlation varchar2(32);
   cnt integer;
   errmsg varchar2(255);
   dbm varchar2(255);
begin
   out_taskid := '0';
   out_msg := null;
   out_tasktype := null;

--   dbm := in_userid || ' ~ ' || trans || ' ~ ' || to_char(recvstatus) || ' ~ ' || msg ;
--   zms.log_msg('ZTM', 'E', ' ', substr(dbm,1,254),'T','ztm', dbm);


   recvstatus := zqm.receive(USER_DEFAULT_QUEUE,in_userid,null,zqm.DQ_REMOVE, trans, msg);


   if recvstatus < 0 then
     -- zut.prt('MS_Q WAIT timed out status:'||status);
       trans := null;
       out_msg := 'Recv error ' || recvstatus;
       commit;
       return;
   end if;


   if recvstatus != 1 then
      out_msg := 'Recv error ' || recvstatus;
   else
      out_taskid := nvl(zqm.get_field(msg,1),0);
      out_tasktype := nvl(zqm.get_field(msg,2),'??');
   end if;
   commit;
   return;
exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end work_response;


procedure get_voice_task
   (in_userid            in varchar2,
    in_facility          in varchar2,
    in_location          in varchar2,
    in_equipment         in varchar2,
    in_tasktypeindicator in varchar2,
    in_tasktypestr       in varchar2,
    in_allcusts          in varchar2,
    in_groupid           in varchar2,
    in_onlycust          in varchar2,
    in_nextlinepickby    in varchar2,
    out_taskid           out varchar2,
    out_tasktype         out varchar2,
    out_msg              out varchar2)
is
   logmsg varchar(255);
   msg varchar(255) := null;
   tid varchar(255) := '0';
   tty varchar(255) := null;
begin
   out_taskid := '0';
   out_msg := null;
   out_tasktype := null;

   work_request('VOICETASK', in_userid, in_facility, in_location, in_equipment,
         in_tasktypeindicator, in_tasktypestr, in_allcusts, in_groupid,
         in_onlycust, in_nextlinepickby, 0, msg);

   if (msg is null) then
      work_response(in_userid, in_facility, tid, tty, msg);
   end if;

   if tty = '(none)' then
     tty := null;
   end if;

   if ((nvl(length(tid), 0) > 15) or (nvl(length(tty), 0) > 2) or (nvl(length(msg), 0) > 80)) then
      rollback;
      zms.log_msg('GET_A_TASK', in_facility, null, 'tid=<'||tid||'>', 'T', in_userid, logmsg);
      zms.log_msg('GET_A_TASK', in_facility, null, 'tty=<'||tty||'>', 'T', in_userid, logmsg);
      zms.log_msg('GET_A_TASK', in_facility, null, 'msg=<'||msg||'>', 'T', in_userid, logmsg);
      commit;
   end if;

   out_taskid := tid;
   out_msg := msg;
   out_tasktype := tty;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end get_voice_task;


procedure get_conveyor_pick
   (in_userid     in varchar2,
    in_facility   in varchar2,
    io_location   in out varchar2,
    io_direction  in out varchar2,
    out_taskid    out varchar2,
    out_tasktype  out varchar2,
    out_msg       out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   msg varchar2(1000);
   status integer;
   errmsg varchar2(255);
   trans varchar2(20);
   dbm varchar2(255);
begin
   out_taskid := '0';
   out_tasktype := null;
   out_msg := null;

--   dbm := in_userid || '~' || in_facility || '~' || io_location || '~' || io_direction;
--   zms.log_msg('GCP', 'E', ' ', substr(dbm,1,254),'T','gcp', dbm);

   correlation := ztm.find_correlation(in_facility);

   l_msg := 'CONVEYOR' || chr(9) ||
            in_facility || chr(9) ||
            in_userid || chr(9) ||
            io_location || chr(9) ||
            io_direction|| chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;

   if status != 1 then
      out_msg := 'Send error ' || status;
   else
      status := zqm.receive(USER_DEFAULT_QUEUE,in_userid,null,zqm.DQ_REMOVE, trans, msg);
      if status < 0 then
        -- zut.prt('MS_Q WAIT timed out status:'||status);
          trans := null;
          out_msg := 'Recv error ' || status;
          commit;
          return;
      else
         out_taskid := nvl(zqm.get_field(msg,1),'0');
         out_tasktype := nvl(zqm.get_field(msg,2),'??');
         io_location := nvl(zqm.get_field(msg,3),'(none)');
         io_direction := nvl(zqm.get_field(msg,4),'?');
      end if;
   end if;
   commit;
exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_conveyor_pick;


procedure assign_by_priority
   (userfacility       in varchar2,
    equipment          in varchar2,
    tasktypeindicator  in varchar2,
    tasktypestr        in varchar2,
    userid             in varchar2,
    custtype           in varchar2,
    custaux            in varchar2,
    nextlinepickby     in varchar2,
    userlocation       in varchar2,
    voice              in varchar2,
    out_taskid         out number,
    out_tasktype       out varchar2,
    out_msg            out varchar2)
is
   cursor c_pickseq is
      select nvl(pickingseq, 0)
         from location
         where facility = userfacility
           and locid = userlocation;
   userseq location.pickingseq%type := 0;

   cursor c_pasgn_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_free_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid is null
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_pasgn_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_free_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid is null
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_pasgn_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_free_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority in ('1', '2', '3', '4')
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and curruserid is null
           and touserid is null
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
         order by priority,
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;

   if (nextlinepickby != 'O') then
      open c_pickseq;
      fetch c_pickseq into userseq;
      close c_pickseq;
   end if;

   if (custtype = '1') then
      for t in c_pasgn_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_free_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (custtype = 'S') then
      for t in c_pasgn_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_free_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   for t in c_pasgn_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;
   for t in c_free_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_by_priority;


procedure assign_by_section
   (userfacility      in varchar2,
    usersection       in varchar2,
    equipment         in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    nextlinepickby    in varchar2,
    userlocation      in varchar2,
    voice             in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2)
is
   cursor c_ssrch is
      select searchstr
         from sectionsearch
         where facility = userfacility
           and sectionid = usersection;
   sectionstr sectionsearch.searchstr%type;

   cursor c_pickseq is
      select nvl(pickingseq, 0)
         from location
         where facility = userfacility
           and locid = userlocation;
   userseq location.pickingseq%type := 0;

   cursor c_imm_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_high_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_norm_empty_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_norm_any_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_low_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_imm_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_high_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_empty_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_any_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_low_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_imm_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_high_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_norm_empty_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_norm_any_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
   cursor c_low_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));
begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;

   open c_ssrch;
   fetch c_ssrch into sectionstr;
   if c_ssrch%notfound then
      close c_ssrch;
      out_taskid := -1;
      return;
   end if;
   close c_ssrch;

   if (nextlinepickby != 'O') then
      open c_pickseq;
      fetch c_pickseq into userseq;
      close c_pickseq;
   end if;

   if (custtype = '1') then
      if (prilevel = 'I') then
         for t in c_imm_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_empty_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_any_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (custtype = 'S') then
      if (prilevel = 'I') then
         for t in c_imm_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_empty_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_any_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'I') then
      for t in c_imm_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'L') then
      for t in c_low_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   for t in c_high_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;
   for t in c_norm_empty_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;
   for t in c_norm_any_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_by_section;


procedure assign_preassigned_by_section
   (userfacility      in varchar2,
    usersection       in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    nextlinepickby    in varchar2,
    userlocation      in varchar2,
    voice             in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2)
is
   cursor c_ssrch is
      select searchstr
         from sectionsearch
         where facility = userfacility
           and sectionid = usersection;
   sectionstr sectionsearch.searchstr%type;

   cursor c_pickseq is
      select nvl(pickingseq, 0)
         from location
         where facility = userfacility
           and locid = userlocation;
   userseq location.pickingseq%type := 0;

   cursor c_imm_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_high_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_empty_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_any_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_low_1cust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_imm_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_high_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_empty_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_any_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_low_selcust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));


   cursor c_imm_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '1'
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_high_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '2'
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_empty_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_norm_any_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '3'
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

   cursor c_low_anycust is
      select taskid, tasktype
         from tasks, customer
         where facility = userfacility
           and priority = '4'
           and touserid = userid
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr, tasktype),1),
                      'E', nvl(-instr(tasktypestr, tasktype),1)+.5,
                      1) > 0
           and instr(sectionstr, '|'||rpad(fromsection,10)||'|') > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and ztm.count_task_restrictions(voice, taskid) = 0
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(wave,0), pickwave)
         order by instr(sectionstr, '|'||rpad(fromsection,10)||'|'),
            ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
                    decode(decode(tasktype,'PI','P',nextlinepickby),
                     'O', taskid,
                          decode(sign(locseq-userseq),
                             -1, locseq-userseq+9999999,
                              0, 0,
                              1, locseq-userseq));

begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;

   open c_ssrch;
   fetch c_ssrch into sectionstr;
   if c_ssrch%notfound then
      close c_ssrch;
      out_taskid := -1;
      return;
   end if;
   close c_ssrch;

   if (nextlinepickby != 'O') then
      open c_pickseq;
      fetch c_pickseq into userseq;
      close c_pickseq;
   end if;

   if (custtype = '1') then
      if (prilevel = 'I') then
         for t in c_imm_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_empty_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_any_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (custtype = 'S') then
      if (prilevel = 'I') then
         for t in c_imm_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_empty_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_any_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'I') then
      for t in c_imm_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'L') then
      for t in c_low_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   for t in c_high_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

   for t in c_norm_empty_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

   for t in c_norm_any_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_preassigned_by_section;


procedure assign_order_pick
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    pickorderid   in number,
    pickshipid    in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskid    out number,
    out_msg       out varchar2)
is
   cursor c_aop_ship is
      select taskid
         from tasks, customer
         where tasktype = in_tasktype
           and facility = userfacility
           and priority in ('1', '2', '3', '4')
           and curruserid is null
           and nvl(touserid, userid) = userid
           and orderid = pickorderid
           and shipid = pickshipid
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
         order by case when touserid is not null then 0 else 1 end, priority, taskid;
   cursor c_aop_any is
      select taskid
         from tasks, customer
         where tasktype = in_tasktype
           and facility = userfacility
           and priority in ('1', '2', '3', '4')
           and curruserid is null
           and nvl(touserid, userid) = userid
           and orderid = pickorderid
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and taskid not in (select taskid from cants
                                 where nameid = userid)
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
         order by case when touserid is not null then 0 else 1 end, priority, shipid, taskid;
begin
   out_taskid := 0;
   out_msg := null;

   if (pickshipid != 0) then
      for t in c_aop_ship loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         return;
      end loop;
   else
      for t in c_aop_any loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         return;
      end loop;
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_order_pick;

procedure assign_sort_item_pick
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    picklpid      in varchar2,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2)
is
   cursor c_sip is
      select t.taskid as taskid
      from tasks t, subtasks s, customer c, waves w
      where s.lpid = picklpid
        and t.taskid = s.taskid
        and t.tasktype = 'SO'
        and t.priority in ('1', '2', '3', '4')
        and t.curruserid is null
        and nvl(t.touserid, userid) = userid
        and equipment in (select equipid from equipprofequip e
                           where e.profid = t.fromprofile)
        and t.taskid not in (select c.taskid from cants c
                              where nameid = userid)
        and c.custid (+) = t.custid
        and nvl(c.paperbased,'N') = 'N'
        and w.wave(+) = t.wave;

begin
   out_taskcount := 0;
   out_msg := null;

   for cs in c_sip loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = cs.taskid;
   end loop;
   select count(1) into out_taskcount
      from tasks
      where curruserid = userid;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_sort_item_pick;

procedure assign_sort_item_pick_load
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    in_loadno     in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2)
is
   cursor c_sip is
      select t.taskid as taskid
      from tasks t, subtasks s, customer c, waves w
      where s.loadno = in_loadno
        and t.taskid = s.taskid
        and t.tasktype = 'SO'
        and t.priority in ('1', '2', '3', '4')
        and t.curruserid is null
        and nvl(t.touserid, userid) = userid
        and equipment in (select equipid from equipprofequip e
                           where e.profid = t.fromprofile)
        and t.taskid not in (select c.taskid from cants c
                              where nameid = userid)
        and c.custid (+) = t.custid
        and nvl(c.paperbased,'N') = 'N'
        and w.wave(+) = t.wave;
l_msg varchar(256);
begin
   out_taskcount := 0;
   out_msg := null;
   zms.log_autonomous_msg('IPL', 'T', ' ', 'fac=' ||userfacility || ' userid='||userid ||
               ' equipment='||equipment || ' loadno='||in_loadno ||
               ' custtype=' || custtype ||' custaux=' || custaux ||
               ' tasktype='||in_tasktype,'T','ipl', l_msg);

   for cs in c_sip loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = cs.taskid;
         out_taskcount := 1;
         return;
   end loop;
exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_sort_item_pick_load;

procedure assign_sort_item_pick_wave
   (userfacility  in varchar2,
    userid        in varchar2,
    equipment     in varchar2,
    in_wave       in number,
    custtype      in varchar2,
    custaux       in varchar2,
    in_tasktype   in varchar2,
    out_taskcount out number,
    out_msg       out varchar2)
is
   cursor c_sip is
      select t.taskid as taskid
      from tasks t, subtasks s, customer c, waves w
      where s.wave = in_wave
        and t.taskid = s.taskid
        and t.tasktype = 'SO'
        and t.priority in ('1', '2', '3', '4')
        and t.curruserid is null
        and nvl(t.touserid, userid) = userid
        and equipment in (select equipid from equipprofequip e
                           where e.profid = t.fromprofile)
        and t.taskid not in (select c.taskid from cants c
                              where nameid = userid)
        and c.custid (+) = t.custid
        and nvl(c.paperbased,'N') = 'N'
        and w.wave(+) = t.wave;

begin
   out_taskcount := 0;
   out_msg := null;

   for cs in c_sip loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = cs.taskid;
         out_taskcount := 1;
         return;
   end loop;
exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_sort_item_pick_wave;


procedure assign_conveyor_pick
   (in_userid     in varchar2,
    in_facility   in varchar2,
    io_location   in out varchar2,
    io_direction  in out varchar2,
    out_taskid    out varchar2,
    out_tasktype  out varchar2,
    out_msg       out varchar2)
is
   cursor c_conv_fwd (p_zone varchar2, p_seq number) is
      select taskid, tasktype, fromloc
         from tasks, customer
         where facility = in_facility
           and tasktype in ('PK', 'OP', 'SO')
           and pickingzone = p_zone
           and priority in ('1', '2', '3', '4')
           and curruserid is null
           and taskid not in (select taskid from cants
                                 where nameid = in_userid)
           and locseq >= p_seq
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
         order by ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
           locseq;
   cursor c_conv_bck (p_zone varchar2, p_seq number) is
      select taskid, tasktype, fromloc
         from tasks, customer
         where facility = in_facility
           and tasktype in ('PK', 'OP', 'SO')
           and pickingzone = p_zone
           and priority in ('1', '2', '3', '4')
           and curruserid is null
           and taskid not in (select taskid from cants
                                 where nameid = in_userid)
           and locseq <= p_seq
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
         order by ztk.task_crush_factor(tasks.taskid,tasks.tasktype,tasks.custid,tasks.item),
           locseq desc;
   cursor c_loc is
      select L.pickingseq, L.pickingzone, upper(Z.convdirection) as convdirection
         from location L, zone Z
         where L.facility = in_facility
           and L.locid = io_location
           and Z.facility = in_facility
           and Z.zoneid = L.pickingzone;
   loc c_loc%rowtype;
   cnt pls_integer := 0;
begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;

   open c_loc;
   fetch c_loc into loc;
   close c_loc;

   while (cnt < 2)
   loop
      if (io_direction = 'F') then
         for t in c_conv_fwd(loc.pickingzone, loc.pickingseq) loop
            update tasks
               set curruserid = in_userid,
                   prevpriority = priority,
                   priority = '0',
                   convpickloc = io_location
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            io_location := t.fromloc;
            return;
         end loop;

         if (loc.convdirection = 'O') then
            loc.pickingseq := 0;
         else
            io_direction := 'B';
         end if;
      else
         for t in c_conv_bck(loc.pickingzone, loc.pickingseq) loop
            update tasks
               set curruserid = in_userid,
                   prevpriority = priority,
                   priority = '0',
                   convpickloc = io_location
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            io_location := t.fromloc;
            return;
         end loop;

         if (loc.convdirection = 'O') then
            loc.pickingseq := 9999999;
         else
            io_direction := 'F';
         end if;
      end if;
      cnt := cnt +1;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_conveyor_pick;


procedure assign_max_line_picks
   (in_taskid in number,
    in_userid in varchar2,
    out_msg   out varchar2)
is
   cursor c_usr(p_userid varchar2) is
      select nvl(fullpicklimit, 0) fullpicklimit
         from userheader
         where nameid = p_userid;
   usr c_usr%rowtype;
   cursor c_tsk(p_taskid number) is
      select tasktype, facility, fromloc, shippingtype
         from subtasks
         where taskid = p_taskid;
   tsk c_tsk%rowtype;
   cursor c_full_pick(p_facility varchar2, p_fromloc varchar2, p_userid varchar2) is
      select T.taskid
         from tasks T, subtasks S, customer C
         where T.facility = p_facility
           and T.tasktype = 'PK'
           and T.priority in ('1', '2', '3', '4')
           and T.curruserid is null
           and nvl(T.touserid, p_userid) = p_userid
           and T.taskid not in (select taskid from cants
                                 where nameid = p_userid)
           and S.taskid = T.taskid
           and S.fromloc = p_fromloc
           and S.shippingtype = 'F'
           and C.custid (+) = T.custid
           and nvl(C.paperbased,'N') = 'N'
         order by T.priority;
   l_found boolean;
   l_workcnt pls_integer;
   l_fullcnt pls_integer;
begin
   out_msg := null;

   open c_tsk(in_taskid);
   fetch c_tsk into tsk;
   l_found := c_tsk%found;
   close c_tsk;
   if (not l_found) or (tsk.tasktype != 'PK') or (tsk.shippingtype != 'F') then
      return;
   end if;

   open c_usr(in_userid);
   fetch c_usr into usr;
   l_found := c_usr%found;
   close c_usr;
   if (not l_found) or (usr.fullpicklimit < 2) then
      return;
   end if;

   select count(1) into l_workcnt
      from tasks T, subtasks S
      where T.curruserid = in_userid
        and T.priority = '0'
        and S.taskid = T.taskid;

   select count(1) into l_fullcnt
      from tasks T, subtasks S
      where T.curruserid = in_userid
        and T.priority = '0'
        and T.tasktype = 'PK'
        and S.taskid = T.taskid
        and S.shippingtype = 'F';

-- picker must only have full picks assigned
   if (l_workcnt = l_fullcnt) and (l_fullcnt < usr.fullpicklimit) then
      for t in c_full_pick(tsk.facility, tsk.fromloc, in_userid) loop
         update tasks
            set curruserid = in_userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;

         l_fullcnt := l_fullcnt + 1;
         exit when l_fullcnt >= usr.fullpicklimit;
      end loop;
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_max_line_picks;


procedure assign_wave_pick
   (in_facility  in varchar2,
    in_userid    in varchar2,
    in_equipment in varchar2,
    in_tasktype  in varchar2,
    in_wave      in number,
    out_taskid   out number,
    out_msg      out varchar2)
is
   cursor c_awp is
      select T.taskid
         from tasks T, orderhdr O, customer C
         where T.tasktype = in_tasktype
           and T.facility = in_facility
           and T.priority in ('1', '2', '3', '4')
           and T.curruserid is null
           and nvl(T.touserid, in_userid) = in_userid
           and in_equipment in (select equipid from equipprofequip EQE
                  where EQE.profid = T.fromprofile)
           and T.taskid not in (select taskid from cants
                                 where nameid = in_userid)
           and O.wave = in_wave
           and T.orderid = O.orderid
           and T.shipid = O.shipid
           and C.custid (+) = T.custid
           and nvl(C.paperbased,'N') = 'N';
begin
   out_taskid := 0;
   out_msg := null;

   for t in c_awp loop
      update tasks
         set curruserid = in_userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_wave_pick;


procedure get_section_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_section   in varchar2,
    in_equipment in varchar2,
    in_allcusts  in varchar2,
    in_groupid   in varchar2,
    in_onlycust  in varchar2,
    in_tasktypes in varchar2,
    in_startpos  in number,
    out_assigned out number,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   correlation varchar2(32);
   l_msg varchar2(1000);
   status number;
   tmp_tasktype tasks.tasktype%type;
   errmsg varchar2(255);
   dbm varchar2(255);
begin
   out_assigned := 0;
   out_msg := null;

   correlation := ztm.find_correlation(in_facility);

   l_msg := 'SECTIONPK' || chr(9) ||
             in_facility || chr(9) ||
             in_section || chr(9) ||
             in_userid || chr(9) ||
             in_equipment || chr(9);

   if (in_onlycust is not null) then
      l_msg := l_msg || '1' || chr(9) || in_onlycust || chr(9);
   else
      l_msg := l_msg || in_allcusts || chr(9) || in_groupid || chr(9);
   end if;
   l_msg := l_msg || in_tasktypes || chr(9) || in_startpos || chr(9);

   status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
   commit;

   if (status != 1) then
      out_msg := 'Send error ' || status;
   else
      work_response(in_userid, in_facility, out_assigned, tmp_tasktype, out_msg);
   end if;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end get_section_pick;


procedure assign_section_pick
   (in_userid    in varchar2,
    in_facility  in varchar2,
    in_section   in varchar2,
    in_equipment in varchar2,
    in_tasktypes in varchar2,
    in_ctype     in varchar2,
    in_caux      in varchar2,
    in_startpos  in number,
    out_assigned out number,
    out_msg      out varchar2)
is
begin
   out_assigned := 0;
   out_msg := null;

   if in_ctype = '1' then
      update tasks
         set curruserid = in_userid,
             prevpriority = priority,
             priority = '0'
         where taskid in (select T.taskid
                  from tasks T, customer C
                  where T.facility = in_facility
                    and T.priority in ('1', '2', '3', '4')
                    and in_equipment in (select equipid from equipprofequip EQ
                           where EQ.profid = T.fromprofile)
                    and T.curruserid is null
                    and nvl(T.touserid, in_userid) = in_userid
                    and T.taskid not in (select taskid from cants
                                          where nameid = in_userid)
                    and fromsection = in_section
                    and instr(in_tasktypes, T.tasktype) > 0
                    and C.custid (+) = T.custid
                    and nvl(C.paperbased,'N') = 'N'
                    and nvl(T.locseq,0) >= in_startpos
                    and nvl(T.custid, in_caux) = in_caux);
      out_assigned := sql%rowcount;
   elsif in_ctype = 'S' then
      update tasks
         set curruserid = in_userid,
             prevpriority = priority,
             priority = '0'
         where taskid in (select T.taskid
                  from tasks T, customer C
                  where T.facility = in_facility
                    and T.priority in ('1', '2', '3', '4')
                    and in_equipment in (select equipid from equipprofequip EQ
                           where EQ.profid = T.fromprofile)
                    and T.curruserid is null
                    and nvl(T.touserid, in_userid) = in_userid
                    and T.taskid not in (select taskid from cants
                                          where nameid = in_userid)
                    and fromsection = in_section
                    and instr(in_tasktypes, T.tasktype) > 0
                    and C.custid (+) = T.custid
                    and nvl(C.paperbased,'N') = 'N'
                    and nvl(T.locseq,0) >= in_startpos
                    and (T.custid is null
                     or  T.custid in (select custid from usercustomer U
                                          where U.nameid = in_userid)));
      out_assigned := sql%rowcount;
   else
      update tasks
         set curruserid = in_userid,
             prevpriority = priority,
             priority = '0'
         where taskid in (select T.taskid
                  from tasks T, customer C
                  where T.facility = in_facility
                    and T.priority in ('1', '2', '3', '4')
                    and in_equipment in (select equipid from equipprofequip EQ
                           where EQ.profid = T.fromprofile)
                    and T.curruserid is null
                    and nvl(T.touserid, in_userid) = in_userid
                    and T.taskid not in (select taskid from cants
                                          where nameid = in_userid)
                    and fromsection = in_section
                    and instr(in_tasktypes, T.tasktype) > 0
                    and C.custid (+) = T.custid
                    and nvl(C.paperbased,'N') = 'N'
                    and nvl(T.locseq,0) >= in_startpos);
      out_assigned := sql%rowcount;
   end if;


exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_section_pick;

procedure updt_appt_sched
   (in_loadno  in varchar2,
    in_userid  in varchar2,
    out_msg    out varchar2)
is
  cursor c_uad_loadno is
    select loadno, apptdate
      from loads
     where loadno = in_loadno;
 l_auxmsg  varchar2(100);
begin
  out_msg := null;
  for t in c_uad_loadno loop
     update pimevents
       set starttime = t.apptdate,
          finishtime = t.apptdate + interval '15' minute
      where loadno = t.loadno;
  end loop;
  out_msg := 'OKAY';
exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end updt_appt_sched;

-- Public functions


FUNCTION subtask_min_apptdate
(in_taskid number
) return date
as

cursor curSubTasks is
  select orderid, shipid
    from subtasks
   where taskid = in_taskid
     and orderid is not null
     and shipid is not null;

cursor curOrderHdr(in_orderid number, in_shipid number) is
  select apptdate
    from orderhdr
   where orderid = in_orderid
     and shipid = in_shipid;

oh curOrderHdr%rowtype;

minApptDate orderhdr.apptdate%type;

begin

minApptDate := null;
for st in curSubTasks
loop
  oh := null;
  open curOrderHdr(st.orderid,st.shipid);
  fetch curOrderHdr into oh;
  close curOrderHdr;
  if (minApptDate is null) or
     ( (oh.apptdate is not null) and
       (oh.apptdate < minApptDate) )then
    minApptDate := oh.apptdate;
  end if;
end loop;

return minApptDate;

exception when others then
  return null;
end;


function count_task_restrictions
   (in_voice  in varchar2,
    in_taskid in number)
return number
is
   l_count number := 0;
begin
   if in_voice = 'Y' then
      select count(1) into l_count
         from subtasks S, facility F, location L, zone Z
         where S.taskid = in_taskid
           and F.facility = S.facility
           and L.facility = S.facility
           and L.locid = S.fromloc
           and Z.facility (+) = L.facility
           and Z.zoneid (+) = L.pickingzone
           and 'Y' != decode(nvl(Z.allow_voice_picking, 'F'),
                        'F', F.allow_voice_picking,
                             Z.allow_voice_picking);
   end if;
   return l_count;

exception
   when OTHERS then
      return 0;
end count_task_restrictions;

procedure kill_rfwhse_user
   (in_facility  in varchar2,
    in_rf_userid in varchar2,
    in_userid    in varchar2,
    out_errorno  out number,
    out_msg      out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
  correlation varchar2(32);
  status number;
  tmp_tasktype tasks.tasktype%type;
  tmp_assigned number;
  l_cnt pls_integer;
  l_msg varchar2(255);
begin

  out_errorno := 0;
  out_msg := 'OKAY';
  begin
    select count(1)
      into l_cnt
      from userhistory
     where nameid = upper(in_rf_userid)
       and ( (begtime > sysdate - 2/1440) or
             (endtime > sysdate - 2/1440) );
  exception when others then
    l_cnt := -1;
  end;
  if l_cnt > 0 then
    out_errorno := -4;
    out_msg :=  'Has recent actvity';
    return;
  end if;
  correlation := ztm.find_correlation(in_facility);
  l_msg := 'KILLRFUSER' || chr(9) ||
           trim(in_facility) || chr(9) ||
           trim(in_rf_userid) || chr(9) ||
           trim(in_userid) || chr(9);
  status := zqm.send(WORK_DEFAULT_QUEUE,'MSG',l_msg,1,correlation);
  commit;
  if (status != 1) then
    out_errorno := -2;
    out_msg := 'Send error ' || status;
    return;
  end if;
  ztm.work_response(in_userid, in_facility, tmp_assigned, tmp_tasktype, out_msg);
  if tmp_tasktype != 'OK' then
    out_errorno := -3;
    out_msg := 'Can''t kill: ' || tmp_tasktype;
  end if;
exception
   when OTHERS then
      out_msg := 'krfu ' || substr(sqlerrm, 1, 80);
      rollback;
end kill_rfwhse_user;

procedure assign_by_sequence
   (userfacility      in varchar2,
    equipment         in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2)
is
   sortBy waves.task_assignment_sequence%type;

   cursor c_imm_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                     where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_high_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_norm_empty_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_norm_any_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_low_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_imm_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_high_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_empty_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_any_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_low_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_imm_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_high_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_norm_empty_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_norm_any_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
   cursor c_low_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid is null
           and equipment in (select equipid from equipprofequip
                  where equipprofequip.profid = tasks.fromprofile)
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;
begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;
   begin
      select task_assignment_sequence into sortBy
         from waves
         where wave = pickwave;
   exception when no_data_found then
      sortBy := null;
   end;
   if (custtype = '1') then
      if (prilevel = 'I') then
         for t in c_imm_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_empty_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_any_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (custtype = 'S') then
      if (prilevel = 'I') then
         for t in c_imm_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_empty_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      for t in c_norm_any_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'I') then
      for t in c_imm_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'L') then
      for t in c_low_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   for t in c_high_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;
   for t in c_norm_empty_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;
   for t in c_norm_any_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_by_sequence;

procedure assign_preassigned_by_sequence
   (userfacility      in varchar2,
    tasktypestr       in varchar2,
    tasktypeindicator in varchar2,
    userid            in varchar2,
    prilevel          in varchar2,
    custtype          in varchar2,
    custaux           in varchar2,
    pickwave          in number,
    out_taskid        out number,
    out_tasktype      out varchar2,
    out_msg           out varchar2)
is
   sortBy waves.task_assignment_sequence%type;
   cursor c_imm_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_high_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_empty_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_any_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_low_1cust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid = userid
           and nvl(tasks.custid, custaux) = custaux
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_imm_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_high_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_empty_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_any_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_low_selcust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid = userid
           and (tasks.custid is null
            or  tasks.custid in (select custid from usercustomer
                             where usercustomer.nameid = userid))
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;


   cursor c_imm_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '1'
           and tasks.touserid = userid
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_high_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '2'
           and tasks.touserid = userid
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_empty_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and tasks.fromloc not in (select fromloc from tasks t1
                  where tasks.facility = t1.facility
                    and tasks.fromsection = t1.fromsection
                    and tasks.fromloc = t1.fromloc
                    and t1.curruserid != userid
                    and t1.priority = '0')
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_norm_any_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '3'
           and tasks.touserid = userid
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

   cursor c_low_anycust is
      select tasks.taskid, tasks.tasktype
         from tasks, customer, subtasks
         where tasks.facility = userfacility
           and tasks.priority = '4'
           and tasks.touserid = userid
           and tasks.taskid not in (select taskid from cants
                                 where nameid = userid)
           and decode(tasktypeindicator,
                      'I', nvl(instr(tasktypestr,tasks.tasktype),1),
                      'E', nvl(-instr(tasktypestr,tasks.tasktype),1)+.5,
                      1) > 0
           and customer.custid (+) = tasks.custid
           and nvl(customer.paperbased,'N') = 'N'
           and nvl(tasks.wave,0) = decode(nvl(pickwave, 0), 0, nvl(tasks.wave,0), pickwave)
           and tasks.taskid = subtasks.taskid
         order by decode(sortBy, 'CUBE', tasks.cube) desc,
                  decode(sortby, 'ITEM', subtasks.item),
                  decode(sortBy, 'QUANTITY', tasks.qty) desc,
                  decode(sortBy, 'WEIGHT', tasks.weight) desc,
                  decode(sortBy, null, taskid) ;

begin
   out_taskid := 0;
   out_tasktype := null;
   out_msg := null;
   begin
      select task_assignment_sequence into sortBy
         from waves
         where wave = pickwave;
   exception when no_data_found then
      sortBy := null;
   end;

   if (custtype = '1') then
      if (prilevel = 'I') then
         for t in c_imm_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_1cust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_empty_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_any_1cust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (custtype = 'S') then
      if (prilevel = 'I') then
         for t in c_imm_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      if (prilevel = 'L') then
         for t in c_low_selcust loop
            update tasks
               set curruserid = userid,
                   prevpriority = priority,
                   priority = '0'
               where taskid = t.taskid;
            out_taskid := t.taskid;
            out_tasktype := t.tasktype;
            return;
         end loop;
         return;
      end if;

      for t in c_high_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_empty_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;

      for t in c_norm_any_selcust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'I') then
      for t in c_imm_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   if (prilevel = 'L') then
      for t in c_low_anycust loop
         update tasks
            set curruserid = userid,
                prevpriority = priority,
                priority = '0'
            where taskid = t.taskid;
         out_taskid := t.taskid;
         out_tasktype := t.tasktype;
         return;
      end loop;
      return;
   end if;

   for t in c_high_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

   for t in c_norm_empty_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

   for t in c_norm_any_anycust loop
      update tasks
         set curruserid = userid,
             prevpriority = priority,
             priority = '0'
         where taskid = t.taskid;
      out_taskid := t.taskid;
      out_tasktype := t.tasktype;
      return;
   end loop;

exception
   when OTHERS then
      out_msg := substr(sqlerrm, 1, 80);
end assign_preassigned_by_sequence;


procedure is_sort_by_item
   (in_lpid  in varchar2,
    is_sbi   out number)
is
sWave tasks.wave%type;
wBatch_pick_by_item_yn waves.batch_pick_by_item_yn%type;

cursor c_subtask is
   select nvl(wave,0)
     from subtasks
    where lpid = in_lpid
      and tasktype = 'SO';

cursor c_wave(in_wave number) is
   select nvl(batch_pick_by_item_yn,'N') as batch_pick_by_item_yn
    from waves
    where wave in (select wave from orderhdr
                   where original_wave_before_combine = in_wave);


begin
is_sbi := 0;
open c_subtask;
fetch c_subtask into sWave;
if c_subtask%notfound then
   close c_subtask;
   return;
end if;
close c_subtask;
if (sWave = 0) then
   return;
end if;
open c_wave(sWave);
fetch c_wave into wBatch_pick_by_item_yn;
if c_wave%notfound then
   close c_wave;
   return;
end if;
if  wBatch_pick_by_item_yn = 'Y' then
   is_sbi := 1;
end if;
return;
end is_sort_by_item;


procedure is_sort_by_item_wave
   (in_wave  in number,
    is_sbi   out number)
is
begin
is_sbi := 0;

select count(1) into is_sbi
   from waves
   where wave in (select wave
                    from orderhdr
                    where original_wave_before_combine = in_wave)
     and nvl(batch_pick_by_item_yn,'N') = 'Y';

return;
end is_sort_by_item_wave;

procedure is_sort_by_item_load
   (in_loadno in number,
    is_sbi    out number)
is
sLoadno tasks.loadno%type;
oWave orderhdr.wave%type;
oOriginal_wave_before_combine orderhdr.original_wave_before_combine%type;
wBatch_pick_by_item_yn waves.batch_pick_by_item_yn%type;

cursor c_wave(in_loadno number) is
   select nvl(batch_pick_by_item_yn,'N') as batch_pick_by_item_yn
    from waves
    where wave in (select wave from orderhdr
                   where loadno = in_loadno);


begin
is_sbi := 0;

open c_wave(in_loadno);
fetch c_wave into wBatch_pick_by_item_yn;
if c_wave%notfound then
   close c_wave;
   return;
end if;
if  wBatch_pick_by_item_yn = 'Y' then
   is_sbi := 1;
end if;
return;
end is_sort_by_item_load;

procedure sbi_task_count
   (in_lpid  in varchar2,
    in_user  in varchar2,
    out_count out number)
is
begin
   select count(1) into out_count
      from subtasks s, tasks t
      where s.lpid = in_lpid
        and t.taskid = s.taskid
        and nvl(t.curruserid, 'x') <> in_user;
end;

end ztaskmanager;
/

show errors package body ztaskmanager;
exit;
