--
-- $Id$
--
DROP TABLE counted_by_types;

CREATE TABLE counted_by_types (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX counted_by_types_IDX ON
  counted_by_types(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('Counted_by_Types','N','N','>Aa;0;_','SYSTEM',sysdate);

insert into counted_by_types
values ('S', 'Shipper','Shipper','N','SYSTEM',sysdate);

insert into counted_by_types
values ('D1', 'Driver','DriverPallet','N','SYSTEM',sysdate);

insert into counted_by_types
values ('D2', 'Driver','DriverPieces','N','SYSTEM',sysdate);

commit;

--exit;

