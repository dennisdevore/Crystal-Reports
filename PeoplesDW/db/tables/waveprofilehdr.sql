create table waveprofilehdr (
    facility        varchar2(3)     not null,
    profile         varchar2(10)    not null,
    descr           varchar2(36),
    abbrev          varchar2(12),
    lastuser        varchar2(12),
    lastupdate      date
);

create unique index waveprofilehdr_unique on
        waveprofilehdr(facility, profile);

exit;
