--
-- $Id: alter_tblidx_weber_pallet_labels_sscc.sql 9095 2012-11-08 16:53:53Z ed $
--

create index weber_pallet_labels_ssccidx
   on weber_pallet_labels(sscc18);

exit;
