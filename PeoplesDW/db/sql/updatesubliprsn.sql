--
-- $Id$
--
update customer
set subslprsnrequired = 'N'
where subslprsnrequired is null;
update custitem
set subslprsnrequired = 'C'
where subslprsnrequired is null;
commit;
exit;
