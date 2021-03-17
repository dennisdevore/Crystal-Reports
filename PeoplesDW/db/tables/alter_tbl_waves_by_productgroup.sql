--
-- $Id$
--
alter table waves add
(
    pick_by_productgroup  char(1) default 'N'
);

exit;