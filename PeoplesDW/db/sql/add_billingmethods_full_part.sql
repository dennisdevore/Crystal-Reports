--
-- $Id: add_billingmethod_tariff.sql $
--
insert into billingmethod
	values('FULL','Full Pick','Full Pick','N','ZETHCON',SYSDATE);
  
insert into billingmethod
	values('PART','Partial Pick','Partial Pick','N','ZETHCON',SYSDATE);
	
exit;