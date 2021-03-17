--
-- $Id: add_enable_shippingplatehistory.sql 5785 2010-11-24 21:49:48Z ed $
--
insert into systemdefaults values ('ENABLE_SHIPPINGPLATEHISTORY', 'Y', 'SYNAPSE', sysdate);

exit;
