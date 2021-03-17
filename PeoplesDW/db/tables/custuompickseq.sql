--
-- $Id$
--
create table custuompickseq (
   custid     varchar2(10) not null,
   sequence   number(4) not null,
   pickuom    varchar2(4) not null,
   lastuser   varchar2(12),
   lastupdate date
);

create unique index custuompickseq_idx on custuompickseq
 (custid,pickuom);
 
exit;