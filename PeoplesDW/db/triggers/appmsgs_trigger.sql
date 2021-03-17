--
-- Trigger to set status to need to send if entry in table
--   and to send the message
--
create or replace trigger appmsgs_bi
--
-- $Id$
--
before insert
on appmsgs
for each row
declare
   cursor c_amc(in_author varchar2, in_msgtype varchar2) is
      select *
         from alert_contacts
         where author = in_author
           and msgtype = in_msgtype
         order by custid, text_match;
   amc c_amc%rowtype;
   errmsg varchar2(100);
begin

    select msgidseq.NEXTVAL into :new.msgid from dual;

   open c_amc(:new.author, :new.msgtype);
   loop
      fetch c_amc into amc;
      exit when c_amc%notfound;

      if (amc.custid is null or :new.custid like amc.custid)
      and (amc.text_match is null or :new.msgtext like amc.text_match) 
      and (amc.facility is null or :new.facility like amc.facility) 
      then
         :new.status := 'UNRV';
        insert into alert_manager (
            alertid,
            created,
            useralertid,
            contactuserid, 
            author,
            facility,
            custid,
            msgtext,
            msgtype,
            status,
            nextsend,
            sender,
            notify,
            lastuser,
            lastupdate)
        values (
            alertidseq.nextval,
            sysdate,
            amc.useralertid,
            amc.userid,
            :new.author,
            :new.facility,
            :new.custid,
            :new.msgtext,
            :new.msgtype,
            :new.status,
            sysdate,
            amc.sender,
            amc.notify,
            :new.lastuser,
            sysdate);
    -- zqm.send('alerts','msg','check',1,null);

--         zam.send_alert_msg(:new.author, errmsg);
--         exit;
      end if;
   end loop;
   close c_amc;
end;
/
show error trigger appmsgs_bi;

exit;
