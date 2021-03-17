#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare
l_fty_parfile utl_file.file_type;
l_outline varchar2(255);

begin

begin
  l_fty_parfile := utl_file.fopen('SYNAPSE_$$_DUMPS','exp_fac_cust_$1_$2.sql','w',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfile open error');
  return;
end;

utl_file.put_line(l_fty_parfile, 'begin');
utl_file.put_line(l_fty_parfile, 'for syn in (select synonym_name');
utl_file.put_line(l_fty_parfile, '              from all_synonyms');
utl_file.put_line(l_fty_parfile, '             where table_owner = ''ALPS''');
utl_file.put_line(l_fty_parfile, '               and owner = ''PUBLIC'')');
utl_file.put_line(l_fty_parfile, 'loop');
utl_file.put_line(l_fty_parfile, '  execute immediate ''drop public synonym '' || syn.synonym_name;');
utl_file.put_line(l_fty_parfile, 'end loop;');
utl_file.put_line(l_fty_parfile, 'end;');
utl_file.put_line(l_fty_parfile, '/');
for syn in (select synonym_name,table_name
              from all_synonyms
             where table_owner = 'ALPS'
               and owner = 'PUBLIC')
loop
  utl_file.put(l_fty_parfile, 'create public synonym ' );
  utl_file.put(l_fty_parfile, syn.synonym_name );
  utl_file.put(l_fty_parfile, ' for ' );
  utl_file.put_line(l_fty_parfile, syn.table_name || ';');
end loop;
utl_file.put_line(l_fty_parfile, 'exit;');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
