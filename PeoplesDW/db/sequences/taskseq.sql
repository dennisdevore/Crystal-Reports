--
-- $Id$
--
-- drop sequence taskseq;

create sequence taskseq
 increment by 1
 start with 1
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

exit;
