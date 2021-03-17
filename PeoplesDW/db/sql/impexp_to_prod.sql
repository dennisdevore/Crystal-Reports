--
-- $Id$
--
set serveroutput on;
declare
cursor curImpExp is
  select rowid,deffilename
    from impexp_definitions;
begin

update impexp_definitions
   set targetalias = 'alsOhlProd';

zut.prt('processing . . .');
/*
for x in curImpExp loop
  zut.prt(x.deffilename);
  if substr(upper(x.deffilename),1,11) = 'G:\OHLPROD\' then
    zut.prt('updating . . ');
    update impexp_definitions
       set deffilename = 'C:\OHLTEST\' || substr(x.deffilename,12,255)
     where rowid = x.rowid;
     zut.prt('ohlprod updated');
  end if;
  if substr(upper(x.deffilename),1,25) = 'G:\HP\EDI\INBOUND\ORDERS\' then
    zut.prt('updating . . ');
    update impexp_definitions
       set deffilename = 'C:\OHLTEST\IMPORT\INCOMING\' || substr(x.deffilename,26,255)
     where rowid = x.rowid;
     zut.prt('inbound updated');
  end if;
end loop;
*/
--commit;

end;
/
--exit;