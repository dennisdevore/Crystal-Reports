--
-- $Id: alter_tbl_ucc_standard_labels_27_2.sql 5943 2011-01-11 15:27:01Z ed $
--
alter table ucc_standard_labels add
(
   bigseq  number(7),
   bigseqof number(7)
);

exit;
