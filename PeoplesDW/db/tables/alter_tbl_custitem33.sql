--
-- $Id$
--
alter table custitem add
(
  msdsformat   varchar2(255),
  printmsds    char(1) default 'N'
);
update custitem set printmsds = 'N';

commit;

exit;
