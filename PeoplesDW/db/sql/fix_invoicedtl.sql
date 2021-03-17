--
-- $Id$
--
update invoicedtl
  set invoice = 0
where invoice is null;

commit;

exit;
