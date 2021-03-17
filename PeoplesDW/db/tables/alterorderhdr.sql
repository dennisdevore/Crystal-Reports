--
-- $Id$
--
alter table orderhdr
add
(parentorderid number(7)
,parentshipid number(2)
,parentorderitem varchar2(50)
,parentorderlot varchar2(30)
);
exit;
