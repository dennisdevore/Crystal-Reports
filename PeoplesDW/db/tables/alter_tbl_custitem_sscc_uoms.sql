--
-- $Id: alter_tbl_custitem_26.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custitem add (
   sscccasepackfromuom varchar2(4),
   sscccasepacktouom varchar2(4)
);

exit;

