--
-- $Id$
--
drop index pk_multishipcodes;
create unique index pk_multishipcodes
on multishipcodes(convcode);
exit;

