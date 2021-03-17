--
-- $Id$
--
alter table allocrulesdtl add
(wholeunitsonly char(1)
);

update allocrulesdtl
   set wholeunitsonly = 'N';
commit;
--exit;
