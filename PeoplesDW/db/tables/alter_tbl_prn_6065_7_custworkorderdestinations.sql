--
-- $Id$
--
create table custworkorderdestinations
(seq number(8) not null
,subseq number(8) not null
,facility varchar2(3) not null
,location varchar2(10)
,loctype varchar2(3)
,constraint custworkorderdestinations_pk primary key (seq,subseq) enable
);

insert into custworkorderdestinations
   (seq, subseq, facility, location, loctype)
select seq, subseq, destfacility, destlocation, destloctype
from custworkorderinstructions
where destfacility is not null;

exit;
