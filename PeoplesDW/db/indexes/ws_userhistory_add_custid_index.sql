--
-- $Id: ws_userhistory_add_custid_index.sql 1 2005-05-26 12:20:03Z ed $
--
--drop index ws_userhistory_custid_idx;

create index ws_userhistory_custid_idx on
   ws_user_history(custid);

exit;
