--
-- $Id$
--
create or replace PACKAGE alps.zempactv
IS

PROCEDURE summarize_time
(in_nameid varchar2
,in_custid varchar2
,in_facility varchar2
,in_event varchar2
,in_begtime date
,in_endtime date
,out_days IN OUT number
,out_hours IN OUT number
,out_minutes IN OUT number
,out_seconds IN OUT number
,out_msg  IN OUT varchar2
);

END zempactv;
/
exit;