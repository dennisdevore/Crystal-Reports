create table alps.routingstatus
(
    code       varchar2(12) not null,
    descr      varchar2(32) not null,
    abbrev     varchar2(12) not null,
    dtlupdate  varchar2(1)      null,
    lastuser   varchar2(12)     null,
    lastupdate date             null
);

create unique index routingstatus_idx on 
    routingstatus(code);

alter table routingstatus add (
     constraint pk_routingstatus  primary key (code));

insert into tabledefs (tableid, hdrupdate, dtlupdate, codemask,
    lastuser, lastupdate)
values('RoutingStatus', 'Y', 'Y', '>Cccccccccccc;0;_', 'SUP',sysdate);

commit;

--exit;
