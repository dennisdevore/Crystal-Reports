set serveroutput on size 1000000

declare
  v_block_size number;
begin

  select to_number(value) into v_block_size
  from v$parameter
  where name = 'db_block_size';

  for rec in (
    select 'alter database datafile '''||file_name||''' resize ' ||
       ceil( (nvl(hwm,1)*v_block_size)/1024/1024 + 20) || 'm' cmd
    from dba_data_files a,
     ( select file_id, max(block_id+blocks-1) hwm
         from dba_extents
        group by file_id ) b
    where a.file_id = b.file_id(+)
      and lower(tablespace_name) like '%users%'
      and ceil( blocks*v_block_size/1024/1024) -
      ceil( (nvl(hwm,1)*v_block_size)/1024/1024 ) > 0)
  loop

    dbms_output.put_line(rec.cmd);
    execute immediate rec.cmd;
  end loop;

end;
/
exit;
