--
-- $Id$
--
drop index storageparms_pk_idx;

create unique index storageparms_pk_idx
   on storageparms(objectclass);

exit;
exit;
