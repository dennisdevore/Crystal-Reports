set serveroutput on;
spool after_prod_copy_to_test.out
declare
l_cmdSql varchar2(4000);
l_new_targetalias impexp_definitions.targetalias%type;
l_new_defaultvalue systemdefaults.defaultvalue%type;
l_updflag char(1);

begin

l_updflag := upper('&&1');

dbms_output.enable(1000000);

for obj in (select rowid,impexp_definitions.*
              from impexp_definitions
             where instr(targetalias, 'prod') != 0)
loop

  l_new_targetalias := replace(obj.targetalias, 'prod', 'test');
  l_cmdSql := 'update impexp_definitions set targetalias = ''' ||
            l_new_targetalias || ''' ' ||
            'where rowid = ''' || obj.rowid || '''';
            
  dbms_output.put_line(l_cmdSql);
  if l_updflag = 'Y' then
    execute immediate l_cmdSql;
  end if;
  
end loop;

for obj in (select rowid,impexp_definitions.*
              from impexp_definitions
             where instr(targetalias, 'PROD') != 0)
loop

  l_new_targetalias := replace(obj.targetalias, 'PROD', 'TEST');
  l_cmdSql := 'update impexp_definitions set targetalias = ''' ||
            l_new_targetalias || ''' ' ||
            'where rowid = ''' || obj.rowid || '''';
            
  dbms_output.put_line(l_cmdSql);
  if l_updflag = 'Y' then
    execute immediate l_cmdSql;
  end if;
  
end loop;

for obj in (select rowid,systemdefaults.*
              from systemdefaults
             where instr(defaultvalue, 'prod') != 0)
loop

  l_new_defaultvalue := replace(obj.defaultvalue, 'prod', 'test');
  l_cmdSql := 'update systemdefaults set defaultvalue = ''' ||
            l_new_defaultvalue || ''' ' ||
            'where rowid = ''' || obj.rowid || '''';
            
  dbms_output.put_line(l_cmdSql);
  if l_updflag = 'Y' then
    execute immediate l_cmdSql;
  end if;
  
end loop;


for obj in (select rowid,systemdefaults.*
              from systemdefaults
             where instr(defaultvalue, 'PROD') != 0)
loop

  l_new_defaultvalue := replace(obj.defaultvalue, 'PROD', 'TEST');
  l_cmdSql := 'update systemdefaults set defaultvalue = ''' ||
            l_new_defaultvalue || ''' ' ||
            'where rowid = ''' || obj.rowid || '''';
            
  dbms_output.put_line(l_cmdSql);
  if l_updflag = 'Y' then
    execute immediate l_cmdSql;
  end if;
  
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
