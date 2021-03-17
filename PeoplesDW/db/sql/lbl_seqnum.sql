--
-- $Id$
--
drop table lbl_seqnum;

create table lbl_seqnum
(seqnum    number);

create unique index lbl_seqnum_unique on
  lbl_seqnum(seqnum);

begin
   for i in 1..10000 loop
     insert into lbl_seqnum values(i);
   end loop;
end;
/
exit;
