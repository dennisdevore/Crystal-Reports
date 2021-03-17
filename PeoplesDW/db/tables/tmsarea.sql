--
-- $Id$
--

DROP TABLE TMSAREA CASCADE CONSTRAINTS ;

CREATE TABLE TMSAREA (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE);


CREATE UNIQUE INDEX TRANSAREA_IDX ON
  TMSAREA(CODE) ;

insert into tabledefs (tableid,hdrupdate,dtlupdate,codemask)
values('TMSArea','Y','Y','>Aaaa;0;_');

exit;