--
-- $Id$
--
alter table userhistory add
(
   baseuom     varchar2(4),
   baseunits   number(7),
   cube        number(10,4),
   weight      number(17,8)
);
exit;
