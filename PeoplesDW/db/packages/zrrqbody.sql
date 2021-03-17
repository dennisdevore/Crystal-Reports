create or replace package body alps.report_requestq as

procedure rptparm_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_rpt_format  in varchar2,  -- path to .rpt file
out_msg        in out varchar2
)

is 

l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);
l_trans varchar2(20);
l_response_msg varchar2(255);

begin

out_msg := 'NONE';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_session_id || chr(9) ||
                  in_userid || chr(9) ||
                  in_rpt_format || chr(9);

l_status := zqm.send_commit(RPTPARM_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            null);

if l_status != 1 then
 out_msg := 'rptparm_send_request send error ' || to_char(l_status);
 zms.log_autonomous_msg('RPTPARM', null, null,
                        out_msg,'E', 'RPTPARM', l_msg);
 return;
end if;

l_status := zqm.receive_commit(ztm.USER_DEFAULT_QUEUE,
                               in_session_id,
                               60,
                               zqm.DQ_REMOVE,
                               l_trans,
                               l_response_msg);
if (l_status != 1) then
  out_msg := 'Rptparm receive error ' || l_status;
  return;
end if;

out_msg := zqm.get_field(l_response_msg,1);

exception when others then
  out_msg := substr('zrrreq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('RPTPARM', null, null,
                         out_msg,'e', 'RPTPARM', l_msg);
end rptparm_send_request;

procedure rptparm_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_rpt_format  out varchar2,
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_session_id := '';
out_userid := '';
out_rpt_format := '';
out_msg := 'OKAY';

l_status := zqm.receive_commit(rptparm_DEFAULT_QUEUE,
                               l_qmsg.message,
                               1,
                               zqm.DQ_REMOVE,
                               l_qmsg.trans,
                               l_qmsg.message);

if l_status = -1 then -- timeout
  out_msg := 'OKAY--received timed out';
  return;
end if;

if l_status != 1 then
  out_msg := 'rptparm_get_request bad receive status: ' || to_char(l_status);
  zms.log_autonomous_msg('rptparm', null, null,
                          out_msg, 'E', 'rptparm', l_msg);
  return;
end if;

out_session_id := nvl(zqm.get_field(l_qmsg.message,1),'none');
out_userid := nvl(zqm.get_field(l_qmsg.message,2),'none');
out_rpt_format := nvl(zqm.get_field(l_qmsg.message,3),'none');

exception when others then
  out_msg := substr('zrrrgr: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptparm', null, null,
                         out_msg,'e', 'rptparm', l_msg);
end rptparm_get_request;

procedure rptparm_send_response
(
in_session_id   in varchar2,  -- websynapse user session
in_response_msg in varchar2,  -- 'OKAY' or error message text
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_msg := 'OKAY';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_response_msg || chr(9);

l_status := zqm.send_commit(ztm.USER_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            in_session_id);
if l_status != 1 then
 out_msg := 'rptparm_send_response send error ' || to_char(l_status);
 zms.log_autonomous_msg('rptparm', null, null,
                        out_msg,'E', 'rptparm', l_msg);
 return;
end if;

exception when others then
  out_msg := substr('zrrreq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptparm', null, null,
                         out_msg,'e', 'rptparm', l_msg);
end rptparm_send_response;

procedure rptreq_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_rpt_format  in varchar2,  -- path to .rpt file
in_rpt_type    in varchar2,  -- pdf, xls, csv, html, etc.
out_msg        in out varchar2
)

is 

l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);
l_trans varchar2(20);
l_response_msg varchar2(255);

begin

out_msg := 'NONE';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_session_id || chr(9) ||
                  in_userid || chr(9) ||
                  in_rpt_format || chr(9) ||
                  in_rpt_type || chr(9);

l_status := zqm.send_commit(RPTREQ_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            null);

if l_status != 1 then
 out_msg := 'rptreq_send_request send error ' || to_char(l_status);
 zms.log_autonomous_msg('rptreq', null, null,
                        out_msg,'E', 'rptreq', l_msg);
 return;
end if;

l_status := zqm.receive_commit(ztm.USER_DEFAULT_QUEUE,
                               in_session_id,
                               60,
                               zqm.DQ_REMOVE,
                               l_trans,
                               l_response_msg);
