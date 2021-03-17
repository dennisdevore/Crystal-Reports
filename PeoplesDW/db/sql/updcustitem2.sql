--
-- $Id$
--
update custitem
set lotsumreceipt = 'N',
lotsumrenewal = 'N',
lotsumbol = 'N'
where lotsumreceipt is null;
exit;
