set serverout on

declare
cntTot pls_integer;
cntObj pls_integer;
cntExists pls_integer;
cntNoUniqueKey pls_integer;
cntCreated pls_integer;
cntRenamed pls_integer;
cntDropped pls_integer;
cntMulti pls_integer;
cntExcept pls_integer;
cntRows pls_integer;
l_sqlcmd varchar2(2000);
l_index_columns varchar2(2000);
l_index_has_nulls char(1);
l_index_name varchar2(30);
l_sys_index_name varchar2(30);
l_error boolean;
l_constraint_name varchar2(30);
updflag char(1);

procedure get_unique_index_data(in_table_name varchar2)

is

cntNulls integer;

begin

l_error := False;

select count(1)
  into cntRows
  from user_indexes
 where table_name = in_table_name
   and uniqueness = 'UNIQUE'
   and (index_name not like 'SYS%' or
        index_name = 'SYSTEMDEFAULTS_UNIQUE');
if cntRows = 0 then
  cntNoUniqueKey := cntNoUniqueKey + 1;
  zut.prt(in_table_name || ' has no unique key');
  l_error := True;
  return;
elsif cntRows = 1 then
  select index_name
    into l_index_name
    from user_indexes
   where table_name = in_table_name
     and uniqueness = 'UNIQUE'
     and (index_name not like 'SYS%' or
          index_name = 'SYSTEMDEFAULTS_UNIQUE');
elsif in_table_name = 'CARRIERPRONO' then
  l_index_name := 'CARRIERPRONO_PRONO_IDX';
elsif in_table_name = 'CUSTAUDITSTAGELOC' then
  l_index_name := 'CUSTAUDITSTAGELOC_CUSTID';
elsif in_table_name = 'CUSTITEMALIAS' then
  l_index_name := 'CUSTITEMALIAS_IDX';
elsif in_table_name = 'CUSTITEMBOLCOMMENTS' then
  l_index_name := 'CUSTITEMBOLCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMOUTCOMMENTS' then
  l_index_name := 'CUSTITEMOUTCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMINCOMMENTS' then
  l_index_name := 'CUSTITEMINCOMMENTS_UNIQUE';
elsif in_table_name = 'CUSTITEMSUBS' then
  l_index_name := 'CUSTITEMSUBS_UNIQUE';
elsif in_table_name = 'CUSTITEMLOT' then
  l_index_name := 'CUSTITEMLOT_UNIQUE';
elsif in_table_name = 'CUSTITEMTOT' then
  l_index_name := 'CUSTITEMTOT_UNIQUE_CUSTID';
elsif in_table_name = 'CUSTOMER' then
  l_index_name := 'CUSTOMER_UNIQUE';
elsif in_table_name = 'IMPEXP_CHUNKS_MAPPINGS' then
  l_index_name := 'PK_IMPEXP_CHUNKS_MAPPINGS';
elsif in_table_name = 'IMPEXP_DEFINITIONS' then
  l_index_name := 'PK_IMPEXP_DEFINITIONS';
elsif in_table_name = 'LOADS' then
  l_index_name := 'LOADS_IDX';
elsif in_table_name = 'MULTISHIPDTL' then
  l_index_name := 'IX_MULTISHIPDTL_CARTONID';
elsif in_table_name = 'ORDERDTLLINE' then
  l_index_name := 'ORDERDTLLINE_LINENUMBER';
elsif in_table_name = 'ORDERHDR' then
  l_index_name := 'ORDERHDR_IDX';
elsif in_table_name = 'ORDERDTL' then
  l_index_name := 'ORDERDTL_UNIQUE';
elsif in_table_name = 'ORDERDTLBOLCOMMENTS' then
  l_index_name := 'ORDERDTLBOLCOMMENTS_UNIQUE';
elsif in_table_name = 'WAVES' then
  l_index_name := 'WAVES_UNIQUE';
elsif in_table_name = 'PIMEVENTS' then
  l_index_name := 'PIMEVENTS_START';
elsif in_table_name = 'ALERT_CONTACTS' then
  l_index_name := 'ALERT_CONTACTS_PK';
elsif in_table_name = 'TARIFFBREAKS' then
  l_index_name := 'TARIFFBREAKS_UNIQUE';
elsif in_table_name = 'FREIGHT_BILL_RESULTS' then
  l_index_name := 'FREIGHT_BILL_RESULTS_UNIQUE_AC';
elsif in_table_name = 'TRAILER' then
  l_index_name := 'PK_TRAILER';
else
  zut.prt(in_table_name || ' has multiple unique indexes');
  cntMulti := cntMulti + 1;
  l_error := True;
  return;
end if;

for idx in (select *
              from user_indexes
             where table_name = in_table_name
               and index_name = l_index_name)
