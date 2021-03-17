Set heading off
Set trimout on
Set trimspool on
Set linesize 100
set timing on
set tab off
spool lastupdates.out

create global temporary table tmp_lastupdate
(table_name varchar2(30)
,lastupdate date
)
on commit delete rows;

declare
l_cmd varchar2(255);
l_lastupdate date;
begin

  for obj in (select table_name from user_tables
               where exists (select 1 from user_tab_columns
                                where user_tables.table_name = user_tab_columns.table_name
                                  and column_name = 'LASTUPDATE'))
  loop
    l_cmd := 'select max(lastupdate) from ' || obj.table_name;
    execute immediate l_cmd
      into l_lastupdate;
    if l_lastupdate is not null then
      l_cmd := 'insert into tmp_lastupdate values(' ||
        ':p_table_name, :p_lastupdate)';
      execute immediate l_cmd
        using obj.table_name, l_lastupdate;
    end if;
  end loop;

end;
/
select table_name,to_char(lastupdate, 'yyyy/mm/dd hh24:mi:ss') lastupdate
  from tmp_lastupdate
 order by lastupdate desc, table_name;
commit;
drop table tmp_lastupdate;
exit;


