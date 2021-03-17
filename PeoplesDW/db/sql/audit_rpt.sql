set serveroutput on;
set heading off;
spool audit_rpt.out;

declare
l_cursor aud_mod_rpt_pkg.aud_mod_rpt_type;
l_sessionid number := 0;
l_key_value varchar2(4000);
l_prev aud_mod_rpt%rowtype := null;

begin

select sys_context('USERENV','SESSIONID')
  into l_sessionid
  from dual;

aud_mod_rpt_proc(l_cursor,
                 sysdate - 500, -- begin date
                 sysdate,  -- end date
                 'CUSTOMER', -- table name
                 '', -- facility
                 '', -- custid
                 '', -- item
                 'Y', -- show insert/delete detail
                 ''); -- column

for obj in (select *
              from aud_mod_rpt
             where sessionid = l_sessionid
             order by mod_seq desc, mod_column)
loop

  if (nvl(l_prev.mod_type,'x') = 'x') or
     (l_prev.mod_time <> obj.mod_time) or
     (l_prev.mod_type <> obj.mod_type) or
     (l_prev.mod_table_name <> obj.mod_table_name) or
     (nvl(l_prev.mod_key1,'x') <> nvl(obj.mod_key1,'x')) or
     (nvl(l_prev.mod_key2,'x') <> nvl(obj.mod_key2,'x')) or
     (nvl(l_prev.mod_key3,'x') <> nvl(obj.mod_key3,'x')) or
     (nvl(l_prev.mod_key4,'x') <> nvl(obj.mod_key4,'x')) or
     (nvl(l_prev.mod_key5,'x') <> nvl(obj.mod_key5,'x')) or
     (nvl(l_prev.mod_key6,'x') <> nvl(obj.mod_key6,'x')) then
    l_key_value := '[' || obj.mod_key1;
    if obj.mod_key2 is not null then
      l_key_value := l_key_value || '|' || obj.mod_key2;
    end if;
    if obj.mod_key3 is not null then
      l_key_value := l_key_value || '|' || obj.mod_key3;
    end if;
    if obj.mod_key4 is not null then
      l_key_value := l_key_value || '|' || obj.mod_key4;
    end if;
    if obj.mod_key5 is not null then
      l_key_value := l_key_value || '|' || obj.mod_key5;
    end if;
    if obj.mod_key6 is not null then
      l_key_value := l_key_value || '|' || obj.mod_key6;
    end if;
    l_key_value := l_key_value || ']';
    dbms_output.put_line(to_char(obj.mod_time, 'mm/dd/yy hh24:mi:ss') ||
       ' ' || obj.mod_type || ' ' || obj.mod_table_name || ' ' || l_key_value);
    l_prev := obj;
  end if;
  
  dbms_output.put_line(obj.mod_column || ' old: (' || obj.mod_old_col_value ||
                       ') new: (' || obj.mod_new_col_value || ')');  
  
end loop;
                               
exception when others then
  zut.prt(sqlerrm);
end;
/
exit;


