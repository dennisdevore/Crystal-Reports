--
-- $Id$
--
create table palletweights
(code varchar2(12) not null
,descr varchar2(255) not null
,abbrev varchar2(12) not null
,dtlupdate varchar2(1)
,lastuser varchar2(12)
,lastupdate date
);

create unique index palletweights_unique
   on palletweights(code);

insert into palletweights values('CHEP','Chep Pallet','67','Y','SYSTEM',sysdate);
insert into palletweights values('PLASTIC','Formed Plastic Pallet','50','Y','SYSTEM',sysdate);
insert into palletweights values('WOOD','Wooden Pallet','42','Y','SYSTEM',sysdate);

insert into tabledefs values('PalletWeights','Y','Y','>Aaaaaaaaaaaa;0;_','SYSTEM',sysdate);

exit;
