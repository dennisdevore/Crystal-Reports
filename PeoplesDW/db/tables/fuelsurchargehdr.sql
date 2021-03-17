--drop table fuelsurchargehdr;

create table fuelsurchargehdr
(surchargeid varchar(12) not null
,descr varchar(32) not null
,comment1 clob
,lastuser varchar(12)
,lastupdate date
);