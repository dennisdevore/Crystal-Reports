#!/bin/sh

IAM=`basename $0`

cat >/tmp/$IAM.$$.sql <<EOF

set feedback off verify off serveroutput on linesize 4000 trimspool on;
spool $IAM.sql
declare
cmdSql varchar2(4000);

begin

dbms_output.enable(1000000);

for q in (select name from user_queues
           where queue_type in ('NORMAL_QUEUE')
            order by name)
loop
  cmdSql := 'exec dbms_aqadm.start_queue(queue_name => ''' || q.name || ''')';
  dbms_output.put_line(cmdSql);
end loop;

dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
spool off;
exit;
EOF
sqlplus -s ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
sqlplus -s ${ALPS_DBLOGON} @$IAM.sql
rm /tmp/$IAM.$$.sql
