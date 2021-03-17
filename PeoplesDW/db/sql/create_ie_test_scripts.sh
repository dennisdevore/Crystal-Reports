#!/bin/bash

IAM=`basename $0`

case $# in
1) ;;
*) echo "\nusage: $IAM <export_format_name>"
   exit ;;
esac

SYN_FORMAT=`echo ${1} | tr ' ' '_'`
SYN_UPPER=`echo ${1} | tr 'a-z' 'A-Z'`

cat >/tmp/$IAM_begin.$$.sql <<EOF
set serveroutput on format wrapped
set feedback off
set heading off
set verify off
set echo off
set term off
set pagesize 0
set trimspool on
spool begin_$SYN_FORMAT.sql

declare

cursor curArguments(in_object_name varchar2) is
  select package_name,
         argument_name,
         data_type,
         in_out
    from user_arguments
   where object_name = upper(in_object_name)
   order by position;

cursor curFormat is
  select name,
         beforeprocessproc,
         upper(beforeprocessprocparams) || chr(13) beforeprocessprocparams
    from impexp_definitions
   where upper(name) = '${SYN_UPPER}';
fmt curFormat%rowtype;
   
l_text varchar2(4000);
l_package_name user_arguments.package_name%type;
l_col_total pls_integer;
l_col_count pls_integer;
l_object_name user_arguments.object_name%type;
l_pos pls_integer;
l_len pls_integer;
l_params impexp_definitions.beforeprocessprocparams%type;
l_param impexp_definitions.beforeprocessprocparams%type;

begin

fmt := null;
open curFormat;
fetch curFormat into fmt;
close curFormat;

if fmt.name is null then
  dbms_output.put_line('Format not found');
  return;
end if;

l_object_name := fmt.beforeprocessproc;

dbms_output.enable(1000000);

dbms_output.put_line('set serveroutput on');
dbms_output.put_line('');
dbms_output.put_line('declare');

l_col_count := 0;
l_col_total := 0;

for x in curArguments(l_object_name)
loop
  l_text := x.argument_name || ' ';
  if x.data_type in ('VARCHAR2','CHAR') then
    l_text := l_text || 'varchar2(255);';
  else
    l_text := l_text || 'number;';
  end if;
  dbms_output.put_line(l_text);
  l_col_total := l_col_total + 1;
end loop;

dbms_output.put_line('l_cmd varchar2(4000);');
dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');

l_col_count := 0;
l_package_name := null;

for x in curArguments(l_object_name)
loop
  l_pos := instr(fmt.beforeprocessprocparams,x.argument_name);
  if l_pos = 0 then
    l_text := x.argument_name || ' := null;';
  else
    l_len := length(x.argument_name);
    l_params := substr(fmt.beforeprocessprocparams,l_pos+l_len+1,1000);
    l_param := 'null';
    l_pos := instr(l_params,chr(13));
    if l_pos <> 1 then
      if x.data_type in ('VARCHAR2','CHAR') then
        l_param := '''';
      else
        l_param := null;
      end if;
      l_param := l_param || substr(l_params,1,l_pos-1);
      if x.data_type in ('VARCHAR2','CHAR') then
        l_param := l_param || '''';
      end if;
    end if;
    if substr(l_param,3,1000) in ('CUSTPARM''', 'LASTDATE''', 'BEGDATE''', 'ROWID''') then
      l_param := '''''';
    elsif substr(l_param,3,1000) in ('VIEWNUM''') then
      l_param := '1';
    elsif substr(l_param,2,1000) in ('LOADPARM','ORDERPARM','SHIPPARM') then
      l_param := '0';
    end if;
    l_text := x.argument_name || ' := ' || l_param || ';';
  end if;
  if l_package_name is null then
    l_package_name := x.package_name;
  end if;
  dbms_output.put_line(l_text);
end loop;

dbms_output.put_line('');
dbms_output.put_line('out_errorno := -12345;');
dbms_output.put_line('');

