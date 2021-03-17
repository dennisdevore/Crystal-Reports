--
-- $Id$
--
alter table customer add
(
  defpalletqty number(7)
);
update customer
set defpalletqty = 0
where defpalletqty is null;
commit;
--exit;
