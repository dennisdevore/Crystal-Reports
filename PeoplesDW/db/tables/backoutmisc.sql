--
-- $Id$
--

DROP TABLE BACKOUTMISC;

CREATE TABLE BACKOUTMISC (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX BACKOUTMISC_IDX ON
  BACKOUTMISC(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask) values('BackOutMisc','Y','Y','>Aaaa;0;_');
commit;
exit;

