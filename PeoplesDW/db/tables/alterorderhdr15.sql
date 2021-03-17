--
-- $Id$
--
alter table orderhdr add(
	transapptdate date,
	deliveryaptconfname varchar2(20),
	interlinecarrier varchar2(4),
	companycheckok char(1)
);

update orderhdr set companycheckok = 'N';

commit;

exit;
