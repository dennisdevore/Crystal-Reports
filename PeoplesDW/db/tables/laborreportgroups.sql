--
-- $Id$
--

DROP TABLE LABORREPORTGROUPS;

CREATE TABLE LABORREPORTGROUPS (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX LABORREPORTGROUPS_IDX ON
  LABORREPORTGROUPS(CODE);


insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask)
values('LaborReportGroups','Y','Y','Aaaaaaaaaaaa;0;_');
commit;

exit;


