--
-- $Id$
--
-- drop sequence physicalinventoryseq;

create sequence physicalinventoryseq
 increment by 1
 start with 1
 maxvalue   99999999
 minvalue   1
 nocache
 cycle;

exit;
