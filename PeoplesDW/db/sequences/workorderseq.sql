--
-- $Id$
--
-- drop sequence workorderseq;

create sequence workorderseq
 increment by 1
 start with 1
 maxvalue   99999999
 minvalue   1
 nocache
 cycle;

exit;