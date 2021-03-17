--drop table tariff;

create table tariff
(tariff varchar2(12) not null
,descr varchar2(32) not null
,max_truckload_charge number(12,6)
,discountable_flag varchar2(1) not null
,comment1 clob
,lastuser varchar2(12)
,lastupdate date
);

exit;
