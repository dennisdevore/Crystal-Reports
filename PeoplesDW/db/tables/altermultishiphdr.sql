--
-- $Id$
--
alter table multishiphdr add(
    satdelivery     varchar2(1),
    orderstatus     varchar2(1),
    orderpriority   varchar2(1),
    ordercomments   varchar2(80)
);

exit;