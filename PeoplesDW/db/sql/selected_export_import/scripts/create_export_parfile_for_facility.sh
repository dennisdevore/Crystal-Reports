#!/bin/sh

ls -1 parfiles_for_facility/*.txt > dumps/parfiles_for_facility$$.out
FACILITIES=`echo $1 |  sed 's/,/_/g'`

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

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
l_fty_parfile utl_file.file_type;
l_inline varchar2(32767);
l_outline varchar2(255);
l_txt_file_name varchar2(4000);
l_object_name varchar2(4000);
l_tbl_tot pls_integer := 0;
l_txt_dup pls_integer := 0;
l_txt_ntf pls_integer := 0;
l_obj_tot pls_integer := 0;
l_obj_oky pls_integer := 0;
l_obj_ntf pls_integer := 0;
l_facilities varchar2(100);
l_query_clause varchar2(4000);
l_11g_version_count pls_integer;
l_table_count pls_integer;

begin

l_facilities := '$1';
l_facilities := '''' || replace(l_facilities, ',', ''',''') || '''';

begin
  l_fty_parfile := utl_file.fopen('SYNAPSE_$$_DUMPS','exp_facility_${FACILITIES}_$2.par','w',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfile open error');
  return;
end;

utl_file.put_line(l_fty_parfile, 'directory=SYNAPSE_$$_DUMPS');
utl_file.put_line(l_fty_parfile, 'dumpfile=exp_facility_${FACILITIES}_$2.dmp');
utl_file.put_line(l_fty_parfile, 'logfile=exp_facility_${FACILITIES}_$2.log');
utl_file.put_line(l_fty_parfile, 'exclude=statistics');
select count(1)
  into l_11g_version_count
  from v\$version
 where banner like '%11g%';
if l_11g_version_count != 0 then
  utl_file.put_line(l_fty_parfile, 'reuse_dumpfiles=y');
end if;
utl_file.put_line(l_fty_parfile, 'content=$2');
utl_file.put_line(l_fty_parfile, 'query=');

begin
  l_fty_filelist := utl_file.fopen('SYNAPSE_$$_DUMPS','parfiles_for_facility$$.out','r',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfiles_for_facility.out open error');
  return;
end;

--dbms_output.put_line('begin parfiles_for_facility processing...');
l_tbl_tot := 0;

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
--  dbms_output.put_line('processing parfile ' || l_txt_file_name || '...');
  begin
    l_fty_file := utl_file.fopen('SYNAPSE_$$_PARFILES',l_txt_file_name,'r',32767);
  exception when others then
    dbms_output.put_line(sqlerrm);
    dbms_output.put_line('parfile file open error ' || l_txt_file_name);
    return;
  end;
  while(1=1)
  loop
    begin
      utl_file.get_line(l_fty_file,l_inline,32767);
      if (substr(l_inline,1,1) != '#') and
         (trim(l_inline) is not null) then
        l_object_name := trim(upper(l_inline));
        l_tbl_tot := l_tbl_tot + 1;
        if l_tbl_tot > 1 then
          l_outline := ',';
        else
          l_outline := '';
        end if;
        select count(1)
          into l_table_count
          from user_tables
         where table_name = l_object_name;
        l_query_clause := null;
        if l_table_count != 0 then
          case l_txt_file_name
            when 'parfiles_for_facility/by_facility_tables.txt' then
              l_query_clause := 'where facility in (' || l_facilities || ') or facility is null';
            when 'parfiles_for_facility/by_customer_tables.txt' then
              l_query_clause := 'where custid = ''DEFAULT'' ' ||
               ' or custid in (select distinct custid from custfacility where facility in (' || l_facilities || '))';
            when 'parfiles_for_facility/unconditional_tables.txt' then
              l_query_clause := null;
            when 'parfiles_for_facility/filter_later_tables.txt' then
              l_query_clause := null;
            else
              l_query_clause := 'where 1 = 0';
          end case;
        end if;
        if l_query_clause is not null then
          l_outline := l_outline || l_object_name || ':"' || l_query_clause || '"';
          utl_file.put_line(l_fty_parfile, l_outline);
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

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others...');
end;
/
exit;
EOF
sqls @/tmp/$IAM.$$.sql
rm /tmp/$IAM.$$.sql
rm dumps/parfiles_for_facility$$.out
