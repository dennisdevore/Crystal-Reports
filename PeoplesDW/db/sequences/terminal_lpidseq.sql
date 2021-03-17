--
-- $Id$
--
-- drop sequence lpidseq;

create sequence lpidseq
 increment by 1
 start with 500000000000000
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

exit;
