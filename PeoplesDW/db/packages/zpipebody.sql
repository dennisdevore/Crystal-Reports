create or replace package body alps.pipeutility as
--
-- $Id$
--


-- Public procedures


procedure flush_rf_user
   (in_facility in varchar2,
    in_user     in varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   l_status number;
   l_qmsg qmsg := qmsg(null, null);
   txt varchar2(4000);
   tid varchar2(4000);
   ttype varchar2(4000);
   cnt integer;
   logmsg varchar(255);
begin
   loop

      l_status := zqm.receive(ztm.USER_DEFAULT_QUEUE,in_user,
                            zqm.WT_NOWAIT,zqm.DQ_REMOVE,
                            l_qmsg.trans, l_qmsg.message);

      commit;

      exit when l_status <> 1;

      tid := null;
      ttype := null;
      tid := zqm.get_field(l_qmsg.message,1);
      ttype := zqm.get_field(l_qmsg.message,2);

      cnt := 0;
      if ((tid is not null) and (ttype is not null)) then
         select count(1) into cnt
            from tasktypes
            where code = ttype;

         if (cnt != 0) then
            update tasks
               set curruserid = null,
                   clusterposition = null,
                   priority = prevpriority,
                   lastuser = 'FLUSH_RF',
                   lastupdate = sysdate,
                   convpickloc = null
               where taskid = tid
                 and tasktype = ttype
                 and curruserid = in_user;

            cnt := sql%rowcount;
            if (cnt != 0) then
               zms.log_autonomous_msg('FLUSH_RF', in_facility, null,
                                      'taskid=' || tid, 'W', in_user, logmsg);
            end if;
         end if;
      end if;

      if (cnt = 0) then
         zms.log_autonomous_msg('FLUSH_RF', in_facility, null,
               'p0=' || tid || ' p1=' || ttype,
               'W', in_user, logmsg);
         commit;
      end if;
   end loop;

exception
   when OTHERS then
      rollback;
end flush_rf_user;

end pipeutility;
/

show errors package body pipeutility;
exit;
