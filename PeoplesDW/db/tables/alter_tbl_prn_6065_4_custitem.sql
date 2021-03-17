--
-- $Id$
--
alter table custitem add
(unkitted_class varchar2(2)
);

declare
cntRows integer;
new_iskit custitem.iskit%type;

begin

for cit in (select rowid,nvl(iskit,'x') as iskit
              from custitem
             where nvl(iskit,'x') in ('x','S','O'))
loop

  if cit.iskit = 'x' then
    new_iskit := 'N';
  else
    new_iskit := 'K';
  end if;

  update custitem
     set iskit = new_iskit
   where rowid = cit.rowid;

end loop;

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
exit;
