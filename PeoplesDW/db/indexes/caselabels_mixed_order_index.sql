--
-- $Id: caselabels_index.sql 1 2005-05-26 12:20:03Z ed $
--
create index caselabels_mox1 on caselabels
   (mixedorderorderid, mixedordershipid, item, lotnumber);

exit;
