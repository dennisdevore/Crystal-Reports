--
-- $Id$
--
alter table waves add
(fpf_full_picks_bypass_fpf   char(1)
);

declare
l_rowcount pls_integer := 0;

begin

for wv in (select rowid
             from waves
            where fpf_full_picks_bypass_fpf is null)
loop

  update waves
     set fpf_full_picks_bypass_fpf = 'N'
   where rowid = wv.rowid;

  l_rowcount := l_rowcount + 1;
  if mod(l_rowcount, 10000) = 0 then
    zut.prt('rowcount is ' || l_rowcount);
    commit;
  end if;
  
end loop;

commit;

end;
/   
exit;
