set serveroutput on;
--
-- $Id: 
--
alter table orderhdr add
(returns_exception_yn char(1)
,returns_partial_yn char(1)
);

declare
l_rowcount pls_integer := 0;

begin

for oh in (select rowid
             from orderhdr
            where is_returns_order like 'Y%'
              and returns_exception_yn is null)
loop

  update orderhdr
     set returns_exception_yn = 'N',
         returns_partial_yn = 'N'
   where rowid = oh.rowid;

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