dbms_output.put_line('zut.prt(''execute ' || l_object_name || ''');');
dbms_output.put_line('');

l_text := l_package_name || '.' || l_object_name || '(';
dbms_output.put_line(l_text);

l_col_count := 0;

for x in curArguments(l_object_name)
loop
  if (l_col_count > 0) and
     (l_col_count <> l_col_total) then
    dbms_output.put_line(',');
  end if;
  l_col_count := l_col_count + 1;
  l_text := x.argument_name;
  dbms_output.put(l_text);
  if (l_col_count = l_col_total) then
    dbms_output.put_line(');');
  end if;
end loop;

dbms_output.put_line('');

for x in curArguments(l_object_name)
loop
  if instr(x.in_out,'OUT') <> 0 then
    l_text := 'zut.prt(''' || 
               x.argument_name || ' is >'' || ' || 
               x.argument_name || ' || ''<'');';          
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line('');

dbms_output.put_line('exception when others then');
dbms_output.put_line('  dbms_output.put_line(''others...'');');
dbms_output.put_line('  dbms_output.put_line(sqlerrm);');
dbms_output.put_line('end;');
dbms_output.put_line('/');
dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
exit;
EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM_begin.$$.sql
rm /tmp/$IAM_begin.$$.sql
cat >/tmp/$IAM_end.$$.sql <<EOF
set serveroutput on format wrapped
set feedback off
set heading off
set verify off
set echo off
set term off
set pagesize 0
set trimspool on
spool end_$SYN_FORMAT.sql

declare

cursor curArguments(in_object_name varchar2) is
  select package_name,
         argument_name,
         data_type,
         in_out
    from user_arguments
   where object_name = upper(in_object_name)
   order by position;

cursor curFormat is
  select name,
         afterprocessproc,
         upper(afterprocessprocparams) || chr(13) afterprocessprocparams
    from impexp_definitions
   where upper(name) = '${SYN_UPPER}';
fmt curFormat%rowtype;
   
l_text varchar2(4000);
l_package_name user_arguments.package_name%type;
l_col_total pls_integer;
l_col_count pls_integer;
l_object_name user_arguments.object_name%type;
l_pos pls_integer;
l_len pls_integer;
l_params impexp_definitions.afterprocessprocparams%type;
l_param impexp_definitions.afterprocessprocparams%type;

begin

fmt := null;
open curFormat;
fetch curFormat into fmt;
close curFormat;

if fmt.name is null then
  dbms_output.put_line('Format not found');
  return;
end if;

l_object_name := fmt.afterprocessproc;

dbms_output.enable(1000000);

dbms_output.put_line('set serveroutput on');
dbms_output.put_line('');
dbms_output.put_line('declare');

l_col_count := 0;
l_col_total := 0;

for x in curArguments(l_object_name)
loop
  l_text := x.argument_name || ' ';
  if x.data_type in ('VARCHAR2','CHAR') then
    l_text := l_text || 'varchar2(255);';
  else
    l_text := l_text || 'number;';
  end if;
  dbms_output.put_line(l_text);
  l_col_total := l_col_total + 1;
end loop;

dbms_output.put_line('l_cmd varchar2(4000);');
dbms_output.put_line('');
dbms_output.put_line('begin');
dbms_output.put_line('');

l_col_count := 0;
l_package_name := null;

for x in curArguments(l_object_name)
loop
  l_pos := instr(fmt.afterprocessprocparams,upper(x.argument_name));
  if l_pos = 0 then
    l_text := x.argument_name || ' := null;';
  else
    l_len := length(x.argument_name);
    l_params := substr(fmt.afterprocessprocparams,l_pos+l_len+1,1000);
    l_param := 'null';
    l_pos := instr(l_params,chr(13));
    if l_pos <> 1 then
      if x.data_type in ('VARCHAR2','CHAR') then
        l_param := '''';
      else
        l_param := null;
      end if;
      l_param := l_param || substr(l_params,1,l_pos-1);
      if x.data_type in ('VARCHAR2','CHAR') then
        l_param := l_param || '''';
      end if;
    end if;
    if substr(l_param,3,1000) in ('CUSTPARM''', 'LASTDATE''', 'BEGDATE''', 'ROWID''') then
      l_param := '''''';
    elsif substr(l_param,3,1000) in ('VIEWNUM''') then
      l_param := '1';
    elsif substr(l_param,2,1000) in ('LOADPARM','ORDERPARM','SHIPPARM') then
      l_param := '0';
    end if;
    l_text := x.argument_name || ' := ' || l_param || ';';
  end if;
  if l_package_name is null then
    l_package_name := x.package_name;
  end if;
  dbms_output.put_line(l_text);
end loop;

dbms_output.put_line('');
dbms_output.put_line('out_errorno := -12345;');
dbms_output.put_line('');

dbms_output.put_line('zut.prt(''execute ' || l_object_name || ''');');
dbms_output.put_line('');

l_text := l_package_name || '.' || l_object_name || '(';
dbms_output.put_line(l_text);

l_col_count := 0;

for x in curArguments(l_object_name)
loop
  if (l_col_count > 0) and
     (l_col_count <> l_col_total) then
    dbms_output.put_line(',');
  end if;
  l_col_count := l_col_count + 1;
  l_text := x.argument_name;
  dbms_output.put(l_text);
  if (l_col_count = l_col_total) then
    dbms_output.put_line(');');
  end if;
end loop;

dbms_output.put_line('');

for x in curArguments(l_object_name)
loop
  if instr(x.in_out,'OUT') <> 0 then
    l_text := 'zut.prt(''' || 
               x.argument_name || ' is >'' || ' || 
               x.argument_name || ' || ''<'');';          
    dbms_output.put_line(l_text);
  end if;
end loop;

dbms_output.put_line('');

dbms_output.put_line('exception when others then');
dbms_output.put_line('  dbms_output.put_line(''others...'');');
dbms_output.put_line('  dbms_output.put_line(sqlerrm);');
dbms_output.put_line('end;');
dbms_output.put_line('/');
dbms_output.put_line('exit;');

exception when others then
  dbms_output.put_line('others');
  dbms_output.put_line(sqlerrm);
end;
/
exit;

EOF
sqlplus -S ${ALPS_DBLOGON} @/tmp/$IAM_end.$$.sql
rm /tmp/$IAM_end.$$.sql
