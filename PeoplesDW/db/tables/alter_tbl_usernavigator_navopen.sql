alter table usernavigator add
(
  navopen    char(1)
);

update usernavigator
set navopen = 'Y'
where navopen is null;

commit;

exit;
