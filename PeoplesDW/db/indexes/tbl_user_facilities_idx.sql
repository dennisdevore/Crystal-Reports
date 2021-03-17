--
-- $Id: tbl_user_facilities_idx.sql 1 2005-05-26 12:20:03Z ed $
--

create unique index tbl_user_facilities_idx
on tbl_user_facilities(nameid,facility_id);
exit;
