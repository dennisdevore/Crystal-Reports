--
-- $Id$
--
drop table zseq;

create table zseq
(
    seq number(5) not null,
    CONSTRAINT pk_zseq PRIMARY KEY (seq)
)
ORGANIZATION INDEX;

declare
ix pls_integer;

begin
  for ix in 1..10000 loop
    insert into zseq values (ix);
  end loop;
end;
/
exit;
