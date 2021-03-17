--
-- $Id$
--

DROP TABLE TMSCARRIERS CASCADE CONSTRAINTS ; 

CREATE TABLE TMSCARRIERS ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE);


CREATE UNIQUE INDEX TMSCARRIERS_IDX ON 
  TMSCARRIERS(CODE) ; 

insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('TMSCarriers','Y','Y','>Aaaa;0;_');


exit;

