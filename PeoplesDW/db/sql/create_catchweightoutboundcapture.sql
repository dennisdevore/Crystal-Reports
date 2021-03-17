--
-- $Id$
--
create table catchweightoutboundcapture
(
   code        varchar2(12) not null,
   descr       varchar2(32) not null,
   abbrev      varchar2(12) not null,
   dtlupdate   varchar2(1),
   lastuser    varchar2(12),
   lastupdate  date
);

create unique index catchweightoutboundcapture_idx
   on catchweightoutboundcapture(code);

insert into tabledefs
   values('CatchWeightOutboundCapture', 'N', 'N', '>A;0;_', 'SUP', sysdate);

insert into catchweightoutboundcapture
   values('G', 'Gross Weight', 'Gross', 'N', 'SUP', sysdate);

insert into catchweightoutboundcapture
   values('N', 'Net Weight', 'Net', 'N', 'SUP', sysdate);

insert into catchweightoutboundcapture
   values(' ', 'None', 'None', 'N', 'SUP', sysdate);

commit;

exit;
