--
-- $Id$
--
-- drop sequence masterinvseq;

create sequence masterinvseq
 increment by 1
 start with 1000
 maxvalue   99999999
 minvalue   1
 nocache
 cycle;

exit;

