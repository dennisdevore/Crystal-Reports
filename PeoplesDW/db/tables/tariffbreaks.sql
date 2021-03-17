--drop table tariffbreaks;

create table tariffbreaks
(tariff varchar2(12) not null
,from_weight number(17,8) not null
,to_weight number(17,8) not null
,descr varchar2(32) not null
,abbrev varchar2(12) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;
