--
-- $Id$
--
drop table custpallethdr;

create table custpallethdr
(facility varchar2(3) not null
,custid varchar2(10) not null
,pallettype varchar2(4) not null
,qty number(7)
,lastuser varchar2(12)
,lastupdate date
);

create unique index custpallethdr_unique
   on custpallethdr(facility,custid,pallettype);

exit;
