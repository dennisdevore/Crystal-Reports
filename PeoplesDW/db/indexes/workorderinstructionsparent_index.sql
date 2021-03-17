--
-- $Id$
--
--drop index workorderinstrparent_idx;

create index workorderinstrparent_idx
   on workorderinstructions(parent);

exit;
