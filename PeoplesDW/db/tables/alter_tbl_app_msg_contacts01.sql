--
-- $Id$
--
alter table app_msgs_contacts add
(
   custid      varchar2(10),
   text_match  varchar2(50)
);

alter table app_msgs_contacts modify
(
   notify varchar2(255)
);

exit;
