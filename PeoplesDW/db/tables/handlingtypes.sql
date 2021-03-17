--
-- $Id$
--
drop table handlingtypes;

create table handlingtypes
(code varchar2(4) not null
,descr varchar2(32) not null
,abbrev varchar2(12) not null
,activity varchar2(4) not null
,lastuser varchar2(12)
,lastupdate date
);
exit;
