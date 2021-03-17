--
-- $Id$
--
alter table custproductgroup add(
putawayconfirmation char(1),
ordercheckrequired char(1),
weightcheckrequired char(1),
status varchar2(4)
);

exit;
