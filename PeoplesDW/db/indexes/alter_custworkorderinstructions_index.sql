--
-- $Id$
--
drop index custworkorderinst_parent;

create index custworkorderinst_parent
   on custworkorderinstructions(seq, parent);
exit;
