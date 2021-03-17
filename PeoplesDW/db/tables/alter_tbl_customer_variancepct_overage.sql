--
-- $Id$
--
alter table customer add
(
variancepct_overage number(3)
);

update customer
   set variancepct = 0,
       variancepct_overage = 100
 where variancepct_overage is null;

exit;
