create table waveprofiledtl (
    facility        varchar2(3)     not null,
    profile         varchar2(10)    not null,
    priority        number(7),
    wavedescr       varchar2(36),
    lastuser        varchar2(12),
    lastupdate      date
);

create unique index waveprofiledtl_unique on
        waveprofiledtl(facility, profile, priority);

exit;