if (l_status != 1) then
  out_msg := 'rptreq receive error ' || l_status;
  return;
end if;

out_msg := zqm.get_field(l_response_msg,1);

exception when others then
  out_msg := substr('zrrreq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptreq', null, null,
                         out_msg,'e', 'rptreq', l_msg);
end rptreq_send_request;

procedure rptreq_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_rpt_format  out varchar2,
out_rpt_type    out varchar2,
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_session_id := '';
out_userid := '';
out_rpt_format := '';
out_rpt_type := '';
out_msg := 'OKAY';

l_status := zqm.receive_commit(RPTREQ_DEFAULT_QUEUE,
                               l_qmsg.message,
                               1,
                               zqm.DQ_REMOVE,
                               l_qmsg.trans,
                               l_qmsg.message);

if l_status = -1 then -- timeout
  out_msg := 'OKAY--received timed out';
  return;
end if;

if l_status != 1 then
  out_msg := 'rptreq_get_request bad receive status: ' || to_char(l_status);
  zms.log_autonomous_msg('rptreq', null, null,
                          out_msg, 'E', 'rptreq', l_msg);
  return;
end if;

out_session_id := nvl(zqm.get_field(l_qmsg.message,1),'none');
out_userid := nvl(zqm.get_field(l_qmsg.message,2),'none');
out_rpt_format := nvl(zqm.get_field(l_qmsg.message,3),'none');
out_rpt_type := nvl(zqm.get_field(l_qmsg.message,4),'none');

exception when others then
  out_msg := substr('zrrrgr: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptreq', null, null,
                         out_msg,'e', 'rptreq', l_msg);
end rptreq_get_request;

procedure rptreq_send_response
(
in_session_id    in varchar2,  -- websynapse user session
in_response_path in varchar2,  -- path to the crystal-created file
out_msg          out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_msg := 'OKAY';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_response_path || chr(9);

l_status := zqm.send_commit(ztm.USER_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            in_session_id);
if l_status != 1 then
 out_msg := 'rptreq_send_response send error ' || to_char(l_status);
 zms.log_autonomous_msg('rptreq', null, null,
                        out_msg,'E', 'rptreq', l_msg);
 return;
end if;

exception when others then
  out_msg := substr('zrrreq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptreq', null, null,
                         out_msg,'e', 'rptreq', l_msg);
end rptreq_send_response;

procedure rptparm_save_parm_data
(
in_session_id    in varchar2,  -- websynapse user session
in_rpt_format    in varchar2,  -- path to crystal .rpt file
in_parm_number   in varchar2,  -- parm number
in_parm_descr    in varchar2,  -- parm description
in_parm_type     in varchar2,  -- string or date, etc
in_parm_ro       in varchar2,  -- required or optional
out_msg          out varchar2
)
is
l_msg varchar2(255);
v_type report_request_parms.parm_type%type;
v_num number;

begin

out_msg := 'OKAY';

v_num := to_number(in_parm_number);
v_type := 'varchar';

--zms.log_autonomous_msg('rptsavparm', 'fac', 'cust',
--					'rptprm savparm, parm no = ' || in_parm_number,
--                  'e', 'rptsavparm', l_msg);

if v_num = 1 then
	delete from report_request_parms
	 where session_id = in_session_id
	   and rpt_name = in_rpt_format;
end if;

if substr(in_parm_type, 1, 6) = 'String' then
	v_type := 'varchar';
elsif substr(in_parm_type, 1, 8) = 'DateTime' then
	v_type := 'range';
elsif substr(in_parm_type, 1, 4) = 'Date' then
	v_type := 'date';
elsif substr(in_parm_type, 1, 6) = 'Number' then
	v_type := 'number';
elsif substr(in_parm_type, 1, 7) = 'Boolean' then
	v_type := 'boolean';
end if;

insert into report_request_parms
	(session_id, rpt_name, parm_number, parm_descr, parm_type, parm_required_optional, lastuser, lastupdate)
	values (in_session_id, in_rpt_format, v_num, in_parm_descr, v_type, in_parm_ro, 'SYNAPSE', sysdate);
commit;

exception when others then
  out_msg := substr('zrrreq save parm: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptreq save parm', null, null,
                         out_msg,'e', 'rptparm', l_msg);
end rptparm_save_parm_data;

procedure rptparm_get_parm_data
(
in_session_id    in varchar2,  -- websynapse user session
in_rpt_format    in varchar2,  -- path to crystal .rpt file
in_parm_number   in varchar2,  -- parm number
out_parm_value   out varchar2, -- parm value entered by websynapse user
out_msg          out varchar2
)
is
l_msg varchar2(255);
v_num number;

begin

out_msg := 'OKAY';
out_parm_value := '';

v_num := to_number(in_parm_number);

--zms.log_autonomous_msg('rptgetparm', 'fac', 'cust',
--					'rptreq getparm, parm no = ' || in_parm_number,
--                  'e', 'rptgetparm', l_msg);

BEGIN
  select nvl(parm_value,'') into out_parm_value
    from report_request_parms
   where session_id = in_session_id
	 and rpt_name = in_rpt_format
	 and parm_number = v_num;
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_parm_value := '';
  when others then
	out_msg := substr('zrrreq get parm: '|| sqlerrm,1,255);
	zms.log_autonomous_msg('rptreq get parm', null, null,
                         out_msg,'e', 'rptparm', l_msg);
END;	
end rptparm_get_parm_data;

procedure rptload_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
out_msg        in out varchar2
)

