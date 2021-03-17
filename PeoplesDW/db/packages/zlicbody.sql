create or replace package body alps.zlicense as
--
-- $Id$
--


-- constants


QUEUENAME   CONSTANT    varchar2(7) := 'license';
TIMEOUT     CONSTANT    integer := 15;


-- cursors


cursor c_sid is
   select sys_context('USERENV','SESSIONID')
      from dual;


-- Public procedures


procedure logon
   (in_user     in varchar2,
    in_facility in varchar2,
    in_origin   in varchar2,
    out_msgno   out number,
    out_msg     out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   status number;
   sid number := null;
   msgno varchar2(10);
   l_msg varchar2(256);
   trans varchar2(20);
   msg varchar2(1000);
begin
   open c_sid;
   fetch c_sid into sid;
   close c_sid;

   l_msg := 'LOGON' || chr(9) ||
            in_user || chr(9) ||
            in_facility || chr(9) ||
            in_origin || chr(9) ||
            sid || chr(9);

   status := zqm.send(QUEUENAME,'MSG',l_msg,1,'LICENSE');
   commit;

   if (status != 1) then
      out_msgno := 101;
      out_msg := 'Send error ' || status;
   else
      status := zqm.receive(ztm.USER_DEFAULT_QUEUE,to_char(sid),
                            TIMEOUT,zqm.DQ_REMOVE, trans, msg);
      commit;
      if (status = -1) then
         out_msgno := 103;
         out_msg := 'No license server';
      elsif (status != 1) then
         out_msgno := 102;
         out_msg := 'Recv error ' || status;
      else
         msgno := nvl(zqm.get_field(msg,1),'(none)');
         out_msg := nvl(zqm.get_field(msg,2),'(none)');
         out_msgno := to_number(msgno);
      end if;
   end if;

exception
   when OTHERS then
      out_msgno := 100;
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end logon;


procedure logoff
   (in_user     in varchar2,
    in_facility in varchar2,
    in_origin   in varchar2,
    out_msgno   out number,
    out_msg     out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   status number;
   sid number := null;
   msgno varchar2(10);
   l_msg varchar2(256);
begin
   open c_sid;
   fetch c_sid into sid;
   close c_sid;

   l_msg := 'LOGOFF' || chr(9) ||
            in_user || chr(9) ||
            in_facility || chr(9) ||
            in_origin || chr(9) ||
            sid || chr(9);

   status := zqm.send(QUEUENAME,'MSG',l_msg,1,'LICENSE');
   commit;

   if (status != 1) then
      out_msgno := 101;
      out_msg := 'Send error ' || status;
   else
      out_msgno := 0;
      out_msg := 'OKAY';
   end if;

exception
   when OTHERS then
      out_msgno := 100;
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end logoff;


procedure switchfacility
   (in_user        in varchar2,
    in_facility    in varchar2,
    in_origin      in varchar2,
    in_newfacility in varchar2,
    out_msgno      out number,
    out_msg        out varchar2)
is PRAGMA AUTONOMOUS_TRANSACTION;
   status number;
   sid number := null;
   msgno varchar2(10);
   cinfo varchar2(64);
   l_msg varchar2(256);
   trans varchar2(20);
   msg varchar2(1000);
begin
   open c_sid;
   fetch c_sid into sid;
   close c_sid;

   l_msg := 'SWITCH' || chr(9) ||
            in_user || chr(9) ||
            in_facility || chr(9) ||
            in_origin || chr(9) ||
            in_newfacility || chr(9) ||
            sid || chr(9);

   status := zqm.send(QUEUENAME,'MSG',l_msg,1,'LICENSE');
   commit;

   if (status != 1) then
      out_msgno := 101;
      out_msg := 'Send error ' || status;
   else
      status := zqm.receive(ztm.USER_DEFAULT_QUEUE,to_char(sid),
                            TIMEOUT,zqm.DQ_REMOVE, trans, msg);
      commit;
      if (status = -1) then
         out_msgno := 103;
         out_msg := 'No license server';
      elsif (status != 1) then
         out_msgno := 102;
         out_msg := 'Recv error ' || status;
      else
         msgno := nvl(zqm.get_field(msg,1),'(none)');
         out_msg := nvl(zqm.get_field(msg,2),'(none)');
         out_msgno := to_number(msgno);
      end if;
   end if;

exception
   when OTHERS then
      out_msgno := 100;
      out_msg := substr(sqlerrm, 1, 80);
      rollback;
end switchfacility;


end zlicense;
/

show errors package body zlicense;
exit;
