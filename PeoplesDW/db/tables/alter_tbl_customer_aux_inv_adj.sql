--
-- $Id: alter_tbl_customer_aux_inv_adj.sql 1558 2007-02-05 20:26:20Z brianb $
--
alter table customer_aux add
(
inv_adj_export_format varchar2(255),
warn_before_sending_inv_adj char(1) default 'N'
);

exit;
