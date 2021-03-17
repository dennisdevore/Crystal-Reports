--
-- $Id$
--
alter table custproductgroup add
(variancepct_overage number(3)
,variancepct_use_default char(1)
);

update custproductgroup
   set variancepct_use_default = 'Y'
 where variancepct_use_default is null;

exit;
