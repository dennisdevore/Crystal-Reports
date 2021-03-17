create or replace package body alps.zutility
is
--
-- $Id$
--

function data_type(in_table_name varchar2, in_column_name varchar2)
return varchar2

is

l_data_type user_tab_columns.data_type%type;

begin

l_data_type := '?';

select data_type
  into l_data_type
  from user_tab_columns
 where table_name = in_table_name
   and column_name = in_column_name;
   
return l_data_type;

exception when others then
  return '?';
end;

procedure prt(in_text in varchar2 := null)
is

datestr varchar2(17);

begin

  select to_char(sysdate, 'mm/dd/yy hh24:mi:ss')
    into datestr
    from dual;
  dbms_output.put_line(datestr || ' ' || in_text);

end prt;

procedure show_index(in_table_name varchar2)
is

cursor c1 is
  select index_name,uniqueness,index_type from user_indexes
   where table_name = upper(in_table_name)
   order by index_name;

cursor c2(in_index_name in varchar2) is
   select I.column_name, T.nullable
     from user_tab_columns T, user_ind_columns I
    where I.index_name = in_index_name
      and T.table_name = I.table_name
      and T.column_name = I.column_name
    order by I.column_position;

strNullable varchar2(25);

begin

 zut.prt('table: '||in_table_name);
 for c1rec in c1 loop
   zut.prt(   '.   index: '||c1rec.index_name||' '||c1rec.uniqueness||' '||c1rec.index_type);
   for c2rec in c2(c1rec.index_name) loop
     if c2rec.nullable = 'Y' then
       strNullable := ' (nullable)';
     else
       strNullable := null;
     end if;
     zut.prt('.     col: '||c2rec.column_name || strNullable);
   end loop;
   zut.prt('=======================');
 end loop;

end show_index;


procedure drop_index(in_table_name varchar2)
is

cursor tblcur is
  select index_name
    from user_indexes
   where table_name = upper(in_table_name)   order by table_name;

sqlcur integer;
sqlcount integer;

begin

show_index(in_table_name);

for tbl in tblcur
loop
  sqlcur := dbms_sql.open_cursor;
  dbms_sql.parse(sqlcur, 'drop index ' || tbl.index_name, dbms_sql.native);
  zut.prt('Dropping ' || tbl.index_name || '. . .');
  sqlcount := dbms_sql.execute(sqlcur);
  dbms_sql.close_cursor(sqlcur);
end loop;

zut.prt('Index drop complete');

exception when others then
  zut.prt('Drop index exception' || sqlerrm);
end drop_index;

procedure show_constraints(in_table_name varchar2)
is

cursor c1 is
  select *
    from user_constraints
   where table_name = upper(in_table_name)
   order by constraint_type,constraint_name;

cursor c2(in_index_name in varchar2) is
   select I.column_name, T.nullable
     from user_tab_columns T, user_ind_columns I
    where I.index_name = in_index_name
      and T.table_name = I.table_name
      and T.column_name = I.column_name
    order by I.column_position;

strNullable varchar2(25);
strReferenceTableName user_tables.table_name%type;
cntTot integer;

begin

 cntTot := 0;

 zut.prt('Constraints for table: ' || in_table_name);
 for con in c1 loop
   zut.prt('.  ' || con.constraint_type || '-' || con.constraint_name);
   if con.index_name is not null then
     zut.prt('.    ' || '(Index: ' || con.index_name || ')');
   end if;
   zut.prt('.    ' || '(' ||
           con.status || '/' || con.deferrable || '/' || con.deferred || '/' ||
           con.validated || ')');
   if con.constraint_type = 'C' then
     zut.prt('.    ' || rtrim(to_char(con.search_condition)));
   end if;
   if con.constraint_type in ('P','U','R') then
     for cols in (select column_name,position
                    from user_cons_columns
                   where owner = con.owner
                     and constraint_name = con.constraint_name
                     and table_name = con.table_name
                   order by position)
     loop
       zut.prt('.      ' || cols.position || ' ' || cols.column_name);
     end loop;
   end if;
   if con.constraint_type = 'R' then
     strReferenceTableName := 'unknown';
     begin
       select table_name
         into strReferenceTableName
         from user_constraints
        where owner = con.r_owner
          and constraint_name = con.r_constraint_name;
     exception when others then
       null;
     end;
     zut.prt('.      References: ' || strReferenceTableName || ' (' || con.r_constraint_name || ')');
     for cols in (select column_name,position
                    from user_cons_columns
                   where owner = con.r_owner
                     and constraint_name = con.r_constraint_name
                     and table_name = strReferenceTableName
                   order by position)
     loop
       zut.prt('.      ' || cols.position || ' ' || cols.column_name);
     end loop;
   end if;
 end loop;

end show_constraints;

function is_active_customer(in_custid IN varchar2)
return char
is

l_rows pls_integer;

begin

l_rows := 0;

select count(1)
  into l_rows
  from customer
 where custid = in_custid
   and status = 'ACTV';

if l_rows = 0 then
  return 'N';
else
  return 'Y';
end if;

exception when others then
  return 'N';
end;

function is_active_facility(in_facility IN varchar2)
return char
is

l_rows pls_integer;

begin

l_rows := 0;

select count(1)
  into l_rows
  from facility
 where facility = in_facility
   and facilitystatus = 'A';

if l_rows = 0 then
  return 'N';
