create or replace package body  alps.zarchive
as
--
-- $Id$
--

---------------------------------------------------------------------------------------------------------------------------------
-- Compares ALPS.<TABLENAME> to ARC.<TABLENAME> and returns Y if both structures are the same or N if there is any difference. --
---------------------------------------------------------------------------------------------------------------------------------
function compareArchiveTable
(in_tablename IN varchar2)
return char is

cntBoth integer;
cntAlps integer;

begin

select count(distinct a.column_name)
  into cntBoth
  from all_tab_columns a, all_tab_columns b
 where a.table_name = in_tablename
   and a.owner = 'ALPS'
   and b.table_name = in_tablename
   and b.owner = 'ARC'
   and a.column_name = b.column_name
   and a.data_type = b.data_type
   and nvl(a.nullable,'N') = nvl(b.nullable,'N')
   and nvl(a.data_length,0) = nvl(b.data_length,0)
   and nvl(a.data_precision,0) = nvl(b.data_precision,0)
   and nvl(a.data_scale,0) = nvl(b.data_scale,0);

select count(column_name)
  into cntAlps from all_tab_columns
 where table_name = in_tablename
   and owner = 'ALPS';

if (cntAlps = cntBoth) and
   (cntAlps != 0) then
  return 'Y';
else
  return 'N';
end if;

exception when others then
  return 'N';
end compareArchiveTable;

-------------------------------------------------------------------------
-- Given an ALPS tablename creates an identical table in the ARC user. --
-------------------------------------------------------------------------

procedure creatArchiveTable
(in_tablename IN varchar2,
out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)  is


curFunc integer;
keyFunction integer;
insDelFunction integer;
cntRows integer;
cmdSql varchar2(32766);

cursor curColumns(theTable varchar2) is
  select *
    from user_tab_columns
   where table_name = theTable
   order by column_id;

strPrevTableName varchar2(255);
strColumnName varchar2(255);
strDataType varchar2(255);
strNullClause varchar2(255);

strUser char(4);



firstField boolean;

begin


strUser := 'ARC.';

-----------------------------
-- drop the existing table --
-----------------------------

begin
  cmdSql := 'drop table ' || strUser || ltrim(in_tablename);

  curFunc := dbms_sql.open_cursor;
  dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curFunc);
  dbms_sql.close_cursor(curFunc);
exception when others then
  out_errorno := 0; -- the table probably didn't exist, so just continue
end;

cmdSql := 'create table ' || strUser || ltrim(in_tablename) || '( ';

firstField := true;

for x in curColumns(in_tablename) loop

  strColumnName := x.column_name;
  strDataType   := x.data_type;

  if x.data_type in ('NUMBER') then
    strDataType := strDataType || '(' || x.data_precision;
    if x.data_scale <> 0 then
      strDataType := strDataType || ',' || x.data_scale;
    end if;
    strDataType := strDataType || ')';
  end if;

  if x.data_type in ('CHAR','VARCHAR2') then
    strDataType := strDataType || '(' || x.data_length;
    strDataType := strDataType || ')';
  end if;

  if x.nullable = 'N' then
    strNullClause := 'not null';
  else
    strNullClause := null;
  end if;

  if firstField then
    firstField := false;
  else
    strColumnName := ',' || strColumnName;
  end if;

  if strNullClause is not null then
    cmdSql := cmdSql || strColumnName || ' ' || strDataType || ' ' || strNullClause;
  else
    cmdSql := cmdSql || strColumnName || ' ' || strDataType;
  end if;


end loop;


cmdSql := cmdSql || ')';


curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
end creatArchiveTable;


--------------------------
-- Drops All ARC Tables --
--------------------------

procedure dropArchiveTables
(out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)  is

curFunc integer;
cntRows integer;
cmdSql varchar2(32766);

cursor tblist is
	select table_name from all_tables
		where owner = 'ARC';

begin

	for tbl in tblist loop
		cmdSql := 'drop table arc.' || ltrim(tbl.table_name);
		curFunc := dbms_sql.open_cursor;
		dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
		cntRows := dbms_sql.execute(curFunc);
		dbms_sql.close_cursor(curFunc);
	end loop;

	out_errorno := 0;
    	out_msg := 'OKAY';

exception when others then
    out_errorno := sqlcode;
    out_msg := substr(sqlerrm,1,80);

end dropArchiveTables;



end zarchive;
/
--exit;
