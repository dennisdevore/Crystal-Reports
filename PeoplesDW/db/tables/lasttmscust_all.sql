--
-- $Id$
--

DROP TABLE LASTTMSCUST_ALL CASCADE CONSTRAINTS ; 

CREATE TABLE LASTTMSCUST_ALL ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE);


CREATE UNIQUE INDEX LASTTMSCUST_ALL_IDX ON 
  LASTTMSCUST_ALL(CODE) ; 
  
insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('LASTTMSCUST_ALL','Y','Y','>Aaaaaaaa;0;_');

insert into lasttmscust_all ( code,descr,abbrev) values ('ALLALL','Last TMS Cust/Consignee Export','010101000000');


 
exit;
