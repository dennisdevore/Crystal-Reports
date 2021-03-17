--drop table tariffbreaksclass;

create table tariffbreaksclass
(tariff varchar2(12) not null
,from_weight number(17,8) not null
,to_weight number(17,8) not null
,freight_class varchar2(12) not null
,rate number(12,6) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;