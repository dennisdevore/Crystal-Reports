#!/bin/sh

ls -1 parfiles_for_order/*.txt > dumps/parfiles_for_order$$.out

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
l_outline varchar2(10000);
l_txt_file_name varchar2(10000);
l_object_name varchar2(10000);
l_tbl_tot pls_integer := 0;
l_txt_dup pls_integer := 0;
l_txt_ntf pls_integer := 0;
l_obj_tot pls_integer := 0;
l_obj_oky pls_integer := 0;
l_obj_ntf pls_integer := 0;
l_custid customer.custid%type;
l_has_loads number;
l_wave waves.wave%type;
l_wave_row waves%rowtype;
l_order_row orderhdr%rowtype;
l_query_clause varchar2(10000);
l_11g_version_count pls_integer;
l_table_count pls_integer;

begin

l_wave := $1;

begin
  select *
  into l_wave_row
  from waves
  where wave = l_wave;
exception
  when others then
    dbms_output.put_line('Unable to find wave ' || l_wave);
  return;
end;

begin
  select * 
  into l_order_row
  from orderhdr
  where orderid = l_wave and rownum = 1;
exception
  when others then
    l_order_row := null;
end;

select count(1)
into l_has_loads
from orderhdr
where loadno is not null and (orderid = l_wave or wave = l_wave);

begin
  l_fty_parfile := utl_file.fopen('SYNAPSE_$$_DUMPS','exp_order_$1_$2_$3.par','w',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfile open error');
  return;
end;

utl_file.put_line(l_fty_parfile, 'directory=SYNAPSE_$$_DUMPS');
utl_file.put_line(l_fty_parfile, 'dumpfile=exp_order_$1_$2_$3.dmp');
utl_file.put_line(l_fty_parfile, 'logfile=exp_order_$1_$2_$3.log');
utl_file.put_line(l_fty_parfile, 'exclude=statistics');
select count(1)
  into l_11g_version_count
  from v\$version
 where banner like '%11g%';
if l_11g_version_count != 0 then
  utl_file.put_line(l_fty_parfile, 'reuse_dumpfiles=y');
end if;
utl_file.put_line(l_fty_parfile, 'content=$3');
utl_file.put_line(l_fty_parfile, 'query=');

begin
  l_fty_filelist := utl_file.fopen('SYNAPSE_$$_DUMPS','parfiles_for_order$$.out','r',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfiles_for_order.out open error');
  return;
end;

--dbms_output.put_line('begin parfiles_for_order processing...');
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
            when 'parfiles_for_order/by_custid_tables.txt' then
              l_query_clause := 'where custid = ''DEFAULT'' or custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')';
            when 'parfiles_for_order/by_custworkorder_tables.txt' then
              l_query_clause := 'where seq in (select distinct seq from custworkorder ' ||
                                               'where custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || '))';
            when 'parfiles_for_order/by_facility_tables.txt' then
              l_query_clause := 'where facility in (''' || l_wave_row.facility || ''',''' || nvl(l_order_row.fromfacility,l_order_row.tofacility) || ''')';
            when 'parfiles_for_order/by_facility_custid_tables.txt' then
              l_query_clause := 'where facility in (''' || l_wave_row.facility || ''',''' || nvl(l_order_row.fromfacility,l_order_row.tofacility) || ''')' ||
                                ' and custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')';
            when 'parfiles_for_order/by_facility_custid_orderid_tables.txt' then
              l_query_clause := 'where facility in (''' || l_wave_row.facility || ''',''' || nvl(l_order_row.fromfacility,l_order_row.tofacility) || ''')' ||
                                ' and custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')' ||
                                ' and (orderid, shipid) in (select orderid, shipid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')';
            when 'parfiles_for_order/by_invoice_tables.txt' then
              l_query_clause := 'where invoice in (select distinct invoice from ' ||
                                'invoicedtl where (orderid, shipid) in (select orderid, shipid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || '))';
            when 'parfiles_for_order/by_loadno_tables.txt' then
              if l_has_loads > 0 then
                l_query_clause := 'where loadno in (select distinct loadno from orderhdr
                                                    where (orderid = ' || l_wave || ' or wave = ' || l_wave || ') and loadno is not null)';
              else
                l_query_clause := 'where 1 = 0';
              end if;
            when 'parfiles_for_order/by_orderid_tables.txt' then
              l_query_clause := 'where (orderid, shipid) in (select orderid, shipid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')'; 
            when 'parfiles_for_order/by_orderid_noshipid.txt' then
              l_query_clause := 'where (orderid) in (select orderid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')';
            when 'parfiles_for_order/by_plate_tables.txt' then
              l_query_clause := 'where (custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')' ||
                                ' and type != ''XP'') ' ||
                                'or (custid in (select distinct custid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')' ||
                                ' and type = ''XP'' and lpid in (select ' ||
                                'distinct fromlpid from shippingplate ' ||
                                'where (orderid, shipid) in (select orderid, shipid from orderhdr where orderid = ' || l_wave || ' or wave = ' || l_wave || ')' || 
                                ' and parentlpid is null))';
            when 'parfiles_for_order/by_wave_tables.txt' then
              l_query_clause := 'where wave in (' || l_wave || ',' || nvl(l_order_row.wave,-1) || ')';
            when 'parfiles_for_order/unconditional_tables.txt' then
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
rm dumps/parfiles_for_order$$.out
