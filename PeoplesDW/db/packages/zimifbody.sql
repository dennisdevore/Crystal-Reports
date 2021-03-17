create or replace package body alps.zimportprocif as
--
-- $Id$
--

procedure begin_malvern_stage_carton
(in_custid IN varchar2
,in_filename IN varchar2
,in_datafield IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

l_lpid  plate.lpid%type;
l_termid multishipterminal.termid%type;
l_fac facility.facility%type;

strdebugyn varchar2(1);
strSuffix varchar2(40);
cmdsql varchar2(300);
viewcount integer;
cntrows integer;

procedure debugmsg(in_text varchar2)
as

cntChar integer;

begin

if strDebugYN <> 'Y' then
  return;
end if;

cntChar := 1;
while (cntChar * 60) < (Length(in_text)+60)
loop
  zut.prt(substr(in_text,((cntChar-1)*60)+1,60));
  cntChar := cntChar + 1;
end loop;

exception when others then
  null;
end;


begin

if out_errorno = -12345 then
  strDebugYN := 'Y';
  debugmsg('debug is on');
else
  strDebugYN := 'N';
end if;

out_errorno := 0;
out_msg := '';

debugmsg('find view suffix');
viewcount := 1;
while(1=1)
loop
  strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || viewcount;
  select count(1)
    into cntRows
    from user_tables
   where table_name = 'MALVERN_STAGE_CARTON_' || strSuffix;
  if cntRows = 0 then
    exit;
  else
    viewcount := viewcount + 1;
  end if;
end loop;

debugmsg('strSuffix:'||strSuffix);

l_lpid := substr(in_datafield,1,15);

l_fac := substr(in_datafield,16, 3);

l_termid := substr(in_datafield,19);



cmdSql := 'create view MALVERN_STAGE_CARTON_' || strSuffix ||
' as select '''
    ||in_filename||''' importfileid, '''
    ||l_fac||''' facility, '''
    ||in_custid||''' custid, '''
    ||l_lpid||''' lpid, '''||l_termid||''' termid from dual';
debugmsg(cmdSql);
execute immediate cmdSql;
out_msg := 'OKAY';
out_errorno := viewcount;

exception when others then
  out_msg := 'zimif ' || sqlerrm;
  out_errorno := sqlcode;
end begin_malvern_stage_carton;

procedure end_malvern_stage_carton
(in_custid IN varchar2
,in_viewsuffix IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
as

curFunc integer;
cntRows integer;
cmdSql varchar2(20000);

strSuffix varchar2(32);

begin

out_errorno := 0;
out_msg := '';

strSuffix := translate(rtrim(upper(in_custid)),'----------','__________') || in_viewsuffix;

cmdSql := 'drop view malvern_stage_carton_' || strSuffix;
curFunc := dbms_sql.open_cursor;
dbms_sql.parse(curFunc, cmdSql, dbms_sql.native);
cntRows := dbms_sql.execute(curFunc);
dbms_sql.close_cursor(curFunc);

out_msg := 'OKAY';
out_errorno := 0;

exception when others then
  out_msg := 'zimfreighte ' || sqlerrm;
  out_errorno := sqlcode;
end end_malvern_stage_carton;


end zimportprocif;
/
show error package body zimportprocif;
exit;
