--
-- WS_USER_HISTORY 
--
create table ws_user_history
(nameid varchar2(12) not null        -- WebSynapse Userid 
,event_time date not null            -- activity start time
,facility varchar2(3)                        
,custid varchar2(10)                 
,pgm varchar2(100)                   -- The PHP module that handled the request
,opcode varchar2(255)                -- The opcode of the action
,parms varchar2(2000)                -- parameters sent by the qooxdoo client
,ipaddr varchar2(100)                -- Client IP Address
,sessionid varchar2(200)             -- PHP Session ID
);
create index ws_user_history_nametm_idx 
	on ws_user_history(nameid,event_time);
	
exit;
