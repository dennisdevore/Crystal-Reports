--
-- $Id$
--
create table QCConditions( code varchar2(4) not null, descr varchar2(32) not null, abbrev varchar2(12) not null, dtlupdate varchar2(1), lastuser varchar2(12), lastupdate date);            

create unique index QCConditions_idx  on QCConditions(code);                                                                                                                      
insert into tabledefs values('QCConditions','Y','Y','>Aaaa;0;_','SUP',sysdate);                                                                                                      
commit;

-- exit;


