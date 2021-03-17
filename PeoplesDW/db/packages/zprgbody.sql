CREATE OR REPLACE package body zpurge
as
--
-- $Id$
--

/*
Note: issue the following alter before executing this proc:
   ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY MM DD HH24:MI:SS';
*/

type datacol_type is record
(column_name varchar2(30)
,data_type varchar2(30)
,column_value varchar2(4000)
);

type datacol_tbltype is table of datacol_type
  index by binary_integer;

pcol datacol_tbltype;
ccol datacol_tbltype;

type badkey_type is record
(parenttable varchar2(30)
,childtable varchar2(30)
);

type badkey_tbltype is table of badkey_type
  index by binary_integer;

bk badkey_tbltype;

type purgetot_type is record
(tablename varchar2(30)
,count number
);

type purgetot_tbltype is table of purgetot_type
  index by binary_integer;

pt purgetot_tbltype;

ptix integer;
bkix integer;
pix integer;
cix integer;
pkey1x integer;
pkey2x integer;
pkey3x integer;
ckey1x integer;
ckey2x integer;
ckey3x integer;
pfacilityx integer;
pcustidx integer;
pbasedonx integer;
cmdSql varchar2(20000);
cmdParentSql varchar2(2000);
cmdChildSql varchar2(2000);
curSql integer;
curRule integer;
curParent integer;
curChild integer;
cntRows integer;
cntParentScanned integer;
cntParentPurged integer;
ParentValues varchar2(20000);
ChildValues varchar2(20000);
cntCondition integer;
lenLong integer;
strMsg varchar2(255);
strArchiveOwner varchar2(30);


procedure do_purge
(out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
) is

cursor curAllTablesToPurge is
  select distinct parenttable as tablename
    from purgetablelist
      union
  select distinct childtable as tablename
    from purgetablelist;

cursor curPurgeRules(in_tablename varchar2) is
  select tablename,
         basedonfield,
         rule1field,rule1operator,rule1value,
         rule2field,rule2operator,rule2value,
         rule3field,rule3operator,rule3value,
         functionname,
         facilityfield,
         custidfield
    from purgerules
   where tablename = in_tablename
   order by descr;
rule curPurgeRules%rowtype;

cursor curParentTablesNoFunc is
  select *
    from purgetablelist
   where childtable is null
     and not exists
         (select *
            from purgerules
           where purgerules.tablename = purgetablelist.parenttable
             and purgerules.functionname is not null)
   order by descr;

cursor curParentTablesWithFunc is
  select *
    from purgetablelist
   where childtable is null
     and exists
         (select *
            from purgerules
           where purgerules.tablename = purgetablelist.parenttable
             and purgerules.functionname is not null)
   order by descr;
ptbl purgetablelist%rowtype;

cursor curChildTables(in_ParentTable varchar2) is
  select *
    from purgetablelist
   where parenttable = in_ParentTable
     and ChildTable is not null;
ctbl curChildTables%rowtype;

cursor curTableColumns(theTable varchar2) is
  select column_name,data_type
    from user_tab_columns
   where table_name = theTable
   order by column_id;

cursor curFuncArguments(in_functionname varchar2) is
  select argument_name,position
    from user_arguments
   where package_name = 'ZPURGE'
     and object_name = in_functionname
     and position != 0
   order by position;

function prep_field_value(in_column_value in varchar2, in_data_type in varchar2)
return varchar2 is

newValue varchar2(4000);

begin

if in_column_value is null then
  newValue := 'null';
