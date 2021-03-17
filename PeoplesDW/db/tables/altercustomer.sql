--
-- $Id$
--
alter table customer add
(weightcheckrequired char(1)
,ordercheckrequired char(1)
,fifowindowdays number(3)
,putawayconfirmation char(1)
);

exit;
