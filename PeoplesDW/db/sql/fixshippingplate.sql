--
-- $Id$
--
alter table shippingplate modify (custid null);
alter table shippingplate modify (item null);

update shippingplate set custid = null where custid = '(mixed)';

update shippingplate set item = null where item = '(mixed)';

update shippingplate set parentlpid = null where parentlpid = lpid;

exit;
