--
-- $Id$
--
alter table customer add(
  use_ailabels char(1)
);

update customer set use_ailabels = 'N';
commit;
exit;
