--
-- $Id$
--
alter table custitem add (lotsumaccess varchar2(1));
update custitem set lotsumaccess = 'N';

-- exit;
