--
-- $Id: alter_tbl_userheader_ws_sessionid.sql 1 2005-05-26 12:20:03Z ed $
--
alter table userheader
add
(ws_session_id varchar2(255)
);
exit;
