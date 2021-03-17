CREATE OR REPLACE package body zalert as
-- **********************************************************************
-- *                                                                    *
-- *      CONSTANTS                                                     *
-- *                                                                    *
-- **********************************************************************
--
--

debug BOOLEAN := False;

last_date   date := null;
last_seq    number := null;

MAILER_ID      constant varchar2(256) := 'Oracle UTL_SMTP';

-- **********************************************************************
-- *                                                                    *
-- *      CURSORS                                                       *
-- *                                                                    *
-- **********************************************************************
--
CURSOR C_ALT(in_alertid number)
IS
SELECT *
  FROM alert_manager
 WHERE alertid = in_alertid;

CURSOR C_AC(in_useralertid number)
IS
SELECT *
  FROM alert_contacts
 WHERE useralertid = in_useralertid;

CURSOR C_AE(in_escalateid number)
IS
SELECT *
  FROM alert_escalation
 WHERE useralertid = in_escalateid;



-- **********************************************************************
-- *                                                                    *
-- *      PROCEDURES AND FUNCTIONS                                      *
-- *                                                                    *
-- **********************************************************************


----------------------------------------------------------------------
--
-- log - add a log entry
--
----------------------------------------------------------------------
PROCEDURE log
(
    in_src  varchar2,
    in_msg  varchar2
)
IS PRAGMA AUTONOMOUS_TRANSACTION;
l_seq number;
l_dt date;
BEGIN

    l_dt := sysdate;

    if last_date is null
    or last_date != l_dt then
        l_seq := 1;
    else
        l_seq := last_seq + 1;
    end if;

    last_date := l_dt;
    last_seq := l_seq;

    INSERT into imt_log(created,seq,source,message)
    VALUES(l_dt,l_seq,in_src, in_msg);

    COMMIT;
EXCEPTION WHEN OTHERS THEN
    null;
END log;



----------------------------------------------------------------------
--
-- send_msg
--
---------------------------------------------------------------------
PROCEDURE send_msg(in_alertid number)
IS

ALT alert_manager%rowtype;
AC alert_contacts%rowtype;

cnt integer;
l_dt date;

l_msg varchar2(32767);




BEGIN

l_msg := null;

ALT := null;
OPEN C_ALT(in_alertid);
FETCH C_ALT into ALT;
CLOSE C_ALT;

if ALT.status not in ('NOTI','UNRV') then
    return;
end if;

AC := null;
OPEN C_AC(ALT.useralertid);
FETCH C_AC into AC;
CLOSE C_AC;

-- Setup message 
l_msg := 
    '----------------------------------------------------------------------' ||
    utl_tcp.crlf ||
    'Alert Name: '|| AC.name || utl_tcp.crlf ||
    'Customer:   '|| ALT.custid || utl_tcp.crlf ||
    'Facility:   '|| ALT.facility || utl_tcp.crlf ||
    'Alert Type: '|| ALT.msgtype || utl_tcp.crlf ||
    'Date/Time:  '|| to_char(ALT.created, 'YYYY/MM/DD HH24:MI:SS') 
                    || utl_tcp.crlf ||
    'Created By: '|| ALT.author || utl_tcp.crlf ||
    'Description: '|| ALT.msgtext || utl_tcp.crlf ||
    '----------------------------------------------------------------------' ||
    utl_tcp.crlf ||
    utl_tcp.crlf ||
    AC.comments;

-- Check if sent anything yet
cnt := 0;
select count(1)
  into cnt
  from alert_history
 where alertid = in_alertid
   and escalateid = 0;


if nvl(cnt,0) = 0 then


-- This is the first time thru
    insert into alert_history(alertid, escalateid, sentdate)
        values(in_alertid, 0, sysdate);
    if nvl(AC.priority,'N') <> 'Y' then
        zsmtp.send_mail(AC.sender, AC.notify, AC.notify_cc, AC.notify_bcc,
            AC.subject, l_msg);
    else 
        zsmtp.send_mail(AC.sender, AC.notify, AC.notify_cc, AC.notify_bcc,
            AC.subject, l_msg, 1);
    end if;
    return;
