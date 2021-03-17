set serveroutput on;
spool audit_pimevents_loadno.out

declare
l_tot pls_integer := 0;
l_oky pls_integer := 0;
l_err pls_integer := 0;
l_msg varchar2(255);
l_update char(1) := 'N';

begin

for pe in (select loadno,rowid
             from pimevents
            where nvl(loadno,0) != 0
            order by loadno)
loop

  l_tot := l_tot + 1;
  for ld in (select loadno,loadstatus,lastupdate,lastuser
               from loads
              where loadno = pe.loadno)
  loop
  
    if ld.loadstatus < '9' or
       ld.loadstatus = 'E' then
      l_oky := l_oky + 1;
      l_msg := 'Oky';
    else
      l_err := l_err + 1;
      l_msg := 'Err';
      if l_update = 'Y' then
        delete from pimevents where rowid = pe.rowid;
      end if;
    end if;
    
    zut.prt('Loadno ' || ld.loadno || ' status ' || ld.loadstatus ||
            ' ' || ld.lastupdate || ' ' || ld.lastuser || ' ' || l_msg);
            
  end loop;

end loop;

zut.prt('Tot ' || l_tot);
zut.prt('Oky ' || l_oky);
zut.prt('Err ' || l_err);

end;
/
exit;
