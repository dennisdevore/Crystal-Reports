#!/bin/sh

ls -1 parfiles_for_facility_customer/*.txt > dumps/parfiles_for_facility_customer$$.out
FACILITIES=`echo $1 |  sed 's/,/_/g'`

cat >/tmp/$IAM.$$.sql <<EOF
set serveroutput on;

declare
  l_table_exists number := 0;
begin

  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_FACILITY';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_FACILITY');
    execute immediate 'truncate table EXPORT_TMP_FACILITY';
  else
    dbms_output.put_line('Creating EXPORT_TMP_FACILITY');
    execute immediate '
      create table EXPORT_TMP_FACILITY
      as select facility from facility where 1=0';
  end if;
  
  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_CUSTOMER';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_CUSTOMER');
    execute immediate 'truncate table EXPORT_TMP_CUSTOMER';
  else
    dbms_output.put_line('Creating EXPORT_TMP_CUSTOMER');
    execute immediate '
      create table EXPORT_TMP_CUSTOMER
      as select custid from customer where 1=0';
  end if;
  
  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_ORDERS';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_ORDERS');
    execute immediate 'truncate table EXPORT_TMP_ORDERS';
  else
    dbms_output.put_line('Creating EXPORT_TMP_ORDERS');
    execute immediate '
      create table EXPORT_TMP_ORDERS
      as select orderid,shipid from orderhdr where 1=0';
  end if;
  
  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_LOADS';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_LOADS');
    execute immediate 'truncate table EXPORT_TMP_LOADS';
  else
    dbms_output.put_line('Creating EXPORT_TMP_LOADS');
    execute immediate '
      create table EXPORT_TMP_LOADS
      as select loadno from loads where 1=0';
  end if;
  
  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_POSTHDR';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_POSTHDR');
    execute immediate 'truncate table EXPORT_TMP_POSTHDR';
  else
    dbms_output.put_line('Creating EXPORT_TMP_POSTHDR');
    execute immediate '
      create table EXPORT_TMP_POSTHDR
      as select invoice from posthdr where 1=0';
  end if;
  
  select count(1) into l_table_exists from user_tables where table_name = 'EXPORT_TMP_CUSTWO';
  if (l_table_exists > 0) then
    dbms_output.put_line('Truncating EXPORT_TMP_CUSTWO');
    execute immediate 'truncate table EXPORT_TMP_CUSTWO';
  else
    dbms_output.put_line('Creating EXPORT_TMP_CUSTWO');
    execute immediate '
      create table EXPORT_TMP_CUSTWO
      as select seq from custworkorder where 1=0';
  end if;
end;
/

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
l_facilities varchar2(4000);
l_customers varchar2(4000);
l_query_clause varchar2(4000);
l_11g_version_count pls_integer;
l_table_count pls_integer;
l_incremental varchar2(1);
l_need_facility varchar2(1);
l_need_customer varchar2(1);
l_facility_clause varchar2(200);
l_customer_clause varchar2(200);
l_norows_clause varchar2(200);
l_by_custworkorder_clause varchar2(200);
l_by_custfac_clause varchar2(200);

begin

if (upper('$3') = 'Y') then
  l_incremental := 'Y';
else
  l_incremental := 'N';
end if;

if (l_incremental = 'N' or upper('$4') = 'Y') then
  l_need_facility := 'Y';
else
  l_need_facility := 'N';
end if;

if (l_incremental = 'N' or upper('$5') = 'Y') then
  l_need_customer := 'Y';
else
  l_need_customer := 'N';
end if;

dbms_output.put_line('Incremental Update: ' || l_incremental);
dbms_output.put_line('Need Facility Information: ' || l_need_facility);
dbms_output.put_line('Need Customer Information: ' || l_need_customer);

l_facilities := '$1';
l_facilities := '''' || replace(l_facilities, ',', ''',''') || '''';

l_customers := '$2';
l_customers := '''' || replace(l_customers, ',', ''',''') || '''';

dbms_output.put_line('Facilities: ' || l_facilities);
dbms_output.put_line('Customers: ' || l_customers);

execute immediate '
  insert into EXPORT_TMP_FACILITY
  select facility 
  from facility
  where facility in (' || l_facilities || ')
';
dbms_output.put_line('Facilities added: ' || sql%rowcount);

if (l_customers = '''ALL''') then
  execute immediate '
    insert into EXPORT_TMP_CUSTOMER
    select distinct custid 
    from custfacility a, EXPORT_TMP_FACILITY b
    where a.facility = b.facility
  ';
else
  execute immediate '
    insert into EXPORT_TMP_CUSTOMER
    select custid 
    from customer
    where custid in (' || l_customers || ')
  ';
end if;
dbms_output.put_line('Customers added: ' || sql%rowcount);

execute immediate '
  insert into EXPORT_TMP_ORDERS
  select orderid, shipid 
  from orderhdr a, EXPORT_TMP_FACILITY b, EXPORT_TMP_CUSTOMER c
  where a.custid = c.custid and nvl(a.fromfacility,a.tofacility) = b.facility
';
dbms_output.put_line('Orders added: ' || sql%rowcount);

execute immediate '
  insert into EXPORT_TMP_LOADS
  select distinct loadno
  from orderhdr a, EXPORT_TMP_FACILITY b, EXPORT_TMP_CUSTOMER c
  where a.custid = c.custid and nvl(a.fromfacility,a.tofacility) = b.facility
    and loadno is not null
';
dbms_output.put_line('Loads added: ' || sql%rowcount);

execute immediate '
  insert into EXPORT_TMP_POSTHDR
  select distinct invoice
  from posthdr a, EXPORT_TMP_FACILITY b, EXPORT_TMP_CUSTOMER c
  where a.custid = c.custid and a.facility = b.facility
';
dbms_output.put_line('Posthdr added: ' || sql%rowcount);
  
execute immediate '
  insert into EXPORT_TMP_CUSTWO
  select distinct seq
  from custworkorder a, EXPORT_TMP_CUSTOMER b
  where a.custid = b.custid
';
dbms_output.put_line('Cust Work Orders added: ' || sql%rowcount);

commit;

begin
  l_fty_parfile := utl_file.fopen('SYNAPSE_$$_DUMPS','exp_fac_cust_${FACILITIES}_$6.par','w',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfile open error');
  return;
end;

utl_file.put_line(l_fty_parfile, 'directory=SYNAPSE_$$_DUMPS');
utl_file.put_line(l_fty_parfile, 'dumpfile=exp_fac_cust_${FACILITIES}_$6.dmp');
utl_file.put_line(l_fty_parfile, 'logfile=exp_fac_cust_${FACILITIES}_$6.log');
utl_file.put_line(l_fty_parfile, 'exclude=statistics');
select count(1)
  into l_11g_version_count
  from v\$version
 where banner like '%11g%';
if l_11g_version_count != 0 then
  utl_file.put_line(l_fty_parfile, 'reuse_dumpfiles=y');
end if;
utl_file.put_line(l_fty_parfile, 'content=$6');
utl_file.put_line(l_fty_parfile, 'query=');

begin
  l_fty_filelist := utl_file.fopen('SYNAPSE_$$_DUMPS','parfiles_for_facility_customer$$.out','r',32767);
exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('parfiles_for_facility_customer.out open error');
  return;
end;

--dbms_output.put_line('begin parfiles_for_facility_customer processing...');
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
        
          if (l_incremental = 'N' and l_need_facility = 'Y') then
            l_facility_clause := '(facility in (select facility from export_tmp_facility) or facility is null)';
          elsif (l_need_facility = 'Y') then
            l_facility_clause := '(facility in (select facility from export_tmp_facility))';
          else
            l_facility_clause := null;
          end if;
          
          if (l_incremental = 'N' and l_need_customer = 'Y') then
            l_customer_clause := '(custid in (select custid from export_tmp_customer) or custid = ''DEFAULT'')';
          elsif (l_need_customer = 'Y') then
            l_customer_clause := '(custid in (select custid from export_tmp_customer))';
          else
            l_customer_clause := null;
          end if;
          
          if (l_incremental = 'Y') then
            l_norows_clause := 'where 1 = 0';
            l_by_custfac_clause := 'where (custid in (select custid from export_tmp_customer)) and ' ||
                                    '(facility in (select facility from export_tmp_facility))';
          else
            l_norows_clause := null;
            l_by_custfac_clause := 'where (custid = ''DEFAULT'' ' ||
                                    ' or custid in (select custid from export_tmp_customer)) and ' ||
                                    '(facility in (select facility from export_tmp_facility) or facility is null)';
          end if;
          
          if (l_need_customer = 'Y') then
            l_by_custworkorder_clause := 'where seq in (select seq from export_tmp_custwo)';
          else
            l_by_custworkorder_clause := 'where 1 = 0';
          end if;
          
          case l_txt_file_name
            when 'parfiles_for_facility_customer/by_facility_tables.txt' then
              l_query_clause := 'where ' || nvl(l_facility_clause, '1 = 0');
            when 'parfiles_for_facility_customer/by_customer_tables.txt' then
              l_query_clause := 'where ' || nvl(l_customer_clause, '1 = 0');
            when 'parfiles_for_facility_customer/by_customer_facility.txt' then
              l_query_clause := l_by_custfac_clause;
            when 'parfiles_for_facility_customer/by_loadno.txt' then
              l_query_clause := 'where loadno in (select loadno from export_tmp_loads)';
            when 'parfiles_for_facility_customer/by_custworkorder.txt' then
              l_query_clause := l_by_custworkorder_clause;
            when 'parfiles_for_facility_customer/by_posthdr.txt' then
              l_query_clause := 'where invoice in (select invoice from export_tmp_posthdr)';
            when 'parfiles_for_facility_customer/by_orderid.txt' then
              l_query_clause := 'where orderid in (select orderid from export_tmp_orders)';
            when 'parfiles_for_facility_customer/by_orderid_shipid.txt' then
              l_query_clause := 'where (orderid,shipid) in (select orderid,shipid from export_tmp_orders)';
            when 'parfiles_for_facility_customer/unconditional_tables.txt' then
              l_query_clause := l_norows_clause;
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
rm dumps/parfiles_for_facility_customer$$.out
