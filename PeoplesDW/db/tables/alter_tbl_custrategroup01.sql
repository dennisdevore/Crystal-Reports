--
-- $Id$
--
alter table custrategroup add(
    linkyn  char(1),
    linkrategroup varchar2(10));

update custrategroup
   set linkyn = 'N';

exit;
