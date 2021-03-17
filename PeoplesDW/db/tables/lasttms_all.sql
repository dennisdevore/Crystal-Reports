--
-- $Id$
--


DROP TABLE LASTTMS_ALL CASCADE CONSTRAINTS ; 

CREATE TABLE LASTTMS_ALL ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE);


CREATE UNIQUE INDEX LASTTMS_ALL_IDX ON 
  LASTTMS_ALL(CODE) ;
  
  insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('LASTTMS_ALL','Y','Y','>Aaaaaaaa;0;_');

insert into lasttms_all ( code,descr,abbrev) values ('ALLALL','Last TMS Export','010101000000');

   
exit;
