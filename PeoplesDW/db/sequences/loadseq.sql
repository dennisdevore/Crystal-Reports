--
-- $Id$
--
-- drop sequence loadseq;

create sequence loadseq
 increment by 1
 start with 1
 maxvalue   9999999
 minvalue   1
 nocache
 cycle;
 exit;
