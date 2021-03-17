--
-- $Id$
--
update customer
set packlist = 'N'
where packlist is null;
commit;
exit;
