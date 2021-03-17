--
-- $Id$
--
-- drop sequence vlpidseq;

create sequence vlpidseq
 increment by 1
 start with 999000000000000
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

exit;
