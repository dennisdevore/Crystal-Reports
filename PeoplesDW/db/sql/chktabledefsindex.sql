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
idxSql varchar2(2000);
idxCur integer;
idxName tabledefs.tableid%type;
idxCount integer;
idxRows integer;
addCur integer;
addRows integer;
addSql varchar2(2000);
cntRows integer;
cntTot integer;
cntErr integer;
cntOky integer;
qtyTot integer;
qtyErr integer;
qtyOky integer;

begin

cntTot := 0;
cntErr := 0;
cntOky := 0;
qtyTot := 0;
qtyErr := 0;
qtyOky := 0;

zut.prt('begin proc. . .');


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
      idxSql := 'select count(1) as count from user_indexes ' ||
        'where upper(table_name) = ''' || tblName || '''';
      idxCur := dbms_sql.open_cursor;
      dbms_sql.parse(idxCur, idxSql, dbms_sql.native);
      dbms_sql.define_column(idxCur,1,idxCount);
      idxRows := dbms_sql.execute(idxCur);
      idxRows := dbms_sql.fetch_rows(idxCur);
      if idxRows <= 0 then
        zut.prt('NOT found--No index for ' || tblName);
        cntErr := cntErr + 1;
      else
        dbms_sql.column_value(idxCur,1,idxCount);
        if idxCount <> 1 then
          zut.prt('Table ' || tblName || ' index count: ' || idxCount);
          cntErr := cntErr + 1;
          if Length(tblName) > 26 then
            idxName := substr(tblName,Length(tblName)-25,26);
          else
            idxName := tblName;
          end if;
          idxName := idxName || '_IDX';
          addSql := 'create unique index ' || idxName || ' on ' ||
            tblName || '(code)';
          addCur := dbms_sql.open_cursor;
          dbms_sql.parse(addCur, addSql, dbms_sql.native);
          addRows := dbms_sql.execute(addCur);
          dbms_sql.close_cursor(addCur);
        else
          cntOky := cntOky + 1;
        end if;
      end if;
    exception when others then
      zut.prt('idxCur exception');
      dbms_sql.close_cursor(idxCur);
      raise;
    end;
    dbms_sql.close_cursor(idxCur);
  end loop;
  dbms_sql.close_cursor(tblCur);
exception when no_data_found then
  zut.prt('tblCur exception');
  dbms_sql.close_cursor(tblCur);
  raise;
end;

zut.prt('total count: ' || cntTot || ' total quantity: ' || qtyTot);
zut.prt('error count: ' || cntErr || ' error quantity: ' || qtyErr);
zut.prt('okay  count: ' || cntOky || ' okay  quantity: ' || qtyOky);

zut.prt('end proc . . .');

exception when others then
  zut.prt('when others');
  zut.prt(sqlerrm);
end;
/
--exit;

