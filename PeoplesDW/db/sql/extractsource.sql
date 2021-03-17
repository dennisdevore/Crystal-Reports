--
-- $Id$
--
set serveroutput on;

declare
ftySource utl_file.file_type;
strFileName varchar2(255);
strPrevName user_source.name%type;
strPrevType user_source.type%type;

cursor curSource is
  select *
    from user_source
   order by name,type,line;

begin

ftySource := null;
strPrevName := 'x';
strPrevType := 'x';

dbms_output.enable(1000000);

for src in curSource
loop
  if (src.Name <> strPrevName) or
     (src.Type <> strPrevType) then
    if utl_file.is_open(ftySource) then
      utl_file.put_line(ftySource, 'exit;');
      utl_file.fclose(ftySource);
    end if;
    strPrevName := src.Name;
    strPrevType := src.Type;
    strFileName := lower(src.Name || ' ' || src.Type || '.sql');
    ftySource := utl_file.fopen('c:\zethcon\ohl\sql\extract\',strFileName,'w');
    utl_file.put_line(ftySource, 'create or replace ');
  end if;
  utl_file.put_line(ftySource, src.Text);
end loop;

if utl_file.is_open(ftySource) then
  utl_file.put_line(ftySource, 'exit;');
  utl_file.fclose(ftySource);
end if;

dbms_output.put_line('finished');

exception when others then
  dbms_output.put_line(sqlerrm);
  dbms_output.put_line('others....');
end;
/
--exit;
