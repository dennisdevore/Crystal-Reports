--
-- $Id$
--
create table cartontypes
(code varchar2(4) not null
,descr varchar2(36) not null
,abbrev varchar2(12) not null
,length number(10,4) not null
,width number(10,4) not null
,height number(10,4) not null
,maxweight number(10,4) not null
,maxcube number(10,4) not null
,lastuser varchar2(12)
,lastupdate date
);

exit;
