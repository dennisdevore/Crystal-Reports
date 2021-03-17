alter table appmsgs add
(msgid number(10)
);

declare
cursor curappmsgs is
         select rowid
           from appmsgs
          where msgid is null;
           
type appmsgs_tbl_type is table of rowid;

appmsgs_tbl appmsgs_tbl_type;
l_dtl_rows pls_integer;
l_appmsgs_rows pls_integer := 0;

begin

open curappmsgs;
loop
  
  fetch curappmsgs bulk collect into appmsgs_tbl limit 100000;
  
  if appmsgs_tbl.count = 0 then
    exit;
  end if;

  forall i in appmsgs_tbl.first .. appmsgs_tbl.last
    update appmsgs
       set msgid = 1
     where rowid = appmsgs_tbl(i);

  l_dtl_rows := sql%rowcount;
  l_appmsgs_rows := l_appmsgs_rows + l_dtl_rows;

  commit;     
  
end loop;

zut.prt('rows processed: ' || l_appmsgs_Rows);

exception when others then
  zut.prt(sqlerrm);
  zut.prt('others...');
end;
/
alter table appmsgs modify
msgid not null;
exit;
