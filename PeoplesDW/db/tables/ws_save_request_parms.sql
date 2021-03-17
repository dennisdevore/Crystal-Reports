create table save_request_parms
(nameid varchar2(50) not null
,rqst_type varchar2(1) not null      -- type of Request: 'O' (order query) or 'R' (report), etc.
,rpt_or_query_name varchar2(255) not null
,parm_number number(3)               -- used to sequence the parameters
,parm_descr varchar2(255)            -- parameter description or column name
,parm_type varchar2(20)              -- parameter type 'DATE','CHAR','NUMBER', etc.
,parm_required_optional varchar2(12) -- 'required', 'optional'
,parm_opcode varchar2(10)            -- (for queries): 'eq', 'co', 'sw', etc
,parm_value varchar2(4000)
,lastuser varchar2(12)
,lastupdate date
);
create unique index save_request_parms_idx 
	on save_request_parms(nameid,rqst_type,rpt_or_query_name,parm_number);
exit;
