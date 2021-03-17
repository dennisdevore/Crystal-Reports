--
-- $Id$
--
declare
cursor curImpExp is
  select rowid,deffilename
    from impexp_definitions;
begin

zut.prt('processing . . .');
for x in curImpExp loop
  zut.prt(x.deffilename);
  if substr(upper(x.deffilename),1,12) = 'N:\OHLTRAIN\' then
    zut.prt('updating . . ');
    update impexp_definitions
       set deffilename = 'G:\OHLPROD\' || substr(x.deffilename,13,255)
     where rowid = x.rowid;
  end if;
end loop;
--commit;

end;
/
--exit;
