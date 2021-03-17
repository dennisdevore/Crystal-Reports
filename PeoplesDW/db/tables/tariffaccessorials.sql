--drop table tariffaccessorials;

create table tariffaccessorials
(tariff varchar2(12) not null
,activitycode varchar2(4) not null
,flat_charge number(12,6)
,cwt_rate number(12,6)
,min_cwt_charge number(12,6)
,rateflag varchar2(1) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;