else
  newValue := in_column_value;
  if in_data_type in ('VARCHAR','VARCHAR2','CHAR','LONG','DATE','ROWID') then
    -- replace single quotes with double quotes
    newValue := replace(newValue,'''','''''');
    --place quotes around field
    newValue :=  '''' || newValue || '''';
  end if;
end if;

return newValue;

end prep_field_value;

procedure check_custid_and_item
is

custidx integer;

begin

  custidx := -1;
  for pix in 1 .. pcol.count
  loop
    if pcol(pix).column_name = 'CUSTID' then
      if pcol(pix).column_value is null then
        exit;
      end if;
      custidx := pix;
      cmdSql := 'update customer set lastupdate = sysdate, lastuser = ''PURGE''' ||
        ' where customer = ' ||
        prep_field_value(pcol(pix).column_value,pcol(pix).data_type) ||
        ' and status <> ''ACTV'' and lastupdate < sysdate - 1';
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
    end if;
  end loop;

  if custidx = -1 then
    return;
  end if;

  for pix in 1 .. pcol.count
  loop
    if pcol(pix).column_name = 'ITEM' then
      if pcol(pix).column_value is null then
        exit;
      end if;
      cmdSql := 'update custitem set lastupdate = sysdate, lastuser = ''PURGE''' ||
        ' where customer = ' ||
        prep_field_value(pcol(custidx).column_value,pcol(custidx).data_type) ||
        ' and item = ' ||
        prep_field_value(pcol(pix).column_value,pcol(pix).data_type) ||
        ' and status <> ''ACTV'' and lastupdate < sysdate - 1';
      curSql := dbms_sql.open_cursor;
      dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
      cntRows := dbms_sql.execute(curSql);
      dbms_sql.close_cursor(curSql);
    end if;
  end loop;

exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
end check_custid_and_item;

procedure increment_purge_count(in_tablename varchar2, in_count number)
is
begin
  if pt.count <> 0 then
    for ptix in 1 .. pt.count
    loop
      if in_tablename = pt(ptix).tablename then
        pt(ptix).count := pt(ptix).count + in_count;
        return;
      end if;
    end loop;
  end if;
  ptix := pt.count + 1;
  pt(ptix).tablename := in_tablename;
  pt(ptix).count := in_count;
end;

function old_enough(in_days number)
return boolean
is
begin
  cmdSql := 'select count(1) from dual where floor(sysdate - to_date(' ||
     prep_field_value(pcol(pbasedonx).column_value,pcol(pbasedonx).data_type) ||
     ',''YYYY MM DD HH24:MI:SS'')) > ' || in_days;
  cntCondition := 0;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cntCondition);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows <= 0 then
    dbms_sql.close_cursor(curSql);
    return False;
  end if;
  dbms_sql.column_value(curSql,1,cntCondition);
  dbms_sql.close_cursor(curSql);
  if cntCondition = 0 then
    return False;
  else
    return True;
  end if;
exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  return False;
end old_enough;

function function_fits
return boolean
is

blnResult number;

begin

  cmdSql := 'select zprg.' || rule.functionname  || '(';
  for fa in curFuncArguments(rule.functionname)
  loop
    if fa.position != 1 then
      cmdSql := cmdSql || ',';
    end if;
    pix := 1;
    while (pix < pcol.count)
    loop
      if substr(fa.argument_name,4,255) = pcol(pix).column_name then
        exit;
      end if;
      pix := pix + 1;
    end loop;
    if pix = pcol.count then
      return False;
    end if;
    cmdSql := cmdSql ||
      prep_field_value(pcol(pix).column_value,pcol(pix).data_type);
  end loop;
  cmdSql := cmdSql ||  ') from dual;';
  cntCondition := 0;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cntCondition);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows <= 0 then
    dbms_sql.close_cursor(curSql);
    return False;
  end if;
  dbms_sql.column_value(curSql,1,cntCondition);
  dbms_sql.close_cursor(curSql);

  if cntCondition = 0 then
    return False;
  else
    return True;
  end if;

exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  return False;
end function_fits;

function rule_fits(in_rulefield varchar2, in_operator varchar2, in_value varchar2)
return boolean
is
begin
  cmdSql := 'select count(1) from dual where ';
  pix := 1;
  while (pix < pcol.count)
  loop
    if in_rulefield = pcol(pix).column_name then
      exit;
    end if;
    pix := pix + 1;
  end loop;
  if pix = pcol.count then
    return False;
  end if;
  cmdSql := cmdSql ||
    prep_field_value(pcol(pix).column_value,pcol(pix).data_type);
  if in_operator = 'IN' then
    cmdsql := cmdsql || ' ' ||
      zcm.in_str_clause('I',in_value);
  else
    cmdSql := cmdSql || ' ' || in_operator || ' ' ||
      prep_field_value(in_value,pcol(pix).data_type);
  end if;
  cntCondition := 0;
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  dbms_sql.define_column(curSql,1,cntCondition);
  cntRows := dbms_sql.execute(curSql);
  cntRows := dbms_sql.fetch_rows(curSql);
  if cntRows <= 0 then
    dbms_sql.close_cursor(curSql);
    return False;
  end if;
  dbms_sql.column_value(curSql,1,cntCondition);
  dbms_sql.close_cursor(curSql);
  if cntCondition = 0 then
    return False;
  else
    return True;
  end if;
exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  return False;
end rule_fits;

function fits_retention_days
return boolean
is

cntDays integer;

