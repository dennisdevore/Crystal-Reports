--
-- $Id: add_billingmethod_freight.sql $
--
--delete from billingmethod where code = 'FGHT';

insert into billingmethod
	values('FGHT','Freight','Freight','N','ZETHCON',SYSDATE);
	
exit;