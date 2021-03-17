--
-- $Id$
--
create table allocruleshdr
(facility varchar2(3)
,allocrule varchar2(10) not null
,descr varchar2(36)
,abbrev varchar2(12)
,lastuser varchar2(12)
,lastupdate date
);
exit;