#!/bin/sh

IAM=`basename $0`

case $# in
0) ;;
*) echo -e "\nusage: $IAM\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF

set feedback off verify off serveroutput on linesize 4000 trimspool on;
spool $IAM.sql
declare
cmdSql varchar2(4000);
updflag char(1) := 'N';

begin

dbms_output.enable(1000000);

for obj in (select table_name
              from user_tables ut
             where ( (table_name like '%\_OLD' escape '\') or
                     (table_name like '%\_NEW' escape '\') )
               and exists (select 1
                             from user_tab_columns utc
                            where ut.table_name = utc.table_name
                              and utc.column_name = 'MOD_TABLE_NAME'))
                       
loop
  cmdSql := 'truncate table ' || obj.table_name;
  dbms_output.put_line(cmdSql);
  if updflag = 'Y' then
    execute immediate cmdSql;
  end if;
end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
spool off;
exit;
EOF
sqlplus -s ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
