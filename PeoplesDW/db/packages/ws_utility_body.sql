create or replace package body ws_utility
as

  /* -----------------------------------------------------------------------------------------------
  QS
  -------------------------------------------------------------------------------------------------*/
  function qs(p_string in varchar2) return varchar2
  as
  begin
    return '''' || p_string || '''';
  end qs;
  
  /* -----------------------------------------------------------------------------------------------
  GET_TOKEN
  -------------------------------------------------------------------------------------------------*/
  function get_token(p_string in varchar2, p_delim in varchar2, p_position in varchar2) return varchar2
  as
  begin
    return REGEXP_SUBSTR(p_string, '[^' || p_delim || ']+', 1, p_position);
  end get_token;
  
  /* -----------------------------------------------------------------------------------------------
  IS_ORDER_INBOUND
  -------------------------------------------------------------------------------------------------*/
  function is_order_inbound(p_ordertype in varchar2) return number
  as
  begin
    if (p_ordertype in ('R','Q','P','A','C','I')) then
      return 1;
    end if;
    
    return 0;
  end is_order_inbound;

  /* -----------------------------------------------------------------------------------------------
  GENERATE_PASSTHRU_COLUMN_DEFS
  -------------------------------------------------------------------------------------------------*/
  procedure generate_passthru_column_defs(p_message out varchar2)
  as 
    v_message varchar2(255);
	v_seq number;
	v_width number;
	v_type varchar2(255);
	v_ud varchar2(255);
  begin
	v_message := 'OKAY';
	select max(col_order_num) into v_seq from ws_columns where query_type = 'ORDERS' and target_width > 0;
	for cc in (select column_name, lower(data_type) as data_type from user_tab_columns
					where table_name = 'ORDERHDR'
					  and column_name like '%PASSTHRU%'
					order by column_name)
		loop
			v_width := 60;
			v_type := cc.data_type;
			if v_type = 'varchar2' then
				v_type := 'string';
			end if;
			if v_type = 'date' then
				v_width := 75;
			end if;
			v_seq := v_seq + 1;

			v_ud := substr(cc.column_name, 1, 11);
			v_ud := v_ud || ' ' || substr(cc.column_name, 12);

			insert into ws_columns (query_type, col_db_name, col_user_descr, col_order_num, col_type,
				hide_types, target_width, disappear_order, visible_by_default, lastuser, lastupdate)
				values ('ORDERS', cc.column_name, v_ud, v_seq, v_type, null, v_width, 
						-1, 'N', 'SYNAPSE', sysdate);
		end loop;
	commit;
	p_message := v_message;
  end generate_passthru_column_defs;

  function load_a_report( p_file in varchar2 )  return number
  as
    l_blob  blob;
    l_bfile bfile;
  begin
    insert into ws_generated_reports (rptkey, rptfl, created) values (p_file, empty_blob(), sysdate) 
		returning rptfl into l_blob;
    l_bfile := bfilename( 'DP_TMP', p_file );
    dbms_lob.fileopen( l_bfile );
    dbms_lob.loadfromfile( l_blob, l_bfile,
                           dbms_lob.getlength( l_bfile ) );
    dbms_lob.fileclose( l_bfile );
	return dbms_lob.getlength( l_bfile );
  end load_a_report;

  procedure get_a_report( rpt_key in varchar2, out_blobfile out blob )
  as 
  begin
  BEGIN	
    out_blobfile := empty_blob();
	select rptfl into out_blobfile
	  from ws_generated_reports
	 where rptkey = rpt_key;
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    out_blobfile := empty_blob();
  END;
    
  end get_a_report;

  /* -----------------------------------------------------------------------------------------------
  get_custid_max
  -------------------------------------------------------------------------------------------------*/
  function get_custid_max(p_sid in varchar2, p_ip in varchar2, p_key in varchar2) return varchar2
  as
	outkey varchar2(2048);
	keystr varchar2(1000);
	inpstr varchar2(1000);
	numlic number;
  begin
  BEGIN	
  select maxcusts into inpstr from WS_MAX where rownum = 1;
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    numlic := 5;
	return to_char(numlic);
  END;
  keystr := p_sid || p_ip || p_key;
  keystr := rpad(keystr, (trunc(length(keystr)/24)+1)*24, chr(0));
  inpstr := utl_raw.cast_to_varchar2(hextoraw(inpstr));
  dbms_obfuscation_toolkit.DES3Decrypt(
               input_string => inpstr,
               key_string => keystr,
               decrypted_string => outkey,
               which => dbms_obfuscation_toolkit.ThreeKeyMode);
  --numlic := to_number(outkey);
  --return numlic;
  return outkey;
  end get_custid_max;

  /* -----------------------------------------------------------------------------------------------
  get_custid_cnt
  -------------------------------------------------------------------------------------------------*/
  function get_custid_cnt return number
  as
	numcusts number;
  begin
  BEGIN	
	select count(distinct uh.custid) into numcusts 
		from ws_user_history uh, customer c
		where c.custid = uh.custid and c.status = 'ACTV';
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    numcusts := 0;
	return numcusts;
  END;

  return numcusts;
  end get_custid_cnt;
    
end ws_utility;
/

show error package body ws_utility;
exit;