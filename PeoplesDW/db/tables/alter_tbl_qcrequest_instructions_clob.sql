set serveroutput on;
declare
cmdSql varchar2(4000);
curSql integer;
curIns integer;
cmdIns varchar2(10000);
curUpd integer;
cmdUpd varchar2(10000);
out_rowid varchar2(18);
out_varchar2 varchar2(4000);
cntTot integer;
cntRows integer;
begin
cntTot := 0;
zut.prt('drop temp table');
begin
  cmdSql := 'drop table qcrequest_tmp';
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);
exception when others then
  null;
end;
zut.prt('create temp table');
cmdSql := 'create table qcrequest_tmp (orig_rowid varchar2(18), orig_char_value varchar2(4000))';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);
cmdSql := 'select rowid,instructions from qcrequest' || 
          ' where instructions is not null';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql,cmdSql,dbms_sql.native);
dbms_sql.define_column(curSql,1,out_rowid,18);
dbms_sql.define_column(curSql,2,out_varchar2,4000);
cntRows := dbms_sql.execute(curSql);
while dbms_sql.fetch_rows(curSql) > 0
loop
  cntTot := cntTot + 1;
  dbms_sql.column_value(curSql,1,out_rowid);
  dbms_sql.column_value(curSql,2,out_varchar2);
  cmdIns := 'insert into qcrequest_tmp values (''' ||
   rtrim(out_rowid)  || ''',''' || rtrim(translate(out_varchar2,chr(39),chr(96))) || ''')';
  curIns := dbms_sql.open_cursor;
  dbms_sql.parse(curIns, cmdIns, dbms_sql.native);
  cntRows := dbms_sql.execute(curIns);
  dbms_sql.close_cursor(curIns);
  commit;
end loop;
dbms_sql.close_cursor(curSql);
zut.prt('Rows processed ' || cntTot);
cmdSql := 'alter table qcrequest drop column instructions';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql,cmdSql,dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
cmdSql := 'alter table qcrequest add (instructions clob)';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql,cmdSql,dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
cmdSql := 'select orig_rowid,orig_char_value from qcrequest_tmp';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql,cmdSql,dbms_sql.native);
dbms_sql.define_column(curSql,1,out_rowid,18);
dbms_sql.define_column(curSql,2,out_varchar2,4000);
cntRows := dbms_sql.execute(curSql);
cntTot := 0;
while dbms_sql.fetch_rows(curSql) > 0
loop
  cntTot := cntTot + 1;
  dbms_sql.column_value(curSql,1,out_rowid);
  dbms_sql.column_value(curSql,2,out_varchar2);
  cmdUpd := 'update qcrequest set instructions = ''' || rtrim(out_varchar2) || '''' ||
    ' where rowid = ''' || rtrim(out_rowid) || '''';
  curUpd := dbms_sql.open_cursor;
  dbms_sql.parse(curUpd, cmdUpd, dbms_sql.native);
  cntRows := dbms_sql.execute(curUpd);
  dbms_sql.close_cursor(curUpd);
  commit;
end loop;
dbms_sql.close_cursor(curSql);
zut.prt('Rows updated ' || cntTot);
zut.prt('drop temp table');
cmdSql := 'drop table qcrequest_tmp';
curSql := dbms_sql.open_cursor;
dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curSql);
dbms_sql.close_cursor(curSql);
exception when others then
  zut.prt(sqlerrm);
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  zut.prt('others...');
end;
/
exit;
