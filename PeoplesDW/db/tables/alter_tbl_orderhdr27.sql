--
-- $Id$
--
alter table orderhdr add(
  xdockprocessing varchar(2) null
);

update orderhdr set xdockprocessing = 'S'
 where xdockprocessing is null;
commit;
exit;
