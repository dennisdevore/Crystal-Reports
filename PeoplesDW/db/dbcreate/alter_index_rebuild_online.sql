set serveroutput on;

declare
l_cnt pls_integer := 0;
l_sql varchar2(4000);

begin

for idx in (select index_name
              from user_indexes
             where tablespace_name = 'USERS16KB')
loop

  l_sql := 'alter index ' || idx.index_name || ' rebuild online';
  zut.prt(l_sql);
  execute immediate l_sql;
  l_cnt := l_cnt + 1;

end loop;

zut.prt('indexes rebuild count: ' || l_cnt);

end;
/
exit;
