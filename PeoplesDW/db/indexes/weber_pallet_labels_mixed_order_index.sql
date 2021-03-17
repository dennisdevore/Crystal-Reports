--
-- $Id: weber_pallet_labels_mixed_order_index.sql 1 2005-05-26 12:20:03Z ed $
--
create index weber_pallet_labels_mox1 on weber_pallet_labels
   (mixedorderorderid, mixedordershipid);

exit;
