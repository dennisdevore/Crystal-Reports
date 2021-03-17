--
-- $Id$
--
alter table custbilldates add(
      lastrenewal         date,
      lastreceipt         date,
      lastmiscellaneous   date,
      lastassessorial     date
);

exit;