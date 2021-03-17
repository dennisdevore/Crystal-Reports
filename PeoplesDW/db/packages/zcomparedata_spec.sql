create or replace package zcomparedata
as

  DATA_SEPERATOR CONSTANT varchar2(3) := '|=|';

  --Types
  type column_list_type is table of varchar2(30);

  --Procedure and Functions
  procedure compare_table_across_env(p_table_name in varchar2, p_db_link in varchar2, p_check_non_common_columns in number default 1, p_check_non_common_rows in number default 1);
  function validate_tables(p_table_name in varchar2, p_db_link in varchar2) return column_list_type;
  
  function get_common_non_pk_columns(p_table_name in varchar2, p_db_link in varchar2) return column_list_type;
  function local_cols_not_in_remote(p_table_name in varchar2, p_db_link in varchar2) return column_list_type;
  function remote_cols_not_in_local(p_table_name in varchar2, p_db_link in varchar2) return column_list_type;
  
  procedure local_rows_not_in_remote(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type);
  procedure remote_rows_not_in_local(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type);
  
  procedure compare_common_rows(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type, p_common_columns column_list_type);
  function get_column_data_sql(p_common_columns column_list_type) return varchar2;
  function get_token(p_string in varchar2, p_delim in varchar2, p_position in varchar2) return varchar2;

end zcomparedata;
/

show error package zcomparedata;
exit;