loop
  l_index_columns := null;
  cntNulls := 0;
  for col in (select I.column_name, T.nullable
                 from user_tab_columns T, user_ind_columns I
                where I.index_name = idx.index_name
                  and T.table_name = I.table_name
                  and T.column_name = I.column_name
                order by I.column_position)
  loop
    if l_index_columns is null then
      l_index_columns := col.column_name;
    else
      l_index_columns := l_index_columns || ',' || col.column_name;
    end if;
    if col.nullable = 'Y' then
      cntNulls := cntNulls + 1;
    end if;
  end loop;
  if cntNulls > 0 then
    l_index_has_nulls := 'Y';
  else
    l_index_has_nulls := 'N';
  end if;

end loop;

exception when others then
  zut.prt('get_unique_index_data: ' || sqlerrm);
end get_unique_index_data;

begin

updflag := substr(upper('&1'),1,1);

cntTot := 0;
cntExists := 0;
cntNoUniqueKey := 0;
cntCreated := 0;
cntRenamed := 0;
cntDropped := 0;
cntMulti := 0;
cntExcept := 0;

select count(1)
  into cntObj
  from user_indexes
 where index_name = 'ZSEQ_PK';
if cntObj != 0 then
  execute immediate
    'alter index ZSEQ_PK rename to PK_ZSEQ';
end if;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'BILLPARENTPLTCNT'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'SYS%';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'PK_BILLPARENTPLTCNT';
exception when others then
  null;
end;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'WS_COLUMN_VALIDATIONS'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'SYS%';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'PK_WS_COLUMN_VALIDATIONS';
exception when others then
  null;
end;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'WS_GENERATED_REPORTS'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'SYS%';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'PK_WS_GENERATED_REPORTS';
exception when others then
  null;
end;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'WS_USERHEADER'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'SYS%';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'PK_WS_USERHEADER';
exception when others then
  null;
end;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'INVOICETERMS'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'PK_CODE';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'INVOICETERMS_IDX';
exception when others then
  null;
end;

begin
  select index_name
    into l_sys_index_name
   from user_indexes
  where table_name = 'SSCCEXTENSIONDIGITS'
   and uniqueness = 'UNIQUE'
   and index_type = 'NORMAL'
   and index_name like 'PK_EXTENSION_DIGIT';
  execute immediate
    'alter index ' || l_sys_index_name || ' rename to ' || 'SSCCEXTENSIONDIGITS_IDX';
exception when others then
  null;
end;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_CUSTITEMBOLCOMMENTS'
   and index_name = 'CUSTITEMBOLCOMMENTS_CON';
if cntObj != 0 then
  execute immediate
    'alter table custitembolcomments drop constraint uk_custitembolcomments';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'PK_CUSTITEMBOLCOMMENTS'
   and index_name = 'CUSTITEMBOLCOMMENTS_CON';
if cntObj != 0 then
  execute immediate
    'alter table custitembolcomments drop constraint pk_custitembolcomments';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_CUSTITEMOUTCOMMENTS'
   and index_name = 'CUSTITEMOUTCOMMENTS_CON';
if cntObj != 0 then
  execute immediate
    'alter table custitemoutcomments drop constraint uk_custitemoutcomments';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'PK_CUSTITEMOUTCOMMENTS'
   and index_name = 'CUSTITEMOUTCOMMENTS_CON';
if cntObj != 0 then
  execute immediate
    'alter table custitemoutcomments drop constraint pk_custitemoutcomments';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_CUSTITEMTOT'
   and index_name = 'CUSTITEMTOT_UNIQUE_FACILITY';
if cntObj != 0 then
  execute immediate
    'alter table custitemtot drop constraint uk_custitemtot';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'PK_CUSTITEMTOT'
   and index_name = 'CUSTITEMTOT_UNIQUE_FACILITY';
if cntObj != 0 then
  execute immediate
    'alter table custitemtot drop constraint pk_custitemtot';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_LOADS'
   and index_name = 'LOADS_IDX';
if cntObj != 0 then
  execute immediate
    'alter table loads drop constraint uk_loads';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_LOADSTOP'
   and index_name = 'LOADSTOP_IDX';
if cntObj != 0 then
  execute immediate
    'alter table loadstop drop constraint uk_loadstop';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_LOADSTOPSHIP'
   and index_name = 'LOADSTOPSHIP_IDX';
if cntObj != 0 then
  execute immediate
    'alter table loadstopship drop constraint uk_loadstopship';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_ORDERHDRBOLCOMMENTS'
   and index_name = 'ORDERHDRBOLCOMMENTS_UNIQUE';
