--
-- $Id: workorderinstrseq.sql 1 2005-05-26 12:20:03Z ed $
--

create sequence workorderinstrseq
 increment by 1
 start with 1
 maxvalue   99999999
 minvalue   1
 nocache
 cycle;

exit;