create or replace package body alps.zalertmsg as
--
-- $Id$
--
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--
-- NLCR char(2) := chr(10) || chr(13);
-- NLCR char(1) := chr(13);
NLCR char(1) := chr(10);

----------------------------------------------------------------------


-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************

----------------------------------------------------------------------
--
-- send_alert_msg
--
----------------------------------------------------------------------
PROCEDURE send_alert_msg
(
    in_msg       IN         varchar2,
    out_errmsg   IN OUT     varchar2
)
IS
  l_status integer;
  l_qcount integer;
  l_qmsg qmsg := qmsg('ALERT', in_msg);
  strMsg varchar2(255);

BEGIN

  out_errmsg := 'OKAY';

  begin
    select count(1)
      into l_qcount
      from qt_rp_alerts;
  exception when others then
    l_qcount := 0;
  end;
  if l_qcount < 2 then
    l_status := zqm.send(ALERTS_DEFAULT_QUEUE,
                         l_qmsg.trans, l_qmsg.message, 1, null);
    if l_status != 1 then
      out_errmsg := 'Unable to send alerts author ' || in_msg ||
       ' to alerts queue';
      zms.log_autonomous_msg('ALERTS', null, null,
        out_errmsg,
        'E', 'ALERTS', strMsg);
    end if;
  end if;

exception when others then
  zms.log_autonomous_msg('ALERTS', null, null,
    sqlerrm,
    'E', 'ALERTS', strMsg);
  rollback;
END send_alert_msg;


