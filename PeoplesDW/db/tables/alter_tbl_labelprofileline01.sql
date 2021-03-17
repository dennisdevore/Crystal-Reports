--
-- $Id$
--
alter table labelprofileline modify
(
   viewname       varchar2(255),
   viewkeycol     null,
   printerstock   null
);
exit;
