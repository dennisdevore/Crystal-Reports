create table fac_usersessions (
    facility varchar2(3),
    time_period date,
    crt number default 0,
    legacyrf number default 0,
    webrf number default 0,
    total number default 0,
    primary key (facility, time_period)
);

create index fac_usersess_time_fac on fac_usersessions(time_period, facility);

exit;
/