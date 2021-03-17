--
-- $Id$
--
alter table custitem add
(
   allow_component_overpicking   char(1) default 'N'
);

exit;
