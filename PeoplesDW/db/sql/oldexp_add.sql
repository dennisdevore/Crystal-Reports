--
-- $Id$
--
set serveroutput on;

declare

cursor curChunks(in_definc number) is
  select *
    from impexp_chunks
   where definc = in_definc;

cntRows integer;
prmdefinc integer;
prmDeleteOld varchar2(255);
begin

prmDeleteOld := upper('&DeleteOld');
prmdefinc := &DefInc;

if prmDeleteOld = 'Y' then
  delete from oldexp_definitions;
  delete from oldexp_lines;
  delete from oldexp_chunks;
  delete from oldexp_afterprocessprocparams;
  commit;
  zut.prt('deleted old data');
end if;

insert into oldexp_definitions
  select * from impexp_definitions
   where definc = prmdefinc;
cntRows := sql%rowcount;
zut.prt('definitions copied ' || cntRows);

insert into oldexp_lines
  select * from impexp_lines
   where definc = prmdefinc;
cntRows := sql%rowcount;
zut.prt('lines copied ' || cntRows);

cntRows := 0;
for x in curChunks(prmdefinc)
loop
  insert into oldexp_chunks
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

insert into oldexp_afterprocessprocparams
  select * from impexp_afterprocessprocparams
   where definc = prmdefinc;
cntRows := sql%rowcount;
zut.prt('afters copied ' || cntRows);

commit;
zut.prt('commit complete');

exception when others then
  zut.prt('when others...');
  zut.prt(sqlerrm);
end;
/
--exit;

