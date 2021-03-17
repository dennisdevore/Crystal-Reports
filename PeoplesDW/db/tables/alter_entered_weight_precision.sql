--
-- $Id$
--
alter table orderdtl modify
(
   weight_entered_lbs number(14,4),
   weight_entered_kgs number(14,4)
);

alter table orderhdr modify
(
   weight_entered_lbs number(14,4),
   weight_entered_kgs number(14,4)
);

alter table loadstopship modify
(
   weight_entered_lbs number(14,4),
   weight_entered_kgs number(14,4)
);

alter table loadstop modify
(
   weight_entered_lbs number(14,4),
   weight_entered_kgs number(14,4)
);

alter table loads modify
(
   weight_entered_lbs number(14,4),
   weight_entered_kgs number(14,4)
);

exit;


