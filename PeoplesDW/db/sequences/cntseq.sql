--
-- $Id$
--
-- drop sequence cntseq;

create sequence cntseq
 increment by 1
 start with 1
 maxvalue   9999999999
 minvalue   1
 nocache
 cycle;

exit;
