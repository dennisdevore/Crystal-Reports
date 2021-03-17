--
-- $Id$
--
drop index usertoolbar_unique;

create unique index usertoolbar_unique on
  usertoolbar(userid);
exit;