is 

l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);
l_trans varchar2(20);
l_response_msg varchar2(255);

begin

out_msg := 'NONE';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_session_id || chr(9) ||
                  in_userid || chr(9);

l_status := zqm.send_commit(RPTLOAD_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            null);

if l_status != 1 then
 out_msg := 'rptload_send_request send error ' || to_char(l_status);
 zms.log_autonomous_msg('RPTLOAD', null, null,
                        out_msg,'E', 'RPTLOAD', l_msg);
 return;
end if;

l_status := zqm.receive_commit(ztm.USER_DEFAULT_QUEUE,
                               in_session_id,
                               60,
                               zqm.DQ_REMOVE,
                               l_trans,
                               l_response_msg);
if (l_status != 1) then
  out_msg := 'Rptload receive error ' || l_status;
  return;
end if;

out_msg := zqm.get_field(l_response_msg,1);

exception when others then
  out_msg := substr('zrrlsr: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('RPTLOAD', null, null,
                         out_msg,'e', 'RPTLOAD', l_msg);
end rptload_send_request;

procedure rptload_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_session_id := '';
out_userid := '';
out_msg := 'OKAY';

l_status := zqm.receive_commit(RPTLOAD_DEFAULT_QUEUE,
                               l_qmsg.message,
                               1,
                               zqm.DQ_REMOVE,
                               l_qmsg.trans,
                               l_qmsg.message);

if l_status = -1 then -- timeout
  out_msg := 'OKAY--received timed out';
  return;
end if;

if l_status != 1 then
  out_msg := 'rptload_get_request bad receive status: ' || to_char(l_status);
  zms.log_autonomous_msg('rptload', null, null,
                          out_msg, 'E', 'rptload', l_msg);
  return;
end if;

out_session_id := nvl(zqm.get_field(l_qmsg.message,1),'none');
out_userid := nvl(zqm.get_field(l_qmsg.message,2),'none');

exception when others then
  out_msg := substr('zrrlgr: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptload', null, null,
                         out_msg,'e', 'rptload', l_msg);
end rptload_get_request;

procedure rptload_send_response
(
in_session_id   in varchar2,  -- websynapse user session
in_response_msg in varchar2,  -- 'OKAY' or error message text
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_msg := 'OKAY';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_response_msg || chr(9);

l_status := zqm.send_commit(ztm.USER_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            in_session_id);
if l_status != 1 then
 out_msg := 'rptload_send_response send error ' || to_char(l_status);
 zms.log_autonomous_msg('rptload', null, null,
                        out_msg,'E', 'rptload', l_msg);
 return;
end if;

exception when others then
  out_msg := substr('zrrlsr: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptload', null, null,
                         out_msg,'e', 'rptload', l_msg);
end rptload_send_response;

procedure rptload_load_report
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
in_rpt_name      in varchar2,  -- descriptive name of the report
in_rpt_path      in varchar2,  -- path to the .rpt file
out_msg          out varchar2
)
is
v_rptname applicationobjects.objectname%type;
v_len number;
l_msg varchar2(255);

