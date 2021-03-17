--
-- $Id$
--
create index userhistory_begin_event on
   userhistory(begtime, event);

exit;
