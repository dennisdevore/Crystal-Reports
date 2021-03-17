--
-- $Id
--
alter table userforms add
(
  formstate number(1)
);

update userforms
set formstate = 2
where formstate is null;

commit;

exit;
