--
-- $Id$
--
alter table orderhdr add
(
  has_consumables  char(1) default 'N'
);

update orderhdr set has_consumables = 'N';

commit;
exit;
