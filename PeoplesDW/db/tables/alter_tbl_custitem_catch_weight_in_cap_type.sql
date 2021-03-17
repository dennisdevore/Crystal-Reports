--
-- $Id$
--
alter table custitem add
(
   catch_weight_in_cap_type   char(1) default 'G'
);

exit;
