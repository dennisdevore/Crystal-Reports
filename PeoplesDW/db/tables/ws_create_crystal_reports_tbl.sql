--DROP TABLE ws_generated_reports;
CREATE TABLE ws_generated_reports 
(rptkey varchar2(255) primary key 
,rptfl BLOB
,created date); 
exit;
