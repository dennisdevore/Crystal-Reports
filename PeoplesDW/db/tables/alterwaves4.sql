--
-- $Id$
--
alter table waves add
(fromlot  varchar2(30)
,tolot    varchar2(30)
,orderlimit number(5)
);

exit;
