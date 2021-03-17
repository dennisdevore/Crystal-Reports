--
-- $Id$
--
alter table deletedplate add
(qtytasked number(7)
,childfacility varchar2(3)
,childitem varchar2(50)
,parentfacility varchar2(3)
,parentitem varchar2(50)
);

exit;
