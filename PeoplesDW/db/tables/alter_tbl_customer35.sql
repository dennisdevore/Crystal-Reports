--
-- $Id$
--
alter table customer add(
  xdockprocessing varchar(2) null
);

update customer set xdockprocessing = 'S';
commit;
exit;
