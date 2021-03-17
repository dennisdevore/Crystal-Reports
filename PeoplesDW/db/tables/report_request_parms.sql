create table report_request_parms
(session_id varchar2(255) not null
,rpt_name varchar2(255) not null
,parm_number number(3)               -- used to sequence the parameters
,parm_descr varchar2(255)            -- parameter description
,parm_type varchar2(12)              -- parameter type 'DATE','CHAR','NUMBER', etc.
,parm_required_optional varchar2(12) -- 'required', 'optional'
,parm_value varchar2(4000)
,lastuser varchar2(12)
,lastupdate date
);
create unique index report_request_parms_idx on report_request_parms(session_id,rpt_name,parm_number);
exit;
