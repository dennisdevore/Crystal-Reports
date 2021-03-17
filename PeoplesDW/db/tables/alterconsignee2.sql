--
-- $Id$
--
alter table consignee add(
	apptrequired char(1),
	billforpallets char(1),
	masteraccount  varchar2(10)
);

update consignee
	set apptrequired ='N', billforpallets = 'N';
	
commit;


-- exit;
