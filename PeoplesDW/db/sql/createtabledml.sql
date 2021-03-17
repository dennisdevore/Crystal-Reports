--
-- $Id: createtabledml.sql 1 2005-05-26 12:20:03Z ed $
--
set serveroutput on format wrapped;
set heading off;
set verify off;
set echo off;
set term off;
set pagesize 0;
set trimspool on;
spool &&1..txt

declare

cursor curColumns is
  select *
    from user_tab_columns
   where table_name = upper('&&1')
   order by table_name,column_id;

l_text varchar2(255);
l_col_total int;
l_col_count int;
l_parm1 varchar2(255);

begin

dbms_output.enable(1000000);

l_parm1 := '&&1';

select count(1)
  into l_col_total
  from user_tab_columns
 where table_name = upper(l_parm1);

dbms_output.put_line('insert into ' || l_parm1);

l_col_count := 0;

for x in curColumns
loop
  l_col_count := l_col_count + 1;
  if l_col_count = 1 then
    l_text := ' (';
  else
    l_text := l_text || ',';
  end if;
  if length(l_text) + length(x.column_name) > 79 then
    dbms_output.put_line(l_text);
    l_text := '  ';
  end if;
  l_text := l_text || x.column_name;
  if l_col_count = l_col_total then
    l_text := l_text || ')';
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line(' values ');

l_col_count := 0;

for x in curColumns
loop
  l_col_count := l_col_count + 1;
  if l_col_count = 1 then
    l_text := ' (';
  else
    l_text := l_text || ',';
  end if;
  if length(l_text) + length(x.column_name) + 2 > 79 then
    dbms_output.put_line(l_text);
    l_text := '  ';
  end if;
  l_text := l_text || 'x.' || x.column_name;
  if l_col_count = l_col_total then
    l_text := l_text || ');';
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line('execute immediate ''insert into ' ||
                     l_parm1 || '_'' || strSuffix ||');

dbms_output.put_line('  ''  values '' ||');
l_col_count := 0;

for x in curColumns
loop
  l_col_count := l_col_count + 1;
  if l_col_count = 1 then
    l_text := '  '' (';
  else
    l_text := l_text || ',';
  end if;
  if length(l_text) + length(x.column_name) + 1 > 75 then
    dbms_output.put_line(l_text || ''' ||');
    l_text := '  '' ';
  end if;
  l_text := l_text || ':' || x.column_name;
  if l_col_count = l_col_total then
    l_text := l_text || ')''';
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line('  using ');

l_col_count := 0;
l_text := '  ';

for x in curColumns
loop
  l_col_count := l_col_count + 1;
  if l_col_count = 1 then
    null;
  else
    l_text := l_text || ',';
  end if;
  if length(l_text) + length(x.column_name) + 2 > 75 then
    dbms_output.put_line(l_text);
    l_text := '  ';
  end if;
  l_text := l_text || 'x.' || x.column_name;
  if l_col_count = l_col_total then
    l_text := l_text || ';';
    dbms_output.put_line(l_text);
  end if;
end loop;

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
spool off;
exit;
