--
-- $Id: alter_tbl_waves_sdi.sql 8580 2012-06-25 13:06:24Z brianb $
--
alter table waves add
(sdi_manual_picks_yn char(1)
);

declare
l_rowcount pls_integer := 0;

begin

for wv in (select rowid
             from waves
            where sdi_manual_picks_yn is null)
loop

  update waves
     set sdi_manual_picks_yn = 'N'
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
