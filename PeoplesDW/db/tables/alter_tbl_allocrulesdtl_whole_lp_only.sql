--
-- $Id
--
alter table allocrulesdtl add
(wholelponly char(1)
);

update allocrulesdtl
   set wholelponly = 'N'
 where wholelponly is null;
commit;
--exit;
