--
-- $Id$
--
alter table waves add
(use_flex_pick_fronts_yn    char(1)
,fpf_minqty                 number(7)
,fpf_minuom                 varchar2(4)
,fpf_maxqty                 number(7)
,fpf_maxuom                 varchar2(4)
,fpf_allocrule              varchar2(10)
,fpf_begin_location         varchar2(10)
,fpf_full_picks_to_fpf_yn   char(1)
);

declare
l_rowcount pls_integer := 0;

begin

for wv in (select rowid
             from waves
            where use_flex_pick_fronts_yn is null)
loop

  update waves
     set use_flex_pick_fronts_yn = 'N',
         fpf_full_picks_to_fpf_yn = 'N'
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
