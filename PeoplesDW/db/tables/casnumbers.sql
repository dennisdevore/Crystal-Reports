--
-- $Id: casnumbers.sql 1 2006-09-01 00:00:00Z eric $
--
create table casnumbers
(CAS VARCHAR2(12) not null
,DESCR VARCHAR2(255) not null
,ABBREV VARCHAR2(12) not null
,WEIGHT NUMBER(13,4)
,LASTUSER VARCHAR2(12)
,LASTUPDATE DATE
);

create unique index casnumbers_unique
   on casnumbers(cas);

exit;
