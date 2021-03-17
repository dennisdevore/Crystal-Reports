--
-- $Id$
--
-- drop sequence tempinvseq;

create sequence tempinvseq
 increment by 1
 start with 1
 maxvalue   9999
 minvalue   1
 nocache
 cycle;

exit;

