--
-- $Id: alter_tbl_custfacility_tariff.sql $
--
alter table custfacility add
(
tariff varchar2(12)
,discount number(5,2)
,codid varchar2(12)
,surchargeid varchar(12)	
);

exit;