begin

out_msg := 'OKAY-EXISTS';
v_len := 180;

BEGIN
  select objectname into v_rptname
	 from applicationobjects
	where objectdescr = in_rpt_path 
	  and objecttype = 'R';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_rptname := '';
END;

if length(v_rptname) > 0 then
	-- Report is already in the report list, skip it.
	-- But add its activity into ws_rptload_activity for this update session
	insert into ws_rptload_activity (nameid, report_name, activity, lastuser, lastupdate)
	values (in_userid, in_rpt_path, out_msg, in_userid, sysdate);
	commit;
	return; 
end if;	

BEGIN
SELECT DATA_LENGTH into v_len FROM USER_TAB_COLS WHERE TABLE_NAME = 'APPLICATIONOBJECTS' AND COLUMN_NAME = 'OBJECTNAME';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    v_len := 180;
END;

if length(in_rpt_name) > v_len then
	v_rptname := substr(in_rpt_name,1,v_len);
else
	v_rptname := in_rpt_name;
end if;

out_msg := 'OKAY-ADDED';

insert into applicationobjects
	(objectname, objecttype, objectdescr, lastuser, lastupdate)
	values (v_rptname, 'R', in_rpt_path, in_userid, sysdate);
insert into ws_rptload_activity (nameid, report_name, activity, lastuser, lastupdate)
	values (in_userid, in_rpt_path, out_msg, in_userid, sysdate);
commit;

exception when others then
  out_msg := substr('zrrlrpt load rpt: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptload load report', null, null,
                         out_msg,'e', 'rptload', l_msg);
end rptload_load_report;

procedure rptload_begin
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
out_msg          out varchar2
)
is
l_msg varchar2(255);

begin

delete from ws_rptload_activity
where nameid = in_userid;

commit;

out_msg := 'OKAY';

exception when others then
  out_msg := substr('zrrq begin rptld: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptload begin process', null, null,
                         out_msg,'e', 'rptload', l_msg);
end rptload_begin;

procedure rptload_end
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
out_msg          out varchar2
)
is
l_msg varchar2(255);

begin

out_msg := 'OKAY';

for rpt in (select objectdescr from applicationobjects
			where objecttype = 'R'
			and objectdescr not in 
			(select report_name from ws_rptload_activity where nameid = in_userid))
	loop
		delete from applicationobjects
		where objectdescr = rpt.objectdescr
		and objecttype = 'R';

		delete from ws_user_reports
		where report_name = rpt.objectdescr;
	end loop;

commit;

out_msg := 'OKAY';

exception when others then
  out_msg := substr('zrrq end rptld: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptload end process', null, null,
                         out_msg,'e', 'rptload', l_msg);
end rptload_end;

procedure rptsrvr_get_parms
(
out_rpt_path    out varchar2,
out_log_path    out varchar2,
out_rpt_dest    out varchar2,
out_rpt_web     out varchar2,
out_msg         out varchar2
)
is
l_msg varchar2(255);

begin

out_rpt_path := '';
out_log_path := '';
out_rpt_dest := '';
out_rpt_web := '';
out_msg := 'OKAY';

BEGIN
SELECT defaultvalue into out_rpt_path 
FROM systemdefaults 
WHERE defaultid = 'WEBSYNAPSERPTPATH';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_rpt_path := '';
END;

BEGIN
SELECT defaultvalue into out_log_path 
FROM systemdefaults 
WHERE defaultid = 'WEBSYNAPSELOGPATH';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_log_path := '';
END;

BEGIN
SELECT defaultvalue into out_rpt_dest 
FROM systemdefaults 
WHERE defaultid = 'WEBSYNAPSERPTDEST';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_rpt_dest := '';
END;

