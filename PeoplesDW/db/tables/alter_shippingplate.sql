--
-- $Id$
--
alter table shippingplate add
(openfacility varchar2(3)
);
update shippingplate
   set openfacility = facility
 where type in ('F','P')
   and status != 'SH';
exit;
