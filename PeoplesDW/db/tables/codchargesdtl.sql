--drop table codchargesdtl;

create table codchargesdtl
(codid varchar2(12) not null
,from_amount number(12,6) not null
,to_amount number(12,6) not null
,cod_charge number(12,6) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;