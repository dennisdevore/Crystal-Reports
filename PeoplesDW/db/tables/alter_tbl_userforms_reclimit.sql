--
-- $Id$
--
alter table userforms add
(
   reclimit  number(5)
);

update userforms
set reclimit = 100
where reclimit is null;

commit;

exit;
