--
-- $Id$
--
alter table orderdtlline add
(
   weight_entered_lbs number(10),
   weight_entered_kgs number(10)
);

exit;

