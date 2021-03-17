--
-- $Id$
--
select *
  from impexpdefview
 where targetalias is not null
    or deffilename is not null
    or dateformat is not null
    or deftype is not null
    or floatdecimals is not null
    or amountdecimals is not null
    or linelength is not null
    or afterprocessproc is not null
    or beforeprocessproc is not null
    or afterprocessprocparams is not null
    or beforeprocessprocparams is not null
    or timeformat is not null
    or includecrlf is not null;
select *
  from impexplinview
 where parent is not null
    or type is not null
    or identifier is not null
    or delimiter is not null
    or linealias is not null
    or procname is not null
    or delimiteroffset is not null
    or afterprocessprocname is not null
    or headertrailerflag is not null
    or orderbycolumns is not null;
select *
  from impexpchuview
 where chunktype is not null
    or paramname is not null
    or offset is not null
    or length is not null
    or defvalue is not null
    or description is not null
    or lktable is not null
    or lkfield is not null
    or lkkey is not null
    or parentlineparam is not null
    or chunkdecimals is not null;
select *
  from impexpaftview
 where chunkinc is not null
    or defvalue is not null;

set serveroutput on;

declare

cursor curNewMappings is
  select definc,
         lineinc,
         chunkinc,
         mappings
    from impexp_chunks;

cursor curOldMappings(in_definc number,in_lineinc number,
                      in_chunkinc number) is
  select definc,
         lineinc,
         chunkinc,
         mappings
    from oldexp_chunks
   where definc = in_definc
     and lineinc = in_lineinc
     and chunkinc = in_chunkinc;
om curOldMappings%rowtype;

begin

for x in curNewMappings
loop
  om := null;
  open curOldMappings(x.definc,x.lineinc,x.chunkinc);
  fetch curOldMappings into om;
  close curOldMappings;
  if om.definc is not null then
    if nvl(x.mappings,'x') != nvl(om.mappings,'x') then
      zut.prt('diff mappings: ' || x.definc || ' ' ||
        x.lineinc || ' ' || x.chunkinc);
      zut.prt('old: ' || om.mappings);
      zut.prt('new: ' || x.mappings);
    end if;
  end if;
end loop;
exception when others then
  zut.prt('when others . . .');
  zut.prt(sqlerrm);
end;
/
exit;

