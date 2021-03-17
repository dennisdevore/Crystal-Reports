#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare
  l_fty_customers utl_file.file_type;
  l_fty_users utl_file.file_type;
  l_fty_facilities utl_file.file_type;
  l_inline varchar2(32767);
begin

  /* INSERT CUSTOMERS */
  execute immediate 'truncate table tmp_customers';
  
  begin
    l_fty_customers := utl_file.fopen('SYNAPSE_$$_FILTER','customers.txt','r',32767);
  exception when others then
    dbms_output.put_line(sqlerrm);
    dbms_output.put_line('customers.txt open error');
    return;
  end;
  
  while(1=1)
  loop
    begin
      utl_file.get_line(l_fty_customers,l_inline,32767);
      
      if (substr(l_inline,1,1) != '#') and(trim(l_inline) is not null) then
        insert into tmp_customers (custid) values (trim(l_inline));
      end if;
      
    exception when NO_DATA_FOUND then
      if utl_file.is_open(l_fty_customers) then
        utl_file.fclose(l_fty_customers);
      end if;
      exit;
    end;
  end loop;
  
  /* INSERT USERS */
  execute immediate 'truncate table tmp_users';
  
  begin
    l_fty_users := utl_file.fopen('SYNAPSE_$$_FILTER','users.txt','r',32767);
  exception when others then
    dbms_output.put_line(sqlerrm);
    dbms_output.put_line('customers.txt open error');
    return;
  end;
  
  while(1=1)
  loop
    begin
      utl_file.get_line(l_fty_users,l_inline,32767);
      
      if (substr(l_inline,1,1) != '#') and(trim(l_inline) is not null) then
        insert into tmp_users (nameid) values (trim(l_inline));
      end if;
      
    exception when NO_DATA_FOUND then
      if utl_file.is_open(l_fty_users) then
        utl_file.fclose(l_fty_users);
      end if;
      exit;
    end;
  end loop;
  
  /* INSERT FACILITIES */
  execute immediate 'truncate table tmp_facilities';
  
  begin
    l_fty_facilities := utl_file.fopen('SYNAPSE_$$_FILTER','facilities.txt','r',32767);
  exception when others then
    dbms_output.put_line(sqlerrm);
    dbms_output.put_line('facilities.txt open error');
    return;
  end;
  
  while(1=1)
  loop
    begin
      utl_file.get_line(l_fty_facilities,l_inline,32767);
      
      if (substr(l_inline,1,1) != '#') and(trim(l_inline) is not null) then
        insert into tmp_facilities (facility) values (trim(l_inline));
      end if;
      
    exception when NO_DATA_FOUND then
      if utl_file.is_open(l_fty_facilities) then
        utl_file.fclose(l_fty_facilities);
      end if;
      exit;
    end;
  end loop;
  
  commit;
    
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
  rollback;
end;
/
exit;
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
