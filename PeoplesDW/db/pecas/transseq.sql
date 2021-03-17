--
-- $Id$
--
drop sequence transseq;

create sequence transseq
 increment by 1
 start with 1
 maxvalue   999999999
 minvalue   1
 nocache
 cycle;

exit;