begin

  pfacilityx := -1;
  if rule.facilityfield is not null then
    for pix in 1 .. pcol.count
    loop
      if rule.facilityfield = pcol(pix).column_name then
        pfacilityx := pix;
        exit;
      end if;
    end loop;
  end if;

  pcustidx := -1;
  if rule.custidfield is not null then
    for pix in 1 .. pcol.count
    loop
      if rule.custidfield = pcol(pix).column_name then
        pcustidx := pix;
        exit;
      end if;
    end loop;
  end if;

  if rule.basedonfield is null then
    return False;
  end if;

  pbasedonx := -1;
  for pix in 1 .. pcol.count
  loop
    if rule.basedonfield = pcol(pix).column_name then
      pbasedonx := pix;
      exit;
    end if;
  end loop;

  if pbasedonx = -1 then
    return False;
  end if;

  if (pcustidx = -1) or
     (pcol(pcustidx).column_value is null) then
    goto facility_only_check;
  end if;

<< custid_and_facility_check >>

  if (pfacilityx = -1) or
     (pcol(pfacilityx).column_value is null) then
    goto cust_only_check;
  end if;

  begin
    select daystokeep
      into cntDays
      from purgerulesdtl
     where tablename = ptbl.parenttable
       and nvl(rule1field,'$x') = nvl(rule.rule1field,'$x')
       and nvl(rule1operator,'$x') = nvl(rule.rule1operator,'$x')
       and nvl(rule1value,'$x') = nvl(rule.rule1value,'$x')
       and nvl(rule2field,'$x') = nvl(rule.rule2field,'$x')
       and nvl(rule2operator,'$x') = nvl(rule.rule2operator,'$x')
       and nvl(rule2value,'$x') = nvl(rule.rule2value,'$x')
       and nvl(rule3field,'$x') = nvl(rule.rule3field,'$x')
       and nvl(rule3operator,'$x') = nvl(rule.rule3operator,'$x')
       and nvl(rule3value,'$x') = nvl(rule.rule3value,'$x')
       and custid = pcol(pcustidx).column_value
       and facility = pcol(pfacilityx).column_value;
  exception when others then
    cntDays := -1;
  end;

  if cntDays < 0 then
    goto cust_only_check;
  end if;

  if old_enough(cntDays) then
    return True;
  else
    return False;
  end if;

<< cust_only_check >>

  begin
    select daystokeep
      into cntDays
      from purgerulesdtl
     where tablename = ptbl.parenttable
       and nvl(rule1field,'$x') = nvl(rule.rule1field,'$x')
       and nvl(rule1operator,'$x') = nvl(rule.rule1operator,'$x')
       and nvl(rule1value,'$x') = nvl(rule.rule1value,'$x')
       and nvl(rule2field,'$x') = nvl(rule.rule2field,'$x')
       and nvl(rule2operator,'$x') = nvl(rule.rule2operator,'$x')
       and nvl(rule2value,'$x') = nvl(rule.rule2value,'$x')
       and nvl(rule3field,'$x') = nvl(rule.rule3field,'$x')
       and nvl(rule3operator,'$x') = nvl(rule.rule3operator,'$x')
       and nvl(rule3value,'$x') = nvl(rule.rule3value,'$x')
       and custid = pcol(pcustidx).column_value
       and facility is null;
  exception when others then
    cntDays := -1;
  end;

  if cntDays < 0 then
    goto facility_only_check;
  end if;

  if old_enough(cntDays) then
    return True;
  else
    return False;
  end if;

<< facility_only_check >>

  if (pfacilityx = -1) or
     (pcol(pfacilityx).column_value is null) then
    goto default_check;
  end if;

  begin
    select daystokeep
      into cntDays
      from purgerulesdtl
     where tablename = ptbl.parenttable
       and nvl(rule1field,'$x') = nvl(rule.rule1field,'$x')
       and nvl(rule1operator,'$x') = nvl(rule.rule1operator,'$x')
       and nvl(rule1value,'$x') = nvl(rule.rule1value,'$x')
       and nvl(rule2field,'$x') = nvl(rule.rule2field,'$x')
       and nvl(rule2operator,'$x') = nvl(rule.rule2operator,'$x')
       and nvl(rule2value,'$x') = nvl(rule.rule2value,'$x')
       and nvl(rule3field,'$x') = nvl(rule.rule3field,'$x')
       and nvl(rule3operator,'$x') = nvl(rule.rule3operator,'$x')
       and nvl(rule3value,'$x') = nvl(rule.rule3value,'$x')
       and custid is null
       and facility = pcol(pfacilityx).column_value;
  exception when others then
    cntDays := -1;
  end;

  if cntDays < 0 then
    goto default_check;
  end if;

  if old_enough(cntDays) then
    return True;
  else
    return False;
  end if;

