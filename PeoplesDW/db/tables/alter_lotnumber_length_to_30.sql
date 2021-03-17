set serveroutput on
set heading off
set pagesize 0
set linesize 32000
set trimspool on
spool upd_item_sizes.out
declare
l_tot pls_integer := 0;
l_oky pls_integer := 0;
l_err pls_integer := 0;
out_errorno pls_integer;
out_msg varchar2(255);
l_cmd varchar2(4000);
l_update char(1) := 'N';

begin

for obj in (select table_name, column_name
              from user_tab_columns
             where data_type in ('CHAR','VARCHAR2')
               and data_length = 20
               and column_name like '%LOT%'
               and exists (select 1
                             from user_objects
                            where object_name = table_name
                              and object_type = 'TABLE')
            order by table_name, column_name)
loop

  l_tot := l_tot + 1;

  l_cmd := 'alter table ' || obj.table_name || ' modify ' ||
           obj.column_name || ' varchar2(30)';
           
  dbms_output.put_line(l_cmd);
  
  begin
    if l_update = 'Y' then
      execute immediate l_cmd;
      l_oky := l_oky + 1;
    end if;
  exception when others then
    dbms_output.put_line(sqlcode || ' ' || sqlerrm);
    l_err := l_err + 1;
  end;
  
end loop;

zut.prt('total ' || l_tot);
zut.prt('okay  ' || l_oky);
zut.prt('error ' || l_err);

end;
/
alter table custitem modify descr varchar2(255);

spool off;
exit;
