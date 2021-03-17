set serveroutput on;
set timing on;


alter trigger custitem_aiu disable;
alter trigger custitem_aui disable;

alter table custitem add
(
entrydate date
);

declare

type rows_tbl_type is table of rowid;
rows_tbl rows_tbl_type;
l_rows_updated pls_integer;
l_tot_rows pls_integer := 0;

cursor curRows is
  select rowid
    from custitem
   where entrydate is null;

begin

open curRows;
loop

  fetch curRows bulk collect into rows_tbl limit 50000;
  
  if rows_tbl.count = 0 then
    exit;
  end if;
  
  forall i in rows_tbl.first .. rows_tbl.last
    update custitem
       set entrydate = '01-JAN-2014'
     where rowid = rows_tbl(i);
     
  l_rows_updated := sql%rowcount;
  l_tot_rows := l_tot_rows + l_rows_updated;  
  zut.prt('rows so far is ' || l_tot_rows);
  
  commit;

  exit when curRows%notfound;
  
end loop;  
 
if curRows%isopen then
  close curRows;
end if;

zut.prt('Custitem rows updated: ' || l_tot_rows);

end;
/

alter trigger custitem_aiu enable;
alter trigger custitem_aui enable;

exit;