else
  return 'Y';
end if;

exception when others then
  return 'N';
end;

function is_purgable(in_loadno int, in_orderid int, in_shipid int, in_lastupdate date)
return char
is

l_rows integer;
l_loadstatus loads.loadstatus%type;
l_loadstatusupdate loads.statusupdate%type;
l_orderstatus orderhdr.orderstatus%type;
l_orderhdrstatusupdate orderhdr.statusupdate%type;
l_orderhdrcustid orderhdr.custid%type;
l_date_to_check date;

begin

l_date_to_check := in_lastupdate;

if nvl(in_loadno,0) != 0 then
  begin
    select loadstatus, statusupdate
      into l_loadstatus, l_loadstatusupdate
      from loads
     where loadno = in_loadno;
  exception when no_data_found then
    l_loadstatus := '9';
  end;
  if l_loadstatus < '9' or
     l_loadstatus in ('A','E') then
    return 'N';
  end if;
  if l_date_to_check is null then
    l_date_to_check := l_loadstatusupdate;
  end if;
end if;

if nvl(in_orderid,0) != 0 then
  begin
    select orderstatus, statusupdate, custid
      into l_orderstatus, l_orderhdrstatusupdate, l_orderhdrcustid
      from orderhdr
     where orderid = in_orderid
       and shipid = in_shipid;
  exception when no_data_found then
    l_orderstatus := '9';
  end;
  if l_orderstatus < '9' or
     l_orderstatus = 'A' then
    return 'N';
  end if;
  if is_active_customer(l_orderhdrcustid) = 'N' then
    return 'Y';
  end if;
  if l_date_to_check is null then
    l_date_to_check := l_orderhdrstatusupdate;
  end if;
end if;

if l_date_to_check < (sysdate - 92) then
  return 'Y';
end if;

return 'N';

end;

function custid_in_object_name(in_object_name varchar2)
return varchar2

is

l_custid varchar2(255);
l_object_name varchar2(255);
l_substring varchar2(255);
l_begpos pls_integer;
l_rows pls_integer;

begin

l_custid := null;
l_object_name := upper(in_object_name);

while length(trim(l_object_name)) > 0
loop
  l_begpos := instr(l_object_name, '_');
  if l_begpos != 0 then
    l_substring := substr(l_object_name,1,l_begpos-1);
    l_object_name := substr(l_object_name,l_begpos+1,255);
  else
    l_substring := l_object_name;
    l_object_name := '';
  end if;
  select count(1)
    into l_rows
    from customer
   where custid = l_substring;
  if l_rows != 0 then
    return l_substring;
  end if;
end loop;

return null;

end;

PROCEDURE check_data_file_usage
IS
l_subject varchar2(255);
l_message varchar2(4000);
l_db_name varchar2(255);
l_host varchar2(255);
l_below_tolerance pls_integer;
l_above_tolerance pls_integer;
begin

    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Begin Check Data File Usage',
            'I', 'DAILYJOB', l_message);
    select sys_context('USERENV','DB_NAME')
      into l_db_name
      from dual;
    select sys_context('USERENV','HOST')
      into l_host
      from dual;
    for ts in (select distinct tablespace_name tablespace_name
                 from dba_data_files)
    loop
      l_below_tolerance := 0;
      l_above_tolerance := 0;
      for df in (select file_name,
                        decode(maxbytes,0,0,bytes/maxbytes*100) percent_used
                   from dba_data_files
                  where tablespace_name = ts.tablespace_name
                  order by file_name)
      loop
        if df.percent_used < 90 then
          l_below_tolerance := l_below_tolerance + 1;
        else
          l_above_tolerance := l_above_tolerance + 1;
        end if;
      end loop;
      if l_below_tolerance != 0 then
        goto continue_ts;
      end if;
      l_subject := 'Host: ' || l_host || ' Instance: ' || l_db_name ||
                   '  Data File Usage above 90% ';
      l_message := 'The data file usage for tablespace ' || ts.tablespace_name ||
               ' is above 90 percent: ' || chr(13) || chr(13);
      for df in (select file_name,
                        bytes/1024/1024/1024 as sizegb,
                        maxbytes/1024/1024/1024 as maxgb,
                        decode(maxbytes,0,0,bytes/maxbytes*100) percent_used
                   from dba_data_files
                  where tablespace_name = ts.tablespace_name
                  order by file_name)
      loop
        l_message := l_message || df.file_name ||
                 '  Size: ' || to_char(df.sizegb,'FM999.00') || 'G ' ||
                 '  Max: ' || to_char(df.maxgb,'FM999.00') || 'G ' ||
                 '  Used: ' || to_char(df.percent_used,'FM999.00') || '%' ||
                 chr(13);
      end loop;
      zsmtp.send_mail('monitor@zethcon.com', 'monitorall@zethcon.com',null,null,
                      l_subject, l_message);
    << continue_ts >>
      null;
    end loop;
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'End Check Data File Usage',
            'I', 'DAILYJOB', l_message);
EXCEPTION WHEN OTHERS THEN
  begin
    zms.log_autonomous_msg('DAILYJOB', null, null,
            'Check Data Files Usage: '||sqlerrm,
            'E', 'DAILYJOB', l_message);
  exception when others then
    null;
  end;
END check_data_file_usage;
begin
  dbms_output.enable(1000000);

end zutility;

/
show error package body zutility;
exit;

