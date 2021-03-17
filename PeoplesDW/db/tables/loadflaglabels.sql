--
-- $Id$
--

drop table loadflaglabels cascade constraints ; 

create table loadflaglabels ( 
  code        varchar2 (12)  not null, 
  descr       varchar2 (32)  not null, 
  abbrev      varchar2 (12)  not null, 
  dtlupdate   varchar2 (1), 
  lastuser    varchar2 (12), 
  lastupdate  date);


create unique index loadflaglabels_idx on 
  loadflaglabels(code) ; 
  
insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('Loadflaglabels','y','y','>A;0;_');

insert into loadflaglabels ( code,descr,abbrev,dtlupdate,lastuser,lastupdate) 
values ('D','Destination Load Flag','1   DLFF','Y','SUP',sysdate);
insert into loadflaglabels ( code,descr,abbrev,dtlupdate,lastuser,lastupdate) 
values ('S','Small Package Load Flag','1   SLFF','Y','SUP',sysdate);
insert into loadflaglabels ( code,descr,abbrev,dtlupdate,lastuser,lastupdate) 
values ('M','Mail List Load Flag','1   MLFF','Y','SUP',sysdate);

exit;
