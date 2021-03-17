#!/bin/sh

IAM=`basename $0`

case $# in
2) ;;
*) echo -e "\nusage: $IAM custid* update_flag_yn\n"
   exit ;;
esac

cat >/tmp/$$.sql <<EOF
set serveroutput on;

declare

l_col_count pls_integer;
l_tbl_count pls_integer;
l_prev_table_name user_tables.table_name%type;
l_rowcount pls_integer;
l_tot_rowcount pls_integer;
updflag char(1);
cmdSql varchar2(4000);

begin

updflag := nvl(substr(upper('${2}'),1,1),'N');

zut.prt('CustId is ' || upper('${1}'));
zut.prt('Update flag is ' || updflag);
l_tot_rowcount := 0;
l_col_count := 0;
l_tbl_count := 0;
l_prev_table_name := null;

for obj in (select table_name,column_name
			  from user_tab_columns utc
             where column_name like '%CUSTID%'
               and exists (select 1
                             from user_objects uo
                            where utc.table_name = uo.object_name
                              and object_type = 'TABLE')
                            order by table_name,column_name)
loop

  if l_prev_table_name is null then
    l_tbl_count := 0;
	l_prev_table_name := obj.table_name;
  elsif l_prev_table_name != obj.table_name then
    l_tbl_count := l_tbl_count + 1;
	l_prev_table_name := obj.table_name;
  end if;
  
  l_col_count := l_col_count + 1;

  if updflag = 'Y' then
    cmdSql := 'delete from ' || obj.table_name ||
	          ' where ' || obj.column_name || ' = ''' || upper('${1}') || '''';
    zut.prt(cmdSql);
    execute immediate cmdSql;
    l_rowcount := sql%rowcount;
    commit;
	zut.prt('Rows deleted: ' || l_rowcount);
	l_tot_rowcount := l_tot_rowcount + l_rowcount;
  else
    cmdSql := 'select count(1) from ' || obj.table_name ||
	          ' where ' || obj.column_name || ' = ''' || upper('${1}') || '''';
    zut.prt(cmdSql);
    execute immediate cmdSql into l_rowcount;
	zut.prt('Rows to be deleted: ' || l_rowcount);
	l_tot_rowcount := l_tot_rowcount + l_rowcount;
  end if;

end loop;

zut.prt('Tables processed: ' || l_tbl_count);
zut.prt('Columns processed: ' || l_col_count);
zut.prt('Total rows processed: ' || l_tot_rowcount);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit
EOF
sqlplus -S alps/alps @/tmp/$$.sql
rm /tmp/$$.sql
