--
-- $Id$
--
alter table orderhdr
add
(rejectcode number(6)
,rejecttext varchar2(255)
,dateshipped date
);
exit;
