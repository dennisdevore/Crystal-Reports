--
-- $Id$
--
-- drop sequence rmaseq;

create sequence rmaseq
 increment by 1
 start with 10000
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

exit;
