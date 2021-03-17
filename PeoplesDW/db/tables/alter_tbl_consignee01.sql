--
-- $Id: $
--

alter table consignee add (bolemail char(1));

update consignee set bolemail = 'N' where bolemail is null;

exit;
