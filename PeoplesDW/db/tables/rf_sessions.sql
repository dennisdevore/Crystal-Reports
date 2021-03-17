--
-- $Id: rf_sessions.sql 1 2005-05-26 12:20:03Z ed $
--
create table rf_sessions
(sessionid  number
,rf_type    varchar2(12) -- 'rfwhse' or 'WEBRF'
,rf_userid  varchar2(12) not null
,processid  varchar2(255) -- linux pid for rfwhse; null for others
);

create index rf_sessions_idx on rf_sessions(sessionid);
exit;
