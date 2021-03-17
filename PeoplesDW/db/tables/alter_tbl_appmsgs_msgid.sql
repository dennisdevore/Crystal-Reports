--
-- $Id
--
alter table appmsgs add
(
   msgid      number(10)
);

update appmsgs
set msgid = rownum
where msgid is null;

alter table appmsgs
modify(msgid not null);

exit;
