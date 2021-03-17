--
-- $Id$
--
-- drop sequence cancelledid;
 
create sequence cancelledid
 increment by 1
 start with 1
 maxvalue   9999999
 minvalue   1
 nocache
 cycle;
exit;
