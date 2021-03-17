create table alert_escalation (
    escalateid          number(10) not null,
    useralertid         number(10) not null,
    notify              varchar2(255),
    interval            number(5),
    frequency           varchar2(10),
 constraint alert_escalation_pk primary key (escalateid)
);

create index alert_contacts_useralertid_idx on alert_escalation(useralertid);


exit;
