create or replace trigger alert_contacts_bi
before insert
on alert_contacts
for each row
begin

if :new.useralertid is null then
  select useralertidseq.nextval
    into :new.useralertid
    from dual;

  :new.lastupdate := sysdate;
  :new.created := sysdate;
  :new.userid := :new.lastuser;
end if;

end;
/
create or replace trigger alert_contacts_ad
after delete
on alert_contacts
for each row
begin

delete from alert_escalation
where useralertid = :old.useralertid;

end;
/
show error trigger alert_contacts_bi;
show error trigger alert_contacts_ad;

exit;