<< default_check >>

  begin
    select daystokeep
      into cntDays
      from purgerulesdtl
     where tablename = ptbl.parenttable
       and nvl(rule1field,'$x') = nvl(rule.rule1field,'$x')
       and nvl(rule1operator,'$x') = nvl(rule.rule1operator,'$x')
       and nvl(rule1value,'$x') = nvl(rule.rule1value,'$x')
       and nvl(rule2field,'$x') = nvl(rule.rule2field,'$x')
       and nvl(rule2operator,'$x') = nvl(rule.rule2operator,'$x')
       and nvl(rule2value,'$x') = nvl(rule.rule2value,'$x')
       and nvl(rule3field,'$x') = nvl(rule.rule3field,'$x')
       and nvl(rule3operator,'$x') = nvl(rule.rule3operator,'$x')
       and nvl(rule3value,'$x') = nvl(rule.rule3value,'$x')
       and custid is null
       and facility is null;
  exception when others then
    cntDays := -1;
  end;

  if cntDays < 0 then
    return False;
  end if;

  if old_enough(cntDays) then
    return True;
  else
    return False;
  end if;

exception when others then
  return False;
end fits_retention_days;

function row_eligible_for_purging
return boolean
is

begin

  open curPurgeRules(ptbl.ParentTable);
  while (1=1)
  loop
    fetch curPurgeRules into rule;
    if curPurgeRules%notfound then
      close curPurgeRules;
      return FALSE;
    end if;
    if rule.rule1field is not null and
       rule.rule1operator is not null and
       rule.rule1value is not null then
      if not rule_fits(rule.rule1field,rule.rule1operator,rule.rule1value) then
        goto next_rule_set;
      end if;
    end if;
    if rule.rule2field is not null and
       rule.rule2operator is not null and
       rule.rule2value is not null then
      if not rule_fits(rule.rule2field,rule.rule2operator,rule.rule2value) then
        goto next_rule_set;
      end if;
    end if;
    if rule.rule3field is not null and
       rule.rule3operator is not null and
       rule.rule3value is not null then
      if not rule_fits(rule.rule3field,rule.rule3operator,rule.rule3value) then
        goto next_rule_set;
      end if;
    end if;
    if rule.functionname is not null then
      if not function_fits then
        goto next_rule_set;
      end if;
    end if;
    if not fits_retention_days then
      goto next_rule_set;
    end if;
    close curPurgeRules;
    return True;
  << next_rule_set >>
    null;
  end loop;
  close curPurgeRules;

  return False;

exception when others then
  if curPurgeRules%isopen then
    close curPurgeRules;
  end if;
  raise;
end row_eligible_for_purging;

procedure archive_child_row
is
begin

  cmdSql := 'insert into ' || strArchiveOwner || ctbl.childtable ||
    ' values (' || childValues || ')';
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);

  cmdSql := 'delete from ' || ctbl.childtable || ' where rowid = ' ||
    prep_field_value(ccol(ccol.count).column_value,ccol(ccol.count).data_type);
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  increment_purge_count(ctbl.childTable, cntRows);
  dbms_sql.close_cursor(curSql);

exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  raise;
end archive_child_row;

