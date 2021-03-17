--
-- $Id$
--
drop table app_msgs_contacts;

create table app_msgs_contacts
(author varchar2(12) not null
,msgtype varchar2(3)
,notify varchar2(12)
,notify_type varchar2(10)
,lastuser varchar2(12)
,lastupdate date
,comments varchar2(25)
);

create index app_msgs_contacts_author
   on app_msgs_contacts(author,msgtype);

exit;
