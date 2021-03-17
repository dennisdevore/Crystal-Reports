--drop table fuelsurchargedtl;

create table fuelsurchargedtl
(surchargeid varchar2(12) not null
,effdate date not null
,surcharge_percent number(4,2) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;