procedure process_child_table
is
begin

  ckey1x := -1;
  ckey2x := -1;
  ckey3x := -1;
  ccol.delete;
  cix := 1;
  for td in curTableColumns(ctbl.ChildTable)
  loop
    ccol(cix).column_name := td.column_name;
    if td.column_name = ctbl.keyfield1 then
      ckey1x := cix;
    end if;
    if td.column_name = ctbl.keyfield2 then
      ckey2x := cix;
    end if;
    if td.column_name = ctbl.keyfield3 then
      ckey3x := cix;
    end if;
    ccol(cix).data_type := td.data_type;
    cix := cix + 1;
  end loop;
  if ( (pkey1x > 0) and (ckey1x < 0) ) or
     ( (pkey2x > 0) and (ckey2x < 0) ) or
     ( (pkey3x > 0) and (ckey3x < 0) ) then
    if bk.count <> 0 then
      for bkix in 1 .. bk.count
      loop
        if (bk(bkix).parenttable = ptbl.parenttable) and
           (bk(bkix).childtable = ctbl.ChildTable) then
          return;
        end if;
      end loop;
    end if;
    bkix := bk.count + 1;
    bk(bkix).parenttable := ptbl.parenttable;
    bk(bkix).childtable := ctbl.childtable;
    zms.log_msg('PURGE', null, null,
      'Parent/Child key mismatch on ' ||
        ptbl.ParentTable || '/' || ctbl.ChildTable ||
        '--child table will NOT be purged',
        'E', 'PURGE', out_msg);
    return;
  end if;
  cmdChildSql := 'select ' || ctbl.childtable || '.*,' ||
    ctbl.childtable || '.rowid from ' || ctbl.childtable;
  cmdChildSql := cmdChildSql || ' where ';
  if pkey1x > 0 then
    cmdChildSql := cmdChildSql ||
      ccol(ckey1x).column_name || ' = ' ||
      prep_field_value(pcol(pkey1x).column_value,ccol(ckey1x).data_type);
  end if;
  if pkey2x > 0 then
    if pkey1x > 0 then
      cmdChildSql := cmdChildSql || ' and ';
    end if;
    cmdChildSql := cmdChildSql ||
      ccol(ckey2x).column_name || ' = ' ||
      prep_field_value(pcol(pkey2x).column_value,ccol(ckey2x).data_type);
  end if;
  if pkey3x > 0 then
    if (pkey1x > 0) or
       (pkey2x > 0) then
      cmdChildSql := cmdChildSql || ' and ';
    end if;
    cmdChildSql := cmdChildSql ||
      ccol(ckey2x).column_name || ' = ' ||
      prep_field_value(pcol(pkey2x).column_value,ccol(ckey2x).data_type);
  end if;
  curChild := dbms_sql.open_cursor;
  dbms_sql.parse(curChild, cmdChildSql, dbms_sql.native);
  for cix in 1 .. ccol.count
  loop
    if ccol(cix).data_type = 'LONG' then
      dbms_sql.define_column_long(curChild,cix);
    else
      dbms_sql.define_column(curChild,cix,ccol(cix).column_value,4000);
    end if;
  end loop;
  cix := ccol.count + 1;
  ccol(cix).data_type := 'ROWID';
  dbms_sql.define_column(curChild,cix,ccol(cix).column_value,4000);

  cntRows := dbms_sql.execute(curChild);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curChild);
    if cntRows <= 0 then
      exit;
    end if;
    ChildValues := '';
    -- load fetched column into values string (exclude rowid)
    for cix in 1 .. ccol.count
    loop
      if ccol(cix).data_type = 'LONG' then
        dbms_sql.column_value_long(curChild,cix,4000,0,ccol(cix).column_value,lenLong);
      else
        dbms_sql.column_value(curChild,cix,ccol(cix).column_value);
      end if;
      if cix != ccol.count then
        if (cix != 1) then
          ChildValues := ChildValues || ',';
        end if;
        ChildValues := ChildValues ||
          prep_field_value(ccol(cix).column_value,ccol(cix).data_type);
      end if;
    end loop;
    archive_child_row;
  end loop;
  dbms_sql.close_cursor(curChild);

exception when others then
  if dbms_sql.is_open(curChild) then
    dbms_sql.close_cursor(curChild);
  end if;
  raise;
end process_child_table;

procedure check_child_tables
is
begin

  open curChildTables(ptbl.ParentTable);
  while(1=1)
  loop

    fetch curChildTables into ctbl;
    if curChildTables%notfound then
      close curChildTables;
      exit;
    end if;

    process_child_table;

  end loop;

exception when others then
  cntRows := sqlcode;
  strMsg := substr(sqlerrm,1,255);
  rollback;
  if curChildTables%isopen then
    close curChildTables;
  end if;
  zms.log_msg('PURGE', null, null,
    'Exception while processing Child' ||
      ctbl.ChildTable || ' (' || cntRows || ') ' || strMsg,
      'E', 'PURGE', out_msg);
  commit;
  raise;
end check_child_tables;

procedure archive_parent_row
is
begin

--  cntRows := 1;
--  while (cntRows * 60) < (Length(cmdSql)+60)
--  loop
--    zut.prt(substr(cmdSql,((cntRows-1)*60)+1,60));
--    cntRows := cntRows + 1;
--  end loop;
  cmdSql := 'insert into ' || strArchiveOwner || ptbl.parenttable ||
    ' values (' || ParentValues || ')';
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  dbms_sql.close_cursor(curSql);

  cmdSql := 'delete from ' || ptbl.parenttable || ' where rowid = ' ||
    prep_field_value(pcol(pcol.count).column_value,pcol(pcol.count).data_type);
  curSql := dbms_sql.open_cursor;
  dbms_sql.parse(curSql, cmdSql, dbms_sql.native);
  cntRows := dbms_sql.execute(curSql);
  cntParentPurged := cntParentPurged + cntRows;
  increment_purge_count(ptbl.ParentTable, cntRows);
  dbms_sql.close_cursor(curSql);

exception when others then
  if dbms_sql.is_open(curSql) then
    dbms_sql.close_cursor(curSql);
  end if;
  raise;
