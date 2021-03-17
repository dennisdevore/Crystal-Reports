--
-- $Id$
--

DROP TABLE TMSSTATECODE CASCADE CONSTRAINTS ; 

CREATE TABLE TMSSTATECODE ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE ) ; 


CREATE UNIQUE INDEX TMSSTATECODE_IDX ON 
  TMSSTATECODE(CODE) 
; 



insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('TMSStateCode','Y','Y','>Aa;0;_');


exit;