drop table aud_mod_rpt;

create table aud_mod_rpt
(sessionid            number,
 mod_seq              number(10),
 mod_table_name       varchar2(30),
 mod_type             varchar2(6), -- Insert, Update, Delete
 mod_time             date,
 mod_key1             varchar2(4000),
 mod_key1_column_name varchar2(30),
 mod_key2             varchar2(4000),
 mod_key2_column_name varchar2(30),
 mod_key3             varchar2(4000),
 mod_key3_column_name varchar2(30),
 mod_key4             varchar2(4000),
 mod_key4_column_name varchar2(30),
 mod_key5             varchar2(4000),
 mod_key5_column_name varchar2(30),
 mod_key6             varchar2(4000),
 mod_key6_column_name varchar2(30),
 mod_column           varchar2(30),
 mod_old_col_value    varchar2(4000),
 mod_new_col_value    varchar2(4000),
 lastupdate           date
);

create index aud_mod_rpt_sessionid_idx
 on aud_mod_rpt(sessionid);

create index aud_mod_rpt_lastupdate_idx
 on aud_mod_rpt(lastupdate);

create or replace package aud_mod_rpt_pkg
as type aud_mod_rpt_type is ref cursor return aud_mod_rpt%rowtype;

end aud_mod_rpt_pkg;
/

create or replace procedure aud_mod_rpt_proc
(
aud_mod_rpt_cursor IN OUT aud_mod_rpt_pkg.aud_mod_rpt_type
,in_mod_time_from IN date
,in_mod_time_until IN date
,in_table_name IN varchar2
,in_facility IN varchar2
,in_custid IN varchar2
,in_item IN varchar2
,in_insert_delete_detail_yn IN char
,in_column_name IN varchar2
)

as

l_sessionid number := 0;
l_count pls_integer;
type cur_type is REF CURSOR;
l_obj_cur cur_type;
l_obj_sql varchar2(32767);
l_mod_cur binary_integer;
l_mod_sql varchar2(32767);
l_modold_cur binary_integer;
l_modold_sql varchar2(32767);
l_mod_col_count binary_integer;
l_varchar2 varchar2(4000);

l_new_cur cur_type;
l_old_cur cur_type;
l_sql_cur cur_type;
l_sql varchar2(32767);
l_sql_old varchar2(32767);
l_sql_new varchar2(32767);
l_table_name_new user_tables.table_name%type;
l_table_name_old user_tables.table_name%type;
l_table_name_to_use user_tables.table_name%type;
l_prev_table_name_to_use user_tables.table_name%type := 'x';
l_prev_mod_table_name user_tables.table_name%type := 'x';
l_loop_count pls_integer;
l_colnx pls_integer;
l_custid_col_total pls_integer;
l_where_clause varchar2(4000);
l_aud_mod_rpt_count pls_integer := 0;
AMR aud_mod_rpt%rowtype := null;

type mod_rcd_type is record (
  column_value    varchar2(4000)
);
type mod_tbl_type is table of mod_rcd_type
   index by binary_integer;
mods mod_tbl_type;
modx binary_integer;
modfoundx binary_integer;
modolds mod_tbl_type;
modoldx binary_integer;
modoldfoundx binary_integer;

type col_rcd_type is record (
  column_name     user_tab_columns.column_name%type
);

type col_tbl_type is table of col_rcd_type
     index by binary_integer;

keys col_tbl_type;
keyx pls_integer;

cols col_tbl_type;
colx pls_integer;

function col_select_as_varchar2(in_column_name varchar2, in_data_type varchar2)
return varchar2
is

l_col_sql varchar2(255);

