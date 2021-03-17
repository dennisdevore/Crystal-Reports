--
-- $Id$
--
truncate table oldexp_definitions;
truncate table oldexp_lines;
truncate table oldexp_chunks;
truncate table oldexp_afterprocessprocparams;

set serveroutput on;

declare

cursor curChunks is
  select *
    from impexp_chunks;

cntRows integer;

begin

insert into oldexp_definitions
  select * from impexp_definitions;
cntRows := sql%rowcount;
zut.prt('definitions copied ' || cntRows);

insert into oldexp_lines
  select * from impexp_lines;
cntRows := sql%rowcount;
zut.prt('lines copied ' || cntRows);

cntRows := 0;
for x in curChunks
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
  select * from impexp_afterprocessprocparams;
cntRows := sql%rowcount;
zut.prt('afters copied ' || cntRows);

commit;
zut.prt('commit complete');

exception when others then
  zut.prt('when others...');
  zut.prt(sqlerrm);
end;
/
exit;