----------------------------------------------------------------------
--
-- send_email_msg
--
----------------------------------------------------------------------
PROCEDURE send_email_msg
(
    in_to        IN      varchar2,
    in_subject   IN      varchar2,
    in_msg       IN      varchar2,
    out_errmsg   IN OUT     varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   l_status integer;
   l_qmsg qmsg := qmsg(null, null);
   strMsg varchar2(255);
BEGIN
   out_errmsg := 'OKAY';

   l_qmsg.trans := 'MSG';
   l_qmsg.message := in_to || chr(9) ||
                     in_subject || chr(9) ||
                     in_msg || chr(9);

   l_status := zqm.send(EMAILER_DEFAULT_QUEUE,l_qmsg.trans,l_qmsg.message,1,null);

   commit;

   if l_status != 1 then
     out_errmsg := 'Emailer send error ' || to_char(l_status);
     zms.log_autonomous_msg('EMAILER', null, null,
        out_errmsg,'E', 'EMAILER', strMsg);
   end if;

exception when others then
  out_errmsg := 'zamsem:'||sqlerrm;
  zms.log_autonomous_msg('EMAILER', null, null,
        out_errmsg,'E', 'EMAILER', strMsg);
  rollback;
END send_email_msg;

----------------------------------------------------------------------
--
-- recv_email_msg
--
----------------------------------------------------------------------
PROCEDURE recv_email_msg
(
    out_to       OUT      varchar2,
    out_subject  OUT      varchar2,
    out_msg      OUT      varchar2,
    out_errmsg   OUT      varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
   l_status integer;
   l_qmsg qmsg := qmsg(null, null);
   strMsg varchar2(255);

BEGIN

    out_errmsg := 'OKAY';

    out_to := '';
    out_subject := '';
    out_msg := '';

    l_status := zqm.receive(EMAILER_DEFAULT_QUEUE,l_qmsg.message);

    commit;

    if l_status <> 1 then
      out_errmsg := 'Emailer bad receive status: ' || to_char(l_status);
      zms.log_autonomous_msg('EMAILER', null, null,
        out_errmsg, 'E', 'EMAILER', strMsg);
      return;
    end if;

    out_to := nvl(zqm.get_field(l_qmsg.message,1),'(none)');
    out_subject := nvl(zqm.get_field(l_qmsg.message,2),'(none)');
    out_msg := nvl(zqm.get_field(l_qmsg.message,3),'(none)');

exception when others then
   zms.log_autonomous_msg('EMAILER', null, null,
     sqlerrm,'E', 'EMAILER', strMsg);
	 rollback;
END recv_email_msg;


----------------------------------------------------------------------
--
-- process_alerts -
--
----------------------------------------------------------------------
PROCEDURE process_alerts
IS

  CURSOR C_AM
  IS
    SELECT AM.rowid, AM.*, MT.descr
      FROM messagetypes MT, appmsgs AM
     WHERE AM.status = 'NOTI'
       AND AM.msgtype = MT.code(+);

  CURSOR C_AMC(in_author varchar2, in_msgtype varchar2)
  IS
    SELECT *
      FROM app_msgs_contacts
     WHERE author = in_author
       AND msgtype = in_msgtype;

   errmsg varchar2(200);
   msg varchar2(1000);

   msg_fac varchar2(30);
   msg_faccus varchar2(60);

   l_recipients varchar2(32767);

   function xlate_db_address
      (in_addr     in varchar2,
       in_custid   in varchar2,
       in_facility in varchar2)
   return varchar2
   is
      l_addr varchar2(256) := null;
   begin
      if upper(substr(in_addr, 1, 10)) = '$CUSTOMER.' then
         execute immediate 'select '|| substr(in_addr, 11)
               || ' from customer where custid = :p_custid'
            into l_addr using in_custid;
      elsif upper(substr(in_addr, 1, 10)) = '$FACILITY.' then
         execute immediate 'select '|| substr(in_addr, 11)
               || ' from customer where custid = :p_custid'
            into l_addr using in_custid;
      end if;

      return nvl(l_addr, in_addr);
   exception
      when OTHERS then
         return in_addr;
   end xlate_db_address;
BEGIN

   for crec in C_AM loop
      for crec2 in C_AMC(crec.author, crec.msgtype) loop
         if (crec2.custid is null or crec.custid like crec2.custid)
         and (crec2.text_match is null or crec.msgtext like crec2.text_match) then

--          zut.prt('TO:'||crec2.notify||' AUTH:'||crec.author);
--          msg := substr(rpad(nvl(crec.notify,' '),12),1,12)
--             || substr(rpad(nvl(crec.comments,' '),25),1,25)
--             || substr(rpad(nvl(:new.msgtype,' '),1),1,1)
--             || substr(rpad(nvl(:new.facility,' '),3),1,3)
--             || substr(rpad(nvl(:new.custid,' '),10),1,10)
--             || :new.msgtext;

            msg_fac := null;
            msg_faccus := null;
            if crec.facility is not null then
               msg_fac := '   Facility: '||crec.facility;
            end if;
            if crec.custid is not null then
               msg_faccus := msg_fac || ' Custid: '||crec.custid || NLCR;
            end if;

            msg := 'A Synapse condition has occurred at '
                  || substr(rpad(to_char(crec.created,'MM-DD-YYYY HH24:MI:SS'),20),1,20)
                  || NLCR
                  || crec2.comments || NLCR
                  || msg_faccus
                  || 'Type: '||crec.descr|| NLCR
                  || crec.msgtext;

            if nvl(crec2.notify_type, 'OUTLOOK') = 'OUTLOOK' then
               send_email_msg(crec2.notify, 'Synapse Alert: '||crec.author, msg, errmsg);
            else
               l_recipients := xlate_db_address(zsmtp.get_address(crec2.notify),
                     crec.custid, crec.facility);
               while (crec2.notify is not null) loop
                  l_recipients := l_recipients||';'
                        ||xlate_db_address(zsmtp.get_address(crec2.notify), crec.custid, crec.facility);
               end loop;
               zsmtp.mail(l_recipients, 'Synapse Alert: '||crec.author, msg);
            end if;
         end if;
      end loop;
      update appmsgs
         set status = 'UNRV'
         where rowid = crec.rowid;
   end loop;

exception when others then
  errmsg := 'zampa:'||sqlerrm;
END process_alerts;

end zalertmsg;
/

show errors package body zalertmsg;
exit;
