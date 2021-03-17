--
-- $Id: alter_tbl_orderdtl18.sql 170 2006-07-25 00:00:00Z eric $
--
alter table orderdtl add
(
   unrestrict_lot_sub varchar2(1) default 'N'
);

exit;


