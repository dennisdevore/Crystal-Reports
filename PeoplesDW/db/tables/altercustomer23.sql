--
-- $Id$
--
alter table customer add(
	billforpallets char(1),
	masteraccount  varchar2(10)
);

update customer
	set billforpallets = 'N';
	
commit;


-- exit;
