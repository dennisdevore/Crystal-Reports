--
-- $
--
alter table allocrulesdtl add
(
   bylot   varchar2(1)
);

update allocrulesdtl
set bylot = 'N'
where bylot is null;

exit;
