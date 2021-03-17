--
-- $Id$
--
set serveroutput on;

declare
   l_cnt pls_integer;
   l_update char(1);
begin
   dbms_output.enable(1000000);
   l_update := upper('&1');

   for utc in (select C.table_name
                  from user_tab_columns C, user_objects O
                  where C.column_name = 'LASTUSER'
                    and O.object_name = C.table_name
                    and O.object_type = 'TABLE'
                  order by C.table_name) loop

      execute immediate 'select count(1) from '||utc.table_name
            into l_cnt;

      if l_cnt > 50000 then
         dbms_output.put_line('Skipping '||utc.table_name||': '||l_cnt);
      elsif l_cnt > 0 then
         execute immediate 'select count(1) from '||utc.table_name
               || ' where upper(lastuser) = ''SUP'''
               into l_cnt;    
         if l_cnt > 0 then                          
            if l_update = 'Y' then
               execute immediate 'update '||utc.table_name
                     || ' set lastuser = ''SYNAPSE'' where upper(lastuser) = ''SUP''';
            end if;
            dbms_output.put_line(utc.table_name||': '||l_cnt);
         end if;
      end if;
   end loop;
   if l_update = 'Y' then
      commit;
   end if;
end;
/
exit;
