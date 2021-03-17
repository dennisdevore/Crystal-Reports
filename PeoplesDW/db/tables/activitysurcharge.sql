create table activitysurcharge
(
    activity    varchar2(4) not null,
    surcharge   varchar2(4) not null,
    lastuser    varchar2(12),
    lastupdate  date,
constraint activitysurcharge_pk primary key  (activity, surcharge)
);

exit;
