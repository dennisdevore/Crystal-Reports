#!/bin/sh

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare

l_fty_parfile utl_file.file_type;
l_inline varchar2(32767);
l_outline varchar2(255);

begin

begin
  l_fty_parfile := utl_file.fopen('SYNAPSE_$$_DUMPS','imp_$1.par','w',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfile open error');
  return;
end;

utl_file.put_line(l_fty_parfile, 'directory=SYNAPSE_$$_DUMPS');
utl_file.put_line(l_fty_parfile, 'dumpfile=$1.dmp');
utl_file.put_line(l_fty_parfile, 'logfile=imp_$1.log');
utl_file.put_line(l_fty_parfile, 'table_exists_action=replace');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