begin

  l_col_sql := null;
  if in_data_type in ('FLOAT','NUMBER') then
    l_col_sql := 'to_char(' || in_column_name || ') as ' || in_column_name;
  elsif in_data_type in ('DATE','TIMESTAMP(6)','TIMESTAMP(9)') then
    l_col_sql := 'to_char(' || in_column_name ||
      ',''mm/dd/yy hh24:mi:ss'') as ' || in_column_name;
  elsif in_data_type in ('CLOB') then
    l_col_sql := 'substr(' ||
      in_column_name || ',1,4000) as ' || in_column_name;
  elsif in_data_type in ('BLOB') then
    l_col_sql := '''Length: '' || ' || 'length(' ||
      in_column_name || ') as ' || in_column_name;
  else
    l_col_sql := in_column_name;
  end if;

  return l_col_sql;
  
end;

begin

select sys_context('USERENV','SESSIONID')
 into l_sessionid
 from dual;

delete from aud_mod_rpt
 where sessionid = l_sessionid;
commit;

delete from aud_mod_rpt
 where lastupdate < trunc(sysdate);

commit;

select count(1)
  into l_count
  from aud_mod_rpt
 where lastupdate < sysdate;

if l_count = 0 then
  EXECUTE IMMEDIATE 'truncate table aud_mod_rpt';
end if;

l_obj_sql := 'select table_name from user_tables ut where table_name like ' ||
  '''%~_NEW'' escape ''~'' and exists (select 1 from user_tab_columns uc where ut.table_name = ' ||
  ' uc.table_name and uc.column_name = ''MOD_SEQ'') order by table_name';

open l_obj_cur for l_obj_sql;
loop

  fetch l_obj_cur into l_table_name_new;
  exit when l_obj_cur%notfound;

  l_table_name_old := replace(l_table_name_new,'_NEW','_OLD');

  for l_loop_count in 1..2
  loop

    if l_loop_count = 1 then
      l_table_name_to_use := l_table_name_new;
    else
      l_table_name_to_use := l_table_name_old;
    end if;
    
    l_mod_sql := 'select ';
    l_count := 1;
    for col in (select column_name,data_type
                  from user_tab_columns
                 where table_name = l_table_name_to_use
                 order by column_id)
    loop
      if l_count > 1 then
        l_mod_sql := l_mod_sql || ',';
      end if;
      l_mod_sql := l_mod_sql || col_select_as_varchar2(col.column_name,col.data_type);
      l_count := l_count + 1;
    end loop;

    l_mod_sql := l_mod_sql ||
      ' from ' || l_table_name_to_use || ' where mod_time >= ''' ||
      in_mod_time_from || ''' and mod_time < ''' ||
      in_mod_time_until || '''';

    if l_loop_count = 2 then
      l_mod_sql := l_mod_sql || ' and mod_type = ''D''';
    end if;
    
    if rtrim(in_table_name) is not null then
      l_mod_sql := l_mod_sql || ' and mod_table_name ' ||
        zcm.in_str_clause('I',upper(rtrim(in_table_name)));
    end if; 

    if rtrim(in_facility) is not null then
      l_sql := 'select count(1) from user_tab_columns where table_name = ''' ||
        upper(rtrim(l_table_name_to_use)) || ''' and column_name = ''FACILITY''';
      execute immediate l_sql into l_custid_col_total;
      if l_custid_col_total = 0 then
        goto continue_obj_loop;
      end if;
      l_mod_sql := l_mod_sql || ' and facility ' ||
        zcm.in_str_clause('I',upper(rtrim(in_facility)));
    end if;
    
    if rtrim(in_custid) is not null then
      l_sql := 'select count(1) from user_tab_columns where table_name = ''' ||
        upper(rtrim(l_table_name_to_use)) ||
        ''' and column_name = ''CUSTID''';
      execute immediate l_sql into l_custid_col_total;
      if l_custid_col_total = 0 then
        goto continue_obj_loop;
      end if;
      l_mod_sql := l_mod_sql || ' and custid ' ||
        zcm.in_str_clause('I',upper(rtrim(in_custid)));
    end if;
    
    if rtrim(in_item) is not null then
      l_sql := 'select count(1) from user_tab_columns where table_name = ''' ||
        l_table_name_to_use || ''' and column_name = ''ITEM''';
      execute immediate l_sql into l_custid_col_total;
      if l_custid_col_total = 0 then
        goto continue_obj_loop;
      end if;
      l_mod_sql := l_mod_sql || ' and item ' ||
        zcm.in_str_clause('I',upper(rtrim(in_item)));
    end if;

    l_mod_cur := dbms_sql.open_cursor;
    dbms_sql.parse(l_mod_cur,l_mod_sql,dbms_sql.native);
    if l_table_name_to_use != l_prev_table_name_to_use then
      cols.delete;
      begin
        select count(1)
          into l_mod_col_count
          from user_tab_columns
         where table_name = l_table_name_to_use;
      exception when others then
        l_mod_col_count := 1;
      end;
      for utc in (select column_name,data_type
                    from user_tab_columns
                   where table_name = l_table_name_to_use
                   order by column_id)
      loop
        colx := cols.count + 1;
        cols(colx).column_name := utc.column_name;
      end loop; 
      l_prev_table_name_to_use := l_table_name_to_use;
    end if;

    for i in 1..l_mod_col_count
    loop
      dbms_sql.define_column(l_mod_cur,i,l_varchar2,4000);
    end loop;
    
    l_count := dbms_sql.execute(l_mod_cur);
    AMR := null;
    
    while dbms_sql.fetch_rows(l_mod_cur) > 0
    loop
      mods.delete;
      for i in 1..l_mod_col_count
      loop
        dbms_sql.column_value(l_mod_cur,i,l_varchar2);
        modx := mods.count + 1;
        mods(modx).column_value := l_varchar2;
        if cols(i).column_name = 'MOD_SEQ' then
          AMR.mod_seq := mods(modx).column_value;
        elsif cols(i).column_name = 'MOD_TABLE_NAME' then
          AMR.mod_table_name := mods(modx).column_value;
        elsif cols(i).column_name = 'MOD_TYPE' then
          AMR.mod_type := mods(modx).column_value;
          if AMR.mod_type = 'I' then
            AMR.mod_type := 'Insert';
          elsif AMR.mod_type = 'U' then
            AMR.mod_type := 'Update';
          else
            AMR.mod_type := 'Delete';
          end if;
        elsif cols(i).column_name = 'MOD_TIME' then
          AMR.mod_time := to_date(mods(modx).column_value,'mm/dd/yy hh24:mi:ss');
        end if;
      end loop;

      if AMR.mod_table_name != l_prev_mod_table_name then
        keys.delete;
        l_colnx := 1;
        for utc in (select uic.column_name
                       from user_tab_columns utc, user_ind_columns uic, user_indexes ui
                      where ui.table_name = AMR.mod_table_name
                        and ui.index_name = zaud.which_unique_index(AMR.mod_table_name)
                        and ui.table_name = uic.table_name
                        and ui.table_name = utc.table_name
                        and uic.column_name = utc.column_name
                        and ui.index_name = uic.index_name
                        and ui.uniqueness = 'UNIQUE'
                      order by uic.column_position)
        loop
          keyx := keys.count + 1;
          keys(keyx).column_name := utc.column_name;
          l_colnx := l_colnx + 1;
          if l_colnx > 6 then
            exit;
          end if;
        end loop; 
        l_prev_mod_table_name := AMR.mod_table_name;
      end if;
      for keyx in 1..keys.count      
      loop
      
        modfoundx := 0;
        for modx in 1..mods.count
        loop
          if cols(modx).column_name = keys(keyx).column_name then
            modfoundx := modx;
            exit;
          end if;
        end loop;
        if modfoundx != 0 then
          case keyx
            when 1 then
              AMR.mod_key1 := mods(modfoundx).column_value;
              AMR.mod_key1_column_name := cols(modfoundx).column_name;
            when 2 then
              AMR.mod_key2 := mods(modfoundx).column_value;
              AMR.mod_key2_column_name := cols(modfoundx).column_name;
            when 3 then
              AMR.mod_key3 := mods(modfoundx).column_value;
              AMR.mod_key3_column_name := cols(modfoundx).column_name;
            when 4 then
              AMR.mod_key4 := mods(modfoundx).column_value;
              AMR.mod_key4_column_name := cols(modfoundx).column_name;
            when 5 then
              AMR.mod_key5 := mods(modfoundx).column_value;
              AMR.mod_key5_column_name := cols(modfoundx).column_name;
            when 6 then
              AMR.mod_key6 := mods(modfoundx).column_value;
              AMR.mod_key6_column_name := cols(modfoundx).column_name;
          end case;        
        end if;
      end loop;
      if AMR.mod_type = 'Update' then
        l_modold_sql := substr(l_mod_sql,1,instr(l_mod_sql,' from ')+5);
        l_modold_sql := l_modold_sql || l_table_name_old || ' where ' ||
                        'mod_seq = ' || AMR.mod_seq;
        l_modold_cur := dbms_sql.open_cursor;
        dbms_sql.parse(l_modold_cur,l_modold_sql,dbms_sql.native);
        for i in 1..l_mod_col_count
        loop
          dbms_sql.define_column(l_modold_cur,i,l_varchar2,4000);
        end loop;
        l_count := dbms_sql.execute(l_modold_cur);
        while dbms_sql.fetch_rows(l_modold_cur) > 0
        loop
          modolds.delete;
          for i in 1..l_mod_col_count
          loop
            dbms_sql.column_value(l_modold_cur,i,l_varchar2);
            modoldx := modolds.count + 1;
            modolds(modoldx).column_value := l_varchar2;
          end loop;
        end loop;
        dbms_sql.close_cursor(l_modold_cur);
      end if;
      
      for modx in 1..mods.count
      loop

        if cols(modx).column_name in 
           ('MOD_SEQ','MOD_TABLE_NAME','MOD_TYPE','MOD_TIME') then
          goto continue_mod_loop;
        end if;
          
        if (nvl(rtrim(upper(in_insert_delete_detail_yn)),'N') != 'Y') and 
           (cols(modx).column_name not in ('LASTUSER','LASTUPDATE')) and
           (AMR.mod_type in ('Insert', 'Delete')) then
          goto continue_mod_loop;
        end if;
        
        AMR.mod_new_col_value := mods(modx).column_value;        
        AMR.mod_old_col_value := null;        
        if AMR.mod_type = 'Update' then
          AMR.mod_old_col_value := modolds(modx).column_value;
          if (nvl(AMR.mod_new_col_value,'?x?') = nvl(AMR.mod_old_col_value,'?x?')) and
             (cols(modx).column_name not in ('LASTUSER','LASTUPDATE')) then
            goto continue_mod_loop;
          end if;
        elsif AMR.mod_type = 'Insert' then
          if AMR.mod_new_col_value is null then
            goto continue_mod_loop;
          end if;
        elsif AMR.mod_type = 'Delete' then
          if AMR.mod_old_col_value is null then
            goto continue_mod_loop;
          end if;
        end if;
        
        if (rtrim(in_column_name) is not null) and
           (instr(',' || upper(rtrim(in_column_name)) || ',',
                  ',' || cols(modx).column_name || ',') = 0) then
          goto continue_mod_loop;
        end if;
        
        insert into aud_mod_rpt values
        (l_sessionid, AMR.mod_seq, AMR.mod_table_name, AMR.mod_type,
         AMR.mod_time,
         AMR.mod_key1, AMR.mod_key1_column_name, 
         AMR.mod_key2, AMR.mod_key2_column_name, 
         AMR.mod_key3, AMR.mod_key3_column_name, 
         AMR.mod_key4, AMR.mod_key4_column_name, 
         AMR.mod_key5, AMR.mod_key5_column_name, 
         AMR.mod_key6, AMR.mod_key6_column_name, 
         cols(modx).column_name,AMR.mod_old_col_value, AMR.mod_new_col_value,
         sysdate);
        l_aud_mod_rpt_count := l_aud_mod_rpt_count + 1;
      << continue_mod_loop >>
        null;
      end loop;
    << continue_col_loop >>
      null;
    end loop;
    dbms_sql.close_cursor(l_mod_cur);
    
  << continue_obj_loop >>  
    null;
  end loop;  

end loop;

open aud_mod_rpt_cursor for
 select *
   from aud_mod_rpt
  where sessionid = l_sessionid
  order by mod_seq desc, mod_column asc;

end aud_mod_rpt_proc;
/
show error procedure aud_mod_rpt_proc;

CREATE OR REPLACE PACKAGE Body aud_mod_rpt_pkg AS

end aud_mod_rpt_pkg;
/
show error package aud_mod_rpt_pkg;
show error package body aud_mod_rpt_pkg;
exit;
