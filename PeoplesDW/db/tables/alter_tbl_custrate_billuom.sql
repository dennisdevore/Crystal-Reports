--
-- $Id: alter_tbl_custrate01.sql 1 2005-05-26 12:20:03Z ed $
--
alter table custrate add(billuom   varchar2(4));

alter table custrate_new add(billuom   varchar2(4));

alter table custrate_old add(billuom   varchar2(4));

exit;
