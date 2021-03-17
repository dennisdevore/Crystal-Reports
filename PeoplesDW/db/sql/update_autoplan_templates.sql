--
-- $Id$
--
set serveroutput on;
declare

cursor curRequests is
  select rowid,descr,str14,str01
	 from requests
   where reqtype = 'WaveSelect'
	  and substr(nvl(str14,'HDRPASSTHRU'),1,11) != 'HDRPASSTHRU'
	  and str15 is not null
   order by descr;

cntRows integer;
cntErr integer;
newstr14 requests.str14%type;
begin

cntRows := 0;
cntErr := 0;

for req in curRequests
loop
  zut.prt(req.descr);
  zut.prt('  ' || req.str14);
  begin
	 select fieldname
		into newstr14
		from custdict
     where custid = req.str01
		 and labelvalue = substr(req.str14,1,length(req.str14)-1);
  exception when others then
	 newstr14 := '???';
	 cntErr := cntErr + 1;
  end;
  if newstr14 <> '???' then
	 update requests
		 set str14 = newstr14
     where rowid = req.rowid;
  end if;
  zut.prt('  ' || newstr14);
  cntRows := cntRows + 1;
end loop;

zut.prt('total ' || cntRows);
zut.prt('error ' || cntErr);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
--exit;
