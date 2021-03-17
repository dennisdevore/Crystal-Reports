--
-- $Id$
--
set serveroutput on;

declare

out_msg varchar2(255);
out_errorno integer;
tblSql varchar2(2000);
tblCur integer;
tblName tabledefs.tableid%type;
tblRows integer;
usrSql varchar2(2000);
usrCur integer;
usrName tabledefs.tableid%type;
usrCount integer;
usrRows integer;
updCur integer;
updRows integer;
updSql varchar2(2000);
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;
updflag char(1);
l_index_name varchar2(35);
l_new_index_name varchar2(35);
l_constraint_name varchar2(37);
l_new_constraint_name varchar2(37);
l_sqlcmd varchar2(2000);

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

updflag := upper('&1');
zut.prt('begin compare tableid to objects...');

begin
  tblSql := 'select upper(tableid) as tableid ' ||
    'from tabledefs order by tableid';
  tblCur := dbms_sql.open_cursor;
  dbms_sql.parse(tblCur, tblSql, dbms_sql.native);
  dbms_sql.define_column(tblCur,1,tblName,32);
  tblRows := dbms_sql.execute(tblCur);
  while(1=1)
  loop
    tblRows := dbms_sql.fetch_rows(tblCur);
    if tblRows <= 0 then
      Exit;
    end if;
    cntTot := cntTot + 1;
    dbms_sql.column_value(tblCur,1,tblName);
    begin
      usrSql := 'select count(1) as count from user_tables ' ||
        'where upper(table_name) = ''' || tblName || '''';
      usrCur := dbms_sql.open_cursor;
      dbms_sql.parse(usrCur, usrSql, dbms_sql.native);
      dbms_sql.define_column(usrCur,1,usrCount);
      usrRows := dbms_sql.execute(usrCur);
      usrRows := dbms_sql.fetch_rows(usrCur);
      if usrRows > 0 then
        dbms_sql.column_value(usrCur,1,usrCount);
      end if;
      if (usrRows <= 0) or (usrCount = 0) then
        zut.prt('NOT found--No table for ' || tblName);
        cntErr := cntErr + 1;
        if updflag = 'Y' then
          begin
            updCur := dbms_sql.open_cursor;
            dbms_sql.parse(updCur, 'delete from tabledefs where ' ||
              'upper(tableid) = ''' || tblname || '''', dbms_sql.native);
            updRows := dbms_sql.execute(updCur);
            zut.prt(tblname || ' ' || to_char(updRows) || ' rows updated');
            dbms_sql.close_cursor(updCur);
          exception when NO_DATA_FOUND then
            dbms_sql.close_cursor(updCur);
            zut.prt(tblname + ' --unable to delete');
            raise;
          end;
        end if;
      else
        cntOky := cntOky + 1;
        for nul in (select column_name
                      from user_tab_columns
                     where table_name = tblName
                       and column_name in ('CODE','DESCR','ABBREV')
                       and nullable = 'Y')
        loop
          execute immediate 'alter table ' || tblName || ' modify ' || nul.column_name ||
            ' not null';
        end loop;
        l_new_constraint_name := 'PK_' || rtrim(substr(tblName,1,27));
        l_new_index_name := tblName || '_IDX';
        while (length(trim(l_new_index_name))) > 30
        loop
          l_new_index_name := substr(l_new_index_name,2,50);
        end loop;
        begin
          select constraint_name
            into l_constraint_name
            from user_constraints
           where table_name = tblName
             and constraint_type = 'P';
        exception when others then
          l_constraint_name := null;
        end;
        if substr(l_constraint_name,1,4) = 'SYS_' then
          l_sqlcmd := 'alter table ' || tblName || ' drop constraint ' ||
             l_constraint_name;
          zut.prt(l_sqlcmd);
          execute immediate l_sqlcmd;
          l_constraint_name := null;
        end if;
        begin
          select index_name
            into l_index_name
            from user_indexes
           where table_name = tblName
             and uniqueness = 'UNIQUE';
        exception when no_data_found then
          l_index_name := null;
        end;
        if l_index_name is null then
          l_sqlcmd := 'create unique index ' || l_new_index_name ||
            ' on ' || tblName || '(code)';
          zut.prt(l_sqlcmd);
          if updflag = 'Y' then
            execute immediate l_sqlcmd;
          end if;
        end if;
        if l_constraint_name is null then
          l_sqlcmd := 'alter table ' || tblName || ' add constraint ' ||
             l_new_constraint_name || ' primary key (code)';
          if l_index_name is not null then
            l_sqlcmd := l_sqlcmd || ' using index ' || l_index_name;
          end if;
          cntErr := cntErr + 1;
          zut.prt(l_sqlcmd);
          if updflag = 'Y' then
            begin
              execute immediate l_sqlcmd;
            exception when others then
              zut.prt('pk alter exception');
              zut.prt(sqlerrm);
            end;
          end if;
        elsif l_constraint_name != 'PK_' || rtrim(substr(tblName,1,27)) then
          l_sqlcmd := 'alter constraint ' || l_constraint_name || ' rename to ' || l_new_constraint_name;
          zut.prt(l_sqlcmd);
          if updflag = 'Y' then
            execute immediate l_sqlcmd;
          end if;
        end if;
        if l_index_name != l_new_index_name then
          cntErr := cntErr + 1;
          l_sqlcmd := 'alter index ' || l_index_name || ' rename to ' || l_new_index_name;
          zut.prt(l_sqlcmd);
          if updflag = 'Y' then
            execute immediate l_sqlcmd;
          end if;
        end if;
      end if;
    exception when others then
      zut.prt(tblname || ' usrCur exception');
      dbms_sql.close_cursor(usrCur);
      raise;
    end;
    dbms_sql.close_cursor(usrCur);
  end loop;
  dbms_sql.close_cursor(tblCur);
exception when no_data_found then
  zut.prt(tblname || ' tblCur exception');
  dbms_sql.close_cursor(tblCur);
  raise;
end;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('begin compare objects to tableid...');

begin
  tblSql := 'select upper(table_name) ' ||
    'from user_tab_columns utc1 where column_name = ''DTLUPDATE''' ||
    ' and table_name != ''TABLEDEFS'' and table_name not like ''BIN$%''' ||
    ' and table_name != ''BUSINESSEVENTS''' ||
    ' and not exists (select 1 from user_tab_columns utc2 where ' ||
    ' utc1.table_name = utc2.table_name and utc2.column_name = ''ORA_ROWSCN'')' ||
    ' order by table_name';
  tblCur := dbms_sql.open_cursor;
  dbms_sql.parse(tblCur, tblSql, dbms_sql.native);
  dbms_sql.define_column(tblCur,1,tblName,32);
  tblRows := dbms_sql.execute(tblCur);
  while(1=1)
  loop
    tblRows := dbms_sql.fetch_rows(tblCur);
    if tblRows <= 0 then
      Exit;
    end if;
    cntTot := cntTot + 1;
    dbms_sql.column_value(tblCur,1,tblName);
    begin
      usrSql := 'select count(1) as count from tabledefs ' ||
        'where upper(tableid) = ''' || tblName || '''';
      usrCur := dbms_sql.open_cursor;
      dbms_sql.parse(usrCur, usrSql, dbms_sql.native);
      dbms_sql.define_column(usrCur,1,usrCount);
      usrRows := dbms_sql.execute(usrCur);
      usrRows := dbms_sql.fetch_rows(usrCur);
      if usrRows > 0 then
        dbms_sql.column_value(usrCur,1,usrCount);
      end if;
      if (usrRows <= 0) or (usrCount = 0) then
        zut.prt('NOT found--No tabledef for ' || tblName);
        cntErr := cntErr + 1;
        if updflag = 'Y' then
          begin
            updCur := dbms_sql.open_cursor;
            dbms_sql.parse(updCur, 'insert into tabledefs values (' ||
              '''' || tblname || ''',' ||
              '''' || 'N' || ''',' ||
              '''' || 'N' || ''',' ||
              '''' || '>Aaaaaaaaaaaa;0;_' || ''',' ||
              '''' || 'SYNAPSE' || ''',' ||
              'sysdate' ||
              ')',
              dbms_sql.native);
            updRows := dbms_sql.execute(updCur);
            zut.prt(tblname || ' ' || to_char(updRows) || ' rows inserted');
            dbms_sql.close_cursor(updCur);
          exception when NO_DATA_FOUND then
            dbms_sql.close_cursor(updCur);
            zut.prt(tblname + ' --unable to delete');
            raise;
          end;
        end if;
      else
        cntOky := cntOky + 1;
      end if;
    exception when others then
      zut.prt(tblname || ' usrCur exception');
      dbms_sql.close_cursor(usrCur);
      raise;
    end;
    dbms_sql.close_cursor(usrCur);
  end loop;
  dbms_sql.close_cursor(tblCur);
exception when no_data_found then
  zut.prt('tblCur exception');
  dbms_sql.close_cursor(tblCur);
  raise;
end;

if updflag = 'Y' then
  commit;
end if;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end proc . . .');

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
update tabledefs
   set codemask = '>Aaaaaaaaaaaa;0;_'
 where tableid like 'EDI_%'
   and codemask != '>Aaaaaaaaaaaa;0;_';

exit;

