--
-- $Id: alter_tbl_facility05.sql 960 2006-06-20 21:58:44Z mikeh $
--
alter table facility add
(
   cc_item_summary char(1) default 'N'
);

commit;

exit;