end if;

-- Determine the escalations to send
for AE in (select *
             from alert_escalation
            where useralertid = AC.useralertid
              and escalateid not in 
                (select escalateid
                   from alert_history
                  where alertid = in_alertid))
loop
    l_dt := ALT.created;
    if AE.frequency = 'Min' then
        l_dt := l_dt + (AE.interval / 1440);
    elsif AE.frequency = 'Hour' then
        l_dt := l_dt + (AE.interval / 24);
    elsif AE.frequency = 'Day' then
        l_dt := l_dt + (AE.interval);
    elsif AE.frequency = 'Week' then
        l_dt := l_dt + (AE.interval * 7);
    end if;

    if l_dt < sysdate then

        insert into alert_history(alertid, escalateid, sentdate)
            values(in_alertid, AE.escalateid, sysdate);

        zsmtp.send_mail(nvl(zci.default_value('SMTP_SENDER'),
                    'synapse@'||zci.default_value('SMTP_DOMAIN')), 
            AE.notify, '', '',
            'ESCALATED ALERT('||AC.subject||')', l_msg, 1);
        
        update alert_manager
           set status = 'NOTI'
         where alertid = in_alertid;

    end if;
end loop;

END send_msg;


----------------------------------------------------------------------
--
-- setup_msg
--
---------------------------------------------------------------------
PROCEDURE setup_msg(in_alertid number)
IS

ALT alert_manager%rowtype;
AC alert_contacts%rowtype;


l_dt date;
l_least date;

BEGIN

ALT := null;
OPEN C_ALT(in_alertid);
FETCH C_ALT into ALT;
CLOSE C_ALT;

AC := null;
OPEN C_AC(ALT.useralertid);
FETCH C_AC into AC;
CLOSE C_AC;

l_least := null;

-- Determine the next escalations to send
for AE in (select *
             from alert_escalation
            where useralertid = AC.useralertid
              and escalateid not in 
                (select escalateid
                   from alert_history
                  where alertid = in_alertid))
loop
    l_dt := null;
    if AE.frequency = 'Min' then
        l_dt := ALT.created + (AE.interval / 1440);
    elsif AE.frequency = 'Hour' then
        l_dt := ALT.created + (AE.interval / 24);
    elsif AE.frequency = 'Day' then
        l_dt := ALT.created + (AE.interval);
    elsif AE.frequency = 'Week' then
        l_dt := ALT.created + (AE.interval * 7);
    end if;

    if l_dt is not null then
        if l_dt <= nvl(l_least, l_dt) then
            l_least := l_dt;
        end if;
    end if;

end loop;

if ALT.status != 'NOTI' then
    l_least := null;
end if;

update alert_manager
   set nextsend = l_least
 where alertid = in_alertid;

END setup_msg;


----------------------------------------------------------------------
--
-- alert_process
--
---------------------------------------------------------------------
PROCEDURE alert_process
IS

errno integer;
errmsg varchar2(255);
msg_in varchar2(255);

curr_date    number;

msgtype varchar2(1);
exp number;
l_msg varchar2(255);

descr varchar2(60);

CURSOR C_FAC(in_facility varchar2)
IS
SELECT name
  FROM facility
 WHERE facility = in_facility;

fac_name facility.name%type;
  

BEGIN
    loop
        dbms_lock.sleep(60);
      
        for cr in (select alertid
                     from alert_manager
                    where nextsend <= sysdate)
        loop
        -- Have something to send check to determine what it is
            send_msg(cr.alertid);

        -- setup for next escalation if there is any
            setup_msg(cr.alertid);

        end loop;

        commit;

    end loop;
    
EXCEPTION
    WHEN OTHERS THEN
        log('alert_process',substr(sqlerrm,1,100));
END alert_process;

end zalert;
/
exit;
