create table alert_contacts (
    useralertid         number(10) not null,
    created             date,
    userid              varchar2(12),
    name                varchar2(30),
    author              varchar2(12) not null,
    msgtype             varchar2(3),
    facility            varchar2(3),
    custid              varchar2(10),
    text_match          varchar2(50),
    sender              varchar2(50),
    subject             varchar2(50),
    notify_type         varchar2(10),
    notify              varchar2(255),
    notify_cc           varchar2(255),
    notify_bcc          varchar2(255),
    priority            char(1),
    comments            varchar2(1000),
    lastuser            varchar2(12),
    lastupdate          date,
 constraint alert_contacts_pk primary key (useralertid)
);

create index alert_contacts_author_idx on alert_contacts(author, msgtype);
create unique index alert_contacts_name_idx on alert_contacts(name);

create sequence alps.alertidseq
  start with 1
  maxvalue 9999999999
  minvalue 1
  cycle
  nocache
  noorder;

insert into
alert_contacts
(
  useralertid,
  created,
  userid,
  name,
  author,
  msgtype,
  facility,
  custid,
  text_match,
  sender,
  subject,
  notify_type,
  notify,
  notify_cc,
  notify_bcc,
  priority,
  comments,
  lastuser,
  lastupdate
)
select
  useralertidseq.nextval,
  sysdate,
  'SYNAPSE',
  null,
  amc.author,
  amc.msgtype,
  null,
  amc.custid,
  amc.text_match,
  nvl(sd.defaultvalue,'SYNAPSE'),
  'Synapse Alert',
  amc.notify_type,
  amc.notify,
  null,
  null,
  null,
  amc.comments,
  'SYNAPSE',
  sysdate
from app_msgs_contacts amc, systemdefaults sd
where sd.defaultid (+) = 'SMTP_SENDER';

update alert_contacts
set name='ALERT'||useralertid
where name is null;

exit;
