--
-- $Id$
--
alter table customer
add
(dup_reference_ynw char(1)
);
update customer
   set dup_reference_ynw = 'Y'
 where dup_reference_ynw is null;
--exit;
