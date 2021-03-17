set serveroutput on;

declare
l_sql varchar2(4000);
l_updflag char(1);
l_constraint_name user_constraints.constraint_name%type;
l_table_name user_tables.table_name%type;

begin

l_table_name := upper('&&1');
l_updflag := substr(upper('&&2'),1,1);
if trim(l_updflag) is null then
  l_updflag := 'N';
end if;

for ix in (select index_name
             from user_indexes
            where table_name = l_table_name
              and index_name not like 'SYS_IL%'
              and tablespace_name != 'USERS16KB'
            order by index_name)
loop

  begin
    select constraint_name
      into l_constraint_name
      from user_constraints
     where index_name = ix.index_name
       and table_name = l_table_name;
  exception when others then
    l_constraint_name := null;
  end;
  if l_constraint_name is not null then
    l_sql := 'alter table ' || l_table_name || ' disable constraint ' || l_constraint_name;
    zut.prt(l_sql);
    if l_updflag = 'Y' then
      execute immediate l_sql;
    end if;
  end if;
  l_sql := 'alter index ' || ix.index_name || ' rebuild tablespace users16kb';
  zut.prt(l_sql);
  if l_updflag = 'Y' then
    execute immediate l_sql;
  end if;
  if l_constraint_name is not null then
    l_sql := 'alter table ' || l_table_name || ' enable constraint ' || l_constraint_name;
    zut.prt(l_sql);
    if l_updflag = 'Y' then
      execute immediate l_sql;
    end if;
  end if;

end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
