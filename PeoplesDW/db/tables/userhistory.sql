--
-- $Id$
--
create table userhistory
(
   nameid      varchar2(12) not null,
   begtime     date not null,
   event       varchar2(4) not null,
   endtime     date,
   facility    varchar2(3),
   custid      varchar2(10),
   equipment   varchar2(2),
   units       number(7),
   etc         varchar2(255)
);

create index userhistory_idx on userhistory
   (nameid, begtime, event);

exit;
