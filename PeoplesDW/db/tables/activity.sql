--
-- $Id$
--
create table activity
(code varchar2(4) not null
,descr varchar2(32) not null
,abbrev varchar2(12) not null
,glacct varchar2(20) not null
,lastuser varchar2(12)
,lastupdate date
);
exit;