end archive_parent_row;

procedure process_parent_table
is
begin

  strMsg := 'Processing parent table '  || ptbl.ParentTable;

  if ptbl.keyfield1 is null and
     ptbl.keyfield2 is null and
     ptbl.keyfield3 is null then
    strMsg := strMsg || ' (no keys are defined--Child Tables WILL NOT be checked)';
  else
    strMsg := strMsg || ' (keys are defined--Child Tables WILL be checked)';
  end if;

  zms.log_msg('PURGE', null, null, strMsg, 'I', 'PURGE', out_msg);
  commit;

  cntParentScanned := 0;
  cntParentPurged := 0;

  cmdParentSql := 'select ' || ptbl.parenttable || '.*,' ||
    ptbl.parenttable || '.rowid from ' || ptbl.parenttable;
  curParent := dbms_sql.open_cursor;
  dbms_sql.parse(curParent, cmdParentSql, dbms_sql.native);

  pix := 1;
  pkey1x := -1;
  pkey2x := -1;
  pkey3x := -1;
  pcol.delete;
  for td in curTableColumns(ptbl.ParentTable)
  loop
    pcol(pix).column_name := td.column_name;
    if td.column_name = ptbl.keyfield1 then
      pkey1x := pix;
    end if;
    if td.column_name = ptbl.keyfield2 then
      pkey2x := pix;
    end if;
    if td.column_name = ptbl.keyfield3 then
      pkey3x := pix;
    end if;
    pcol(pix).data_type := td.data_type;
    if td.data_type = 'LONG' then
      dbms_sql.define_column_long(curParent,pix);
    else
      dbms_sql.define_column(curParent,pix,pcol(pix).column_value,4000);
    end if;
    pix := pix + 1;
  end loop;
  pcol(pix).data_type := 'ROWID';
  dbms_sql.define_column(curParent,pix,pcol(pix).column_value,4000);

  cntRows := dbms_sql.execute(curParent);
  while (1=1)
  loop
    cntRows := dbms_sql.fetch_rows(curParent);
    if cntRows <= 0 then
      exit;
    end if;
    cntParentScanned := cntParentScanned + 1;
    if mod(cntParentScanned,1000) = 0 then
      zms.log_msg('PURGE', null, null,
        ptbl.ParentTable || ': ' || cntParentScanned ||
        ' rows scanned... (Cumulative archive count ' || cntParentPurged || ')',
        'I', 'PURGE', strMsg);
      commit;
    end if;
    ParentValues := '';
    -- load fetched column into values string (exclude rowid)
    for pix in 1 .. pcol.count
    loop
      if pcol(pix).data_type = 'LONG' then
        dbms_sql.column_value_long(curParent,pix,4000,0,pcol(pix).column_value,lenLong);
      else
        dbms_sql.column_value(curParent,pix,pcol(pix).column_value);
      end if;
      if pix != pcol.count then
        if (pix != 1) then
          ParentValues := ParentValues || ',';
        end if;
        ParentValues := ParentValues ||
          prep_field_value(pcol(pix).column_value,pcol(pix).data_type);
      end if;
    end loop;
    if row_eligible_for_purging then
      archive_parent_row;
      if ptbl.keyfield1 is not null or
         ptbl.keyfield2 is not null or
         ptbl.keyfield3 is not null then
        check_child_tables;
      end if;
    else
      check_custid_and_item;
    end if;
  end loop;
  dbms_sql.close_cursor(curParent);

  zms.log_msg('PURGE', null, null,
    ptbl.ParentTable || '--Total rows scanned: ' || cntParentScanned ||
      '    Total rows archived: ' || cntParentPurged,
      'I', 'PURGE', strMsg);
  commit;

exception when others then
  cntRows := sqlcode;
  strMsg := substr(sqlerrm,1,255);
  rollback;
  if dbms_sql.is_open(curParent) then
    dbms_sql.close_cursor(curParent);
  end if;
  zms.log_msg('PURGE', null, null,
    'Exception while processing ' ||
      ptbl.ParentTable || ' (' || cntRows || ') ' || strMsg,
      'E', 'PURGE', out_msg);
  commit;
end process_parent_table;

-- Begin Main Purge Logic
begin

strMsg := null;
select value
  into strMsg
  from v$nls_parameters
 where parameter = 'NLS_DATE_FORMAT';
if nvl(strMsg,'x') != 'YYYY MM DD HH24:MI:SS' then
  out_errorno := -99;
  out_msg :=  'An "ALTER SESSION SET NLS_DATE_FORMAT = ''YYYY MM DD HH24:MI:SS''" command must be issued before the purge can run';
  zms.log_msg('PURGE', null, null, out_msg, 'I', 'PURGE', strMsg);
  commit;
  return;
