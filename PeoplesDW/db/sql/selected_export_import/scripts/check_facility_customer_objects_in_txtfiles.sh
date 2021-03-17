#!/bin/sh

ls -1 parfiles_for_facility_customer/*.txt > dumps/txtfiles_for_facility_customer$$.out

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;
set verify off trimspool on feedback off;

declare

type obj_rcd_type is record (
  object_name user_tables.table_name%type,
  object_found boolean
);

type obj_tbl_type is table of obj_rcd_type index by binary_integer;

txts obj_tbl_type;
txtx binary_integer;
txtfoundx binary_integer;

l_fty_filelist utl_file.file_type;
l_fty_file utl_file.file_type;
l_inline varchar2(32767);
l_txt_file_name varchar2(4000);
l_object_name varchar2(4000);
l_txt_tot pls_integer := 0;
l_txt_dup pls_integer := 0;
l_txt_ntf pls_integer := 0;
l_obj_tot pls_integer := 0;
l_obj_oky pls_integer := 0;
l_obj_ntf pls_integer := 0;

begin

begin
  l_fty_filelist := utl_file.fopen('SYNAPSE_$$_DUMPS','txtfiles_for_facility_customer$$.out','r',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('txtfiles_for_facility_customer$$.out open error');
  return;
end;

--dbms_output.put_line('begin txtfiles_for_facility_customer processing...');
while(1=1)
loop
  begin
    utl_file.get_line(l_fty_filelist,l_inline,32767);
  exception when NO_DATA_FOUND then
    if utl_file.is_open(l_fty_filelist) then
      utl_file.fclose(l_fty_filelist);
    end if;
    exit;
  end;
  l_txt_file_name := l_inline;
--  dbms_output.put_line('processing txtfile ' || l_txt_file_name || '...');
  begin
    l_fty_file := utl_file.fopen('SYNAPSE_$$_PARFILES',l_txt_file_name,'r',32767);
  exception when others then
    dbms_output.put_line(sqlerrm);
    dbms_output.put_line('txtfile file open error ' || l_txt_file_name);
    return;
  end;
  while(1=1)
  loop
    begin
      utl_file.get_line(l_fty_file,l_inline,32767);
      if (substr(l_inline,1,1) != '#') and
         (trim(l_inline) is not null) then
        l_txt_tot := l_txt_tot + 1;
        l_object_name := trim(upper(l_inline));
        txtfoundx := 0;
        if Length(nvl(l_object_name,'x')) > 1 then
          for txtx in 1..txts.count
          loop
            if txts(txtx).object_name = l_object_name then
              txtfoundx := txtx;
              exit;
            end if;
          end loop;
        end if;
        if txtfoundx = 0 then
          txtx := txts.count + 1;
          txts(txtx).object_name := l_object_name;
          txts(txtx).object_found := False;
        else
          dbms_output.put_line('Duplicate entry in txt files: ' || l_object_name);
          l_txt_dup := l_txt_dup + 1;
        end if;
      end if;
    exception when NO_DATA_FOUND then
      if utl_file.is_open(l_fty_file) then
        utl_file.fclose(l_fty_file);
      end if;
      exit;
    end;
  end loop;
end loop;

for uo in (select table_name
             from user_tables
            where exists (select 1
                            from user_objects
                           where user_tables.table_name = user_objects.object_name
                             and object_type = 'TABLE'
                             and object_name not like 'SYS_EXPORT_SCHEMA%')
            order by user_tables.table_name)
loop
  l_obj_tot := l_obj_tot + 1;
  txtfoundx := 0;
  for txtx in 1..txts.count
  loop
    if txts(txtx).object_name = uo.table_name then
      txts(txtx).object_found := True;
      txtfoundx := txtx;
      exit;
    end if;
  end loop;
  if txtfoundx = 0 then
    select count(1)
      into txtfoundx
      from tabledefs
     where upper(tableid) = uo.table_name;
  end if;
  if txtfoundx = 0 then
    l_obj_ntf := l_obj_ntf + 1;
    dbms_output.put_line('db object not found in txt file: ' || uo.table_name);
  else
    l_obj_oky := l_obj_oky + 1;  
  end if;    
end loop;

for txtx in 1..txts.count
loop
  if txts(txtx).object_found = False then
    l_txt_ntf := l_txt_ntf + 1;
    dbms_output.put_line('txt file object not found in db: ' || txts(txtx).object_name);
  end if;
end loop;

dbms_output.put_line('txtfile tot obj count is ' || l_txt_tot);
if l_txt_dup <> 0 then
  dbms_output.put_line('txtfile *duplicates* is  ' || l_txt_dup);
end if;
if l_txt_ntf <> 0 then
  dbms_output.put_line('txtfile *not found* is   ' || l_txt_ntf);
end if;
dbms_output.put_line('db tot obj count is  ' || l_obj_tot);
--dbms_output.put_line('db oky obj count is  ' || l_obj_oky);
if l_obj_ntf <> 0 then
  dbms_output.put_line('db *not found* is    ' || l_obj_ntf);
end if;

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
rm dumps/txtfiles_for_facility_customer$$.out

