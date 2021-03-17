create or replace package body alps.report_request as

function facility_where_clause
(in_userid     IN varchar2
,in_column_names IN varchar2 -- comma-delimited list of column names
) return varchar2

is

l_prelim_where_sql varchar2(4000);
l_final_where_sql varchar2(4000);
l_company userheader.company%type;
l_column_name user_tab_columns.column_name%type;
l_count pls_integer;
l_chgfacility userheader.chgfacility%type;
l_facility userheader.facility%type;

begin

begin
  select company, chgfacility, facility
    into l_company, l_chgfacility, l_facility
    from userheader
   where nameid = upper(in_userid);
exception when others then
  return 'INVALID_USER ' || in_userid;
end;

if l_chgfacility = 'A' and
   l_company is null then
  return null;
end if;

l_prelim_where_sql := null;

if l_company is not null then
  begin
    select chgfacility
      into l_chgfacility
      from company
     where company = l_company;
  exception when others then
    return 'INVALID_COMPANY ' || l_company;    
  end;
  if l_chgfacility = 'A' then
    return null;
  end if;
  for cf in (select facility
                from companyfacility
               where company = l_company)
  loop
    if l_prelim_where_sql is null then
      l_prelim_where_sql := ' ($column$ in (';
    else
      l_prelim_where_sql := l_prelim_where_sql || ',';
    end if;
    l_prelim_where_sql := l_prelim_where_sql || '''' || cf.facility || '''';
  end loop;             
  l_prelim_where_sql := l_prelim_where_sql || '))';
