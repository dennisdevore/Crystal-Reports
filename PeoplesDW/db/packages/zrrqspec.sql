create or replace package alps.report_requestq as

RPTPARM_DEFAULT_QUEUE      constant       varchar2(7) := 'rptparm';
RPTREQ_DEFAULT_QUEUE       constant       varchar2(6) := 'rptreq';
RPTLOAD_DEFAULT_QUEUE      constant       varchar2(7) := 'rptload';
ORDATT_DEFAULT_QUEUE       constant       varchar2(9) := 'ordattach';

-- Used by WebSynapse to request that the parameters for a report
-- be populated into the report_request_parms table
procedure rptparm_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_rpt_format  in varchar2,  -- path to crystal .rpt file
out_msg        in out varchar2
);

-- Used by the report parm processor to get a request
-- from a WebSynapse User
procedure rptparm_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_rpt_format  out varchar2,
out_msg         out varchar2
);

-- Used by the report parm processor to send a message back
-- to the WebSynapse process to indicate that the
-- report_request_parms table has been populated
procedure rptparm_send_response
(
in_session_id   in varchar2,  -- websynapse user session
in_response_msg in varchar2,  -- 'OKAY' or error message text
out_msg         out varchar2
);


-- Used by WebSynapse to request a report whose parameters have
-- been set in the report_request_parms table
procedure rptreq_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_rpt_format  in varchar2,  -- path to crystal .rpt file
in_rpt_type    in varchar2,  -- pdf, xls, csv, html, etc.
out_msg        in out varchar2
);

-- Used by the report request processor to get a request
-- from a WebSynapse User
procedure rptreq_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_rpt_format  out varchar2,
out_rpt_type    out varchar2,
out_msg         out varchar2
);

-- Used by the report request processor to send a message back
-- to the WebSynapse process to indicate that the
-- report has been created.
procedure rptreq_send_response
(
in_session_id    in varchar2,  -- websynapse user session
in_response_path in varchar2,  -- path to the crystal-created file
out_msg          out varchar2
);

-- Used by the report request processor to populate
-- the report_request_parms table. Each call adds a parm row.
procedure rptparm_save_parm_data
(
in_session_id    in varchar2,  -- websynapse user session
in_rpt_format    in varchar2,  -- path to crystal .rpt file
in_parm_number   in varchar2,  -- parm number
in_parm_descr    in varchar2,  -- parm description
in_parm_type     in varchar2,  -- string or date, etc
in_parm_ro       in varchar2,  -- required or optional
out_msg          out varchar2
);

-- Used by the report request processor to retrieve
-- the user entered parms from the report_request_parms table. 
-- Each call gets a parm row.
procedure rptparm_get_parm_data
(
in_session_id    in varchar2,  -- websynapse user session
in_rpt_format    in varchar2,  -- path to crystal .rpt file
in_parm_number   in varchar2,  -- parm number
out_parm_value   out varchar2, -- parm value entered by websynapse user
out_msg          out varchar2
);

-- Used by WebSynapse to request that the report folders be scanned,
-- so that new reports can be loaded into the application_objects table.
procedure rptload_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
out_msg        in out varchar2
);

-- Used by the report request processor to get a report load request
-- from a WebSynapse User
procedure rptload_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_msg         out varchar2
);

-- Used by the report request processor to send a message back
-- to the WebSynapse process to indicate that the
-- report load process has been completed.
procedure rptload_send_response
(
in_session_id    in varchar2,  -- websynapse user session
in_response_msg  in varchar2,  -- 'OKAY' or error message text
out_msg          out varchar2
);

-- Used by the report request processor to load a report
-- to the applicationobjects table. This makes the report 
-- visible to WebSynapse users on the ReportList screen.
procedure rptload_load_report
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
in_rpt_name      in varchar2,  -- descriptive name of the report
in_rpt_path      in varchar2,  -- path to the .rpt file
out_msg          out varchar2
);

-- Used by the report request processor to start a report list update session.
procedure rptload_begin
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
out_msg          out varchar2
);

-- Used by the report request processor to complete a report list update session.
-- This will allow the server to delete untouched (removed) reports.
procedure rptload_end
(
in_session_id    in varchar2,  -- websynapse user session
in_userid        in varchar2,  -- websynapse user
out_msg          out varchar2
);

-- Used by the report request processor to get the 
-- SYSTEMDEFAULTS parameters it needs.
procedure rptsrvr_get_parms
(
out_rpt_path    out varchar2,
out_log_path    out varchar2,
out_rpt_dest    out varchar2,
out_rpt_web     out varchar2,
out_msg         out varchar2
);

-- Used by the report request processor to insert a report row and get an 
-- empty BLOB object for that row. The p_file is the generated CR Report filename. 
-- It will then update the BLOB with the generated Crystal Report file contents
-- using BlobStream.CopyFrom(FileStream,FileStream.Size), followed by a commit.
--
-- Also used by the Order Attachment processor to deliver the attachments.
function load_a_report_get_blob( p_file in varchar2 ) return blob;

-- Used by WebSynapse to request an order attachment
procedure ordatt_send_request
(
in_session_id  in varchar2,  -- websynapse user session
in_userid      in varchar2,  -- websynapse user
in_att_fpath   in varchar2,  -- path to order attachment file
out_msg        in out varchar2
);

-- Used by the order attachment request processor to get an attachment request
-- from a WebSynapse User
procedure ordatt_get_request
(
out_session_id  out varchar2,
out_userid      out varchar2,
out_att_fpath   out varchar2,
out_msg         out varchar2
);

-- Used by the order attachment request processor to send a message back
-- to the WebSynapse process to indicate that the
-- order attachment has been delivered.
procedure ordatt_send_response
(
in_session_id     in varchar2,  -- websynapse user session
in_response_fpath in varchar2,  -- path to the order attachment
out_msg           out varchar2
);

end report_requestq;
/
show errors package report_requestq;

exit;
