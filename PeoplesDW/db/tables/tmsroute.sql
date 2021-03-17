--
-- $Id$
--

DROP TABLE TMSROUTE CASCADE CONSTRAINTS ; 

CREATE TABLE TMSROUTE ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE ) ; 


CREATE UNIQUE INDEX TRANSROUTE_IDX ON 
  TMSROUTE(CODE) 
; 


insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('TMSRoute','Y','Y','>Aaaaaa;0;_');

exit;