if cntObj != 0 then
  execute immediate
    'alter table orderhdrbolcomments drop constraint uk_orderhdrbolcomments';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_TBL_COMPANIES'
   and index_name = 'TBL_COMPANIES_UK';
if cntObj != 0 then
  execute immediate
    'alter table tbl_companies drop constraint uk_tbl_companies';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_TBL_GROUPS'
   and index_name = 'TBL_GROUPS_UK11009853010396_1';
if cntObj != 0 then
  execute immediate
    'alter table tbl_groups drop constraint uk_tbl_groups';
end if;

select count(1)
  into cntObj
  from user_constraints
 where constraint_name = 'UK_TBL_USER_PROFILE'
   and index_name = 'TBL_USER_PROF_UK';
if cntObj != 0 then
  execute immediate
    'alter table tbl_user_profile drop constraint uk_tbl_user_profile';
end if;

for col in (select table_name, column_name
              from user_tab_columns uc
             where column_name = 'KITTED_CLASS'
               and table_name not like 'BIN%'
               and exists
                   (select 1
                      from user_tables ut
                     where ut.table_name = uc.table_name)
            )
loop

  l_sqlcmd := 'alter table ' || col.table_name ||
              ' modify kitted_class varchar2(2) not null';
  zut.prt(l_sqlcmd);
  
  if updflag = 'Y' then
    begin
      execute immediate l_sqlcmd;
    exception when others then
      zut.prt(sqlerrm);
    end;
  end if;

end loop;

for tbl in (select constraint_name, table_name, constraint_type
              from user_constraints uc
             where not exists
                   (select 1
                      from user_queues uq
                     where uc.table_name = uq.queue_table)
               and table_name not like 'BIN%'
               and constraint_type in ('U','P')
             order by table_name
            )
loop

  if tbl.constraint_type = 'U' then
    l_constraint_name := 'UK_';
  else
    l_constraint_name := 'PK_';
  end if;
  l_constraint_name := l_constraint_name || substr(tbl.table_name,1,27);

  if l_constraint_name != tbl.constraint_name then
	  l_sqlcmd := 'alter table ' || tbl.table_name || ' rename constraint ' ||
	              tbl.constraint_name || ' to ' || l_constraint_name;
	              
	  zut.prt(l_sqlcmd);
	  
	  if updflag = 'Y' then
	    cntRenamed := cntRenamed + 1;
	    begin
	      execute immediate l_sqlcmd;
	    exception when others then
	      zut.prt(sqlerrm);
	      cntExcept := cntExcept + 1;
	    end;
	  end if;
  end if;	
  
end loop;

for tbl in (select table_name
              from user_tables ut
             where not exists
                   (select 1
                      from user_queues uq
                     where ut.table_name = uq.queue_table)
               and table_name not like 'BIN%'
             order by table_name
           )
loop

 cntTot := cntTot + 1;

 select count(1)
   into cntRows
   from user_constraints
  where table_name = tbl.table_name
    and constraint_type in ('P','U');

 if cntRows <> 0 then
   cntExists := cntExists + 1;
   goto continue_tbl_loop;
 end if;

 get_unique_index_data(tbl.table_name);

 if l_error = True then
   goto continue_tbl_loop;
 end if;

 l_sqlcmd := 'alter table ' || tbl.table_name || ' add constraint ';
 if l_index_has_nulls = 'Y' then
   l_sqlcmd := l_sqlcmd || 'UK_';
 else
   l_sqlcmd := l_sqlcmd || 'PK_';
 end if;
 l_sqlcmd := l_sqlcmd || substr(tbl.table_name,1,27);
 if l_index_has_nulls = 'Y' then
   l_sqlcmd := l_sqlcmd || ' unique(';
 else
   l_sqlcmd := l_sqlcmd || ' primary key(';
 end if;
 l_sqlcmd := l_sqlcmd || l_index_columns || ')';
 if l_index_name is not null then
   l_sqlcmd := l_sqlcmd || ' using index ' || l_index_name;
 end if;

 zut.prt(l_sqlcmd);

 if updflag = 'Y' then
   cntCreated := cntCreated + 1;
   begin
     execute immediate l_sqlcmd;
   exception when others then
     zut.prt(sqlerrm);
     cntExcept := cntExcept + 1;
   end;
 end if;

<< continue_tbl_loop >>
  null;
end loop;

zut.prt('Total         ' || cntTot);
zut.prt('PK exists     ' || cntExists);
zut.prt('No Unique Key ' || cntNoUniqueKey);
zut.prt('Created       ' || cntCreated);
zut.prt('Renamed       ' || cntRenamed);
zut.prt('Multiple      ' || cntMulti);
zut.prt('Exceptions    ' || cntExcept);

exception when others then
  zut.prt(sqlerrm);
end;
/
exit;
