#!/bin/sh

IAM=`basename $0`

cat >/tmp/$IAM.$$.sql <<EOF

set feedback off verify off serveroutput on linesize 4000 trimspool on;
spool $IAM.sql
declare
cmdSql varchar2(4000);

begin

dbms_output.enable(1000000);

for obj in (select constraint_name, table_name
              from user_constraints
             where status = 'DISABLED')
loop
  cmdSql := 'alter table ' || obj.table_name || ' enable constraint ' ||
            obj.constraint_name || ';';
  dbms_output.put_line(cmdSql);
end loop;

dbms_output.put_line('exit;');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
spool off;
exit;
EOF
sqlplus -s ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
sqlplus -s ${ALPS_DBLOGON} @$IAM.sql
rm /tmp/$IAM.$$.sql
