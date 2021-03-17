set serveroutput on;
set pagesize 0
set linesize 32000;
set trimspool on
spool examine_indexes.out;

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
            order by index_name
                 and not exists
                     (select 1
                        from user_queues
                       where queue_table = user_indexes.table_name))
  loop

    vSql := 'analyze index ' || idx.index_name ||
            ' validate structure';
    zut.prt(vSql);
    
    execute immediate vSql;
    
    select height, lf_rows, del_lf_rows
      into vHeight, vLfRows, vDLfRows
      from index_stats;

    if vLfRows = 0 then
      vDLfPerc := 0;
    else
      vDLfPerc := (vDLfRows / vLfRows) * 100;
    end if;    
     
    zut.prt(idx.index_name || ' Height ' || vHeight ||
                              ' Leaf % ' || vDLfPerc);
    if (vHeight > vMaxHeight) or (vDLfPerc > vMaxDel) then    
      begin
        vNumRows := vNumRows + 1;
        vSql := 'alter index '|| idx.index_name
            || ' rebuild tablespace ' || idx.tablespace_name;
        zut.prt(vNumRows || ' ' || vSql);  
        if vUpdate = 'Y' then
          execute immediate vSql;
        end if;
      exception when others then
        vErrRows := vErrRows + 1;
        zut.prt(sqlerrm);
      end;     
    end if;
                
  end loop;
  
  zut.prt(' ');
  zut.prt(' ');
  zut.prt('The index analysis and rebuilding process has completed!');
  zut.prt(' ');
  zut.prt('Total Indexe(s) Rebuilt .: '|| vNumRows);
  zut.prt('Total Errors ............: '|| vErrRows);
  zut.prt(' ');

end;
/
exit;
