--
-- $Id$
--
alter table ucc_standard_labels add
(
   itemweight  number(17,8),
   vendhuman   varchar2(255),
   vendbar     varchar2(255)
);

exit;
