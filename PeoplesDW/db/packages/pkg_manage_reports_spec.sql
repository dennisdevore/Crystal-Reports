--
-- $Id: pkg_manage_reports_spec.sql 5114 2010-06-14 15:55:21Z eric $
--
create or replace package pkg_manage_reports is

procedure usp_add_report(
  in_report_filename VARCHAR2,
  in_report_label VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

procedure usp_delete_report(
  in_label_id NUMBER,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

procedure usp_update_report_label(
  in_label_id NUMBER,
  in_report_label VARCHAR2,
  return_status OUT NUMBER,
  return_msg OUT VARCHAR2
);

end pkg_manage_reports;
/
exit;