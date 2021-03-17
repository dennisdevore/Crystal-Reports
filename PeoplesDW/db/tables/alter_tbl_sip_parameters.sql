--
-- $Id$
--
DROP TABLE sip_parameters;

CREATE TABLE sip_parameters (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX sip_parameters_IDX ON
  sip_parameters(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('sip_parameters','Y','Y','>Aaaaaaaaaaaa;0;_','SYSTEM',sysdate);

commit;

--exit;

