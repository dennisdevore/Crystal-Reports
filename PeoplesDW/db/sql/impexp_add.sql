--
-- $Id$
--
set serveroutput on;

declare

cursor curOldDefInc is
  select definc,name
    from oldexp_definitions;

cursor curChunks(in_definc number) is
  select *
    from oldexp_chunks
   where definc = in_definc;

cntRows integer;
prmdefinc integer;

begin

zut.prt('begin old loop');

for old in curOldDefInc
loop
  zut.prt('check for existing definc');
  begin
    select definc
      into prmdefinc
      from impexp_definitions
     where name = old.name;
  exception when others then
    prmdefinc := null;
  end;
  zut.prt('existing is ' || prmdefinc);
  if prmdefinc is not null then
    zut.prt('deleting existing format ' || old.definc || ' ' || old.name);
    delete from impexp_afterprocessprocparams
     where definc = prmdefinc;
    delete from impexp_chunks
     where definc = prmdefinc;
    delete from impexp_lines
     where definc = prmdefinc;
    delete from impexp_definitions
     where definc = prmdefinc;
  end if;

  zut.prt('finding new definc');
  select max(definc)+1
    into prmdefinc
    from impexp_definitions;

  while(1=1)
  loop
    cntRows := 0;
    begin
      select count(1)
        into cntRows
        from oldexp_definitions
       where definc = prmdefinc;
    exception when others then
      null;
    end;
    if cntRows != 0 then
      prmdefinc := prmdefinc + 1;
    else
      exit;
    end if;
  end loop;

  zut.prt('using new definc ' || prmdefinc);

  update oldexp_definitions
     set definc = prmdefinc
   where definc = old.definc;
  update oldexp_lines
     set definc = prmdefinc
   where definc = old.definc;
  update oldexp_chunks
     set definc = prmdefinc
   where definc = old.definc;
  update oldexp_afterprocessprocparams
     set definc = prmdefinc
   where definc = old.definc;

  insert into impexp_definitions
    select * from oldexp_definitions
     where definc = prmdefinc;
  cntRows := sql%rowcount;
  zut.prt('definitions copied ' || cntRows);

  insert into impexp_lines
    select * from oldexp_lines
     where definc = prmdefinc;
  cntRows := sql%rowcount;
  zut.prt('lines copied ' || cntRows);

  cntRows := 0;
  for x in curChunks(prmdefinc)
  loop
    insert into impexp_chunks
     (DEFINC,LINEINC,CHUNKINC,CHUNKTYPE,PARAMNAME,OFFSET,LENGTH,
      DEFVALUE,DESCRIPTION,LKTABLE,LKFIELD,LKKEY,MAPPINGS,
      PARENTLINEPARAM,CHUNKDECIMALS)
    values
     (x.DEFINC,x.LINEINC,x.CHUNKINC,x.CHUNKTYPE,x.PARAMNAME,x.OFFSET,x.LENGTH,
      x.DEFVALUE,x.DESCRIPTION,x.LKTABLE,x.LKFIELD,x.LKKEY,x.MAPPINGS,
      x.PARENTLINEPARAM,x.CHUNKDECIMALS);
    cntRows := cntRows + 1;
  end loop;
  zut.prt('chunks copied ' || cntRows);

  insert into impexp_afterprocessprocparams
    select * from oldexp_afterprocessprocparams
     where definc = prmdefinc;
  cntRows := sql%rowcount;
  zut.prt('afters copied ' || cntRows);

  commit;

end loop;
zut.prt('commit complete');

exception when others then
  zut.prt('when others...');
  zut.prt(sqlerrm);
end;
/
--exit;

