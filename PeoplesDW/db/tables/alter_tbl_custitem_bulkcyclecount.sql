--
-- $Id$
--
alter table custitem add
(
   bulkcount_expdaterequired  char(1),
   bulkcount_mfgdaterequired  char(1)
);

exit;
