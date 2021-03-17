create or replace package ws_utility
as
  
  function qs(p_string in varchar2) return varchar2;
  
  function get_token(p_string in varchar2, p_delim in varchar2, p_position in varchar2) return varchar2;
  
  function is_order_inbound(p_ordertype in varchar2) return number;
  
  procedure generate_passthru_column_defs(p_message out varchar2);

  function load_a_report( p_file in varchar2 ) return number;
  procedure get_a_report( rpt_key in varchar2, out_blobfile out blob );
  
  function get_custid_max(p_sid in varchar2, p_ip in varchar2, p_key in varchar2) return varchar2;
  function get_custid_cnt return number;

end ws_utility;
/

show error package ws_utility;
exit;