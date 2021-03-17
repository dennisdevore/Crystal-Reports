--
-- $Id: lpidseq.sql 1 2005-05-26 12:20:03Z ed $
--
-- drop sequence broyhillsnseq;

create sequence broyhillsnseq
 increment by 1
 start with 1
 maxvalue   999999999999999
 minvalue   1
 nocache
 cycle;

exit;
