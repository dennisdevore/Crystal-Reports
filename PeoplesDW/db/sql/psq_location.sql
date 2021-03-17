--
-- $Id$
--
create table psq_location (
 facility     varchar2(3),
 locid        varchar2(10),
 putawayseq   number(7)
);

create unique index psq_location_unique on psq_location
   (facility, locid);

exit;
