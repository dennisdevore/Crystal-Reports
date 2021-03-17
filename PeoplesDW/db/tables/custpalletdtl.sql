--
-- $Id$
--
drop table custpalletdtl;

create table custpalletdtl
(facility varchar2(3) not null
,custid varchar2(10) not null
,trandate date
,pallettype varchar2(4) not null
,trantype varchar2(4)
,qty number(7)
,lastuser varchar2(12)
,lastupdate date
);

create index custpalletdtl_index
   on custpalletdtl(facility,custid,trandate,pallettype);

create index custpalletdtl_trandate_index
   on custpalletdtl(trandate);

exit;
