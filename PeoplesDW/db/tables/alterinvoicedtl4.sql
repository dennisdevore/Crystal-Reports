--
-- $Id$
--
alter table invoicedtl add
(
 useinvoice     varchar2(8),
 weight         number(10,4)
);

exit;
