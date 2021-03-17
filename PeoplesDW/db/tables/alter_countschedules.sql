--
-- $Id$
--
alter table countschedules
add
(
facility varchar2(3),
reqtype varchar2(12)
);
exit;
