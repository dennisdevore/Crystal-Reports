--
-- $Id$
--
alter table carrier add
(
   freetimedays      number(7),
   dailydemurrage    number(10,2),
   liveunloadtime    number(7)
);

exit;
