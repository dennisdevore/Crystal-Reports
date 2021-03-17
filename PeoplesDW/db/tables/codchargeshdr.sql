--drop table codchargeshdr;

create table codchargeshdr
(codid varchar2(12) not null
,descr varchar2(32) not null
,comment1 clob
,lastuser varchar2(12)
,lastupdate date
);

exit;