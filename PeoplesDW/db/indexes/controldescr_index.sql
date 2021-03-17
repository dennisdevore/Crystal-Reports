--
-- $Id$
--
drop index controldescr_unique;

create unique index controldescr_unique
on controldescr(controlnumber);

exit;