BEGIN
SELECT defaultvalue into out_rpt_web 
FROM systemdefaults 
WHERE defaultid = 'WEBSYNAPSERPTDESTWEB';
EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_rpt_web := '';
END;

exception when others then
  out_msg := substr('zrrsgp: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('rptsrvr', null, null,
                         out_msg,'e', 'rptsrvr', l_msg);
end rptsrvr_get_parms;

function load_a_report_get_blob( p_file in varchar2 )  return blob
as
  l_blob  blob;
begin
  insert into ws_generated_reports (rptkey, rptfl, created) values (p_file, empty_blob(), sysdate) 
	returning rptfl into l_blob;
  return l_blob;
end load_a_report_get_blob;

procedure ordatt_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_att_fpath   in varchar2,  -- path to order attachment file
out_msg        in out varchar2
)

is 

l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);
l_trans varchar2(20);
l_response_msg varchar2(255);

begin

out_msg := 'NONE';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_session_id || chr(9) ||
                  in_userid || chr(9) ||
                  in_att_fpath || chr(9);

l_status := zqm.send_commit(ORDATT_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            null);

if l_status != 1 then
 out_msg := 'ordatt_send_request send error ' || to_char(l_status);
 zms.log_autonomous_msg('attsrq', null, null,
                        out_msg,'E', 'attsrq', l_msg);
 return;
end if;

l_status := zqm.receive_commit(ztm.USER_DEFAULT_QUEUE,
                               in_session_id,
                               60,
                               zqm.DQ_REMOVE,
                               l_trans,
                               l_response_msg);
if (l_status != 1) then
  out_msg := 'attsrq receive error ' || l_status;
  return;
end if;

out_msg := zqm.get_field(l_response_msg,1);

exception when others then
  out_msg := substr('attsrq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('attsrq', null, null,
                         out_msg,'e', 'attsrq', l_msg);
end ordatt_send_request;

procedure ordatt_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_att_fpath   out varchar2,
out_msg         out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_session_id := '';
out_userid := '';
out_att_fpath := '';
out_msg := 'OKAY';

l_status := zqm.receive_commit(ORDATT_DEFAULT_QUEUE,
                               l_qmsg.message,
                               1,
                               zqm.DQ_REMOVE,
                               l_qmsg.trans,
                               l_qmsg.message);

if l_status = -1 then -- timeout
  out_msg := 'OKAY--received timed out';
  return;
end if;

if l_status != 1 then
  out_msg := 'ordatt_get_request bad receive status: ' || to_char(l_status);
  zms.log_autonomous_msg('attgrq', null, null,
                          out_msg, 'E', 'attgrq', l_msg);
  return;
end if;

out_session_id := nvl(zqm.get_field(l_qmsg.message,1),'none');
out_userid := nvl(zqm.get_field(l_qmsg.message,2),'none');
out_att_fpath := nvl(zqm.get_field(l_qmsg.message,3),'none');

exception when others then
  out_msg := substr('attgrq: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('attgrq', null, null,
                         out_msg,'e', 'attgrq', l_msg);
end ordatt_get_request;

procedure ordatt_send_response
(
in_session_id     in varchar2,  -- websynapse user session
in_response_fpath in varchar2,  -- path to the attachment file
out_msg           out varchar2
)
is
l_status integer;
l_qmsg qmsg := qmsg(null, null);
l_msg varchar2(255);

begin

out_msg := 'OKAY';

l_qmsg.trans := 'MSG';
l_qmsg.message := in_response_fpath || chr(9);

l_status := zqm.send_commit(ztm.USER_DEFAULT_QUEUE,
                            l_qmsg.trans,
                            l_qmsg.message,
                            1,
                            in_session_id);
if l_status != 1 then
 out_msg := 'ordatt_send_response send error ' || to_char(l_status);
 zms.log_autonomous_msg('attsrp', null, null,
                        out_msg,'E', 'attsrp', l_msg);
 return;
end if;

exception when others then
  out_msg := substr('attsrp: '|| sqlerrm,1,255);
  zms.log_autonomous_msg('attsrp', null, null,
                         out_msg,'e', 'attsrp', l_msg);
end ordatt_send_response;

end report_requestq;
/
show error package body report_requestq;
exit;
