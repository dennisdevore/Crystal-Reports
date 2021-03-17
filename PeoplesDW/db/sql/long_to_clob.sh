#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM update_flag_yn\n"
   return ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare

cntTot integer;
cntAltered integer;
updflag char(1);
cmdSql varchar2(4000);

begin

updflag := nvl(substr(upper('${1}'),1,1),'N');

zut.prt('Update flag is ' || updflag);
cntTot := 0;
cntAltered := 0;

for obj in (select table_name,column_name,char_length,data_type
              from user_tab_columns utc
             where data_type = 'LONG'
               and table_name not in ('PLAN_TABLE')
               and exists (select 1
                             from user_objects uo
                            where utc.table_name = uo.object_name
                              and object_type = 'TABLE')
             order by table_name,column_name)
loop

  cntTot := cntTot + 1;
  
  cmdSql := 'alter table ' || obj.table_name ||
            ' modify ' || obj.column_name || ' ' ||
            'clob';
            
  zut.prt(cmdSql);
  
  if updflag = 'Y' then
    execute immediate cmdSql;
    cntAltered := cntAltered + 1;
  end if;

end loop;

zut.prt('Total   ' || cntTot);
zut.prt('Altered ' || cntAltered);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
