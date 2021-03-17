create table alert_manager (
    alertid     number(10) not null,
    useralertid number(10) not null,
    created     date not null,
    author      varchar2(12),
    facility    varchar2(3),
    custid      varchar2(10),
    msgtext     varchar2(255),
    msgtype     varchar2(1),
    status      varchar2(4),
    nextsend    date,
    lastuser    varchar2(12),
    lastupdate  date, 
  constraint alert_manager_pk primary key (alertid));

create index alert_manager_nextsend_idx on alert_manager(nextsend);

create index alert_manager_status_idx on alert_manager(status);

create index alert_manager_created_idx on alert_manager(created);

create index alert_manager_author_idx on alert_manager(author, created);

exit;


