create table alert_history (
    alertid             number(10) not null,
    escalateid          number(10) not null,
    sentdate            date
);

create index alert_contacts_alertid_idx on alert_history(alertid);

exit;