end if;

out_errorno := 0;
out_msg := null;
bk.delete;
pt.delete;

strArchiveOwner := 'ARC.';

-- Drop and recreate the archive tables. --

zlk.get_app_lock('PURGE',NULL,'PURGE',out_msg);

if out_msg = 'OKAY' then
  zms.log_msg('PURGE', null, null, 'Begin Purge run', 'I', 'PURGE', out_msg);
  commit;
  for tbl in curAllTablesToPurge
  loop
    if zarc.compareArchiveTable(tbl.tablename) = 'N' then
      zarc.creatArchiveTable(tbl.tablename,out_errorno,out_msg );
      commit;
    end if;
  end loop;
else
  rollback;
  out_msg := 'Purge was not executed--application ''PURGE'' lock is set.';
  zms.log_msg('PURGE', null, null, out_msg, 'E', 'PURGE', strMsg);
  commit;
  out_errorno := -1;
  return;
end if;

open curParentTablesNoFunc;
while(1=1)
loop

  fetch curParentTablesNoFunc into ptbl;
  if curParentTablesNoFunc%notfound then
    close curParentTablesNoFunc;
    exit;
  end if;

  process_parent_table;

end loop;

commit;

open curParentTablesWithFunc;
while(1=1)
loop

  fetch curParentTablesWithFunc into ptbl;
  if curParentTablesWithFunc%notfound then
    close curParentTablesWithFunc;
    exit;
  end if;

  process_parent_table;

end loop;

commit;

if upper(substr(zci.default_value('PURGEAUTOUNLOCK'),1,1)) = 'Y' then
  zlk.release_app_lock('PURGE',NULL,'PURGE',out_msg);
else
  out_msg := 'OKAY';
end if;

if out_msg = 'OKAY' then
  commit;
  for ptix in 1 .. pt.count
  loop
    zms.log_msg('PURGE', null, null,
      'Recap ' ||pt(ptix).tablename || ' table total rows archived: ' || pt(ptix).count,
      'I', 'PURGE', strMsg);
    commit;
  end loop;
  zms.log_msg('PURGE', null, null,
    'Purge run complete.',
    'I', 'PURGE', strMsg);
  commit;
  out_errorno := 0;
  out_msg := 'OKAY';
else
  rollback;
  zms.log_msg('PURGE', null, null,
    'Unable to release PURGE lock: ' || out_msg,
    'I', 'PURGE', strMsg);
  commit;
  out_errorno := -4;
  out_msg := 'Unable to release PURGE application lock';
end if;

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,80);
  rollback;
  zms.log_msg('PURGE', null, null, out_msg, 'E', 'PURGE', strMsg);
  commit;
end do_purge;

procedure retention_update
(in_old_tablename IN varchar2
,in_old_rule1field IN varchar2
,in_old_rule1operator IN varchar2
,in_old_rule1value IN varchar2
,in_old_rule2field IN varchar2
,in_old_rule2operator IN varchar2
,in_old_rule2value IN varchar2
,in_old_rule3field IN varchar2
,in_old_rule3operator IN varchar2
,in_old_rule3value IN varchar2
,in_new_tablename IN varchar2
,in_new_rule1field IN varchar2
,in_new_rule1operator IN varchar2
,in_new_rule1value IN varchar2
,in_new_rule2field IN varchar2
,in_new_rule2operator IN varchar2
,in_new_rule2value IN varchar2
,in_new_rule3field IN varchar2
,in_new_rule3operator IN varchar2
,in_new_rule3value IN varchar2
,in_userid IN varchar2
,out_errorno IN OUT NUMBER
,out_msg IN OUT varchar2
)
is
begin

out_errorno := 0;
out_msg := '';

if rtrim(in_old_tablename) = rtrim(in_new_tablename) and
   nvl(rtrim(in_old_rule1field),'$x') = nvl(rtrim(in_new_rule1field),'$x') and
   nvl(rtrim(in_old_rule1operator),'$x') = nvl(rtrim(in_new_rule1operator),'$x') and
   nvl(rtrim(in_old_rule1value),'$x') = nvl(rtrim(in_new_rule1value),'$x') and
   nvl(rtrim(in_old_rule2field),'$x') = nvl(rtrim(in_new_rule2field),'$x') and
   nvl(rtrim(in_old_rule2operator),'$x') = nvl(rtrim(in_new_rule2operator),'$x') and
   nvl(rtrim(in_old_rule2value),'$x') = nvl(rtrim(in_new_rule2value),'$x') and
   nvl(rtrim(in_old_rule3field),'$x') = nvl(rtrim(in_new_rule3field),'$x') and
   nvl(rtrim(in_old_rule3operator),'$x') = nvl(rtrim(in_new_rule3operator),'$x') and
   nvl(rtrim(in_old_rule3value),'$x') = nvl(rtrim(in_new_rule3value),'$x') then
  out_msg := 'OKAY';
  return;
