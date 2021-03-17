--
-- $Id$
--
set serveroutput on;
declare
sql_cur integer;
sql_count integer;
checkdate date;
latedate date;

cursor tblcur is
  select distinct table_name
    from user_tab_columns
   where column_name = 'LASTUPDATE'
     and exists (select *
                   from user_tables
                  where user_tables.table_name =
                        user_tab_columns.table_name)
   order by table_name;

begin

checkdate := to_date('199906091200','yyyymmddhh24mi');
latedate := to_date('199906090945','yyyymmddhh24mi');

for tbl in tblcur
loop

  begin
    sql_cur := dbms_sql.open_cursor;
    dbms_sql.parse(sql_cur, 'update ' || tbl.table_name ||
        ' set lastupdate = :x  where lastupdate > :y',
         dbms_sql.native);
    dbms_sql.bind_variable(sql_cur, ':x', checkdate);
    dbms_sql.bind_variable(sql_cur, ':y', latedate);
    sql_count := dbms_sql.execute(sql_cur);
    zut.prt(tbl.table_name || ' ' || to_char(sql_count) || ' rows updated');
    dbms_sql.close_cursor(sql_cur);
  exception when NO_DATA_FOUND then
    dbms_sql.close_cursor(sql_cur);
    zut.prt(tbl.table_name + 'no data found');
    raise;
  end;
  
end loop;

exception when OTHERS then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;

/