--
-- $Id$
--
alter table customer add
(
   ok_to_pick_unreleased_ai   char(1) default 'N'
);

exit;
