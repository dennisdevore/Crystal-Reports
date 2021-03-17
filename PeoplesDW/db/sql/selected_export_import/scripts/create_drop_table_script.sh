#!/bin/sh

case $# in
1) ;;
*) echo -e "\nusage: $IAM <parfile directory>\n"
   return ;;
esac

cd $1

temp_file=../temp$$.sql
create_file=../create$$.sql
drop_file=../drop_extra_tables.sql

for f in *; do
  cat $f >> $temp_file
done

sed -e '/^$/d' $temp_file > $create_file
mv -f $create_file $temp_file

sed "s/^/insert into tmp_keep_tables(table_name) values ('/g" $temp_file > $create_file
mv -f $create_file $temp_file

sed "s/$/');/g" $temp_file > $create_file
mv -f $create_file $temp_file

echo "create table tmp_keep_tables (table_name varchar2(100) primary key);" > $create_file
echo "truncate table tmp_keep_tables;" >> $create_file
cat $temp_file >> $create_file
echo "update tmp_keep_tables set table_name = upper(table_name);" >> $create_file
echo "commit;" >> $create_file
echo "exit;" >> $create_file
echo "/" >> $create_file
rm -f $temp_file

sqlf $create_file
rm -f $create_file

sqlplus -s ${ALPS_DBLOGON} >$drop_file <<EOF
  set serveroutput on size unlimited
  set linesize 1000
  set heading off
  set pagesize 0
  set feedback off

  select 'drop table ' || table_name || ';'
  from user_tables a
  where not exists (select 1 from tmp_keep_tables where table_name = a.table_name)
    and table_name <> 'TMP_KEEP_TABLES' 
  order by table_name; 

  drop table tmp_keep_tables;
EOF


cd ..
