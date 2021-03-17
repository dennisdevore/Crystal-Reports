--
-- $Id$
--
drop table custinvstatuschange;
create table custinvstatuschange (
    custid  varchar2(10)        not null,
    fromstatus  varchar2(2)     not null,
    tostatus    varchar2(2)     not null,
    loctype     varchar2(3)     not null,
    adjreason   varchar2(2)     not null,
    tasktypes   varchar2(255),
    lastuser    varchar2(12),
    lastupdate  date);

create unique index custinvstatuschange_pk
on custinvstatuschange(custid, fromstatus, loctype);

exit;
