--
-- $Id$
--
alter table userheader add (
   blendedpword      varchar2(40),
   session_id        varchar2(255)
);

begin

for uh in (select nameid,rowid
             from userheader
            where blendedpword is null)
loop

  update userheader
     set blendedpword = zus.blenderize_user(uh.nameid,uh.nameid)
   where rowid = uh.rowid;
   
end loop;

end;
/
exit;
