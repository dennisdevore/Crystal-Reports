--
-- $Id$
--
set serveroutput on;

declare

cursor curFDI is
  select definc,linelength
    from impexp_definitions
   where upper(name) = 'FORMAT DEFINITION IMPORT';
ie_def curFDI%rowtype;

cursor curFDIline(in_definc number) is
  select lineinc
    from impexp_lines
   where definc = in_definc
     and upper(procname) = 'IMPORT_FORMAT_CHUNK';
ie_line curFDIline%rowtype;

cursor curFDImaxchunk(in_definc number, in_lineinc number) is
  select max(chunkinc) as chunkinc
    from impexp_chunks
   where definc = in_definc
     and lineinc = in_lineinc;
ie_maxchunk curFDImaxchunk%rowtype;

cursor curFDE is
  select definc,linelength
    from impexp_definitions
   where upper(name) = 'FORMAT DEFINITION EXPORT';

cursor curFDEline(in_definc number) is
  select lineinc
    from impexp_lines
   where definc = in_definc
     and upper(procname) = 'IMPEXPFMT_CHUNK_VIEW';

cursor curFDEmaxchunk(in_definc number, in_lineinc number) is
  select max(chunkinc) as chunkinc
    from impexp_chunks
   where definc = in_definc
     and lineinc = in_lineinc;

cntRows integer;

begin


ie_def := null;
open curFDI;
fetch curFDI into ie_def;
close curFDI;
if ie_def.definc is null then
  zut.prt('Format Definition Import-definition not found');
  goto do_export;
end if;

if ie_def.linelength != 2404 then
  update impexp_definitions
     set linelength = 2404
   where definc = ie_def.definc;
  zut.prt('Import Definition Record Length Set to 2404');
  commit;
end if;

ie_line := null;
open curFDIline(ie_def.definc);
fetch curFDIline into ie_line;
close curFDIline;
if ie_line.lineinc is null then
  zut.prt('Format Definition Import-import_format_chunk line not found');
  goto do_export;
end if;

ie_maxchunk := null;
open curFDImaxchunk(ie_def.definc,ie_line.lineinc);
fetch curFDImaxchunk into ie_maxchunk;
close curFDImaxchunk;
if ie_maxchunk.chunkinc is null then
  zut.prt('Format Definition Import-import_format_chunk max chunk not found');
  goto do_export;
end if;

select count(1)
  into cntRows
  from impexp_chunks
 where definc = ie_def.definc
   and lineinc = ie_line.lineinc
   and chunkinc = ie_maxchunk.chunkinc
   and upper(paramname) = 'IN_FROM_ANOTHER_CHUNK';
if cntRows != 0 then
  zut.prt('Format Definition Import already updated');
  goto do_export;
end if;

ie_maxchunk.chunkinc := ie_maxchunk.chunkinc + 1;
insert into impexp_chunks
(definc,lineinc,chunkinc,
 chunktype,paramname,
 offset,length,
 description,chunkdecimals)
values
(ie_def.definc,ie_line.lineinc,ie_maxchunk.chunkinc,
 0,'IN_NO_FIELDPREFIX_ON_NULL',
 1531,1,
 'No Field Prefix on Null','N'
);

ie_maxchunk.chunkinc := ie_maxchunk.chunkinc + 1;
insert into impexp_chunks
(definc,lineinc,chunkinc,
 chunktype,paramname,
 offset,length,
 description,chunkdecimals)
values
(ie_def.definc,ie_line.lineinc,ie_maxchunk.chunkinc,
 0,'IN_FROM_ANOTHER_CHUNK',
 1532,35,
 'From Another Chunk Description','N'
);

zut.prt('Format Definition Import update complete');

commit;

<<do_export>>

ie_def := null;
open curFDE;
fetch curFDE into ie_def;
close curFDE;
if ie_def.definc is null then
  zut.prt('Format Definition Export-definition not found');
  goto end_it;
end if;

if ie_def.linelength != 2404 then
  update impexp_definitions
     set linelength = 2404
   where definc = ie_def.definc;
  zut.prt('Export Definition Record Length Set to 2404');
  commit;
end if;

ie_line := null;
open curFDEline(ie_def.definc);
fetch curFDEline into ie_line;
close curFDEline;
if ie_line.lineinc is null then
  zut.prt('Format Definition Export-header line not found');
  goto end_it;
end if;

ie_maxchunk := null;
open curFDEmaxchunk(ie_def.definc,ie_line.lineinc);
fetch curFDEmaxchunk into ie_maxchunk;
close curFDEmaxchunk;
if ie_maxchunk.chunkinc is null then
  zut.prt('Format Definition Export-import_format_header chunk not found');
  goto end_it;
end if;

select count(1)
  into cntRows
  from impexp_chunks
 where definc = ie_def.definc
   and lineinc = ie_line.lineinc
   and chunkinc = ie_maxchunk.chunkinc
   and upper(paramname) = 'IN_FROM_ANOTHER_CHUNK';
if cntRows != 0 then
  zut.prt('Format Definition Export already updated');
  goto end_it;
end if;

ie_maxchunk.chunkinc := ie_maxchunk.chunkinc + 1;
insert into impexp_chunks
(definc,lineinc,chunkinc,
 chunktype,paramname,
 offset,length,
 description,chunkdecimals)
values
(ie_def.definc,ie_line.lineinc,ie_maxchunk.chunkinc,
 0,'NO_FIELDPREFIX_ON_NULL_VALUE',
 1531,1,
 'No Field Prefix on Null','N'
);

ie_maxchunk.chunkinc := ie_maxchunk.chunkinc + 1;
insert into impexp_chunks
(definc,lineinc,chunkinc,
 chunktype,paramname,
 offset,length,
 description,chunkdecimals)
values
(ie_def.definc,ie_line.lineinc,ie_maxchunk.chunkinc,
 0,'FROM_ANOTHER_CHUNK_DESCRIPTION',
 1532,35,
 'From Another Chunk Description','N'
);

zut.prt('Format Definition Export update complete');

commit;

<<end_it>>

zut.prt('end-of-update');

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
