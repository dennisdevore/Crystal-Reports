--
-- $Id$
--
DROP TABLE loaded_by_types;

CREATE TABLE loaded_by_types (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX loaded_by_types_IDX ON
  loaded_by_types(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('Loaded_by_Types','N','N','>A;0;_','SYSTEM',sysdate);

insert into loaded_by_types
values ('S', 'Shipper','Shipper','N','SYSTEM',sysdate);

insert into loaded_by_types
values ('D', 'Driver','Driver','N','SYSTEM',sysdate);

commit;

--exit;

