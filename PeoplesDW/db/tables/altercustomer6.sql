--
-- $Id$
--
alter table customer add
(
   sumassessorial       varchar2(1),
   lastaccountmin       date,
   prevaccountmin       date
);

exit;
