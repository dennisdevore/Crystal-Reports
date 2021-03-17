create or replace package ws_reports
as

  -- ERROR MESSAGES --
  REQUIRE_CUSTOMER          CONSTANT varchar2(50) := 'customer required';
  REQUIRE_FACILITY          CONSTANT varchar2(50) := 'facility required';

  -- TYPES --
  type ws_savedata_list is table of varchar2(255) index by binary_integer;
  
  -- FUNCTIONS AND PROCEDURES --
  function get_report_list(p_nameid in varchar2, p_custid in varchar2) return sys_refcursor;
  function get_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, p_rpt in varchar2) return sys_refcursor;
  
  function set_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, p_rpt in varchar2, p_savedata in ws_savedata_list) return number;
  procedure delete_report_parms(p_nameid in varchar2, p_custid in varchar2, p_sess in varchar2, p_rpt in varchar2, p_message out varchar2);
  procedure delete_report(p_nameid in varchar2, p_rpt in varchar2, p_message out varchar2);
  procedure save_report_format(p_nameid in varchar2, p_custid in varchar2, p_rptfmt in varchar2, p_message out varchar2);

end ws_reports;
/

show error package ws_reports;
exit;