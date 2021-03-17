#!/bin/sh

IAM=`basename $0`

case $# in
1) ;;
*) echo -e "\nusage: $IAM update_flag_yn\n"
   exit ;;
esac

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare

cntTot integer;
cntDrop integer;
updflag char(1);
cmdSql varchar2(4000);

begin

updflag := nvl(substr(upper('${1}'),1,1),'N');

zut.prt('Update flag is ' || updflag);
cntTot := 0;
cntDrop := 0;

for obj in (select object_name, object_type,
                   to_char(last_ddl_time, 'mm/dd/yy hh24:mi:ss') last_ddl_time
              from user_objects
             where object_type in ('TABLE','VIEW')
               and object_name like 'RCPT_NOTE_944\_%\_%' escape '\'
               and last_ddl_time < sysdate - .035
             order by object_name)
loop

  cntTot := cntTot + 1;

  if updflag = 'Y' then
    cmdSql := 'drop ' || rtrim(obj.object_type) || ' ' || obj.object_name;
    cntDrop := cntDrop + 1;
    zut.prt(cmdSql);
    execute immediate cmdSql;
  else
    zut.prt('Selected ' || obj.object_type || ' ' ||obj.object_name || ' ' ||
            obj.last_ddl_time);
  end if;

end loop;

zut.prt('Total   ' || cntTot);
zut.prt('Deleted ' || cntDrop);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit
EOF
sqlplus -S alps/alps @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
