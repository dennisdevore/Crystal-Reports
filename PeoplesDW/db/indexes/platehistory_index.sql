--
-- $Id$
--
drop index platehistory_idx;

create index platehistory_idx on platehistory(lpid, whenoccurred);

exit;
