--
-- $Id$
--
create table LotReceiptCapture
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index LotReceiptCapture_idx
   on LotReceiptCapture(code);

insert into tabledefs
   values('LotReceiptCapture', 'N', 'N', '>Aaaa;0;_', 'SUP', sysdate);

commit;

-- exit;
