create table ws_rptload_activity
(nameid varchar2(50) not null
,report_name varchar2(255) not null
,activity varchar2(255) not null
,lastuser varchar2(12)
,lastupdate date
);
create unique index ws_rptload_idx 
	on ws_rptload_activity(nameid,report_name);
exit;
