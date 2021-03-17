--
-- $Id$
--
alter table invoicedtl add
(
orderitem varchar2(50),
orderlot varchar2(30),
shipid number(2)
);

exit;
