--
-- $Id$
--
create table loadstopbolcomments
(loadno number(7) not null
,stopno number(7) not null
,bolcomment long
,lastuser varchar2(12)
,lastupdate date
);
exit;