create or replace trigger alert_escalation_bi
before insert
on alert_escalation
for each row
begin

if :new.escalateid is null then
  select escalateidseq.nextval
    into :new.escalateid
    from dual;
end if;


end;
/
show error trigger alert_escalation_bi;

exit;