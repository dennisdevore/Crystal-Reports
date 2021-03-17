--
-- $Id$
--
DROP TABLE Delivery_Point_Types;

CREATE TABLE Delivery_Point_Types (
  CODE        VARCHAR2 (12)  NOT NULL,
  DESCR       VARCHAR2 (32)  NOT NULL,
  ABBREV      VARCHAR2 (12)  NOT NULL,
  DTLUPDATE   VARCHAR2 (1),
  LASTUSER    VARCHAR2 (12),
  LASTUPDATE  DATE ) ;


CREATE UNIQUE INDEX Delivery_Point_Types_IDX ON
  Delivery_Point_Types(CODE) ;

insert into tabledefs(tableid,hdrupdate,dtlupdate,codemask,lastuser,lastupdate)
  values('Delivery_Point_Types','N','N','>A;0;_','SYSTEM',sysdate);

insert into delivery_point_types
values ('C', 'Consignee','Consignee','N','SYSTEM',sysdate);
insert into delivery_point_types
values ('D', 'Distributor','Distributor','N','SYSTEM',sysdate);

commit;

exit;

