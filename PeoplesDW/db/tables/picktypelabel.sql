-- $ID: $

--drop table picktypelabel;

create table picktypelabel
  (code	 varchar2(12) not null,
   descr varchar2(32) not null,
   abbrev varchar2(12) not null,
   dtlupdate varchar2(1),
   lastuser varchar2(12),
   lastupdate date);

insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('BAT', 'Batch Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('LINE', 'Line Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('CLUS', 'Cluster Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('ORDR', 'Order Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('OP', 'Order Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('BP', 'Batch Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('PK', 'Pick Label', 'N','Y', 'SUP',sysdate);
insert into picktypelabel (code, descr, abbrev, dtlupdate, lastuser, lastupdate)
values('SO', 'Sorter Pick Label', 'N','Y', 'SUP',sysdate);
commit;

exit;
