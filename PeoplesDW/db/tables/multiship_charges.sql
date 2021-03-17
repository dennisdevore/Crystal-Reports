/* drop table multiship_charges; */

create table multiship_charges
(
    cartonid    varchar2(15),
    orderid     number(9),
    shipid      number(2),
    trackid     varchar2(30),
    published_rate  number(6,2),
    discount    number(6,2),
    residential_das number(6,2),
    transport   number(6,2),
    other       number(6,2),
    fsc         number(6,2),
    manifest    number(6,2),
    payacct     varchar2(20),
    zone        varchar2(5),
    dimweight   number(13,4),
    nmflag      char(1),
    shipcharge_activity char(4),
    lastuser    varchar2(12),
    lastupdate  date,
    constraint multiship_charges_pk primary key (cartonid)
);

create index multiship_charges_ord on multiship_charges(orderid, shipid);

exit;
