create or replace package body zcomparedata
as
  -----------------------------------------------------------------------------------
  -- compare_table_across_env
  -----------------------------------------------------------------------------------
  procedure compare_table_across_env(p_table_name in varchar2, p_db_link in varchar2, p_check_non_common_columns in number default 1, p_check_non_common_rows in number default 1)
  as
    primary_keys column_list_type;
    common_columns column_list_type;
    not_in_remote column_list_type;
    not_in_local column_list_type;
  begin
    
    dbms_output.put_line('COMPARING TABLE ' || p_table_name || ' WITH DATABASE ' || p_db_link);
    dbms_output.put_line(' ');
    
    -- validate tables exist, etc..., which also returns primary key columns that are used to compare rows
    primary_keys := validate_tables(p_table_name, p_db_link);

    if (p_check_non_common_columns <> 0) then
      -- list of columns that are in remote table, but not local table, can't compare this data
      not_in_local := remote_cols_not_in_local(p_table_name, p_db_link);
      if (not_in_local.count > 0) then
        dbms_output.put_line(not_in_local.count || ' column(s) in ' || p_db_link || ' not in local table');
        for i in not_in_local.first .. not_in_local.last
        loop
          dbms_output.put_line(' -> ' || not_in_local(i));
        end loop;
        dbms_output.put_line(' ');
      end if;
    
      -- list of columns that are in local table, but not remote table, can't compare this data
      not_in_remote := local_cols_not_in_remote(p_table_name, p_db_link);
      if (not_in_remote.count > 0) then
        dbms_output.put_line(not_in_remote.count || ' column(s) in local table not in ' || p_db_link);
        for i in not_in_remote.first .. not_in_remote.last
        loop
          dbms_output.put_line(' -> ' || not_in_remote(i));
        end loop;
        dbms_output.put_line(' ');
      end if;
    end if;
    
    if (p_check_non_common_rows <> 0) then
      local_rows_not_in_remote(p_table_name, p_db_link, primary_keys);
      remote_rows_not_in_local(p_table_name, p_db_link, primary_keys);
    end if;
    
    common_columns := get_common_non_pk_columns(p_table_name, p_db_link);
    compare_common_rows(p_table_name, p_db_link, primary_keys, common_columns);
    
  end compare_table_across_env;
  
  -----------------------------------------------------------------------------------
  -- validate_tables
  -----------------------------------------------------------------------------------
  function validate_tables(p_table_name in varchar2, p_db_link in varchar2) return column_list_type
  as
    v_count number;
    v_sql varchar2(1000);
    primary_keys column_list_type;
  begin
    select count(1)
    into v_count
    from all_tables
    where lower(table_name) = lower(p_table_name);
    
    if (v_count = 0) then
      raise_application_error(-20001, 'Table ' || p_table_name || ' does not exist in this database');
    end if;
    
    v_sql := 'select count(1) from all_tables@' || p_db_link || ' 
      where lower(table_name) = lower(''' || p_table_name || ''')';
    execute immediate v_sql into v_count;
    
    if (v_count = 0) then
      raise_application_error(-20001, 'Table ' || p_table_name || ' does not exist in database ' || p_db_link);
    end if;
  
    select count(1)
    into v_count
    from all_constraints a, all_cons_columns b
    where lower(b.table_name) = lower(p_table_name)
      and a.constraint_type = 'P'
      and a.constraint_name = b.constraint_name
      and a.owner = b.owner;
      
    if (v_count = 0) then
      raise_application_error(-20001, 'Table does not have primary key, cannot compare data');
    end if;
    
    select b.column_name
    bulk collect into primary_keys
    from all_constraints a, all_cons_columns b
    where lower(b.table_name) = lower(p_table_name)
      and a.constraint_type = 'P'
      and a.constraint_name = b.constraint_name
      and a.owner = b.owner
    order by b.position;
    
    return primary_keys;
    
  end validate_tables;
  
  -----------------------------------------------------------------------------------
  -- local_cols_not_in_remote
  -----------------------------------------------------------------------------------
  function local_cols_not_in_remote(p_table_name in varchar2, p_db_link in varchar2) return column_list_type
  as 
    column_list column_list_type;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select column_name
              from
              (select column_name
               from all_tab_cols
               where lower(table_name) = lower(''' || p_table_name || ''')
               minus
               select column_name
               from all_tab_cols@' || p_db_link || '
               where lower(table_name) = lower(''' || p_table_name || '''))
              order by column_name';
               
    execute immediate v_sql bulk collect into column_list;
    return column_list;
  end local_cols_not_in_remote;
  
  -----------------------------------------------------------------------------------
  -- remote_cols_not_in_local
  -----------------------------------------------------------------------------------
  function remote_cols_not_in_local(p_table_name in varchar2, p_db_link in varchar2) return column_list_type
  as 
    column_list column_list_type;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select column_name
              from
              (select column_name
               from all_tab_cols@' || p_db_link || '
               where lower(table_name) = lower(''' || p_table_name || ''')
               minus
               select column_name
               from all_tab_cols
               where lower(table_name) = lower(''' || p_table_name || '''))
              order by column_name';
               
    execute immediate v_sql bulk collect into column_list;
    return column_list;
  end remote_cols_not_in_local;
  
  -----------------------------------------------------------------------------------
  -- get_common_non_pk_columns
  -----------------------------------------------------------------------------------
  function get_common_non_pk_columns(p_table_name in varchar2, p_db_link in varchar2) return column_list_type
  as
    column_list column_list_type;
    v_sql varchar2(1000);
  begin
  
    v_sql := 'select a.column_name
              from all_tab_cols a, all_tab_cols@' || p_db_link || ' b
              where lower(a.table_name) = lower(''' || p_table_name || ''')
                and a.table_name = b.table_name and a.owner = b.owner and a.column_name = b.column_name
                and a.data_type not like ''%LOB%''
              order by a.column_name';
              
    execute immediate v_sql bulk collect into column_list;
    return column_list;          
  end get_common_non_pk_columns;
  
  -----------------------------------------------------------------------------------
  -- local_rows_not_in_remote
  -----------------------------------------------------------------------------------
  procedure local_rows_not_in_remote(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type)
  as
    v_primary_key_list varchar2(200);
    v_count number := 0;
    v_sql varchar2(1000);
    v_cursor sys_refcursor;
    v_row_data varchar2(200);
  begin
  
    for i in p_primary_keys.first .. p_primary_keys.last
    loop
      v_primary_key_list := case when v_count > 0 then v_primary_key_list || ' / ' else '' end || p_primary_keys(i);
      v_count := v_count + 1;
    end loop;
    
    v_sql := 'select primary_key
              from 
              (select ' || v_primary_key_list || ' as primary_key
               from ' || p_table_name || '
               minus
               select ' || v_primary_key_list || ' as primary_key
               from ' || p_table_name || '@' || p_db_link || ')
              order by primary_key';
     
    v_count := 0;         
    open v_cursor for v_sql;
    loop
      if (v_count = 0) then
        dbms_output.put_line('Rows in local table not in ' || p_db_link);
        dbms_output.put_line(' Primary Key Columns => ' || v_primary_key_list);
      end if;
      v_count := v_count + 1;
      
      fetch v_cursor into v_row_data;
      exit when v_cursor%NOTFOUND;
      dbms_output.put_line('  -> ' || v_row_data);
    end loop;

    close v_cursor;

    dbms_output.put_line(' ');

  end local_rows_not_in_remote;
  
 -----------------------------------------------------------------------------------
  -- remote_rows_not_in_local
  -----------------------------------------------------------------------------------
  procedure remote_rows_not_in_local(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type)
  as
    v_primary_key_list varchar2(200);
    v_count number := 0;
    v_sql varchar2(1000);
    v_cursor sys_refcursor;
    v_row_data varchar2(200);
  begin
  
    for i in p_primary_keys.first .. p_primary_keys.last
    loop
      v_primary_key_list := case when v_count > 0 then v_primary_key_list || ' / ' else '' end || p_primary_keys(i);
      v_count := v_count + 1;
    end loop;
    
    v_sql := 'select primary_key
              from 
              (select ' || v_primary_key_list || ' as primary_key
               from ' || p_table_name || '@' || p_db_link || '
               minus
               select ' || v_primary_key_list || ' as primary_key
               from ' || p_table_name || ')
              order by primary_key';
     
    v_count := 0;         
    open v_cursor for v_sql;
    loop
      if (v_count = 0) then
        dbms_output.put_line('Rows in ' || p_db_link || ' not in local table');
        dbms_output.put_line(' Primary Key Columns => ' || v_primary_key_list);
      end if;
      v_count := v_count + 1;
      
      fetch v_cursor into v_row_data;
      exit when v_cursor%NOTFOUND;
      dbms_output.put_line('  -> ' || v_row_data);
    end loop;

    close v_cursor;
    dbms_output.put_line(' ');
    
  end remote_rows_not_in_local;
  
  -----------------------------------------------------------------------------------
  -- compare_common_rows
  -----------------------------------------------------------------------------------
  procedure compare_common_rows(p_table_name in varchar2, p_db_link in varchar2, p_primary_keys in column_list_type, p_common_columns column_list_type)
  as
    v_sql varchar2(30000);
    v_count number := 0;
    v_row_count number := 0;
    v_cursor sys_refcursor;
    v_where_clause varchar2(30000);
    v_column_data varchar2(30000);
    v_primary_key_sql varchar2(2000);
    v_primary_key_list varchar2(1000);
    
    v_sql_heading varchar2(10000);
    v_heading varchar2(2000);
    v_sql_local_data varchar2(30000);
    v_local_data varchar2(30000);
    v_sql_remote_data varchar2(30000);
    v_remote_data varchar2(30000);
    v_local_column varchar2(1000);
    v_remote_column varchar2(1000);
  begin
    
    v_sql := 'select ';
    for i in p_primary_keys.first .. p_primary_keys.last
    loop
      v_sql := v_sql || case when v_count > 0 then ' || '' and  '' || ' else '' end 
        || '''to_char(' || p_primary_keys(i) || ') = '''''' || ' || 'to_char(a.' || p_primary_keys(i) || ') || ''''''''';
      v_count := v_count + 1;
    end loop;
    v_sql := v_sql || ' from '  || p_table_name || ' a, ' || p_table_name || '@' || p_db_link || ' b';
    v_sql := v_sql || ' where ';
    
    v_count := 0;
    for i in p_primary_keys.first .. p_primary_keys.last
    loop
      v_sql := v_sql || case when v_count > 0 then ' and ' else '' end 
        || ' a.' || p_primary_keys(i) || ' = b.' || p_primary_keys(i);
      v_count := v_count + 1;
    end loop;
    
    --v_sql := v_sql || ' and rownum < 5';
    
    v_count := 0;
    for i in p_primary_keys.first .. p_primary_keys.last
    loop
      v_primary_key_sql := v_primary_key_sql || case when v_count > 0 then ' / ' else '' end || p_primary_keys(i);
      v_primary_key_list := case when v_count > 0 then v_primary_key_list || ' / ' else '' end || p_primary_keys(i);
      v_count := v_count + 1;
    end loop;
    
    v_column_data := get_column_data_sql(p_common_columns);
    
    v_count := 0;         
    open v_cursor for v_sql;
    loop
      fetch v_cursor into v_where_clause;
      exit when v_cursor%NOTFOUND;
      
      if (v_count = 0) then
        dbms_output.put_line('Data Differences (Local - ' || p_db_link || ')');
      end if;
      v_count := v_count + 1;
      
      v_sql_heading := 'select ' || v_primary_key_sql || '
                        from ' || p_table_name || '
                        where ' || v_where_clause;
      execute immediate v_sql_heading into v_heading;
      
      v_sql_local_data := 'select ' || v_column_data || '
                           from ' || p_table_name || ' 
                           where ' || v_where_clause;
          
      --dbms_output.put_line(v_sql_local_data);                
      execute immediate v_sql_local_data into v_local_data;
      
      v_sql_remote_data := 'select ' || v_column_data || '
                            from ' || p_table_name || '@' || p_db_link || '  
                            where ' || v_where_clause;
            
      --dbms_output.put_line(v_sql_remote_data);                
      execute immediate v_sql_remote_data into v_remote_data;
      
      v_row_count := 0;
      dbms_output.put_line(' ' || v_primary_key_list || ' => ' || v_heading);
      for i in p_common_columns.first .. p_common_columns.last
      loop
        v_local_column := get_token(v_local_data, DATA_SEPERATOR, i);
        v_remote_column := get_token(v_remote_data, DATA_SEPERATOR, i);
        if (v_local_column <> v_remote_column) then
          v_row_count := v_row_count + 1;
          dbms_output.put_line('  ' || p_common_columns(i) || ' => ' || v_local_column || ' - ' || v_remote_column);
        end if;
      end loop;
      if (v_row_count = 0) then
        dbms_output.put_line('  ALL DATA IS THE SAME');
      else
        dbms_output.put_line('  ' || v_row_count || ' difference(s)');
      end if;
      dbms_output.put_line(' ');
      
    end loop;

    close v_cursor;
    dbms_output.put_line(' ');
    
  end compare_common_rows;
  
  -----------------------------------------------------------------------------------
  -- get_column_data_sql
  -----------------------------------------------------------------------------------
  function get_column_data_sql(p_common_columns column_list_type) return varchar2
  as
    v_sql varchar2(30000);
    v_count number := 0;
  begin
  
    for i in p_common_columns.first .. p_common_columns.last
    loop
      v_sql := case when v_count > 0 then v_sql || ' || '''  || DATA_SEPERATOR || ''' || ' else '' end 
        || 'nvl(to_char(' || p_common_columns(i) || '),''(null)'')';
      v_count := v_count + 1;
    end loop;
    
    return v_sql;
    
  end get_column_data_sql;
  
  -----------------------------------------------------------------------------------
  -- get_token
  -----------------------------------------------------------------------------------
  function get_token(p_string in varchar2, p_delim in varchar2, p_position in varchar2) return varchar2
  as
  begin
    return REGEXP_SUBSTR(p_string, '[^' || p_delim || ']+', 1, p_position);
  end get_token;
  
end zcomparedata;
/

show error package body zcomparedata;
exit;