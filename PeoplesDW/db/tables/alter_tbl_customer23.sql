--
-- $Id$
--
alter table customer add
(
   multifac_picking char(1)
);

update customer
	set multifac_picking = 'N'
   where multifac_picking is null;

commit;

exit;
