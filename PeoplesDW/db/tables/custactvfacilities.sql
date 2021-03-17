--
-- $Id$
--
drop table custactvfacilities;

create table custactvfacilities
(
    custid      varchar2(10) not null,
    activity    varchar2(4) not null,
    facilities  varchar2(200),
    lastuser    varchar2(12),
    lastupdate  date
);