end if;

update purgerulesdtl
   set tablename = in_new_tablename,
       rule1field = in_new_rule1field,
       rule1operator = in_new_rule1operator,
       rule1value = in_new_rule1value,
       rule2field = in_new_rule2field,
       rule2operator = in_new_rule2operator,
       rule2value = in_new_rule2value,
       rule3field = in_new_rule3field,
       rule3operator = in_new_rule3operator,
       rule3value = in_new_rule3value
 where tablename = rtrim(in_old_tablename)
   and nvl(rtrim(rule1field),'$x') = nvl(rtrim(in_old_rule1field),'$x')
   and nvl(rtrim(rule1operator),'$x') = nvl(rtrim(in_old_rule1operator),'$x')
   and nvl(rtrim(rule1value),'$x') = nvl(rtrim(in_old_rule1value),'$x')
   and nvl(rtrim(rule2field),'$x') = nvl(rtrim(in_old_rule2field),'$x')
   and nvl(rtrim(rule2operator),'$x') = nvl(rtrim(in_old_rule2operator),'$x')
   and nvl(rtrim(rule2value),'$x') = nvl(rtrim(in_old_rule2value),'$x')
   and nvl(rtrim(rule3field),'$x') = nvl(rtrim(in_old_rule3field),'$x')
   and nvl(rtrim(rule3operator),'$x') = nvl(rtrim(in_old_rule3operator),'$x')
   and nvl(rtrim(rule3value),'$x') = nvl(rtrim(in_old_rule3value),'$x');

out_msg := 'OKAY';

exception when others then
  out_errorno := sqlcode;
  out_msg := substr(sqlerrm,1,255);
end;

function item_purgable
(in_custid varchar2
,in_item varchar2
) return number
is

cntRows integer;

cursor curFacility is
  select facility
    from facility;

cursor curBillStatus is
  select code
    from billstatus;

begin

  select count(1)
    into cntRows
    from custitem
   where custid = in_custid
     and item = in_item
     and status = 'ACTV';
  if cntRows != 0 then
    return 0;
  end if;

  select count(1)
    into cntRows
    from plate
   where custid = in_custid
     and item = in_item;
  if cntRows != 0 then
    return 0;
  end if;

  for fc in curFacility
  loop
    cntRows := 0;
    select count(1)
      into cntRows
      from shippingplate
     where facility = fc.facility
       and custid = in_custid
       and item = in_item;
    if cntRows != 0 then
      return 0;
    end if;
  end loop;

  for bs in curBillStatus
  loop
    for fc in curFacility
    loop
      cntRows := 0;
      select count(1)
        into cntRows
        from invoicedtl
       where billstatus = bs.code
         and facility = fc.facility
         and custid = in_custid
         and item = in_item;
      if cntRows != 0 then
        return 0;
      end if;
    end loop;
  end loop;
  return 1;

exception when others then
  return 0;
end item_purgable;

function custid_purgable
(in_custid varchar2
) return number
is

cntRows integer;

cursor curFacility is
  select facility
    from facility;

begin

  select count(1)
    into cntRows
    from customer
   where custid = in_custid
     and status = 'ACTV';
  if cntRows != 0 then
    return 0;
  end if;

  select count(1)
    into cntRows
    from plate
   where custid = in_custid;
  if cntRows != 0 then
    return 0;
  end if;

  select count(1)
    into cntRows
    from invoicehdr
   where custid = in_custid;
  if cntRows != 0 then
    return 0;
  end if;

  for fc in curFacility
  loop
    cntRows := 0;
    select count(1)
      into cntRows
      from shippingplate
     where facility = fc.facility
       and custid = in_custid;
    if cntRows != 0 then
      return 0;
    end if;
  end loop;

  return 1;

exception when others then
  return 0;
end custid_purgable;

function xp_plate_purgable
(in_parentlpid varchar2
) return number is

cntRows integer;

begin

  select count(1)
    into cntRows
    from shippingplate
   where lpid = in_parentlpid;

  if cntRows = 0 then
    return 1;
  else
    return 0;
  end if;

exception when others then
  return 0;
end xp_plate_purgable;

end zpurge;
/
show errors package body zpurge;
--exit;
