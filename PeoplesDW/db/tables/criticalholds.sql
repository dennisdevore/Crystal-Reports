--
-- $Id: criticalholds
--

--DROP TABLE CRITICALHOLDS CASCADE CONSTRAINTS ; 

CREATE TABLE CRITICALHOLDS ( 
  CODE        VARCHAR2 (12)  NOT NULL, 
  DESCR       VARCHAR2 (32)  NOT NULL, 
  ABBREV      VARCHAR2 (12)  NOT NULL, 
  DTLUPDATE   VARCHAR2 (1), 
  LASTUSER    VARCHAR2 (12), 
  LASTUPDATE  DATE);


CREATE UNIQUE INDEX CRITICALHOLDS_IDX ON 
  CRITICALHOLDS(CODE) ; 

insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('CriticalHolds','Y','Y','>Aa;0;_');


exit;