else
  if l_chgfacility = 'N' then
    l_prelim_where_sql := ' ($column$ = ''' || l_facility || ''')';
  else
    for uf in (select facility
                  from userfacility
                 where nameid  = upper(in_userid))
    loop
      if l_prelim_where_sql is null then
        l_prelim_where_sql := ' ($column$ in (';
      else
        l_prelim_where_sql := l_prelim_where_sql || ',';
      end if;
      l_prelim_where_sql := l_prelim_where_sql || '''' || uf.facility || '''';
    end loop;
    l_prelim_where_sql := l_prelim_where_sql || '))';
  end if;
end if;

l_final_where_sql := null;

/* only works in 11g+ */
-- select regexp_count(in_column_names, ',') + 1
select length(in_column_names) - length(replace(in_column_names,',',null)) + 1
  into l_count
  from dual;
  
for i in 1 .. l_count loop
  select upper(regexp_substr(in_column_names,'[^,]+', 1, i))
    into l_column_name
    from dual;        
  if l_column_name is null then
    exit;
  end if;
  if l_final_where_sql is not null then
    l_final_where_sql := l_final_where_sql || ' or ';
  end if;
  l_final_where_sql := l_final_where_sql || replace(l_prelim_where_sql, '$column$', l_column_name);
end loop;

return '(' || l_final_where_sql || ' )';

exception when others then
  return null;
end facility_where_clause;

function custid_where_clause
(in_userid     IN varchar2
,in_column_names IN varchar2 -- comma-delimited list of column names
) return varchar2

is

l_prelim_where_sql varchar2(4000);
l_final_where_sql varchar2(4000);
l_company userheader.company%type;
l_allcusts userheader.allcusts%type;
l_custid userheader.custid%type;
l_column_name user_tab_columns.column_name%type;
l_lookup_count pls_integer;
l_ordertype_count pls_integer;
l_count pls_integer;

begin

begin
  select company, allcusts, custid
    into l_company, l_allcusts, l_custid
    from userheader
   where nameid = upper(in_userid);
exception when others then
  return 'INVALID_USER ' || in_userid;
end;

if l_allcusts = 'A' and
   l_company is null then
  return null;
end if;

l_prelim_where_sql := null;

if l_company is not null then
  begin
    select allcusts
      into l_allcusts
      from company
     where company = l_company;
  exception when others then
    return 'INVALID_COMPANY ' || l_company;    
  end;
  if l_allcusts = 'A' then
    return null;
  end if;
  for cc in (select custid
                from companycustomer
               where company = l_company)
  loop
    if l_prelim_where_sql is null then
      l_prelim_where_sql := ' ($column$ in (';
    else
      l_prelim_where_sql := l_prelim_where_sql || ',';
    end if;
    l_prelim_where_sql := l_prelim_where_sql || '''' || cc.custid || '''';
  end loop;             
  l_prelim_where_sql := l_prelim_where_sql || '))';
else
  for uc in (select custid
                from usercustomer
               where nameid  = upper(in_userid))
  loop
    if l_prelim_where_sql is null then
      l_prelim_where_sql := ' ($column$ in (';
    else
      l_prelim_where_sql := l_prelim_where_sql || ',';
    end if;
    l_prelim_where_sql := l_prelim_where_sql || '''' || uc.custid || '''';
  end loop;
  l_prelim_where_sql := l_prelim_where_sql || '))';
end if;

l_final_where_sql := null;

/* only works in 11g+ */
-- select regexp_count(in_column_names, ',') + 1
select length(in_column_names) - length(replace(in_column_names,',',null)) + 1
  into l_count
  from dual;
  
for i in 1 .. l_count loop
  select upper(regexp_substr(in_column_names,'[^,]+', 1, i))
    into l_column_name
    from dual;        
  if l_column_name is null then
    exit;
  end if;
  if l_final_where_sql is not null then
    l_final_where_sql := l_final_where_sql || ' or ';
  end if;
  l_final_where_sql := l_final_where_sql || replace(l_prelim_where_sql, '$column$', l_column_name);
end loop;

return '(' || l_final_where_sql || ' )';

exception when others then
  return null;
end custid_where_clause;

function orderlookup_where_clause
(in_userid     IN varchar2
) return varchar2

is

l_data_type user_tab_columns.data_type%type;
l_prelim_where_sql varchar2(4000);
l_lookup_where_sql varchar2(4000);
l_ordertype_where_sql varchar2(4000);
l_final_where_sql varchar2(4000);
l_facility_where_sql varchar2(4000);
l_custid_where_sql varchar2(4000);
l_company userheader.company%type;
l_count pls_integer;
l_ordertype orderhdr.ordertype%type;
l_lookup_count pls_integer;
l_ordertype_count pls_integer;
l_columnvalues_count pls_integer;
l_columnvalues companyorderlookup.columnvalues%type;

begin

begin
  select company
    into l_company
    from userheader
   where nameid = upper(in_userid);
exception when others then
  return 'INVALID_USER ' || in_userid;
end;

l_lookup_count := 1;

for col in (select ordertypes, columnname, operator, columnvalues
              from companyorderlookup
             where company = l_company)
loop

  l_prelim_where_sql := ' (ordertype in (';

  /* only works in 11g+ */
  -- select regexp_count(col.ordertypes, ',') + 1
  select length(col.ordertypes) - length(replace(col.ordertypes,',',null)) + 1
    into l_count
    from dual;

  l_ordertype_count := 1;

  for i in 1 .. l_count loop
    select upper(regexp_substr(col.ordertypes,'[^,]+', 1, i))
      into l_ordertype
      from dual;        
    if l_ordertype is null then
      exit;
    end if;
    if l_ordertype_count > 1 then
      l_prelim_where_sql := l_prelim_where_sql || ',';
    end if;
    l_prelim_where_sql := l_prelim_where_sql || '''' || l_ordertype || '''';
    l_ordertype_count := l_ordertype_count + 1;
  end loop;

  l_prelim_where_sql := l_prelim_where_sql || ') and (' ||
                        trim(zcm.column_select_sql('ORDERHDR',col.columnname)) || ' ' ||
                        col.operator || ' ';

  l_ordertype_where_sql := l_prelim_where_sql;
  
  /* only works in 11g+ */
  -- select regexp_count(col.columnvalues, ',') + 1
  select length(col.columnvalues) - length(replace(col.columnvalues,',',null)) + 1
    into l_count
    from dual;

  if col.operator = 'IN' then
    l_prelim_where_sql := l_prelim_where_sql || '(';
    l_columnvalues_count := 1;
    for i in 1 .. l_count loop
      select upper(regexp_substr(col.columnvalues,'[^,]+', 1, i))
        into l_columnvalues
        from dual;        
      if l_columnvalues is null then
        exit;
      end if;
      if l_columnvalues_count > 1 then
        l_prelim_where_sql := l_prelim_where_sql || ',';
      end if;
      l_prelim_where_sql := l_prelim_where_sql || '''' ||
        trim(zcm.column_select_sql('ORDERHDR',l_columnvalues)) || '''';
      l_columnvalues_count := l_columnvalues_count + 1;
    end loop;
    l_prelim_where_sql := l_prelim_where_sql || ')))';
  else
    l_columnvalues_count := 1;
    for i in 1 .. l_count loop
      select upper(regexp_substr(col.columnvalues,'[^,]+', 1, i))
        into l_columnvalues
        from dual;        
      if l_columnvalues is null then
        exit;
      end if;
      l_prelim_where_sql := l_ordertype_where_sql || '''' ||
        trim(zcm.column_select_sql('ORDERHDR',l_columnvalues)) || '''';
      l_columnvalues_count := l_columnvalues_count + 1;
      l_prelim_where_sql := l_prelim_where_sql || '))';
      if l_lookup_count > 1 then
        l_lookup_where_sql := l_lookup_where_sql || ' or ';
      end if;
      l_lookup_where_sql := l_lookup_where_sql || l_prelim_where_sql;
      l_lookup_count := l_lookup_count + 1;
    end loop;
    goto continue_lookup_loop;
  end if;
  
  if l_lookup_count > 1 then
    l_lookup_where_sql := l_lookup_where_sql || ' or ';
  end if;
  
  l_lookup_where_sql := l_lookup_where_sql || l_prelim_where_sql;
  
  l_lookup_count := l_lookup_count + 1;

<< continue_lookup_loop >>
  null;  
end loop;             

if l_lookup_where_sql is not null then
  l_lookup_where_sql := '(' || l_lookup_where_sql || ' )';
end if;

l_final_where_sql := l_lookup_where_sql;

l_facility_where_sql := zrr.facility_where_clause(in_userid,'FROMFACILITY,TOFACILITY');
if l_facility_where_sql is not null then
  l_final_where_sql := l_final_where_sql || ' and ' || l_facility_where_sql;
end if;

l_custid_where_sql := zrr.custid_where_clause(in_userid,'CUSTID');
if l_custid_where_sql is not null then
  l_final_where_sql := l_final_where_sql || ' and ' || l_custid_where_sql;
end if;

return l_final_where_sql;

exception when others then
  return null;
end orderlookup_where_clause;

end report_request;
/
show error package body report_request;
exit;
