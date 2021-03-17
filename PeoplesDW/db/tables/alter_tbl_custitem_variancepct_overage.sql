--
-- $Id$
--
alter table custitem add
(variancepct_overage number(3)
,variancepct_use_default char(1)
);

update custitem
   set variancepct_use_default = 'Y'
 where variancepct_use_default is null;

exit;
