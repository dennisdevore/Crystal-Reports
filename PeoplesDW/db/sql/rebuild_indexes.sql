set serveroutput on;
set pagesize 0
set linesize 32000;
set trimspool on
spool rebuild_indexes.out;

declare
  vNumRows       integer := 0;
  vErrRows       integer := 0;
  vHeight        sys.index_stats.height%type;
  vLfRows        sys.index_stats.lf_rows%type;
  vDLfRows       sys.index_stats.del_lf_rows%type;
  vDLfPerc       number;
  vMaxHeight     number;
  vMaxDel        number;
  vSql           varchar2(4000);
  vUpdate        char(1) := 'N';
  
begin

  vMaxHeight := 3;
  vMaxDel    := 15;

  for idx in (select index_name, tablespace_name, table_name
                from user_indexes
               where not exists
                     (select 1
                        from user_queues
                       where queue_table = user_indexes.table_name)
               order by index_name
             )
  loop

    vSql := 'alter index '|| idx.index_name
       || ' rebuild tablespace ' || idx.tablespace_name;
    vNumRows := vNumRows + 1;
    zut.prt(vSql);
    if vUpdate = 'Y' then
      begin
        execute immediate vSql;
      exception when others then
        vErrRows := vErrRows + 1;
        zut.prt(sqlerrm);
      end;     
    end if;
                
  end loop;
  
  zut.prt(' ');
  zut.prt(' ');
  zut.prt('Total Indexe(s) Rebuilt .: '|| vNumRows);
  zut.prt('Total Errors ............: '|| vErrRows);
  zut.prt(' ');

end;
/
exit;
