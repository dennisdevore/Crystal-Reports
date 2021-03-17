--
-- $Id$
--
update impexp_definitions
set includecrlf = 'N'
where includecrlf is null;
commit;
exit;

