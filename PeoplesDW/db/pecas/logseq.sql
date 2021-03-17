--
-- $Id$
--
drop sequence logseq;

create sequence logseq
 increment by 1
 start with 1
 maxvalue   999999999
 minvalue   1
 nocache
 cycle;

exit;
